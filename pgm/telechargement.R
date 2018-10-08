
library(dplyr, warn.conflicts = FALSE)
# library(xml2)
library(rvest)
library(httr)

url_et <- "https://www.data.gouv.fr/fr/datasets/finess-extraction-du-fichier-des-etablissements/"

# urls_fic <- read_html(url_et) %>% 
#   html_nodes('*') %>% 
#   html_attr('href') %>% 
#   .[grepl('etalab_cs', .)]

urls_fic <- jsonlite::read_json('https://www.data.gouv.fr/api/1/datasets/53699569a3a729239d2046eb') %>% 
  .$resources %>% 
  purrr::map('url') %>% 
  purrr::flatten_chr()



f <- stringr::str_split(urls_fic, '\\/') %>% purrr::map(function(l){l[length(l)]})
d <- stringr::str_extract_all(urls_fic, '[0-9]{8}\\-[0-9]{6}')

1:length(urls_fic) %>% 
  purrr::map(function(i){
  GET(urls_fic[i], write_disk(file.path('data_origine', f[i]), overwrite = TRUE))})

url_ej <- "https://www.data.gouv.fr/fr/datasets/finess-extraction-des-entites-juridiques/#_"
# urls_fic <- read_html(url_ej) %>% 
#   html_nodes('*') %>% 
#   html_attr('href') %>% 
#   .[grepl('etalab_cs', .)]

urls_fic <- jsonlite::read_json('https://www.data.gouv.fr/api/1/datasets/5369956ba3a729239d2046fc') %>% 
  .$resources %>% 
  purrr::map('url') %>% 
  purrr::flatten_chr()

urls_fic <- urls_fic %>% .[grepl('csv$', .)]
f <- stringr::str_split(urls_fic, '\\/') %>% purrr::map(function(l){l[length(l)]}) %>% purrr::flatten_chr()


1:length(urls_fic) %>% 
  purrr::map(function(i){
    GET(urls_fic[i], write_disk(file.path('data_origine', f[i]), overwrite = TRUE))})


# telechargement notice pdf statique pour les ej
GET('http://static.data.gouv.fr/de/a0180358fc250d40408519e76a2c7a020731624a129330773aceecaae64416.pdf',
    write_disk(file.path('data_origine', 'etalab_cs1100501.pdf')))
    