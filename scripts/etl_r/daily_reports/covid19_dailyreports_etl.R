library(tidyverse)
library(rvest)

##  save links as these may change 
covid_dailyreports <- "https://github.com/CSSEGISandData/COVID-19/tree/master/csse_covid_19_data/csse_covid_19_daily_reports"
x_path_href <- "//td[@class='content']/span/a"
x_path_data_table <- "//table[@class = 'js-csv-data csv-data js-file-line-container']"

## import functions
source("./scripts/etl_r/daily_reports/covid_daily_report_functions.R")


## Step one: Extract

    covid_links <- get_covid_links(covid_dailyreports, x_path_href)
    covid_data <-  purrr::map(covid_links, get_covid_df, x_path = x_path_data_table)
