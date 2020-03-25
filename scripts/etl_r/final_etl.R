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
    
    to_insert <- purrr::map(transformed_data, ~paste0(apply(.x, 1, function(x) paste0("('", paste0(x, collapse = "', '"), "')")),
                                       collapse = ", "))
    
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
    