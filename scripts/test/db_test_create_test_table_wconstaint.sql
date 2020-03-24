CREATE TABLE cc(
  province_state text,
  country_region text,
  event text,
  event_date date,
  UNIQUE(province_state, country_region, event_date)
);