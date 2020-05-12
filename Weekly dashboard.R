# Weekly dashboard

library(easypackages)

libraries(c("readxl", "readr", "plyr", "dplyr", "ggplot2", "tidyverse", "reshape2", "scales", 'jsonlite', 'zoo', 'stats', 'fingertipsR', 'officer'))

github_repo_dir <- "~/Documents/Repositories/another_covid_repo"

capwords = function(s, strict = FALSE) {
  cap = function(s) paste(toupper(substring(s, 1, 1)),
                          {s = substring(s, 2); if(strict) tolower(s) else s},sep = "", collapse = " " )
  sapply(strsplit(s, split = " "), cap, USE.NAMES = !is.null(names(s)))}

options(scipen = 999)

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

# data ####

# Run daily tracker if you want to
# source(paste0(github_repo_dir, '/tracking_new_cases.R'))

daily_cases <- read_csv(paste0(github_repo_dir, '/ltla_sussex_daily_cases.csv'))

weekly_all_place_deaths <- read_csv(paste0(github_repo_dir, '/All_settings_deaths_occurrences.csv'))

# 01 March 2020 to 
dates_granular <- read_excel("~/Documents/Repositories/another_covid_repo/granular_mortality_file.xlsx", sheet = "Contents") %>% 
  filter(`Worksheet name` %in% c('Table 2', 'Table 5'))

la_asmr <- read_csv(paste0(github_repo_dir, '/mortality_01_march_to_date_la.csv'))
mosa_deaths <- read_csv(paste0(github_repo_dir, '/mortality_01_march_to_date_msoa.csv'))

place_of_death <- read_csv(paste0(github_repo_dir, '/Mortality_place_of_death_weekly.csv'))
care_home_ons <- read_csv(paste0(github_repo_dir, '/Care_home_death_occurrences_ONS_weekly.csv'))
cqc_ch_deaths <- read_csv(paste0(github_repo_dir, '/cqc_care_home_daily_deaths.csv'))


read_pptx(path = paste0(github_repo_dir, '/Death Slides - West Sussex V1.pptx'))

# slide 1 - table

tab_1 <- weekly_all_place_deaths %>% 
  filter(Name %in% c('Brighton and Hove', 'East Sussex', 'West Sussex', 'Sussex areas combined')) %>% 
  select(Name, Cause, Week_ending, Deaths) %>% 
  mutate(Week_ending = paste0('w/e ', ordinal(as.numeric(format(Week_ending, '%d'))), format(Week_ending, ' %b'))) %>% 
  mutate(Name = factor(Name, levels = c('Brighton and Hove', 'East Sussex', 'West Sussex', 'Sussex areas combined')))

date_labels <- unique(tab_1$Week_ending)

tab_1 <- tab_1 %>% 
  mutate(Week_ending = factor(Week_ending, levels =  date_labels)) %>% 
  spread(Cause, Deaths) %>% 
  mutate(`Non-Covid` = `All causes` - `COVID 19`) %>% 
  gather(key = 'Cause', value = 'Deaths', `All causes`:`Non-Covid`) %>% 
  spread(Week_ending, Deaths) %>% 
  arrange(Cause)

tab_1 %>% 
  write.csv(., paste0(github_repo_dir, '/weekly_deaths_table_1.csv'), row.names = FALSE, na = '')
  
# slide 2 - local figure plus crude rate per 100,000

wsx_all_cause <- weekly_all_place_deaths %>% 
  filter(Name == 'West Sussex') %>% 
  filter(Cause == 'All causes') %>% 
  mutate(Week_ending = factor(paste0('w/e ', ordinal(as.numeric(format(Week_ending, '%d'))), format(Week_ending, ' %b')), levels = date_labels)) 

latest_we <- subset(wsx_all_cause, Week_number == max(wsx_all_cause$Week_number), select = 'Week_ending')

wsx_wk_all_deaths_plot <- ggplot(wsx_all_cause,
       aes(x = Week_ending, 
           y = Deaths)) +
  geom_bar(stat = 'identity',
           fill = '#f8c000') +
  labs(title = paste0('Weekly all cause deaths; West Sussex; w/e 3rd Jan 2020 - ', latest_we$Week_ending),
       subtitle = 'By week of occurrence',
       x = 'Week',
       y = 'Number of deaths') +
  scale_y_continuous(breaks = seq(0,round_any(max(wsx_all_cause$Deaths, na.rm = TRUE), 50, ceiling),50),
                     limits = c(0,round_any(max(wsx_all_cause$Deaths, na.rm = TRUE), 50, ceiling))) +
  ph_theme() +
  annotate(geom = "text", 
           x = wsx_all_cause$Week_ending,
           y = wsx_all_cause$Deaths,
           label = wsx_all_cause$Deaths,
           size = 3, 
           fontface = "bold",
           vjust = -1) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = .5)) 

library(png)
library(gridExtra)

png(paste0(github_repo_dir, "/wsx_wk_all_deaths_plot.png"), width = 480, height = 250)
wsx_wk_all_deaths_plot
dev.off()

wsx_cov_non_cov <- weekly_all_place_deaths %>% 
  filter(Name == 'West Sussex') %>% 
  select(Name, Cause, Week_ending, Deaths) %>% 
  mutate(Week_ending = factor(paste0('w/e ', ordinal(as.numeric(format(Week_ending, '%d'))), format(Week_ending, ' %b')), levels = date_labels)) %>% 
  spread(Cause, Deaths) %>% 
  mutate(`Non-Covid` = `All causes` - `COVID 19`) %>%
  select(-`All causes`) %>% 
  gather(key = 'Cause', value = 'Deaths', `COVID 19`:`Non-Covid`) %>% 
  mutate(Cause = factor(Cause, levels = rev(c('Non-Covid', 'COVID 19')))) %>% 
  mutate(lab_posit = ifelse(Cause == 'Non-Covid', 1.5, -1))
  
wsx_wk_cause_deaths_plot <- ggplot(wsx_cov_non_cov,
       aes(x = Week_ending, 
           y = Deaths,
           fill = Cause,
           colour = Cause,
           label = Deaths)) +
  geom_bar(stat = 'identity',
           colour = '#ffffff') +
  geom_text(data = subset(wsx_cov_non_cov, Deaths > 0),
            position = 'stack',
            size = 3, 
            fontface = "bold",
            aes(vjust = lab_posit)) +
  labs(title = paste0('Weekly deaths; West Sussex; w/e 3rd Jan 2020 - ', latest_we$Week_ending),
       subtitle = 'By week of occurrence and by Covid-19 mentioned',
       x = 'Week',
       y = 'Number of deaths') +
  scale_fill_manual(values = c('#006d90','#003343')) +
  scale_colour_manual(values = c('#000000', '#ffffff')) +
  scale_y_continuous(breaks = seq(0,round_any(max(wsx_all_cause$Deaths, na.rm = TRUE), 50, ceiling),50),
                     limits = c(0,round_any(max(wsx_all_cause$Deaths, na.rm = TRUE), 50, ceiling))) +
  ph_theme() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = .5),
        legend.position = c(.1,.8))  +
  guides(colour = FALSE)

png(paste0(github_repo_dir, "/wsx_wk_cause_deaths_plot.png"), width = 480, height = 250)
wsx_wk_cause_deaths_plot
dev.off()

wsx_care_home <- care_home_ons %>% 
  filter(Name == 'West Sussex') %>% 
  filter(Cause == 'All causes') %>% 
  mutate(Week_ending = factor(paste0('w/e ', ordinal(as.numeric(format(Week_ending, '%d'))), format(Week_ending, ' %b')), levels = date_labels)) 

latest_we <- subset(wsx_care_home, Week_number == max(wsx_care_home$Week_number), select = 'Week_ending')

wsx_wk_care_home_all_deaths_plot <- ggplot(wsx_care_home,
       aes(x = Week_ending, 
           y = Deaths)) +
  geom_bar(stat = 'identity',
           fill = '#70AD47') +
  labs(title = paste0('Weekly all cause care home deaths; West Sussex; w/e 3rd Jan 2020 - ', latest_we$Week_ending),
       subtitle = 'By week of occurrence',
       x = 'Week',
       y = 'Number of deaths') +
  scale_y_continuous(breaks = seq(0,round_any(max(wsx_care_home$Deaths, na.rm = TRUE), 20, ceiling),20),
                     limits = c(0,round_any(max(wsx_care_home$Deaths, na.rm = TRUE), 20, ceiling))) +
  ph_theme() +
  annotate(geom = "text", 
           x = wsx_care_home$Week_ending,
           y = wsx_care_home$Deaths,
           label = wsx_care_home$Deaths,
           size = 3, 
           fontface = "bold",
           vjust = -1) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = .5)) 

png(paste0(github_repo_dir, "/wsx_wk_care_home_all_deaths_plot.png"), width = 480, height = 250)
wsx_wk_care_home_all_deaths_plot
dev.off()

wsx_place <- place_of_death %>% 
  filter(Name == 'West Sussex') %>% 
  filter(Cause == 'All causes')  %>% 
  mutate(Week_ending = factor(paste0('w/e ', ordinal(as.numeric(format(Week_ending, '%d'))), format(Week_ending, ' %b')), levels = date_labels)) %>% 
  mutate(Place_of_death = factor(Place_of_death, levels = rev(c("Home", "Care home", "Hospital", "Hospice", 'Elsewhere (including other communal establishments)'))))
 
wsx_place_death_all_cause_plot <- ggplot(wsx_place,
       aes(x = Week_ending, 
           y = Deaths,
           fill = Place_of_death)) +
  geom_bar(stat = 'identity',
           colour = '#ffffff') +
  labs(title = paste0('Weekly all cause deaths; West Sussex; w/e 3rd Jan 2020 - ', latest_we$Week_ending),
       subtitle = 'By week of occurrence and place of death',
       x = 'Week',
       y = 'Number of deaths') +
  scale_fill_manual(values = rev(c("#f6de6c", "#ed8a46", "#be3e2b","#34738f", '#4837bc')),
                    breaks = c("Home", "Care home", "Hospital", "Hospice", 'Elsewhere (including other communal establishments)'),
                    name = 'Place of death') +
  scale_y_continuous(breaks = seq(0,round_any(max(wsx_all_cause$Deaths, na.rm = TRUE), 50, ceiling),50),
                     limits = c(0,round_any(max(wsx_all_cause$Deaths, na.rm = TRUE), 50, ceiling))) +
  ph_theme() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = .5),
        legend.position = c(.39,.85),
        legend.key.size = unit(0.5, "lines")) +
  guides(fill = guide_legend(nrow = 2, byrow = TRUE))

png(paste0(github_repo_dir, "/wsx_place_death_all_cause_plot.png"), width = 480, height = 250)
wsx_place_death_all_cause_plot
dev.off()

# slide 3 - local asmr data between 01 March and two weeks prior
# slide 4 - msoa for sussex between 01 March and two weeks prior
# slide 5 - deaths in care homes

