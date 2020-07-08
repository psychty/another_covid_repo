
output_directory_x <- paste0(github_repo_dir, '/Outputs/P12_daily_cases/')

areas_to_loop <- c('West Sussex', 'Adur', 'Arun', 'Chichester', 'Crawley', 'Horsham', 'Mid Sussex', 'Worthing')

 # Public facing data pack - West Sussex and LTLAs
library(easypackages)

libraries(c("readxl", "readr", "plyr", "dplyr", "ggplot2", "tidyverse", "reshape2", "scales", 'jsonlite', 'zoo', 'stats', 'fingertipsR', 'readODS'))

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

# We are interested in the whole of Sussex (three LA combined)
sussex_pop <- mye_total %>% 
  filter(Name %in% c('Brighton and Hove', 'East Sussex', 'West Sussex')) %>%
  summarise(Population = sum(Population, na.rm = TRUE)) %>% 
  mutate(Name = 'Sussex areas combined') %>% 
  mutate(Code = '-')

area_code_names <- mye_total %>% 
  select(Code, Name)

mye_total <- mye_total %>%
  bind_rows(sussex_pop) %>% 
  select(-Name)

#download.file('https://fingertips.phe.org.uk/documents/Historic%20COVID-19%20Dashboard%20Data.xlsx', paste0(github_repo_dir, '/refreshed_daily_cases.xlsx'), mode = 'wb')

# On 14th April, the way in which PHE share data on cases changed. Data were presented daily on the number of confirmed cases reported to PHE on a particular day. As testing takes time, and as capacity is being increased, there can be some delay in returning results. An example is a patient having a swab taken on 1st April, with results returned on 5th April and reported to PHE. In such a case, the confirmed case will be attributed to 5th April even though the patient was infected at least four days earlier. The new method of reporting shows confirmed cases by the date at which the specimen for testing was taken. Duplicate tests for the same person are removed. The first positive specimen date is used as the specimen date for that person.

# Whilst this method more accurately tracks the dates at which people are known to be infected, it may look like the most recent days' cases (which are still being reported daily) are sloping off (getting smaller). This is not the case, it is just that the most recent testing results may take several days to be reported. PHE suggest that data for the most recent five days should be treated with caution and considered 'incomplete'.

# Prior to April 14th, the earliest reporting date was March 9th. In some areas, there were already cases, and in other areas there were none. Data are now back dated and revised such that every lab-confirmed case is attributed to the date at which the specimin was taken, which means the time series starts at different dates for different areas. The first specimens for a confirmed Covid-19 infection were taken on January 30th 2020.

daily_cases_raw <- read_csv('https://coronavirus.data.gov.uk/downloads/csv/coronavirus-cases_latest.csv') %>%   
  rename(Name = `Area name`) %>% 
  rename(Code = `Area code`) %>% 
  rename(Date = `Specimen date`) %>% 
  rename(New_cases = `Daily lab-confirmed cases`) %>% 
  rename(Cumulative_cases = `Cumulative lab-confirmed cases`) %>% 
  arrange(Name, Date) %>% 
  select(Name, Code, `Area type`, Date, New_cases, Cumulative_cases) %>% 
  group_by(Name, Code, Date) %>% 
  mutate(Count = n()) %>% 
  filter(!(`Area type` == 'Lower tier local authority' & Count == 2)) %>% 
  select(-c(`Area type`, Count)) %>% 
  left_join(mye_total, by = 'Code') %>% 
  select(-DATE_NAME) %>% 
  ungroup()

# Create a subset for Sussex
sussex_daily_cases <- daily_cases_raw %>% 
  filter(Name %in% c('Brighton and Hove', 'East Sussex', 'West Sussex')) %>%
  group_by(Date) %>% 
  summarise(New_cases = sum(New_cases, na.rm = TRUE)) %>%
  ungroup() %>% 
  mutate(Cumulative_cases = cumsum(New_cases)) %>% # We have to rebuild this because in some cases there are no rows for an individual area if no new cases. 
  mutate(Name = 'Sussex areas combined') %>% 
  mutate(Code = '-') %>% 
  left_join(mye_total, by = 'Code') %>% 
  select(-DATE_NAME) %>% 
  mutate(Type = 'Sussex areas combined') %>% 
  ungroup()

# Combine raw data with Sussex data
daily_cases <- daily_cases_raw %>% 
  bind_rows(sussex_daily_cases)

rm(daily_cases_raw, sussex_daily_cases, sussex_pop)

# Now have a date of specimen for each area. If no specimens are taken on a day, there is no row for it, and it would be missing data. Indeed, the only zeros are on the latest day. We need to therefore backfill and say if no date exists where it should, then add it, with the cumulative total and zero for new cases.

# One way to do this is to create a new dataframe with a row for each area and date, and left join the daily_cases data to it.
first_date <- min(daily_cases$Date)
last_date <- max(daily_cases$Date)

Areas = daily_cases %>% 
  select(Name, Code, Type) %>% 
  unique()

Dates = seq.Date(first_date, last_date, by = '1 day')

daily_cases_reworked <- data.frame(Name = rep(Areas$Name, length(Dates)), Code = rep(Areas$Code, length(Dates)), Type = rep(Areas$Type, length(Dates)), check.names = FALSE) %>% 
  arrange(Name) %>% 
  group_by(Name) %>% 
  mutate(Date = seq.Date(first_date, last_date, by = '1 day')) %>% 
  left_join(daily_cases, by = c('Name', 'Code', 'Type', 'Date')) %>% 
  mutate(New_cases = ifelse(is.na(New_cases), 0, New_cases)) %>% 
  mutate(New_cumulative = cumsum(New_cases)) %>% 
  filter(!is.na(Cumulative_cases)) %>% 
  mutate(Calculated_same_as_original = ifelse(Cumulative_cases == New_cumulative, 'Yaas', 'Negative'))

# PHE say the last five data points are incomplete (perhaps they should not publish them). Instead, we need to make sure we account for this so that it is not misinterpreted.
complete_date <- max(daily_cases_reworked$Date) - 5

p12_test_df <- data.frame(Name = rep(Areas$Name, length(Dates)), Code = rep(Areas$Code, length(Dates)), Type = rep(Areas$Type, length(Dates)), check.names = FALSE) %>% 
  arrange(Name) %>% 
  group_by(Name) %>% 
  mutate(Date = seq.Date(first_date, last_date, by = '1 day')) %>% 
  mutate(Data_completeness = ifelse(Date >= max(Date) - 4, 'Considered incomplete', 'Complete')) %>% 
  left_join(daily_cases, by = c('Name', 'Code', 'Type', 'Date')) %>% 
  mutate(New_cases = ifelse(is.na(New_cases), 0, New_cases)) %>% 
  rename(Original_cumulative = Cumulative_cases) %>% # We should keep the original cumulative cases for reference
  mutate(Cumulative_cases = cumsum(New_cases)) %>% # These are based on the new cases data being accurate
  group_by(Name) %>% 
  mutate(Seven_day_average_new_cases = rollapply(New_cases, 7, mean, align = 'right', fill = NA)) %>%
  mutate(Seven_day_average_cumulative_cases = rollapply(Cumulative_cases, 7, mean, align = 'right', fill = NA)) %>% 
  mutate(Period = format(Date, '%d %B')) %>%
  select(-Population) %>% 
  left_join(mye_total[c('Code', 'Population')], by = 'Code') %>% 
  mutate(Cumulative_per_100000 = (Cumulative_cases / Population) * 100000) %>% 
  mutate(New_cases_per_100000 = (New_cases / Population) * 100000) %>% 
  mutate(new_case_key = factor(ifelse(New_cases == 0, 'No new cases', ifelse(New_cases >= 1 & New_cases <= 10, '1-10 cases', ifelse(New_cases >= 11 & New_cases <= 25, '11-25 cases', ifelse(New_cases >= 26 & New_cases <= 50, '26-50 cases', ifelse(New_cases >= 51 & New_cases <= 75, '51-75 cases', ifelse(New_cases >= 76 & New_cases <= 100, '76-100 cases', ifelse(New_cases >100, 'More than 100 cases', NA))))))), levels =  c('No new cases', '1-10 cases', '11-25 cases', '26-50 cases', '51-75 cases', '76-100 cases', 'More than 100 cases'))) %>%
  mutate(new_case_per_100000_key = factor(ifelse(New_cases_per_100000 < 0, 'Data revised down', ifelse(round(New_cases_per_100000,0) == 0, 'No new cases', ifelse(round(New_cases_per_100000,0) > 0 & round(New_cases_per_100000, 0) <= 5, '1-5 new cases per 100,000', ifelse(round(New_cases_per_100000,0) >= 6 & round(New_cases_per_100000,0) <= 10, '6-10 new cases per 100,000', ifelse(round(New_cases_per_100000,0) >= 11 & round(New_cases_per_100000, 0) <= 15, '11-15 new cases per 100,000', ifelse(round(New_cases_per_100000,0) >= 16 & round(New_cases_per_100000,0) <= 20, '16-20 new cases per 100,000', ifelse(round(New_cases_per_100000,0) > 20, 'More than 20 new cases per 100,000', NA))))))), levels =  c('No new cases', '1-5 new cases per 100,000', '6-10 new cases per 100,000', '11-15 new cases per 100,000', '16-20 new cases per 100,000', 'More than 20 new cases per 100,000'))) %>% 
  ungroup() %>% 
  mutate(Name = ifelse(Name == 'South East', 'South East region', Name)) %>% 
  filter(Name %in% areas_to_loop) %>% 
  mutate(Test_pillar = 'Pillars 1 and 2')

rm(daily_cases, Areas, Dates, first_date, mye_total, area_code_names, daily_cases_reworked)

for(i in 1:length(areas_to_loop)){
  
area_x <- areas_to_loop[i]

area_x_df_1 <- p12_test_df %>%
  filter(Name == area_x)

peak_case_label <- area_x_df_1 %>%
  filter(New_cases == max(New_cases, na.rm = TRUE)) %>%
  filter(Date == min(Date, na.rm = TRUE))

# max_cumulative_case_limit <- ifelse(max(area_x_df_1$Cumulative_cases, na.rm = TRUE) < 50, round_any(max(area_x_df_1$Cumulative_cases, na.rm = TRUE), 5, ceiling), ifelse(max(area_x_df_1$Cumulative_cases, na.rm = TRUE) < 100, round_any(max(area_x_df_1$Cumulative_cases, na.rm = TRUE), 10, ceiling), ifelse(max(area_x_df_1$Cumulative_cases, na.rm = TRUE) < 250, round_any(max(area_x_df_1$Cumulative_cases, na.rm = TRUE), 25, ceiling), ifelse(max(area_x_df_1$Cumulative_cases, na.rm = TRUE) < 500, round_any(max(area_x_df_1$Cumulative_cases, na.rm = TRUE), 50, ceiling), round_any(max(area_x_df_1$Cumulative_cases, na.rm = TRUE), 100, ceiling)))))
# 
# max_cumulative_case_break <- ifelse(max(area_x_df_1$Cumulative_cases, na.rm = TRUE) < 20, 2, ifelse(max(area_x_df_1$Cumulative_cases, na.rm = TRUE) < 50, 5, ifelse(max(area_x_df_1$Cumulative_cases, na.rm = TRUE) < 100, 10, ifelse(max(area_x_df_1$Cumulative_cases, na.rm = TRUE) < 250, 25, ifelse(max(area_x_df_1$Cumulative_cases, na.rm = TRUE) < 500, 50, 100)))))

max_daily_case_limit <- ifelse(max(area_x_df_1$New_cases, na.rm = TRUE) < 50, round_any(max(area_x_df_1$New_cases, na.rm = TRUE), 5, ceiling), ifelse(max(area_x_df_1$New_cases, na.rm = TRUE) < 100, round_any(max(area_x_df_1$New_cases, na.rm = TRUE), 10, ceiling), ifelse(max(area_x_df_1$New_cases, na.rm = TRUE) < 250, round_any(max(area_x_df_1$New_cases, na.rm = TRUE), 25, ceiling), ifelse(max(area_x_df_1$New_cases, na.rm = TRUE) < 500, round_any(max(area_x_df_1$New_cases, na.rm = TRUE), 50, ceiling), round_any(max(area_x_df_1$New_cases, na.rm = TRUE), 100, ceiling)))))

max_daily_case_break <- ifelse(max(area_x_df_1$New_cases, na.rm = TRUE) < 20, 2, ifelse(max(area_x_df_1$New_cases, na.rm = TRUE) < 50, 5, ifelse(max(area_x_df_1$New_cases, na.rm = TRUE) < 100, 10, ifelse(max(area_x_df_1$New_cases, na.rm = TRUE) < 250, 25, ifelse(max(area_x_df_1$New_cases, na.rm = TRUE) < 500, 50, 100)))))


total_cases_reported_plot <- ggplot(area_x_df_1,
                                      aes(x = Date,
                                          y = New_cases,
                                          group = Test_pillar)) +
  geom_bar(stat = 'identity',
           position = 'stack',
           colour = '#ffffff',
           aes(fill = Test_pillar)) +
  geom_line(data = area_x_df_1,
            aes(x = Date,
                y = Seven_day_average_new_cases),
            group = 1,
            colour = '#000000') +
  scale_fill_manual(values = c('#071b7c'),
                    name = 'Pillar') +
  scale_x_date(date_labels = "%b %d",
               breaks = seq.Date(max(area_x_df_1$Date) -(52*7), max(area_x_df_1$Date), by = 7),
               limits = c(min(area_x_df_1$Date), max(area_x_df_1$Date)),
               expand = c(0.01,0.01)) +
  scale_y_continuous(labels = label_comma(accuracy = 1),
                     breaks = seq(0,max_daily_case_limit, max_daily_case_break),
                     limits = c(0,max_daily_case_limit)) +
  geom_segment(x = complete_date+1,
               y = 0,
               xend = complete_date+1,
               yend = Inf,
               color = "red",
               linetype = "dashed") +
  annotate('rect',
           xmin = complete_date + 1,
           xmax = max(area_x_df_1$Date),
           ymin = 0,
           ymax = Inf,
           fill = '#cccccc',
           alpha = .25) +
  annotate('text',
           x = complete_date,
           y = max_daily_case_limit * .8,
           label = 'Last 5 days\nnot considered\ncomplete:',
           size = 2.5,
           hjust = 1) +
  labs(x = 'Date',
       y = 'Number of daily confirmed cases',
       title = paste0('Daily number of confirmed Covid-19 cases; Pillar 1 and 2 combined; ', area_x),
       subtitle = paste0('Confirmed cases by specimen date; 01 March - ', format(max(area_x_df_1$Date), '%d %B %Y')),
       caption = 'The black line represents the average number of new cases confirmed in the previous seven days.') +
  ph_theme() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = .5)) +
  theme(legend.position = 'none')

png(paste0(output_directory_x, '/Covid_19_confirmed_cases_', gsub(' ', '_', area_x), '.png'),
    width = 1580,
    height = 750,
    res = 200)
print(total_cases_reported_plot)
dev.off()

}

ltla_p12_test_df <- p12_test_df %>% 
  filter(Name != 'West Sussex')

max_daily_case_limit <- ifelse(max(ltla_p12_test_df$New_cases, na.rm = TRUE) < 50, round_any(max(ltla_p12_test_df$New_cases, na.rm = TRUE), 5, ceiling), ifelse(max(ltla_p12_test_df$New_cases, na.rm = TRUE) < 100, round_any(max(ltla_p12_test_df$New_cases, na.rm = TRUE), 10, ceiling), ifelse(max(ltla_p12_test_df$New_cases, na.rm = TRUE) < 250, round_any(max(ltla_p12_test_df$New_cases, na.rm = TRUE), 25, ceiling), ifelse(max(ltla_p12_test_df$New_cases, na.rm = TRUE) < 500, round_any(max(ltla_p12_test_df$New_cases, na.rm = TRUE), 50, ceiling), round_any(max(ltla_p12_test_df$New_cases, na.rm = TRUE), 100, ceiling)))))

max_daily_case_break <- ifelse(max(ltla_p12_test_df$New_cases, na.rm = TRUE) < 20, 2, ifelse(max(ltla_p12_test_df$New_cases, na.rm = TRUE) < 50, 5, ifelse(max(ltla_p12_test_df$New_cases, na.rm = TRUE) < 100, 10, ifelse(max(ltla_p12_test_df$New_cases, na.rm = TRUE) < 250, 25, ifelse(max(ltla_p12_test_df$New_cases, na.rm = TRUE) < 500, 50, 100)))))

total_cases_reported_plot_2 <- ggplot(ltla_p12_test_df,
       aes(x = Date,
           y = New_cases,
           group = Test_pillar)) +
  geom_bar(stat = 'identity',
           position = 'stack',
           colour = '#ffffff',
           fill = '#071b7c',
           aes(fill = Test_pillar)) +
  geom_line(data = ltla_p12_test_df,
            aes(x = Date,
                y = Seven_day_average_new_cases),
            group = 1,
            colour = '#000000') +
  scale_fill_manual(values = c('#071b7c'),
                    name = 'Pillar') +
  scale_x_date(date_labels = "%b %d",
               breaks = seq.Date(max(ltla_p12_test_df$Date) -(52*7), max(ltla_p12_test_df$Date), by = 7),
               limits = c(min(ltla_p12_test_df$Date), max(ltla_p12_test_df$Date)),
               expand = c(0.01,0.01)) +
  scale_y_continuous(labels = label_comma(accuracy = 1),
                     breaks = seq(0,max_daily_case_limit, max_daily_case_break),
                     limits = c(0,max_daily_case_limit)) +
  geom_segment(x = complete_date+1,
               y = 0,
               xend = complete_date+1,
               yend = Inf,
               color = "red",
               linetype = "dashed") +
  annotate('rect',
           xmin = complete_date + 1,
           xmax = max(ltla_p12_test_df$Date),
           ymin = 0,
           ymax = Inf,
           fill = '#cccccc',
           alpha = .25) +
  annotate('text',
           x = complete_date,
           y = max_daily_case_limit * .8,
           label = 'Last 5 days\nnot considered\ncomplete:',
           size = 2.5,
           hjust = 1) +
  labs(x = 'Date',
       y = 'Number of daily confirmed cases',
       title = paste0('Daily number of confirmed Covid-19 cases; Pillar 1 and 2 combined; West Sussex lower tier Local Authorities'),
       subtitle = paste0('Confirmed cases by specimen date; 01 March - ', format(max(ltla_p12_test_df$Date), '%d %B %Y')),
       caption = 'The black line represents the average number of new cases confirmed in the previous seven days.') +
  ph_theme() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = .5)) +
  facet_wrap(~Name, ncol = 3) +
  theme(legend.position = 'none')

png(paste0(output_directory_x, '/Covid_19_confirmed_cases_wsx_ltlas.png'),
    width = 1580,
    height = 1050,
    res = 120)
print(total_cases_reported_plot_2)
dev.off()

# Mortality ####

deaths_labels <- read_csv(paste0(github_repo_dir, '/All_settings_deaths_occurrences.csv')) %>% 
  arrange(Week_number) %>% 
  select(Week_ending) %>% 
  unique() %>% 
  mutate(deaths_label = paste0('w/e ', ordinal(as.numeric(format(Week_ending, '%d'))), format(Week_ending, ' %b')))

weekly_all_place_all_deaths <- read_csv(paste0(github_repo_dir, '/All_settings_deaths_occurrences.csv')) %>% 
  filter(Name %in% areas_to_loop) %>% 
  filter(Cause == 'All causes') %>% 
  arrange(Week_number) %>% 
  select(Name, Week_ending, Deaths) %>% 
  mutate(Week_ending = factor(paste0('w/e ', ordinal(as.numeric(format(Week_ending, '%d'))), format(Week_ending, ' %b')), levels = deaths_labels$deaths_label)) %>% 
  rename(All_deaths = Deaths)

weekly_all_place_deaths <- read_csv(paste0(github_repo_dir, '/All_settings_deaths_occurrences.csv')) %>% 
  filter(Name %in% areas_to_loop) %>%
  arrange(Week_number) %>% 
  select(Name, Cause, Week_ending, Deaths) %>% 
  mutate(Week_ending = factor(paste0('w/e ', ordinal(as.numeric(format(Week_ending, '%d'))), format(Week_ending, ' %b')), levels = deaths_labels$deaths_label)) %>% 
  pivot_wider(id_cols = c(Name, Week_ending),
              names_from = Cause,
              values_from = Deaths) %>% 
  mutate(`Non-Covid` = `All causes` - `COVID 19`) %>%
  select(-`All causes`) %>% 
  gather(key = 'Cause', value = 'Deaths', `COVID 19`:`Non-Covid`) %>% 
  mutate(Cause = factor(Cause, levels = rev(c('Non-Covid', 'COVID 19')))) %>% 
  mutate(lab_posit = ifelse(Cause == 'Non-Covid', 1.5, -1)) %>% 
  left_join(weekly_all_place_all_deaths, by = c('Name', 'Week_ending'))

for(i in 1:length(areas_to_loop)){
  
area_x <- areas_to_loop[i]

area_x_cov_non_cov <- weekly_all_place_deaths %>% 
  filter(Name == area_x)

max_deaths_limit <- ifelse(max(area_x_cov_non_cov$All_deaths, na.rm = TRUE) < 50, round_any(max(area_x_cov_non_cov$All_deaths, na.rm = TRUE), 5, ceiling), ifelse(max(area_x_cov_non_cov$All_deaths, na.rm = TRUE) < 100, round_any(max(area_x_cov_non_cov$All_deaths, na.rm = TRUE), 10, ceiling), ifelse(max(area_x_cov_non_cov$All_deaths, na.rm = TRUE) < 250, round_any(max(area_x_cov_non_cov$All_deaths, na.rm = TRUE), 25, ceiling), ifelse(max(area_x_cov_non_cov$All_deaths, na.rm = TRUE) < 500, round_any(max(area_x_cov_non_cov$All_deaths, na.rm = TRUE), 50, ceiling), round_any(max(area_x_cov_non_cov$All_deaths, na.rm = TRUE), 100, ceiling)))))

max_deaths_break <- ifelse(max(area_x_cov_non_cov$All_deaths, na.rm = TRUE) < 20, 2, ifelse(max(area_x_cov_non_cov$All_deaths, na.rm = TRUE) < 50, 5, ifelse(max(area_x_cov_non_cov$All_deaths, na.rm = TRUE) < 100, 10, ifelse(max(area_x_cov_non_cov$All_deaths, na.rm = TRUE) < 250, 25, ifelse(max(area_x_cov_non_cov$All_deaths, na.rm = TRUE) < 500, 50, 100)))))


area_x_wk_cause_deaths_plot <- ggplot(area_x_cov_non_cov,
                                      aes(x = Week_ending, 
                                          y = Deaths,
                                          fill = Cause,
                                          colour = Cause,
                                          label = Deaths)) +
  geom_bar(stat = 'identity',
           colour = '#ffffff') +
  # geom_text(data = subset(area_x_cov_non_cov, Deaths > 0),
  #           position = 'stack',
  #           size = 3, 
  #           fontface = "bold",
  #           aes(vjust = lab_posit)) +
  labs(title = paste0('Weekly deaths; ', area_x,'; w/e 3rd Jan 2020 - ', deaths_labels$deaths_label[length(deaths_labels$deaths_label)]),
       subtitle = paste0('By week of occurrence and by Covid-19 mentioned on death certificate (deaths registered by ', format(max(deaths_labels$Week_ending) + 8, '%d %B %Y'), ')'),
       x = 'Week',
       y = 'Number of deaths') +
  scale_fill_manual(values = c('#2F5597','#BDD7EE'),
                    labels = c('COVID-19', 'COVID not mentioned')) +
  scale_colour_manual(values = c('#000000', '#ffffff')) +
  scale_y_continuous(breaks = seq(0,max_deaths_limit, max_deaths_break),
                     limits = c(0,max_deaths_limit)) +
  ph_theme() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = .5),
        legend.position = 'bottom')  +
  guides(colour = FALSE)

png(paste0(output_directory_x, '/Covid_19_deaths_', gsub(' ', '_', area_x), '.png'),
    width = 1580,
    height = 750,
    res = 200)
print(area_x_wk_cause_deaths_plot)
dev.off()

care_home_ons_all_deaths <- read_csv(paste0(github_repo_dir, '/Care_home_death_occurrences_ONS_weekly.csv')) %>% 
  filter(Name %in% areas_to_loop) %>% 
  filter(Cause == 'All causes') %>% 
  arrange(Week_number) %>% 
  select(Name, Week_ending, Deaths) %>% 
  mutate(Week_ending = factor(paste0('w/e ', ordinal(as.numeric(format(Week_ending, '%d'))), format(Week_ending, ' %b')), levels = deaths_labels$deaths_label)) %>% 
  rename(All_deaths = Deaths)

carehome_weekly_deaths <- read_csv(paste0(github_repo_dir, '/Care_home_death_occurrences_ONS_weekly.csv')) %>% 
  filter(Name %in% areas_to_loop) %>%
  arrange(Week_number) %>% 
  select(Name, Cause, Week_ending, Deaths) %>% 
  mutate(Week_ending = factor(paste0('w/e ', ordinal(as.numeric(format(Week_ending, '%d'))), format(Week_ending, ' %b')), levels = deaths_labels$deaths_label)) %>% 
  pivot_wider(id_cols = c(Name, Week_ending),
              names_from = Cause,
              values_from = Deaths) %>% 
  mutate(`Non-Covid` = `All causes` - `COVID 19`) %>%
  select(-`All causes`) %>% 
  gather(key = 'Cause', value = 'Deaths', `COVID 19`:`Non-Covid`) %>% 
  mutate(Cause = factor(Cause, levels = rev(c('Non-Covid', 'COVID 19')))) %>% 
  mutate(lab_posit = ifelse(Cause == 'Non-Covid', 1.5, -1)) %>% 
  left_join(care_home_ons_all_deaths, by = c('Name', 'Week_ending'))

area_x_cov_non_cov_carehome <- carehome_weekly_deaths %>% 
  filter(Name == area_x)

area_x_wk_cause_deaths_plot_2 <- ggplot(area_x_cov_non_cov_carehome,
       aes(x = Week_ending, 
           y = Deaths,
           fill = Cause,
           colour = Cause,
           label = Deaths)) +
  geom_bar(stat = 'identity',
           colour = '#ffffff') +
  # geom_text(data = subset(area_x_cov_non_cov, Deaths > 0),
  #           position = 'stack',
  #           size = 3, 
  #           fontface = "bold",
  #           aes(vjust = lab_posit)) +
  labs(title = paste0('Weekly deaths in care homes; ', area_x,'; w/e 3rd Jan 2020 - ', deaths_labels$deaths_label[length(deaths_labels$deaths_label)]),
       subtitle = paste0('By week of occurrence and by Covid-19 mentioned on death certificate (deaths registered by ', format(max(deaths_labels$Week_ending) + 8, '%d %B %Y'), ')'),
       x = 'Week',
       y = 'Number of deaths') +
  scale_fill_manual(values = c('#ED7D31','#FFD966'),
                    labels = c('COVID-19', 'COVID not mentioned')) +
  scale_colour_manual(values = c('#000000', '#ffffff')) +
  scale_y_continuous(breaks = seq(0,max_deaths_limit, max_deaths_break),
                     limits = c(0,max_deaths_limit)) +
  ph_theme() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = .5),
        legend.position = 'bottom')  +
  guides(colour = FALSE)

png(paste0(output_directory_x, '/Covid_19_deaths_carehomes_', gsub(' ', '_', area_x), '.png'),
    width = 1580,
    height = 750,
    res = 200)
print(area_x_wk_cause_deaths_plot_2)
dev.off()

}

ltla_deaths_df <- weekly_all_place_deaths %>% 
  filter(Name != 'West Sussex')

max_deaths_limit <- ifelse(max(ltla_deaths_df$All_deaths, na.rm = TRUE) < 50, round_any(max(ltla_deaths_df$All_deaths, na.rm = TRUE), 5, ceiling), ifelse(max(ltla_deaths_df$All_deaths, na.rm = TRUE) < 100, round_any(max(ltla_deaths_df$All_deaths, na.rm = TRUE), 10, ceiling), ifelse(max(ltla_deaths_df$All_deaths, na.rm = TRUE) < 250, round_any(max(ltla_deaths_df$All_deaths, na.rm = TRUE), 25, ceiling), ifelse(max(ltla_deaths_df$All_deaths, na.rm = TRUE) < 500, round_any(max(ltla_deaths_df$All_deaths, na.rm = TRUE), 50, ceiling), round_any(max(ltla_deaths_df$All_deaths, na.rm = TRUE), 100, ceiling)))))

max_deaths_break <- ifelse(max(ltla_deaths_df$All_deaths, na.rm = TRUE) < 20, 2, ifelse(max(ltla_deaths_df$All_deaths, na.rm = TRUE) < 50, 5, ifelse(max(ltla_deaths_df$All_deaths, na.rm = TRUE) < 100, 10, ifelse(max(ltla_deaths_df$All_deaths, na.rm = TRUE) < 250, 25, ifelse(max(ltla_deaths_df$All_deaths, na.rm = TRUE) < 500, 50, 100)))))

ltla_deaths_plot_1 <- ggplot(ltla_deaths_df,
                          aes(x = Week_ending, 
                              y = Deaths,
                              fill = Cause,
                              colour = Cause,
                              label = Deaths)) +
  geom_bar(stat = 'identity',
           colour = '#ffffff') +
  # geom_text(data = subset(area_x_cov_non_cov, Deaths > 0),
  #           position = 'stack',
  #           size = 3, 
  #           fontface = "bold",
  #           aes(vjust = lab_posit)) +
  labs(title = paste0('Weekly deaths; w/e 3rd Jan 2020 - ', deaths_labels$deaths_label[length(deaths_labels$deaths_label)], '; West Sussex lower tier Local Authorities'),
       subtitle = paste0('By week of occurrence and by Covid-19 mentioned on death certificate (deaths registered by ', format(max(deaths_labels$Week_ending) + 8, '%d %B %Y'), ')'),
       x = 'Week',
       y = 'Number of deaths') +
    scale_fill_manual(values = c('#2F5597','#BDD7EE'),
                      labels = c('COVID-19', 'COVID not mentioned')) +
  scale_colour_manual(values = c('#000000', '#ffffff')) +
  scale_y_continuous(breaks = seq(0,max_deaths_limit, max_deaths_break),
                     limits = c(0,max_deaths_limit)) +
  ph_theme() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = .5),
        legend.position = 'bottom')  +
  guides(colour = FALSE) +
  facet_wrap(~Name, ncol = 3)

png(paste0(output_directory_x, '/Covid_19_deaths_wsx_ltlas.png'),
    width = 1580,
    height = 1050,
    res = 120)
print(ltla_deaths_plot_1)
dev.off()


ltla_deaths_df_2 <- carehome_weekly_deaths %>% 
  filter(Name != 'West Sussex')

ltla_deaths_plot_2 <- ggplot(ltla_deaths_df_2,
                             aes(x = Week_ending, 
                                 y = Deaths,
                                 fill = Cause,
                                 colour = Cause,
                                 label = Deaths)) +
  geom_bar(stat = 'identity',
           colour = '#ffffff') +
  # geom_text(data = subset(area_x_cov_non_cov, Deaths > 0),
  #           position = 'stack',
  #           size = 3, 
  #           fontface = "bold",
  #           aes(vjust = lab_posit)) +
  labs(title = paste0('Weekly deaths in care homes; w/e 3rd Jan 2020 - ', deaths_labels$deaths_label[length(deaths_labels$deaths_label)], '; West Sussex lower tier Local Authorities'),
       subtitle = paste0('By week of occurrence and by Covid-19 mentioned on death certificate (deaths registered by ', format(max(deaths_labels$Week_ending) + 8, '%d %B %Y'), ')'),
       x = 'Week',
       y = 'Number of deaths') +
  scale_fill_manual(values = c('#ED7D31','#FFD966'),
                    labels = c('COVID-19', 'COVID not mentioned')) +
  scale_colour_manual(values = c('#000000', '#ffffff')) +
  scale_y_continuous(breaks = seq(0,max_deaths_limit, max_deaths_break),
                     limits = c(0,max_deaths_limit)) +
  ph_theme() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = .5),
        legend.position = 'bottom')  +
  guides(colour = FALSE) +
  facet_wrap(~Name, ncol = 3)

png(paste0(output_directory_x, '/Covid_19_deaths_in_carehomes_wsx_ltlas.png'),
    width = 1580,
    height = 1050,
    res = 120)
print(ltla_deaths_plot_2)
dev.off()