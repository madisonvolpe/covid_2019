library(tidyverse)

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
    k <- ex_1 %>%
      mutate(State_Detailed = ifelse(str_detect(`Province/State`, ",") & !is.na(`Province/State`),
                                     gsub(".*,","", `Province/State`), `Province/State`)) %>%
      mutate(City_County = ifelse(str_detect(`Province/State`, ",") & !is.na(`Province/State`),
                                  gsub(",.*$", "",`Province/State`), NA)) ## washington dc case 
    
    tets <- all_dat %>% 
      map(chg_col_map) %>%
      map(to_date, patrn = "Date") %>%
      map(remove_patrn, "Country_Region", "\\*")
    
   
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    ### 
    # l <- map_df(all_dat, function(x) unique(x["Country/Region"]))
    # 
    # chk <- l %>% 
    #   group_by(`Country/Region`) %>%
    #   summarise(n=n()) %>%
    #   arrange(`Country/Region`)
    # 
