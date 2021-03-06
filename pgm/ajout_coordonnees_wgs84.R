

finess_et <- readr::read_rds('data_results/etalab-cs1100507-stock-20200304-0416.rds')

convertir_proj <- function(p){
  
  if (p != ""){
  convert_string <- case_when(
   #p == 'LAMBERT_93' ~ "+proj=lcc +lat_1=44 +lat_2=49+lat_0=46.5 +lon_0=3 +x_0=700000 +y_0=6600000 +towgs84=0,0,0,0,0,0,0 +ellps=GRS80 +units=m +no_defs",
   p == 'LAMBERT_93' ~ "+init=epsg:2154",
   p == 'UTM_N20'    ~ "+proj=utm +zone=20 +datum=WGS84",
   p == 'UTM_N21'    ~ "+proj=utm +zone=21 +datum=WGS84",
   p == 'UTM_N22'    ~ "+proj=utm +zone=22 +datum=WGS84",
   p == 'UTM_S38'    ~ "+proj=utm +zone=38 +south +datum=WGS84",
   p == 'UTM_S40'    ~ "+proj=utm +zone=40 +south +datum=WGS84"
  )
  
  temp <- finess_et %>% filter(grepl(p, sourcecoordet))
  geoc<- temp %>% select(lon = coordxet, lat = coordyet)
  sp::coordinates(geoc) <- ~ lon + lat
  sp::proj4string(geoc) <- sp::CRS(convert_string)
  geoc<-sp::spTransform(geoc, sp::CRS("+init=epsg:4326"))
  geoc2 <- geoc@coords
  temp <- cbind(temp,geoc2)
  } 
  else if (p == ""){
    temp <- finess_et %>% filter(sourcecoordet == "") %>% 
      mutate(lat = NA, lon = NA)
  }
  
  as_tibble(temp)
}

finess_et %>% 
  select(sourcecoordet) %>% 
  mutate(proj = stringr::str_split_fixed(sourcecoordet, ",", n = 7)[,7]) %>% 
  count(proj) %>% 
  pull(proj) -> projs

finess_et_wgs84 <- projs %>% purrr::map(convertir_proj) %>% bind_rows() %>% 
  dplyr::arrange(nofinesset, nofinessej)

readr::write_rds(finess_et_wgs84, 'data_results/etalab-cs1100507-stock-20200304-0416-wgs84.rds')
readr::write_delim(finess_et_wgs84, 'data_results/etalab-cs1100507-stock-20200304-0416-wgs84.csv', delim = ";", na = "")
