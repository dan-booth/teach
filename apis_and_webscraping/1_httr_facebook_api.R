# =========================================================================== #
#                                                                             #
# Author: Daniel Booth                                                        #
# Date:  Wed 13 Sep 2017                                                      #
# File Name: httr_facebook_api.R                                              #
# Description: This script provides an introduction to using R to extract data#
#              through the Facebook Graph API.                                #
#              We will extract data from the RStudio facebook page using the  #
#              httr package and also show how to post to our wall             #
#                                                                             #
# =========================================================================== #

# Note this tutorial is written more formally as a Vignette on R Pubs.
# See: http://rpubs.com/danbooth/facebook_api

# == Register a Facebook Application ==========================================

# Before you can use the API, Facebook requires you to register an Application.
# Do this at: https://developers.facebook.com/apps/ 
# Full instructions at: http://rpubs.com/danbooth/facebook_api

# == Packages =================================================================
library(httr)
library(jsonlite)
library(dplyr)
library(lubridate)

# == Authenticate =============================================================

# We can choose between a User Access Token (most common) or App Access Token
# See: https://developers.facebook.com/docs/facebook-login/access-tokens/
# - https://developers.facebook.com/docs/graph-api

# Here I'll show how to authenticate with a User Access Token. See the Vignette
# above for how to register with an app access token

# Define keys  (I load these creds from a script)
# Your keys are available at: https://developers.facebook.com/apps/
app_id = '<your_app_id>'
app_secret = '<your_app_secret>'

# Define the app
fb_app <- oauth_app(appname = "facebook",
                    key = app_id,
                    secret = app_secret)

# Get OAuth user access token
# We define what permissions we want to request from the user (in this case us)
# See https://developers.facebook.com/docs/facebook-login/permissions/
# We will request:
# - 'public_profile' - The default. Let's us query public pages
# - 'publish_actions' - Let's us query publish posts on behalf of the user
fb_token <- oauth2.0_token(oauth_endpoints("facebook"),
                           fb_app,
                           scope = c('public_profile', 'publish_actions'),
                           cache = TRUE)

# == Make some GET requests ===================================================

# All nodes and edges in the API can be read with an **HTTP `GET` request** to
# the relevant endpoint

# The structure of the GET request is:
# GET graph.facebook.com
#   /{node-id}/{edge-type}?
#   fields=<first-level>{<second-level>}

# See the vignette for more detail

# Fortunately httr handles this all for us

# = User information ==========================================================
# GET request for your user information
response <- GET("https://graph.facebook.com",
                path = "/me",
                config = config(token = fb_token))

# You can inspect response to see if you got a 200 (OK) HTTP Status code
response
# Full list of status codes are available at: https://en.wikipedia.org/wiki/List_of_HTTP_status_codes

# Show content returned
content(response)

# Note if this fails you might need to go to: https://www.facebook.com/settings?tab=applications and then Remove access for the app and retry 

# = RStudio Page Info =========================================================
# GET request for RStudio facebook page info
# This is a Page node in the API: https://developers.facebook.com/docs/graph-api/reference/page
# We also define the fields we want to return

# Define the node and fields
path <- '/rstudioinc'
query_args <- list(fields = 'username,id,name,category,fan_count,link')

# GET request
response <- GET('https://graph.facebook.com',
                path = path,
                query = query_args,
                config(token = fb_token))

# This response is JSON as the API docs told us
http_type(response)

# To inspect the content of the response we can use the `content()` function,
# which automatically parses the **json**. We'll wrap this with `str()` to inspect
str(content(response))

# If we need to access the JSON use
content(response, as = 'text')

# = RStudio Page posts ========================================================

# Let's now get the RStudio Page posts into a tibble
# Define the node, edge and fields
path <- '/rstudioinc/feed'
query_args <- list(fields = 'id,created_time,from,message,type,place,permalink_url,shares,likes.summary(true),comments.summary(true)')

# GET request
response <- GET('https://graph.facebook.com',
                path = path,
                query = query_args,
                config(token = fb_token))

# Convert json to a list
response_parsed <- fromJSON(content(response, "text"))

# Inspect
glimpse(response_parsed$data)

# You will notice only 25 results returned. This is by design. To balance load,
# Facebook deliberately returns the results of our request in paginated chunks.
# Thus the `response_parsed$paging` list tells us how to transverse through the
# rest of the paginated results
str(response_parsed$paging)

# To get the next 25 results we'd run:
response_next <- GET(content(response)$paging$`next`,
                     config(token = fb_token))

# In practice we would use a `while` loop to continue this until `paging$`next``
# is `NULL`.

# Our final step is to clean the results:
posts <- tibble(id = response_parsed$data$id,
                created_time = with_tz(ymd_hms(response_parsed$data$created_time,
                                               tz = 'UTC'),
                                       tz = 'Australia/Sydney'),
                from_id = response_parsed$data$from$id,
                from_name = response_parsed$data$from$name,
                message = response_parsed$data$message,
                type = response_parsed$data$type,
                permalink_url = response_parsed$data$permalink_url,
                shares_count = response_parsed$data$shares$count,
                likes_count = response_parsed$data$likes$summary$total_count,
                comments_count = response_parsed$data$comments$summary$total_count)

# Inspect
glimpse(posts)
View(posts)

# == Make a POST ==============================================================

# Define the node and fields
# See: https://developers.facebook.com/docs/graph-api/reference/v2.10/user/feed#publish for details
path <- '/me/feed'

# = Only-me post ==============================================================
query_args <- list(message = 'Hello SURF!',
                   link = 'https://github.com/dan-booth',
                   privacy = "{value:'SELF'}") # Pass in as JSON key:value pairs

response <- POST("https://graph.facebook.com",
                 path = path,
                 query = query_args,
                 config = config(token = fb_token))

# Show content returned
content(response)
# This is the ID of the post
# If we go to our wall now we will see this post!

# Alternatively, we can send get request on this post via the post_id returned
# to get the permalink for the post
response <- GET("https://graph.facebook.com",
                path = content(response)$id,
                query = list(fields = 'permalink_url'),
                config = config(token = fb_token))

# So we can view at
content(response)$permalink_url
browseURL(content(response)$permalink_url)

# = All friends post ==========================================================
# Note we need to have granted that permission during OAuth
query_args <- list(message = 'Hello SURF!',
                   link = 'https://github.com/dan-booth',
                   privacy = "{value:'ALL_FRIENDS'}")

response <- POST("https://graph.facebook.com",
                 path = path,
                 query = query_args,
                 config = config(token = fb_token))

# Show content returned
content(response)
# This is the ID of the post
# If we go to our wall now we will see this post!

# Alternatively, we can send get request on this post via the post_id returned
# to get the permalink for the post
response <- GET("https://graph.facebook.com",
                path = content(response)$id,
                query = list(fields = 'permalink_url'),
                config = config(token = fb_token))

# So we can view at
content(response)$permalink_url
browseURL(content(response)$permalink_url)
# We see this has permissions for all my friends

# == See also: RFacebook package ==============================================

# My goal here was to show you as raw as possible a way to interact with the API
# There is however a package RFacebook that wraps many of these workflows into
# functions which you can also explore: https://cran.r-project.org/web/packages/Rfacebook/index.html