library(dplyr, warn.conflicts = FALSE)

type_fichier <- 'cs1100507'

# fichier le plus récent du type précisé
f <- list.files('data_origine/') %>% 
  .[grepl('csv', .)] %>% 
  .[grepl(type_fichier, .)] %>% 
  sort(decreasing = TRUE)
  
dt <- stringr::str_extract(f, '[0-9]{8}')
format <- readr::read_csv2(paste0('data_results/formats/format_etalab', 
                                     type_fichier, '.csv'), 
                           locale = readr::locale(encoding = "latin1"))
sections <- unique(format$section)


# lire le fichier
w <- tibble(l = readr::read_lines(file.path('data_origine', f), 
                                  locale = readr::locale(encoding = "latin1")))

u <- function(section1, labeler = FALSE){
  temp <- w %>% filter(grepl(section1, l))
  format_ <- format %>% filter(section == section1) %>% 
    mutate(name = ifelse(is.na(name), 'V1', name))
  
  if (section1 == 'structure_et'){
    # ; en fin de ligne pour cette section, on rajoute une colonne avant de séparer pour éviter les warnings
  temp_2 <- temp %>% tidyr::separate(l, into = c(format_$name, 'crlf'), sep = ";") %>% select(-crlf)
  } else if (section1 == 'geolocalisation'){
    # pas de ; en fin de ligne pour cette section
    temp_2 <- temp %>% tidyr::separate(l, into = format_$name, sep = ";")
  }
  
  
  if (labeler){
    temp_2 <- sjlabelled::set_label(temp_2, format_$libelle)
  }
  return(temp_2 %>% select(-V1))
}

bases <- sections %>% purrr::map(u, labeler = TRUE)

finess_et <- bases %>% purrr::reduce(left_join, by = 'nofinesset', suffix = paste0('_', sections))
glimpse(sample_n(finess_et, 40))

fout <- stringr::str_replace(f, '\\.csv', '\\.rds')

readr::write_rds(finess_et, paste0('data_results/', fout))
