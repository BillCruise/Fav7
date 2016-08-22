
library(dplyr)
library(purrr)
library(twitteR)

# Download cacert file for Windows use.
download.file(url="http://curl.haxx.se/ca/cacert.pem", destfile="cacert.pem")

consumer_key <- 'your key'
consumer_secret <- 'your secret'
access_token <- 'your access token'
access_secret <- 'your access secret'
setup_twitter_oauth(consumer_key,
                    consumer_secret,
                    access_token,
                    access_secret)

requests <- 1 # keep count of how many requests are sent
num_tweets <- 3000 # number of tweets to fetch per request
delay <- 62.0 # add in a delay so the API doesn't block

fav_film_tweets <- searchTwitter("#Fav7Films\n", n=num_tweets)
Sys.sleep(delay) # be nice to the API
fav_film_df <- tbl_df(map_df(fav_film_tweets, as.data.frame))

fav_film_all <- fav_film_df[fav_film_df$isRetweet == FALSE, ]


while(nrow(fav_film_df) == num_tweets) {
    max_id <- fav_film_df$id[num_tweets]
    requests <- requests + 1
    fav_film_tweets <- searchTwitter("#Fav7Films\n", n=num_tweets, maxID=max_id)
    fav_film_df <- tbl_df(map_df(fav_film_tweets, as.data.frame))
    fav_film_all <- rbind(fav_film_all, fav_film_df[fav_film_df$isRetweet == FALSE, ])

    Sys.sleep(delay) # be nice to the API
}

# 126,017 tweets retrieved (from 8/15, to 8/22)
save(fav_film_all, file="Fav7FilmTweets.Rda")

# remove multiple tweets from the same user
fav_film_all <- fav_film_all[!duplicated(fav_film_all$screenName), ]

# remove the hashtag, ignoring case
fav_film_all$text <- gsub("#fav7films", "", fav_film_all$text, ignore.case=TRUE)

# remove numbers from lists
fav_film_all$text <- gsub("\\d\\.|\\)|-", "", fav_film_all$text)

# convert to common case for all tweets
fav_film_all$text <- tolower(fav_film_all$text)

# trim any whitespace left over from earlier steps
fav_film_all$text <- trimws(fav_film_all$text)


# build a list of titles
titles <- list()
titles <- append(titles, strsplit(fav_film_all$text, split="\n"))
titles <- unlist(titles)

# remove leading 'a' and 'the' from titles
titles <- gsub("^a ", "", titles)
titles <- gsub("^the ", "", titles)

# remove empty titles
titles <- titles[titles != ""]

ranked_titles <- sort(table(titles), decreasing=TRUE)
top_25 <- head(ranked_titles, 25)


