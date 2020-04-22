
library(easypackages)

libraries(c("readxl", "readr", "plyr", "dplyr", "ggplot2", "tidyverse", "reshape2", "scales", 'jsonlite', 'zoo', 'stats', 'aweek'))

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
mye_total <- read_csv('http://www.nomisweb.co.uk/api/v01/dataset/NM_2002_1.data.csv?geography=2092957699,2013265921...2013265932,1816133633...1816133848&date=latest&gender=0&c_age=200&measures=20100&select=date_name,geography_name,geography_code,obs_value') %>% 
  rename(Population = OBS_VALUE,
         Code = GEOGRAPHY_CODE,
         Name = GEOGRAPHY_NAME) 

# We are interested in the whole of Sussex (three LA combined)
sussex_pop <- mye_total %>% 
  filter(Name %in% c('Brighton and Hove', 'East Sussex', 'West Sussex')) %>%
  summarise(Population = sum(Population, na.rm = TRUE)) %>% 
  mutate(Name = 'Sussex areas combined') %>% 
  mutate(Code = '-')

mye_total <- mye_total %>%
  bind_rows(sussex_pop) %>% 
  select(-Name)

# Mortality data ####

# Deaths of patients who have died in hospitals in England and had tested positive for Covid-19 at time of death. All deaths are recorded against the date of death rather than the day the deaths were announced. Likely to be some revision.

# Note: interpretation of the figures should take into account the fact that totals by date of death, particularly for recent prior days, are likely to be updated in future releases. For example as deaths are confirmed as testing positive for Covid-19, as more post-mortem tests are processed and data from them are validated. Any changes are made clear in the daily files.					

# if(!file.exists(paste0(github_repo_dir, '/etr.csv'))){
#   download.file('https://files.digital.nhs.uk/assets/ods/current/etr.zip', paste0(github_repo_dir, '/etr.zip'), mode = 'wb')
#   unzip(paste0(github_repo_dir, '/etr.zip'), exdir = github_repo_dir)
#   file.remove(paste0(github_repo_dir, '/etr.zip'), paste0(github_repo_dir, '/etr.pdf'))
# }
# 
# etr <- read_csv(paste0(github_repo_dir, '/etr.csv'),col_names = c('Code', 'Name', 'National_grouping', 'Health_geography', 'Address_1', 'Address_2', 'Address_3', 'Address_4', 'Address_5', 'Postcode', 'Open_date', 'Close_date', 'Null_1', 'Null_2', 'Null_3', 'Null_4', 'Null_5', 'Contact', 'Null_6', 'Null_7', 'Null_8', 'Amended_record_indicator', 'Null_9', 'GOR', 'Null_10', 'Null_11', 'Null_12')) %>%
#   select(Code, Name, National_grouping) %>% 
#   mutate(Name = capwords(Name, strict = TRUE)) %>% 
#   mutate(Name = gsub(' And ', ' and ', Name)) %>% 
#   mutate(Name = gsub(' Of ', ' of ', Name)) %>% 
#   mutate(Name = gsub(' Nhs ', ' NHS ', Name)) %>% 
#   add_row( Code = '-', Name = 'England', National_grouping = '-')
# 
# download.file('https://www.england.nhs.uk/statistics/wp-content/uploads/sites/2/2020/04/COVID-19-total-announced-deaths-14-April-2020.xlsx', paste0(github_repo_dir, '/refreshed_daily_deaths_trust.xlsx'), mode = 'wb')
#               
# refreshed_daily_deaths_trust <- read_excel(paste0(github_repo_dir, "/refreshed_daily_deaths_trust.xlsx"), skip = 15) %>% 
#   select(-c(...2, Total)) %>% 
#   filter(!is.na(Code)) %>% 
#   mutate(Name = capwords(Name, strict = TRUE)) %>% 
#   gather(key = "Date", value = "Deaths", 5:ncol(.)) %>% 
#   mutate(Date = as.Date(as.numeric(Date), origin = "1899-12-30")) %>% 
#   filter(!is.na(Date))

set_week_start('Friday')

week_ending <- data.frame(Week_ending = get_date(week = 1:52, year = 2020)) %>% 
  mutate(Week_number = row_number())

download.file('https://www.ons.gov.uk/file?uri=%2fpeoplepopulationandcommunity%2fhealthandsocialcare%2fcausesofdeath%2fdatasets%2fdeathregistrationsandoccurrencesbylocalauthorityandhealthboard%2f2020/lahbtables.xlsx', paste0(github_repo_dir, '/ons_mortality.xlsx'), mode = 'wb')

# Lookups
lookup <- read_csv(url("https://opendata.arcgis.com/datasets/3e4f4af826d343349c13fb7f0aa2a307_0.csv")) %>% 
  select(-c(FID, LTLA19NM)) %>% 
  left_join(read_csv(url('https://opendata.arcgis.com/datasets/3ba3daf9278f47daba0f561889c3521a_0.csv')), by = c('LTLA19CD' = 'LAD19CD')) %>% 
  select(-c(FID, LAD19NM))

# Weeks run from Saturday to Friday

Registrations_utla <- read_xlsx(paste0(github_repo_dir, '/ons_mortality.xlsx'), sheet = 'Registrations - All data', skip = 2) %>% 
  filter(`Geography type` == 'Local Authority') %>% 
  filter(substr(`Area code`, 1,1) == 'E') %>% 
  left_join(lookup, by = c('Area code' = 'LTLA19CD')) %>% 
  group_by(UTLA19CD, UTLA19NM, `Cause of death`,`Week number`, `Place of death`) %>% 
  summarise(Deaths = sum(`Number of deaths`, na.rm = TRUE)) %>% 
  rename(Area_name = UTLA19NM,
         Area_code = UTLA19CD,
         Cause = `Cause of death`,
         Week_number = `Week number`,
         Place_of_death = `Place of death`) %>% 
  mutate(Area_type = 'UTLA') %>% 
  select(Area_code, Area_name, Area_type, Week_number, Cause, Place_of_death, Deaths) %>% 
  left_join(week_ending, by = 'Week_number') %>% 
  ungroup()

Registrations_region <- read_xlsx(paste0(github_repo_dir, '/ons_mortality.xlsx'), sheet = 'Registrations - All data', skip = 2) %>% 
  filter(`Geography type` == 'Local Authority') %>% 
  filter(substr(`Area code`, 1,1) == 'E') %>% 
  left_join(lookup, by = c('Area code' = 'LTLA19CD')) %>% 
  group_by(RGN19CD, RGN19NM, `Cause of death`,`Week number`, `Place of death`) %>% 
  summarise(Deaths = sum(`Number of deaths`, na.rm = TRUE)) %>% 
  rename(Area_name = RGN19NM,
         Area_code = RGN19CD,
         Cause = `Cause of death`,
         Week_number = `Week number`,
         Place_of_death = `Place of death`) %>% 
  mutate(Area_type = 'Region') %>% 
  select(Area_code, Area_name, Area_type, Week_number, Cause, Place_of_death, Deaths) %>% 
  left_join(week_ending, by = 'Week_number') %>% 
  ungroup()

Sussex_combined <- Registrations_utla %>% 
  filter(Area_name %in% c('Brighton and Hove', 'East Sussex', 'West Sussex')) %>% 
  group_by(Week_number, Week_ending, Cause, Place_of_death) %>% 
  summarise(Deaths = sum(Deaths, na.rm = TRUE)) %>% 
  mutate(Area_code = '-',
         Area_name = 'Sussex areas combined') %>% 
  mutate(Area_type = 'Sussex areas combined') %>% 
  select(Area_code, Area_name, Area_type, Week_number, Week_ending, Cause, Place_of_death, Deaths) %>% 
  ungroup()

England <- Registrations_utla %>% 
  group_by(Week_number, Week_ending, Cause, Place_of_death) %>% 
  summarise(Deaths = sum(Deaths, na.rm = TRUE)) %>% 
  mutate(Area_code = 'E92000001',
         Area_name = 'England') %>% 
  mutate(Area_type = 'England') %>% 
  select(Area_code, Area_name, Area_type, Week_number, Week_ending, Cause, Place_of_death, Deaths) %>% 
  ungroup()

Registrations <- Registrations_utla %>% 
  bind_rows(Registrations_region)
  bind_rows(Sussex_combined) %>% 
  bind_rows(England)

rm(Registrations_utla, Registrations_region ,England, lookup, Sussex_combined, sussex_pop, week_ending)

All_settings_registration <- Registrations %>% 
  group_by(Area_code, Area_name, Week_number, Week_ending, Cause) %>% 
  summarise(Deaths = sum(Deaths, na.rm = TRUE)) %>% 
  group_by(Area_code, Area_name, Cause) %>% 
  arrange(Area_code, Cause, Week_number) %>% 
  mutate(Cumulative_deaths = cumsum(Deaths))

Latest_registration <- All_settings_registration %>% 
  filter(Week_ending == max(Week_ending))


# Use occurances, be mindful that the most recent week of occurance data may not be complete if the death is not registered within 7 days (there is a week lag in reporting to allow up to seven days for registration to take place), this will be updated each week. Estimates suggest around 74% of deaths in England and Wales are registered within seven calendar days of occurance, with the proportion as low as 68% in the South East region. It is difficult to know what impact Covid-19 has on length of time taken to register a death. 


names(Registrations)

Occurrences <- read_xlsx(paste0(github_repo_dir, '/ons_mortality.xlsx'), sheet = 'Occurrences - All data', skip = 2)

# Weekly death figures provide provisional counts of the number of deaths registered in England and Wales for which data are available.	From 31 March 2020 these figures also show the number of deaths involving coronavirus (COVID-19), based on any mention of COVID-19 on the death certificate.											

# The tables include deaths that occurred up to 10 April but were registered up to 18 April. Figures by place of death may differ to previously published figures (week 15) due to improvements in the way we code place of death.											

# These figures do not include deaths of those resident outside England and Wales or those records where the place of residence is either missing or not yet fully coded. For this reason counts may differ to published figures when summed.											

# These figures represent death occurrences and registrations, there can be a delay between the date a death occurred and the date a death was registered. More information can be found in our impact of registration delays release. 											

# Notes and definitions											

# Deaths occurring in England and Wales are registered on the General Register Office's Registration Online system (RON).											
# Daily extracts of death registration records from RON are processed on our database systems.											
# Provisional data on deaths registered in each week (ending on a Friday) are compiled at the end of the following week.											
# Bank Holidays could affect the number of registrations made within those weeks.											

# The counts of deaths from specific conditons are updated with each weekly publication as the coding of the underlying cause is not always complete at the time of production.											
# For deaths registered from 1st January 2020, cause of death is coded to the ICD-10 classification using MUSE 5.5 software. Previous years were coded to IRIS 4.2.3, further information about the change in software is available.											

# Where there are the same values in categories in consecutive weeks, the counts have been checked and are made up of unique death registrations.							 Figures for the latest week are based on boundaries as of February 2020.		

# A total of 10,350 deaths involving COVID-19 were registered in England and Wales between 28 December 2019 and 10 April 2020 (year to date).
# Including deaths that occurred up to 10 April but were registered up to 18 April, the number involving COVID-19 was 13,121.
# For deaths that occurred up to 10 April, the comparative number of death notifications reported by the Department of Health and Social Care (DHSC) on GOV.UK for England and Wales was 9,288.
# NHS England COVID-19 deaths by date of death, which come from the same source as DHSC but are continuously updated, showed 10,260 deaths by 10 April; 2,256 fewer than Office for National Statistics figures for England by date of death (12,516).
# Week 15 included the Good Friday bank holiday; the five-year average does show a decrease in registrations over the Easter holiday; however, the Coronavirus Act 2020 allowed registry offices to remain open over Easter, which may have reduced any drop in registrations for Week 15 2020.

# The DHSC release daily updates on the GOV.UK website counting the total number of deaths reported to them among patients who had tested positive for COVID-19. This covers all deaths that occurred in hospitals in England and were reported up to 5pm the day before, and all deaths in Wales, Scotland and Northern Ireland wherever they occurred, if known to the public health agencies. To allow comparison, only the numbers for England and Wales are shown here.

# The ONS provides figures based on all deaths registered involving COVID-19 according to death certification, whether in or out of hospital, for England and Wales. We also provide the figures by date of death (occurrence). More information can be found in the Measuring the data section of our weekly deaths publication.