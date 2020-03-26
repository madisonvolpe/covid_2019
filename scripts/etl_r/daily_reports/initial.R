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
  keep(~str_detect(.x, ".csv$")) %>%
  paste0("https://github.com", .)



test %>% map(get_covid_df, x_path = "//table[@class = 'js-csv-data csv-data js-file-line-container']")



get_covid_df <- function(df, x_path){
  
df_extracted <-   df %>%
                    read_html() %>%
                    html_nodes(xpath = x_path) %>%
                    html_table() %>%
                    as.data.frame() %>% 
                    discard(~sum(is.na(.x)) == length(.x))

df_extracted_titles <- unlist(head(df_extracted, 1))
names(df_extracted_titles) <- NULL

df_final <- df_extracted %>%
              slice(2:n()) %>%
              set_names(df_extracted_titles)

return(df_final)
  
}


"//table[@class = 'js-csv-data csv-data js-file-line-container']"

  





    
    
  
  
  






