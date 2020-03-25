## Load Libraries 
library(tidyverse)
library(DBI)
library(RPostgreSQL)
library(rstudioapi)

  ## Step One - Extract
    
    ## saving links from github 
    confirmed <- "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_19-covid-Confirmed.csv"
    recovered <- "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_19-covid-Recovered.csv"
    deaths <- "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_19-covid-Deaths.csv"
    dat <- c(confirmed, recovered, deaths)
    
    ## extracting names from github links
    extract_name <- as_mapper(~str_extract(.x, "Confirmed|Recovered|Deaths"))
    
    ## mapping over each link -> reading the csv -> setting list name to be variable extracted from link
    all_dat <- purrr::map(dat, readr::read_csv) %>% set_names(map_chr(dat, extract_name))
    
  ## Step Two - Transforming Data 
    
    ## load in functions
    source('./scripts/etl_r/etl_func.R')
    
    ## A - Add an event column to identify what the data is measuring (Confirmed cases, Deaths, Recovered)
    list_names <- names(all_dat)
    all_dat   <- map2(all_dat, list_names, event_name)
    
    ## B - transforming datasets from wide to long format 
    all_dat      <- all_dat %>% map(wide_to_long)
    
    ## C - cleaning/variable creation 
    transformed_data <- all_dat %>% 
      map(chg_col_map) %>%
      map(to_date, patrn = "event_date") %>%
      map(remove_patrn, "country_region", "\\*") %>%
      map(remove_patrn, "country_region", "'") %>%
      map(remove_patrn, "province_state", "'") %>%
      map(detailed_location)
  
  ## cleaning up global environment
  rm(list=ls(pattern = "[^transformed_cases]"))
  
  ## Pre - Load 
    
    ## prepare data to be written like INSERT statement in SQL
    ## code adapted from https://www.pmg.com/blog/insert-r-data-frame-sql%EF%BB%BF/
    
    ## must convert NAs in numeric column to NaN first 
    na_to_null <- function(df, col){
                df[[col]] <- ifelse(is.na(df[[col]]), "NULL", df[[col]])
                return(df)
    }  
    
    # not_quoted_null <- function(df){
    #   for(i in 1:nrow(df)){
    #     for(j in seq_along(df)){
    #       if(is.element(df[i,j], "NULL")){
    #         df[i,j] <- df[i,j]
    #       } else if (is.na(df[i,j])){
    #         df[i,j] <- paste0("'", df[i,j], "'")
    #       } else {
    #         df[i,j] <- df[i,j]
    #       }
    #     }
    #   }
    #   return(df)
    # } # not optimized function 
    
    # optimized function
    not_quoted_null <- function(df){
     
     df <- df %>%
        mutate(event_date = as.character(event_date)) %>%
        mutate_all(., 
                   list(~case_when(
                     . == "NULL" ~ "NULL",
                     is.na(.) ~ paste0("'", NA, "'"),
                     . != "NULL" & !is.na(.)~ paste0("'", . ,"'")
      )))
    
     return(df)
    }
    
    trans_to_sql <- function(df){
    
      trans1 <- not_quoted_null(df)
      trans2 <- apply(trans1, 1, function(x) paste0(x, collapse = ","))
      trans3 <- paste0("(", trans2, ")")
      trans4 <- paste0(trans3, collapse = " ,")
      
      return(trans4)
    }
    
    transformed_data <- purrr::map(transformed_data, ~na_to_null(.x, "event_amt"))
    to_insert <- purrr::map(transformed_data, trans_to_sql)
 
    confirmed_query <- paste0("INSERT INTO confirmed VALUES", to_insert$Confirmed, " ON CONFLICT (province_state, country_region, event_date) DO NOTHING;")
    recovered_query <- paste0("INSERT INTO recovered VALUES", to_insert$Recovered, " ON CONFLICT (province_state, country_region, event_date) DO NOTHING;")
    deaths_query <- paste0("INSERT INTO deaths VALUES", to_insert$Deaths, " ON CONFLICT (province_state, country_region, event_date) DO NOTHING;")
    
  ## Step 3 - LOAD
    
    ## Connect to postgres database
    db_user <- Sys.getenv("user")
    db_password <- Sys.getenv("password")
    
    pg = dbDriver("PostgreSQL")
    con = dbConnect(pg, user = db_user , password = db_password, host = 'localhost', port = 5432, dbname = "covid_2019_r_db")
    
    ## loading confirmed data
    dbSendQuery(con, confirmed_query)
    ## loading recovered data
    dbSendQuery(con, recovered_query)
    ## loading deaths data
    dbSendQuery(con, deaths_query)
    