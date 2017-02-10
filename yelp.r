# Dodge W. Coates
# Untangled source from yelp.org

# Multiple plot function
#
# ggplot objects can be passed in ..., or to plotlist (as a list of ggplot objects)
# - cols:   Number of columns in layout
# - layout: A matrix specifying the layout. If present, 'cols' is ignored.
#
# If the layout is something like matrix(c(1,2,3,3), nrow=2, byrow=TRUE),
# then plot 1 will go in the upper left, 2 will go in the upper right, and
# 3 will go all the way across the bottom.
#
multiplot <- function(..., plotlist=NULL, file, cols=1, layout=NULL) {
  library(grid)

  # Make a list from the ... arguments and plotlist
  plots <- c(list(...), plotlist)

  numPlots = length(plots)

  # If layout is NULL, then use 'cols' to determine layout
  if (is.null(layout)) {
    # Make the panel
    # ncol: Number of columns of plots
    # nrow: Number of rows needed, calculated from # of cols
      layout <- matrix(seq(1, cols * ceiling(numPlots/cols)),
                       ncol = cols, nrow = ceiling(numPlots/cols))
  }

 if (numPlots==1) {
    print(plots[[1]])

  } else {
    # Set up the page
    grid.newpage()
    pushViewport(viewport(layout = grid.layout(nrow(layout), ncol(layout))))

    # Make each plot, in the correct location
    for (i in 1:numPlots) {
      # Get the i,j matrix positions of the regions that contain this subplot
      matchidx <- as.data.frame(which(layout == i, arr.ind = TRUE))

      print(plots[[i]], vp = viewport(layout.pos.row = matchidx$row,
                                      layout.pos.col = matchidx$col))
    }
  }
}

library(ggplot2)
library(data.table)
library(dplyr)
library(ascii)
options(asciiType = "org")
options(max.print = 200)

read_table <- function(filename) {                                          
    table <- fread(filename)  # use fread to quickly read csv file
    # Make sure there ren't any unacceptable chracters in the column names
    names(table) <- make.names(tolower(names(table)), unique = TRUE)
    table
}

print("Loading reviews...")
reviews_t = system.time(reviews <- read_table('./data/review.csv'))

print("Loading tip...")
tips_t = system.time(tips <- read_table("./data/tip.csv"))

print("Loading business...")
business_t = system.time(business <- read_table("./data/business.csv"))

print("Loading user...")
users_t = system.time(users <- read_table("./data/user.csv"))

print("Loading checkin...")
checkins_t = system.time(checkins <- read_table("./data/checkin.csv"))

total_load_time <- reviews_t + tips_t + business_t + users_t + checkins_t
sprintf("Time to load CSV data into data.frames: %.2f minutes", total_load_time["elapsed"]/60.0)

grab_zip <- function(address) {
    as.numeric(substr(address,
                      nchar(address, keepNA = TRUE) - 4,
                      nchar(address, keepNA = TRUE)))
}

zips = lapply(business$full_address, grab_zip)

business <- mutate(business, zip_codes = zips)

percent_null_zips <- length(zips[is.na(zips)])/length(zips)*100

sprintf("%.2f%% of restaurants have undecipherable zip codes", percent_null_zips)

longs <- grep('[[:digit:]]+.[[:digit:]]*', business$longitude)
lats <- grep('[[:digit:]]+.[[:digit:]]*', business$latitude)
stopifnot(length(longs) == length(lats),
          length(longs) == length(business$latitude))
print("Done.")

business <- merge(business, 
                  rename(aggregate(stars ~ business_id,
                                   data=reviews,
                                   FUN=mean), 
                         stars.avg = stars),
                  by='business_id')
business <- rename(business, stars.median = stars) # for pleasant merges with `reviews`
business$price.range <- factor(business$price.range, labels=c('Low',
                                                              'Medium Low', 
                                                              'Medium High',
                                                              'High'))

star_variance <- merge(aggregate(stars ~ business_id,
                                 data = reviews, 
                                 FUN = var),
                       na.omit(business[,c('price.range',
                                           'stars.avg',
                                           'business_id',
                                           'review_count')]),
                       by = 'business_id')
star_variance <- rename(star_variance, stars.var = stars)

aggregate(stars.var ~ price.range, data = star_variance, FUN = mean)

cor(star_variance$stars.var, star_variance$stars.avg, use='complete')

x <- ""
sprintf("Correlation between rating variance and rating average: %.2f", 
        as.numeric(x))

star_freq<- function(r, rating) {
    sum(r == rating)/length(r)
}
# There is definitely a nicer way to do this, but I'm done with that 
# rabbit hole.
s1 <- rename(aggregate(stars ~ business_id,
                       data=reviews,
                       FUN=function(stars) star_freq(stars, 1)),
             one=stars)

s2 <- rename(aggregate(stars ~ business_id,
                       data=reviews,
                       FUN=function(stars) star_freq(stars, 2)),
             two=stars)

s3 <- rename(aggregate(stars ~ business_id,
                       data=reviews,
                       FUN=function(stars) star_freq(stars, 3)),
             three=stars)

s4 <- rename(aggregate(stars ~ business_id,
                       data=reviews,
                       FUN=function(stars) star_freq(stars, 4)),
             four=stars)

s5 <- rename(aggregate(stars ~ business_id,
                       data=reviews,
                       FUN=function(stars) star_freq(stars, 5)),
             five=stars)


business <- merge(business, Reduce(merge,list(s1, s2, s3, s4, s5)),
                  by="business_id")

library(scales)
r <- filter(business, review_count > 100)
ggplot(r, aes(x=one, y=five, color = price.range)) +
    geom_point() +
    scale_x_continuous(labels = percent) +
    scale_y_continuous(labels = percent) + 
    labs(color = "Business Price Range", 
         x = ("One star"),
         y = ("Five star"), 
         title="Rating composition: five-star vs one-star")

g1 <- rename(aggregate(stars ~ business_id, data=reviews, FUN=function(stars) star_freq(stars, 1)), one=stars)
g2 <- rename(aggregate(stars ~ business_id, data=reviews, FUN=function(stars) star_freq(stars, 2)), two=stars)
g3 <- rename(aggregate(stars ~ business_id, data=reviews, FUN=function(stars) star_freq(stars, 3)), three=stars)
g4 <- rename(aggregate(stars ~ business_id, data=reviews, FUN=function(stars) star_freq(stars, 4)), four=stars)
g5 <- rename(aggregate(stars ~ business_id, data=reviews, FUN=function(stars) star_freq(stars, 5)), five=stars)

business <- merge(business, Reduce(merge,list(g1, g2, g3, g4, g5)), by="business_id")

star_freq<- function(rs) {   
    tabulate(rs)/length(rs)
}

business <- merge(rename(aggregate(stars ~ business_id,
                                   data=reviews,
                                   FUN=star_freq),
                         stars.dist=stars),
                  business,
                  by="business_id")

b <- filter(business, review_count > 20)
g <- ggplot(data=b, aes(stars.avg))
g + geom_histogram(breaks=seq(1,5,by=.10),
                   fill="red",
                   col="red",
                   alpha=.2) + 
    labs(title = "Distribution average business rating", 
         x = "Mean Rating",
         y = "Count")

ggplot(business, aes(x=price.range, y=stars.avg, fill=price.range)) + 
    geom_boxplot() + 
    stat_summary(fun.y="mean", geom="point") + 
    labs(x = "Price Range",
         y = "Rating average",
         title = "Rating distribution by price ranges")

# priced restaurants only
ggplot(business[!is.na(business$price.range), ],
       aes(x=stars.avg, fill=price.range)) + geom_histogram(binwidth=.25) +
       ylab('Count') +
       xlab('Rating average (mean)') +
       labs(fill="Price Range") +
       ggtitle('Distribution of ratings by business price range')

b <- business[business$review_count > 20, ]
ggplot(b[is.na(b$price.range),], aes(x=stars.avg)) +
    geom_histogram(binwidth=.10, color='orange', fill='orange') +
    ylab('Count') +
    xlab('Rating average (mean)') +
    labs(fill="Price Range") +
    ggtitle('Distribution of ratings for unpriced businesses by price range')

s <- star_variance[star_variance$review_count > 20, ]
ggplot(s, aes(x=stars.var)) + geom_histogram(color='red', fill='red', binwidth=.1)

s <- star_variance[star_variance$review_count > 100, ]
ggplot(s, aes(x=stars.var, y=review_count)) + geom_point()

sprintf("Average rating across all reviews: %.3f", mean(reviews$stars))

s <- sample_n(filter(star_variance, review_count > 30 ), 16000)
ggplot(filter(s, as.numeric(s$price.range) == 1), aes(x=review_count, y=stars.var)) + 
    geom_point() + 
    scale_y_continuous(limits = c(0, 4)) + 
    scale_x_continuous(limits = c(0, 4000))
