# Weekly dashboard

library(easypackages)

libraries(c("readxl", "readr", "plyr", "dplyr", "ggplot2", "tidyverse", "reshape2", "scales", 'jsonlite', 'zoo', 'stats', 'fingertipsR', 'officer', 'lemon', 'spdplyr', 'geojsonio', 'rmapshaper', 'jsonlite', 'rgeos', 'sp', 'sf', 'maptools', 'png', 'epitools'))

github_repo_dir <- "~/Documents/Repositories/another_covid_repo"

capwords = function(s, strict = FALSE) {
  cap = function(s) paste(toupper(substring(s, 1, 1)),
                          {s = substring(s, 2); if(strict) tolower(s) else s},sep = "", collapse = " " )
  sapply(strsplit(s, split = " "), cap, USE.NAMES = !is.null(names(s)))}

options(scipen = 999)

hm_theme = function(){
  theme(
    axis.text.x = element_text(angle = 90, hjust = 0, vjust = 0),
    legend.position = "bottom",
    legend.text = element_text(colour = "#323232", size = 8),
    panel.background = element_rect(fill = "white"),
    plot.title = element_text(colour = "#000000", face = "bold", size = 9, vjust = 1),  
    legend.title = element_text(colour = "#323232", face = "bold", size = 9),
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank(),
    panel.grid.major.y = element_blank(),
    panel.grid.minor.y = element_blank(),
    legend.key.size = unit(0.65, "lines"),
    legend.background = element_rect(fill = "#ffffff"),
    legend.key = element_rect(fill = "#ffffff", colour = "#E2E2E3"),
    strip.text = element_text(colour = "#000000", face = "bold"),
    strip.background = element_rect(fill = "#ffffff"),
    axis.ticks.x = element_blank())
}

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

weekly_all_place_deaths <- read_csv(paste0(github_repo_dir, '/All_settings_deaths_occurrences.csv'))

# 01 March 2020 to 
dates_granular <- read_excel("~/Documents/Repositories/another_covid_repo/granular_mortality_file.xlsx", sheet = "Contents") %>% 
  filter(`Worksheet name` %in% c('Table 2', 'Table 5'))

la_asmr <- read_csv(paste0(github_repo_dir, '/mortality_01_march_to_date_la.csv'))

place_of_death <- read_csv(paste0(github_repo_dir, '/Mortality_place_of_death_weekly.csv'))
care_home_ons <- read_csv(paste0(github_repo_dir, '/Care_home_death_occurrences_ONS_weekly.csv'))
cqc_ch_deaths <- read_csv(paste0(github_repo_dir, '/cqc_care_home_daily_deaths.csv'))

daily_deaths_trust <- read_csv(paste0(github_repo_dir, '/daily_trust_deaths.csv'))
daily_trust_deaths_table <- read_csv(paste0(github_repo_dir, '/daily_trust_deaths_table.csv'))
meta_trust_deaths <- read_csv(paste0(github_repo_dir, '/meta_trust_deaths.csv'))

read_pptx(path = paste0(github_repo_dir, '/Death Slides - West Sussex V1.pptx'))

# Confirmed cases - context ####

daily_cases <- read_csv(paste0(github_repo_dir, '/ltla_sussex_daily_cases.csv')) %>% 
  mutate(Name = factor(Name, levels = rev(c('Brighton and Hove','East Sussex','Eastbourne', 'Hastings', 'Lewes','Rother','Wealden','West Sussex','Adur', 'Arun', 'Chichester','Crawley','Horsham','Mid Sussex', 'Worthing', 'South East region', 'England')))) %>% 
  mutate(new_case_key = factor(ifelse(New_cases == 0, 'No new cases', ifelse(New_cases >= 1 & New_cases <= 10, '1-10 cases', ifelse(New_cases >= 11 & New_cases <= 25, '11-25 cases', ifelse(New_cases >= 26 & New_cases <= 50, '26-50 cases', ifelse(New_cases >= 51 & New_cases <= 75, '51-75 cases', ifelse(New_cases >= 76 & New_cases <= 100, '76-100 cases', ifelse(New_cases >100, 'More than 100 cases', NA))))))), levels =  c('No new cases', '1-10 cases', '11-25 cases', '26-50 cases', '51-75 cases', '76-100 cases', 'More than 100 cases'))) %>%
  mutate(new_case_per_100000_key = factor(ifelse(New_cases_per_100000 < 0, 'Data revised down', ifelse(round(New_cases_per_100000,0) == 0, 'No new cases', ifelse(round(New_cases_per_100000,0) > 0 & round(New_cases_per_100000, 0) <= 2, '1-2 new cases per 100,000', ifelse(round(New_cases_per_100000,0) <= 4, '3-4 new cases per 100,000', ifelse(round(New_cases_per_100000,0) <= 6, '5-6 new cases per 100,000', ifelse(round(New_cases_per_100000,0) <= 8, '7-8 new cases per 100,000', ifelse(round(New_cases_per_100000,0) <= 10, '9-10 new cases per 100,000', ifelse(round(New_cases_per_100000,0) > 10, 'More than 10 new cases per 100,000', NA)))))))), levels =  c('No new cases', '1-2 new cases per 100,000', '3-4 new cases per 100,000', '5-6 new cases per 100,000', '7-8 new cases per 100,000', '9-10 new cases per 100,000', 'More than 10 new cases per 100,000'))) 

daily_cases %>% 
  group_by(new_case_per_100000_key) %>% 
  summarise(n())

# PHE say the last five data points are incomplete (perhaps they should not publish them). Instead, we need to make sure we account for this so that it is not misinterpreted.
complete_date <- max(daily_cases$Date) - 5
complete_period <- format(complete_date, '%d %B')

# Latest
case_summary_latest <- daily_cases %>% 
  filter(Date == max(Date)) %>% 
  select(Name, Cumulative_cases, Cumulative_per_100000, Three_day_average_cumulative_cases) %>% 
  rename(`Total confirmed cases so far` = Cumulative_cases,
         `Total cases per 100,000 population` = Cumulative_per_100000,
         `Three day average cumulative cases` = Three_day_average_cumulative_cases)

case_summary_complete <- daily_cases %>% 
  filter(Date == complete_date) %>% 
  select(Name, New_cases, New_cases_per_100000, Three_day_average_new_cases) %>% 
  rename(`Confirmed cases swabbed on most recent complete day` = New_cases,
         `Confirmed cases swabbed per 100,000 population on most recent complete day` = New_cases_per_100000,
         `Average number of confirmed cases tested in past three complete days` = Three_day_average_new_cases) 

doubling_time_df_summary <- daily_cases %>% 
  filter(period_in_reverse %in% c(1,2)) %>% 
  arrange(-period_in_reverse) %>% 
  select(Name, date_range_label, Double_time) %>% 
  unique() %>% 
  spread(date_range_label, Double_time)

case_summary <- case_summary_latest %>% 
  left_join(case_summary_complete, by = 'Name') %>% 
  left_join(doubling_time_df_summary, by = 'Name') %>% 
  arrange(Name) %>% 
  mutate(Name = factor(Name, levels = unique(Name))) %>% 
  mutate(`Rate of growth in cases` = ifelse(.[[8]] > .[[9]], 'Slowing', ifelse(.[[8]] < .[[9]], 'Speeding up', NA))) %>% 
  mutate_at(vars(2,5), funs(format(., big.mark = ',', trim = TRUE))) %>% 
  mutate_at(vars(3,4,6,7), funs(format(round(.,0), big.mark = ',', trim = TRUE))) %>% 
  mutate_at(vars(8,9), funs(paste0(format(round(.,1), big.mark = ',', trim = TRUE),' days'))) %>% 
  mutate(highlight = ifelse(Name %in% c('West Sussex', 'Brighton and Hove', 'East Sussex'), 'bold', 'plain'))

new_case_rate_plot <- ggplot(daily_cases, aes(x = Date,
                           y = Name,
                           fill = new_case_per_100000_key)) +
  scale_fill_manual(values = c('#ffffb2','#fed976','#feb24c','#fd8d3c','#fc4e2a','#e31a1c','#b10026'),
                    name = 'Tile colour\nkey',
                    drop = FALSE) +
  geom_tile(colour = "#ffffff") +
  labs(x = NULL,
       y = NULL) +
  scale_x_date(date_labels = "%b %d",
               breaks = seq.Date(max(daily_cases$Date) -(52*7), max(daily_cases$Date), by = 7),
               limits = c(min(daily_cases$Date), max(daily_cases$Date)),
               expand = c(0,0.0)) +
  scale_y_discrete(position = 'right') +
  hm_theme() +
  theme(axis.text.y = element_text(colour = "#323232", face = case_summary$highlight, size = 8)) +
  # theme(axis.text.y = element_blank()) +
  theme(legend.position = 'none')

case_title = paste0('Summary of new confirmed Covid-19 cases per 100,000 population (all ages); ', format(min(daily_cases$Date), '%d %B'), ' to ',format(max(daily_cases$Date), '%d %B'))

png(paste0(github_repo_dir, "/new_case_rate_plot.png"), width = 680, height = 500, res = 120)
new_case_rate_plot
dev.off()

case_summary %>%
  arrange(rev(Name)) %>%
  select(-c(`Total cases per 100,000 population`,highlight)) %>%
  write.csv(., paste0(github_repo_dir, '/case_summary.csv'), row.names = FALSE, na = '')

utla_daily_cases <- daily_cases %>% 
  filter(Name %in% c('Brighton and Hove', 'East Sussex', 'West Sussex')) %>% 
  filter(Days_since_case_x >= 0)

ggplot(utla_daily_cases,
       aes(x = Days_since_case_x,
           y = Cumulative_cases,
           group = Name,
           colour = Name)) +
    geom_point(aes(x = Days_since_case_x,
                   y = Cumulative_cases,
                   group = Name),
             size = 3,
             colour = '#ffffff',
             shape = 21) +
  labs(title = paste0('Cumulative confirmed Covid-19 cases over timel days since case 10; linear scale'),
       x = 'Days since case 10',
       y = 'Number of deaths') +
  scale_fill_manual(values = c("#92D050", "#FFC000","#C00000"),
                    name = '') +
  scale_y_continuous(breaks = seq(0,round_any(max(utla_daily_cases$Cumulative_cases, na.rm = TRUE), 250, ceiling),100),
                     limits = c(0,round_any(max(utla_daily_cases$Cumulative_cases, na.rm = TRUE), 250, ceiling))) +
  ph_theme() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = .5),
        legend.key.size = unit(0.5, "lines")) 

# Deaths slides ####

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
  mutate(Place_of_death = factor(Place_of_death, levels = rev(c("Home", "Care home", "Hospital", "Hospice", 'Elsewhere (including other communal establishments)')))) %>% 
  group_by(Week_number, Name) %>% 
  mutate(Deaths_proportion = Deaths / sum(Deaths)) %>% 
  ungroup()

 
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

png(paste0(github_repo_dir, "/wsx_place_death_all_cause_plot_no_leg.png"), width = 480, height = 250)
wsx_place_death_all_cause_plot +
  theme(legend.position = 'bottom')
dev.off()

wsx_place_death_all_cause_proportion_plot <- ggplot(wsx_place,
         aes(x = Week_ending, 
         y = Deaths_proportion,
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
  scale_y_continuous(breaks = seq(0,1,.2),
                     limits = c(0,1),
                     labels = percent) +
  ph_theme() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = .5),
        legend.key.size = unit(0.5, "lines")) +
  guides(fill = guide_legend(nrow = 2, byrow = TRUE))

png(paste0(github_repo_dir, "/wsx_place_death_all_cause_proportion_plot.png"), width = 480, height = 250)
wsx_place_death_all_cause_proportion_plot
dev.off()

latest_wsx_place <- wsx_place %>% 
  filter(Week_number == max(Week_number)) %>% 
  arrange(Place_of_death) %>% 
  mutate(cumulative = cumsum(Deaths),
         pos = lag(cumulative) + Deaths/2) %>% 
  mutate(pos = ifelse(is.na(pos), cumulative/2, pos)) %>% 
  mutate(pos = sum(Deaths) - pos) %>% 
  mutate(Place_label = paste0(Place_of_death, ' (', format(Deaths, big.mark = ',', trim = TRUE), ' deaths)')) %>% 
  mutate(Place_label = factor(Place_label, levels = unique(Place_label)))
  
latest_place_death <- ggplot(latest_wsx_place, aes(x = 2, 
                             y = Deaths, 
                             fill = Place_label,
                             colour = "#ffffff")) +
  geom_bar(stat="identity") +
  geom_text(data = subset(latest_wsx_place, Deaths > 10), 
            aes(label = format(Deaths,big.mark = ","), 
                y = pos), 
            size = 4, 
            colour = "#000000", 
            fontface="bold") +
  xlim(.5, 2.5) +
  coord_polar(theta = "y", start = 0, direction = 1) +
  labs(x = '', 
       y = '')+
  scale_fill_manual(values = rev(c("#f6de6c", "#ed8a46", "#be3e2b","#34738f", '#4837bc')),
                    breaks = rev(levels(latest_wsx_place$Place_label)),
                    name = '') +
  scale_colour_manual(values= "#ffffff", guide = FALSE) +
  geom_text(aes(label = paste0("Deaths in\n", Name, '\n', Week_ending, '\n', format(sum(Deaths),big.mark = ","), sep = ""),hjust = .5, vjust = 2, y= 0), size = 5, colour = "#000000")+
  theme_bw()+
  theme(axis.ticks=element_blank(),
        axis.text=element_blank(),
        axis.title=element_blank(),
        panel.grid=element_blank(),
        panel.border=element_blank(),
        legend.position = 'bottom',
        legend.key.size = unit(0.5, "lines"),
        legend.text = element_text(size = 15),
        legend.margin=margin(0,0,0,0),
        legend.box.margin=margin(0,0,0,0)) +
  guides(fill = guide_legend(nrow = 5, byrow = TRUE))
 
png(paste0(github_repo_dir, "/latest_place_death.png"), width = 1500, height = 1500, res = 220)
latest_place_death
dev.off()

wsx_place_table_n <- wsx_place %>% 
  select(Week_ending, Place_of_death, Deaths) %>% 
  spread(Week_ending, Deaths) %>% 
  arrange(rev(Place_of_death)) %>% 
  write.csv(., paste0(github_repo_dir, '/wsx_place_table_n.csv'), row.names = FALSE, na = '')

wsx_place_table_p <- wsx_place %>% 
  select(Week_ending, Place_of_death, Deaths_proportion) %>% 
  mutate(Deaths_proportion = paste0(round(Deaths_proportion * 100, 1),'%')) %>% 
  spread(Week_ending, Deaths_proportion) %>% 
  arrange(rev(Place_of_death)) %>% 
  write.csv(., paste0(github_repo_dir, '/wsx_place_table_p.csv'), row.names = FALSE, na = '')

# png("./Alcohol/DBIU_referral_1617_Plot.png", height = 1420, width = 2591, res = 100, pointsize = 12)

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

# Extra - rate covid 19

covid_19_rate <- weekly_all_place_deaths %>% 
  filter(Name %in% c('West Sussex', 'Brighton and Hove', 'East Sussex', 'Sussex areas combined', 'England')) %>% 
  filter(Cause == 'COVID 19') %>% 
  mutate(Week_ending = factor(paste0('w/e ', ordinal(as.numeric(format(Week_ending, '%d'))), format(Week_ending, ' %b')), levels = date_labels)) %>% 
  select(Name, Week_ending, Deaths_crude_rate_per_100000, Deaths_crude_rate_lci, Deaths_crude_rate_uci)

England_covid_rate <- covid_19_rate %>% 
  filter(Name == 'England') %>% 
  rename(England = Name,
         Eng_deaths_rate = Deaths_crude_rate_per_100000,
         Eng_lci = Deaths_crude_rate_lci,
         Eng_uci = Deaths_crude_rate_uci) %>% 
  select(Week_ending, Eng_deaths_rate, Eng_lci, Eng_uci)

covid_19_rate_df <- covid_19_rate %>% 
  filter(Name != 'England') %>% 
  mutate(Name = factor(Name, levels = c('Brighton and Hove', 'East Sussex', 'West Sussex','Sussex areas combined'))) %>% 
  left_join(England_covid_rate, by = 'Week_ending') %>% 
  mutate(significance = factor(ifelse(Deaths_crude_rate_uci < Eng_lci, 'Significantly lower', ifelse(Deaths_crude_rate_lci > Eng_uci, 'Significantly higher', 'Statistically similar')), levels = c('Significantly lower', 'Statistically similar', 'Significantly higher')))

crude_rate_plot_covid <-ggplot(covid_19_rate_df) +
  geom_line(data = England_covid_rate, aes(x = Week_ending, y = Eng_deaths_rate, group = '1'), colour = '#777777') +
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
  labs(title = paste0('Weekly Covid-19 deaths per 100,000 population; w/e 3rd Jan 2020 - ', latest_we$Week_ending),
       subtitle = 'By week of occurrence',
       caption = 'Reference line = England',
       x = 'Week',
       y = 'Number of deaths\nper 100,000') +
  scale_fill_manual(values = c("#92D050", "#FFC000","#C00000"),
                    breaks = c('Significantly lower','Statistically similar','Significantly higher'),
                    name = 'Compared\nto England',
                    drop = FALSE) +
  scale_y_continuous(breaks = seq(0,round_any(max(covid_19_rate_df$Deaths_crude_rate_uci, na.rm = TRUE), 55, ceiling), 5),
                     limits = c(0,round_any(max(covid_19_rate_df$Deaths_crude_rate_uci, na.rm = TRUE), 10, ceiling))) +
  ph_theme() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = .5),
        legend.key.size = unit(0.5, "lines")) +
  facet_rep_grid(Name ~ .) +
  theme(strip.text = element_blank()) +
  annotate(geom = "text", label = levels(covid_19_rate_df$Name), x = 1, y = round_any(max(covid_19_rate_df$Deaths_crude_rate_uci, na.rm = TRUE), 10, ceiling)-5, size = 3, fontface = "bold", hjust = 0)

png(paste0(github_repo_dir, "/crude_rate_plot_covid.png"), width = 1600, height = 1450, res = 250)
crude_rate_plot_covid
dev.off()

# change last two weeks tables ####

latest_cumulative_covid_deaths <- weekly_all_place_deaths %>% 
  filter(Name %in% c('West Sussex', 'Brighton and Hove', 'East Sussex', 'Sussex areas combined', 'England')) %>% 
  filter(Cause == 'COVID 19') %>% 
  filter(Week_number == max(Week_number)) %>% 
  mutate(Cumulative_crude_rate_lci = pois.exact(Cumulative_deaths, All_ages)[[4]]*100000) %>% 
  mutate(Cumulative_crude_rate_uci = pois.exact(Cumulative_deaths, All_ages)[[5]]*100000) %>% 
  mutate(Cumulative_rate_label = paste0(round(Cumulative_crude_rate_per_100000,1), ' (', round(Cumulative_crude_rate_lci, 1), '-', round(Cumulative_crude_rate_uci, 1), ')')) %>% 
  mutate(Cumulative_deaths = format(Cumulative_deaths, big.mark = ',', trim = TRUE)) %>% 
  select(Name, Cumulative_deaths, Cumulative_rate_label) %>% 
  rename(`Latest cumulative total` = Cumulative_deaths,
         `Latest cumulative rate per 100,000` = Cumulative_rate_label)

total_covid_deaths_table <- weekly_all_place_deaths %>% 
  filter(Name %in% c('West Sussex', 'Brighton and Hove', 'East Sussex', 'Sussex areas combined', 'England')) %>% 
  mutate(Name = factor(Name, levels = c('Brighton and Hove', 'East Sussex','West Sussex', 'Sussex areas combined', 'England'))) %>% 
  filter(Cause == 'COVID 19') %>% 
  mutate(Week_ending = factor(paste0('w/e ', ordinal(as.numeric(format(Week_ending, '%d'))), format(Week_ending, ' %b')), levels = date_labels)) %>% 
  filter(Week_number %in% c(max(Week_number), max(Week_number) -1)) %>% 
  select(Name, Week_ending, Deaths) %>% 
  spread(Week_ending, Deaths) %>% 
  mutate(`Change (N)` = format(.[[3]] - .[[2]], big.mark = ',', trim = TRUE)) %>% 
  mutate(`Change (%)` = paste0(round((.[[3]] - .[[2]]) / .[[2]] * 100, 1), '%')) %>% 
  mutate_at(vars(2:3), funs(format(., big.mark = ','))) %>%
  left_join(latest_cumulative_covid_deaths, by = 'Name')

total_covid_deaths_table %>% 
  write.csv(., paste0(github_repo_dir, '/total_covid_deaths_change_table.csv'), row.names = FALSE, na = '')

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

# slide 4 - msoa for sussex between 01 March and two weeks prior ####

# msoa_boundaries
lookup_msoa_la <- read_csv('https://opendata.arcgis.com/datasets/fe6c55f0924b4734adf1cf7104a0173e_0.csv') %>% 
  select(MSOA11CD, LAD17CD, LAD17NM, LACNM) %>% 
  filter(LAD17NM %in% c('Adur', 'Arun', 'Chichester','Crawley','Horsham','Mid Sussex','Worthing','Brighton and Hove', 'Eastbourne', 'Hastings', 'Lewes', 'Rother', 'Wealden')) %>% 
  unique()


msoa_deaths <- read_csv(paste0(github_repo_dir, '/mortality_01_march_to_date_msoa.csv')) %>% 
  rename(All_cause_deaths = 'All causes',
         Covid_19_mentioned = 'COVID-19',
         Proportion_covid_19 = 'COVID-19 deaths as a percentage of all causes (%)',
         msoa11cd = 'MSOA code',
         msoa11nm = 'MSOA name') %>% 
  filter(msoa11cd %in% lookup_msoa_la$MSOA11CD) %>% 
  mutate(all_cause_bins = factor(ifelse(All_cause_deaths == 0, 'None', ifelse(All_cause_deaths <= 5, '1-5 deaths', ifelse(All_cause_deaths <= 15, '6-15', ifelse(All_cause_deaths <= 25, '16-25', ifelse(All_cause_deaths <= 35, '26-35', ifelse(All_cause_deaths <= 45, '36-45', NA)))))), levels = c('None', '1-5 deaths', '6-15', '16-25','26-35','36-45'))) %>% 
  mutate(covid_mentioned_bins = factor(ifelse(Covid_19_mentioned == 0, 'None', ifelse(Covid_19_mentioned <= 5, '1-5 deaths', ifelse(Covid_19_mentioned <= 10, '6-10', ifelse(Covid_19_mentioned <= 15, '11-15', NA)))), levels = c('None', '1-5 deaths', '6-10', '11-15'))) %>% 
  mutate(Proportion_covid_bins = factor(ifelse(is.na(Proportion_covid_19), 'None', ifelse(Proportion_covid_19 == 0, 'None', ifelse(Proportion_covid_19 <= 20, '1-20% of deaths', ifelse(Proportion_covid_19 <= 40, '21-40%', ifelse(Proportion_covid_19 <= 60, '41-60%', ifelse(Proportion_covid_19 <= 80, '61-80%', ifelse(Proportion_covid_19 <= 100, '81-100%', NA))))))), levels = c('None', '1-20% of deaths', '21-40%','41-60%','61-80%','81-100%')))

summary(msoa_deaths$All_cause_deaths)
summary(msoa_deaths$Covid_19_mentioned)
summary(msoa_deaths$Proportion_covid_19)

County_boundary <- geojson_read("https://opendata.arcgis.com/datasets/b216b4c8a4e74f6fb692a1785255d777_0.geojson",  what = "sp") %>% 
  filter(ctyua19nm %in% c('West Sussex', 'East Sussex','Brighton and Hove')) %>% 
  fortify(region = "ctyua19nm") %>% 
  rename(ctyua19nm = id) 

msoa_spdf <- geojson_read("https://opendata.arcgis.com/datasets/c661a8377e2647b0bae68c4911df868b_3.geojson",  what = "sp") %>% 
  filter(msoa11cd %in% lookup_msoa_la$MSOA11CD)

# ggplot needs the data to be in a single dataframe. The fortify command does this

msoa_fortified <- fortify(msoa_spdf, region = "msoa11cd") %>% 
  rename(msoa11cd = id) %>% # The LSOA code is there by a different name (id), so we renamed it back again
  left_join(msoa_deaths, by = 'msoa11cd')

map_theme = function(){
  theme( 
    plot.background = element_blank(), 
    panel.background = element_blank(),  
    panel.border = element_blank(),
    axis.text = element_blank(), 
    plot.title = element_text(colour = "#000000", face = "bold", size = 8), 
    axis.title = element_blank(),     
    panel.grid.major.x = element_blank(), 
    panel.grid.minor.x = element_blank(), 
    panel.grid.major.y = element_blank(), 
    panel.grid.minor.y = element_blank(), 
    strip.text = element_text(colour = "white"), 
    strip.background = element_rect(fill = "#327d9c"), 
    axis.ticks = element_blank() 
  ) 
} 

msoa_total_title <- as.character(dates_granular %>% 
                             filter(`Worksheet name` == 'Table 5') %>% 
                             select(Content)) %>% 
  gsub('England and Wales, ', 'Sussex, all ', .)

total_msoa_deaths_plot <- ggplot() +
  geom_polygon(data = msoa_fortified, 
               aes(x = long, 
                   y = lat, 
                   group = group,
                   fill= all_cause_bins),
               color= '#ffffff',
               size = .1) +
  coord_fixed(1.5) + 
  map_theme() +
  labs(title = msoa_total_title) +
  scale_fill_manual(values = c('#feebe2','#fcc5c0','#fa9fb5','#f768a1','#c51b8a','#7a0177'),
                    name = 'Total deaths') +
  geom_polygon(data = County_boundary, aes(x=long, y=lat, group = group), 
               color="#000000", 
               fill = NA, 
               size = .8, 
               show.legend = FALSE) +
  theme(legend.position = 'bottom',
        legend.title = element_text(size = 9, face = "bold"),
        legend.key.width = unit(0.2,"cm"),
        legend.key.height = unit(0.2,"cm")) 

png(paste0(github_repo_dir, "/total_msoa_deaths_plot.png"), width = 2600, height = 1450, res = 350)
total_msoa_deaths_plot
dev.off()

msoa_covid_title <- as.character(dates_granular %>% 
                                   filter(`Worksheet name` == 'Table 5') %>% 
                                   select(Content)) %>% 
  gsub('England and Wales, ', 'Sussex, Covid-19 ', .)

covid_msoa_deaths_plot <- ggplot() +
  geom_polygon(data = msoa_fortified, 
               aes(x = long, 
                   y = lat, 
                   group = group,
                   fill= covid_mentioned_bins),
               color= '#ffffff',
               size = .1) +
  coord_fixed(1.5) + 
  map_theme() +
  labs(title = msoa_covid_title) +
  scale_fill_manual(values = c('#ffffb2','#fecc5c','#fd8d3c','#e31a1c'),
                    name = 'Deaths where Covid-19\nmentioned') +
  geom_polygon(data = County_boundary, aes(x=long, y=lat, group = group), 
               color="#000000", 
               fill = NA, 
               size = .8, 
               show.legend = FALSE) +
  theme(legend.position = 'bottom',
        legend.title = element_text(size = 9, face = "bold"),
        legend.key.width = unit(0.2,"cm"),
        legend.key.height = unit(0.2,"cm")) 

png(paste0(github_repo_dir, "/covid_msoa_deaths_plot.png"), width = 2600, height = 1450, res = 350)
covid_msoa_deaths_plot
dev.off()

msoa_prop_covid_title <- as.character(dates_granular %>% 
                                   filter(`Worksheet name` == 'Table 5') %>% 
                                   select(Content)) %>% 
  gsub('Number of deaths by Middle Layer Super Output Area', 'Proportion of deaths where Covid-19 mentioned by MSOA', .) %>% 
  gsub('England and Wales, ', 'Sussex, ', .)

covid_msoa_prop_deaths_plot <- ggplot() +
  geom_polygon(data = msoa_fortified, 
               aes(x = long, 
                   y = lat, 
                   group = group,
                   fill= Proportion_covid_bins),
               color= '#ffffff',
               size = .1) +
  coord_fixed(1.5) + 
  map_theme() +
  labs(title = msoa_prop_covid_title) +
  scale_fill_manual(values = c('#ffffcc','#d9f0a3','#addd8e','#78c679','#31a354','#006837'),
                    name = 'Deaths where Covid-19\nmentioned') +
  geom_polygon(data = County_boundary, aes(x=long, y=lat, group = group), 
               color="#000000", 
               fill = NA, 
               size = .8, 
               show.legend = FALSE) +
  theme(legend.position = 'bottom',
        legend.title = element_text(size = 9, face = "bold"),
        legend.key.width = unit(0.2,"cm"),
        legend.key.height = unit(0.2,"cm")) 

png(paste0(github_repo_dir, "/covid_msoa_prop_deaths_plot.png"), width = 2600, height = 1450, res = 350)
covid_msoa_prop_deaths_plot
dev.off()

# slide 5 - deaths in care homes

covid_19_rate_care_home <- care_home_ons %>% 
  filter(Name %in% c('West Sussex', 'Brighton and Hove', 'East Sussex', 'Sussex areas combined', 'England')) %>% 
  filter(Cause == 'COVID 19') %>% 
  mutate(Week_ending = factor(paste0('w/e ', ordinal(as.numeric(format(Week_ending, '%d'))), format(Week_ending, ' %b')), levels = date_labels)) %>% 
  select(Name, Week_ending, Deaths_crude_rate_per_1000_care_home_beds, Deaths_crude_rate_lci, Deaths_crude_rate_uci)

England_covid_rate_ch <- covid_19_rate_care_home %>% 
  filter(Name == 'England') %>% 
  rename(England = Name,
         Eng_deaths_rate = Deaths_crude_rate_per_1000_care_home_beds,
         Eng_lci = Deaths_crude_rate_lci,
         Eng_uci = Deaths_crude_rate_uci) %>% 
  select(Week_ending, Eng_deaths_rate, Eng_lci, Eng_uci)

covid_19_rate_care_home_df <- covid_19_rate_care_home %>% 
  filter(Name != 'England') %>% 
  mutate(Name = factor(Name, levels = c('Brighton and Hove', 'East Sussex', 'West Sussex','Sussex areas combined'))) %>% 
  left_join(England_covid_rate_ch, by = 'Week_ending') %>% 
  mutate(significance = factor(ifelse(Deaths_crude_rate_uci < Eng_lci, 'Significantly lower', ifelse(Deaths_crude_rate_lci > Eng_uci, 'Significantly higher', 'Statistically similar')), levels = c('Significantly lower', 'Statistically similar', 'Significantly higher')))

crude_rate_care_home_plot_covid <-ggplot(covid_19_rate_care_home_df) +
  geom_line(data = England_covid_rate_ch, aes(x = Week_ending, y = Eng_deaths_rate, group = '1'), colour = '#777777') +
  geom_line(aes(x = Week_ending,
                y = Deaths_crude_rate_per_1000_care_home_beds,
                group = Name)) +
  geom_point(aes(x = Week_ending,
                 y = Deaths_crude_rate_per_1000_care_home_beds,
                 fill = significance,
                 group = Name),
             size = 3,
             colour = '#ffffff',
             shape = 21) +
  labs(title = paste0('Weekly Covid-19 deaths per 1,000 care home beds; w/e 3rd Jan 2020 - ', latest_we$Week_ending),
       subtitle = 'By week of occurrence',
       caption = 'Reference line = England',
       x = 'Week',
       y = 'Number of deaths\nper 1,000 care home beds') +
  scale_fill_manual(values = c("#92D050", "#FFC000","#C00000"),
                    breaks = c('Significantly lower','Statistically similar','Significantly higher'),
                    name = 'Compared\nto England',
                    drop = FALSE) +
  scale_y_continuous(breaks = seq(0,round_any(max(covid_19_rate_care_home_df$Deaths_crude_rate_uci, na.rm = TRUE), 2, ceiling), 2),
                     limits = c(0,round_any(max(covid_19_rate_care_home_df$Deaths_crude_rate_uci, na.rm = TRUE), 5, ceiling))) +
  ph_theme() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = .5),
        legend.key.size = unit(0.5, "lines")) +
  facet_rep_grid(Name ~ .) +
  theme(strip.text = element_blank()) +
  annotate(geom = "text", label = levels(covid_19_rate_care_home_df$Name), x = 1, y = round_any(max(covid_19_rate_care_home_df$Deaths_crude_rate_uci, na.rm = TRUE), 10, ceiling)-2, size = 3, fontface = "bold", hjust = 0)

png(paste0(github_repo_dir, "/crude_rate_care_home_plot_covid.png"), width = 1600, height = 1450, res = 250)
crude_rate_care_home_plot_covid
dev.off()

# change last two weeks tables care homes ####

names(latest_cumulative_covid_deaths_ch)

latest_cumulative_covid_deaths_ch <- care_home_ons %>% 
  filter(Name %in% c('West Sussex', 'Brighton and Hove', 'East Sussex', 'Sussex areas combined', 'England')) %>% 
  filter(Cause == 'COVID 19') %>% 
  filter(Week_number == max(Week_number)) %>% 
  mutate(Cumulative_rate_label = paste0(round(Cumulative_deaths_crude_rate_per_1000_care_home_beds,1), ' (', round(Cumulative_deaths_crude_rate_lci, 1), '-', round(Cumulative_deaths_crude_rate_uci, 1), ')')) %>% 
  mutate(Cumulative_deaths = format(Cumulative_deaths, big.mark = ',', trim = TRUE)) %>% 
  select(Name, Cumulative_deaths, Cumulative_rate_label) %>% 
  rename(`Latest cumulative total` = Cumulative_deaths,
         `Latest cumulative rate per 1,000 beds` = Cumulative_rate_label)

total_covid_deaths_table_ch <- care_home_ons %>% 
  filter(Name %in% c('West Sussex', 'Brighton and Hove', 'East Sussex', 'Sussex areas combined', 'England')) %>% 
  mutate(Name = factor(Name, levels = c('Brighton and Hove', 'East Sussex','West Sussex', 'Sussex areas combined', 'England'))) %>% 
  filter(Cause == 'COVID 19') %>% 
  mutate(Week_ending = factor(paste0('w/e ', ordinal(as.numeric(format(Week_ending, '%d'))), format(Week_ending, ' %b')), levels = date_labels)) %>% 
  filter(Week_number %in% c(max(Week_number), max(Week_number) -1)) %>% 
  select(Name, Week_ending, Deaths) %>% 
  spread(Week_ending, Deaths) %>% 
  mutate(`Change (N)` = format(.[[3]] - .[[2]], big.mark = ',', trim = TRUE)) %>% 
  mutate(`Change (%)` = paste0(round((.[[3]] - .[[2]]) / .[[2]] * 100, 1), '%')) %>% 
  mutate_at(vars(2:3), funs(format(., big.mark = ',', trim = TRUE))) %>%
  left_join(latest_cumulative_covid_deaths_ch, by = 'Name')

total_covid_deaths_table_ch %>% 
  write.csv(., paste0(github_repo_dir, '/total_covid_deaths_table_ch.csv'), row.names = FALSE, na = '')

# daily care home view
local_cqc_ch <- cqc_ch_deaths %>% 
  filter(Name %in% c('West Sussex', 'Brighton and Hove', 'East Sussex', 'England'))

sussex_cqc_ch <- cqc_ch_deaths %>% 
  filter(Name %in% c('West Sussex', 'Brighton and Hove', 'East Sussex')) %>% 
  group_by(Date) %>% 
  summarise(`All cause` = sum(`All cause`, na.rm = TRUE),
            `Covid-19 Deaths` = sum(`Covid-19 Deaths`, na.rm = TRUE)) %>% 
  mutate(Name = 'Sussex areas combined')

cqc_deaths <- local_cqc_ch %>%
  bind_rows(sussex_cqc_ch) %>% 
  mutate(Name = factor(Name, levels = c('Brighton and Hove', 'East Sussex','West Sussex', 'Sussex areas combined', 'England'))) %>% 
  mutate(`Non-Covid-19 Deaths` = `All cause` - `Covid-19 Deaths`) %>% 
  mutate(Proportion_covid = `Covid-19 Deaths`/`All cause`) %>% 
  group_by(Name) %>% 
  arrange(Name, Date) %>% 
  mutate(Cumulative_all_cause = cumsum(`All cause`),
         Cumulative_covid = cumsum(`Covid-19 Deaths`),
         Cumulative_non_covid = cumsum(`Non-Covid-19 Deaths`)) %>% 
  ungroup()

wsx_cqc_deaths <- cqc_deaths %>% 
  filter(Name == 'West Sussex') 

last_daily_cqc_date = paste0(ordinal(as.numeric(format(max(wsx_cqc_deaths$Date), '%d'))), ' ', format(max(wsx_cqc_deaths$Date), '%b %Y'))

# all cause bars daily deaths
wsx_daily_care_home_all_deaths_plot <- ggplot(wsx_cqc_deaths,
       aes(x = Date,
           y = `All cause`)) +
  geom_bar(stat = 'identity',
         fill = '#70AD47') +
  labs(title = paste0('Daily all cause care home deaths; by date of notification to CQC; West Sussex; 10th Apr - ', last_daily_cqc_date),
       # subtitle = 'Where Covid-19 is suspected or confirmed as cause',
       x = 'Date',
       y = 'Number of deaths') +
  scale_y_continuous(breaks = seq(0,round_any(max(wsx_cqc_deaths$`All cause`, na.rm = TRUE), 15, ceiling), 5),
                     limits = c(0,round_any(max(wsx_cqc_deaths$`All cause`, na.rm = TRUE), 15, ceiling))) +
  scale_x_date(date_labels = "%b %d (%A)",
               date_breaks = '1 day',
               # date_minor_breaks = '1 day',
               expand = c(0,.5)) +
  ph_theme() +
  annotate(geom = "text", 
           x = wsx_cqc_deaths$Date,
           y = wsx_cqc_deaths$`All cause`,
           label = wsx_cqc_deaths$`All cause`,
           size = 3, 
           fontface = "bold",
           vjust = -1) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = .5)) 

png(paste0(github_repo_dir, "/wsx_daily_care_home_all_deaths_plot.png"), width = 580, height = 250)
wsx_daily_care_home_all_deaths_plot
dev.off()

wsx_cqc_deaths_stack <- cqc_deaths %>%
  filter(Name == 'West Sussex') %>%
  select(Name, Date, `Covid-19 Deaths`, `Non-Covid-19 Deaths`) %>%
  rename(`COVID 19` = `Covid-19 Deaths`, 
         `Non-Covid` = `Non-Covid-19 Deaths`) %>% 
  gather(key = 'Cause', value = 'Deaths', `COVID 19`:`Non-Covid`) %>%
  mutate(Cause = factor(Cause, levels = rev(c('Non-Covid', 'COVID 19')))) %>%
  mutate(lab_posit = ifelse(Cause == 'Non-Covid', 1.5, -1))

wsx_daily_cause_ch_deaths_plot <- ggplot(wsx_cqc_deaths_stack,
       aes(x = Date,
       y = Deaths,
       fill = Cause,
       colour = Cause,
       label = Deaths)) +
  geom_bar(stat = 'identity',
           colour = '#ffffff') +
  geom_text(data = subset(wsx_cqc_deaths_stack, Deaths > 0),
            position = 'stack',
            size = 3,
            fontface = "bold",
            aes(vjust = lab_posit)) +
  labs(title = paste0('Daily care home deaths by cause; by date of notification to CQC; West Sussex; 10th Apr - ', last_daily_cqc_date),
       subtitle = 'Where Covid-19 is suspected or confirmed as cause',
       x = 'Date',
       y = 'Number of deaths') +
  scale_y_continuous(breaks = seq(0,round_any(max(wsx_cqc_deaths$`All cause`, na.rm = TRUE), 15, ceiling), 5),
                     limits = c(0,round_any(max(wsx_cqc_deaths$`All cause`, na.rm = TRUE), 15, ceiling)),
                     expand = c(0,0.1)) +
  scale_x_date(date_labels = "%b %d (%A)",
               date_breaks = '1 day',
               # date_minor_breaks = '1 day',
               expand = c(0,.1)) +
  scale_fill_manual(values = c('#006d90','#003343')) +
  scale_colour_manual(values = c('#000000', '#ffffff')) +
  ph_theme() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = .5),
        legend.position = c(.1,.8))  +
  guides(colour = FALSE)

png(paste0(github_repo_dir, "/wsx_daily_cause_ch_deaths_plot.png"), width = 580, height = 250)
wsx_daily_cause_ch_deaths_plot
dev.off()

cumulative_wsx_deaths_cqc <- cqc_deaths %>%
  filter(Name == 'West Sussex') %>%
  select(Name, Date, Cumulative_covid, Cumulative_non_covid) %>%
  rename(`COVID 19` = Cumulative_covid, 
         `Non-Covid` = Cumulative_non_covid) %>% 
  gather(key = 'Cause', value = 'Deaths', `COVID 19`:`Non-Covid`) %>%
  mutate(Cause = factor(Cause, levels = rev(c('Non-Covid', 'COVID 19')))) %>%
  mutate(lab_posit = ifelse(Cause == 'Non-Covid', 1.5, -1))

wsx_cumulative_cqc_cause_ch_deaths_plot <- ggplot(cumulative_wsx_deaths_cqc,
       aes(x = Date,
           y = Deaths,
           fill = Cause,
           colour = Cause,
           label = Deaths)) +
  geom_bar(stat = 'identity',
           colour = '#ffffff') +
  geom_text(data = subset(cumulative_wsx_deaths_cqc, Deaths > 0),
            position = 'stack',
            size = 3,
            fontface = "bold",
            aes(vjust = lab_posit)) +
  labs(title = paste0('Cumulative care home deaths by cause; by date of notification to CQC; West Sussex; 10th Apr - ', last_daily_cqc_date),
       subtitle = 'Where Covid-19 is suspected or confirmed as cause',
       x = 'Date',
       y = 'Number of deaths') +
  scale_y_continuous(breaks = seq(0,round_any(max(wsx_cqc_deaths$Cumulative_all_cause, na.rm = TRUE), 50, ceiling), 25),
                     limits = c(0,round_any(max(wsx_cqc_deaths$Cumulative_all_cause, na.rm = TRUE), 50, ceiling)),
                     expand = c(0,0.1)) +
  scale_x_date(date_labels = "%b %d (%A)",
               date_breaks = '1 day',
               # date_minor_breaks = '1 day',
               expand = c(0,.1)) +
  scale_fill_manual(values = c('#006d90','#003343')) +
  scale_colour_manual(values = c('#000000', '#ffffff')) +
  ph_theme() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = .5),
        legend.position = c(.1,.8))  +
  guides(colour = FALSE)

png(paste0(github_repo_dir, "/wsx_cumulative_cqc_cause_ch_deaths_plot.png"), width = 580, height = 250)
wsx_cumulative_cqc_cause_ch_deaths_plot
dev.off()

wsx_cumulative_cqc_covid_ch_deaths_plot <- ggplot(wsx_cqc_deaths,
       aes(x = Date,
           y = Cumulative_covid)) +
  geom_bar(stat = 'identity',
           fill = '#006d90') +
  labs(title = paste0('Cumulative Covid-19 care home deaths; by date of notification to CQC; West Sussex; 10th Apr - ', last_daily_cqc_date),
       subtitle = 'Where Covid-19 is suspected or confirmed as cause',
       x = 'Date',
       y = 'Number of deaths') +
  scale_y_continuous(breaks = seq(0,round_any(max(wsx_cqc_deaths$Cumulative_covid, na.rm = TRUE), 20, ceiling), 20),
                     limits = c(0,round_any(max(wsx_cqc_deaths$Cumulative_covid, na.rm = TRUE), 20, ceiling))) +
  scale_x_date(date_labels = "%b %d (%A)",
               date_breaks = '1 day',
               # date_minor_breaks = '1 day',
               expand = c(0,.5)) +
  ph_theme() +
  annotate(geom = "text", 
           x = wsx_cqc_deaths$Date,
           y = wsx_cqc_deaths$Cumulative_covid,
           label = wsx_cqc_deaths$Cumulative_covid,
           size = 3, 
           fontface = "bold",
           vjust = -1) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = .5)) 

png(paste0(github_repo_dir, "/wsx_cumulative_cqc_covid_ch_deaths_plot.png"), width = 580, height = 250)
wsx_cumulative_cqc_covid_ch_deaths_plot
dev.off()

wsx_cqc_deaths %>% 
  filter(Date == max(Date)) %>% 
  mutate(Prop_cumulative = Cumulative_covid / Cumulative_all_cause) %>% 
  select(Prop_cumulative, Cumulative_all_cause)

# daily hospital view
daily_deaths_trust 
daily_trust_deaths_table 
meta_trust_deaths

# Deaths of patients who have died in hospitals in England and had tested positive for Covid-19 at time of death. All deaths are recorded against the date of death rather than the day the deaths were announced. Likely to be some revision.

# Note: interpretation of the figures should take into account the fact that totals by date of death, particularly for recent prior days, are likely to be updated in future releases. For example as deaths are confirmed as testing positive for Covid-19, as more post-mortem tests are processed and data from them are validated. Any changes are made clear in the daily files.