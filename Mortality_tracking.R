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
mye_total_raw <- read_csv('http://www.nomisweb.co.uk/api/v01/dataset/NM_2002_1.data.csv?geography=2092957699,2013265921...2013265932,1816133633...1816133848&date=latest&gender=0&c_age=200,209&measures=20100&select=date_name,geography_name,geography_code,c_age_name,obs_value') %>% 
  rename(Population = OBS_VALUE,
         Area_code = GEOGRAPHY_CODE,
         Name = GEOGRAPHY_NAME,
         Year = DATE_NAME,
         Age = C_AGE_NAME) 

# We are interested in the whole of Sussex (three LA combined)
sussex_pop <- mye_total_raw %>% 
  filter(Name %in% c('Brighton and Hove', 'East Sussex', 'West Sussex')) %>%
  group_by(Year,Age) %>% 
  summarise(Population = sum(Population, na.rm = TRUE)) %>% 
  mutate(Name = 'Sussex areas combined') %>% 
  mutate(Area_code = '-') 

mye_total <- mye_total_raw %>%
  bind_rows(sussex_pop) %>% 
  select(-Name) %>% 
  spread(Age, Population) %>% 
  rename(All_ages = `All Ages`,
         Age_65_plus = `Aged 65+`)

rm(mye_total_raw, sussex_pop)

# Lookups from ltla to utla and region
lookup <- read_csv(url("https://opendata.arcgis.com/datasets/3e4f4af826d343349c13fb7f0aa2a307_0.csv")) %>% 
  select(-c(FID, LTLA19NM)) %>% 
  left_join(read_csv(url('https://opendata.arcgis.com/datasets/3ba3daf9278f47daba0f561889c3521a_0.csv')), by = c('LTLA19CD' = 'LAD19CD')) %>% 
  select(-c(FID, LAD19NM))

bh_nn <- c('Nottingham', 'Medway', 'Newcastle upon Tyne', 'Liverpool','Portsmouth','Southampton','Leeds','Sheffield','York','Plymouth','Salford','Coventry','Bristol','Southend-on-Sea','Brighton and Hove', 'Reading')

es_nn <- c('Nottinghamshire','Kent','Lancashire','Norfolk','Worcestershire','Staffordshire','Somerset','East Sussex','Devon','Gloucestershire','North Yorkshire','Suffolk','Warwickshire','Essex', 'West Sussex','Hampshire')

ws_nn <- c('Kent','Northamptonshire','Worcestershire', 'Staffordshire','Somerset','East Sussex', 'Devon', 'Gloucestershire', 'Cambridgeshire','North Yorkshire','Suffolk','Warwickshire','Essex','West Sussex', 'Hampshire', 'Oxfordshire')

# ONS Weekly mortality data ####

# Weekly death figures provide provisional counts of the number of deaths registered in England and Wales for which data are available.	From 31 March 2020 these figures also show the number of deaths involving coronavirus (COVID-19), based on any mention of COVID-19 on the death certificate.											

# The tables include deaths that occurred up to the Friday before last but were registered up to last Friday. Figures by place of death may differ to previously published figures due to improvements in the way we code place of death.											

# These figures do not include deaths of those residents outside England and Wales or those records where the place of residence is either missing or not yet fully coded. For this reason counts may differ to published figures when summed. These figures represent death occurrences and registrations, there can be a delay between the date a death occurred and the date a death was registered. More information can be found in our impact of registration delays release. 	

# For this data, the week ends on a friday (so friday is the cut off date for each week of data). It might be helpful for us to say as at this date this is the number of deaths. To do this we need to convert each week number into a 'friday date'.
set_week_start('Friday')

week_ending <- data.frame(Week_ending = get_date(week = 1:52, year = 2020)) %>% 
  mutate(Week_number = row_number())

# Download the data. I am hoping that this is a stable url that will be updated each week
download.file('https://www.ons.gov.uk/file?uri=%2fpeoplepopulationandcommunity%2fhealthandsocialcare%2fcausesofdeath%2fdatasets%2fdeathregistrationsandoccurrencesbylocalauthorityandhealthboard%2f2020/lahbtables.xlsx', paste0(github_repo_dir, '/ons_mortality.xlsx'), mode = 'wb')

# Use occurances, be mindful that the most recent week of occurance data may not be complete if the death is not registered within 7 days (there is a week lag in reporting to allow up to seven days for registration to take place), this will be updated each week. Estimates suggest around 74% of deaths in England and Wales are registered within seven calendar days of occurance, with the proportion as low as 68% in the South East region. It is difficult to know what impact Covid-19 has on length of time taken to register a death. 

# Occurrences data is produced at ltla level and we would probably find it useful to aggregate to utla and region for our analysis
Occurrences_utla <- read_xlsx(paste0(github_repo_dir, '/ons_mortality.xlsx'), sheet = 'Occurrences - All data', skip = 2) %>% 
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

Occurrences_region <- read_xlsx(paste0(github_repo_dir, '/ons_mortality.xlsx'), sheet = 'Occurrences - All data', skip = 2) %>% 
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

Sussex_combined_occurrence <- Occurrences_utla %>% 
  filter(Area_name %in% c('Brighton and Hove', 'East Sussex', 'West Sussex')) %>% 
  group_by(Week_number, Week_ending, Cause, Place_of_death) %>% 
  summarise(Deaths = sum(Deaths, na.rm = TRUE)) %>% 
  mutate(Area_code = '-',
         Area_name = 'Sussex areas combined') %>% 
  mutate(Area_type = 'Sussex areas combined') %>% 
  select(Area_code, Area_name, Area_type, Week_number, Week_ending, Cause, Place_of_death, Deaths) %>% 
  ungroup()

England_occurrence <- Occurrences_utla %>% 
  group_by(Week_number, Week_ending, Cause, Place_of_death) %>% 
  summarise(Deaths = sum(Deaths, na.rm = TRUE)) %>% 
  mutate(Area_code = 'E92000001',
         Area_name = 'England') %>% 
  mutate(Area_type = 'England') %>% 
  select(Area_code, Area_name, Area_type, Week_number, Week_ending, Cause, Place_of_death, Deaths) %>% 
  ungroup()

Occurrences <- Occurrences_utla %>% 
  bind_rows(Occurrences_region) %>% 
  bind_rows(Sussex_combined_occurrence) %>% 
  bind_rows(England_occurrence)

rm(Occurrences_utla, Occurrences_region ,England_occurrence, lookup, Sussex_combined_occurrence, week_ending)

All_settings_occurrences <- Occurrences %>% 
  group_by(Area_code, Area_name, Week_number, Week_ending, Cause) %>% 
  summarise(Deaths = sum(Deaths, na.rm = TRUE)) %>% 
  group_by(Area_code, Area_name, Cause) %>% 
  arrange(Area_code, Cause, Week_number) %>% 
  mutate(Cumulative_deaths = cumsum(Deaths)) %>% 
  left_join(mye_total[c('Area_code','All_ages')], by = 'Area_code') %>% 
  mutate(Cumulative_crude_rate_per_10000 = (Cumulative_deaths / All_ages) * 100000) %>% 
  mutate(Deaths_crude_rate_per_100000 =  pois.exact(Deaths, All_ages)[[3]]*100000) %>% 
  mutate(Deaths_crude_rate_lci = pois.exact(Deaths, All_ages)[[4]]*100000) %>% 
  mutate(Deaths_crude_rate_uci = pois.exact(Deaths, All_ages)[[5]]*100000) 

# Exact Poisin confidence intervals are calculated using the pois.exact function from the epitools package (see https://www.rdocumentation.org/packages/epitools/versions/0.09/topics/pois.exact for details)

Latest_occurrences <- All_settings_occurrences %>% 
  filter(Week_ending == max(Week_ending)) %>% 
  mutate(`Deaths in latest week` = paste0(format(Deaths, big.mark = ',', trim = TRUE), ' deaths (', format(round(Deaths_crude_rate_per_100000, 0), big.mark = ',', trim = TRUE), ' per 100,000, 95% CI: ', format(round(Deaths_crude_rate_lci, 0), big.mark = ',', trim = TRUE), '-', format(round(Deaths_crude_rate_uci, 0), big.mark = ',', trim = TRUE), ')')) 

Latest_occurrences_rate_labels <- Latest_occurrences %>% 
  select(Area_code, Area_name, Cause, Week_number, Week_ending, `Deaths in latest week`) %>% 
  spread(Cause, `Deaths in latest week`)

Covid_burden_of_all_mortality <- All_settings_occurrences %>% 
  select(Area_code, Area_name, Cause, Week_number, Week_ending, Deaths) %>% 
  group_by(Area_code, Area_name, Week_number, Week_ending) %>% 
  spread(Cause, Deaths) %>% 
  mutate(Proportion_covid_deaths = `COVID 19` / `All causes`) %>% 
  ungroup() %>% 
  mutate(Cumulative_deaths_all_cause = cumsum(`All causes`)) %>% 
  mutate(Cumulative_covid_deaths = cumsum(`COVID 19`)) 

Covid_burden_latest <- Covid_burden_of_all_mortality %>% 
  filter(Week_ending == max(Week_ending))

Place_death <- Occurrences %>% 
  group_by(Area_code, Area_name, Week_number, Week_ending, Cause,Deaths, Place_of_death) %>% 
  spread(Place_of_death, Deaths)

Care_home_deaths <- Occurrences %>% 
  filter(Place_of_death == 'Care home') %>% 
  left_join(mye_total[c('Area_code', 'Age_65_plus')], by = 'Area_code') %>% 
  mutate(Deaths_crude_rate_per_100000_65_plus =  pois.exact(Deaths, Age_65_plus)[[3]]*100000) %>% 
  mutate(Deaths_crude_rate_lci = pois.exact(Deaths, Age_65_plus)[[4]]*100000) %>% 
  mutate(Deaths_crude_rate_uci = pois.exact(Deaths, Age_65_plus)[[5]]*100000) 

Hospital_deaths <- Occurrences %>% 
  filter(Place_of_death == 'Care home') %>% 
  left_join(mye_total[c('Area_code', 'All_ages')], by = 'Area_code') %>% 
  mutate(Deaths_crude_rate_per_100000 =  pois.exact(Deaths, All_ages)[[3]]*100000) %>% 
  mutate(Deaths_crude_rate_lci = pois.exact(Deaths, All_ages)[[4]]*100000) %>% 
  mutate(Deaths_crude_rate_uci = pois.exact(Deaths, All_ages)[[5]]*100000) 

#  Notes and definitions											

# Deaths occurring in England and Wales are registered on the General Register Office's Registration Online system (RON).											
# Daily extracts of death registration records from RON are processed on our database systems.											
# Provisional data on deaths registered in each week (ending on a Friday) are compiled at the end of the following week.											
# Bank Holidays could affect the number of registrations made within those weeks.											

# The counts of deaths from specific conditons are updated with each weekly publication as the coding of the underlying cause is not always complete at the time of production.											
# For deaths registered from 1st January 2020, cause of death is coded to the ICD-10 classification using MUSE 5.5 software. Previous years were coded to IRIS 4.2.3, further information about the change in software is available.											

# Where there are the same values in categories in consecutive weeks, the counts have been checked and are made up of unique death registrations.							 Figures for the latest week are based on boundaries as of February 2020.		

# The DHSC release daily updates on the GOV.UK website counting the total number of deaths reported to them among patients who had tested positive for COVID-19. This covers all deaths that occurred in hospitals in England and were reported up to 5pm the day before, and all deaths in Wales, Scotland and Northern Ireland wherever they occurred, if known to the public health agencies. To allow comparison, only the numbers for England and Wales are shown here.

# The ONS provides figures based on all deaths registered involving COVID-19 according to death certification, whether in or out of hospital, for England and Wales. We also provide the figures by date of death (occurrence). More information can be found in the Measuring the data section of our weekly deaths publication.

# Trust level mortality ####

# Deaths of patients who have died in hospitals in England and had tested positive for Covid-19 at time of death. All deaths are recorded against the date of death rather than the day the deaths were announced. Likely to be some revision.

# Note: interpretation of the figures should take into account the fact that totals by date of death, particularly for recent prior days, are likely to be updated in future releases. For example as deaths are confirmed as testing positive for Covid-19, as more post-mortem tests are processed and data from them are validated. Any changes are made clear in the daily files.					

if(!file.exists(paste0(github_repo_dir, '/etr.csv'))){
  download.file('https://files.digital.nhs.uk/assets/ods/current/etr.zip', paste0(github_repo_dir, '/etr.zip'), mode = 'wb')
  unzip(paste0(github_repo_dir, '/etr.zip'), exdir = github_repo_dir)
  file.remove(paste0(github_repo_dir, '/etr.zip'), paste0(github_repo_dir, '/etr.pdf'))
}

etr <- read_csv(paste0(github_repo_dir, '/etr.csv'),col_names = c('Code', 'Name', 'National_grouping', 'Health_geography', 'Address_1', 'Address_2', 'Address_3', 'Address_4', 'Address_5', 'Postcode', 'Open_date', 'Close_date', 'Null_1', 'Null_2', 'Null_3', 'Null_4', 'Null_5', 'Contact', 'Null_6', 'Null_7', 'Null_8', 'Amended_record_indicator', 'Null_9', 'GOR', 'Null_10', 'Null_11', 'Null_12')) %>%
  select(Code, Name, National_grouping) %>%
  mutate(Name = capwords(Name, strict = TRUE)) %>%
  mutate(Name = gsub(' And ', ' and ', Name)) %>%
  mutate(Name = gsub(' Of ', ' of ', Name)) %>%
  mutate(Name = gsub(' Nhs ', ' NHS ', Name)) %>%
  add_row( Code = '-', Name = 'England', National_grouping = '-')

# This should download the data for today (it will only work after the new file is published at 5pm though), shame on those who release new filenames each day and do not allow for a static url
download.file(paste0('https://www.england.nhs.uk/statistics/wp-content/uploads/sites/2/2020/',format(Sys.Date(), '%m'),'/COVID-19-total-announced-deaths-',format(Sys.Date(), '%d-%B-%Y'),'.xlsx'), paste0(github_repo_dir, '/refreshed_daily_deaths_trust.xlsx'), mode = 'wb')


refreshed_daily_deaths_trust <- read_excel(paste0(github_repo_dir, "/refreshed_daily_deaths_trust.xlsx"), sheet = 'COVID19 total deaths by trust', skip = 15)%>% 
   select(-c(...2, Total)) %>% 
   filter(!is.na(Code)) %>% 
   mutate(Name = capwords(Name, strict = TRUE)) %>% 
   gather(key = "Date", value = "Deaths", 5:ncol(.)) %>% 
   mutate(Date = as.Date(as.numeric(Date), origin = "1899-12-30")) %>% 
   filter(!is.na(Date))

meta_trust_deaths <- read_excel(paste0(github_repo_dir, "/refreshed_daily_deaths_trust.xlsx"), sheet = 'COVID19 total deaths by trust', skip = 2, col_names = FALSE, n_max = 5) %>% 
  rename(Item = ...1,
         Description = ...2) %>%
  mutate(Description = ifelse(Item == 'Published:', as.character(format(as.Date(as.numeric(Description), origin = "1899-12-30"), '%d-%b-%Y')), Description)) 

