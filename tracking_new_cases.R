library(easypackages)

libraries(c("readxl", "readr", "plyr", "dplyr", "ggplot2", "tidyverse", "reshape2", "scales", 'jsonlite', 'zoo', 'stats'))

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



#download.file('https://fingertips.phe.org.uk/documents/Historic%20COVID-19%20Dashboard%20Data.xlsx', paste0(github_repo_dir, '/refreshed_daily_cases.xlsx'), mode = 'wb')

# On 14th April, the way in which PHE share data on cases changed. Data were presented daily on the number of confirmed cases reported to PHE on a particular day. As testing takes time, and as capacity is being increased, there can be some delay in returning results. An example is a patient having a swab taken on 1st April, with results returned on 5th April and reported to PHE. In such a case, the confirmed case will be attributed to 5th April even though the patient was infected at least four days earlier. The new method of reporting shows confirmed cases by the date at which the specemin for testing was taken. Duplicate tests for the same person are removed. The first positive specimen date is used as the specimen date for that person.

# Whilst this method more accurately tracks the dates at which people are known to be infected, it may look like the most recent days' cases (which are still being reported daily) are sloping off (getting smaller). This is not the case, it is just that the most recent testing results may take several days to be reported. PHE suggest that data for the most recent five days should be treated with caution and considered 'incomplete'.

# Prior to April 14th, the earliest reporting date was March 9th. In some areas, there were already cases, and in other areas there were none. Data are now back dated and revised such that every lab-confirmed case is attributed to the date at which the specemin was taken, which means the time series starts at different dates for different areas. The first specimins for a confirmed Covid-19 infection were taken on Janurary 30th 2020.

daily_cases_raw <- read_csv('https://coronavirus.data.gov.uk/downloads/csv/coronavirus-cases_latest.csv') %>% 
  rename(Name = `Area name`) %>% 
  rename(Code = `Area code`) %>% 
  rename(Date = `Specimen date`) %>% 
  rename(New_cases = `Daily lab-confirmed cases`) %>% 
  rename(Cumulative_cases = `Cumulative lab-confirmed cases`) %>% 
  arrange(Name, Date) 

# Create a subset for Sussex
sussex_daily_cases <- daily_cases_raw %>% 
  filter(Name %in% c('Brighton and Hove', 'East Sussex', 'West Sussex')) %>%
  group_by(Date, `Area type`) %>% 
  summarise(New_cases = sum(New_cases, na.rm = TRUE)) %>%
  ungroup() %>% 
  mutate(Cumulative_cases = cumsum(New_cases)) %>% # We have to rebuild this because in some cases there are no rows for an individual area if no new cases. 
  mutate(Name = 'Sussex areas combined') %>% 
  mutate(`Area type` = 'Sussex areas combined') %>% 
  mutate(Code = '-')

# Combine raw data with Sussex data
daily_cases <- daily_cases_raw %>% 
  bind_rows(sussex_daily_cases)

rm(daily_cases_raw, sussex_daily_cases, sussex_pop)

# Now have a date of specimin for each area. If no specimins are taken on a day, there is no row for it, and it would be missing data. Indeed, the only zeros are on the latest day. We need to therefore backfill and say if no date exists where it should, then add it, with the cumulative total and zero for new cases.

# One way to do this is to create a new dataframe with a row for each area and date, and left join the daily_cases data to it.
first_date <- min(daily_cases$Date)
last_date <- max(daily_cases$Date)

Areas = daily_cases %>% 
  select(Name, Code, `Area type`) %>% 
  unique()
  
Dates = seq.Date(first_date, last_date, by = '1 day')

daily_cases_reworked <- data.frame(Name = rep(Areas$Name, length(Dates)), Code = rep(Areas$Code, length(Dates)), `Area type` = rep(Areas$`Area type`, length(Dates)), check.names = FALSE) %>% 
  arrange(Name) %>% 
  group_by(Name) %>% 
  mutate(Date = seq.Date(first_date, last_date, by = '1 day')) %>% 
  left_join(daily_cases, by = c('Name', 'Code', 'Area type', 'Date')) %>% 
  mutate(New_cases = ifelse(is.na(New_cases), 0, New_cases)) %>% 
  mutate(New_cumulative = cumsum(New_cases)) %>% 
  filter(!is.na(Cumulative_cases)) %>% 
  mutate(Calculated_same_as_original = ifelse(Cumulative_cases == New_cumulative, 'Yaas', 'Negative'))

daily_cases_reworked %>% 
  filter(Calculated_same_as_original == 'Negative') %>% 
  select(Name) %>% 
  unique()

# The problem with City of London is that there were 5 cumulative cases to start with (and not 0), we need to change that in the dataset to say if cumulative is not blank but new cases is blank, then whats going on.

# My understanding is that Hackney and City of London are reported separately now, whilst Cornwall and Isles of Scilly are combined and use Cornwall GSS code.

# I think we need to keep an eye on this and deal with any areas that are in the SE that may return issues for our work as the above has some implications for rates.

# PHE say the last five data points are incomplete (perhaps they should not publish them). Instead, we need to make sure we account for this so that it is not misinterpreted.
complete_date <- max(daily_cases_reworked$Date) - 5

daily_cases_reworked <- data.frame(Name = rep(Areas$Name, length(Dates)), Code = rep(Areas$Code, length(Dates)), `Area type` = rep(Areas$`Area type`, length(Dates)), check.names = FALSE) %>% 
  arrange(Name) %>% 
  group_by(Name) %>% 
  mutate(Date = seq.Date(first_date, last_date, by = '1 day')) %>% 
  mutate(Data_completeness = ifelse(Date >= max(Date) - 4, 'Considered incomplete', 'Complete')) %>% 
  left_join(daily_cases, by = c('Name', 'Code', 'Area type', 'Date')) %>% 
  mutate(New_cases = ifelse(is.na(New_cases), 0, New_cases)) %>% 
  rename(Original_cumulative = Cumulative_cases) %>% # We should keep the original cumulative cases for reference
  mutate(Cumulative_cases = cumsum(New_cases)) %>% # These are based on the new cases data being accurate
  mutate(Log10Cumulative_cases = log10(Cumulative_cases)) %>% # We also add log scaled cumulative cases for reporting growth
  group_by(Name) %>% 
  mutate(Three_day_average_new_cases = rollapply(New_cases, 3, mean, align = 'right', fill = NA)) %>%
  mutate(Three_day_average_cumulative_cases = rollapply(Cumulative_cases, 3, mean, align = 'right', fill = NA)) %>%
  left_join(mye_total, by = c('Code')) %>% 
  select(-c(Code, DATE_NAME)) %>% 
  mutate(Period = format(Date, '%d %B')) %>%
  mutate(Cumulative_per_100000 = (Cumulative_cases / Population) * 100000) %>% 
  mutate(New_cases_per_100000 = (New_cases / Population) * 100000) %>% 
  mutate(Case_label = paste0('The total (cumulative) number of cases reported for people with specimins taken by this date (', Period, ') was ', format(Cumulative_cases, big.mark = ',', trim = TRUE), '. A total of ', format(New_cases, big.mark = ',', trim = TRUE), ' patients who had sample specimins taken on this day (representing new cases) were confirmed to have the virus',  ifelse(Data_completeness == 'Considered incomplete', paste0('.<font color = "#bf260a"> However, these figures should be considered incomplete until at least ', format(Date + 5, '%d %B'),'.</font>'),'.'))) %>% 
  mutate(Rate_label = paste0('The total (cumulative) number of Covid-19 cases per 100,000 population reported to date (', Period, ') is <b>', format(round(Cumulative_per_100000,0), big.mark = ',', trim = TRUE), '</b> cases per 100,000 population. The new cases (swabbed n this date) represent <b>',format(round(New_cases_per_100000,0), big.mark = ',', trim = TRUE), '</b> cases per 100,000 population</p><p><i>Note: the rate per 100,000 is rounded to the nearest whole number, and sometimes this can appear as zero even when there were some cases reported.</i>')) %>% 
  mutate(Proportion_label = paste0('The new cases for patients swabbed on this day represent <b>', round((New_cases / Cumulative_cases) * 100, 1), '%</b> of the total cumulative number of Covid-19 cases reported to date (<b>', format(Cumulative_cases, big.mark = ',', trim = TRUE), '</b>).')) %>%  
  mutate(Three_day_ave_new_label = ifelse(is.na(Three_day_average_new_cases), paste0('It is not possible to calculate a three day rolling average of new cases for this date (', Period, ') because one of the values in the last three days is missing or revised.'), ifelse(Data_completeness == 'Considered incomplete', paste0('It can take around five days for results to be fully reported and data for this date (', Period, ') should be considered incomplete.', paste0('As such, the rolling average number of new cases in the last three days (<b>', format(round(Three_day_average_new_cases, 0), big.mark = ',', trim = TRUE), ' cases</b>) should be treated with caution.')), paste0('The rolling average number of new cases in the last three days is <b>', format(round(Three_day_average_new_cases, 0), big.mark = ',', trim = TRUE), '  cases</b>.')))) %>% 
  mutate(Three_day_ave_cumulative_label = ifelse(is.na(Three_day_average_cumulative_cases), paste0('It is not possible to calculate a three day rolling average of new cases for this date (', Period, ') because one of the values in the last three days is missing or revised.'), ifelse(Data_completeness == 'Considered incomplete', paste0('It can take around five days for results to be fully reported and data for this date (', Period, ') should be considered incomplete. ', paste0('As such, the rolling average number of cumulative cases in the last three days (<b>', format(round(Three_day_average_cumulative_cases, 0), big.mark = ',', trim = TRUE), ' cases</b>) should be treated with caution.')), paste0('The rolling average number of cumulative cases in the last three days is <b>', format(round(Three_day_average_cumulative_cases, 0), big.mark = ',', trim = TRUE), ' cases</b>.')))) %>%
  mutate(new_case_key = factor(ifelse(New_cases == 0, 'No new cases', ifelse(New_cases >= 1 & New_cases <= 10, '1-10 cases', ifelse(New_cases >= 11 & New_cases <= 25, '11-25 cases', ifelse(New_cases >= 26 & New_cases <= 50, '26-50 cases', ifelse(New_cases >= 51 & New_cases <= 75, '51-75 cases', ifelse(New_cases >= 76 & New_cases <= 100, '76-100 cases', ifelse(New_cases >100, 'More than 100 cases', NA))))))), levels =  c('No new cases', '1-10 cases', '11-25 cases', '26-50 cases', '51-75 cases', '76-100 cases', 'More than 100 cases'))) %>%
  mutate(new_case_per_100000_key = factor(ifelse(New_cases_per_100000 < 0, 'Data revised down', ifelse(round(New_cases_per_100000,0) == 0, 'No new cases', ifelse(round(New_cases_per_100000,0) > 0 & round(New_cases_per_100000, 0) <= 5, '1-5 new cases per 100,000', ifelse(round(New_cases_per_100000,0) >= 6 & round(New_cases_per_100000,0) <= 10, '6-10 new cases per 100,000', ifelse(round(New_cases_per_100000,0) >= 11 & round(New_cases_per_100000, 0) <= 15, '11-15 new cases per 100,000', ifelse(round(New_cases_per_100000,0) >= 16 & round(New_cases_per_100000,0) <= 20, '16-20 new cases per 100,000', ifelse(round(New_cases_per_100000,0) > 20, 'More than 20 new cases per 100,000', NA))))))), levels =  c('No new cases', '1-5 new cases per 100,000', '6-10 new cases per 100,000', '11-15 new cases per 100,000', '16-20 new cases per 100,000', 'More than 20 new cases per 100,000'))) %>% 
  ungroup() %>% 
  mutate(Name = ifelse(Name == 'South East', 'South East region', Name))
  
rm(daily_cases, mye_total, Areas, Dates, first_date)

# We need to figure out the starting case report date and what to do with data revised down.
# We could also concatenate the labels into one set for each tooltip and that way reduce the file size and repeating of text like (this is incomplete).
    
daily_cases_reworked %>% 
  filter(Date == max(Date)) %>% 
  group_by(`Area type`, Date) %>% 
  summarise(Cumulative_cases = sum(Cumulative_cases)) %>% 
  filter(`Area type` != 'Upper tier local authority') %>% 
  rename(Area = `Area type`) %>% 
  spread(value = Cumulative_cases, key = Area) %>%
  mutate(Unconfirmed = Nation - Region) %>% 
  rename(England = Nation) %>% 
  select(-Region) %>% 
  mutate(Proportion_unconfirmed = Unconfirmed / England) %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/another_covid_repo/unconfirmed_latest.json'))
  
levels(daily_cases_reworked$new_case_key) %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/another_covid_repo/daily_cases_bands.json'))

levels(daily_cases_reworked$new_case_per_100000_key) %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/another_covid_repo/daily_cases_per_100000_bands.json'))

# Days since case 1 and case x ####

# Here we find the first instance of a single case, as well as case x (10, or another number) cases.

# Not all areas will reach '10' cases exactly on a single day, so this will be the first date an area reached 10 or more cases. 

# We need to convert date into number of days since case number x.
case_x_number = 10 # This could be changed

first_case_date <- daily_cases_reworked %>% 
  group_by(Name) %>% 
  filter(Cumulative_cases >= 1) %>% 
  slice(1) %>% 
  ungroup() %>% 
  select(Name, Date) %>% 
  rename(First_case_date = Date) 

first_x_date <- daily_cases_reworked %>% 
  group_by(Name) %>% 
  filter(Cumulative_cases >= case_x_number) %>% 
  slice(1) %>% 
  ungroup() %>% 
  select(Name, Date) %>% 
  rename(First_date_x_cases = Date) 

firsts <- first_case_date %>% 
  left_join(first_x_date, by = 'Name')

rm(first_case_date, first_x_date)

daily_cases_reworked <- daily_cases_reworked %>% 
  group_by(Name) %>% 
  left_join(firsts, by = c('Name')) %>% 
  mutate(Days_since_first_case = as.numeric(difftime(Date, First_case_date, units = c("days")))) %>% # add days since start of data
  mutate(Days_since_case_x = as.numeric(difftime(Date, First_date_x_cases, units = c("days")))) %>% 
  select(-c(First_case_date, First_date_x_cases)) %>% 
  ungroup()

# So now we have a dataframe with one row per area per day from the first case in England. This includes new cases and cumulative cases, as well as rates, number of days from case 1 and case 10, as well as some labels for adding to tooltips elsewhere.

# Doubling time ####
# https://jglobalbiosecurity.com/articles/10.31646/gbio.61/
# https://blog.datawrapper.de/weekly-chart-coronavirus-doublingtimes/
# https://blogs.sas.com/content/iml/2020/04/01/estimate-doubling-time-exponential-growth.html

# We create a doubling time using the most recent 5 day period (and doubling time is recalculated every day once new data is available) 
double_time_period <- 5 # this could be 5 or 7 

# I've made an ifelse function that identifies 5 day periods for 100 days or 140 days of data if 7 day doubling time is used and this may have to change in the future.

# Importantly, given that the data has changed from reported date to specimin date, and that the last five days have been concluded as incomplete, it would not be useful to report a doubling time for this time period.

doubling_time_df <- daily_cases_reworked %>% 
  filter(Days_since_case_x >= 0) %>%
  filter(Data_completeness == 'Complete') %>% 
  group_by(Name) %>% 
  arrange(Name,Date) %>% 
  mutate(period_in_reverse = ifelse(Date > max(Date) - (double_time_period), 1, ifelse(Date > max(Date) - (double_time_period * 2), 2, ifelse(Date > max(Date) - (double_time_period * 3), 3, ifelse(Date > max(Date) - (double_time_period * 4), 4, ifelse(Date > max(Date) - (double_time_period * 5), 5, ifelse(Date > max(Date) - (double_time_period * 6), 6, ifelse(Date > max(Date) - (double_time_period * 7), 7, ifelse(Date > max(Date) - (double_time_period * 8), 8, ifelse(Date > max(Date) - (double_time_period * 9), 9, ifelse(Date > max(Date) - (double_time_period * 10), 10, ifelse(Date > max(Date) - (double_time_period * 11), 11, ifelse(Date > max(Date) - (double_time_period * 12), 12, ifelse(Date > max(Date) - (double_time_period * 13), 13, ifelse(Date > max(Date) - (double_time_period * 14), 14, ifelse(Date > max(Date) - (double_time_period * 15), 15, ifelse(Date > max(Date) - (double_time_period * 16), 16, ifelse(Date > max(Date) - (double_time_period * 17), 17, ifelse(Date > max(Date) - (double_time_period * 18), 18, ifelse(Date > max(Date) - (double_time_period * 19), 19, ifelse(Date > max(Date) - (double_time_period * 20), 20, NA))))))))))))))))))))) %>% 
  group_by(Name, period_in_reverse) %>%   
  mutate(Slope = coef(lm(Log10Cumulative_cases ~ Days_since_first_case))[2]) %>% 
  mutate(Double_time = log(2, base = 10)/coef(lm(Log10Cumulative_cases ~ Days_since_first_case))[2]) %>%
  mutate(N_days_in_doubling_period = n()) %>% 
  mutate(Double_time = ifelse(N_days_in_doubling_period != double_time_period, NA, Double_time)) %>%
  mutate(Slope = ifelse(N_days_in_doubling_period != double_time_period, NA, Slope)) %>% 
  mutate(date_range_label = paste0(ifelse(period_in_reverse == '1', paste0('most recent complete ', double_time_period, ' days ('), ifelse(period_in_reverse == '2', paste0('previous ', double_time_period, ' days ('), paste0('period ', period_in_reverse, ' ('))), format(min(Date), '%d-%B'), '-', format(max(Date), '%d-%B'), ')')) %>% 
  mutate(date_range_label = ifelse(N_days_in_doubling_period != double_time_period, NA, date_range_label)) %>% 
  mutate(short_date_label = paste0(format(min(Date), '%d-%b'), '-', format(max(Date), '%d-%b'))) %>% 
  mutate(long_date_label = paste0(format(min(Date), '%d-%B'), ' and ', format(max(Date), '%d-%B'))) %>% 
  mutate(date_range_label = ifelse(N_days_in_doubling_period != double_time_period, NA, date_range_label)) %>% 
  mutate(short_date_label = ifelse(N_days_in_doubling_period != double_time_period, NA, short_date_label)) %>% 
  mutate(long_date_label = ifelse(N_days_in_doubling_period != double_time_period, NA, long_date_label)) %>% 
  ungroup() 

# We might use doubling time in the last five days and in the previous five days in the table.

# This exports a json data object with the date labels for doubling time periods. We can use this object in the javascript file to update labels.
doubling_time_df %>% 
  select(period_in_reverse, date_range_label, short_date_label, long_date_label) %>% 
  unique() %>% 
  filter(!is.na(date_range_label)) %>% 
  arrange(period_in_reverse) %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/another_covid_repo/date_range_doubling.json'))

doubling_time_df %>% 
  select(Name, period_in_reverse, long_date_label, Double_time) %>% 
  filter(!is.na(long_date_label)) %>% 
  unique() %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/another_covid_repo/double_time_area.json'))

# This transposes the period_in_reverse to show change over time (1 is last week)
doubling_time_df_summary <- doubling_time_df %>% 
  select(Name, period_in_reverse, Double_time) %>% 
  unique() %>% 
  spread(period_in_reverse, Double_time) %>% 
  select(Name, `1`,`2`) %>% 
  rename(Latest_doubling_time = `1`,
          Previous_doubling_time = `2`)

# Local areas ####
daily_cases_local <- daily_cases_reworked %>% 
  filter(Name %in% c('Brighton and Hove', 'Bracknell Forest', 'Buckinghamshire', 'East Sussex', 'Hampshire', 'Isle of Wight', 'Kent', 'Medway', 'Milton Keynes', 'Oxfordshire', 'Portsmouth', 'Reading', 'Slough', 'Southampton', 'Surrey', 'West Berkshire', 'West Sussex', 'Windsor and Maidenhead', 'Wokingham', 'Sussex areas combined', 'South East region', 'England')) 

local_cases_summary_latest <- daily_cases_local %>% 
  filter(Date == max(Date)) %>% 
  select(Name, Cumulative_cases, Cumulative_per_100000, Three_day_average_cumulative_cases) %>% 
  rename(`Total confirmed cases so far` = Cumulative_cases,
         `Total cases per 100,000 population` = Cumulative_per_100000,
         `Three day average cumulative cases` = Three_day_average_cumulative_cases)
  
local_cases_summary_complete <- daily_cases_local %>% 
  filter(Date == complete_date) %>% 
  select(Name, New_cases, New_cases_per_100000, Three_day_average_new_cases) %>% 
  rename(`Confirmed cases swabbed on most recent complete day` = New_cases,
         `Confirmed cases swabbed per 100,000 population on most recent complete day` = New_cases_per_100000,
         `Average number of confirmed cases tested in past three complete days` = Three_day_average_new_cases) 

local_cases_summary <- local_cases_summary_latest %>% 
  left_join(local_cases_summary_complete, by = 'Name') %>% 
  left_join(doubling_time_df_summary, by = 'Name') %>% 
  arrange(-`Total confirmed cases so far`) %>% 
  mutate(Name = factor(Name, levels = unique(Name))) %>% 
  mutate(summary_label_doubling = paste0('In the most recent ', double_time_period, ' day time period, cases were set to double in ', round(Latest_doubling_time, 1), ' days. Compared to the previous ', double_time_period, ' days, the doubling time has ', ifelse(Latest_doubling_time > Previous_doubling_time, paste0(' increased from ', round(Previous_doubling_time, 1), ' days (meaning a slowing down of new cases).'), paste0(' decreased from ', round(Previous_doubling_time, 1), ' days (meaning a speeding up of new cases.')), '<b> It should be noted that in some areas, particularly with relatively low numbers of cases, there can be a large amount of fluctuation which can have an impact on doubling time.</b>')) %>% 
  mutate(Growth_rate_change = ifelse(Latest_doubling_time > Previous_doubling_time, 'Slowing', ifelse(Latest_doubling_time < Previous_doubling_time, 'Speeding up', NA)))

rm(local_cases_summary_complete, local_cases_summary_latest)

complete_period <- format(complete_date, '%d %B')

daily_cases_local <- daily_cases_local %>% 
  select(Name, Date, Period, Data_completeness, Cumulative_cases, Three_day_average_cumulative_cases, Cumulative_per_100000, Log10Cumulative_cases, New_cases, New_cases_per_100000, Case_label, Rate_label, Proportion_label, Three_day_ave_cumulative_label, Three_day_ave_new_label, new_case_key, new_case_per_100000_key, Days_since_case_x, Days_since_first_case) %>% 
  left_join(doubling_time_df[c('Name', 'Date', 'period_in_reverse', 'Double_time', 'date_range_label')], by = c('Name', 'Date')) %>% 
  mutate(double_time_label_1 = paste0(ifelse(Days_since_case_x < 0, '', ifelse(Days_since_case_x == 0, paste0('This is the day that the total (cumulative) cases was ', case_x_number, ' or more.'), paste0('This is day ', Days_since_case_x, ' since the number of diagnosed cases reached ', case_x_number, ' or more.'))), paste0(' The total (cumulative) number of cases on this day was ', format(Cumulative_cases, big.mark = ',', trim = TRUE)))) %>% 
  # mutate(double_time_label_1 = ifelse(Days_since_case_x < 0, NA, double_time_label_1)) %>% 
  mutate(double_time_label_2 = paste0('The doubling time is calculated using data for every ', double_time_period, ' day period starting from the latest available complete date (', complete_period ,') back to the date on which the first confirmed patient was swabbed for testing. ', ifelse(is.na(date_range_label), 'Although there are data for this day, there are not enough data points to calculate a doubling time.', ifelse(period_in_reverse == 1, paste0('This day is in the ', date_range_label, ' time period. At the start of this period, it was estimated that cases could potentially double in ', round(Double_time, 1), ' days.'), ifelse(period_in_reverse == 2, paste0('This day is in the ', date_range_label, ' time period. At the start of this period, it was estimated that cases could potentially double in ', round(Double_time, 1), ' days.'), paste0('This day is in ', date_range_label, '. At the start of this period, it was estimated that cases could potentially double in ', round(Double_time, 1), ' days.')))))) %>% 
  mutate(Name = factor(Name, levels = levels(local_cases_summary$Name))) %>% 
  arrange(Name)

rm(firsts, doubling_time_df, doubling_time_df_summary, daily_cases_reworked)

local_cases_summary %>%
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/another_covid_repo/se_case_summary.json'))

# This is the next point in our data series
predicted_double_time_visualised <- daily_cases_local %>% 
  select(Name, Date, Cumulative_cases, Data_completeness, Double_time) %>% 
  group_by(Name) %>% 
  filter(Data_completeness == 'Complete') %>% 
  filter(Date == max(Date)) %>% 
  mutate(Date = Date + Double_time) %>% 
  mutate(Cumulative_cases = Cumulative_cases * 2) %>% 
  mutate(Data_type = 'Predicted') %>% 
  select(Name, Date, Cumulative_cases, Data_type)

daily_cases_local %>% 
  mutate(Date_label = format(Date, '%a %d %B')) %>% 
  select(-Log10Cumulative_cases) %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/another_covid_repo/se_daily_cases.json'))

daily_cases_local %>% 
  filter(Data_completeness == 'Complete') %>% 
  filter(Date == max(Date)) %>% 
  mutate(Data_type = 'Recorded') %>% 
  bind_rows(predicted_double_time_visualised) %>%
  mutate(Period = format(Date, '%d %B')) %>%
  select(Name, Date, Period, Data_type, Cumulative_cases) %>%
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/another_covid_repo/se_daily_cases_doubling_shown.json'))

daily_cases_local %>% 
  filter(Date == min(Date) | Date == max(Date)) %>% 
  select(Date) %>% 
  unique() %>% 
  add_row(Date = complete_date) %>% 
  add_row(Date = complete_date +1) %>% 
  mutate(Date_label = format(Date, '%a %d %B')) %>% 
  arrange(Date) %>% 
  add_column(Order = c('First', 'Complete', 'First_incomplete', 'Last')) %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/another_covid_repo/range_dates.json'))

daily_cases_local <- daily_cases_local%>% 
  mutate(highlight = ifelse(Name %in% c('West Sussex', 'Brighton and Hove', 'East Sussex'), 'bold', 'plain'))

ggplot(daily_cases_local, aes(x = Date,
                y = Name,
                fill = new_case_per_100000_key)) +
  scale_fill_manual(values = c('#ffffb2', '#fed976', '#feb24c', '#fd8d3c', '#f03b20', '#bd0026'),
                    name = 'Tile colour\nkey') +
  geom_tile(colour = "#ffffff") +
  labs(x = NULL,
       y = NULL) +
  scale_x_date(date_labels = "%b %d",
               date_breaks = '1 week',
               limits = c(min(daily_cases_local$Date), max(daily_cases_local$Date)),
               expand = c(0,0.01)) +
  theme(axis.text.x = element_text(angle = 0, hjust = 0),
        legend.position = "bottom",
        legend.text = element_text(colour = "#323232", size = 8),
        panel.background = element_rect(fill = "white"),
        plot.title = element_text(colour = "#000000", face = "bold", size = 11, vjust = 1),
        axis.text.y = element_text(colour = "#323232", face = daily_cases_local$highlight, size = 8),
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

# NHS 111 symptom data ####

# Many caveats around this, not counts of people, people might not use this or might use it multiple times over the course of their symptoms (and maybe not at the start of their symptoms).

# https://digital.nhs.uk/data-and-information/publications/statistical/mi-potential-covid-19-symptoms-reported-through-nhs-pathways-and-111-online/latest

# Might be useful to have a cumulative count of number of people using the system
# West Sussex CCG has 390 triages per 100,000, whilst cases are around 26 diagnosed cases per 100,000. YOU ARE COMPARING SMALL APPLES AND REALLY RIPE CRAB APPLES

# People are encouraged NOT to call NHS 111 to report Covid-19 symptoms unless they are worried but are asked to complete an NHS 111 online triage assessment.

# nhs_111_pathways <- read_csv('https://files.digital.nhs.uk/8E/AE4094/NHS%20Pathways%20Covid-19%20data%202020-04-02.csv')

# nhs_111_online <- read_csv('https://files.digital.nhs.uk/9D/E01A56/111%20Online%20Covid-19%20data_2020-04-02.csv')

# nhs_111_online %>% 
  # filter(journeydate == '31/03/2020') %>% 
  # filter(ccgname %in% c('NHS Coastal West Sussex CCG', 'NHS Crawley CCG', 'NHS Horsham and Mid Sussex CCG')) %>% 
  # summarise(Total = sum(Total, na.rm = TRUE))

# Google mobility data ####

# mobility <- read_csv('https://www.gstatic.com/covid19/mobility/Global_Mobility_Report.csv') %>% 
  # filter(country_region == 'United Kingdom') %>% 
  # filter(sub_region_1 %in% local_cases_summary$Name) %>% 
  # rename(Area = sub_region_1) %>% 
  # select(-sub_region_2)

# setdiff(local_cases_summary$Name, unique(mobility$sub_region_1))

# These reports show how visits and length of stay at different places change compared to a baseline. We calculate these changes using the same kind of aggregated and anonymized data used to show popular times for places in Google Maps.
# Changes for each day are compared to a baseline value for that day of the week:
  # ● The baseline is the median value, for the corresponding day of the week, during the 5- week period Jan 3–Feb 6, 2020.
# ● The reports show trends over several weeks with the most recent data representing approximately 2-3 days ago—this is how long it takes to produce the reports.

