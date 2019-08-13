library(readr)

function(input, output) {
    
    # Filter data based on selections
    output$table <- DT::renderDataTable({
        DT::datatable({
            data <- read_csv("~/EPA Test/epa-water-quality-master/data/water_quality.csv")   %>%
                select(ptl,   ntl  ,chla, st    ,region ,lakename ) %>%
                mutate(
                st = factor(st),
                region =  factor(region),
                lakename  =  factor(lakename)
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