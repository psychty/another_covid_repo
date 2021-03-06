
library(easypackages)

libraries(c("readxl", "readr", "plyr", "dplyr", "ggplot2", "png", "tidyverse", "reshape2", "scales", "viridis", "rgdal", "officer", "flextable", "tmaptools", "lemon", "fingertipsR", "PHEindicatormethods", 'jsonlite', 'readODS', 'zoo', 'stats'))

github_repo_dir <- "~/Documents/Repositories/another_covid_repo"

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

# https://blogs.sas.com/content/iml/2020/04/01/estimate-doubling-time-exponential-growth.html

Italy <-  data.frame(Cumulative_cases = c(2502, 3089, 3858, 4636, 5883, 7375, 9172, 10149, 12462, 12462, 17660, 21157, 24747, 27980, 31506, 35713, 41035, 47021, 53578, 59138, 63927, 69176, 74386, 80589, 86498)) %>% 
  mutate(Area = 'Italy',
         Days = row_number()-1) %>% 
  mutate(Log10Cumul = log10(Cumulative_cases))

US <- data.frame(Cumulative_cases = c(118, 149, 217, 262, 402, 518, 583, 959, 1281, 1663, 2179, 2727, 3499, 4632, 6421, 7783, 13677, 19100, 25489, 33276, 43847, 53740, 65778, 83836, 101657)) %>% 
  mutate(Area = 'US',
         Days = row_number()-1) %>% 
  mutate(Log10Cumul = log10(Cumulative_cases))

Canada <- data.frame(Cumulative_cases = c(1, 1, 2, 2, 3, 4, 4, 4, 8, 9, 17, 17, 24, 50, 74, 94, 121, 139, 181, 219, 628, 1013, 1342, 1632, 2024)) %>% 
  mutate(Area = 'Canada',
         Days = row_number()-1) %>% 
  mutate(Log10Cumul = log10(Cumulative_cases))

SouthKorea <- data.frame(Cumulative_cases = c(5186, 5621, 6088, 6593, 7041, 7314, 7478, 7513, 7755, 7869, 7979, 8086, 8162, 8236, 8320, 8413, 8565, 8652, 8799, 8961, 8961, 9037, 9137, 9241, 9332)) %>% 
  mutate(Area = 'South Korea',
         Days = row_number() - 1) %>% 
  mutate(Log10Cumul = log10(Cumulative_cases))

df <- Italy %>% 
  bind_rows(US) %>% 
  bind_rows(Canada) %>% 
  bind_rows(SouthKorea) %>% 
  group_by(Area) %>% 
  mutate(Date = seq.Date(as.Date('2020-03-03'), as.Date('2020-03-27'), by = 1))  %>% 
  mutate(Log2Cumul = log2(Cumulative_cases))

rm(Italy, Canada, SouthKorea, US)

ggplot(df, aes(x = Date, y = Cumulative_cases, group = Area, fill = Area)) +
  geom_line(colour = '#000000') +
  geom_point(size = 2,
             colour = '#ffffff',
             shape = 21) +
  labs(title = 'Cumulative Covid-19 cases over time - 03 March to 27 March 2020') +
  scale_x_date(date_labels = "%b %d (%A)",
               date_breaks = '1 day',
               expand = c(0,.5)) +
  scale_y_continuous(labels = comma,
                     breaks= seq(0,100000, 10000)) +
  ph_theme() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5)) 

ggplot(df, aes(x = Date, y = Cumulative_cases, group = Area, fill = Area)) +
  geom_line(colour = '#000000') +
  geom_point(size = 2,
             colour = '#ffffff',
             shape = 21) +
  scale_y_continuous(trans = 'log10',
                     # breaks = trans_breaks('log2', function(x) 2^x),
                     breaks= c(50,100, 500, 1000, 5000, 10000, 50000, 100000),
                     labels = comma) +
  labs(title = 'Cumulative Covid-19 cases over time - 03 March to 27 March 2020',
       subtitle = 'y axis is plotted on a log scale') +
  scale_x_date(date_labels = "%b %d (%A)",
               date_breaks = '1 day',
               expand = c(0,.5)) +
  ph_theme() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5))

# This calculates a field for week (or five or seven day period), and then adds the doubling time for each area and each time period

double_time_period <- 7 # this could be 5 or 7 

# I've made an ifelse function for 12 weeks of data

doubling_time_df <- df %>% 
  mutate(period_in_reverse = ifelse(Days > max(Days) -double_time_period, 1, ifelse(Days > max(Days)-(double_time_period*2), 2, ifelse(Days > max(Days)-(double_time_period*3), 3, ifelse(Days > max(Days) - (double_time_period*4), 4, ifelse(Days > max(Days) - (double_time_period *5), 5, ifelse(Days > max(Days) - (double_time_period * 6), 6, ifelse(Days > max(Days) - (double_time_period * 7), 7, ifelse(Days > max(Days) - (double_time_period * 8), 8, ifelse(Days > max(Days) - (double_time_period * 9), 9, ifelse(Days > max(Days) - (double_time_period * 10), 10, ifelse(Days > max(Days) - (double_time_period * 11), 11, ifelse(Days > max(Days) - (double_time_period * 12), 12, NA)))))))))))))%>% 
  group_by(Area, period_in_reverse) %>%   
  mutate(Slope = coef(lm(Log10Cumul ~ Days))[2]) %>% 
  mutate(Double_time = log(2, base = 10)/coef(lm(Log10Cumul ~ Days))[2]) %>% 
  select(Area, period_in_reverse, Slope, Double_time) %>% 
  unique()

# 
# wsx <- data.frame(Cumulative_cases = c(220, 224, 266, 320, 330, 363, 373)) %>% 
#   mutate(Area = 'West Sussex',
#          Days = row_number() - 1) %>% 
#   mutate(Log10Cumul = log10(Cumulative_cases)) %>% 
#   mutate(Slope = coef(lm(Log10Cumul ~ Days))[2]) %>% 
#   mutate(Double_time = log(2, base = 10)/coef(lm(Log10Cumul ~ Days))[2])# %>% 
#   select(Area, period_in_reverse, Slope, Double_time) %>% 
#   unique()


# This transposes the period_in_reverse to show change over time (1 is last week)
doubling_time_df_summary <- doubling_time_df %>% 
  select(-Slope) %>% 
  spread(period_in_reverse, Double_time)

# This is the next point in our data series
predicted_double_time_visualised <- df %>% 
  select(-c(Log2Cumul, Log10Cumul)) %>% 
  group_by(Area) %>% 
  filter(Days == max(Days)) %>% 
  left_join(doubling_time_df_summary[c('Area', '1')], by = 'Area') %>% 
  mutate(Days = Days + `1`) %>% 
  mutate(Cumulative_cases = Cumulative_cases * 2) %>% 
  mutate(Date = Date + `1`) %>% 
  select(-`1`) %>% 
  mutate(Data_type = 'Predicted')
  
df_double_added <- df %>%
  select(-c(Log2Cumul, Log10Cumul)) %>% 
  group_by(Area) %>% 
  filter(Days == max(Days)) %>% 
  mutate(Data_type = 'Recorded') %>% 
  bind_rows(predicted_double_time_visualised) %>% 
  arrange(Area, Date) %>% 
  filter(Area != 'South Korea')

ggplot(df, aes(x = Days, y = Cumulative_cases, group = Area, fill = Area, colour = Area)) +
  geom_line() +
  geom_point(size = 2,
             colour = '#ffffff',
             shape = 21) +
  geom_line(data = df_double_added, 
            aes(x = Days, y = Cumulative_cases, group = Area, colour = Area),
            linetype = 'dashed') +
  geom_point(data = subset(df_double_added, Data_type == 'Predicted', colour = Area),
             shape = 1,
             size = 2) +
  scale_y_continuous(trans = 'log10',
                     # breaks = trans_breaks('log2', function(x) 2^x),
                     breaks= c(50,100, 500, 1000, 5000, 10000, 50000, 100000),
                     labels = comma) +
  labs(title = 'Cumulative Covid-19 cases over time - 03 March to 27 March 2020',
       subtitle = 'y axis is plotted on a log scale') +
  scale_x_continuous(limits = c(0, max(df_double_added$Days)),
                     breaks = seq(0, max(df_double_added$Days), 1)) +
  ph_theme() +
  theme(axis.text.x = element_text(angle = 0, hjust = 1, vjust = 0.5))

# for log2 use 1/coef(lm(Log2Cumul ~ Days, data = italy_last_5))[2]

# for log10 use log(2, base = 10)/ coef(lm(Log10Cumul ~ Days, data = df))[2]
