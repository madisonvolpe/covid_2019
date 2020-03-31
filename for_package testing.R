get_covid_links <- function(link, month, year){
  
  links <- link %>%
    read_html() %>%
    html_nodes(xpath = "//td[@class='content']/span/a") %>%
    html_attr("href") %>%
    keep(~str_detect(.x, ".csv$")) %>%
    paste0("https://github.com", .)
  
  links <- data.frame(link = links, stringsAsFactors = FALSE)
  links <- mutate(links, link_date = lubridate::mdy(str_extract(link, "\\d{2}-\\d{2}-\\d{4}")))
  
  if(missing(month) & missing(year)){
    
    links <- links
    
  } else {
    
    links <- filter(links, lubridate::month(link_date) %in% month & lubridate::year(link_date) %in% year)
    
  }
  
  if(nrow(links)>0){
    links
  } else {
    warning('Please enter valid month and/or year')
  }
  
  list_covid_df <- map(links$link, links_to_df)
  
  return(list_covid_df)
  
}

# Internal function

#' Convert a github webpage link to df
#' @param link_df a charater string representing a github link
#' @NoRd

links_to_df <- function(link_df){
  
  df_extracted <-   link_df %>%
    xml2::read_html() %>%
    rvest::html_nodes(xpath = "//table[@class = 'js-csv-data csv-data js-file-line-container']") %>%
    rvest::html_table() %>%
    as.data.frame() %>% 
    discard(~sum(is.na(.x)) == length(.x))
  
  df_extracted_titles <- unlist(head(df_extracted, 1))
  names(df_extracted_titles) <- NULL
  
  df_final <- df_extracted %>%
    slice(2:n()) %>%
    set_names(df_extracted_titles)
  
  return(df_final)
  
}





covid_links <- get_covid_links(covid_dailyreports, month = c(1,2), year = c(2019,2020))
