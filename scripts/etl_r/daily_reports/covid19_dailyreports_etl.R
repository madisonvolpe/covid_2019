library(tidyverse)
library(rvest)
library(DBI)
library(RPostgreSQL)

##  save links as these may change 
covid_dailyreports <- "https://github.com/CSSEGISandData/COVID-19/tree/master/csse_covid_19_data/csse_covid_19_daily_reports"
x_path_href <- "//td[@class='content']/span/a"
x_path_data_table <- "//table[@class = 'js-csv-data csv-data js-file-line-container']"

## import functions
source("./scripts/etl_r/daily_reports/covid_daily_report_functions.R")


## Step one: Extract

    covid_links <- get_covid_links(covid_dailyreports, x_path_href)
    covid_data <-  purrr::map(covid_links, get_covid_df, x_path = x_path_data_table)

## Step two: Transform 
    
    ## cleaning 
    # Step One - Standardize column names across datasets
    # Step Two - Remove apsotrophe from all columns  
    # Step Three - Change datetime column to uniform datetime
    # Step Four - Change confirmed, deaths, recovered to numeric 
    
    covid_data <- purrr::map(covid_data, standardize_names)
    covid_data_df <- covid_df(covid_data)
    
    covid_data_df <- covid_data_df %>%
                        map_df(remove_apostrophe) %>%
                        mutate_at(vars(starts_with("last")),
                                    list(~str_replace_all(., "T", " "))) %>% 
                        mutate_at(vars(starts_with("last")),
                                    list(~as.character(lubridate::parse_date_time(.,orders = c('mdy_hm', 'ymd_hms'))))) %>%
                        mutate_at(vars(matches("^conf|^reco|^deat")), as.numeric)
    
    
    
    
## testtttt 

    bahamas <- filter(covid_data_df, str_detect(country_region, "Bahamas")) %>% arrange(last_update)
    bahamas <- map_df(bahamas, na_blank_tonull)
    bahamas <- map_df(bahamas, quote_to_sql)
    bahamas <- constraint_blank(bahamas, "province_state")
    
    bahamas_sql <- row_to_sql(bahamas)
    
    bahamas_sql_query <- paste0("INSERT INTO covid_data VALUES ", bahamas_sql, 
                                " ON CONFLICT (province_state, country_region, last_update) DO NOTHING;")
    
    ## Connect to postgres database
    db_user <- Sys.getenv("user")
    db_password <- Sys.getenv("password")
    
    pg = dbDriver("PostgreSQL")
    con = dbConnect(pg, user = db_user , password = db_password, host = 'localhost', port = 5432, dbname = "bahamas_test")
    
    dbSendQuery(con, bahamas_sql_query)
    
    
    
      
      
    
    