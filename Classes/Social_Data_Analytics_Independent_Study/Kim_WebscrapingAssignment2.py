#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Apr 27 21:16:28 2021

@author: josiahkim
"""

"""For the second classwork assignment in this project you must:

1) Submit a py file that collects elections results data from Wikipedia for 
    every election that occurred in every country assigned to you between the 
    years 1990 and 2021, and stores this to a pandas data frame with columns: 
        country, year, party, votes, and percent.

Here are your assigned countries from class (these are the same as assignment 1): first_webscrape_assignment_country_assignments.csv  download  

Please submit both a py file, and a csv of your collected data.
"""

#%%
# Import packages and load data 
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
                 "_Central_African_general_election":"Central African Republic",
                 "_São_Toméan_presidential_election": "Sao Tome and Principe",
                 "_Albanian_parliamentary_election": "Albania",
                 "_Spanish_Guinean_general_election":"Equatorial Guinea",
                 "_Equatorial_Guinean_presidential_election":"Equatorial Guinea",
                 "_Malawian_general_election": "Malawi",
                 "_Yemeni_presidential_election": "Yemen"}

# All the ending urls for each country's election
electionLinks = ["_Romanian_general_election", 
                 "_Turkmenistan_presidential_election",
                 "_Panamanian_general_election", 
                 "_Zimbabwean_general_election",
                 "_Central_African_presidential_election",
                 "_Central_African_general_election", # Add election
                 "_São_Toméan_presidential_election",
                 "_Albanian_parliamentary_election",
                 "_Spanish_Guinean_general_election",
                 "_Equatorial_Guinean_presidential_election", # Add election
                 "_Malawian_general_election",
                 "_Yemeni_presidential_election"]

#%%
# Helper functions
def checkExist(tempsoup):
    return (bool(tempsoup.body.find_all(text = \
                        re.compile('does not have an article'))))

def checkTable(table):
    headers = []
    trs = table.find("tr")    
    for tr in trs:
        try: # Avoid NavigableString error (space in between tags)
            header = tr.text.strip()
            headers.append(header)
        except:
            continue
    if ("Party" in headers) and ("Votes" in headers) and ("%" in headers):
        return True
    else:
        return False 

def getHeaders(table):
    headers = []
    trs = table.find("tr")    
    for tr in trs:
        try:
            header = tr.text.strip()
            headers.append(header)
        except:
            continue
    return headers 

    
#%%
# Main dataframe to be exported to CSV 
countrydf = pd.DataFrame(columns = ["country", "year", "party", "votes", "percent"])

#%%
# Start main nested loops 
for link in electionLinks:
    for year in range(1990, 2022):
        year = str(year)
        url = "https://en.wikipedia.org/wiki/"+year+link
        #print(url)
        temprequest = requests.get(url)
        tempsoup = BeautifulSoup(temprequest.text, "html.parser")
        if not checkExist(tempsoup):
            tables = tempsoup.findAll("table", {"class": "wikitable"}) # Get all instances of wikitables
            for table in tables: 
                if checkTable(table): # Find headers that fit the data frame 
                    trs = table.findAll("tr")
                    headers = getHeaders(table)
                    #print(headers)
                    for tr in trs:
                        try:
                            tds = tr.findAll("td")
                            # Problem: Different tables have different columns
                            # Solution: There are only four different types of tables
                            # so create different dataframes for each table
                            if headers == ['Candidate', 'Party', 'Votes', '%']: 
                                try:
                                    blah1, blah2, party, votes, percent = \
                                        [td.text.strip() for td in tds]
                                except:
                                    continue
                            if headers == ['Party', 'Votes', '%', 'Seats', '+/–']: 
                                try:
                                    blah3, party, votes, percent, blah1, blah2 = \
                                        [td.text.strip() for td in tds]
                                except:
                                    continue
                            if headers == ['Party', 'Votes', '%', 'Seats']:
                                try:
                                    blah2, party, votes, percent, blah1 = \
                                        [td.text.strip() for td in tds]
                                except:
                                    continue
                                #blah = [td.text.strip() for td in tds]
                            if headers == ['Candidate', 'Running mate', 'Party', 'Votes', '%']:
                                try:
                                    blah3, blah1, blah2, party ,votes, percent = \
                                        [td.text.strip() for td in tds]
                                except:
                                    continue
                            tempdf = pd.DataFrame({"country": electionDict[link],
                                                   "year": [int(year)],
                                                   "party": [party],
                                                   "votes": [votes],
                                                   "percent": [percent]
                                                  })
                            countrydf = countrydf.append(tempdf)
                        except:
                            continue
                else:
                    continue
            
#%%
# Export CSV
countrydf.to_csv("josiahcountrydata2.csv", index = False)
                    





