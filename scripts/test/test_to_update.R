library(DBI)
library(RPostgreSQL)


## Testing out how to run an UPSERT using Rpostgres SQL. The test database is a 4 row sample db 
## Basically, I envision the UPSERT to be so that anything that matches province_state, country_region, date 
## Do Nothing... only update the most recent dates and any new region added...
## In short, add data only new data! 
## I went through and spot checked to see if they update data from previous dates, but it seems that only the most recent date
## is updated daily. That is why the UPSERT only needs a condition for province_state, country_region, daterm

  ## connnecting to DB
  db_user <- Sys.getenv("user")
  db_password <- Sys.getenv("password")
  
  pg = dbDriver("PostgreSQL")
  con = dbConnect(pg, user = db_user , password = db_password, host = 'localhost', port = 5432, dbname = "test")
  dbListTables(con)


  ex <- dbGetQuery(con, "SELECT * FROM cc")

          ## df I created to insert data into database, so ideally New York, NY, 2019-01-02 &
          ## NA, China, 2019-01-02 should not be included in the db bc they already exist 
          ## the data from 2019-01-03 should be the only data included!
  
          data_to_insert <- data.frame(province_state = c("New York", "New York", NA, NA),
                             country_region = c("NY", "NY", "China", "China"),
                             event = c("Confirmed", "Confirmed", "Confirmed", "Confirmed"),
                             date = c("2019-01-02","2019-01-03", "2019-01-02", "2019-01-03"))

          ## This code I got from :: https://www.pmg.com/blog/insert-r-data-frame-sql%EF%BB%BF/
          values <- paste0(apply(data_to_insert, 1, function(x) paste0("('", paste0(x, collapse = "', '"), "')")), 
                           collapse = ", ")
          
          ## first segment we are inserting values collected 
          part_one <- paste0("INSERT INTO cc VALUES ", values)
          
          ## second segment include the conflict 
          part_two <- ' ON CONFLICT (province_state, country_region, date) DO NOTHING;'

          query <- paste0(part_one, part_two) 
          
          dbSendQuery(con, query)
          