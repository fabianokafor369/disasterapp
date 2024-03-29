library(shiny)
library(ggplot2)
library(shinydashboard)
suppressPackageStartupMessages(library(rtweet))
suppressPackageStartupMessages(library(ROAuth))
suppressPackageStartupMessages(library(plyr))
suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(wordcloud))
suppressPackageStartupMessages(library(tm))
suppressPackageStartupMessages(library(SnowballC))
suppressPackageStartupMessages(library(googleVis))
suppressPackageStartupMessages(library("syuzhet"))
library(plotly)
library(tidyr)
library(RCurl)
library(httr)

#Create the token
create_token(
    app = "natural disaster tweets",
    consumer_key = "##############################",
    consumer_secret = "############################",
    access_token = "##################################",
    access_secret = "############################")


Sys.setenv("plotly_username"="fabianokafor369")
Sys.setenv("plotly_api_key"="###############################")

ui = dashboardPage(skin = "blue",
                   dashboardHeader(title = "Natural Disaster Analytics", titleWidth = 300),
                   dashboardSidebar(width = 300, sidebarMenu(style = "position: fixed; overflow: visible;",
                                                             menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")), 
                                                             menuItem("About", tabName = "about", icon = icon("file-alt", lib="font-awesome")),
                                                             menuItem("Source code for app",href="https://github.com/fabianokafor369/disasterapp", icon=icon("github")),
                                                             menuItem("Personal website",href="http://fabianokafor369.github.io", icon=icon("file-text-o")),
                                                             menuItem("LinkedIn",href="https://www.linkedin.com/in/fabianokafor", icon=icon("linkedin")),
                                                             br(),
                                                             br(),
                                                             textInput("hashtag", "Search hashtag, word or phrase", value = " "),
                                                             sliderInput("searchnumber", "Number of searches for analysis", min = 200, max = 3000, value = 800, step= 200),
                                                             checkboxInput("retweets", "Include retweets", value = FALSE),
                                                             actionButton("save","Add")
                                                             
                                                             
                   )),
                   
                   dashboardBody(tags$script(HTML("$('body').addClass('fixed');")),
                   tags$script(HTML("
                        var openTab = function(tabName){
                          $('a', $('.sidebar')).each(function() {
                            if(this.getAttribute('data-value') == tabName) {
                              this.click()
                            };
                          });
                        }
                      ")),tabItems(
                       tabItem(tabName = "dashboard", fluidRow(infoBoxOutput(width=3, "tweetloccount"), infoBoxOutput(width=3, "mostactive"), infoBoxOutput(width=3,"mostactivea"), infoBoxOutput(width=3, "mostprominent")),
                               box(htmlOutput("summary5"), width = 800, height = 600),
                               fluidRow(
                                   box(title = "Sentiment analysis of tweet usage", status = "primary", solidHeader = TRUE,
                                       collapsible = TRUE,plotlyOutput('sentanalysis')),
                                   box(title = "Word cloud showing most frequent words for sentiments", status = "primary", solidHeader = TRUE,
                                       collapsible = TRUE, plotOutput("wcloudgrouped"))),
                               fluidRow(
                                   box(title = "Word cloud of generally frequent words in tweet text", status = "primary", solidHeader = TRUE,
                                       collapsible = TRUE, plotOutput('singlewcloud')),
                                   box(title = "Linechart of recent tweet frequency", status = "primary", solidHeader = TRUE,
                                       collapsible = TRUE, plotOutput("linechart")))
                       ),
                       tabItem(tabName="about", h1("About this dashboard"),
                               p("Having read this article " ,span(a("Locating Natural Disasters through Social Media Feeds with R", href="https://towardsdatascience.com/locating-natural-disasters-through-social-media-feeds-with-r-7c8d3f078750")), 
                                 "this dashboard provides an interactive avenue for individuals to track natural disasters around the world. On startup, the dashboard contains filler data visualizations as place holders. However, twitter data retrieved using the Twitter api is cleaned and related to a given search hashtag or word, is cleaned, and plotted over a google map. This allows users to locate clusters of areas where reactions to that given hashtag is greatest. A sentiment analysis and word cloud visualization also gives a general idea of the aggregate feelings expressed through tweets related to that search. Finally, the change in frequency of that search item over the past couple of days is displayed on a line graph.  "),
                               p("This dashboard is a member of a series of data visualization applications built by this same author(using Rshiny). Amongst this series is the ", span(a("GDP index data visualization dashboard", href="https://fabianokafor369.shinyapps.io/GDPapp/")),
                                 "which is an interactive platform for the observation of trends in GDP leading index data of US states. It was built using the Rshiny package, together with Rstudio packages such as googlevis, plotly and rtweet."),
                               p(code("Disclaimer:"), "This app was created using the Twitter API, and its use should be restricted to its purpose of natural disaster information gathering and visualization. Examples of hastags and search items for natural disasters could include '#earthquake', 'hurricane', 'LAwildfire' etc. For more info on the Twitter API use terms and service, visit " , span(a("Twitter Developer Rules", href="https://developer.twitter.com/en/developer-terms/agreement-and-policy.html.")), ".")))
                   )
                   
)

server <- shinyServer(function(input, output, session) {
    showNotification("Select inputs for data visualization and click on enter to view plots", duration = 7, type = "message")
    output$summary5 <- renderGvis({
        gvisMap(Andrew, "LatLong" , "Tip",options=list(showTip=TRUE, showLine=TRUE, enableScrollWheel=TRUE,mapType='hybrid', useMapTypeControl=TRUE,height=570))
    })
    
    output$singlewcloud <- renderPlot({
        data(crude)
        crude <- tm_map(crude, removePunctuation)
        crude <- tm_map(crude, function(x)removeWords(x,stopwords()))
        wordcloud(crude)
    })
    
    output$linechart <- renderPlot({
        t <- plot(ts(matrix(rnorm(300), 100, 3), start = c(1966, 1), frequency = 12))
        t
    })
    
    output$wcloudgrouped <- renderPlot({
        data(SOTU)
        corp <- SOTU
        corp <- tm_map(corp, removePunctuation)
        corp <- tm_map(corp, content_transformer(tolower))
        corp <- tm_map(corp, removeNumbers)
        corp <- tm_map(corp, function(x)removeWords(x,stopwords()))
        
        term.matrix <- TermDocumentMatrix(corp)
        term.matrix <- as.matrix(term.matrix)
        colnames(term.matrix) <- c("SOTU 2010","SOTU 2011")
        comparison.cloud(term.matrix,max.words=10,random.order=FALSE,
                         match.colors=TRUE)
    })
    
    output$sentanalysis <- renderPlotly({
        df <- data.frame(mood=c("happy", "angry", "sad"),
                         population=c(14, 100, 98))
        ggplot(df, aes(x=mood, y=population, fill=mood)) +geom_bar(stat="identity")+theme_minimal()
        
        
    })
    
    observeEvent(input$save, {
        showNotification("The dashboard takes some time to request that much data from the Twitter API. While you wait, feel free to learn more about this app", action = a("About", onclick = "openTab('about')", href="#"), duration = NULL)
        t = as.character(input$hashtag)
        searchnumber <- as.numeric(input$searchnumber)
        tweets = search_tweets(t, n = searchnumber, include_rts=input$retweets, retryonratelimit = TRUE)
        tweets.df = data.frame(tweets)
        
        tweets.df$text=gsub("&amp", "", tweets.df$text)
        tweets.df$text = gsub("&amp", "", tweets.df$text)
        tweets.df$text = gsub("(RT|via)((?:\\b\\W*@\\w+)+)", "", tweets.df$text)
        tweets.df$text = gsub("@\\w+", "", tweets.df$text)
        tweets.df$text = gsub("[[:punct:]]", "", tweets.df$text)
        tweets.df$text = gsub("[[:digit:]]", "", tweets.df$text)
        tweets.df$text = gsub("http\\w+", "", tweets.df$text)
        tweets.df$text = gsub("[ \t]{2,}", "", tweets.df$text)
        tweets.df$text = gsub("^\\s+|\\s+$", "", tweets.df$text)
        tweets.df$text = gsub("[\r\n]", "", tweets.df$text)
        tweets.df$text <- iconv(tweets.df$text, "UTF-8", "ASCII", sub="")
        tweets.df <- lat_lng(tweets.df)
        tweets.df$latlng <- paste(as.character(tweets.df$lat), as.character(tweets.df$lng), sep =  ":") 
        
        tweets.df <- data.frame(tweets.df)
        emotions <- get_nrc_sentiment(tweets.df$text)
        tweets.df$emotionfelt <- colnames(emotions)[max.col(emotions,ties.method="first")]
        tweetswithlocation <- tweets.df %>% drop_na(lat, lng)
        
        
        output$summary5 <- renderGvis({
            #gvisMap(Andrew, "LatLong" , "Tip",options=list(showTip=TRUE, showLine=TRUE, enableScrollWheel=TRUE,mapType='hybrid', useMapTypeControl=TRUE, width=800,height=500))
            gvisMap(tweetswithlocation, locationvar="latlng" , tipvar= "text", options = list(height=550))
        })
        
        output$tweetloccount <- renderInfoBox({
            infoBox("Number of tweets with location", paste0(dim(tweetswithlocation)[1]) , icon=icon("thumbtack", lib = "font-awesome"))
        })
        
        output$mostactive <- renderInfoBox({
            infoBox("Most active tweet device", paste0(data.frame(sort(table(tweets.df$source)))[length(table(tweets.df$source)),1]), icon = icon("envelope-open-text", lib = "font-awesome"))
        })
        
        output$mostactivea <- renderInfoBox({
            infoBox("Most active twitter", paste0(data.frame(sort(table(tweets.df$screen_name)))[length(table(tweets.df$screen_name)),1]), icon = icon("user-circle", lib = "font-awesome"))
        })
        
        output$mostprominent <- renderInfoBox({
            infoBox("Most prominent disaster location", paste0(data.frame(sort(table(tweets.df$place_name)))[length(table(tweets.df$place_name)),1]), icon = icon("search-location", lib = "font-awesome"))
        })
        
        output$singlewcloud <- renderPlot({
            
            #Take out all leading spaces, tabs, links and mentions. 
            tweetstext <- tweets.df$text
            
            corpus <- Corpus(VectorSource(tweetstext))
            
            #Plot wordcloud
            wordcloud(corpus, max.words=400,random.order=FALSE, ordered.color = TRUE)
            
        })
        
        output$sentanalysis <- renderPlotly({
            # Emotions for each tweet using NRC dictionary
            
            emo_bar = colSums(emotions)
            emo_sum = data.frame(count=emo_bar, emotion=names(emo_bar))
            emo_sum$emotion = factor(emo_sum$emotion, levels=emo_sum$emotion[order(emo_sum$count, decreasing = TRUE)])
            
            # Visualize the emotions from NRC sentiments
            p <- plot_ly(emo_sum, x=~emotion, y=~count, type="bar", color=~emotion) %>%
                layout(xaxis=list(title=""), showlegend=FALSE,
                       title="Emotion Type for search item")
            p
        })
        
        output$wcloudgrouped <- renderPlot({
            #Create word cloud 
            
            wordcloud_tweet = c(
                paste(tweets.df$text[emotions$anger > 0], collapse=" "),
                paste(tweets.df$text[emotions$anticipation > 0], collapse=" "),
                paste(tweets.df$text[emotions$disgust > 0], collapse=" "),
                paste(tweets.df$text[emotions$fear > 0], collapse=" "),
                paste(tweets.df$text[emotions$joy > 0], collapse=" "),
                paste(tweets.df$text[emotions$sadness > 0], collapse=" "),
                paste(tweets.df$text[emotions$surprise > 0], collapse=" "),
                paste(tweets.df$text[emotions$trust > 0], collapse=" ")
            )
            
            # create corpus
            corpus = Corpus(VectorSource(wordcloud_tweet))
            
            # remove punctuation, convert every word in lower case and remove stop words
            
            corpus = tm_map(corpus, tolower)
            corpus = tm_map(corpus, removePunctuation)
            corpus = tm_map(corpus, removeWords, c(stopwords("english")))
            corpus = tm_map(corpus, stemDocument)
            
            # create document term matrix
            
            tdm = TermDocumentMatrix(corpus)
            
            # convert as matrix
            tdm = as.matrix(tdm)
            tdmnew <- tdm[nchar(rownames(tdm)) < 11,]
            
            # column name binding
            colnames(tdm) = c('anger', 'anticipation', 'disgust', 'fear', 'joy', 'sadness', 'surprise', 'trust')
            colnames(tdmnew) <- colnames(tdm)
            thecloud <- comparison.cloud(tdmnew, random.order=FALSE,
                                         colors = c("#00B2FF", "red", "#FF0099", "#6600CC", "green", "orange", "blue", "brown"),
                                         title.size=1, max.words=400, scale=c(2.5, 0.5), rot.per=0.4)
            thecloud
            
        })
        
        output$linechart <- renderPlot(
            ts_plot(tweets.df, by = "1 hours") +
                theme(plot.title = element_text(face = "bold")) +
                labs(
                    x = NULL, y = NULL,
                    title = "Frequency of search in recent Twitter statuses",
                    subtitle = "Twitter status (tweet) counts aggregated using one-hour intervals",
                    caption = "\nSource: Data collected from Twitter's REST API via rtweet"
                )
        )
        
        
    })
    
})

shinyApp(ui = ui, server = server)
