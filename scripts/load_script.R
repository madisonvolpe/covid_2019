library(tidyverse)

## Extracting data from github 

confirmed <- "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_19-covid-Confirmed.csv"
recovered <- "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_19-covid-Recovered.csv"
deaths <- "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_19-covid-Deaths.csv"
dat <- c(confirmed, recovered, deaths)

extract_name <- as_mapper(~str_extract(.x, "Confirmed|Recovered|Deaths"))

all_dat <- purrr::map(dat, readr::read_csv) %>% set_names(map_chr(dat, extract_name))

## Transforming data for database

## Step 1 - Add column to identify event (Confirmed, Recovered, Death)
## Step 2 - Convert from wide to long format 
## Step 3 - Any cleaning/creation of new variables along the way 

## Step 1 
list_names <- names(all_dat)
event_name <- as_mapper(~mutate(.x, Event = .y))
all_dat   <- map2(all_dat, list_names, event_name)

## Step 2 
wide_to_long <- as_mapper(~gather(data = .x, key = "Date", value = "Event_Amt", matches("^\\d+\\/\\d+\\/\\d+$")))
all_dat      <- all_dat %>% map(wide_to_long)

## Step 3 

## change col_names 
chg_col_names <- function(x){names(x) <- c("Province_State", "Country_Region", "Lat", "Long", 
                                           "Event", "Date", "Event_Amt")
return(x)
}

chg_col_map <- as_mapper(~chg_col_names(.x))

## convert Date column  to date type 
to_date <- function(x, patrn){ 
  
  x <- x %>% mutate_at(vars(matches(patrn)), lubridate::mdy)
  
}

## remove unecessary patterns from column
remove_patrn <- function(x, clmn, patrn){
  
  x[[clmn]] <- gsub(patrn, "", x[[clmn]])
  return(x)  
}

## create more detailed Province, State, City, Indicator

detailed_location <- function(df){
  
  df_new <- df %>%
    mutate(Province_State = ifelse(Province_State == "Washington, D.C.", 
                                   "Washington DC", Province_State)) %>%
    mutate(State_Detailed = trimws(ifelse(str_detect(Province_State, ",") & !is.na(Province_State),
                                          gsub(".*,", "", Province_State), Province_State))) %>%
    mutate(City_County = trimws(ifelse(str_detect(Province_State, ",") & !is.na(Province_State),
                                       gsub(",.*$", "", Province_State), NA)))
  
}


transformed_data <- all_dat %>% 
  map(chg_col_map) %>%
  map(to_date, patrn = "Date") %>%
  map(remove_patrn, "Country_Region", "\\*") %>%
  map(detailed_location)

## Loading data to database
library(DBI)
library(RPostgreSQL)
library(rstudioapi)

## Connect to postgres database
db_user <- Sys.getenv("user")
db_password <- Sys.getenv("password")

pg = dbDriver("PostgreSQL")
con = dbConnect(pg, user = db_user , password = db_password, host = 'localhost', port = 5432, dbname = "covid_2019")

dbListTables(con)

dbWriteTable(con, "confirmed_cases", transformed_data$Confirmed, row.names = FALSE, append = TRUE)
dbWriteTable(con, "deaths", transformed_data$Deaths, row.names = FALSE, append = TRUE)
dbWriteTable(con, "recovered_cases", transformed_data$Recovered, row.names = FALSE, append = TRUE)

dbGetQuery(con, "SELECT COUNT(*) FROM confirmed_cases")
