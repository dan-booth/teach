# =========================================================================== #
#                                                                             #
# Author: Daniel Booth                                                        #
# Date:  Wed 13 Sep 2017                                                      #
# File Name: reselenium_core_logic_web_driving.R                              #
# Description: Provides an introduction to RSelenium by demonstrating how to  #
#              drive a web browser through an CoreLogic workflow              #
#                                                                             #
# =========================================================================== #

# Note the code here is to be run interactively just for demonstration purposes.
# You would normally run this as a script

# For a good introduction to RSelenium, read vignette at:
# https://cran.r-project.org/web/packages/RSelenium/vignettes/RSelenium-docker.html

# == Packages =================================================================
library(RSelenium)

# Non-docker version
# Start a Chrome browser
rD <- rsDriver(browser = 'chrome')
remDr <- rD[["client"]]

remDr$navigate('https://rpp.rpdata.com/rpp/login.html')

# Give page time to load
Sys.sleep(5)

# Sign in (I load these creds from a script)
# cl_username <- 'your_username'
# cl_password <- 'your_password'

username_field <- remDr$findElement(using = 'id', value = "j_username")
username_field$sendKeysToElement(list(cl_username))
password_field <- remDr$findElement(using = 'id', value = "j_password")
password_field$sendKeysToElement(list(cl_password, "\uE007"))
Sys.sleep(5)

# Search for Property I'm interested in
property_address <- '1107/48 Atchison Street St Leonards NSW 2065'
search_field <- remDr$findElement(using = 'name', value = "addressSearch")
search_field$sendKeysToElement(list(property_address, "\uE007"))

# Now get some data from the page (need rvest)
library(rvest)
library(tidyverse)
property_detail <- read_html(remDr$getPageSource()[[1]])

property_attribute_names <- property_detail %>%
  html_nodes(css = ".attributePanel .iconContainer .attribute") %>% 
  html_attr(name = "title")

property_attribute_values <- property_detail %>%
  html_nodes(css = ".attributePanel .iconContainer .value") %>% 
  html_text()

# Combine and reshape property features
property_attributes <- tibble(property_attribute_names, property_attribute_values) %>% 
  distinct() %>% # To remove the dupes in this node
  spread(key = property_attribute_names, value = property_attribute_values)

# View
glimpse(property_attributes)

# Finally, download a property report
valuation_report <- remDr$findElement(using = 'name', value = "propertyTaskBar.icon.valuationReport")
valuation_report$clickElement()
Sys.sleep(5)

# Confirm attributes
# Switch to new tab
valuation_report_window <- remDr$switchToWindow(windowId = remDr$getWindowHandles()[[2]])

# Hit tab 12 times, then down twice, then enter (Sometimes you need to be a bit hacky)
for (i in 1:12) {
  remDr$sendKeysToActiveElement(list("\uE004"))
}

# Hit u and then enter
remDr$sendKeysToActiveElement(list("u", "\uE007"))

# Click button to download report
valuation_report <- remDr$findElement(using = 'name', value = "agreementsForm:j_id42")
valuation_report$clickElement()

# Close tabs
valuation_report_close <- remDr$findElement(using = 'css selector', value = ".buttonContainerOuterSecondarySml")
valuation_report_close$clickElement()

valuation_report_window <- remDr$switchToWindow(windowId = remDr$getWindowHandles()[[1]])
valuation_report <- remDr$findElement(using = 'css selector', value = ".gradientDark.buttonLarge.rounded")
valuation_report$clickElement()

# Stop the selenium server
rD[["server"]]$stop()
