# =========================================================================== #
#                                                                             #
# Author: Daniel Booth                                                        #
# Date:  Wed 13 Sep 2017                                                      #
# File Name: gcp_ml_apis_via_httr.R
# Description: description
#                                                                             #
# =========================================================================== #

# == Packages =================================================================
library(httr)
library(magrittr)

# == Authenticate =============================================================

# Create a GCP project at: https://console.cloud.google.com/projectcreate
# Enable the Cloud Natural Language API at: https://console.cloud.google.com/apis/api/language.googleapis.com/overview
# Enable the Cloud Vision API at: https://console.cloud.google.com/apis/api/language.googleapis.com/overview
# Make sure to set the consent screen homepage URL to "http://127.0.0.1:1410/"
# Copy keys from https://console.cloud.google.com/apis/credentials

# No OAuth is available for the Cloud NLP API so need api_key
api_key <- 'your_api_key'

# OAuth is available for the Cloud Vision API
# Auth scope https://www.googleapis.com/auth/cloud-vision
client_id <- 'your_client_id'
client_secret <- 'your_client_secret'

g_app <- oauth_app("google",
                   key = client_id,
                   secret = client_secret)

# Get OAuth creds
g_token <- oauth2.0_token(oauth_endpoints("google"),
                          g_app,
                          scope = "https://www.googleapis.com/auth/cloud-vision", cache = FALSE)

# == Cloud Natural Language API ===============================================

# analyzeSentiment
path <- 'v1/documents:analyzeSentiment'
query_args <- list(key = api_key)

# JSON body
# See structure at: https://cloud.google.com/natural-language/docs/reference/rest/v1/documents
body_path <- 'data/gcp_nlp_ex_1.json'
file.edit(body_path)

response <- POST("https://language.googleapis.com",
                 path = path,
                 query = query_args,
                 body = upload_file(body_path))

# Show content returned
content(response)

# annotateText
path <- 'v1/documents:annotateText'

# JSON
body_path <- 'data/gcp_nlp_ex_2.json'
file.edit(body_path)

response <- POST("https://language.googleapis.com",
                 path = path,
                 query = query_args,
                 body = upload_file(body_path))

# Show content returned
content(response)

# Convert from JSON to a list
response_parsed <- jsonlite::fromJSON(content(response, "text"))

str(response_parsed)

# See the product overview page for a nice rendering of this data: https://cloud.google.com/natural-language

# See the docs for details on what each of the response fields represent/measure
# - https://cloud.google.com/natural-language/docs/reference/rest/v1/TextSpan
# - https://cloud.google.com/natural-language/docs/reference/rest/v1/Sentiment
# - https://cloud.google.com/natural-language/docs/reference/rest/v1/Token
# - https://cloud.google.com/natural-language/docs/reference/rest/v1/Entity

# == Cloud Vision API =========================================================

# annotate - Text detection
path <- 'v1/images:annotate'

# JSON

# Images can be passed in one of three ways:
# - as a base64-encoded string;
# - as a Google Cloud Storage URI;
# - or as a web URI

# base64 encode the image
# Bike image from: https://pixabay.com/p-39393
img <- 'data/bike.png'
base64_encoding <- readr::read_file_raw(img) %>% openssl::base64_encode()
# To copy
base64_encoding %>% readr::write_lines('~/Desktop/tmp.txt')
file.edit('~/Desktop/tmp.txt')

# Will request feature types:
# - LABEL_DETECTION
# - TEXT_DETECTION
# - For others see: https://cloud.google.com/vision/docs/reference/rest/v1/images/annotate#Feature
body_path <- 'data/gcp_vision_ex_1.json'
file.edit(body_path)

# API call (with api_key)
response <- POST("https://vision.googleapis.com",
                 path = path,
                 query = query_args,
                 body = upload_file(body_path))

# API call (with OAuth)
response <- POST("https://vision.googleapis.com",
                 path = path,
                 body = upload_file(body_path),
                 config = config(token = g_token))

# Show content returned
content(response) %>% str()

# Will need to parse this depending on the use case

# See the product overview page for a nice rendering of this data: https://cloud.google.com/vision/

# See the docs for details on what each of the response fields represent/measure
# - https://cloud.google.com/vision/docs/reference/rest/v1/images/annotate#AnnotateImageResponse