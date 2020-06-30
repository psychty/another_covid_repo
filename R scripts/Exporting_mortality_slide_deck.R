
library(easypackages)

libraries(c("readxl", "readr", "plyr", "dplyr", "ggplot2", "tidyverse", "reshape2", "scales", 'jsonlite', 'zoo', 'stats', 'fingertipsR', 'lemon', 'spdplyr', 'geojsonio', 'rmapshaper', 'jsonlite', 'rgeos', 'sp', 'sf', 'maptools', 'png', 'epitools', 'officer','flextable'))

github_repo_dir <- "~/Documents/Repositories/another_covid_repo"

Areas_to_loop <- c('Brighton and Hove','East Sussex', 'West Sussex')
All_areas <- c('Brighton and Hove', 'East Sussex', 'West Sussex', 'Sussex areas combined')

tab_1 <- read_csv(paste0(github_repo_dir, '/All_settings_deaths_occurrences.csv')) %>% 
  filter(Name %in% All_areas) %>% 
  select(Name, Cause, Week_ending, Deaths) %>% 
  # mutate(Week_ending = paste0('w/e ', ordinal(as.numeric(format(Week_ending, '%d'))), format(Week_ending, ' %b'))) %>% 
  mutate(Week_ending = paste0(ordinal(as.numeric(format(Week_ending, '%d'))), format(Week_ending, '\n%b'))) %>% 
  mutate(Name = factor(Name, levels = All_areas))

date_labels <- unique(tab_1$Week_ending)

tab_1 <- tab_1 %>% 
  mutate(Week_ending = factor(Week_ending, levels =  date_labels)) %>% 
  spread(Cause, Deaths) %>% 
  mutate(`Non-Covid` = `All causes` - `COVID 19`) %>% 
  gather(key = 'Cause', value = 'Deaths', `All causes`:`Non-Covid`) %>% 
  spread(Week_ending, Deaths) %>% 
  arrange(Cause)

tab_1_all <- tab_1 %>% 
  filter(Cause == 'All causes') %>% 
  rename('All causes' = Name) %>% 
  select(-Cause)

ft_tab_1_all <- flextable(tab_1_all) %>% 
  width(width = 1.4) %>% 
  fontsize(part = "header", size = 9) %>% 
  fontsize(part = "body", size = 8) %>% 
  font(fontname = "Verdana") %>% 
  fit_to_width(max_width = 7) %>% 
  # autofit() %>% 
  height_all(height = .15) %>% 
  valign(valign = "top", part = "all") 

pres_doc <- read_pptx(paste0(github_repo_dir, '/Source files/weekly_mortality_placeholder_template.pptx'))

layout_summary(pres_doc)
layout_properties(pres_doc, 'big_table') 

read_pptx(paste0(github_repo_dir, '/Source files/weekly_mortality_placeholder_template.pptx')) %>%  
  add_slide(layout = "big_table", master = "Office Theme") %>% 
  ph_with(value = paste0('Deaths occurring up to ', ' x ', ', registered by ', ' xx'),
          location = ph_location_label(ph_label = 'Text Placeholder 6')) %>%
  ph_with(value = ft_tab_1_all,
          location = ph_location_label(ph_label = 'Table Placeholder 8')) %>%
  print(paste0(github_repo_dir, '/Outputs/Weekly_mortality_test.pptx') )
