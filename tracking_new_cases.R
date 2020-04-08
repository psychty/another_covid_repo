
library(easypackages)

libraries(c("readxl", "readr", "plyr", "dplyr", "ggplot2", "png", "tidyverse", "reshape2", "scales", "viridis", "rgdal", "officer", "flextable", "tmaptools", "lemon", "fingertipsR", "PHEindicatormethods", 'jsonlite', 'readODS', 'zoo', 'stats'))

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

mye_total <- read_csv('http://www.nomisweb.co.uk/api/v01/dataset/NM_2002_1.data.csv?geography=1941962753...1941962984,2092957699&date=latest&gender=0&c_age=200&measures=20100&select=date_name,geography_name,geography_code,obs_value') %>% 
  rename(Population = OBS_VALUE,
         Code = GEOGRAPHY_CODE,
         Name = GEOGRAPHY_NAME) %>% 
  select(-Name)

download.file('https://fingertips.phe.org.uk/documents/Historic%20COVID-19%20Dashboard%20Data.xlsx', paste0(github_repo_dir, '/refreshed_daily_cases.xlsx'), mode = 'wb')

daily_cases <- read_excel(paste0(github_repo_dir, '/refreshed_daily_cases.xlsx'),sheet = "UTLAs", skip = 6) %>% 
  gather(key = "Date", value = "Cumulative_cases", 3:ncol(.)) %>% 
  rename(Name = `Area Name`) %>% 
  rename(Code = `Area Code`) %>% 
  mutate(Name = ifelse(is.na(Name), 'Unconfirmed', Name)) %>% 
  mutate(Date = as.Date(as.numeric(Date), origin = "1899-12-30")) %>% 
  arrange(Name, Date) %>% 
  group_by(Name) %>% 
  mutate(New_cases = Cumulative_cases - lag(Cumulative_cases)) %>% 
  mutate(New_cases_revised = ifelse(New_cases < 0, NA, New_cases)) %>% 
  mutate(rule_2 = rollapply(New_cases_revised, 3, function(x)if(any(is.na(x))) 'some missing' else 'all there', align = 'right', partial = TRUE)) %>% 
  mutate(Three_day_average_new_cases = ifelse(rule_2 == 'some missing', NA, rollapply(New_cases, 3, mean, align = 'right', fill=NA))) %>%
  select(-c(New_cases_revised, rule_2)) %>% 
  ungroup() %>% 
  # filter(Name != 'Unconfirmed') %>% 
  left_join(mye_total, by = c('Code')) %>% 
  select(-c(Code, DATE_NAME)) %>% 
  mutate(Period = format(Date, '%d %B')) %>% 
  mutate(Cumulative_per_100000 = (Cumulative_cases / Population) * 100000) %>% 
  mutate(New_cases_per_100000 = (New_cases / Population) * 100000) %>% 
  mutate(new_case_key = factor(ifelse(Date == min(Date), 'Starting cases', ifelse(New_cases < 0, 'Data revised down', ifelse(New_cases == 0, 'No new cases', ifelse(New_cases >= 1 & New_cases <= 10, '1-10 cases', ifelse(New_cases >= 11 & New_cases <= 25, '11-25 cases', ifelse(New_cases >= 26 & New_cases <= 50, '26-50 cases', ifelse(New_cases >= 51 & New_cases <= 75, '51-75 cases', ifelse(New_cases > 75, 'More than 75 cases', NA)))))))), levels =  c('Starting cases', 'Data revised down', 'No new cases', '1-10 cases', '11-25 cases', '26-50 cases', '51-75 cases', 'More than 75 cases'))) %>% 
  mutate(new_case_per_100000_key = factor(ifelse(Date == min(Date), 'Starting cases', ifelse(New_cases_per_100000 < 0, 'Data revised down', ifelse(round(New_cases_per_100000,0) == 0, 'No new cases', ifelse(round(New_cases_per_100000,0) > 0 & round(New_cases_per_100000, 0) <= 5, '1-5 new cases per 100,000', ifelse(round(New_cases_per_100000,0) >= 6 & round(New_cases_per_100000,0) <= 10, '6-10 new cases per 100,000', ifelse(round(New_cases_per_100000,0) >= 11 & round(New_cases_per_100000, 0) <= 15, '11-15 new cases per 100,000', ifelse(round(New_cases_per_100000,0) >= 16 & round(New_cases_per_100000,0) <= 20, '16-20 new cases per 100,000', ifelse(round(New_cases_per_100000,0) > 20, 'More than 20 new cases per 100,000', NA)))))))), levels =  c('Starting cases', 'Data revised down', 'No new cases', '1-5 new cases per 100,000', '6-10 new cases per 100,000', '11-15 new cases per 100,000', '16-20 new cases per 100,000', 'More than 20 new cases per 100,000'))) %>% 
  mutate(label_1 = ifelse(new_case_key == 'Starting cases', paste0('This is the first day of recording cases at UTLA level. On the 9th March there ', ifelse(Cumulative_cases == 0, ' were no cases', ifelse(Cumulative_cases == 1, ' was one Covid-19 case ', Cumulative_cases)), ' reported in ', Name, '.'), ifelse(new_case_key == 'Data revised down', paste0("The cumulative number of cases was revised on this day (", Period, ") which meant the number of new cases was negative, these have been reset to zero, with tomorrow's new cases calculated based on the revised cumulative value."), paste0('The number of new cases reported in the previous 24 hours was ', New_cases, '.')))) %>% 
  mutate(label_2 = ifelse(new_case_key %in% c('Starting cases', 'Data revised down'), paste0('The total (cumulative) number of COVID-19 cases reported to date (', Period, ') is <b>', format(Cumulative_cases, big.mark = ',', trim = TRUE), '</b>. This is <b>', round(Cumulative_per_100000,0), '</b> cases per 100,000 population.</p><p><i>Note: the rate per 100,000 is rounded to the nearest whole number, and sometimes this can appear as zero even when there were some cases reported.</i>'), paste0('The new cases reported on this day represent <b>', round((New_cases / Cumulative_cases) * 100, 1), '%</b> of the total cumulative number of COVID-19 cases reported to date (<b>', format(Cumulative_cases, big.mark = ',', trim = TRUE), '</b>). The current cumulative total per 100,000 population is <b>', round(Cumulative_per_100000,0), '</b>.</p><p><i>Note: the rate per 100,000 is rounded to the nearest whole number, and sometimes this can appear as zero even when there were some cases reported.</i>')))  %>% 
  mutate(label_3 = ifelse(is.na(Three_day_average_new_cases), paste0('It is not possible to calculate a three day rolling average for this date (', Period, ') because one of the values in the last three days is missing or revised.'), paste0('The rolling average number of new cases in the last three days is <b>', round(Three_day_average_new_cases, 0), '</b> cases. <i>Note: the rolling average has been rounded to the nearest whole number.</i>'))) 

daily_cases %>% 
  filter(Name %in% c('Unconfirmed', 'England')) %>% 
  filter(Date == max(Date)) %>% 
  select(Date, Name, Cumulative_cases) %>% 
  spread(key = Name, value = Cumulative_cases) %>% 
  mutate(Proportion_unconfirmed = Unconfirmed / England) %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/another_covid_repo/unconfirmed_latest.json'))

levels(daily_cases$new_case_key) %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/another_covid_repo/daily_cases_bands.json'))

levels(daily_cases$new_case_per_100000_key) %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/another_covid_repo/daily_cases_per_100000_bands.json'))

sussex_daily_cases <- daily_cases %>% 
  filter(Name %in% c('Brighton and Hove', 'East Sussex', 'West Sussex')) %>% 
  group_by(Date) %>% 
  summarise(Cumulative_cases = sum(Cumulative_cases, na.rm = TRUE),
            Population = sum(Population, na.rm = TRUE)) %>% 
  mutate(Name = 'Sussex areas combined') %>% 
  mutate(New_cases = Cumulative_cases - lag(Cumulative_cases)) %>% 
  mutate(New_cases_revised = ifelse(New_cases < 0, NA, New_cases)) %>% 
  mutate(rule_2 = rollapply(New_cases_revised, 3, function(x)if(any(is.na(x))) 'some missing' else 'all there', align = 'right', partial = TRUE)) %>% 
  mutate(Three_day_average_new_cases = ifelse(rule_2 == 'some missing', NA, rollapply(New_cases, 3, mean, align = 'right', fill=NA))) %>%
  select(-c(New_cases_revised, rule_2)) %>% 
  mutate(Period = format(Date, '%d %B')) %>% 
  mutate(Cumulative_per_100000 = (Cumulative_cases / Population) * 100000) %>% 
  mutate(New_cases_per_100000 = (New_cases / Population) * 100000) %>% 
  mutate(new_case_key = factor(ifelse(Date == min(Date), 'Starting cases', ifelse(New_cases < 0, 'Data revised down', ifelse(New_cases == 0, 'No new cases', ifelse(New_cases >= 1 & New_cases <= 10, '1-10 cases', ifelse(New_cases >= 11 & New_cases <= 25, '11-25 cases', ifelse(New_cases >= 26 & New_cases <= 50, '26-50 cases', ifelse(New_cases >= 51 & New_cases <= 75, '51-75 cases', ifelse(New_cases > 75, 'More than 75 cases', NA)))))))), levels =  c('Starting cases', 'Data revised down', 'No new cases', '1-10 cases', '11-25 cases', '26-50 cases', '51-75 cases', 'More than 75 cases'))) %>% 
  mutate(new_case_per_100000_key = factor(ifelse(Date == min(Date), 'Starting cases', ifelse(New_cases_per_100000 < 0, 'Data revised down', ifelse(round(New_cases_per_100000,0) == 0, 'No new cases', ifelse(round(New_cases_per_100000,0) > 0 & round(New_cases_per_100000, 0) <= 5, '1-5 new cases per 100,000', ifelse(round(New_cases_per_100000,0) >= 6 & round(New_cases_per_100000,0) <= 10, '6-10 new cases per 100,000', ifelse(round(New_cases_per_100000,0) >= 11 & round(New_cases_per_100000, 0) <= 15, '11-15 new cases per 100,000', ifelse(round(New_cases_per_100000,0) >= 16 & round(New_cases_per_100000,0) <= 20, '16-20 new cases per 100,000', ifelse(round(New_cases_per_100000,0) > 20, 'More than 20 new cases per 100,000', NA)))))))), levels =  c('Starting cases', 'Data revised down', 'No new cases', '1-5 new cases per 100,000', '6-10 new cases per 100,000', '11-15 new cases per 100,000', '16-20 new cases per 100,000', 'More than 20 new cases per 100,000'))) %>% 
  mutate(label_1 = ifelse(new_case_key == 'Starting cases', paste0('This is the first day of recording cases at UTLA level. On the 9th March there ', ifelse(Cumulative_cases == 0, ' were no cases', ifelse(Cumulative_cases == 1, ' was one Covid-19 case ', Cumulative_cases)), ' reported in ', Name, '.'), ifelse(new_case_key == 'Data revised down', paste0("The cumulative number of cases was revised on this day (", Period, ") which meant the number of new cases was negative, these have been reset to zero, with tomorrow's new cases calculated based on the revised cumulative value."), paste0('The number of new cases reported in the previous 24 hours was ', New_cases, '.')))) %>% 
  mutate(label_2 = ifelse(new_case_key %in% c('Starting cases', 'Data revised down'), paste0('The total (cumulative) number of COVID-19 cases reported to date (', Period, ') is <b>', format(Cumulative_cases, big.mark = ',', trim = TRUE), '</b>. This is <b>', round(Cumulative_per_100000,0), '</b> cases per 100,000 population.</p><p><i>Note: the rate per 100,000 is rounded to the nearest whole number, and sometimes this can appear as zero even when there were some cases reported.</i>'), paste0('The new cases reported on this day represent <b>', round((New_cases / Cumulative_cases) * 100, 1), '%</b> of the total cumulative number of COVID-19 cases reported to date (<b>', format(Cumulative_cases, big.mark = ',', trim = TRUE), '</b>). The current cumulative total per 100,000 population is <b>', round(Cumulative_per_100000,0), '</b>.</p><p><i>Note: the rate per 100,000 is rounded to the nearest whole number, and sometimes this can appear as zero even when there were some cases reported.</i>')))  %>% 
  mutate(label_3 = ifelse(is.na(Three_day_average_new_cases), paste0('It is not possible to calculate a three day rolling average for this date (', Period, ') because one of the values in the last three days is missing or revised.'), paste0('The rolling average number of new cases in the last three days is <b>', round(Three_day_average_new_cases, 0), '</b> cases. <i>Note: the rolling average has been rounded to the nearest whole number.</i>'))) 

south_east_region_daily_cases <- daily_cases %>% 
  filter(Name %in% c('Brighton and Hove', 'Bracknell Forest', 'Buckinghamshire', 'East Sussex', 'Hampshire', 'Isle of Wight', 'Kent', 'Medway', 'Milton Keynes', 'Oxfordshire', 'Portsmouth', 'Reading', 'Slough', 'Southampton', 'Surrey', 'West Berkshire', 'West Sussex', 'Windsor and Maidenhead', 'Wokingham')) %>% 
  group_by(Date) %>% 
  summarise(Cumulative_cases = sum(Cumulative_cases, na.rm = TRUE),
            Population = sum(Population, na.rm = TRUE)) %>% 
  mutate(Name = 'South East region') %>% 
  mutate(New_cases = Cumulative_cases - lag(Cumulative_cases)) %>% 
  mutate(New_cases_revised = ifelse(New_cases < 0, NA, New_cases)) %>% 
  mutate(rule_2 = rollapply(New_cases_revised, 3, function(x)if(any(is.na(x))) 'some missing' else 'all there', align = 'right', partial = TRUE)) %>% 
  mutate(Three_day_average_new_cases = ifelse(rule_2 == 'some missing', NA, rollapply(New_cases, 3, mean, align = 'right', fill=NA))) %>%
  select(-c(New_cases_revised, rule_2)) %>% 
  mutate(Period = format(Date, '%d %B')) %>% 
  mutate(Cumulative_per_100000 = (Cumulative_cases / Population) * 100000) %>% 
  mutate(New_cases_per_100000 = (New_cases / Population) * 100000) %>% 
  mutate(new_case_key = factor(ifelse(Date == min(Date), 'Starting cases', ifelse(New_cases < 0, 'Data revised down', ifelse(New_cases == 0, 'No new cases', ifelse(New_cases >= 1 & New_cases <= 10, '1-10 cases', ifelse(New_cases >= 11 & New_cases <= 25, '11-25 cases', ifelse(New_cases >= 26 & New_cases <= 50, '26-50 cases', ifelse(New_cases >= 51 & New_cases <= 75, '51-75 cases', ifelse(New_cases > 75, 'More than 75 cases', NA)))))))), levels =  c('Starting cases', 'Data revised down', 'No new cases', '1-10 cases', '11-25 cases', '26-50 cases', '51-75 cases', 'More than 75 cases'))) %>% 
  mutate(new_case_per_100000_key = factor(ifelse(Date == min(Date), 'Starting cases', ifelse(New_cases_per_100000 < 0, 'Data revised down', ifelse(round(New_cases_per_100000,0) == 0, 'No new cases', ifelse(round(New_cases_per_100000,0) > 0 & round(New_cases_per_100000, 0) <= 5, '1-5 new cases per 100,000', ifelse(round(New_cases_per_100000,0) >= 6 & round(New_cases_per_100000,0) <= 10, '6-10 new cases per 100,000', ifelse(round(New_cases_per_100000,0) >= 11 & round(New_cases_per_100000, 0) <= 15, '11-15 new cases per 100,000', ifelse(round(New_cases_per_100000,0) >= 16 & round(New_cases_per_100000,0) <= 20, '16-20 new cases per 100,000', ifelse(round(New_cases_per_100000,0) > 20, 'More than 20 new cases per 100,000', NA)))))))), levels =  c('Starting cases', 'Data revised down', 'No new cases', '1-5 new cases per 100,000', '6-10 new cases per 100,000', '11-15 new cases per 100,000', '16-20 new cases per 100,000', 'More than 20 new cases per 100,000'))) %>% 
  mutate(label_1 = ifelse(new_case_key == 'Starting cases', paste0('This is the first day of recording cases at UTLA level. On the 9th March there ', ifelse(Cumulative_cases == 0, ' were no cases', ifelse(Cumulative_cases == 1, ' was one Covid-19 case ', Cumulative_cases)), ' reported in ', Name, '.'), ifelse(new_case_key == 'Data revised down', paste0("The cumulative number of cases was revised on this day (", Period, ") which meant the number of new cases was negative, these have been reset to zero, with tomorrow's new cases calculated based on the revised cumulative value."), paste0('The number of new cases reported in the previous 24 hours was ', New_cases, '.')))) %>% 
  mutate(label_2 = ifelse(new_case_key %in% c('Starting cases', 'Data revised down'), paste0('The total (cumulative) number of COVID-19 cases reported on (', Period, ') was <b>', format(Cumulative_cases, big.mark = ',', trim = TRUE), '</b>. This is <b>', round(Cumulative_per_100000,0), '</b> cases per 100,000 population.</p><p><i>Note: the rate per 100,000 is rounded to the nearest whole number, and sometimes this can appear as zero even when there were some cases reported.</i>'), paste0('The new cases reported on this day represent <b>', round((New_cases / Cumulative_cases) * 100, 1), '%</b> of the total cumulative number of COVID-19 cases reported to date (<b>', format(Cumulative_cases, big.mark = ',', trim = TRUE), '</b>). The current cumulative total per 100,000 population is <b>', round(Cumulative_per_100000,0), '</b>.</p><p><i>Note: the rate per 100,000 is rounded to the nearest whole number, and sometimes this can appear as zero even when there were some cases reported.</i>')))  %>% 
  mutate(label_3 = ifelse(is.na(Three_day_average_new_cases), paste0('It is not possible to calculate a three day rolling average for this date (', Period, ') because one of the values in the last three days is missing or revised.'), paste0('The rolling average number of new cases in the last three days is <b>', round(Three_day_average_new_cases, 0), '</b> cases. <i>Note: the rolling average has been rounded to the nearest whole number.</i>'))) 
  
daily_cases_local <- daily_cases %>% 
  filter(Name %in% c('Brighton and Hove', 'Bracknell Forest', 'Buckinghamshire', 'East Sussex', 'Hampshire', 'Isle of Wight', 'Kent', 'Medway', 'Milton Keynes', 'Oxfordshire', 'Portsmouth', 'Reading', 'Slough', 'Southampton', 'Surrey', 'West Berkshire', 'West Sussex', 'Windsor and Maidenhead', 'Wokingham', 'England')) %>% 
  bind_rows(sussex_daily_cases) %>% 
  bind_rows(south_east_region_daily_cases)

# daily_cases_local %>% 
#   filter(Date == max(Date)) %>% 
#   select(Name, Population) %>% 
#   View()

#### to do - doubling time ####
# https://jglobalbiosecurity.com/articles/10.31646/gbio.61/
# https://blog.datawrapper.de/weekly-chart-coronavirus-doublingtimes/
# https://blogs.sas.com/content/iml/2020/04/01/estimate-doubling-time-exponential-growth.html

# So all my code is doing, in theory, is running a regression on cumulative cases against the number of days. From that it will output the gradient of the line of best fit (assumes its linear). So there should be no issue on running it on subsets (say 5 days), although obviously this method would be more susceptible to daily variation (which is a little more evident in Sussex).

#So we need to convert date into number of days since case number x.

# TODO ###
# filter for first instance of 10 cases (not just remove any values of less than 10 incase there is a revision that makes the count go down)
# Add in a safety that says if there are not seven data points in a 'period_in_reverse', then do not calculate doubling_time
#####

# Over a subset of days would be better than the whole series

double_time_period <- 7 # this could be 5 or 7 

# I've made an ifelse function for 12 weeks of data

doubling_time_df <- daily_cases_local %>% 
  group_by(Name) %>% 
  mutate(Days = row_number()-1) %>% 
  mutate(Log10Cumul = log10(Cumulative_cases)) %>% 
  mutate(period_in_reverse = ifelse(Days > max(Days) -double_time_period, 1, ifelse(Days > max(Days)-(double_time_period*2), 2, ifelse(Days > max(Days)-(double_time_period*3), 3, ifelse(Days > max(Days) - (double_time_period*4), 4, ifelse(Days > max(Days) - (double_time_period *5), 5, ifelse(Days > max(Days) - (double_time_period * 6), 6, ifelse(Days > max(Days) - (double_time_period * 7), 7, ifelse(Days > max(Days) - (double_time_period * 8), 8, ifelse(Days > max(Days) - (double_time_period * 9), 9, ifelse(Days > max(Days) - (double_time_period * 10), 10, ifelse(Days > max(Days) - (double_time_period * 11), 11, ifelse(Days > max(Days) - (double_time_period * 12), 12, NA))))))))))))) %>% 
  group_by(Name, period_in_reverse) %>%   
  mutate(Slope = coef(lm(Log10Cumul ~ Days))[2]) %>% 
  mutate(Double_time = log(2, base = 10)/coef(lm(Log10Cumul ~ Days))[2]) %>% 
  select(Name, period_in_reverse, Slope, Double_time) %>% 
  unique()

local_cases_summary <- daily_cases_local %>% 
  filter(Date == max(Date)) %>% 
  select(Name, Cumulative_cases, Cumulative_per_100000, New_cases, New_cases_per_100000, Three_day_average_new_cases) %>%
  rename(`Total cases` = Cumulative_cases,
         `Total cases per 100,000 population` = Cumulative_per_100000,
         `New cases in past 24 hours` = New_cases,
         `New cases per 100,000 population` = New_cases_per_100000,
         `Average number of new cases past three days` = Three_day_average_new_cases) %>%
  arrange(-`Total cases`) %>% 
  mutate(Name = factor(Name, levels = unique(Name))) %>% 
  mutate(highlight = ifelse(Name %in% c('Brighton and Hove', 'East Sussex', 'West Sussex'), 'bold', 'plain'))

daily_cases_local <- daily_cases_local %>% 
  mutate(Name = factor(Name, levels = levels(local_cases_summary$Name))) %>% 
  arrange(Name)

local_cases_summary %>%
  select(-highlight) %>% 
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/another_covid_repo/se_case_summary.json'))

daily_cases_local %>%
  toJSON() %>% 
  write_lines(paste0('/Users/richtyler/Documents/Repositories/another_covid_repo/se_daily_cases.json'))

# ggplot(se_daily_cases, aes(x = Date, 
#                 y = Name, 
#                 fill = new_case_per_100000_key)) + 
#   scale_fill_manual(values = c('#dcf3f5','#a6b4d8','#ffffb2','#fed976','#feb24c','#fd8d3c','#f03b20','#bd0026'),
#                     name = 'Tile colour\nkey') +
#   geom_tile(colour = "#ffffff") +
#   labs(x = NULL, 
#        y = NULL) +
#   scale_x_date(date_labels = "%b %d",
#                date_breaks = '1 week',
#                limits = c(min(se_daily_cases$Date) -1, min(se_daily_cases$Date) + 59),
#                expand = c(0,0.01)) +
#   theme(axis.text.x = element_text(angle = 0, hjust = 0),
#         legend.position = "bottom", 
#         legend.text = element_text(colour = "#323232", size = 8), 
#         panel.background = element_rect(fill = "white"), 
#         plot.title = element_text(colour = "#000000", face = "bold", size = 11, vjust = 1), 
#         axis.text.y = element_text(colour = "#323232", face = se_cases_summary$highlight, size = 8),  
#         legend.title = element_text(colour = "#323232", face = "bold", size = 10),  
#         panel.grid.major.x = element_blank(),
#         panel.grid.minor.x = element_blank(), 
#         panel.grid.major.y = element_blank(),
#         panel.grid.minor.y = element_blank(), 
#         legend.key.size = unit(0.65, "lines"), 
#         legend.background = element_rect(fill = "#ffffff"), 
#         legend.key = element_rect(fill = "#ffffff", colour = "#E2E2E3"), 
#         strip.text = element_text(colour = "#000000", face = "bold"),
#         strip.background = element_rect(fill = "#ffffff"))

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


# Mortality data ####

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

download.file('https://www.england.nhs.uk/statistics/wp-content/uploads/sites/2/2020/04/COVID-19-total-announced-deaths-5-April-2020.xlsx', paste0(github_repo_dir, '/refreshed_daily_deaths_trust.xlsx'), mode = 'wb')
              
refreshed_daily_deaths_trust <- read_excel(paste0(github_repo_dir, "/refreshed_daily_deaths_trust.xlsx"), skip = 15) %>% 
  select(-c(...2, Total)) %>% 
  filter(!is.na(Code)) %>% 
  mutate(Name = capwords(Name, strict = TRUE)) %>% 
  gather(key = "Date", value = "Deaths", 5:ncol(.)) %>% 
  mutate(Date = as.Date(as.numeric(Date), origin = "1899-12-30")) %>% 
  filter(!is.na(Date))

  
  