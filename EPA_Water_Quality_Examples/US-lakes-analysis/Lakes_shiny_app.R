
library(shiny)
library(shinythemes)
library(ggplot2)

lakes.12.ts <- read.csv("lakes12.ts.csv", header = T)
lakes.12.raw <- read.csv("lakes_data2012.csv", header = T)
names.ts <- names(lakes.12.ts)

# Define UI for application that draws a histogram
ui <- fluidPage(theme = shinytheme("lumen"),
    
    # Application title
    titlePanel("Continental US Lakes water quality data "),
    
    h4("This data was obtained from the US EPA national lakes assesment for the year 2012. The raw data can be found at",
       a(href="https://www.epa.gov/national-aquatic-resource-surveys/data-national-aquatic-resource-surveys", "this"),
       "address for free."),
    
    p( strong("Note:"), "The data used in this visualization has been cleaned and log transformed.", style="color:brown"),
    
    p("If you are interested with this kind of data, please visit back after a while 
      as I will be putting additional interactive visualization in the days to come"),
    
    # Top Sidebar with a slider input for number of bins 
    sidebarLayout(
        sidebarPanel(
            selectInput("xcol1", "Parameters:",
                        choices = names.ts, 
                        selected=names.ts[[3]]),
            
            sliderInput("br", "Number of breaks:",
                        min = 10, max = 100, step=5, value = 40)
        ),
        
        # Show a plot of the generated distribution
        mainPanel(
            plotOutput("parPlot"),
            h2("Summary statistics"),
            p("The summary statistics is calculated on the original untrasformed data."),
            verbatimTextOutput("summry"),
            br(),
            hr()
            
            
        )
    ),
    
    
    # Bottom sidebar
    sidebarLayout(
        sidebarPanel(
            selectInput('xcol', 'X Variable', names.ts, selected=names.ts[[3]]),
            
            selectInput('ycol', 'Y Variable', names.ts, selected=names.ts[[4]]),
            
            numericInput("span", "Adjust smoothness", value=0.2, min = 0.1, max=1, step = 0.1)
        ),
        
        # Show a plot of the generated distribution
        mainPanel(
            plotOutput(outputId = "biplot")
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
    
    # First output
    output$parPlot = renderPlot({
        x <- lakes.12.ts[,input$xcol1]
        bins <- seq(min(x), max(x), length.out = input$br + 1)
        hist(x, col="chartreuse4", breaks=bins, freq= F, xlab=input$xcol1, main="")
        lines(density(x, na.rm = T), lwd=2, col="tomato")
    })
    
    output$summry = renderPrint({
      (summary(lakes.12.raw[, input$xcol1]))
    })
    
    # Second output
    # Combine the selected variables into a new data frame
    selectedData <- reactive({
        dt <- lakes.12.ts[, c(input$xcol, input$ycol)]
    })
    
    output$biplot <- renderPlot({
        ggplot(selectedData(), aes(x=lakes.12.ts[,input$xcol],y=lakes.12.ts[,input$ycol])) + 
            geom_smooth(method = "gam", span=input$span, se = TRUE) +
            labs(x=input$xcol, y=input$ycol) +
            geom_point(size=4, color="tomato") 
        
    })
}

# Run the application 
shinyApp(ui = ui, server = server)
