
library(easypackages)

libraries(c("readxl", "readr", "plyr", "dplyr", "ggplot2", "tidyverse", "reshape2", "scales", 'jsonlite', 'zoo', 'stats', 'fingertipsR', 'lemon', 'spdplyr', 'geojsonio', 'rmapshaper', 'jsonlite', 'rgeos', 'sp', 'sf', 'maptools', 'png', 'epitools', 'officer','flextable'))


ph_theme = function(){
  theme( 
    plot.title = element_text(colour = "#000000", face = "bold", size = 10),    
    plot.subtitle = element_text(colour = "#000000", size = 10),
    panel.grid.major.x = element_blank(), 
    panel.grid.minor.x = element_blank(),
    panel.background = element_rect(fill = "#FFFFFF"), 
    panel.grid.major.y = element_line(colour = "#E7E7E7", size = .3),
    panel.grid.minor.y = element_blank(), 
    strip.text = element_text(colour = "#000000", size = 10, face = "bold"), 
    strip.background = element_blank(), 
    axis.ticks = element_line(colour = "#dbdbdb"), 
    legend.position = "bottom", 
    legend.title = element_text(colour = "#000000", size = 9, face = "bold"), 
    legend.background = element_rect(fill = "#ffffff"), 
    legend.key = element_rect(fill = "#ffffff", colour = "#ffffff"), 
    legend.text = element_text(colour = "#000000", size = 9), 
    axis.text.y = element_text(colour = "#000000", size = 8), 
    axis.text.x = element_text(colour = "#000000", angle = 0, hjust = 1, vjust = .5, size = 8), 
    axis.title =  element_text(colour = "#000000", size = 9, face = "bold"),   
    axis.line = element_line(colour = "#dbdbdb")
  ) 
}

github_repo_dir <- "~/Documents/Repositories/another_covid_repo"

Areas_to_loop <- c('Brighton and Hove','East Sussex', 'West Sussex')
All_areas <- c('Brighton and Hove', 'East Sussex', 'West Sussex', 'Sussex areas combined')
i = 1
Area_x <- Areas_to_loop[i]

tab_1_raw <- read_csv(paste0(github_repo_dir, '/All_settings_deaths_occurrences.csv')) %>% 
  filter(Name %in% All_areas) %>% 
  mutate(Date_we = Week_ending) %>% 
  mutate(Week_ending = paste0(ordinal(as.numeric(format(Week_ending, '%d'))), format(Week_ending, '\n%b')))
  
date_labels <- unique(tab_1_raw$Week_ending)
registered_by <- tab_1_raw %>% 
  filter(Date_we == max(Date_we)) %>% 
  select(Date_we) %>% 
  unique() %>% 
  mutate(registered_by = Date_we + 8)

tab_1 <- tab_1_raw %>% 
  select(Name, Cause, Week_ending, Deaths) %>% 
  mutate(Name = factor(Name, levels = All_areas)) %>% 
  mutate(Week_ending = factor(Week_ending, levels =  date_labels)) %>% 
  spread(Cause, Deaths) %>% 
  mutate(`Non-Covid` = `All causes` - `COVID 19`) %>% 
  gather(key = 'Cause', value = 'Deaths', `All causes`:`Non-Covid`) %>% 
  mutate(Deaths = ifelse(Deaths == 0, '-', Deaths)) %>% 
  spread(Week_ending, Deaths) %>% 
  arrange(Cause)

tab_1_all <-  tab_1 %>% 
  filter(Cause == 'All causes') %>% 
  rename('All causes' = Name) %>% 
  select(-Cause) 

bord_style <- fp_border(color = "black", style = "solid", width = .5)

ft_tab_1_all <- flextable(tab_1_all) %>% 
  width(width = .45) %>%
  width(j = 1, width = 1.3) %>%
  fontsize(part = "header", size = 9) %>% 
  fontsize(part = "body", size = 9) %>% 
  font(fontname = "Calibri") %>% 
  height_all(height = .3) %>% 
  valign(valign = "middle", part = "all") %>% 
  bold(part = "header")%>% 
  align(j = 1, align = 'left') %>% 
  hline(i = 1, border = bord_style, part = 'header') %>% 
  hline_bottom(border = bord_style ) %>% 
  hline_top(border = bord_style, part = "all" )

tab_1_covid <-  tab_1 %>% 
  filter(Cause == 'COVID 19') %>% 
  rename('COVID-19' = Name) %>% 
  select(-Cause) 

ft_tab_1_covid <- flextable(tab_1_covid) %>% 
  width(width = .45) %>%
  width(j = 1, width = 1.3) %>%
  fontsize(part = "header", size = 9) %>% 
  fontsize(part = "body", size = 9) %>% 
  font(fontname = "Calibri") %>% 
  height_all(height = .3) %>% 
  valign(valign = "middle", part = "all") %>% 
  bg(bg = "#DAE3F3", part = "all")%>% 
  bold(part = "header") %>% 
  align(j = 1, align = 'left') %>% 
  hline(i = 1, border = bord_style, part = 'header') %>% 
  hline_bottom(border = bord_style ) %>% 
  hline_top(border = bord_style, part = "all" )

tab_1_noncovid <-  tab_1 %>% 
  filter(Cause == 'Non-Covid') %>% 
  rename('Non-COVID-19' = Name) %>% 
  select(-Cause) 

ft_tab_1_noncovid <- flextable(tab_1_noncovid) %>% 
  width(width = .45) %>%
  width(j = 1, width = 1.3) %>%
  fontsize(part = "header", size = 9) %>% 
  fontsize(part = "body", size = 9) %>% 
  font(fontname = "Calibri") %>% 
  height_all(height = .3) %>% 
  valign(valign = "middle", part = "all") %>% 
  bg(bg = "#FFF2CC", part = "all") %>% 
  bold(part = "header")%>% 
  align(j = 1, align = 'left') %>% 
  hline(i = 1, border = bord_style, part = 'header') %>% 
  hline_bottom(border = bord_style ) %>% 
  hline_top(border = bord_style, part = "all" )

# Local figures ####

# Redo date_labels
weekly_all_place_deaths <- read_csv(paste0(github_repo_dir, '/All_settings_deaths_occurrences.csv'))

date_labels <- gsub('\n', ' ', paste0('w/e ', date_labels))

area_x_all_cause <- weekly_all_place_deaths %>% 
  filter(Name == Area_x) %>% 
  filter(Cause == 'All causes') %>% 
  mutate(Week_ending = factor(paste0('w/e ', ordinal(as.numeric(format(Week_ending, '%d'))), format(Week_ending, ' %b')), levels = date_labels)) 

latest_we <- subset(area_x_all_cause, Week_number == max(area_x_all_cause$Week_number), select = 'Week_ending')

area_x_wk_all_deaths_plot <- ggplot(area_x_all_cause,
                                    aes(x = Week_ending, 
                                        y = Deaths)) +
  geom_bar(stat = 'identity',
           fill = '#f8c000') +
  labs(title = paste0('Weekly all cause deaths; ',Area_x,'; w/e 3rd Jan 2020 - ', latest_we$Week_ending),
       subtitle = 'By week of occurrence',
       x = 'Week',
       y = 'Number of deaths') +
  scale_y_continuous(breaks = seq(0,ifelse(Area_x == 'Brighton and Hove', round_any(max(area_x_all_cause$Deaths, na.rm = TRUE), 50, ceiling), ifelse(round_any(max(area_x_all_cause$Deaths, na.rm = TRUE), 50, ceiling) < 250, 250, round_any(max(area_x_all_cause$Deaths, na.rm = TRUE), 50, ceiling))),ifelse(Area_x == 'Brighton and Hove',25, 50)),
                     limits = c(0,ifelse(Area_x == 'Brighton and Hove', round_any(max(area_x_all_cause$Deaths, na.rm = TRUE), 50, ceiling), ifelse(round_any(max(area_x_all_cause$Deaths, na.rm = TRUE), 50, ceiling) < 250, 250, round_any(max(area_x_all_cause$Deaths, na.rm = TRUE), 50, ceiling))))) +
  ph_theme() +
  annotate(geom = "text", 
           x = area_x_all_cause$Week_ending,
           y = area_x_all_cause$Deaths,
           label = area_x_all_cause$Deaths,
           size = 3, 
           fontface = "bold",
           vjust = -1) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = .5)) 



# 
pres_doc <- read_pptx(paste0(github_repo_dir, '/Source files/weekly_mortality_placeholder_template.pptx'))
# 
layout_summary(pres_doc)
layout_properties(pres_doc, 'one_image_text_right')

read_pptx(paste0(github_repo_dir, '/Source files/weekly_mortality_placeholder_template.pptx')) %>%  
  add_slide(layout = "big_table", master = "Office Theme") %>% 
  ph_with(value = paste0('Deaths occurring up to ', format(registered_by$Date_we, '%d %B'), '; registered by ', format(registered_by$registered_by, '%d %B')),
          location = ph_location_label(ph_label = 'Text Placeholder 6')) %>%
  ph_with(value = ft_tab_1_all,
          location = ph_location_label(ph_label = 'Table Placeholder 8')) %>%
  ph_with(value = ft_tab_1_covid,
          location = ph_location_label(ph_label = 'Table Placeholder 2')) %>%
  ph_with(value = ft_tab_1_noncovid,
          location = ph_location_label(ph_label = 'Table Placeholder 4'))  %>% 
  add_slide(layout = "quad_image", master = "Office Theme") %>% 
  ph_with(external_img(src = paste0(github_repo_dir, '/Outputs/004_', gsub(' ', '_', Area_x) ,'_wk_all_deaths_plot.png')),
          location = ph_location_label(ph_label = 'Picture Placeholder 6')) %>%
  ph_with(external_img(src = paste0(github_repo_dir, '/Outputs/005_', gsub(' ', '_', Area_x) ,'_wk_cause_deaths_plot.png')),
          location = ph_location_label(ph_label = 'Picture Placeholder 8')) %>%
  ph_with(external_img(src = paste0(github_repo_dir, '/Outputs/006_', gsub(' ', '_', Area_x) ,'_wk_care_home_all_deaths_plot.png')),
          location = ph_location_label(ph_label = 'Picture Placeholder 10')) %>%
  ph_with(external_img(src = paste0(github_repo_dir, '/Outputs/007_', gsub(' ', '_', Area_x) ,'_place_death_all_cause_plot.png')),
          location = ph_location_label(ph_label = 'Picture Placeholder 12')) %>%
  add_slide(layout = "one_image_text_right", master = "Office Theme") %>% 
  ph_with(value = paste0('Crude rate of all cause mortality; to week ending ', format(registered_by$Date_we, '%d %B'), '; registered by ', format(registered_by$registered_by, '%d %B')),
          location = ph_location_label(ph_label = 'Text Placeholder 6')) %>%
  ph_with(external_img(src = paste0(github_repo_dir, '/Outputs/008_crude_rate_plot.png')),
          location = ph_location_label(ph_label = 'Picture Placeholder 8')) %>%
  ph_with(value = paste0('A crude rate is calculated using the mid-2018 population estimates (all ages) for each area. Note that some areas in Sussex, particularly West Sussex, have an older population compared with England and so the rate is usually, and expectedly, above the national rate.'),
          location = ph_location_label(ph_label = 'Text Placeholder 10')) %>%

  ph_with(value = paste0('Age/sex standardised rates are not currently available from the weekly ONS realease, although cumulative data for specific time periods (March-May 2020) are available and are presented later in this slide deck.'),
          location = ph_location_label(ph_label = 'Text Placeholder 12')) %>%
  print(paste0(github_repo_dir, '/Outputs/Weekly_mortality_test.pptx'))

