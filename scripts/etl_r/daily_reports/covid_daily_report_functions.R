library(tidyverse)
library(rvest)

## Function 1: get_covid_links()
## takes link to github folder with daily report csvs as an argument 
## then it extracts the hrefs to all individuals csvs, which then can 
## be navigated to, in order to extract data for each day 

get_covid_links <- function(link, x_path){
  
links <- link %>%
              read_html() %>%
              html_nodes(xpath = x_path) %>%
              html_attr("href") %>%
              keep(~str_detect(.x, ".csv$")) %>%
              paste0("https://github.com", .)

return(links)  

}

## Function 2: get_covid_df()
## takes link returned from get_covid_links and then extracts the data table from each link
## after the tables are cleaned 
## this function is created to work with purrr::map

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
