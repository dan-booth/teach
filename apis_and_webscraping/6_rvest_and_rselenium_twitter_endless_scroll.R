# =========================================================================== #
#                                                                             #
# Author: Daniel Booth                                                        #
# Date:  Wed 13 Sep 2017                                                      #
# File Name: twitter_endless_scroll_with_rvest_and_RSelenium.R
# Description: description
#                                                                             #
# =========================================================================== #

# Libraries
library(RSelenium)
library(rvest)
library(tibble)

# Form Twitter search URL
from <- '@hadleywickham'
since <- '2017-09-01'
until <- '2017-09-13'

search_url <- paste0('https://twitter.com/search?q=from:', from,
                     ' since:', since, ' until:', until,
                     '&f=tweets')

# Selenium setup
library(RSelenium)
# https://cran.r-project.org/web/packages/RSelenium/vignettes/RSelenium-docker.html

# Non-docker version
# Start a Chrome browser
rD <- rsDriver(browser = 'chrome')
remDr <- rD[["client"]]

# Navigate to page and endless scroll
remDr$navigate(search_url)
  
# Give page time to load
Sys.sleep(5)

# Scroll to the bottom
check_at_footer <- function(remDr) {
  footer <- remDr$findElements(using = 'class name',
                               value = 'stream-footer')
  return(footer[[1]]$getElementText() == 'Back to top ↑')
}

webElem <- remDr$findElement("css", "body")

while(check_at_footer(remDr) == FALSE) {
  webElem$sendKeysToElement(list(key = "end"))
  Sys.sleep(2)
}

# Now pull down html and scrape with httr
twitter_session <- read_html(remDr$getPageSource()[[1]])

# Stop the selenium server
rD[["server"]]$stop()

# Get content
tweet_ids <- twitter_session %>%
  html_nodes(css = ".js-stream-item.stream-item.stream-item") %>% 
  html_attr("data-item-id")

# Note you can now pass these tweet_ids into the Twitter API to pull all the
# content you need, see twitter_via_httr.R

# BUT while we're here let's grab some content

# Is it a reply
is_reply <- twitter_session %>%
  html_nodes(css = ".js-stream-item.stream-item.stream-item .tweet") %>% 
  html_attr("data-is-reply-to") %>% 
  tibble(is_reply = .) %>%
  mutate(is_reply = !is.na(is_reply))

# Get permalink
permalink <- twitter_session %>%
  html_nodes(css = ".js-stream-item.stream-item.stream-item .tweet") %>% 
  html_attr("data-permalink-path") %>% 
  paste0('https://twitter.com', .)

# Get Tweet text
tweet_text <- twitter_session %>%
  html_nodes(css = ".js-stream-item.stream-item.stream-item .js-tweet-text-container") %>% 
  html_text(trim = TRUE)

# Get replies
tweet_replies <- twitter_session %>%
  html_nodes(css = ".ProfileTweet-action--reply .ProfileTweet-actionCount") %>% 
  html_attr("data-tweet-stat-count") %>%
  tibble(replies = .) %>% 
  filter(!is.na(.))

# Get retweets
tweet_retweets <- twitter_session %>%
  html_nodes(css = ".ProfileTweet-action--retweet .ProfileTweet-actionCount") %>% 
  html_attr("data-tweet-stat-count") %>%
  tibble(retweets = .) %>% 
  filter(!is.na(.))

# Get favourites
tweet_favorites <- twitter_session %>%
  html_nodes(css = ".ProfileTweet-action--favorite .ProfileTweet-actionCount") %>% 
  html_attr("data-tweet-stat-count") %>%
  tibble(favorites = .) %>% 
  filter(!is.na(.))

# Combine in tibble
total_tweets <- length(tweet_ids$id)

results <- tibble(tweet_id = tweet_ids,
                  text = tweet_text,
                  replies = tweet_replies$replies,
                  retweets = tweet_retweets$retweets,
                  favorites = tweet_favorites$favorites,
                  is_reply = is_reply$is_reply,
                  permalink = permalink)

# Inspect results
glimpse(results)
View(results)
