# https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_daily_reports/01-23-2020.csv
# 
# a class = 'js-navigation-open'
# 
# once on page 
# table class = 'js-csv-data csv-data js-file-line-container'

library(tidyverse)
library(rvest)

link <- "https://github.com/CSSEGISandData/COVID-19/tree/master/csse_covid_19_data/csse_covid_19_daily_reports"

test <- link %>%
  read_html() %>%
  html_nodes(xpath = "//td[@class='content']/span/a") %>%
  html_attr("href") %>%
  keep(~str_detect(.x, ".csv$"))

  ex <- paste0("https://github.com", test[1])


  
df_extracted <- ex %>%
                  read_html() %>%
                  html_nodes(xpath = "//table[@class = 'js-csv-data csv-data js-file-line-container']") %>%
                  html_table() %>%
                  as.data.frame() %>%
                  discard(~sum(is.na(.x)) == length(.x))

df_extracted_titles <- unlist(head(df_extracted, 1))
names(df_extracted_titles) <- NULL

df_extracted %>%
  slice(2:n()) %>%
  set_names(df_extracted_titles)
  
   
   
  #set_names(~as.vector(map_chr(~head(.x,1))))
  


    
    
  
  
  






