library(DT)
library(readr)
library(shiny)
library(tidyverse)

water <- read_csv("~/EPA Test/epa-water-quality-master/data/water_quality.csv")

fluidPage(
    titlePanel("Basic DataTable for Water Quality"),
    
    
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