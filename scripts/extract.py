
# coding: utf-8

# In[ ]:


import numpy as np
import pandas as pd

# save links only edit once -- if they change
confirmed = "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_19-covid-Confirmed.csv"
deaths = "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_19-covid-Deaths.csv"
recovered = "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_19-covid-Recovered.csv"

links_list = [confirmed, deaths, recovered]

# use list comp to read links 
list_dat = [pd.read_csv(link) for link in links_list]

