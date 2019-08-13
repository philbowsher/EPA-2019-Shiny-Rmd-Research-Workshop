library(tidyverse)
library(plotly)

data <- read_csv("~/EPA Test/epa-water-quality-master/data/water_quality.csv")   %>%
    select(ptl,   ntl  ,chla, st    ,region) %>%
    mutate(
        st = factor(st),
        region =  factor(region)
    )

function(input, output) {
    
    dataset <- reactive({
        data[sample(nrow(data), input$sampleSize),]
    })
    
    output$plot <- renderPlot({
        
        p <- ggplot(dataset(), aes_string(x=input$x, y=input$y)) + geom_point()
        
        if (input$color != 'None')
            p <- p + aes_string(color=input$color)
        
        facets <- paste(input$facet_row, '~', input$facet_col)
        if (facets != '. ~ .')
            p <- p + facet_grid(facets)
        
        if (input$jitter)
            p <- p + geom_jitter()
        if (input$smooth)
            p <- p + geom_smooth()
        
        print(p)
        
    })
    
    
    # Filter data based on selections
    output$table <- DT::renderDataTable({
        DT::datatable({
            data <- read_csv("~/EPA Test/epa-water-quality-master/data/water_quality.csv")   %>%
                select(ptl,   ntl  ,chla, st    ,region ) %>%
                mutate(
                    st = factor(st),
                    region =  factor(region)
                )
            if (input$region != "All") {
                data <- data[data$region == input$region,]
            }
            
            data
            
        },
        
        filter = list(position = 'top', clear = FALSE),
        options = list(pageLength = 15), 
        rownames = FALSE)
    })
    
    
    
}