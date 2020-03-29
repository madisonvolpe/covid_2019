CREATE TABLE covid_data(
province_state text,
country_region text NOT NULL,
last_update timestamp NOT NULL,
confirmed numeric,
deaths numeric,
recovered numeric,
lat numeric,
long numeric,
fps numeric,
admin2 text,
active numeric,
combined_key text,
UNIQUE(province_state, country_region, last_update)
); 
