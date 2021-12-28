#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Author: Josiah Kim
Class: SODA 496
Title: VK Assignment #1
    
"""


#%%
# Import packages, credentials, start VK api

import os 
import vk
import matplotlib.pyplot as plt
import datetime as time 

os.chdir("/Users/josiahkim/Desktop/SODA496")

import creds

session = vk.AuthSession(creds.appid, creds.user,creds.password)
api = vk.API(session, v='5.92')


#%%
# Choose a VK page other than the one we have been working with

titov = api.users.get(user_ids = "bytitov")
##print(titov)

#%%
# Get the numerical id for that account

titov_id = titov[0]["id"]
##print(titov_id)

#%%
# Pull 100 posts from the wall of that account
posts = api.wall.get(owner_id=titov_id, count=100, filter="owner")
##print(posts)


#%%
# Explore the data structure that comes back, 
# and select a measure of engagement that is 
# different from the one we have been working with in class

print(posts["items"][0])

# Engagement measure is the number of comments

print(posts["items"][0]["comments"]["count"])



#%%
# Store the date and your engagement measure 
# for each post to a new dictionary or dataframe

dateEngagement = {"dates":[x["date"] \
                          for x in posts["items"]\
                              if "comments" in x],
                  "comments": [x["comments"]["count"] \
                               for x in posts["items"]\
                      if "comments" in x]}


#%%
# Plot a time series of that measure of engagement
"""Make sure that in your plot you:
Convert epoch time to a more conventional date format
Customize the plot to make it more aesthetic, including adding or customizing:
The title and axis labels
Line color, thickness, type, and opaqueness
Make sure that you research and add an option/argument that we did not go over in class
Submit a py file and a plot"""

# Add a new key to dateEngagement called dateTime for epoch conversion
dateEngagement["dateTime"] = [time.datetime.fromtimestamp(x) \
                              for x in dateEngagement["dates"]]
# Create frame for the plot    
finalPlot, titovPlot = plt.subplots(1)

# Plot data with options
titovPlot.plot("dateTime", "comments", color = "tomato",\
         linestyle = "dashdot", linewidth = 2, \
             alpha = 0.7, label = "Titov",data = dateEngagement)

# Add Title
titovPlot.set_title("Engagement on 100 of Titov's Posts Over Time")

# Add X Label
titovPlot.set_xlabel("Time")

# Add Y Label
titovPlot.set_ylabel("Number of Comments")

# Add Legend
titovPlot.legend(loc=0)

































