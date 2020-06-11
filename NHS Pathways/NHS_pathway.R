library(easypackages)

libraries(c("readxl", "readr", "plyr", "dplyr", "ggplot2", "tidyverse", "reshape2", "scales", 'jsonlite', 'zoo', 'stats', 'epitools', 'xml2', 'rvest'))

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

# NHS pathway analysis

# Many caveats around this, not counts of people, people might not use this or might use it multiple times over the course of their symptoms (and maybe not at the start of their symptoms).

# Might be useful to have a cumulative count of number of people using the system
# West Sussex CCG has 390 triages per 100,000, whilst cases are around 26 diagnosed cases per 100,000. YOU ARE COMPARING SMALL APPLES AND REALLY RIPE CRAB APPLES

# People are encouraged NOT to call NHS 111 to report Covid-19 symptoms unless they are worried but are asked to complete an NHS 111 online triage assessment.

ccg_region_2019 <- read_csv('https://opendata.arcgis.com/datasets/40f816a75fb14dfaaa6db375e6c3d5e6_0.csv') %>% 
  select(CCG19CD, CCG19NM) %>% 
  rename(Old_CCG_Name = CCG19NM,
         Old_CCG_Code = CCG19CD) %>% 
  mutate(New_CCG_Name = ifelse(Old_CCG_Name %in% c('NHS Bath and North East Somerset CCG', 'NHS Swindon CCG', 'NHS Wiltshire CCG'), 'NHS Bath and North East Somerset, Swindon and Wiltshire CCG', ifelse(Old_CCG_Name %in% c('NHS Airedale, Wharfedale and Craven CCG', 'NHS Bradford City CCG', 'NHS Bradford Districts CCG'), 'NHS Bradford District and Craven CCG', ifelse(Old_CCG_Name %in% c('NHS Eastern Cheshire CCG', 'NHS South Cheshire CCG', 'NHS Vale Royal CCG','NHS West Cheshire CCG'), 'NHS Cheshire CCG', ifelse(Old_CCG_Name %in% c('NHS Durham Dales, Easington and Sedgefield CCG', 'NHS North Durham CCG'), 'NHS County Durham CCG',  ifelse(Old_CCG_Name %in% c('NHS Eastbourne, Hailsham and Seaford CCG', 'NHS Hastings and Rother CCG', 'NHS High Weald Lewes Havens CCG'), 'NHS East Sussex CCG', ifelse(Old_CCG_Name %in% c('NHS Herefordshire CCG', 'NHS Redditch and Bromsgrove CCG', 'NHS South Worcestershire CCG','NHS Wyre Forest CCG'), 'NHS Herefordshire and Worcestershire CCG', ifelse(Old_CCG_Name %in% c('NHS Ashford CCG', 'NHS Canterbury and Coastal CCG', 'NHS Dartford, Gravesham and Swanley CCG', 'NHS Medway CCG', 'NHS South Kent Coast CCG', 'NHS Swale CCG', 'NHS Thanet CCG','NHS West Kent CCG'), 'NHS Kent and Medway CCG', ifelse(Old_CCG_Name %in% c('NHS Lincolnshire East CCG', 'NHS Lincolnshire West CCG', 'NHS South Lincolnshire CCG', 'NHS South West Lincolnshire CCG'), 'NHS Lincolnshire CCG', ifelse(Old_CCG_Name %in% c('NHS Great Yarmouth and Waveney CCG', 'NHS North Norfolk CCG', 'NHS Norwich CCG', 'NHS South Norfolk CCG', 'NHS West Norfolk CCG'), 'NHS Norfolk and Waveney CCG', ifelse(Old_CCG_Name %in% c('NHS Barnet CCG', 'NHS Camden CCG', 'NHS Enfield CCG', 'NHS Haringey CCG', 'NHS Islington CCG'), 'NHS North Central London CCG', ifelse(Old_CCG_Name %in% c('NHS Hambleton, Richmondshire and Whitby CCG', 'NHS Scarborough and Ryedale CCG', 'NHS Harrogate and Rural District CCG'),'NHS North Yorkshire CCG', ifelse(Old_CCG_Name %in% c('NHS Corby CCG', 'NHS Nene CCG'), 'NHS Northamptonshire CCG', ifelse(Old_CCG_Name %in% c('NHS Mansfield and Ashfield CCG', 'NHS Newark and Sherwood CCG', 'NHS Nottingham City CCG', 'NHS Nottingham North and East CCG', 'NHS Nottingham West CCG', 'NHS Rushcliffe CCG'), 'NHS Nottingham and Nottinghamshire CCG', ifelse(Old_CCG_Name %in% c('NHS Bexley CCG', 'NHS Bromley CCG', 'NHS Greenwich CCG', 'NHS Lambeth CCG', 'NHS Lewisham CCG','NHS Southwark CCG'), 'NHS South East London CCG',ifelse(Old_CCG_Name %in% c('NHS Croydon CCG', 'NHS Kingston CCG', 'NHS Merton CCG', 'NHS Richmond CCG', 'NHS Sutton CCG', 'NHS Wandsworth CCG'), 'NHS South West London CCG',ifelse(Old_CCG_Name %in% c('NHS East Surrey CCG', 'NHS Guildford and Waverley CCG', 'NHS North West Surrey CCG', 'NHS Surrey Downs CCG'), 'NHS Surrey Heartlands CCG', ifelse(Old_CCG_Name %in% c('NHS Darlington CCG', 'NHS Hartlepool and Stockton-on-Tees CCG', 'NHS South Tees CCG'), 'NHS Tees Valley CCG', ifelse(Old_CCG_Name %in% c('NHS Coastal West Sussex CCG', 'NHS Crawley CCG', 'NHS Horsham and Mid Sussex CCG'), 'NHS West Sussex CCG', Old_CCG_Name)))))))))))))))))))
 
ccg_region_2020 <- read_csv('https://opendata.arcgis.com/datasets/888dc5cc66ba4ad9b4d935871dcce251_0.csv') %>% 
  select(CCG20CD, CCG20NM, NHSER20NM) %>% 
  rename(New_CCG_Code = CCG20CD,
         CCG_Name = CCG20NM,
         NHS_region = NHSER20NM)

ccg_region_2019 <- ccg_region_2019 %>% 
  left_join(ccg_region_2020[c('New_CCG_Code', 'CCG_Name')], by = c('New_CCG_Name'='CCG_Name'))

# NHS Pathway Data
calls_webpage <- read_html('https://digital.nhs.uk/data-and-information/publications/statistical/mi-potential-covid-19-symptoms-reported-through-nhs-pathways-and-111-online/latest') %>%
  html_nodes("a") %>%
  html_attr("href")

nhs_111_pathways_raw <- read_csv(grep('NHS%20Pathways%20Covid-19%20data%202020', calls_webpage, value = T))  %>% 
  rename(CCG_Name = CCGName) %>% 
  mutate(Date = as.Date(`Call Date`, format = '%d/%m/%Y')) %>% 
  select(-`Call Date`) %>% 
  mutate(AgeBand = ifelse(is.na(AgeBand), 'Unknown', AgeBand))
  
nhs_111_pathways_pre_april <- nhs_111_pathways_raw %>% 
  filter(Date < '2020-04-01') %>% 
  left_join(ccg_region_2019[c('Old_CCG_Code','New_CCG_Code', 'New_CCG_Name')], by = c('CCGCode' = 'Old_CCG_Code')) %>% 
  group_by(New_CCG_Code, New_CCG_Name, Date, AgeBand, Sex, SiteType) %>% 
  summarise(TriageCount = sum(TriageCount, na.rm = TRUE)) %>% 
  left_join(ccg_region_2020[c('New_CCG_Code', 'NHS_region')], by = 'New_CCG_Code') %>% 
  ungroup() %>% 
  filter(!is.na(NHS_region))

nhs_111_pathways_post_april <- nhs_111_pathways_raw %>% 
  filter(Date >= '2020-04-01') %>% 
  left_join(ccg_region_2020[c('New_CCG_Code', 'NHS_region')], by = c('CCGCode' ='New_CCG_Code')) %>% 
  filter(!is.na(NHS_region)) %>% 
  rename(New_CCG_Code = CCGCode,
         New_CCG_Name = CCG_Name)

nhs_111_pathways <- nhs_111_pathways_pre_april %>% 
  bind_rows(nhs_111_pathways_post_april) %>% 
  mutate(Pathway = paste0(SiteType, ' triage')) %>% 
  select(-SiteType) %>% 
  rename(Triage_count = TriageCount)

rm(nhs_111_pathways_pre_april, nhs_111_pathways_post_april)

nhs_111_online_raw <- read_csv(grep('111%20Online%20Covid-19%20data_2020', calls_webpage, value = T)) %>% 
  rename(CCG_Name = ccgname,
         CCG_Code = ccgcode,
         Sex = sex,
         AgeBand = ageband) %>% 
  mutate(Date = as.Date(journeydate, format = '%d/%m/%Y')) %>% 
  select(-journeydate) %>% 
  mutate(AgeBand = ifelse(is.na(AgeBand), 'Unknown', AgeBand))

nhs_111_online_post_april <- nhs_111_online_raw %>% 
  filter(Date >= '2020-04-01') %>% 
  left_join(ccg_region_2020[c('New_CCG_Code', 'NHS_region')], by = c('CCG_Code' ='New_CCG_Code')) %>% 
  filter(!is.na(NHS_region)) %>% 
  rename(New_CCG_Code = CCG_Code,
         New_CCG_Name = CCG_Name)

nhs_111_online_pre_april <- nhs_111_online_raw %>% 
  filter(Date < '2020-04-01') %>% 
  left_join(ccg_region_2019[c('Old_CCG_Code','New_CCG_Code', 'New_CCG_Name')], by = c('CCG_Code' = 'Old_CCG_Code')) %>% 
  group_by(New_CCG_Code, New_CCG_Name, Date, AgeBand, Sex) %>% 
  summarise(Total = sum(Total, na.rm = TRUE)) %>% 
  left_join(ccg_region_2020[c('New_CCG_Code', 'NHS_region')], by = 'New_CCG_Code') %>% 
  ungroup() %>% 
  filter(!is.na(NHS_region))

nhs_111_online <- nhs_111_online_pre_april %>% 
  bind_rows(nhs_111_online_post_april) %>% 
  mutate(Pathway = '111 online Journey') %>% 
  rename(Triage_count = Total)

nhs_pathways_p1 <- nhs_111_pathways %>% 
  bind_rows(nhs_111_online) %>% 
  rename(Area_Code = New_CCG_Code,
         Area_Name = New_CCG_Name)

sussex_pathways <- nhs_pathways_p1 %>% 
  filter(Area_Name %in% c('NHS West Sussex CCG', 'NHS East Sussex CCG', 'NHS Brighton and Hove CCG')) %>% 
  group_by(Date, Pathway, Sex, AgeBand) %>% 
  summarise(Triage_count = sum(Triage_count)) %>% 
  mutate(Area_Name = 'Sussex areas combined',
         Area_Code = '-',
         NHS_region = '-')
  
nhs_pathways <- nhs_pathways_p1 %>% 
  bind_rows(sussex_pathways)

nhs_pathways_all_ages_persons <- nhs_pathways %>% 
  group_by(Area_Code, Area_Name, Date, Pathway) %>% 
  summarise(Triage_count = sum(Triage_count)) %>% 
  group_by(Area_Code, Area_Name, Pathway) %>% 
  arrange(Area_Code, Pathway, Date) %>% 
  mutate(Number_change = Triage_count - lag(Triage_count),
         Percentage_change = (Triage_count - lag(Triage_count))/ lag(Triage_count))

rm(ccg_region_2019, ccg_region_2020, nhs_111_online, nhs_111_online_pre_april, nhs_111_online_post_april, nhs_111_online_raw, nhs_111_pathways, nhs_111_pathways_raw, calls_webpage, nhs_pathways_p1, sussex_pathways)

nhs_pathways_all_ages_persons_all_pathways <- nhs_pathways %>% 
  group_by(Area_Code, Area_Name, Date) %>% 
  summarise(Triage_count = sum(Triage_count)) %>% 
  group_by(Area_Code, Area_Name) %>% 
  arrange(Area_Code, Date) %>% 
  mutate(Number_change = Triage_count - lag(Triage_count),
         Percentage_change = (Triage_count - lag(Triage_count))/ lag(Triage_count))

latest_triage_date = nhs_pathways %>% 
  filter(Date == max(Date)) %>% 
  select(Date) %>% 
  unique() %>% 
  mutate(Date = format(Date, '%d %B'))
  
sussex_pathways <- nhs_pathways_all_ages_persons_all_pathways %>% 
  filter(Area_Name == 'Sussex areas combined')

ggplot(sussex_pathways,
       aes(x = Date,
           y = Triage_count,
           group = 1)) +
  geom_segment(x = as.Date('2020-04-09'), y = 0, xend = as.Date('2020-04-09'), yend = as.numeric(subset(sussex_pathways, Date == as.Date('2020-04-09'), select = Triage_count)), color = "red", linetype = "dashed") +
  geom_segment(x = as.Date('2020-04-23'), y = 0, xend = as.Date('2020-04-23'), yend = as.numeric(subset(sussex_pathways, Date == as.Date('2020-04-23'), select = Triage_count)), color = "blue", linetype = "dashed") +
  geom_segment(x = as.Date('2020-05-18'), y = 0, xend = as.Date('2020-05-18'), yend = as.numeric(subset(sussex_pathways, Date == as.Date('2020-05-18'), select = Triage_count)), color = "red", linetype = "dashed") +
  geom_line() +
  geom_point() +
  scale_x_date(date_labels = "%b %d",
               breaks = seq.Date(max(nhs_pathways$Date) -(52*7), max(nhs_pathways$Date), by = 2),
               limits = c(min(nhs_pathways$Date), max(nhs_pathways$Date)),
               expand = c(0.01,0.01)) +
  scale_y_continuous(labels = comma,
                     breaks = seq(0,round_any(max(sussex_pathways$Triage_count, na.rm = TRUE), 500, ceiling),250)) +
  labs(x = 'Date',
       y = 'Number of complete triages',
       title = "Total number of complete triages to NHS Pathways for Covid-19; Sussex CCG's combined",
       subtitle = paste0('Triages via 111 online, 111 phone calls and 999 calls; 18 March - ', latest_triage_date$Date),
       caption = 'Note: red dashed line = some patients excluded,\nblue dashed line = additional patients added') +
  ph_theme() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = .5)) +
  annotate(geom = 'text',
           x = as.Date('2020-04-08'), 
           y = as.numeric(subset(sussex_pathways, Date == as.Date('2020-04-09'), select = Triage_count)),
           label = '9th April',
           fontface = 'bold',
           size = 2.5,
           hjust = 1,
           vjust = 1) +
  annotate(geom = 'text',
           x = as.Date('2020-04-08'), 
           y = as.numeric(subset(sussex_pathways, Date == as.Date('2020-04-09'), select = Triage_count)),
           label = '111 online removed\nfor 0-18 year olds',
           size = 2.5,
           hjust = 1,
           vjust = 1.75) +
  annotate(geom = 'text',
           x = as.Date('2020-04-23'), 
           y = as.numeric(subset(sussex_pathways, Date == as.Date('2020-04-23'), select = Triage_count)),
           label = '23rd April',
           fontface = 'bold',
           size = 2.5,
           hjust = 0,
           vjust = -8) +
  annotate(geom = 'text',
           x = as.Date('2020-04-23'), 
           y = as.numeric(subset(sussex_pathways, Date == as.Date('2020-04-23'), select = Triage_count)),
           label = '111 online reinstated\nfor 5-18 year olds',
           size = 2.5,
           hjust = 0,
           vjust = -1.25) +
  annotate(geom = 'text',
           x = as.Date('2020-05-18'), 
           y = as.numeric(subset(sussex_pathways, Date == as.Date('2020-05-18'), select = Triage_count)),
           label = '18th May',
           size = 2.5,
           fontface = 'bold',
           hjust = 0,
           vjust = -6) +
  annotate(geom = 'text',
           x = as.Date('2020-05-18'), 
           y = as.numeric(subset(sussex_pathways, Date == as.Date('2020-05-18'), select = Triage_count)),
           label = 'Covid-19 pathway case\ndefinition change',
           size = 2.5,
           hjust = 0,
           vjust = -.5)

# SPC ####

run_length <- 6
trend_length <- 7

paste0('These are our conditions; to highlight any consecutive data points in which the last ' , run_length, ' are above or below the process mean, in addition we want to highlight any periods of ', trend_length, ' or more values which are increasing or decreasing.')

sussex_spc <- sussex_pathways %>% 
  mutate(process_number = ifelse(Date <= '2020-04-09', 1, ifelse(Date <= '2020-04-23', 2, ifelse(Date <= '2020-05-18', 3, 4)))) %>% 
  group_by(process_number) %>% 
  mutate(process_mean = mean(Triage_count, na.rm = TRUE)) %>% 
  mutate(mR = abs(Triage_count - lag(Triage_count))) %>% 
  mutate(mean_mR = mean(mR, na.rm = TRUE)) %>% 
  mutate(seq_dev = mean_mR / 1.128) %>% 
  mutate(lower_control_limit = process_mean - (seq_dev * 3),
         upper_control_limit = process_mean + (seq_dev * 3)) %>% 
  mutate(one_sigma_lci = process_mean - seq_dev,
         one_sigma_uci = process_mean + seq_dev,
         two_sigma_lci = process_mean - (seq_dev * 2),
         two_sigma_uci = process_mean + (seq_dev * 2)) %>% 
  mutate(location = ifelse(Triage_count > upper_control_limit, 'Outside +/- 3sigma', ifelse(Triage_count < lower_control_limit, 'Outside +/- 3sigma', ifelse(Triage_count > two_sigma_uci, 'Between +/- 2sigma and 3sigma', ifelse(Triage_count < two_sigma_lci, 'Between +/- 2sigma and 3sigma', ifelse(Triage_count > one_sigma_uci, 'Between +/- 1sigma and 2sigma', ifelse(Triage_count < one_sigma_lci, 'Between +/- 1sigma and 2sigma', 'Within +/- 1sigma'))))))) %>% 
  mutate(rule_1 = ifelse(Triage_count > upper_control_limit, 'Special cause concern', ifelse(Triage_count < lower_control_limit, 'Special cause concern', 'Common cause variation'))) %>% # This highlights any values outside the control limits
  mutate(above_mean = ifelse(Triage_count > process_mean, 1, 0)) %>% # above_mean is 1 if the value is above the mean and 0 if not.
  mutate(rule_2a = rollapplyr(above_mean, run_length, sum, align = 'right', partial = TRUE)) %>% # sum the last five (or whatever 'run_length' is) values for 'above_mean'. if the sum is 5 (or whatever 'run_length' is set to) then you know that there have been at least this many consecutive values above the process mean and this constitutes a 'run'. 
  mutate(rule_2a_label = rollapply(rule_2a, run_length, function(x)if(any(x == run_length)) 'Run above (shift)' else 'No run', align = 'left', partial = TRUE)) %>% # Now we want to identify all values related to that above run which means we have to look forward (using align = 'left') to see if a value should be included in a run.
  mutate(below_mean = ifelse(Triage_count < process_mean, 1, 0)) %>% # Now we do the same as above mean but for the below mean run.
  mutate(rule_2b = rollapplyr(below_mean, run_length, sum, partial = TRUE)) %>%
  mutate(rule_2b_label = rollapply(rule_2b, run_length, function(x)if(any(x == run_length)) 'Run below (shift)' else 'No run', align = 'left', partial = TRUE)) %>%
  mutate(rule_2 = ifelse(rule_2a_label == 'Run above (shift)', rule_2a_label, rule_2b_label)) %>%
  select(-c(above_mean, below_mean, rule_2a, rule_2a_label, rule_2b, rule_2b_label)) %>% 
  mutate(trend_down = ifelse(Triage_count < lag(Triage_count, 1), 1, 0)) %>% # Now we say give 1 if the Triage_count value is lower than the previous Triage_count value, if not give 0
  mutate(trend_down = ifelse(is.na(trend_down), lead(trend_down, 1), trend_down)) %>% # As we were comparing value x to its predecessor, the first row has nothing to compare to and will be NA, so instead we'll use the value of row 2 to determine what this value should be.
  mutate(rule_3a = rollapplyr(trend_down, trend_length, sum, align = 'right', partial = TRUE)) %>% # Similarly to earlier (although we are using 'trend_length' rather than 'run_length') we can sum all the 1's to figure out which values are part of a downward trend. Note that this includes trends from above the mean to below the mean.
  mutate(rule_3a_label = rollapply(rule_3a, trend_length, function(x)if(any(x == trend_length)) 'Trend down (drift)' else 'No trend', align = 'left', partial = TRUE)) %>% # Equally, we use the rule_3a value but looking ahead six (or whatever) values to see if value x should be considered part of the trend.
  mutate(trend_up = ifelse(Triage_count > lag(Triage_count, 1), 1, 0)) %>% 
  mutate(trend_up = ifelse(is.na(trend_up), lead(trend_up, 1), trend_up)) %>% 
  mutate(rule_3b = rollapplyr(trend_up, trend_length, sum, align = 'right', partial = TRUE)) %>% 
  mutate(rule_3b_label = rollapply(rule_3b, trend_length, function(x)if(any(x == trend_length)) 'Trend up (drift)' else 'No trend', align = 'left', partial = TRUE)) %>%
  mutate(rule_3 = ifelse(rule_3a_label == 'Trend down (drift)', rule_3a_label, rule_3b_label)) %>% 
  select(-c(trend_down, trend_up, rule_3a, rule_3a_label, rule_3b, rule_3b_label)) %>%
  mutate(close_to_limit = ifelse(location == 'Between +/- 2sigma and 3sigma', 1, 0)) %>% 
  mutate(rule_4 = rollapplyr(close_to_limit, 3, sum, align = 'right', partial = TRUE)) %>% 
  mutate(rule_4_label = ifelse(rule_4 >= 2, 'Close to limits', ifelse(lead(rule_4,1) >= 2, 'Close to limits', 'Not two out of three'))) %>% 
  mutate(rule_4_label = ifelse(is.na(rule_4_label), ifelse(rule_4 >= 2, 'Close to limits', 'Not two out of three'), rule_4_label)) %>% 
  mutate(rule_4 = rule_4_label) %>% 
  select(-c(rule_4_label, close_to_limit)) %>% 
  mutate(no_variation = ifelse(location == 'Within +/- 1sigma', 1, 0)) %>% 
  mutate(rule_5 = rollapplyr(no_variation, 15, sum, align = 'right', partial = TRUE)) %>% 
  mutate(rule_5 = rollapply(rule_5, 15, function(x)if(any(x == 15)) 'Little variation' else 'Variation', align = 'left', partial = TRUE)) %>% 
  select(-no_variation) %>% 
  mutate(top_label = factor(ifelse(rule_1 == 'Special cause concern', 'Special cause concern', ifelse(rule_2 %in% c('Run above (shift)', 'Run below (shift)'), rule_2, ifelse(rule_3 %in% c('Trend down (drift)', 'Trend up (drift)'), rule_3, ifelse(rule_4 == 'Close to limits', 'Close to limits', ifelse(rule_5 == 'Little variation', rule_5, 'Common cause variation'))))), levels = c('Common cause variation', 'Close to limits', 'Special cause concern', 'Run above (shift)', 'Run below (shift)','Trend up (drift)', 'Trend down (drift)', 'Little variation'))) %>% 
  mutate(variation_label = factor(ifelse(rule_1 == 'Special cause concern', 'Special cause variation', ifelse(rule_2 %in% c('Run above (shift)', 'Run below (shift)'), 'Special cause variation', ifelse(rule_3 %in% c('Trend down (drift)', 'Trend up (drift)'), 'Special cause variation', 'Common cause variation'))), levels = c('Common cause variation', 'Special cause concern'))) # What is an improvement and what is concern will depend on the context. in a purely variation context (where you want things to stay within limits), trends (drift) and runs (shift) as well as points outside of limits may be of concern regardless of whether they are above or below the process mean. In cases where higher values are good then you may want to mark upward trends (drift) and above mean runs as improvement and below mean runs and downward drifts as special variation of concern.



spc_break_points <- sussex_spc %>% 
  select(Date, process_number) %>% 
  group_by(start_process = min(Date),
           end_process = max(Date)) %>% 
  select(-Date) %>% 
  unique()

sussex_spc <- sussex_spc %>% 
  left_join(spc_break_points, by = 'process_number')


# TO DO 

ggplot(data = sussex_spc, aes(x = Date, y = Triage_count, group = 1)) +
  geom_line(aes(x = Date, 
                y = process_mean),
             colour = "#264852",
             lwd = .8) +
  geom_line(colour = '#999999') +
  geom_point(aes(fill =  top_label,
                 colour = top_label), 
             size = 4, 
             shape = 21) +
  geom_line(aes(x = Date,
                y = lower_control_limit),
             colour = "#A8423F",
             linetype="dotted",
             lwd = .7) +
  geom_line(aes(x = Date,
                 y = upper_control_limit),
             colour = "#A8423F",
             linetype="dotted",
             lwd = .7) +
  geom_line(aes(x = Date, 
                y = two_sigma_uci),
             colour = "#3d2b65",
             linetype="dashed",
             lwd = .7) +
  geom_line(aes(x = Date,
                y = two_sigma_lci),
             colour = "#3d2b65",
             linetype="dashed",
             lwd = .7) +
  geom_line(aes(x = Date,
                 y = one_sigma_uci),
             colour = "#45748d",
             linetype="solid",
             lwd = .4) +
  geom_line(aes(x = Date,
                y = one_sigma_lci),
             colour = "#45748d",
             linetype="solid",
             lwd = .4) +  
  scale_x_date(date_labels = "%b %d",
               breaks = seq.Date(max(nhs_pathways$Date) -(52*7), max(nhs_pathways$Date), by = 7),
               limits = c(min(nhs_pathways$Date), max(nhs_pathways$Date)),
               expand = c(0.01,0.01)) +
  scale_y_continuous(labels = comma) +
  scale_fill_manual(values= c("#b5a7b6","#fdbf00","#cc6633", "#61b8d2","#00fdf6","#832157","#ef4d96", '#5a535b'),
                    breaks = c('Common cause variation', 'Close to limits', 'Special cause concern', 'Run above (shift)', 'Run below (shift)','Trend up (drift)', 'Trend down (drift)', 'Little variation'),
                    limits = c('Common cause variation', 'Close to limits', 'Special cause concern', 'Run above (shift)', 'Run below (shift)','Trend up (drift)', 'Trend down (drift)', 'Little variation'),
                    name = 'Variation key') +  
  scale_colour_manual(values=  c("#b5a7b6","#fdbf00","#cc6633", "#61b8d2","#00fdf6","#832157","#ef4d96", '#5a535b'),
                      breaks = c('Common cause variation', 'Close to limits', 'Special cause concern', 'Run above (shift)', 'Run below (shift)','Trend up (drift)', 'Trend down (drift)', 'Little variation'),
                      limits = c('Common cause variation', 'Close to limits', 'Special cause concern', 'Run above (shift)', 'Run below (shift)','Trend up (drift)', 'Trend down (drift)', 'Little variation'),
                      name = 'Variation key') +  
  labs(caption = "Note: Y axis does not start at zero.\nThe red dotted lines represent 99% control limits (3σ, moving range) control limits respectively.\nThe thick solid line represents the long term average.") +
  theme(legend.position = "bottom", 
        axis.text.x = element_text(angle = 90, hjust = 1, vjust = .5, size = 8),
        plot.background = element_rect(fill = "white", colour = "#E2E2E3"), 
        panel.background = element_rect(fill = '#ffffff'),
        axis.line = element_line(colour = "#E7E7E7", size = .3),
        axis.text = element_text(colour = "#000000", size = 8), 
        plot.title = element_text(colour = "#000000", face = "bold", size = 10, vjust = -.5), 
        axis.title = element_text(colour = "#000000", face = "bold", size = 8),     
        panel.grid = element_blank(), 
        strip.background = element_rect(fill = "#327d9c"),
        axis.ticks = element_line(colour = "#9e9e9e"),
        legend.key = element_rect(fill = '#ffffff'),
        legend.text = element_text(colour = "#000000", size = 8),
        legend.title = element_text(face = 'bold', size = 8))



ggplot(data = sussex_spc, aes(x = Date, y = Triage_count, group = 1)) +
  annotate('rect',
         xmin = sussex_spc$start_process,
         xmax = sussex_spc$end_process,
         ymin = sussex_spc$one_sigma_lci,
         ymax = sussex_spc$one_sigma_uci,
         fill = '#d2e8f5',
         alpha = .01) +
  annotate('rect',
           xmin = sussex_spc$start_process,
           xmax = sussex_spc$end_process,
           ymin = sussex_spc$one_sigma_uci,
           ymax = sussex_spc$two_sigma_uci,
           fill = '#ffecd4',
           alpha = .01) +
  annotate('rect',
           xmin = sussex_spc$start_process,
           xmax = sussex_spc$end_process,
           ymin = sussex_spc$one_sigma_lci,
           ymax = sussex_spc$two_sigma_lci,
           fill = '#ffecd4',
           alpha = .01) +
  annotate('rect',
           xmin = sussex_spc$start_process,
           xmax = sussex_spc$end_process,
           ymin = sussex_spc$two_sigma_uci,
           ymax = sussex_spc$upper_control_limit,
           fill = '#edcf66',
           alpha = .01) +
  annotate('rect',
           xmin = sussex_spc$start_process,
           xmax = sussex_spc$end_process,
           ymin = sussex_spc$two_sigma_lci,
           ymax = sussex_spc$lower_control_limit,
           fill = '#edcf66',
           alpha = .01) +
  geom_line(aes(x = Date,
                y = process_mean),
             colour = "#264852",
             lwd = .8) +
  geom_line(aes(x = Date,
                y = lower_control_limit),
             colour = "#A8423F",
             linetype="dotted",
             lwd = .7) +
  geom_line(aes(x = Date,
                y = upper_control_limit),
             colour = "#A8423F",
             linetype="dotted",
             lwd = .7) +
  geom_segment(x = as.Date('2020-04-09'), y = 0, xend = as.Date('2020-04-09'), yend = as.numeric(subset(sussex_pathways, Date == as.Date('2020-04-09'), select = Triage_count)), color = "red", linetype = "dashed") +
  geom_segment(x = as.Date('2020-04-23'), y = 0, xend = as.Date('2020-04-23'), yend = as.numeric(subset(sussex_pathways, Date == as.Date('2020-04-23'), select = Triage_count)), color = "blue", linetype = "dashed") +
  geom_segment(x = as.Date('2020-05-18'), y = 0, xend = as.Date('2020-05-18'), yend = as.numeric(subset(sussex_pathways, Date == as.Date('2020-05-18'), select = Triage_count)), color = "red", linetype = "dashed") +
  geom_line(colour = '#999999') +
  geom_point(aes(fill =  top_label,
                 colour = top_label), 
             size = 4, 
             shape = 21) +
  scale_x_date(date_labels = "%b %d",
               breaks = seq.Date(max(nhs_pathways$Date) -(52*7), max(nhs_pathways$Date), by = 2),
               limits = c(min(nhs_pathways$Date), max(nhs_pathways$Date)),
               expand = c(0.01,0.01)) +
  scale_fill_manual(values= c("#b5a7b6","#fdbf00","#cc6633", "#61b8d2","#00fdf6","#832157","#ef4d96", '#5a535b'),
                    breaks = c('Common cause variation', 'Close to limits', 'Special cause concern', 'Run above (shift)', 'Run below (shift)','Trend up (drift)', 'Trend down (drift)', 'Little variation'),
                    limits = c('Common cause variation', 'Close to limits', 'Special cause concern', 'Run above (shift)', 'Run below (shift)','Trend up (drift)', 'Trend down (drift)', 'Little variation'),
                    name = 'Variation key') +  
  scale_colour_manual(values=  c("#b5a7b6","#fdbf00","#cc6633", "#61b8d2","#00fdf6","#832157","#ef4d96", '#5a535b'),
                      breaks = c('Common cause variation', 'Close to limits', 'Special cause concern', 'Run above (shift)', 'Run below (shift)','Trend up (drift)', 'Trend down (drift)', 'Little variation'),
                      limits = c('Common cause variation', 'Close to limits', 'Special cause concern', 'Run above (shift)', 'Run below (shift)','Trend up (drift)', 'Trend down (drift)', 'Little variation'),
                      name = 'Variation key') +  
  scale_y_continuous(labels = comma,
                     breaks = seq(0,round_any(max(sussex_pathways$Triage_count, na.rm = TRUE), 500, ceiling),250)) +
  labs(x = 'Date',
       y = 'Number of complete triages',
       title = "Total number of complete triages to NHS Pathways for Covid-19; Sussex CCG's combined",
       subtitle = paste0('Triages via 111 online, 111 phone calls and 999 calls; 18 March - ', latest_triage_date$Date),
       caption = "Note: The red dotted lines represent 99% control limits (3σ, moving range) control limits respectively\nThe solid line represents the long term average.") +
  annotate(geom = 'text',
           x = as.Date('2020-04-08'), 
           y = as.numeric(subset(sussex_pathways, Date == as.Date('2020-04-09'), select = Triage_count)),
           label = '9th April',
           fontface = 'bold',
           size = 2.5,
           hjust = 1,
           vjust = 1) +
  annotate(geom = 'text',
           x = as.Date('2020-04-08'), 
           y = as.numeric(subset(sussex_pathways, Date == as.Date('2020-04-09'), select = Triage_count)),
           label = '111 online removed\nfor 0-18 year olds',
           size = 2.5,
           hjust = 1,
           vjust = 1.75) +
  annotate(geom = 'text',
           x = as.Date('2020-04-23'), 
           y = as.numeric(subset(sussex_pathways, Date == as.Date('2020-04-23'), select = Triage_count)),
           label = '23rd April',
           fontface = 'bold',
           size = 2.5,
           hjust = 0,
           vjust = -8) +
  annotate(geom = 'text',
           x = as.Date('2020-04-23'), 
           y = as.numeric(subset(sussex_pathways, Date == as.Date('2020-04-23'), select = Triage_count)),
           label = '111 online reinstated\nfor 5-18 year olds',
           size = 2.5,
           hjust = 0,
           vjust = -1.25) +
  annotate(geom = 'text',
           x = as.Date('2020-05-18'), 
           y = as.numeric(subset(sussex_pathways, Date == as.Date('2020-05-18'), select = Triage_count)),
           label = '18th May',
           size = 2.5,
           fontface = 'bold',
           hjust = 0,
           vjust = -6) +
  annotate(geom = 'text',
           x = as.Date('2020-05-18'), 
           y = as.numeric(subset(sussex_pathways, Date == as.Date('2020-05-18'), select = Triage_count)),
           label = 'Covid-19 pathway case\ndefinition change',
           size = 2.5,
           hjust = 0,
           vjust = -.5) +
  theme(legend.position = "bottom", 
        axis.text.x = element_text(angle = 90, hjust = 1, vjust = .5, size = 8),
        plot.background = element_rect(fill = "white", colour = "#E2E2E3"), 
        panel.background = element_rect(fill = '#ffffff'),
        axis.line = element_line(colour = "#E7E7E7", size = .3),
        axis.text = element_text(colour = "#000000", size = 8), 
        plot.title = element_text(colour = "#000000", face = "bold", size = 10, vjust = -.5), 
        axis.title = element_text(colour = "#000000", face = "bold", size = 8),     
        panel.grid = element_blank(), 
        strip.background = element_rect(fill = "#327d9c"),
        axis.ticks = element_line(colour = "#9e9e9e"),
        legend.key = element_rect(fill = '#ffffff'),
        legend.text = element_text(colour = "#000000", size = 8),
        legend.title = element_text(face = 'bold', size = 8))
