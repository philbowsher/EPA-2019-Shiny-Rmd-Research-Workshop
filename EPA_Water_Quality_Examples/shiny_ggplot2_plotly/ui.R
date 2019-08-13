library(DT)
library(tidyverse)
library(plotly)

dataset <- read_csv("~/EPA Test/epa-water-quality-master/data/water_quality.csv")   %>%
    select(ptl,   ntl  ,chla, st    ,region ) %>%
    mutate(
        st = factor(st),
        region =  factor(region)
    )

navbarPage("Navbar!",
           tabPanel("Plot",
                    
                    fluidPage(
                        
                        title = "Water Explorer",
                        
                        plotlyOutput('plot', height = 350),
                        
                        hr(),
                        
                        fluidRow(
                            column(3,
                                   h4("Water Explorer"),
                                   sliderInput('sampleSize', 'Sample Size', 
                                               min=1, max=nrow(dataset),
                                               value=min(700, nrow(dataset)), 
                                               step=6, round=0),
                                   br(),
                                   checkboxInput('jitter', 'Jitter'),
                                   checkboxInput('smooth', 'Smooth')
                            ),
                            column(4, offset = 1,
                                   selectInput('x', 'X', names(dataset)),
                                   selectInput('y', 'Y', names(dataset), names(dataset)[[2]]),
                                   selectInput('color', 'Color', c('None', names(dataset)))
                            ),
                            column(4,
                                   selectInput('facet_row', 'Facet Row',
                                               c(None='.', names(dataset[sapply(dataset, is.factor)]))),
                                   selectInput('facet_col', 'Facet Column',
                                               c(None='.', names(dataset[sapply(dataset, is.factor)])))
                            )
                        )
                    )
           ),
           
           tabPanel("Data",
                    fluidPage(
                        titlePanel("Basic DataTable for Water Data"),
                        
                        
                        # Create a new Row in the UI for selectInputs
                        fluidRow(
                            column(4,
                                   selectInput("region",
                                               "Region:",
                                               c("All",
                                                 unique(as.character(water$region))))
                            )
                        )
                        ,
                        # Create a new row for the table.
                        fluidRow(
                            DT::dataTableOutput("table")
                        )
                    )
           )
)
