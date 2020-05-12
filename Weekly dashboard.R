# Weekly dashboard

library(easypackages)

libraries(c("readxl", "readr", "plyr", "dplyr", "ggplot2", "tidyverse", "reshape2", "scales", 'jsonlite', 'zoo', 'stats', 'fingertipsR', 'officer', 'lemon'))

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
msoa_deaths <- read_csv(paste0(github_repo_dir, '/mortality_01_march_to_date_msoa.csv'))

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

# Extra - rate all causes

all_cause_rate <- weekly_all_place_deaths %>% 
  filter(Name %in% c('West Sussex', 'Brighton and Hove', 'East Sussex', 'Sussex areas combined', 'England')) %>% 
  filter(Cause == 'All causes') %>% 
  mutate(Week_ending = factor(paste0('w/e ', ordinal(as.numeric(format(Week_ending, '%d'))), format(Week_ending, ' %b')), levels = date_labels)) %>% 
  select(Name, Week_ending, Deaths_crude_rate_per_100000, Deaths_crude_rate_lci, Deaths_crude_rate_uci)

England_all_cause_rate <- all_cause_rate %>% 
  filter(Name == 'England') %>% 
  rename(England = Name,
         Eng_deaths_rate = Deaths_crude_rate_per_100000,
         Eng_lci = Deaths_crude_rate_lci,
         Eng_uci = Deaths_crude_rate_uci) %>% 
  select(Week_ending, Eng_deaths_rate, Eng_lci, Eng_uci)
  
all_cause_rate_df <- all_cause_rate %>% 
  filter(Name != 'England') %>% 
  mutate(Name = factor(Name, levels = c('Brighton and Hove', 'East Sussex', 'West Sussex','Sussex areas combined'))) %>% 
  left_join(England_all_cause_rate, by = 'Week_ending') %>% 
  mutate(significance = factor(ifelse(Deaths_crude_rate_uci < Eng_lci, 'Significantly lower', ifelse(Deaths_crude_rate_lci > Eng_uci, 'Significantly higher', 'Statistically similar')), levels = c('Significantly lower', 'Statistically similar', 'Significantly higher')))

crude_rate_plot <- ggplot(all_cause_rate_df) +
  geom_line(data = England_all_cause_rate, aes(x = Week_ending, y = Eng_deaths_rate, group = '1'), colour = '#777777') +
  geom_line(aes(x = Week_ending,
                    y = Deaths_crude_rate_per_100000,
                    group = Name)) +
  geom_point(aes(x = Week_ending,
                 y = Deaths_crude_rate_per_100000,
                 fill = significance,
                 group = Name),
             size = 3,
             colour = '#ffffff',
             shape = 21) +
  labs(title = paste0('Weekly all cause deaths per 100,000 population; w/e 3rd Jan 2020 - ', latest_we$Week_ending),
       subtitle = 'By week of occurrence',
       caption = 'Reference line = England',
       x = 'Week',
       y = 'Number of deaths\nper 100,000') +
  scale_fill_manual(values = c("#92D050", "#FFC000","#C00000"),
                    name = 'Compared\nto England') +
  scale_y_continuous(breaks = seq(0,round_any(max(all_cause_rate_df$Deaths_crude_rate_uci, na.rm = TRUE), 15, ceiling),15),
                     limits = c(0,round_any(max(all_cause_rate_df$Deaths_crude_rate_uci, na.rm = TRUE), 10, ceiling))) +
  ph_theme() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = .5),
        legend.key.size = unit(0.5, "lines")) +
  facet_rep_grid(Name ~ .) +
  theme(strip.text = element_blank()) +
  annotate(geom = "text", label = levels(all_cause_rate_df$Name), x = 1, y = round_any(max(all_cause_rate_df$Deaths_crude_rate_uci, na.rm = TRUE), 10, ceiling)-5, size = 3, fontface = "bold", hjust = 0)


png(paste0(github_repo_dir, "/crude_rate_plot.png"), width = 1600, height = 1450, res = 250)
crude_rate_plot
dev.off()


# slide 3 - local asmr data between 01 March and two weeks prior

asmr_title <- as.character(dates_granular %>% 
  filter(`Worksheet name` == 'Table 2') %>% 
  select(Content))

asmr_title <- gsub('Number of deaths and a', 'A', asmr_title)
asmr_title <- gsub('Local Authorities in England and Wales', 'West Sussex districts and boroughs', asmr_title)

wsx_asmr <- la_asmr %>% 
  filter(Name %in% c('Adur', 'Arun', 'Chichester', 'Crawley','Horsham','Mid Sussex', 'Worthing','West Sussex', 'South East', 'England')) %>% 
  mutate(Name = factor(Name, levels = c('Adur', 'Arun', 'Chichester', 'Crawley','Horsham','Mid Sussex', 'Worthing','West Sussex', 'South East', 'England'))) %>% 
  mutate(Sex = factor(Sex, levels = c('Females', 'Persons', 'Males')))

all_cause_ltla_asmr_plot <- ggplot(wsx_asmr,
       aes(x = Name,
           y = All_cause_ASMR,
           fill = Name)) +
  geom_bar(stat = 'identity',
           colour = '#ffffff',
           size = .25) +
  geom_errorbar(aes(ymin = All_cause_ASMR, ymax = All_cause_ASMR_uci), colour = "#919191", width = 0.25) +  
  geom_errorbar(aes(ymin = All_cause_ASMR_lci, ymax = All_cause_ASMR), colour = "#ffffff", width = 0.25) +  
  scale_fill_manual(values = c("#c85979",  "#cb5336",  "#c18b41",  "#7ca343",  "#49ae8a",  "#6980ce",  "#b460bd",'#E56C39', '#A4A3A4', '#DAD8DA')) +
  labs(title = paste0(asmr_title),
       subtitle = 'Age-standardised mortality rates per 100,000 people (2013 European Standard Population)',
       x = '',
       y = 'Number of deaths\nper 100,000 ESP') +
  scale_y_continuous(breaks = seq(0,round_any(max(wsx_asmr$All_cause_ASMR_uci, na.rm = TRUE), 20, ceiling),20),
                     limits = c(0,round_any(max(wsx_asmr$All_cause_ASMR_uci, na.rm = TRUE), 20, ceiling))) +
  facet_rep_grid(. ~ Sex, repeat.tick.labels = TRUE) +
  ph_theme() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = .5),
        legend.position = "none") 

png(paste0(github_repo_dir, "/all_cause_ltla_asmr_plot.png"), width = 1600, height = 550, res = 150)
all_cause_ltla_asmr_plot
dev.off()

wsx_asmr %>% 
  mutate(label = paste0(format(All_cause_deaths, big.mark = ',', trim = TRUE), ' deaths (', All_cause_ASMR, ' per 100,000 ESP, 95% CI: ', All_cause_ASMR_lci, '-', All_cause_ASMR_uci, ')')) %>% 
  select(Name, Sex, label) %>% 
  spread(Sex, label) %>% 
  select(Name, Persons) %>% 
  write.csv(., paste0(github_repo_dir, '/all_cause_ltla_asmr_table.csv'), row.names = FALSE, na = '')

second_asmr_title <- gsub('districts and boroughs', 'compared to South East region and England', asmr_title)


utla_asmr_plot <- ggplot(subset(wsx_asmr, Name %in% c('West Sussex', 'South East', 'England')),
       aes(x = Sex,
           y = All_cause_ASMR,
           fill = Sex)) +
  geom_bar(stat = 'identity',
           colour = '#ffffff',
           size = .25) +
  geom_errorbar(aes(ymin = All_cause_ASMR, ymax = All_cause_ASMR_uci), colour = "#919191", width = 0.25) +  
  geom_errorbar(aes(ymin = All_cause_ASMR_lci, ymax = All_cause_ASMR), colour = "#ffffff", width = 0.25) +  
  scale_fill_manual(values = c('#F76402','#172343', '#45C3FF')) +
  labs(title = paste0(second_asmr_title),
       subtitle = 'Age-standardised mortality rates per 100,000 people (2013 European Standard Population)',
       x = '',
       y = 'Number of deaths\nper 100,000 ESP') +
  scale_y_continuous(breaks = seq(0,round_any(max(wsx_asmr$All_cause_ASMR_uci, na.rm = TRUE), 20, ceiling),20),
                     limits = c(0,round_any(max(wsx_asmr$All_cause_ASMR_uci, na.rm = TRUE), 20, ceiling))) +
  facet_rep_grid(. ~ Name,  repeat.tick.labels = FALSE) +
  ph_theme() +
  theme(axis.text.x = element_blank()) 

png(paste0(github_repo_dir, "/all_cause_utla_asmr_plot.png"), width = 1080, height = 400, res = 100)
utla_asmr_plot
dev.off()

covid_ltla_asmr_plot <- ggplot(wsx_asmr,
         aes(x = Name,
             y = Covid_ASMR,
             fill = Name)) +
  geom_bar(stat = 'identity',
           colour = '#ffffff',
           size = .25) +
  geom_errorbar(aes(ymin = Covid_ASMR, ymax = Covid_ASMR_uci), colour = "#919191", width = 0.25) +  
  geom_errorbar(aes(ymin = Covid_ASMR_lci, ymax = Covid_ASMR), colour = "#ffffff", width = 0.25) +  
  scale_fill_manual(values = c("#c85979",  "#cb5336",  "#c18b41",  "#7ca343",  "#49ae8a",  "#6980ce",  "#b460bd",'#E56C39', '#A4A3A4', '#DAD8DA')) +
  labs(title = paste0(asmr_title),
       subtitle = 'Age-standardised mortality rates per 100,000 people (2013 European Standard Population)',
       x = '',
       y = 'Number of deaths\nper 100,000 ESP') +
  scale_y_continuous(breaks = seq(0,round_any(max(wsx_asmr$Covid_ASMR_uci, na.rm = TRUE), 10, ceiling),10),
                     limits = c(0,round_any(max(wsx_asmr$Covid_ASMR_uci, na.rm = TRUE), 10, ceiling))) +
  facet_rep_grid(. ~ Sex, repeat.tick.labels = TRUE) +
  ph_theme() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = .5),
        legend.position = "none") 

png(paste0(github_repo_dir, "/covid_ltla_asmr_plot.png"), width = 1600, height = 550, res = 150)
covid_ltla_asmr_plot
dev.off()

wsx_asmr %>% 
  mutate(label = paste0(format(Covid_deaths, big.mark = ',', trim = TRUE), ' deaths (', Covid_ASMR, ' per 100,000 ESP, 95% CI: ', Covid_ASMR_lci, '-', Covid_ASMR_uci, ')')) %>% 
  select(Name, Sex, label) %>% 
  spread(Sex, label) %>% 
  select(Name, Persons) %>% 
  write.csv(., paste0(github_repo_dir, '/covid_ltla_asmr_table.csv'), row.names = FALSE, na = '')

utla_asmr_covid_plot <- ggplot(subset(wsx_asmr, Name %in% c('West Sussex', 'South East', 'England')),
                         aes(x = Sex,
                             y = Covid_ASMR,
                             fill = Sex)) +
  geom_bar(stat = 'identity',
           colour = '#ffffff',
           size = .25) +
  geom_errorbar(aes(ymin = Covid_ASMR, ymax = Covid_ASMR_uci), colour = "#919191", width = 0.25) +  
  geom_errorbar(aes(ymin = Covid_ASMR_lci, ymax = Covid_ASMR), colour = "#ffffff", width = 0.25) +  
  scale_fill_manual(values = c('#F76402','#172343', '#45C3FF')) +
  labs(title = paste0(second_asmr_title),
       subtitle = 'Age-standardised mortality rates per 100,000 people (2013 European Standard Population)',
       x = '',
       y = 'Number of deaths\nper 100,000 ESP') +
  scale_y_continuous(breaks = seq(0,round_any(max(wsx_asmr$Covid_ASMR_uci, na.rm = TRUE), 10, ceiling),10),
                     limits = c(0,round_any(max(wsx_asmr$Covid_ASMR_uci, na.rm = TRUE), 10, ceiling))) +
  facet_rep_grid(. ~ Name,  repeat.tick.labels = FALSE) +
  ph_theme() +
  theme(axis.text.x = element_blank()) 

png(paste0(github_repo_dir, "/covid_utla_asmr_plot.png"), width = 1080, height = 400, res = 100)
utla_asmr_covid_plot
dev.off()

# slide 4 - msoa for sussex between 01 March and two weeks prior

msoa_deaths %>% 
  View()

lookup_msoa_la

# msoa_boundaries ####

# We need to do a bit of hacking this about to keep the integrity of the coastline around Chichester harbour but also making sure that we dont include clips of all the rivers in Wsx!

#Grab all full extent MSOAs for areas with MSOAs that have names starting with Adur, Arun, Chichester, Crawley, Horsham, Mid Sussex, Worthing and Lewes (as we know there are a couple of LSOAs outside of the boundary)
MSOA_boundary_fe <- as(st_read(paste0("https://ons-inspire.esriuk.com/arcgis/rest/services/Census_Boundaries/Middle_Super_Output_Areas_December_2011_Boundaries/MapServer/1/query?where=msoa11nm%20%3D%20'ADUR'%20OR%20msoa11nm%20%3D%20'ARUN'%20OR%20msoa11nm%20%3D%20'CHICHESTER'%20OR%20msoa11nm%20%3D%20'CRAWLEY'%20OR%20msoa11nm%20%3D%20'HORSHAM'%20OR%20msoa11nm%20%3D%20'MID%20SUSSEX'%20OR%20msoa11nm%20%3D%20'WORTHING'&outFields=msoa11cd,msoa11nm,shape,st_area(shape),st_length(shape)&outSR=4326&f=geojson")), 'Spatial')


# We can grab a subset of LSOAs for just Chichester
MSOA_boundary_clipped <- as(st_read(paste0("https://ons-inspire.esriuk.com/arcgis/rest/services/Census_Boundaries/Middle_Super_Output_Areas_December_2011_Boundaries/MapServer/2/query?where=msoa11nm%20%3D%20'CHICHESTER'&outFields=msoa11cd,msoa11nm,shape,st_area(shape),st_length(shape)&outSR=4326&f=geojson")), 'Spatial')

# Extract the LSOAs we know need to be clipped from the Chichester object
LSOA_boundary_clipped <- LSOA_boundary_clipped %>% 
  filter(LSOA11CD %in% c('E01031532', 'E01031475','E01031476','E01031496','E01031542','E01031540','E01031524','E01031529','E01031513'))

# We want to select all the LSOAs that were not clipped in the above object
LSOA_boundary_fe <- LSOA_boundary_fe %>% 
  filter(!LSOA11CD %in% LSOA_boundary_clipped$LSOA11CD)

# Join the two objects. This will now contain all of Chichester LSOAs (some clipped and some full extent) as well as all LSOAs for the rest of WSx and Lewes. 
LSOA_boundary <- rbind(LSOA_boundary_fe, LSOA_boundary_clipped)

# We can remove the old objects
rm(LSOA_boundary_fe, LSOA_boundary_clipped)




# slide 5 - deaths in care homes

# registered by 5pm 8th May

