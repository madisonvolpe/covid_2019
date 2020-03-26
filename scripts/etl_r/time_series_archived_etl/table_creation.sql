CREATE TABLE confirmed(
province_state text,
country_region text,
lat numeric,
long numeric,
event text,
event_date date,
event_amt numeric,
state_detailed text,
city_county text,
UNIQUE(province_state, country_region, event_date)
);

CREATE TABLE recovered(
province_state text,
country_region text,
lat numeric,
long numeric,
event text,
event_date date,
event_amt numeric,
state_detailed text,
city_county text,
UNIQUE(province_state, country_region, event_date)
);

CREATE TABLE deaths(
province_state text,
country_region text,
lat numeric,
long numeric,
event text,
event_date date,
event_amt numeric,
state_detailed text,
city_county text,
UNIQUE(province_state, country_region, event_date)
);
