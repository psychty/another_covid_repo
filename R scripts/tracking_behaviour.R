
library(easypackages)

libraries(c("readxl", "readr", "plyr", "dplyr", "ggplot2", "tidyverse", "reshape2", "scales", 'jsonlite', 'zoo', 'stats', 'fingertipsR'))

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

# 2018 MYE
mye_total <- read_csv('http://www.nomisweb.co.uk/api/v01/dataset/NM_2002_1.data.csv?geography=1816133633...1816133848,1820327937...1820328318,2092957697...2092957703,2013265921...2013265932&date=latest&gender=0&c_age=200&measures=20100&select=date_name,geography_name,geography_type,geography_code,obs_value') %>% 
  rename(Population = OBS_VALUE,
         Code = GEOGRAPHY_CODE,
         Name = GEOGRAPHY_NAME,
         Type = GEOGRAPHY_TYPE) %>% 
  unique() %>% 
  group_by(Name, Code) %>% 
  mutate(Count = n()) %>% 
  mutate(Type = ifelse(Count == 2, 'Unitary Authority', ifelse(Type == 'local authorities: county / unitary (as of April 2019)', 'Upper Tier Local Authority', ifelse(Type == 'local authorities: district / unitary (as of April 2019)', 'Lower Tier Local Authority', ifelse(Type == 'regions', 'Region', ifelse(Type == 'countries', 'Country', Type)))))) %>% 
  ungroup() %>% 
  select(-Count) %>% 
  unique()

# Google mobility data ####

mobility <- read_csv('https://www.gstatic.com/covid19/mobility/Global_Mobility_Report.csv') %>%
filter(country_region == 'United Kingdom') %>%
rename(Area = sub_region_1) %>%
select(-c(sub_region_2, country_region_code, country_region)) %>% 
  filter(Area %in% c('Brighton and Hove', 'Bracknell Forest', 'Buckinghamshire', 'East Sussex', 'Hampshire', 'Isle of Wight', 'Kent', 'Medway', 'Milton Keynes', 'Oxfordshire', 'Portsmouth', 'Reading', 'Slough', 'Southampton', 'Surrey', 'West Berkshire', 'West Sussex', 'Windsor and Maidenhead', 'Wokingham')) %>% 
  gather(key = "Place", value = "Comparison_to_baseline", `retail_and_recreation_percent_change_from_baseline`:ncol(.)) %>% 
  mutate(Place = factor(ifelse(Place == 'retail_and_recreation_percent_change_from_baseline', 'Retail and recreation', ifelse(Place == 'grocery_and_pharmacy_percent_change_from_baseline', 'Grocery and pharmacy', ifelse(Place == 'parks_percent_change_from_baseline', 'Parks', ifelse(Place == 'transit_stations_percent_change_from_baseline', 'Public transport', ifelse(Place == 'workplaces_percent_change_from_baseline', 'Workplaces', ifelse(Place == 'residential_percent_change_from_baseline', 'Residential', NA)))))), levels = c('Grocery and pharmacy', 'Public transport', 'Parks', 'Retail and recreation', 'Residential', 'Workplaces'))) %>% 
  rename(Date = date) %>% 
  mutate(Date = format(Date, '%d %B (%a)')) %>% 
  mutate(Date = factor(Date, levels = unique(Date)))

mobility %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/another_covid_repo/google_mobility_data.json'))

levels(mobility$Date)[length(levels(mobility$Date))] %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/another_covid_repo/google_mobility_latest_date.json'))

levels(mobility$Date)[1] %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/another_covid_repo/google_mobility_earliest_date.json'))

format(Sys.Date(), '%d %B %Y') %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/another_covid_repo/google_mobility_data_accessed.json'))

bh_mobility <- mobility %>% 
  filter(Area == 'Brighton and Hove')

ggplot(bh_mobility,
       aes(x = Date,
           y = Comparison_to_baseline,
           group = Place,
           fill = Place,
           colour = Place)) +
  scale_colour_manual(values = c('#D7457A', '#26589D', '#DDA241', '#612762', '#7D9B5A', '#DBB2E2')) +
  scale_y_continuous(limits = c(-100, 100),
                     breaks = seq(-100,100,20)) +
  geom_line() + 
  # scale_x_date(date_labels = "%b %d (%A)",
  #              date_breaks = '2 day',
  #              expand = c(0,.1)) +
  geom_hline(yintercept =  0,
             colour = '#000000') +
  ph_theme() +
  theme(axis.text.x = element_text(angle = 90))

# start ####
# add 23rd March as lock down start

# setdiff(local_cases_summary$Name, unique(mobility$sub_region_1))

# These reports show how visits and length of stay at different places change compared to a baseline. We calculate these changes using the same kind of aggregated and anonymized data used to show popular times for places in Google Maps.
# Changes for each day are compared to a baseline value for that day of the week:
# ● The baseline is the median value, for the corresponding day of the week, during the 5- week period Jan 3–Feb 6, 2020.
# ● The reports show trends over several weeks with the most recent data representing approximately 2-3 days ago—this is how long it takes to produce the reports.


