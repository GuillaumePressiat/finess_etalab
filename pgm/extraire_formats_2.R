library(dplyr, warn.conflicts = FALSE)
source('pgm/xml_to_df.R')


url_1 <- "https://www.data.gouv.fr/s/resources/finess-extraction-du-fichier-des-etablissements/"

# standard
f <- "20180404-104958/etalab_cs1100502.pdf"
# geoloc
f <- "20170612-090545/etalab_cs1100507.pdf"

type <- stringr::str_extract(f, 'cs[0-9]{7}')

# Lire le pdf
u <- pdftools::pdf_text(file.path(url_1, f))

# Rassembler toutes les pages dans un seul vecteur
v <- paste0(u, collapse = "\n")
# une data.frame avec une ligne par ligne du pdf 
v <- v %>% stringr::str_split('\n') %>% purrr::flatten_chr() %>% 
  tibble(v = .)

# On identifie le départ de la description xml
v <- v %>% 
  mutate(start = grepl('\\?xml', v),
         start = if_else(start == FALSE, NA, TRUE)) %>% 
  tidyr::fill(start) %>% 
  filter(!grepl('etalab_cs', v), start, v != "")
v <- pull(v,v)

# écrire le fichier xsd à partir de ce pdf : forme brute (sans indentation)
write.table(stringr::str_trim(v), paste0('data_results/formats/format_etalab', type, '.xsd'), row.names = F, col.names = F, quote = F)
# le relire avec xml2
w <- xml2::read_xml(paste0('data_results/formats/format_etalab', type, '.xsd'))
# le ré écrire avec indentation
xml2::write_xml(w, paste0('data_results/formats/format_etalab', type, '.xsd'))


# en passant par du json : si on convertit ce xsd en json avec http://www.utilities-online.info/xmltojson/
# w <- jsonlite::fromJSON(txt = '~/Documents/etalab.json')
# uu <- w$`xs:schema`$`xs:simpleType`
# vv <- w$`xs:schema`$`xs:element`$`xs:complexType`$`xs:sequence`$`xs:element`[[3]]


# directement avec xml2
# lecture
w <- xml2::read_xml(paste0('data_results/formats/format_etalab', type, '.xsd'))
# noeud simpleType : définition des types de colonnes
simpletype <- xml2::xml_find_all(w, ".//xs:simpleType")
e <- xml_to_df(simpletype) %>% tidyr::unnest() %>% 
  mutate(name = xml2::xml_attrs(simpletype, 'name') %>% purrr::flatten_chr()) %>% 
  mutate_at(.vars = vars(starts_with('xs:')), purrr::map, 'value') %>% 
  select(type = name, base, starts_with('xs:')) %>% 
  mutate(base = stringr::str_remove(base, 'xs:'))

# structure du fichier : éléments
xml2::xml_find_all(w, ".//xs:element") %>% 
  xml2::xml_attr("ref") %>% 
  tibble(ref = ., id = 1:length(.)) %>% 
  filter(!is.na(ref)) %>% 
  filter(ref %in% c('structureet', 'geolocalisation')) -> i


# noeud complexType : correspondances entre types de colonnes et noms de colonnes
complex <- function(element){
  index <- i[i$ref == element,]$id
  complextype <- xml2::xml_find_all(w, ".//xs:complexType")[index]
  f <- xml_to_df(complextype) %>% tidyr::unnest() %>% tidyr::unnest() %>% 
    select(name, type, nillable, minOccurs, maxOccurs)
  f %>% mutate(section = element)
}


f <- i$ref %>% purrr::map(complex) %>% bind_rows()

# Jointure
g <- left_join(e,f, by = 'type')

rangs <- u %>% paste0(., collapse = "\n") %>% 
  stringr::str_split(., '\n', simplify = TRUE) %>% .[1,] %>% 
  stringr::str_extract('.*\\s{3,}([a-z]+|.*)') %>% 
  .[!is.na(.)] %>% 
  stringr::str_trim() %>% 
  stringr::str_split_fixed('\\s{3,}',  n = 2) %>% 
  as.data.frame() %>% 
  filter(stringr::str_detect(V2, '^([A-Za-z]+|.{1})\\s+[0-9]+')) %>% 
  tidyr::separate(V2, into = c('V2', 'V3')) %>% 
  rename(libelle = V1, rang = V3) %>% 
  mutate(section = ifelse(stringr::str_detect(libelle, 'Section : '), 
                          stringr::str_replace(libelle, "(Section : )([a-z]+)", "\\2"), NA)) %>% 
  tidyr::fill(section) %>% 
  mutate(V2 = tolower(V2),
         libelle = as.character(libelle))


glimpse(rangs)

# Rassembler toutes les informations
h <- right_join(g, rangs, by = c('name' = 'V2', 'section')) %>% 
  rename_at(vars(starts_with('xs:')), funs(stringr::str_remove(.,'xs:'))) %>% 
  mutate_all(funs(as.character(ifelse(. == "NULL", "", .))))


glimpse(h)

write.csv2(h, paste0('data_results/formats/format_etalab', type, '.csv'), quote = FALSE, row.names = FALSE, na = "")
xlsx::write.xlsx(h, paste0('data_results/formats/format_etalab', type, '.xlsx'))
