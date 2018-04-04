
library(pdftools)

notices <- list.files('data/') %>% 
  .[grepl('\\.pdf', .)]

f = notices[1]
# f = notices[2]

# rangs <- pdf_text(file.path('data', f))[1] %>% 
#   stringr::str_split(., '\n', simplify = TRUE) %>% .[1,] %>% 
#   #stringr::str_extract('\\s{3,}[a-z]+\\s{3,}[0-9]+') %>% 
#   stringr::str_match('\\s{3,}[a-z]+\\s{3,}[0-9]+') %>% 
#   .[!is.na(.)] %>% 
#   stringr::str_trim() %>% 
#   stringr::str_split('\\s+', simplify = TRUE) %>% 
#   as.data.frame()

rangs <- pdf_text(file.path('data', f))[1] %>% 
  stringr::str_split(., '\n', simplify = TRUE) %>% .[1,] %>% 
  stringr::str_extract('.*\\s{3,}[a-z]+\\s{3,}[0-9]+') %>% 
  .[!is.na(.)] %>% 
  stringr::str_split_fixed('\\s{3,}',  n = 3) %>% 
  as.data.frame()


xmlstruct <- pdf_text(file.path('data', f)) %>% paste0(., collapse = "\n") %>% 
  stringr::str_split(., '\n', simplify = TRUE) %>% .[1,] %>% 
  .[grepl('<|>', .)]

library(xml2)
library(dplyr)
library(purrr)
library(stringr)
library(purrr)

# From the root node:
# If has_children, then recurse.
# Otherwise, attributes, value and children (nested) to data frame.

xml_to_df <- function(doc, ns = xml_ns(doc)) {
  node_to_df <- function(node) {
    # Filter the attributes for ones that aren't namespaces
    # x <- list(.index = 0, .name = xml_name(node, ns))
    x <- list(.name = xml_name(node, ns))
    # Attributes as column headers, and their values in the first row
    attrs <- xml_attrs(node)
    if (length(attrs) > 0) {attrs <- attrs[!grepl("xmlns", names(attrs))]}
    if (length(attrs) > 0) {x <- c(x, attrs)}
    # Build data frame manually, to avoid as.data.frame's good intentions
    children <- xml_children(node)
    if (length(children) >= 1) {
      x <- 
        children %>%
        # Recurse here
        map(node_to_df) %>%
        split_by(".name") %>%
        map(bind_rows) %>%
        map(list) %>%
        {c(x, .)}
      attr(x, "row.names") <- 1L
      class(x) <- c("tbl_df", "data.frame")
    } else {
      x$.value <- xml_text(node)
    }
    x
  }
  node_to_df(doc)
}
split_by <- function(.x, .f, ...) {
  vals <- map(.x, .f, ...)
  split(.x, simplify_all(transpose(vals)))
}


write.table(data_frame(stringr::str_trim(xmlstruct)), 'data/test.xml', row.names = F, col.names = F, na = "", quote = F)
pivot <- xml2::read_xml('data/test.xml') %>% 
  xml_to_df() %>% select(`xs:element`) %>% 
  tidyr::unnest() %>% 
  tidyr::unnest() %>% 
  tidyr::unnest() %>% 
  select(`xs:element`) %>% 
  tidyr::unnest() %>% 
  select(name, type)

pivot <- xml2::read_xml('data/formats_text.xml') %>% 
  xml_to_df() %>% select(`xs:element`) %>% 
  tidyr::unnest() %>% 
  tidyr::unnest() %>% 
  tidyr::unnest() %>% 
  select(`xs:element`) %>% 
  tidyr::unnest() %>% 
  select(name, type)


simpleType <- xml2::read_xml('data/formats_text.xml') %>% 
  xml_to_df() %>% select(`xs:simpleType`) %>% 
  tidyr::unnest() %>% 
  tidyr::unnest() %>%
  purrr::compact() %>% 
  group_by(name) %>% 
  tidyr::gather(variable, valeur, - name) %>% 
  filter(valeur != 'NULL') %>% 
  mutate(valeur_2 = stringr::str_replace(valeur, ".*value = \"(.+?)\".*", "\\1")) %>% 
  mutate(variable = stringr::str_remove(variable, "xs:")) %>% 
  filter(variable %in% c('maxLength', 'minLength', 'pattern', 'base')) %>% 
  select(- valeur) %>% 
  distinct() %>% 
  ungroup() %>% 
  #mutate(name = substr(name, 5, nchar(name))) %>% 
  tidyr::spread(variable, valeur_2, fill = "") %>% 
  mutate(base = stringr::str_remove(base, 'xs:'))


resultat <- left_join(simpleType, pivot, by = c("name" = "type")) %>% 
  left_join(rangs, by = c('name.y' = 'V2')) %>% 
  mutate(V3 = as.integer(as.character(V3)))

