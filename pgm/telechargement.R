
library(dplyr, warn.conflicts = FALSE)
# library(xml2)
library(rvest)
library(httr)

url_et <- "https://www.data.gouv.fr/fr/datasets/finess-extraction-du-fichier-des-etablissements/"

urls_fic <- read_html(url_et) %>% 
  html_nodes('*') %>% 
  html_attr('href') %>% 
  .[grepl('etalab_cs', .)]


f <- stringr::str_split(urls_fic, '\\/') %>% purrr::map(function(l){l[8]})
d <- stringr::str_extract_all(urls_fic, '[0-9]{8}\\-[0-9]{6}')

1:length(urls_fic) %>% 
  purrr::map(function(i){
  GET(urls_fic[i], write_disk(file.path('data_origine', f[i]), overwrite = TRUE))})
