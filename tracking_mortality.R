# tracking mortality
library(easypackages)

libraries(c("readxl", "readr", "plyr", "dplyr", "ggplot2", "tidyverse", "reshape2", "scales", 'jsonlite', 'zoo', 'stats', 'aweek', 'epitools', 'fingertipsR'))

github_repo_dir <- "~/Documents/Repositories/another_covid_repo"

capwords = function(s, strict = FALSE) {
  cap = function(s) paste(toupper(substring(s, 1, 1)),
                          {s = substring(s, 2); if(strict) tolower(s) else s},sep = "", collapse = " " )
  sapply(strsplit(s, split = " "), cap, USE.NAMES = !is.null(names(s)))}

options(scipen = 999)

# 2018 MYE
mye_total_raw <- read_csv('http://www.nomisweb.co.uk/api/v01/dataset/NM_2002_1.data.csv?geography=1816133633...1816133848,1820327937...1820328318,2092957697...2092957703,2013265921...2013265932&date=latest&gender=0&c_age=200,209&measures=20100&select=date_name,geography_name,geography_code,geography_type,c_age_name,obs_value') %>%  
  rename(Population = OBS_VALUE,
         Area_code = GEOGRAPHY_CODE,
         Name = GEOGRAPHY_NAME,
         Year = DATE_NAME,
         Age = C_AGE_NAME,
         Type = GEOGRAPHY_TYPE) %>% 
  unique() %>%
  group_by(Name, Area_code) %>% 
  mutate(Count = n()) %>% 
  mutate(Type = ifelse(Count == 4, 'Unitary Authority', ifelse(Type == 'local authorities: county / unitary (as of April 2019)', 'Upper Tier Local Authority', ifelse(Type == 'local authorities: district / unitary (as of April 2019)', 'Lower Tier Local Authority', ifelse(Type == 'regions', 'Region', ifelse(Type == 'countries', 'Country', Type)))))) %>% 
  ungroup() %>% 
  select(-Count) %>% 
  unique()

areas_care_home_beds <- mye_total_raw %>% 
  select(Name, Area_code, Type) %>% 
  unique()

# This is the number of beds in care homes (all; nursing and residential) in each area as reported by Care Quality Care (CQC) on the 31st of March 2019.

care_home_beds_utla <- fingertips_data(IndicatorID = 92489, AreaTypeID = 102) %>% 
  filter(Timeperiod == max(Timeperiod)) %>% 
  filter(Age == 'All ages') %>% 
  select(AreaCode, AreaName, Count) %>%
  rename(Area_code = AreaCode,
         Name = AreaName,
         Care_home_beds = Count) 

care_home_beds_ltla <- fingertips_data(IndicatorID = 92489, AreaTypeID = 101) %>% 
  filter(Timeperiod == max(Timeperiod)) %>% 
  filter(Age == 'All ages') %>% 
  select(AreaCode, AreaName, Count) %>% 
  rename(Area_code = AreaCode,
         Name = AreaName,
         Care_home_beds = Count)

care_home_beds_raw <- care_home_beds_ltla %>% 
  bind_rows(care_home_beds_utla) %>% 
  unique() 

sussex_ch_beds <- care_home_beds_raw %>% 
  filter(Name %in% c('Brighton and Hove', 'East Sussex', 'West Sussex')) %>% 
  summarise(Care_home_beds = sum(Care_home_beds, na.rm = TRUE)) %>% 
  mutate(Name = 'Sussex areas combined') %>% 
  mutate(Area_code = '-') 

care_home_beds <- care_home_beds_raw %>% 
  bind_rows(sussex_ch_beds) %>% 
  select(-Name)

area_code_names <- mye_total_raw %>% 
  select(Area_code, Name) %>% 
  rename(Code = Area_code) %>% 
  unique() 

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
         Age_65_plus = `Aged 65+`) %>% 
  left_join(care_home_beds, by = 'Area_code')

rm(mye_total_raw, sussex_pop, areas_care_home_beds, care_home_beds_ltla, care_home_beds_raw, care_home_beds_utla, care_home_beds, sussex_ch_beds)
   
# Something freaky is happening with downloading of data from Open Geography Portal. The stable urls are broken using the direct reading in R. The quickest workaround (and most frustrating) is to manually download both the ltla to utla and ltla to region look up files and combine them.
if(!file.exists(paste0(github_repo_dir, '/ltla_utla_region_lookup_april_19.csv'))){
# Lookups from ltla to utla and region
lookup <- read_csv(url("https://opendata.arcgis.com/datasets/3e4f4af826d343349c13fb7f0aa2a307_0.csv")) #%>% 
  select(-c(FID, LTLA19NM)) %>% 
  left_join(read_csv(url('https://opendata.arcgis.com/datasets/3ba3daf9278f47daba0f561889c3521a_0.csv')), by = c('LTLA19CD' = 'LAD19CD')) %>% 
  select(-c(FID, LAD19NM))

}

if(file.exists(paste0(github_repo_dir, '/ltla_utla_region_lookup_april_19.csv'))){
  lookup <- read_csv(paste0(github_repo_dir, '/ltla_utla_region_lookup_april_19.csv'))
}

# DHSC running total - daily deaths - be cautious of the definition of these deaths
read_csv('https://coronavirus.data.gov.uk/downloads/csv/coronavirus-deaths_latest.csv') %>%
  filter(`Area name` == 'England') %>% 
  filter(`Reporting date` == max(`Reporting date`)) %>% 
  rename(New_deaths = 'Daily change in deaths') %>% 
  select(-c(`Area code`, `Area name`)) %>% 
  mutate(Date_label = format(`Reporting date`, '%a %d %B')) %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/another_covid_repo/england_latest_mortality.json'))

# bh_nn <- c('Nottingham', 'Medway', 'Newcastle upon Tyne', 'Liverpool','Portsmouth','Southampton','Leeds','Sheffield','York','Plymouth','Salford','Coventry','Bristol','Southend-on-Sea','Brighton and Hove', 'Reading')
# 
# es_nn <- c('Nottinghamshire','Kent','Lancashire','Norfolk','Worcestershire','Staffordshire','Somerset','East Sussex','Devon','Gloucestershire','North Yorkshire','Suffolk','Warwickshire','Essex', 'West Sussex','Hampshire')
# 
# ws_nn <- c('Kent','Northamptonshire','Worcestershire', 'Staffordshire','Somerset','East Sussex', 'Devon', 'Gloucestershire', 'Cambridgeshire','North Yorkshire','Suffolk','Warwickshire','Essex','West Sussex', 'Hampshire', 'Oxfordshire')

# ONS Weekly mortality data ####

# Weekly death figures provide provisional counts of the number of deaths registered in England and Wales for which data are available.	From 31 March 2020 these figures also show the number of deaths involving coronavirus (COVID-19), based on any mention of COVID-19 on the death certificate.											

# The tables include deaths that occurred up to the Friday before last but were registered up to last Friday. Figures by place of death may differ to previously published figures due to improvements in the way we code place of death.											

# These figures do not include deaths of those residents outside England and Wales or those records where the place of residence is either missing or not yet fully coded. For this reason counts may differ to published figures when summed. These figures represent death occurrences and registrations, there can be a delay between the date a death occurred and the date a death was registered. More information can be found in our impact of registration delays release. 	

# For this data, the week ends on a friday (so friday is the cut off date for each week of data). It might be helpful for us to say as at this date this is the number of deaths. To do this we need to convert each week number into a 'friday date'.
set_week_start('Friday')

week_ending <- data.frame(Week_ending = get_date(week = 1:52, year = 2020)) %>% 
  mutate(Week_number = row_number())

# Download the data. I am hoping that this is a stable url that will be updated each week
# download.file('https://www.ons.gov.uk/file?uri=%2fpeoplepopulationandcommunity%2fhealthandsocialcare%2fcausesofdeath%2fdatasets%2fdeathregistrationsandoccurrencesbylocalauthorityandhealthboard%2f2020/lahbtables.xlsx', paste0(github_repo_dir, '/ons_mortality.xlsx'), mode = 'wb')

# Boo! but we can get around it with some date hackery. This will probably not work on Tuesday morning next week
# download.file(paste0('https://www.ons.gov.uk/file?uri=%2fpeoplepopulationandcommunity%2fhealthandsocialcare%2fcausesofdeath%2fdatasets%2fdeathregistrationsandoccurrencesbylocalauthorityandhealthboard%2f2020/lahbtablesweek',substr(as.character(as.aweek(Sys.Date()-11)), 7,8), 'finalcodes.xlsx'), paste0(github_repo_dir, '/ons_mortality.xlsx'), mode = 'wb')

download.file('https://www.ons.gov.uk/file?uri=%2fpeoplepopulationandcommunity%2fhealthandsocialcare%2fcausesofdeath%2fdatasets%2fdeathregistrationsandoccurrencesbylocalauthorityandhealthboard%2f2020/lahbtablesweek21.xlsx', paste0(github_repo_dir, '/ons_mortality.xlsx'), mode = 'wb')

# https://www.ons.gov.uk/file?uri=%2fpeoplepopulationandcommunity%2fhealthandsocialcare%2fcausesofdeath%2fdatasets%2fdeathregistrationsandoccurrencesbylocalauthorityandhealthboard%2f2020/lahbtablesweek20finalcodes.xlsx

# Use occurances, be mindful that the most recent week of occurance data may not be complete if the death is not registered within 7 days (there is a week lag in reporting to allow up to seven days for registration to take place), this will be updated each week. Estimates suggest around 74% of deaths in England and Wales are registered within seven calendar days of occurance, with the proportion as low as 68% in the South East region. It is difficult to know what impact Covid-19 has on length of time taken to register a death. 

# Occurrences data is produced at ltla level and we would probably find it useful to aggregate to utla and region for our analysis

Occurrences_ltla <- read_excel(paste0(github_repo_dir, '/ons_mortality.xlsx'), sheet = 'Occurrences - All data', skip = 2) %>% 
  filter(`Geography type` == 'Local Authority') %>% 
  filter(substr(`Area code`, 1,1) == 'E') %>% 
  rename(Area_name = `Area name`,
         Area_code = `Area code`,
         Cause = `Cause of death`,
         Week_number = `Week number`,
         Place_of_death = `Place of death`,
         Deaths = `Number of deaths`) %>% 
  mutate(Area_type = 'LTLA') %>% 
  select(Area_code, Area_name, Area_type, Week_number, Cause, Place_of_death, Deaths) %>% 
  left_join(week_ending, by = 'Week_number') %>% 
  ungroup()

# Occurrences data is produced at ltla level and we would probably find it useful to aggregate to utla and region for our analysis
Occurrences_utla <- read_excel(paste0(github_repo_dir, '/ons_mortality.xlsx'), sheet = 'Occurrences - All data', skip = 2) %>% 
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

Occurrences_la <- Occurrences_ltla %>% 
  bind_rows(Occurrences_utla) %>% 
  group_by(Area_name, Area_code, Cause, Week_ending, Week_number, Place_of_death) %>% 
  mutate(Count = n()) %>% 
  filter(!(Area_type == 'UTLA' & Count == 2)) %>% 
  select(-c(Area_type, Count)) %>% 
  left_join(mye_total[c('Area_code', 'Type')], by = 'Area_code') %>% 
  ungroup()

rm(Occurrences_ltla, Occurrences_utla)

Occurrences_region <- read_excel(paste0(github_repo_dir, '/ons_mortality.xlsx'), sheet = 'Occurrences - All data', skip = 2) %>% 
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
  mutate(Type = 'Region') %>% 
  select(Area_code, Area_name, Type, Week_number, Cause, Place_of_death, Deaths) %>% 
  left_join(week_ending, by = 'Week_number') %>% 
  ungroup()

Sussex_combined_occurrence <- Occurrences_la %>% 
  filter(Area_name %in% c('Brighton and Hove', 'East Sussex', 'West Sussex')) %>% 
  group_by(Week_number, Week_ending, Cause, Place_of_death) %>% 
  summarise(Deaths = sum(Deaths, na.rm = TRUE)) %>% 
  mutate(Area_code = '-',
         Area_name = 'Sussex areas combined') %>% 
  mutate(Type = 'Sussex areas combined') %>% 
  select(Area_code, Area_name, Type, Week_number, Week_ending, Cause, Place_of_death, Deaths) %>% 
  ungroup()

England_occurrence <- read_excel(paste0(github_repo_dir, '/ons_mortality.xlsx'), sheet = 'Occurrences - All data', skip = 2) %>% 
  filter(`Geography type` == 'Local Authority') %>% 
  filter(substr(`Area code`, 1,1) == 'E') %>% 
  rename(Area_name = `Area name`,
         Area_code = `Area code`,
         Cause = `Cause of death`,
         Week_number = `Week number`,
         Place_of_death = `Place of death`,
         Deaths = `Number of deaths`) %>%  
  group_by(Week_number, Cause, Place_of_death) %>% 
  summarise(Deaths = sum(Deaths, na.rm = TRUE)) %>% 
  mutate(Area_code = 'E92000001',
         Area_name = 'England') %>% 
  mutate(Type = 'England') %>% 
  left_join(week_ending, by = 'Week_number') %>% 
  select(Area_code, Area_name, Type, Week_number, Week_ending, Cause, Place_of_death, Deaths) %>% 
  ungroup()

Occurrences <- Occurrences_la %>% 
  bind_rows(Occurrences_region) %>% 
  bind_rows(Sussex_combined_occurrence) %>% 
  bind_rows(England_occurrence) %>% 
  rename(Code = Area_code,
         Name = Area_name)

rm(Occurrences_la, Occurrences_region ,England_occurrence, lookup, Sussex_combined_occurrence, week_ending)

All_settings_occurrences <- Occurrences %>% 
  group_by(Code, Name, Week_number, Week_ending, Cause) %>% 
  summarise(Deaths = sum(Deaths, na.rm = TRUE)) %>% 
  group_by(Code, Name, Cause) %>% 
  arrange(Code, Cause, Week_number) %>% 
  mutate(Cumulative_deaths = cumsum(Deaths)) %>% 
  left_join(mye_total[c('Area_code','All_ages')], by = c('Code' = 'Area_code')) %>% 
  mutate(Cumulative_crude_rate_per_100000 = (Cumulative_deaths / All_ages) * 100000) %>% 
  mutate(Deaths_crude_rate_per_100000 =  pois.exact(Deaths, All_ages)[[3]]*100000) %>% 
  mutate(Deaths_crude_rate_lci = pois.exact(Deaths, All_ages)[[4]]*100000) %>% 
  mutate(Deaths_crude_rate_uci = pois.exact(Deaths, All_ages)[[5]]*100000) %>% 
  ungroup()

All_settings_occurrences %>% 
  write.csv(., paste0(github_repo_dir, '/All_settings_deaths_occurrences.csv'), na = '', row.names = FALSE)
  
# Exact Poisin confidence intervals are calculated using the pois.exact function from the epitools package (see https://www.rdocumentation.org/packages/epitools/versions/0.09/topics/pois.exact for details)

Latest_occurrences <- All_settings_occurrences %>% 
  filter(Week_ending == max(Week_ending)) %>% 
  mutate(`Deaths in latest week` = paste0(format(Deaths, big.mark = ',', trim = TRUE), ' deaths (', format(round(Deaths_crude_rate_per_100000, 0), big.mark = ',', trim = TRUE), ' per 100,000, 95% CI: ', format(round(Deaths_crude_rate_lci, 0), big.mark = ',', trim = TRUE), '-', format(round(Deaths_crude_rate_uci, 0), big.mark = ',', trim = TRUE), ')')) 

# Latest_occurrences_rates <- Latest_occurrences %>% 
#   select(Code, Name, Cause, Week_number, Week_ending, `Deaths in latest week`) %>% 
#   spread(Cause, `Deaths in latest week`)

Latest_all_cause_occurrences <- Latest_occurrences %>% 
  filter(Cause == 'All causes')

Latest_covid_occurrences <- Latest_occurrences %>% 
  filter(Cause == 'COVID 19')

Covid_burden_of_all_mortality <- All_settings_occurrences %>% 
  select(Code, Name, Cause, Week_number, Week_ending, Deaths) %>% 
  group_by(Code, Name, Week_number, Week_ending) %>% 
  spread(Cause, Deaths) %>% 
  mutate(Proportion_covid_deaths_occuring_in_week = `COVID 19` / `All causes`) %>% 
  group_by(Code, Name) %>% 
  mutate(Cumulative_deaths_all_cause = cumsum(`All causes`)) %>% 
  mutate(Cumulative_covid_deaths = cumsum(`COVID 19`)) %>% 
  mutate(Proportion_covid_deaths_to_date = Cumulative_covid_deaths / Cumulative_deaths_all_cause) %>% 
  ungroup()

Covid_burden_latest <- Covid_burden_of_all_mortality %>% 
  filter(Week_ending == max(Week_ending)) %>% 
  left_join(Latest_all_cause_occurrences[c('Name', 'Cumulative_crude_rate_per_100000', 'Deaths_crude_rate_per_100000', 'Deaths in latest week')], by = 'Name') %>% 
  select(Name, Week_number, Week_ending, `All causes`, Deaths_crude_rate_per_100000, Cumulative_deaths_all_cause, Cumulative_crude_rate_per_100000, `Deaths in latest week`, `COVID 19`,Cumulative_covid_deaths, Proportion_covid_deaths_occuring_in_week, Proportion_covid_deaths_to_date) %>% 
  rename('All cause deaths in week'= `All causes`,
         `All cause deaths in week per 100,000 population` = Deaths_crude_rate_per_100000,
         'Total number of all cause deaths to date in 2020' = Cumulative_deaths_all_cause,
         `Total number of all cause deaths to date per 100,000 population` = Cumulative_crude_rate_per_100000,
         `All cause latest week summary` = `Deaths in latest week`,
         `Deaths attributed to Covid-19 in week` = `COVID 19`,
         `Total number of deaths attributed to Covid-19 to date in 2020` = Cumulative_covid_deaths,
         `Proportion of deaths occuring in week that are attributed to Covid-19` = Proportion_covid_deaths_occuring_in_week,
         `Proportion of deaths to date in 2020 attributed to Covid-19` = Proportion_covid_deaths_to_date) %>% 
  left_join(Latest_covid_occurrences[c('Name', 'Cumulative_crude_rate_per_100000', 'Deaths_crude_rate_per_100000', 'Deaths in latest week')], by = 'Name') %>% 
  rename(`Covid-19 deaths in week per 100,000 population` = Deaths_crude_rate_per_100000,
         `Total number of deaths attributed to Covid-19 to date per 100,000 population` = Cumulative_crude_rate_per_100000,
         `Covid-19 latest week summary` = `Deaths in latest week`) %>% 
  select(Name, Week_number, Week_ending, `All cause deaths in week`, `All cause deaths in week per 100,000 population`, `Total number of all cause deaths to date in 2020`, `Total number of all cause deaths to date per 100,000 population`, `All cause latest week summary`, `Deaths attributed to Covid-19 in week`, `Covid-19 deaths in week per 100,000 population`, `Total number of deaths attributed to Covid-19 to date in 2020`, `Total number of deaths attributed to Covid-19 to date per 100,000 population`, `Covid-19 latest week summary`, `Proportion of deaths occuring in week that are attributed to Covid-19`, `Proportion of deaths to date in 2020 attributed to Covid-19`)

Covid_burden_all_age_latest_SE <- Covid_burden_latest %>% 
  filter(Name %in%  c('Brighton and Hove', 'Bracknell Forest', 'Buckinghamshire', 'East Sussex', 'Hampshire', 'Isle of Wight', 'Kent', 'Medway', 'Milton Keynes', 'Oxfordshire', 'Portsmouth', 'Reading', 'Slough', 'Southampton', 'Surrey', 'West Berkshire', 'West Sussex', 'Windsor and Maidenhead', 'Wokingham', 'Sussex areas combined', 'South East', 'England')) %>% 
  mutate(Name = ifelse(Name == 'South East', 'South East region', Name))

SE_area_code_names <- area_code_names %>% 
  filter(Name %in% c('Brighton and Hove', 'East Sussex', 'West Sussex'))

bh_nn <- data.frame(Name = rep('Brighton and Hove',16), Nearest_neighbour = c('Nottingham', 'Medway', 'Newcastle upon Tyne', 'Liverpool','Portsmouth','Southampton','Leeds','Sheffield','York','Plymouth','Salford','Coventry','Bristol, City of','Southend-on-Sea','Brighton and Hove', 'Reading'))

es_nn <- data.frame(Name = rep('East Sussex',16), Nearest_neighbour =  c('Nottinghamshire','Kent','Lancashire','Norfolk','Worcestershire','Staffordshire','Somerset','East Sussex','Devon','Gloucestershire','North Yorkshire','Suffolk','Warwickshire','Essex', 'West Sussex','Hampshire'))

ws_nn <- data.frame(Name = rep('West Sussex',16), Nearest_neighbour = c('Kent','Northamptonshire','Worcestershire', 'Staffordshire','Somerset','East Sussex', 'Devon', 'Gloucestershire', 'Cambridgeshire','North Yorkshire','Suffolk','Warwickshire','Essex','West Sussex', 'Hampshire', 'Oxfordshire'))

nn_area <- bh_nn %>% 
  bind_rows(es_nn) %>% 
  bind_rows(ws_nn)

all_deaths_cipfa_SE <- nn_area %>% 
  left_join(Covid_burden_latest, by = c('Nearest_neighbour' = 'Name')) %>% 
  group_by(Name) %>% 
  mutate(`Rank of cumulative all cause deaths crude rate among CIPFA neighbours` = ordinal(rank(-`Total number of all cause deaths to date per 100,000 population`))) %>%
  mutate(`Rank of latest Covid-19 deaths crude rate among CIPFA neighbours` = ordinal(rank(-`Covid-19 deaths in week per 100,000 population`))) %>%
  mutate(`Rank of cumulative Covid-19 deaths crude rate among CIPFA neighbours` = ordinal(rank(-`Total number of deaths attributed to Covid-19 to date per 100,000 population`))) %>%
  mutate(`Rank of proportion of deaths to date attributed to Covid-19 among CIPFA neighbours` = ordinal(rank(-`Proportion of deaths to date in 2020 attributed to Covid-19`))) %>% 
  filter(Name == Nearest_neighbour)

# Exporting for figures ####

Occurrences %>% 
  select(Week_ending) %>% 
  unique() %>% 
  filter(Week_ending == max(Week_ending)) %>% 
  rename(Occurring_week_ending = Week_ending) %>% 
  mutate(Reported_week_ending = format(Occurring_week_ending + 7, '%B %d %Y')) %>% 
  mutate(Occurring_week_ending = format(Occurring_week_ending, '%B %d %Y')) %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/another_covid_repo/ons_weekly_mortality_dates.json'))

SE_deaths_by_cause_cat <- All_settings_occurrences %>% 
  filter(Name %in%  c('Brighton and Hove', 'Bracknell Forest', 'Buckinghamshire', 'East Sussex', 'Hampshire', 'Isle of Wight', 'Kent', 'Medway', 'Milton Keynes', 'Oxfordshire', 'Portsmouth', 'Reading', 'Slough', 'Southampton', 'Surrey', 'West Berkshire', 'West Sussex', 'Windsor and Maidenhead', 'Wokingham', 'Sussex areas combined', 'South East', 'England')) %>%
  ungroup() %>% 
  select(Name, Week_number, Week_ending, Cause, Deaths) %>% 
  group_by(Name, Week_number, Week_ending) %>% 
  spread(Cause, Deaths) %>% 
  mutate(`Not attributed to Covid-19` = `All causes` - `COVID 19`) %>% 
  rename(`Covid-19` = `COVID 19`) %>% 
  mutate(Deaths_in_week_label = paste0('The total number of deaths occurring in the week ending ', format(Week_ending, '%d %B %Y'), ' in ', Name, ' was<b> ', format(`All causes`, big.mark = ',', trim = TRUE), '</b>. Of these, <b>', format(`Covid-19`, big.mark = ',', trim = TRUE), ifelse(`Covid-19` == 1, ' death</b> was', ' deaths</b> were'), ' attributed to Covid-19. This is ',  round((`Covid-19`/`All causes`) * 100, 1), '% of deaths occuring in this week.')) %>% 
  group_by(Name) %>% 
  mutate(Cumulative_deaths_all_cause = cumsum(`All causes`)) %>% 
  mutate(Cumulative_covid_deaths = cumsum(`Covid-19`)) %>% 
  mutate(Cumulative_deaths_label = paste0('As at ', format(Week_ending, '%d %B %Y'), ' in ', Name, ' the total cumulative number of deaths for 2020 was<b> ', format(Cumulative_deaths_all_cause, big.mark = ',', trim = TRUE), '</b>. The cumulative number of deaths where Covid-19 is recorded as a cause by this date was ', format(Cumulative_covid_deaths, big.mark = ',', trim = TRUE), '. This is ', round((Cumulative_covid_deaths/Cumulative_deaths_all_cause) * 100, 1), '% of deaths occuring by this week.'))

SE_deaths_by_cause_cat %>% 
  mutate(Date_label = paste('w/e ', ordinal(as.numeric(format(Week_ending, '%d'))), format(Week_ending, '%b'))) %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/another_covid_repo/deaths_all_settings_SE.json'))

# SE_deaths_by_cause_cat %>%   
#   gather(key = Cause, value = Deaths, `All causes`:`Not attributed to Covid-19`) %>% 
#   group_by(Name, Cause) %>% 
#   mutate(Cumulative_deaths = cumsum(Deaths))

all_deaths_cipfa_SE %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/another_covid_repo/latest_cipfa_deaths_all_settings_ranks_SE.json'))

all_deaths_cipfa_SE %>% 
  write.csv(., paste0(github_repo_dir, '/all_deaths_cipfa_ons.csv'), row.names = FALSE, na = '')

# ASMR and MSOA by sex ####

# ONS granular analysis of deaths since March 01 2020 and April 17 2020. It is important to note that only deaths that were registered by the 18th April are included. Note this is different again to other data sources and cannot be compared with the ONS weekly 2020 figures as they have a longer time period to capture occurrences (7 days rather than 1 day) and also this dataset includes only a few weeks rather than all weeks in 2020.

# Age-standardised mortality rates are presented per 100,000 people and standardised to the 2013 European Standard Population. Age-standardised mortality rates allow for differences in the age structure of populations and therefore allow valid comparisons to be made between geographical areas, the sexes and over time. 														
# Rates have been calculated using 2018 mid-year population estimates, the most up-to-date estimates when published. Causes of death was defined using the International Classification of Diseases, Tenth Revision (ICD-10) codes U07.1 and U07.2. Figures include deaths where coronavirus (COVID-19) was the underlying cause or was mentioned on the death certificate as a contributory factor. Figures do not include neonatal deaths (deaths under 28 days).														
# u = low reliability The age-standardised rate is of low quality.														
# : = not available The age-standardised rate and its lower and upper confidence interval is unavailable.														
# Figures are for deaths occurring between 1 March 2020 and 17 April 2020. Figures only include deaths that were registered by 18 April 2020. More information on registration delays can be found on the ONS website:														
download.file('https://www.ons.gov.uk/file?uri=%2fpeoplepopulationandcommunity%2fbirthsdeathsandmarriages%2fdeaths%2fdatasets%2fdeathsinvolvingcovid19bylocalareaanddeprivation%2f1march2020to17april2020/referencetablesdraft.xlsx', paste0(github_repo_dir, '/granular_mortality_file.xlsx'), mode = 'wb')

la_asmr <- read_excel(paste0(github_repo_dir, '/granular_mortality_file.xlsx'), sheet = "Table 2", skip = 5, col_names = c('Sex',	'Area_type',	'Code',	'Name',	'All_cause_deaths',	'All_cause_ASMR',	'All_cause_ASMR_data_quality',	'All_cause_ASMR_lci',	'All_cause_ASMR_uci',	'null',	'Covid_deaths',	'Covid_ASMR',	'Covid_ASMR_data_quality',	'Covid_ASMR_lci',	'Covid_ASMR_uci'), col_types = c("text", "text", "text", "text", "numeric", "numeric", "text", "numeric", "numeric", "text", "numeric", "numeric", "text", "numeric", "numeric")) %>% 
  select(-null) %>% 
  filter(!is.na(Name))

la_asmr %>% 
  write.csv(., paste0(github_repo_dir, '/mortality_01_march_to_date_la.csv'), row.names = FALSE, na = '')

msoa_deaths <- read_excel("~/Documents/Repositories/another_covid_repo/granular_mortality_file.xlsx", sheet = "Table 5", col_types = c("text","text", "numeric", "numeric", "numeric"), skip = 11) 

msoa_deaths %>% 
  write.csv(., paste0(github_repo_dir, '/mortality_01_march_to_date_msoa.csv'), row.names = FALSE, na = '')

dates_granular <- read_excel("~/Documents/Repositories/another_covid_repo/granular_mortality_file.xlsx", sheet = "Contents") %>% 
  filter(`Worksheet name` %in% c('Table 2', 'Table 5'))

# Place of death ####

Place_death <- Occurrences %>% 
  mutate(Place_of_death = ifelse(Place_of_death %in% c('Other communal establishment', 'Elsewhere'), 'Elsewhere (including other communal establishments)', Place_of_death)) %>% 
  group_by(Code, Name, Week_number, Week_ending, Cause, Place_of_death) %>% 
  summarise(Deaths = sum(Deaths, na.rm = TRUE))

Place_death %>% 
  write.csv(., paste0(github_repo_dir, '/Mortality_place_of_death_weekly.csv'), na = '', row.names = FALSE)

Place_death %>%
  filter(Cause == 'All causes') %>% 
  spread(Place_of_death, Deaths) %>% 
  mutate(Date_label = paste('w/e ', ordinal(as.numeric(format(Week_ending, '%d'))), format(Week_ending, '%b'))) %>%
  mutate(`All places` = `Care home` + `Elsewhere (including other communal establishments)` + Home + Hospice + Hospital) %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/another_covid_repo/deaths_all_cause_by_place_SE.json'))

Place_death %>%
  filter(Cause == 'All causes') %>% 
  group_by(Name, Place_of_death) %>% 
  arrange(Week_ending) %>% 
  mutate(Cumulative_deaths = cumsum(Deaths)) %>% 
  select(-Deaths) %>% 
  spread(Place_of_death, Cumulative_deaths) %>%
  mutate(Date_label = paste('w/e ', ordinal(as.numeric(format(Week_ending, '%d'))), format(Week_ending, '%b'))) %>%
  mutate(`All places` = `Care home` + `Elsewhere (including other communal establishments)` + Home + Hospice + Hospital) %>%
  toJSON() %>%
  write_lines(paste0('/Users/richtyler/Documents/Repositories/another_covid_repo/cumulative_deaths_all_cause_by_place_SE.json'))

Place_death %>%
  filter(Cause == 'COVID 19') %>% 
  spread(Place_of_death, Deaths) %>% 
  mutate(Date_label = paste('w/e ', ordinal(as.numeric(format(Week_ending, '%d'))), format(Week_ending, '%b'))) %>%
  mutate(`All places` = `Care home` + `Elsewhere (including other communal establishments)` + Home + Hospice + Hospital) %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/another_covid_repo/deaths_covid_by_place_SE.json'))

Place_death %>%
  filter(Cause == 'COVID 19') %>% 
  group_by(Name, Place_of_death) %>% 
  arrange(Week_ending) %>% 
  mutate(Cumulative_deaths = cumsum(Deaths)) %>% 
  select(-Deaths) %>% 
  spread(Place_of_death, Cumulative_deaths) %>%
  mutate(Date_label = paste('w/e ', ordinal(as.numeric(format(Week_ending, '%d'))), format(Week_ending, '%b'))) %>%
  mutate(`All places` = `Care home` + `Elsewhere (including other communal establishments)` + Home + Hospice + Hospital) %>%
  toJSON() %>%
  write_lines(paste0('/Users/richtyler/Documents/Repositories/another_covid_repo/cumulative_deaths_covid_by_place_SE.json'))

# Care home deaths ONS ####

Care_home_deaths <- Occurrences %>% 
  filter(Place_of_death == 'Care home') %>% 
  group_by(Code, Name, Cause) %>% 
  arrange(Name, Cause, Week_ending) %>% 
  mutate(Cumulative_deaths = cumsum(Deaths)) %>% 
  ungroup() %>% 
  left_join(mye_total[c('Area_code', 'Care_home_beds')], by = c('Code' = 'Area_code')) %>% 
  mutate(Deaths_crude_rate_per_1000_care_home_beds =  pois.exact(Deaths, Care_home_beds)[[3]]*1000) %>% 
  mutate(Deaths_crude_rate_lci = pois.exact(Deaths, Care_home_beds)[[4]]*1000) %>% 
  mutate(Deaths_crude_rate_uci = pois.exact(Deaths, Care_home_beds)[[5]]*1000) %>% 
  mutate(Cumulative_deaths_crude_rate_per_1000_care_home_beds =  pois.exact(Cumulative_deaths, Care_home_beds)[[3]]*1000) %>% 
  mutate(Cumulative_deaths_crude_rate_lci = pois.exact(Cumulative_deaths, Care_home_beds)[[4]]*1000) %>% 
  mutate(Cumulative_deaths_crude_rate_uci = pois.exact(Cumulative_deaths, Care_home_beds)[[5]]*1000) %>% 
  mutate(Deaths_label = paste0(format(Deaths, big.mark = ',', trim = TRUE), ' deaths (', format(round(Deaths_crude_rate_per_1000_care_home_beds, 0), big.mark = ',', trim = TRUE), ' per 1,000 care home beds, 95% CI: ', format(round(Deaths_crude_rate_lci, 0), big.mark = ',', trim = TRUE), '-', format(round(Deaths_crude_rate_uci, 0), big.mark = ',', trim = TRUE), ')')) %>% 
  mutate(Cumulative_deaths_label = paste0(format(Cumulative_deaths, big.mark = ',', trim = TRUE), ' deaths (', format(round(Cumulative_deaths_crude_rate_per_1000_care_home_beds, 0), big.mark = ',', trim = TRUE), ' per 1,000 care home beds, 95% CI: ', format(round(Cumulative_deaths_crude_rate_lci, 0), big.mark = ',', trim = TRUE), '-', format(round(Cumulative_deaths_crude_rate_uci, 0), big.mark = ',', trim = TRUE), ')')) 

Care_home_latest_all_cause <- Care_home_deaths %>% 
  filter(Week_ending == max(Week_ending)) %>% 
  filter(Cause == 'All causes')

Care_home_latest_covid <- Care_home_deaths %>% 
  filter(Week_ending == max(Week_ending)) %>% 
  filter(Cause == 'COVID 19')

Covid_burden_of_all_mortality_care_homes <- Care_home_deaths %>% 
  select(Code, Name, Cause, Week_number, Week_ending, Deaths) %>% 
  group_by(Code, Name, Week_number, Week_ending) %>% 
  spread(Cause, Deaths) %>% 
  mutate(Proportion_covid_deaths_occuring_in_week = `COVID 19` / `All causes`) %>% 
  group_by(Code, Name) %>% 
  mutate(Cumulative_deaths_all_cause = cumsum(`All causes`)) %>% 
  mutate(Cumulative_covid_deaths = cumsum(`COVID 19`)) %>% 
  mutate(Proportion_covid_deaths_to_date = Cumulative_covid_deaths / Cumulative_deaths_all_cause) %>% 
  ungroup()

Covid_burden_latest_care_homes <- Covid_burden_of_all_mortality_care_homes %>% 
  filter(Week_ending == max(Week_ending)) %>% 
  left_join(Care_home_latest_all_cause[c('Name', 'Cumulative_deaths_crude_rate_per_1000_care_home_beds', 'Deaths_crude_rate_per_1000_care_home_beds', 'Deaths_label', 'Cumulative_deaths_label')], by = 'Name') %>% 
  rename('All cause care home deaths in week'= `All causes`,
         `All cause care home deaths in week per 1,000 care home beds` = Deaths_crude_rate_per_1000_care_home_beds,
         'Total number of all cause care home deaths to date in 2020' = Cumulative_deaths_all_cause,
         `Total number of all cause care home deaths to date per 1,000 care home beds` = Cumulative_deaths_crude_rate_per_1000_care_home_beds,
         `All cause latest week care home summary` = Deaths_label,
         `All cause cumulative care home summary` = Cumulative_deaths_label,
         `Care home deaths attributed to Covid-19 in week` = `COVID 19`,
         `Total number of care home deaths attributed to Covid-19 to date in 2020` = Cumulative_covid_deaths,
         `Proportion of care home deaths occuring in week that are attributed to Covid-19` = Proportion_covid_deaths_occuring_in_week,
         `Proportion of care home deaths to date in 2020 attributed to Covid-19` = Proportion_covid_deaths_to_date) %>% 
  left_join(Care_home_latest_covid[c('Name', 'Cumulative_deaths_crude_rate_per_1000_care_home_beds', 'Deaths_crude_rate_per_1000_care_home_beds', 'Deaths_label', 'Cumulative_deaths_label')], by = 'Name') %>% 
  rename(`Covid-19 care home deaths in week per 1,000 care home beds` = Deaths_crude_rate_per_1000_care_home_beds,
         `Total number of care home deaths attributed to Covid-19 to date per 1,000 care home beds` = Cumulative_deaths_crude_rate_per_1000_care_home_beds,
         `Covid-19 latest week care home summary` = Deaths_label,
         `Covid-19 cumulative care home summary` = Cumulative_deaths_label) %>% 
  select(Name,Week_number,Week_ending, `All cause care home deaths in week`, `All cause care home deaths in week per 1,000 care home beds`, `All cause latest week care home summary`, `Total number of all cause care home deaths to date in 2020`, `Total number of all cause care home deaths to date per 1,000 care home beds`, `All cause cumulative care home summary`, `Care home deaths attributed to Covid-19 in week`, `Covid-19 care home deaths in week per 1,000 care home beds`, `Total number of care home deaths attributed to Covid-19 to date in 2020`, `Total number of care home deaths attributed to Covid-19 to date per 1,000 care home beds`, `Covid-19 latest week care home summary`, `Covid-19 cumulative care home summary`, `Proportion of care home deaths occuring in week that are attributed to Covid-19`, `Proportion of care home deaths to date in 2020 attributed to Covid-19`)

Covid_care_home_burden_all_age_latest_SE <- Covid_burden_latest_care_homes %>% 
  filter(Name %in%  c('Brighton and Hove', 'Bracknell Forest', 'Buckinghamshire', 'East Sussex', 'Hampshire', 'Isle of Wight', 'Kent', 'Medway', 'Milton Keynes', 'Oxfordshire', 'Portsmouth', 'Reading', 'Slough', 'Southampton', 'Surrey', 'West Berkshire', 'West Sussex', 'Windsor and Maidenhead', 'Wokingham', 'Sussex areas combined', 'South East', 'England')) %>% 
  mutate(Name = ifelse(Name == 'South East', 'South East region', Name))

SE_area_code_names <- area_code_names %>% 
  filter(Name %in% c('Brighton and Hove', 'Bracknell Forest', 'Buckinghamshire', 'East Sussex', 'Hampshire', 'Isle of Wight', 'Kent', 'Medway', 'Milton Keynes', 'Oxfordshire', 'Portsmouth', 'Reading', 'Slough', 'Southampton', 'Surrey', 'West Berkshire', 'West Sussex', 'Windsor and Maidenhead', 'Wokingham'))

care_home_ons_cipfa <- nn_area %>% 
  left_join(Covid_burden_latest_care_homes, by = c('Nearest_neighbour' = 'Name')) %>% 
  group_by(Name) %>% 
  mutate(`Rank of cumulative all cause care home deaths crude rate among CIPFA neighbours` = ordinal(rank(-`Total number of all cause care home deaths to date per 1,000 care home beds`))) %>%
  mutate(`Rank of latest Covid-19 care home deaths crude rate among CIPFA neighbours per 1,000 care home beds` = ordinal(rank(-`Covid-19 care home deaths in week per 1,000 care home beds`))) %>%
  mutate(`Rank of cumulative Covid-19 care home deaths crude rate among CIPFA neighbours per 1,000 care home beds` = ordinal(rank(-`Total number of care home deaths attributed to Covid-19 to date per 1,000 care home beds`))) %>%
  mutate(`Rank of proportion of care home deaths to date attributed to Covid-19 among CIPFA neighbours` = ordinal(rank(-`Proportion of care home deaths to date in 2020 attributed to Covid-19`))) %>% 
  filter(Name == Nearest_neighbour)

care_home_ons_cipfa %>% 
  write.csv(., paste0(github_repo_dir, '/care_home_ons_cipfa.csv'), row.names = FALSE, na = '')

# exporting ONS ch data

Care_home_deaths %>% 
  write.csv(., paste0(github_repo_dir, '/Care_home_death_occurrences_ONS_weekly.csv'), row.names = FALSE, na = '') 

# CQC mortality in care homes ####

# Note: The notifications only include those received by 5pm on 22nd May.

download.file('https://www.ons.gov.uk/file?uri=%2fpeoplepopulationandcommunity%2fbirthsdeathsandmarriages%2fdeaths%2fdatasets%2fnumberofdeathsincarehomesnotifiedtothecarequalitycommissionengland%2f2020/20200531officialsensitivecoviddeathnotificationsdata20200529.xlsx', paste0(github_repo_dir, '/cqc_mortality_care_homes.xlsx'), mode = 'wb')

cqc_care_home_daily_all_cause <- read_excel(paste0(github_repo_dir, '/cqc_mortality_care_homes.xlsx'), sheet = 'Table 3', skip = 2) %>% 
  rename(Name = ...1) %>% 
  gather(key = "Date", value = "All cause", 2:ncol(.)) %>% 
  mutate(Date = as.Date(as.numeric(Date), origin = "1899-12-30")) 

cqc_care_home_daily_covid <- read_excel(paste0(github_repo_dir, '/cqc_mortality_care_homes.xlsx'), sheet = 'Table 2', skip = 2) %>% 
  rename(Name = ...1) %>% 
  gather(key = "Date", value = "Covid-19 Deaths", 2:ncol(.)) %>% 
  mutate(Date = as.Date(as.numeric(Date), origin = "1899-12-30")) 

cqc_care_home_daily_deaths <- cqc_care_home_daily_all_cause %>% 
  left_join(cqc_care_home_daily_covid, by = c('Name', 'Date'))

cqc_care_home_daily_deaths %>% 
  write.csv(., paste0(github_repo_dir, '/cqc_care_home_daily_deaths.csv'), row.names = FALSE, na = '')

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

# Hospital provider trusts do not have geographically defined boundaries for their population nor do they have complete lists of registered patients. However, modelled estimates of the catchment populations for hospital provider trusts in England are provided by Public Health England (PHE). These experimental statistics estimates the number of people who are using each hospital trust or have the potential to do so. Individual acute trusts sometimes use varying methods to define the population they serve, such as patient flow, CCG derived or travel time based estimates. PHE published modelled estimates use the patient flow method.

if(!file.exists(paste0(github_repo_dir, '/trust_catchment_population_estimates.csv'))){
  
  catchment_pop <- read_excel(paste0(github_repo_dir, "/2020 Trust Catchment Populations Worksheet.xlsx"), sheet = "Trust Analysis", col_types = c("text", "text", "text", "text", "text", "numeric", "text", "text", "numeric", "numeric", "numeric", "numeric","numeric")) %>% 
    group_by(CatchmentYear, TrustCode, TrustName, AdmissionType) %>% 
    summarise(Catchment = sum(Catchment, na.rm = TRUE)) %>% 
    filter(CatchmentYear == 2018) %>% 
    filter(AdmissionType == 'Emergency') %>% 
    rename(Emergency_catchment_pop_2018 = Catchment) %>% 
    rename(Code = TrustCode) %>% 
    ungroup() %>% 
    select(Code, Emergency_catchment_pop_2018)
  
  catchment_pop %>% 
    write.csv(., paste0(github_repo_dir, '/trust_catchment_population_estimates.csv'), row.names = FALSE)
}

catchment_pop <- read_csv(paste0(github_repo_dir, '/trust_catchment_population_estimates.csv')) %>% 
  left_join(etr, by = 'Code')

# This should download the data for today (it will only work after the new file is published at 5pm though), shame on those who release new filenames each day and do not allow for a static url

# This is a bit of a hack, it says download today. If you run the script before a new file is uploaded it will obviously fail. So at the very least, you'll get the updated file from yesterday 
# download.file(paste0('https://www.england.nhs.uk/statistics/wp-content/uploads/sites/2/2020/',format(Sys.Date(), '%m'),'/COVID-19-total-announced-deaths-',format(Sys.Date(), '%d-%B-%Y'),'.xlsx'), paste0(github_repo_dir, '/refreshed_daily_deaths_trust.xlsx'), mode = 'wb')
# 
# # if the downlaod does fail, it wipes out the old one, which we can use to our advantage
# if(!file.exists(paste0(github_repo_dir, '/refreshed_daily_deaths_trust.xlsx'))){
# download.file(paste0('https://www.england.nhs.uk/statistics/wp-content/uploads/sites/2/2020/',format(Sys.Date()-1, '%m'),'/COVID-19-total-announced-deaths-',format(Sys.Date()-1, '%d-%B-%Y'),'.xlsx'), paste0(github_repo_dir, '/refreshed_daily_deaths_trust.xlsx'), mode = 'wb')
# }

# find urls on a page
scraped_urls <- read_html('https://www.england.nhs.uk/statistics/statistical-work-areas/covid-19-daily-deaths/') %>%
  html_nodes("a") %>%
  html_attr("href")

# search for our specific url (the filename always contains this "total" string). This will return all strings
url <- grep('COVID-19-total-announced-deaths', scraped_urls, value = T)

#2nd query inverts findings to ignore new weekly file and only take summary
query_url2 <- "weekly-table"
url2 <- grep(query_url2, url, value = T, invert = T)

download.file(url2, paste0(github_repo_dir, '/refreshed_daily_deaths_trust.xlsx'), mode = 'wb')

local_trust_codes <- c('RXC', 'RTP', 'RDR','RXH', 'RYR')

daily_deaths_trust <- read_excel(paste0(github_repo_dir, "/refreshed_daily_deaths_trust.xlsx"), sheet = 'Tab4 Deaths by trust', skip = 15) %>% 
  select(-c(...2, Total)) %>% 
  filter(!is.na(Code)) %>% 
  mutate(Name = capwords(Name, strict = TRUE)) %>% 
  mutate(Name = gsub('Nhs', 'NHS', Name)) %>% 
  mutate(Name = gsub(' And ', ' and ', Name)) %>% 
  mutate(Name = gsub('Cic', 'CIC', Name)) %>% 
  rename(`43890` =  `Up to 01-Mar-20`) %>% 
  gather(key = "Date", value = "Deaths", 4:ncol(.)) %>% 
  mutate(Date = as.Date(as.numeric(Date), origin = "1899-12-30")) %>% 
  filter(!is.na(Date)) %>% 
  rename(Trust = Name) %>% 
  group_by(Trust) %>% 
  arrange(Date) %>% 
  mutate(Cumulative_deaths = cumsum(Deaths)) %>% 
  left_join(catchment_pop, by = 'Code') %>% 
  mutate(`Crude rate deaths per 100,000 emergency catchment population` = ifelse(is.na(Cumulative_deaths), NA, pois.exact(Cumulative_deaths, Emergency_catchment_pop_2018)[[3]]*100000)) %>% 
  mutate(Cumulative_deaths_crude_rate_lci = ifelse(is.na(Cumulative_deaths), NA, pois.exact(Cumulative_deaths, Emergency_catchment_pop_2018)[[4]]*100000)) %>% 
  mutate(Cumulative_deaths_crude_rate_uci = ifelse(is.na(Cumulative_deaths), NA, pois.exact(Cumulative_deaths, Emergency_catchment_pop_2018)[[5]]*100000)) %>% 
  mutate(`Cumulative rate summary` = ifelse(is.na(`Crude rate deaths per 100,000 emergency catchment population`), NA, paste0(format(Cumulative_deaths, big.mark = ',', trim = TRUE), ' deaths (', round(`Crude rate deaths per 100,000 emergency catchment population`,0), ' per 100,000, 95% CI: ', round(Cumulative_deaths_crude_rate_lci,0), '-', round(Cumulative_deaths_crude_rate_uci,0), ')'))) %>% 
  ungroup()
  
latest_reported_daily_trust_deaths <- daily_deaths_trust %>% 
  filter(Date == max(Date)) %>% 
  filter(Code %in% c(local_trust_codes, '-')) %>%
  select(Trust, Cumulative_deaths, `Crude rate deaths per 100,000 emergency catchment population`, `Cumulative rate summary`)

latest_complete_deaths_trust_date <- max(daily_deaths_trust$Date)-5

daily_trust_deaths_table <- daily_deaths_trust %>% 
  filter(Date == latest_complete_deaths_trust_date) %>% 
  rename(`Deaths reported on most recent complete day` = Deaths) %>% 
  filter(Code %in% c(local_trust_codes, '-')) %>%
  select(Code, Trust, Date, `Deaths reported on most recent complete day`) %>% 
  left_join(latest_reported_daily_trust_deaths, by = 'Trust')

meta_trust_deaths <- read_excel(paste0(github_repo_dir, "/refreshed_daily_deaths_trust.xlsx"), sheet = 'Tab4 Deaths by trust', skip = 2, col_names = FALSE, n_max = 5) %>% 
  rename(Item = ...1,
         Description = ...2) %>%
  mutate(Description = ifelse(Item == 'Published:', as.character(format(as.Date(as.numeric(Description), origin = "1899-12-30"), '%d-%b-%Y')), Description))

meta_trust_deaths %>% 
  filter(Item == 'Period:') %>% 
  select(Description)

daily_deaths_trust %>% 
  filter(Code %in% c(local_trust_codes, '-')) %>%
  write.csv(., paste0(github_repo_dir, '/daily_trust_deaths.csv'), row.names = FALSE, na = '')

daily_trust_deaths_table %>% 
  write.csv(., paste0(github_repo_dir, '/daily_trust_deaths_table.csv'), row.names = FALSE, na = '')

meta_trust_deaths %>% 
  write.csv(., paste0(github_repo_dir, '/meta_trust_deaths.csv'), row.names = FALSE, na = '')

daily_deaths_trust %>% 
  filter(`NHS England Region` == 'South East') %>% 
  select(Trust, Date, Deaths, Cumulative_deaths, `Cumulative rate summary`) %>% 
  arrange(Date) %>% 
  mutate(Date = format(Date, '%d %B')) %>% 
  mutate(Date = factor(Date, levels = unique(Date))) %>% 
  toJSON() %>% 
  write_lines(paste0(github_repo_dir, '/SE_hospital_trust_daily_mortality.json'))

daily_deaths_trust %>% 
  filter(Code %in% c(local_trust_codes)) %>% 
  filter(Date == max(Date)) %>% 
  select(Trust, Date, Cumulative_deaths) %>% 
  group_by(Date) %>% 
  mutate(Cumulative_sussex = ifelse(Trust == 'Surrey and Sussex Healthcare NHS Trust', Cumulative_deaths / 2, Cumulative_deaths)) %>% 
  summarise(Cumulative_sussex = round(sum(Cumulative_sussex),0)) %>%
  mutate(Date = format(Date, '%d %B')) %>% 
  toJSON() %>% 
  write_lines(paste0(github_repo_dir, '/sussex_approximate_latest_hospital_deaths.json'))
  
# Excess mortality ####

# excess_mortality <- read_excel(paste0(github_repo_dir, '/ons_mortality.xlsx'), sheet = 'Occurrences - All data', skip = 2) 

