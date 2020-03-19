library(tidyverse)

## Reading COVID-2019 Time Series Data from John Hopkins CSSE 
## Will use purrr to read the 3 separate csvs for Confirmed, Deaths, and Recovered 
  
  # save csv files as variables, will be useful in case link to data changes on github 
  confirmed <- "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_19-covid-Confirmed.csv"
  recovered <- "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_19-covid-Recovered.csv"
  deaths <- "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_19-covid-Deaths.csv"
  
      # save the 3 links in a vector to iterate through later using purrr
      dat <- c(confirmed, recovered, deaths)
  
      # create mapper to extract dataset name from link 
      extract_name <- as_mapper(~str_extract(.x, "Confirmed|Recovered|Deaths"))
  
  # read datasets using purrr and then name dataset using extract_name mapper
  all_dat <- purrr::map(dat, readr::read_csv) %>% set_names(map_chr(dat, extract_name))
  