#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Apr 12 15:03:16 2021

@author: josiahkim
"""

#%%
# Import packages and change WD
import requests
import pandas as pd
import os 
from bs4 import BeautifulSoup
import re

os.chdir("/Users/josiahkim/Desktop/SODA496")



#%%
# Dictionary with the ending url as key and country as value
electionDict = {"_Romanian_general_election": "Romania", 
                 "_Turkmenistan_presidential_election": "Turkmenistan",
                 "_Panamanian_general_election": "Panama", 
                 "_Zimbabwean_general_election": "Zimbabwe",
                 "_Central_African_presidential_election": "Central African Republic",
                 "_São_Toméan_presidential_election": "Sao Tome and Principe",
                 "_Albanian_parliamentary_election": "Albania",
                 "_Spanish_Guinean_general_election":"Equatorial Guinea",
                 "_Malawian_general_election": "Malawi",
                 "_Yemeni_presidential_election": "Yemen"}

# All the ending urls for each country's election
electionLinks = ["_Romanian_general_election", 
                 "_Turkmenistan_presidential_election",
                 "_Panamanian_general_election", 
                 "_Zimbabwean_general_election",
                 "_Central_African_presidential_election",
                 "_São_Toméan_presidential_election",
                 "_Albanian_parliamentary_election",
                 "_Spanish_Guinean_general_election",
                 "_Malawian_general_election",
                 "_Yemeni_presidential_election"]

# Main dataframe to be exported to CSV 
countrydf = pd.DataFrame(columns = ["country", "year", "coalition"])

# Helper functions
def checkExist(tempsoup):
    return (bool(tempsoup.body.find_all(text = \
                        re.compile('does not have an article'))))
def checkCoalition(tempsoup):
    if bool(tempsoup.body.find_all(text = re.compile('coalition'))):
        return 1
    else: 
        return 0
# End helper functions

# Start main nested loops 
for link in electionLinks:
    for year in range(1990, 2022):
        year = str(year)
        url = "https://en.wikipedia.org/wiki/"+year+link
        temprequest = requests.get(url)
        tempsoup = BeautifulSoup(temprequest.text, "html.parser")
        if not checkExist(tempsoup):
            tempdf = pd.DataFrame({"country": electionDict[link],
                                   "year": [int(year)],
                                   "coalition":[checkCoalition(tempsoup)]})
            countrydf = countrydf.append(tempdf)
# End main nested loops 

# Export to CSV
countrydf.to_csv("josiahcountrydata.csv", index = False)
    





