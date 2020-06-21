
case_x_number = 5

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
  ungroup() %>% 
  mutate(Data_completeness = ifelse(Date >= max(Date) - 4, 'Considered incomplete', 'Complete')) 

# Doubling time ####
# https://jglobalbiosecurity.com/articles/10.31646/gbio.61/
# https://blog.datawrapper.de/weekly-chart-coronavirus-doublingtimes/
# https://blogs.sas.com/content/iml/2020/04/01/estimate-doubling-time-exponential-growth.html

# We create a doubling time using the most recent 5 day period (and doubling time is recalculated every day once new data is available) 
double_time_period <- 7 # this could be 5 or 7 

# I've made an ifelse function that identifies 7 day periods for 100 days or 140 days of data if 7 day doubling time is used and this may have to change in the future.

# Importantly, given that the data has changed from reported date to specimen date, and that the last five days have been concluded as incomplete, it would not be useful to report a doubling time for this time period.

# I think we're on week 25 now, so perhaps add some more

doubling_time_df <- daily_cases_reworked %>% 
  filter(Days_since_case_x >= 0) %>%
  filter(Data_completeness == 'Complete') %>% 
  group_by(Name) %>% 
  arrange(Name,Date) %>% 
  mutate(period_in_reverse = ifelse(Date > max(Date) - (double_time_period), 1, ifelse(Date > max(Date) - (double_time_period * 2), 2, ifelse(Date > max(Date) - (double_time_period * 3), 3, ifelse(Date > max(Date) - (double_time_period * 4), 4, ifelse(Date > max(Date) - (double_time_period * 5), 5, ifelse(Date > max(Date) - (double_time_period * 6), 6, ifelse(Date > max(Date) - (double_time_period * 7), 7, ifelse(Date > max(Date) - (double_time_period * 8), 8, ifelse(Date > max(Date) - (double_time_period * 9), 9, ifelse(Date > max(Date) - (double_time_period * 10), 10, ifelse(Date > max(Date) - (double_time_period * 11), 11, ifelse(Date > max(Date) - (double_time_period * 12), 12, ifelse(Date > max(Date) - (double_time_period * 13), 13, ifelse(Date > max(Date) - (double_time_period * 14), 14, ifelse(Date > max(Date) - (double_time_period * 15), 15, ifelse(Date > max(Date) - (double_time_period * 16), 16, ifelse(Date > max(Date) - (double_time_period * 17), 17, ifelse(Date > max(Date) - (double_time_period * 18), 18, ifelse(Date > max(Date) - (double_time_period * 19), 19, ifelse(Date > max(Date) - (double_time_period * 20), 20, ifelse(Date > max(Date) - (double_time_period * 21), 21,ifelse(Date > max(Date) - (double_time_period * 22), 22,ifelse(Date > max(Date) - (double_time_period * 23), 23,ifelse(Date > max(Date) - (double_time_period * 24), 24,ifelse(Date > max(Date) - (double_time_period * 25), 25,ifelse(Date > max(Date) - (double_time_period * 26), 26,ifelse(Date > max(Date) - (double_time_period * 27), 27, ifelse(Date > max(Date) - (double_time_period * 28), 28, ifelse(Date > max(Date) - (double_time_period * 29), 29, ifelse(Date > max(Date) - (double_time_period * 30), 30,NA))))))))))))))))))))))))))))))) %>% 
  group_by(Name, period_in_reverse) %>%   
  mutate(Slope = coef(lm(Log10Cumulative_cases ~ Days_since_first_case))[2]) %>% 
  mutate(Double_time = log(2, base = 10)/coef(lm(Log10Cumulative_cases ~ Days_since_first_case))[2]) %>%
  mutate(N_days_in_doubling_period = n()) %>% 
  mutate(Cases_in_doubling_period = sum(New_cases, na.rm = TRUE)) %>% 
  mutate(Double_time = ifelse(N_days_in_doubling_period != double_time_period, NA, ifelse(Cases_in_doubling_period == 0, NA, Double_time))) %>%
  mutate(Slope = ifelse(N_days_in_doubling_period != double_time_period, NA, Slope)) %>% 
  mutate(date_range_label = paste0(ifelse(period_in_reverse == '1', paste0('most recent complete ', double_time_period, ' days ('), ifelse(period_in_reverse == '2', paste0('previous ', double_time_period, ' days ('), paste0('period ', period_in_reverse, ' ('))), format(min(Date), '%d-%B'), '-', format(max(Date), '%d-%B'), ')')) %>% 
  mutate(date_range_label = ifelse(N_days_in_doubling_period != double_time_period, NA, date_range_label)) %>% 
  mutate(short_date_label = paste0(format(min(Date), '%d-%b'), '-', format(max(Date), '%d-%b'))) %>% 
  mutate(long_date_label = paste0(format(min(Date), '%d-%B'), ' and ', format(max(Date), '%d-%B'))) %>% 
  mutate(date_range_label = ifelse(N_days_in_doubling_period != double_time_period, NA, date_range_label)) %>% 
  mutate(short_date_label = ifelse(N_days_in_doubling_period != double_time_period, NA, short_date_label)) %>% 
  mutate(long_date_label = ifelse(N_days_in_doubling_period != double_time_period, NA, long_date_label)) %>% 
  ungroup() 


# 3 - 12% of tests being positive is an indicator of robust testing

# WHO recommendation that ten negative tests to one positive is a general benchmark of a system that's doing enough testing to pick up all cases.

# It can be more or it can be less depending on the circumstance. It's not an objective but you really do want to see a lot... You know you're missing a lot of cases if 80 or 90% of the people you test are positive; you are probably missing a lot of cases.


# So i think you need to create a template with placeholders in powerpoint for your items (images mostly). Then we should be able to use that in R to generate new files.

https://www.r-bloggers.com/creating-and-saving-multiple-plots-to-powerpoint/
  
library(officer)

my_super_pres <- read_pptx('/Users/richtyler/Documents/Repositories/another_covid_repo/Outputs/test_presentation.pptx')

my_super_pres <- add_slide(my_super_pres, layout = "overview_four_charts", master = "Office Theme")
my_super_pres <- ph_with(x = my_super_pres, value = new_case_rate_plot,
                         ph_location_type(type = "body",
                                          position_right = TRUE,
                                          position_top = TRUE))
?ph_with()

my_super_pres <- ph_with(x = my_super_pres, value = new_case_rate_plot,
                 location = ph_location_type(type = "body"),
                 bg = "transparent" )


print(doc, target = "ph_with_gg.pptx")