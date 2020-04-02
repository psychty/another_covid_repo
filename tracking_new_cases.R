
library(easypackages)

libraries(c("readxl", "readr", "plyr", "dplyr", "ggplot2", "png", "tidyverse", "reshape2", "scales", "viridis", "rgdal", "officer", "flextable", "tmaptools", "lemon", "fingertipsR", "PHEindicatormethods", 'jsonlite', 'readODS', 'zoo'))

github_repo_dir <- "~/Documents/Repositories/critical_care_sitrep"

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

github_repo_dir = '~/Documents/Repositories/another_covid_repo'

download.file('https://fingertips.phe.org.uk/documents/Historic%20COVID-19%20Dashboard%20Data.xlsx', paste0(github_repo_dir, '/refreshed_daily_cases.xlsx'), mode = 'wb')

mye_total <- read_csv('http://www.nomisweb.co.uk/api/v01/dataset/NM_2002_1.data.csv?geography=1941962753...1941962984&date=latest&gender=0&c_age=200&measures=20100&select=date_name,geography_name,geography_code,obs_value') %>% 
  rename(Population = OBS_VALUE,
         Code = GEOGRAPHY_CODE,
         Name = GEOGRAPHY_NAME)

daily_cases <- read_excel(paste0(github_repo_dir, '/refreshed_daily_cases.xlsx'),sheet = "UTLAs", skip = 8) %>% 
  gather(key = "Date", value = "Cumulative_cases", 3:ncol(.)) %>% 
  rename(Name = `Area Name`) %>% 
  rename(Code = `Area Code`) %>% 
  mutate(Name = ifelse(is.na(Name), 'Unconfirmed', Name)) %>% 
  mutate(Date = as.Date(as.numeric(Date), origin = "1899-12-30")) %>% 
  arrange(Name, Date) %>% 
  group_by(Name) %>% 
  mutate(New_cases = Cumulative_cases - lag(Cumulative_cases)) %>% 
  ungroup() %>% 
  filter(Name != 'Unconfirmed') %>% 
  left_join(mye_total, by = c('Code','Name')) %>% 
  mutate(Cumulative_per_100000 = (Cumulative_cases / Population) * 100000) %>% 
  mutate(New_cases_per_100000 = (New_cases / Population) * 100000) %>% 
  mutate(new_case_key = factor(ifelse(Date == min(Date), 'Starting cases', ifelse(New_cases < 0, 'Data revised down', ifelse(New_cases == 0, 'No new cases', ifelse(New_cases >= 1 & New_cases <= 5, '1-5', ifelse(New_cases >= 6 & New_cases <= 10, '6-10', ifelse(New_cases >= 11 & New_cases <= 15, '11-15', ifelse(New_cases >= 16 & New_cases <= 20, '16-20', ifelse(New_cases > 20, 'Above 20', NA)))))))), levels =  c('Starting cases', 'Data revised down', 'No new cases', '1-5', '6-10', '11-15', '16-20', 'Above 20')))

se_daily_cases <- daily_cases %>% 
  filter(Name %in% c('Brighton and Hove', 'Bracknell Forest', 'Buckinghamshire', 'East Sussex', 'Hampshire', 'Isle of Wight', 'Kent', 'Medway', 'Milton Keynes', 'Oxfordshire', 'Portsmouth', 'Reading', 'Slough', 'Southampton', 'Surrey', 'West Berkshire', 'West Sussex', 'Windsor and Maidenhead', 'Wokingham')) 

summary(se_daily_cases$New_cases)
summary(se_daily_cases$New_cases_per_100000)

se_cases_summary <- se_daily_cases %>% 
  filter(Date == max(Date)) %>% 
  select(Name, Cumulative_cases, Cumulative_per_100000, New_cases, New_cases_per_100000) %>%
  rename(`Total cases` = Cumulative_cases,
         `Total cases per 100,000 population` = Cumulative_per_100000,
         `New cases in past 24 hours` = New_cases,
         `New cases per 100,000 population` = New_cases_per_100000) %>%
  arrange(`Total cases`) %>% 
  mutate(Name = factor(Name, levels = unique(Name))) %>% 
  mutate(highlight = ifelse(Name %in% c('Brighton and Hove', 'East Sussex', 'West Sussex'), 'bold', 'plain'))

se_daily_cases <- se_daily_cases %>% 
  mutate(Name = factor(Name, levels = levels(se_cases_summary$Name))) %>% 
  arrange(Name)

se_cases_summary %>%
  select(-highlight) %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/another_covid_repo/se_case_summary.json'))

se_daily_cases %>%
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/another_covid_repo/se_daily_cases.json'))


ggplot(se_daily_cases, aes(x = Date, 
                y = Name, 
                fill = new_case_key)) + 
  scale_fill_manual(values = c('#dcf3f5','#a6b4d8','#ffffb2','#fed976','#feb24c','#fd8d3c','#f03b20','#bd0026'),
                    name = 'Tile colour\nkey') +
  geom_tile(colour = "#ffffff") +
  labs(x = NULL, 
       y = NULL) +
  scale_x_date(date_labels = "%b %d",
               date_breaks = '1 week',
               limits = c(min(se_daily_cases$Date) -1, min(se_daily_cases$Date) + 59),
               expand = c(0,0.01)) +
  theme(axis.text.x = element_text(angle = 0, hjust = 0),
        legend.position = "bottom", 
        legend.text = element_text(colour = "#323232", size = 8), 
        panel.background = element_rect(fill = "white"), 
        plot.title = element_text(colour = "#000000", face = "bold", size = 11, vjust = 1), 
        axis.text.y = element_text(colour = "#323232", face = se_cases_summary$highlight, size = 8),  
        legend.title = element_text(colour = "#323232", face = "bold", size = 10),  
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(), 
        panel.grid.major.y = element_blank(),
        panel.grid.minor.y = element_blank(), 
        legend.key.size = unit(0.65, "lines"), 
        legend.background = element_rect(fill = "#ffffff"), 
        legend.key = element_rect(fill = "#ffffff", colour = "#E2E2E3"), 
        strip.text = element_text(colour = "#000000", face = "bold"),
        strip.background = element_rect(fill = "#ffffff"))

sse <-daily_cases %>% 
  filter(Name %in% c('Brighton and Hove', 'East Sussex', 'West Sussex'))


