library(dplyr, warn.conflicts = FALSE)

#section1 <- "structureet"
decouper <- function(section1, format, w, labeler = FALSE) {
  cat(paste('-----', section1), sep = "\n")
  temp <- w %>% filter(grepl(section1, l))
  format_ <- format %>% filter(section == section1) %>%
    mutate(name = ifelse(is.na(name), 'V1', name))
  
  if (section1 == 'structureet') {
    # ; en fin de ligne pour cette section, on rajoute une colonne avant de séparer pour éviter les warnings
    
    readr::write_lines(temp$l, 'data_temp/temptemp')
    temp_2 <- readr::read_delim('data_temp/temptemp', na = "NA", delim = ";",
                                col_names = c(format_$name, 'crlf'), 
                                col_types = readr::cols(.default = readr::col_character())) %>% 
      select(-crlf) %>% 
      mutate_at(vars(starts_with('date')), lubridate::as_date)
      
    if (labeler) {
      temp_2 <- sjlabelled::set_label(temp_2, format_$libelle)
    }
    file.remove('data_temp/temptemp')
    return(temp_2 %>% select(-V1))
  } 
  else if (section1 == 'geolocalisation') {
    # pas de ; en fin de ligne pour cette section
    
    readr::write_lines(temp$l, 'data_temp/temptemp')
    temp_2 <- readr::read_delim('data_temp/temptemp', delim = ";", na = "NA",
                                col_names = format_$name, 
                                col_types = readr::cols(.default = readr::col_character()))  %>% 
      mutate_at(vars(starts_with('coord')), as.numeric)  %>% 
      mutate_at(vars(starts_with('date')), lubridate::as_date)
    
    if (labeler) {
      temp_2 <- sjlabelled::set_label(temp_2, format_$libelle)
    }
    file.remove('data_temp/temptemp')
    return(temp_2 %>% select(-V1))
  } 
  else if (section1 == 'structureej') {
    readr::write_lines(temp$l, 'data_temp/temptemp')
    temp_2 <- readr::read_delim('data_temp/temptemp', delim = ";", na = "NA",
                                col_names = c('V1', format_$name), 
                                col_types = readr::cols(.default = readr::col_character()))  %>% 
      mutate_at(vars(starts_with('date')), lubridate::as_date)
    
    if (labeler) {
      temp_2 <- sjlabelled::set_label(temp_2, c('V1 label', format_$libelle))
    }
    file.remove('data_temp/temptemp')
    return(temp_2 %>% select(-V1))
  }

}

# juridique
type_fichier <- 'cs1100501'
# géographique
# type_fichier <- 'cs1100507'

importer <- function(type_fichier){
  cat(paste('--', type_fichier), sep = "\n")
# fichier le plus récent du type précisé
f <- list.files('data_origine/') %>% 
  .[grepl('csv', .)] %>% 
  .[grepl(type_fichier, .)] %>% 
  sort(decreasing = TRUE) %>% 
  .[1]

# lire la date dans le fichier
dt <- stringr::str_extract(f, '[0-9]{8}')
format <- readr::read_delim(paste0('data_results/formats/format_etalab', 
                                  type_fichier, '.csv'), delim = ";",
                           locale = readr::locale(encoding = "latin1"),
                           col_types = readr::cols(
                             type = readr::col_character(),
                             base = readr::col_character(),
                             pattern = readr::col_character(),
                             maxLength = readr::col_integer(),
                             minLength = readr::col_integer(),
                             enumeration = readr::col_character(),
                             name = readr::col_character(),
                             nillable = readr::col_character(),
                             minOccurs = readr::col_integer(),
                             maxOccurs = readr::col_integer(),
                             section = readr::col_character(),
                             libelle = readr::col_character()
                           ))

sections <- unique(format$section)

# lire le fichier
w <- tibble(l = readr::read_lines(file.path('data_origine', f), 
                                  locale = readr::locale(encoding = "latin1")))

bases <- sections %>% purrr::map(decouper, format, w, labeler = TRUE)

# nom du fichier rds de sortie
fout <- stringr::str_replace(f, '\\.csv', '\\.rds')


if (type_fichier == 'cs1100507') {
  # Cas finess et
  res <-
    bases %>% purrr::reduce(left_join, by = 'nofinesset', suffix = paste0('_', sections))
} else if (type_fichier == 'cs1100501') {
  # Cas finess ej
  res <- bases[[1]]

}

readr::write_rds(res, paste0('data_results/', fout))
readr::write_delim(res, paste0('data_results/', f), delim = ";", na = "")

return(res)
}

res <- importer('cs1100501')
res <- importer('cs1100507')

