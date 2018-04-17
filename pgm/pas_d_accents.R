library(dplyr, warn.conflicts = FALSE)


recap <- function(file_in){
  temp <- readr::read_rds(file_in)
  file_out <- stringr::str_replace(file_in, '\\.rds', '_ascii\\.csv')
  
  temp_ <- temp %>% 
    mutate_if(is.character, iconv, from = "UTF-8", to = "ASCII//TRANSLIT") %>% 
    mutate_if(is.character, stringr::str_replace, pattern = ';', replacement = '\\.') %>% 
    mutate_if(is.character, stringr::str_replace, pattern = '\\"|\\°', replacement = ' ') %>% 
    mutate_if(is.character, stringr::str_replace, pattern = '@', replacement = 'A') %>% 
    mutate_if(is.character, stringr::str_replace, pattern = '@', replacement = 'a') %>% 
    mutate_if(is.character, stringr::str_replace, pattern = '€', replacement = 'e')

  readr::write_delim(temp_, file_out , delim = ";", na = "")
}

recap('data_results/etalab_cs1100507_stock_20180129-0428-wgs84.rds')
recap('data_results/etalab_cs1100501_stock_20180129-0431.rds')
