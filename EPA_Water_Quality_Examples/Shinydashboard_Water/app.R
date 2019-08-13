library(shiny)
library(shinydashboard)
library(tidyverse)
library(plotly)
library(shinyWidgets)
library(leaflet)
library(sf)
library(broom)
library(DT)

water <- read_csv("data/water_quality.csv")

vars_all <- c("ptl", "chla", "ntl") 

# referenes for radio buttons
measures_lookup <- c("Chlorophylla", "Total Phosphorus", "Total Nitrogen")
names(measures_lookup) <- c("chla", "ptl", "ntl")

shinyApp(
  ui = dashboardPage(
    dashboardHeader(
      title = "US Lake Water Quality",
      titleWidth = 350
    ),
    dashboardSidebar(
      width = 350,
      sidebarMenu(
        menuItem("Menu Item"),

        multiInput(
          inputId = "states", label = "States :",
          choices = state.abb,
          selected = c("CA", "OR", "WA", "NV"), width = "400px",
          options = list(
            enable_search = TRUE,
            non_selected_header = "Select States:",
            selected_header = "You have selected:"
          )
        ),
        # y - variable selection 
        radioButtons("y_var", "Choose response variable:",
                     choiceNames = list(
                       "Chlorophylla",
                       "Total Phosphorus",
                       "Total Nitrogen"
                     ),
                     choiceValues = list(
                       "chla", "ptl", "ntl"
                     )),
        # x var selection
        radioButtons("x_var", "Choose predictor variable:",
                     choiceNames = list(
                       "Chlorophylla",
                       "Total Phosphorus",
                       "Total Nitrogen"
                     ),
                     choiceValues = list(
                       "chla", "ptl", "ntl"
                     ), selected = "ptl")
      )
    ),
    dashboardBody(
      
      fluidRow(width = "100%",
               box(width = 6, 
                 leafletOutput( "ggregion")
               ),
               box(
                   column(
                     width = 12,
                     plotlyOutput("ggmod")
                   )
               )
      ),
      
      fluidRow(

        # model output
        box(width = 6, height = 430,
          column(width = 12,
            fluidRow(
              DT::DTOutput("raw_obs")
            )
          )
        ),
        box(width = 6, height = 430,
            column(
              height = 12, 
              width = 12, 
               fluidRow(
                 DT::DTOutput("mod_output")
                 ))
        )
      )
    )
  ),
  
  server = function(input, output) { 
    
    # identify z variable
    z_var <- reactive({
      
      vars_all[!vars_all %in% paste(c(input$x_var, input$y_var))]
      
    })
    
    # filter the data
    dat <- reactive({
      water %>% 
        filter(st %in%  input$states) %>% 
        rename(
          y = input$y_var,
          x = input$x_var,
          z = z_var()
        )
    })
    
    output$raw_obs <- DT::renderDT({
      water %>% 
        filter(st %in% input$states) %>% 
        select(Name = lakename,
               Chlorophylla = chla,
               Nitrogen = ntl,
               Phosphorus = ptl)
      }, options = list(pageLength = 8))
    
    output$ggregion <- renderLeaflet({
      dat() %>% 
        mutate(msg = glue::glue({
          "Name: {lakename}<br>
    {measures_lookup[[input$x_var]]}: {x}<br>
    {measures_lookup[[input$y_var]]}: {y}<br>
    {measures_lookup[[z_var()]]}: {z}<br>
    "})) %>% 
        st_as_sf(coords = c("lon_dd", "lat_dd")) %>% 
        leaflet() %>% 
        addTiles() %>% 
        addMarkers(popup = ~msg)
        
    })
    
    # render model plot
    output$ggmod <- renderPlotly({
      
       ggplot(dat(), aes(x, y)) + 
        geom_point(alpha = .4) + 
        geom_smooth(method = "lm", alpha = .5) + 
        labs(x = measures_lookup[[input$x_var]], y = measures_lookup[[input$y_var]],
             #title = "US Water Quality",
             title = glue::glue("US Water Quality\nStates: {paste(input$states, collapse = ', ')}")) +
        theme_minimal() + 
        scale_x_log10() + 
        scale_y_log10() 

    }) 
    
    # model output
    output$mod_output <- DT::renderDT({
      
      mod <- lm(log10(y) ~ log10(x) , dat())

      estimates <- broom::tidy(mod) %>% 
        mutate(term = case_when(
          term == "x" ~ measures_lookup[[input$x_var]],
          term == "z" ~ measures_lookup[[z_var()]],
          TRUE ~ term
        ),
        `Estimate (SE)` = glue::glue("{round(estimate, 2)} ({round(std.error, 2)})"),
        `p-value` = round(p.value, 3)) %>% 
        select(Term = term, `Estimate (SE)`, `p-value`)
    
      
      bind_rows(
        mutate_all(estimates, as.character), 
        tibble(Term = "", `Estimate (SE)` = "", `p-value` = ""),
        glance(mod) %>% 
          select(R2 = 1, `Adj. R2` = 2, AIC, `DF` = df.residual) %>% 
          gather(Term, `Estimate (SE)`) %>% 
          mutate(`Estimate (SE)` = as.character(round(`Estimate (SE)`, 2)),
                 `p-value` = ""))
      
  
    }, autoHideNavigation = TRUE)
    
    # summary output
    # output$summary_output <- render_gt({
    #   summary_gt <- dat() %>% 
    #     gather(Variable, Measure, x, y, z) %>% 
    #     select(Variable, Measure) %>% 
    #     group_by(Variable) %>% 
    #     summarise_at(vars(Measure), list(`Mean` = mean, `Std. Dev.` = sd, `Median` = median),
    #                  na.rm = TRUE) %>% 
    #     mutate(Variable = str_replace_all(Variable, measures_lookup))
    #   
    #   summary_gt
    #   
    # })
    
    
    }
)

