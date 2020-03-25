library(tidyverse)

## function - that adds event type to each dataset
## .x represents the df in the list, while .y would be a vector of names
## corresponding to each dataset.
## eg - .x[1] is the Confirmed df, so .y[1] = 'Confirmed' 
event_name <- as_mapper(~mutate(.x, Event = .y))

## function - that transforms each df from wide to long
## .x represents each dataframe, while key represents the name
## of the column that we are brining from wide to long
## value represents the name of the column for the values corresponding to key column
wide_to_long <- as_mapper(~gather(data = .x, key = "event_date", value = "event_amt", matches("^\\d+\\/\\d+\\/\\d+$")))

## function that changes column names 
chg_col_names <- function(x){names(x) <- c("province_state", "country_region", "lat", "long", 
                                           "event", "event_date", "event_amt")
return(x)
}

chg_col_map <- as_mapper(~chg_col_names(.x))

## function that changes variables that match 'patrn' to date format 
to_date <- function(x, patrn){ 
  
  x <- x %>% mutate_at(vars(matches(patrn)), lubridate::mdy)
  
}

## function that removes unnecessary patterns from
## desired columns 
remove_patrn <- function(x, clmn, patrn){
  
  x[[clmn]] <- gsub(patrn, "", x[[clmn]])
  return(x)  
}

## function that creates more detailed geographic indicators
detailed_location <- function(df){
  
  df_new <- df %>%
    mutate(province_state = ifelse(province_state == "Washington, D.C.", 
                                   "Washington DC", province_state)) %>%
    mutate(state_detailed = trimws(ifelse(str_detect(province_state, ",") & !is.na(province_state),
                                          gsub(".*,", "", province_state), province_state))) %>%
    mutate(city_county = trimws(ifelse(str_detect(province_state, ",") & !is.na(province_state),
                                       gsub(",.*$", "", province_state), NA)))
  
}
