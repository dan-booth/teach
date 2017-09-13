# =========================================================================== #
#                                                                             #
# Author: Daniel Booth                                                        #
# Date:  Wed 13 Sep 2017                                                      #
# File Name: rvest_realestatecomau.R                                          #
# Description: Pull down property rental prices in St Leonards                # 
#                                                                             #
# =========================================================================== #

# == Packages =================================================================
library(rvest)
library(stringr)
library(tidyverse)

# == Preparation for scraping =================================================

# Check robots.txt
browseURL('https://www.realestate.com.au/robots.txt')

# Use your web browser to establsh the URL structure
# For 2 bed apartments in St Leonards the URL is
search_url <- 'https://www.realestate.com.au/rent/property-unit+apartment-with-2-bedrooms-in-st+leonards%2c+nsw+2065/list-1?maxBeds=2&source=location-search'

# Set user agent (for MacBook Pro)
chrome_ua <- "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.81 Safari/537.36"

# == Scrape ===================================================================

# Start session
realestate_session <- html_session(search_url, httr::user_agent(chrome_ua))

# Get property ids
property_id <- realestate_session %>%
  html_nodes(css = '.resultBody') %>% 
  html_attr('id')

# Get listing details
listings <- realestate_session %>%
  html_nodes(css = '.listingInfo')

# Now extract the data (Note only first 9 listings have agent)
agent <- listings %>% 
  html_nodes(css = '.listerName') %>% 
  html_text() %>% 
  str_sub(start = 7) # Remove 'Agent ' prefix

price_text <- listings %>% 
  html_nodes(css = '.priceText') %>% 
  html_text()

address <- listings %>% 
  html_nodes(css = '.name') %>% 
  html_text()

listing_url <- listings %>% 
  html_nodes(css = '.name') %>% 
  html_attr('href') %>% 
  paste0('https://www.realestate.com.au', .)

property_feature_names <- listings %>% 
  html_nodes(css = '.rui-property-features .rui-visuallyhidden') %>% 
  html_text

property_feature_values <- listings %>% 
  html_nodes(css = '.rui-property-features dd') %>% 
  html_text

# Combine and reshape property features
property_features <- tibble(property_id = rep(property_id, each = 3),
       property_feature_names, property_feature_values) %>% 
  spread(key = property_feature_names, value = property_feature_values)

# == Bind all the results together ============================================
tibble(property_id,
       c(agent, rep(NA_character_, 11)),
       price_text,
       address,
       listing_url) %>% 
  inner_join(property_features)
