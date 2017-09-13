# =========================================================================== #
#                                                                             #
# Author: Daniel Booth                                                        #
# Date:  Wed 13 Sep 2017                                                      #
# File Name: twitter_via_httr.R
# Description: Interacting with the Twitter Search API via httr.
#                                                                             #
# =========================================================================== #

# == Packages =================================================================
library(tidyverse)
library(httr)
library(jsonlite)

# == OAuth ====================================================================

# See https://dev.twitter.com/oauth/overview
# Register an application at https://apps.twitter.com/
# Make sure to set callback url to "http://127.0.0.1:1410/"
# Copy keys from app admin window

# Define keys
consumer_key <- "<your_consumer_key>"
consumer_secret <- "<your_consumer_secret>"


# Define app
myapp <- oauth_app("twitter",
                   key = consumer_key,
                   secret = consumer_secret)

# Get token
twitter_token <- oauth1.0_token(oauth_endpoints("twitter"), myapp, cache = TRUE)

# Now we can run a test query
response <- GET("https://api.twitter.com/1.1/statuses/home_timeline.json",
                config(token = twitter_token))
content(response)

# == Search Tweets GET requests ===============================================

# Learn how to use the search well with at https://twitter.com/search-home
# And the q operators https://dev.twitter.com/rest/public/search
# For example, to just get tweets only from a user 'from:twitter_account_no'
# hashtag add as it
# To include dates add ' since:yyyy-mm-dd until:yyyy-mm-dd' although this will
# only work within the 7 days

# GET request

# Let's use #AusPol as an example
query_args <- list(q = '#AusPol', # httr handles the URL encoding of space, @ and #
                   result_type = 'recent',
                   count = '100',
                   include_entities = 'true')

response <- GET('https://api.twitter.com/1.1/search/tweets.json',
                config = config(token = twitter_token),
                query = query_args)

# Inspect
content(response)

# Convert json to a list
response_parsed <- fromJSON(content(response, "text"))

glimpse(response_parsed$statuses)

# Form a tibble with just the core info (you can include more depending on use-case)

tweets <- tibble(created_at = lubridate::mdy_hms(paste(stringr::str_sub(response_parsed$statuses$created_at, 5, 10),
                                                       stringr::str_sub(response_parsed$statuses$created_at, -4),
                                                       stringr::str_sub(response_parsed$statuses$created_at, 12, 19))),
                 id_str = response_parsed$statuses$id_str,
                 text = response_parsed$statuses$text,
                 retweet_count = response_parsed$statuses$retweet_count,
                 favorite_count = response_parsed$statuses$favorite_count,
                 hastags = response_parsed$statuses$entities$hashtags,
                 user_mentions = response_parsed$statuses$entities$user_mentions,
                 urls = response_parsed$statuses$entities$urls,
                 source = response_parsed$statuses$source,
                 in_reply_to_status_id_str = response_parsed$statuses$in_reply_to_status_id_str,
                 in_reply_to_user_id_str = response_parsed$statuses$in_reply_to_user_id_str,
                 in_reply_to_screen_name = response_parsed$statuses$in_reply_to_screen_name,
                 user_id_str = response_parsed$statuses$user$id_str,
                 user_name = response_parsed$statuses$user$name,
                 user_screen_name = response_parsed$statuses$user$screen_name)

# == GET statuses by ID =======================================================

# You can search a tweet directly by its id. This allows you to view historical
# results after say a webscraping exercise.
# See docs at: https://dev.twitter.com/rest/reference/get/statuses/show/id

# Here's the ID of the Tweet where Hadley announces the tidyverse website:
tweet_id <- '894588979479228420'

# GET request
query_args <- list(id = tweet_id,
                   trim_user = 'true',
                   include_my_retweet = 'false',
                   include_entities = 'true')

response <- GET('https://api.twitter.com/1.1/statuses/show.json',
                config = config(token = twitter_token),
                query = query_args)

# Inspect
content(response)

# Convert json to a list
response_parsed <- fromJSON(content(response, "text"))

glimpse(response_parsed)

# == See also: twitteR package ================================================

# My goal here was to show you as raw as possible a way to interact with the API
# There is however a package twitteR that wraps many of these workflows into
# functions which you can also explore: https://cran.r-project.org/web/packages/twitteR/index.html