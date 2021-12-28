#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Mar 16 16:16:30 2021

@author: josiahkim
"""

"""
Building a sampling frame

For this assignment, you are being asked to put together the code 
we have been going over and apply it to the page you used in your 
first VK assignment to build a sampling frame of approximately 100,000 
users (minus duplicates) that also contains whatever useful information 
you can gather on those users from VK.  You are required to submit 
a py file and a csv. Your assignment should contain:

- A script that can be run from the command line or imported as a 
function in an IDE that:
        1. Pulls the last 100 posts on your page.
        2. Builds a dataframe of the last 1000 users to like each 
            of the last 100 posts, and drops duplicated users.
        3. Returns useful information about those users.
            1. We have investigated this method a little in class 
                to pull user city and screenname, but you must investigate 
                these options further on the developer page documentation 
                and include requests for additional information that you 
                think would be pertinent to this survey.
- A csv that stores the results of you running your code.
 

You will be graded on the following:

- Do your scripts function (correctly)?

- Have you hit all the elements of the assignment?

- How elegant is your code?
"""

#%%
# Import packages, credentials, start VK api

import os 
import vk
import matplotlib.pyplot as plt
import pandas as pd
import time

os.chdir("/Users/josiahkim/Desktop/SODA496")

import creds

session = vk.AuthSession(creds.appid, creds.user,creds.password)
api = vk.API(session, v='5.92')


#%%
'''
1. Pulls the last 100 posts on your page.

'''

# Helper function to get the user ID number
def getUserID(name):
    id = api.users.get(user_ids = name)
    return(id[0]["id"])


def lastOneHundredPosts(name):
    posts = api.wall.get(owner_id = getUserID(name), 
                         count = 100, filter = "owner")
    return(posts)



#%%
'''
2. Builds a dataframe of the last 1000 users to like each 
            of the last 100 posts, and drops duplicated users.
3. Returns useful information about those users.

'''
def lastOneThousandLikers(name):
    userinfo = pd.DataFrame(columns = ["first", "last", "id", 
                                       "sex", "birth" ,"home", "job"])
    tempList = []
    
    posts = lastOneHundredPosts(name)
    
    for i in posts["items"]:
        if (len(userinfo) >= 1000):
            userinfo = userinfo[0:999]
            break
            
        ll = api.likes.getList(type = "post", 
                               owner_id = getUserID(name),
                               item_id = i["id"])
       
        # Build a temprary list of 1000 users, then send it to users.get() 
        if (len(tempList) <= 1000) and (len(tempList)+len(ll["items"]) <= 1000):
            for z in ll["items"]:    
                tempList.append(z)
            print("I have accumulated", len(tempList), "user ids.")
        
        else:
            info = api.users.get(user_ids = tempList, fields = 
                                 ["sex", "bdate", "home_town", "occupation"])
            
            for x in info:
                # Access dictionaries without the worry of gettting a KeyError
                # This way, there will always be a value to a key 
                first = x.get("first_name")
                last = x.get("last_name")
                userID = x.get("id")
                sex = x.get("sex")
                if (sex == ""):
                    sex = None
                birth = x.get("bdate")
                if (birth == ""):
                    birth = None
                home = x.get("home_town")
                if (home == ""):
                    home = None
                job = x.get("occupation")
                if (job == ""):
                    job = None
      
                # Place our data into their respective keys 
                info_df = pd.DataFrame({"first":first,
                                    "last":last,
                                    "id": userID,
                                    "sex":sex,
                                    "birth": birth,
                                    "home": home,
                                    "job": job}, index = [0])
                   
                # Append the case to our master dataframe 
                userinfo = userinfo.append(info_df)
                
            # Drop duplicates before the next iteration of posts 
            userinfo.drop_duplicates(subset = "id",
                                       keep = "first",
                                       inplace = False)
            
            print("Just added", len(tempList),"samples. There are now",
                  len(userinfo),
                  "samples in total after duplicates are removed.")
            
            # tempList needs to be empty for new IDs
            tempList.clear()
        
        # Turns out that getList() also has a rate limit
        time.sleep(0.3)
    
    
    # Export 1,000 samples to CSV format
    ### userinfo.to_csv("lastOneThousandLikers.csv", index=False)
    return(userinfo) 


#%%
# Get a sampling of 100,000 users from Titov's page

def getOneHundredThoudsandSamples(name):

    userinfo = pd.DataFrame(columns = ["first", "last", "id", "sex", 
                                       "birth" ,"home", "job"])
    tempList = []
    
    while (len(userinfo) <= 100000):
        posts = api.wall.get(owner_id = getUserID(name), count = 100, filter = "owner")
        
        for i in posts["items"]:
            ll = api.likes.getList(type = "post", 
                                   owner_id = id[0]["id"],
                                   item_id = i["id"])
           
            # Build a temprary list of 1000 users, then send it to users.get() 
            if (len(tempList) <= 1000) and \
            (len(tempList)+len(ll["items"]) <= 1000):
                for z in ll["items"]:    
                    tempList.append(z)
                print("I have accumulated", len(tempList), "user ids.")
            
            else:
                info = api.users.get(user_ids = tempList, fields = 
                                     ["sex", "bdate", "home_town", 
                                      "occupation"])
                
                for x in info:
                    # Access dictionaries without the worry of gettting a KeyError
                    # This way, there will always be a value to a key 
                    first = x.get("first_name")
                    last = x.get("last_name")
                    userID = x.get("id")
                    sex = x.get("sex")
                    if (sex == ""):
                        sex = None
                    birth = x.get("bdate")
                    if (birth == ""):
                        birth = None
                    home = x.get("home_town")
                    if (home == ""):
                        home = None
                    job = x.get("occupation")
                    if (job == ""):
                        job = None
          
                    
                    info_df = pd.DataFrame({"first":first,
                                        "last":last,
                                        "id": userID,
                                        "sex":sex,
                                        "birth": birth,
                                        "home": home,
                                        "job": job}, index = [0])
                       

                            
                    userinfo = userinfo.append(info_df)
                    
                # Drop duplicates before the next iteration of posts 
                userinfo.drop_duplicates(subset = "id",
                                           keep = "first",
                                           inplace = False)
                
                print("Just added", len(tempList),"samples. There are now",
                  len(userinfo),
                  "samples in total after duplicates are removed.")
                # tempList needs to be empty for new IDs
                tempList.clear()
            # Turns out that getList() also has a rate limit
            time.sleep(0.3)
    # Export 100,000 samples to CSV format
    userinfo = userinfo[0:99999]
    return(userinfo)
    
####getSample("bytitov")







#%%

def main():
    print("This program will explore the page of Boris Titov\n")
    time.sleep(1)
    print("Here is a list of functions:\n1. lastOneHundredPosts(name)\
          \n2. lastOneThousandLikers(name)\n3. getOneHundredThousandSamples(name)")
    time.sleep(1)
    answer = 999
    while answer != 0:
        answer = int(input("Which function would you like to explore (0 to exit)? "))
        if (answer == 1):
            pd.DataFrame.from_dict(lastOneHundredPosts("bytitov")).to_csv("lastOneHundredPosts.csv", 
                                                                          index = False)
            print("The last 100 posts have been exported to CSV.")
        if (answer == 2):
            lastOneThousandLikers("bytitov").to_csv("lastOneThousandLikers.csv", index = False)
            print("The last 1,000 likers have been exported to CSV.")
        if (answer == 3):
            getOneHundredThoudsandSamples("bytitov").to_csv("getOneHundredThoudsandSamples.csv", 
                                                            index = False)
            print("100,000 samples have been exported to CSV.")
    print("Goodbye!")
    
if __name__ == "__main__":
    main()


































