library(shiny)

# Define UI for application that draws a histogram
fluidPage(

  # Application title
  titlePanel("Hello Shiny!"),

  # Sidebar with a slider input for the number of bins
  sidebarLayout(
    sidebarPanel(
      sliderInput("ReviewCount",
                  "Review number lower bound:",
                  min = 1,
                  max = 1000,
                  value = 400),
      sliderInput("PriceRange",
                  "Price Range:",
                  min = 1,
                  max = 5,
                  value = 1)
    ),
    # Show a plot of the generated distribution
    mainPanel(
      plotOutput("distPlot")
    )
  )
)
