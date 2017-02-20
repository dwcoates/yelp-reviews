library(shiny)

# Define server logic required to draw a histogram
function(input, output) {

  # Expression that generates a histogram. The expression is
  # wrapped in a call to renderPlot to indicate that:
  #
  #  1) It is "reactive" and therefore should be automatically
  #     re-executed when inputs change
  #  2) Its output type is a plot

  output$distPlot <- renderPlot({
    r <- filter(business, review_count > input$ReviewCount & as.numeric(price.range) == input$PriceRange)

    ggplot(r, aes(x=one, y=four, color = price.range)) +
        geom_point() +
        guides(color=FALSE) +
        scale_y_continuous(limits = c(0, 1)) +
        scale_x_continuous(limits = c(0, 1)) +
        ggtitle("Low Price Businesses")
  })}
