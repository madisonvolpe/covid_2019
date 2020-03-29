library(tidyverse)
library(rvest)

## Extraction phase 

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

## Transformation phase

### Function 3: takes df extracts names and then edits the names so that they match, doing this so dataframes could be 
### combined 

standardize_names <- function(df){
  
  # take out column names and apply operations to them
  names_df <- names(df)
  
  names_df <- tolower(names_df)
  names_df <- str_replace(names_df,"\\/", "_")
  names_df <- str_replace(names_df,"_$", "")
  names_df <- trimws(names_df)
  names_df <- str_replace(names_df, "\\s+", "_")
  
  names_df[grepl("^lat", names_df)] <- "lat"
  names_df[grepl("^long", names_df)] <- "long"
  
  names(df) <- names_df
  
  return(df)
}

### Function 4: covid_df - take list and create one dataframe

covid_df <- function(list){
  
  df <- bind_rows(list)
  
  return(df)
}

### Function 5: from df it removes all ' (apostrophe) and replaces with blank space, this is done so data 
### could be inserted into SQL database 
### this should be applied to all columns, so it works best with map_df

remove_apostrophe <- as_mapper(~str_replace_all(.x, "'", ""))




## Load phase

### Function 6a: converts NA and blank values to NULL for SQL puproses

na_blank_tonull <- function(col){

  for(i in 1:length(col)){
    if(is.na(col[i])){
      col[i] <- "NULL"
    } else if(is.element(col[i], "")){
      col[i] <- "NULL"
    } else {
      col[i] <- col[i]
    }
  }
return(col)
}

#### Function 6b: the first column cannot be NULL bc of the UNIQUE CONSTRAINT convert back to blank 

constraint_blank <- function(df,pat){
  
  df <- df %>% mutate_at(vars(matches(pat)), ~ "' '")
  
  return(df)
}

### Function 7: NULLs should not be quoted, but everything else should be when writing insert
### statement from R to SQL

quote_to_sql <- function(col){
  
  for(i in 1:length(col)){
    if(is.element(col[i], "NULL")){
      col[i] <- col[i]
    } else {
      col[i] <- paste("'", col[i], "'")
    } 
  }
  return(col)
}


### Function 8: Final transformation before SQL, collapse each row into its own vector... 

row_to_sql <- function(df){
  
  trans1 <- apply(df, 1, function(x) paste0(x, collapse = ","))
  trans2 <- paste0("(", trans1, ")")
  trans3 <- paste0(trans2, collapse = ",")
  
  return(trans3)
  
}
  
  


    
    
    



## Useful to keep (tests)
# test <- unlist(map(covid_data, ~names(standardize_names(.x))))
# unique(test)
## punctuation in all 
# map(covid_data_df, ~table(unlist(str_extract_all(.x, "[[:punct:]]"))))
# map(map_df(covid_data_df, ~str_replace_all(.x,"'","")),~table(unlist(str_extract_all(.x, "[[:punct:]]"))))
  

