library(easypackages)


libraries(c("readxl", "readr", "plyr", "dplyr", "ggplot2", "tidyverse", "reshape2", "scales", 'jsonlite', 'zoo', 'stats', 'fingertipsR', 'epitools', 'projections', 'incidence', 'xml2', 'rvest'))

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

# NHS pathway analysis

# Many caveats around this, not counts of people, people might not use this or might use it multiple times over the course of their symptoms (and maybe not at the start of their symptoms).

# https://digital.nhs.uk/data-and-information/publications/statistical/mi-potential-covid-19-symptoms-reported-through-nhs-pathways-and-111-online/latest

# Might be useful to have a cumulative count of number of people using the system
# West Sussex CCG has 390 triages per 100,000, whilst cases are around 26 diagnosed cases per 100,000. YOU ARE COMPARING SMALL APPLES AND REALLY RIPE CRAB APPLES

# People are encouraged NOT to call NHS 111 to report Covid-19 symptoms unless they are worried but are asked to complete an NHS 111 online triage assessment.

# nhs_111_online %>% 
# filter(journeydate == '31/03/2020') %>% 
# filter(ccgname %in% c('NHS Coastal West Sussex CCG', 'NHS Crawley CCG', 'NHS Horsham and Mid Sussex CCG')) %>% 
# summarise(Total = sum(Total, na.rm = TRUE))

# CCG to NHS England lookup - tidy mergers

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

# Daily deaths by trust

# This webscraping method is great if the data uploader puts a typo in the filepath, but may break if other files are uploaded with similar names. I think it will work more of the time than the method I have been using.

# An alternative that I have been using takes the system date from the computer to change the filepath.
# This should download the data for today (it will only work after the new file is published at 5pm though), shame on those who release new filenames each day and do not allow for a static url.

# This is a bit of a hack. If you run the script before a new file is uploaded it will obviously fail. So at the very least, you'll get the updated file from yesterday 
# download.file(paste0('https://www.england.nhs.uk/statistics/wp-content/uploads/sites/2/2020/',format(Sys.Date(), '%m'),'/COVID-19-total-announced-deaths-',format(Sys.Date(), '%d-%B-%Y'),'.xlsx'), paste0(github_repo_dir, '/refreshed_daily_deaths_trust.xlsx'), mode = 'wb')
 
# if the downlaod does fail, it wipes out the old one, which we can use to our advantage.
# if(!file.exists(paste0(github_repo_dir, '/refreshed_daily_deaths_trust.xlsx'))){
# download.file(paste0('https://www.england.nhs.uk/statistics/wp-content/uploads/sites/2/2020/',format(Sys.Date()-1, '%m'),'/COVID-19-total-announced-deaths-',format(Sys.Date()-1, '%d-%B-%Y'),'.xlsx'), paste0(github_repo_dir, '/refreshed_daily_deaths_trust.xlsx'), mode = 'wb')
# }

# find urls on a page
scraped_urls <- read_html('https://www.england.nhs.uk/statistics/statistical-work-areas/covid-19-daily-deaths/') %>%
  html_nodes("a") %>%
  html_attr("href")

# search for our specific url (the filename always contains this string). This will return all strings
url <- grep('COVID-19-total-announced-deaths', scraped_urls, value = T)

#2nd query inverts findings to ignore new weekly file and only take summary
query_url2 <- "weekly-table"
trust_deaths_url <- grep(query_url2, url, value = T, invert = T)

nhs_2018_pop <- read_csv('https://raw.githubusercontent.com/qleclerc/nhs_pathways_report/master/data/csv/nhs_region_population_2018.csv')

# NHS Pathway Data
calls_webpage <- read_html('https://digital.nhs.uk/data-and-information/publications/statistical/mi-potential-covid-19-symptoms-reported-through-nhs-pathways-and-111-online/latest') %>%
  html_nodes("a") %>%
  html_attr("href")

nhs_111_pathways_raw <- read_csv(grep('NHS%20Pathways%20Covid-19%20data%202020', calls_webpage, value = T))  %>% 
  rename(CCG_Name = CCGName) %>% 
  mutate(Date = as.Date(`Call Date`, format = '%d/%m/%Y')) %>% 
  select(-`Call Date`) %>% 
  mutate(AgeBand = ifelse(is.na(AgeBand), 'Unknown', AgeBand))
  
nhs_111_pathways_post_april <- nhs_111_pathways_raw %>% 
  filter(Date >= '2020-04-01') %>% 
  left_join(ccg_region_2020[c('New_CCG_Code', 'NHS_region')], by = c('CCGCode' ='New_CCG_Code')) %>% 
  filter(!is.na(NHS_region)) %>% 
  rename(New_CCG_Code = CCGCode,
         New_CCG_Name = CCG_Name)

nhs_111_pathways_pre_april <- nhs_111_pathways_raw %>% 
  filter(Date < '2020-04-01') %>% 
  left_join(ccg_region_2019[c('Old_CCG_Code','New_CCG_Code', 'New_CCG_Name')], by = c('CCGCode' = 'Old_CCG_Code')) %>% 
  group_by(New_CCG_Code, New_CCG_Name, Date, AgeBand, Sex, SiteType) %>% 
  summarise(TriageCount = sum(TriageCount, na.rm = TRUE)) %>% 
  left_join(ccg_region_2020[c('New_CCG_Code', 'NHS_region')], by = 'New_CCG_Code') %>% 
  ungroup() %>% 
  filter(!is.na(NHS_region))

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

nhs_pathways <- nhs_111_pathways %>% 
  bind_rows(nhs_111_online) %>% 
  rename(CCG_Code = New_CCG_Code,
         CCG_Name = New_CCG_Name)
  
nhs_pathways_all_ages_persons <- nhs_pathways %>% 
  group_by(CCG_Code, CCG_Name, Date, Pathway) %>% 
  summarise(Triage_count = sum(Triage_count)) %>% 
  group_by(CCG_Code, CCG_Name, Pathway) %>% 
  arrange(CCG_Code, Pathway, Date) %>% 
  mutate(Number_change = Triage_count - lag(Triage_count),
         Percentage_change = (Triage_count - lag(Triage_count))/ lag(Triage_count))

rm(ccg_region_2019, ccg_region_2020, nhs_111_online, nhs_111_online_pre_april, nhs_111_online_post_april, nhs_111_online_raw, nhs_111_pathways, nhs_111_pathways_raw, calls_webpage, query_url2, scraped_urls, url)

nhs_pathways_all_ages_persons_all_pathways <- nhs_pathways %>% 
  group_by(CCG_Code, CCG_Name, Date) %>% 
  summarise(Triage_count = sum(Triage_count)) %>% 
  group_by(CCG_Code, CCG_Name) %>% 
  arrange(CCG_Code, Date) %>% 
  mutate(Number_change = Triage_count - lag(Triage_count),
         Percentage_change = (Triage_count - lag(Triage_count))/ lag(Triage_count))
  
wsx_pathways <- nhs_pathways_all_ages_persons_all_pathways %>% 
  filter(CCG_Name == 'NHS West Sussex CCG') 

ggplot(wsx_pathways,
       aes(x = Date,
           y = Triage_count,
           group = 1)) +
  geom_line() +
  geom_point() +
  scale_x_date(date_labels = "%b %d",
               breaks = seq.Date(max(nhs_pathways$Date) -(52*7), max(nhs_pathways$Date), by = 7),
               limits = c(min(nhs_pathways$Date), max(nhs_pathways$Date)),
               expand = c(0.01,0.01)) +
  scale_y_continuous(labels = comma) +
  ph_theme() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = .5)) 

esx_pathways <- nhs_pathways_all_ages_persons_all_pathways %>% 
  filter(CCG_Name == 'NHS East Sussex CCG') 

ggplot(esx_pathways,
       aes(x = Date,
           y = Triage_count,
           group = 1)) +
  geom_line() +
  geom_point() +
  scale_x_date(date_labels = "%b %d",
               breaks = seq.Date(max(nhs_pathways$Date) -(52*7), max(nhs_pathways$Date), by = 7),
               limits = c(min(nhs_pathways$Date), max(nhs_pathways$Date)),
               expand = c(0.01,0.01)) +
  scale_y_continuous(labels = comma) +
  ph_theme() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = .5)) 

bh_pathways <- nhs_pathways_all_ages_persons_all_pathways %>% 
  filter(CCG_Name == 'NHS Brighton and Hove CCG') 

ggplot(bh_pathways,
       aes(x = Date,
           y = Triage_count,
           group = 1)) +
  geom_line() +
  geom_point() +
  scale_x_date(date_labels = "%b %d",
               breaks = seq.Date(max(nhs_pathways$Date) -(52*7), max(nhs_pathways$Date), by = 7),
               limits = c(min(nhs_pathways$Date), max(nhs_pathways$Date)),
               expand = c(0.01,0.01)) +
  scale_y_continuous(labels = comma) +
  ph_theme() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = .5)) 

nhs_pathways_england <- nhs_pathways %>% 
  group_by(Date) %>% 
  summarise(Triage_count = sum(Triage_count)) %>% 
  arrange(Date) %>% 
  mutate(Number_change = Triage_count - lag(Triage_count),
         Percentage_change = (Triage_count - lag(Triage_count))/ lag(Triage_count))

ggplot(nhs_pathways_england,
       aes(x = Date,
           y = Triage_count,
           group = 1)) +
  geom_line() +
  geom_point() +
  scale_x_date(date_labels = "%b %d",
               breaks = seq.Date(max(nhs_pathways$Date) -(52*7), max(nhs_pathways$Date), by = 7),
               limits = c(min(nhs_pathways$Date), max(nhs_pathways$Date)),
               expand = c(0.01,0.01)) +
  scale_y_continuous(labels = comma) +
  ph_theme() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = .5)) 

wsx_pathways_by_method <- nhs_pathways_all_ages_persons %>% 
  filter(CCG_Name == 'NHS West Sussex CCG')

# SPC wsx ####

# Brilliant post I found after a few hours trying to figure out the difference between SD and sigma. https://r-bar.net/xmr-control-chart-tutorial-examples/ this explains the constant value 1.128

# These are our conditions periods. We will want to highlight any consecutive data points in which the last five are above or below the process mean, in addition we want to highlight any periods of six or more values which are increasing or decreasing.

run_length <- 6
trend_length <- 7

wsx_spc <- wsx_pathways %>% 
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
  mutate(rule_2a = rollapplyr(above_mean, run_length, sum, align = 'right', partial = TRUE)) %>% # sum the last five (or whatever 'run_length' is) values for 'above_mean'. if the sum is 5 (or whatever 'run_length' is set to) then you know that there have been at least this many consecutive values above the process mean and this constitues a 'run'. 
  mutate(rule_2a_label = rollapply(rule_2a, run_length, function(x)if(any(x == run_length)) 'Run above (shift)' else 'No run', align = 'left', partial = TRUE)) %>% # Now we want to identify all values related to that above run which means we have to look forward (using align = 'left') to see if a value should be included in a run. Here, ScrewID 8 is at the beginning of a run. Although the rule_2 for ScrewID 8 = 1 (meaning that only ScrewID 8 was above the mean (and ScrewID 4-7 were not)), looking in the other direction you can see that for ScrewID 12 it has a rule_2 value of 5 (meaning that ScrewID 8-12 were all above the mean).
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

# TO DO 

ggplot(data = wsx_spc, aes(x = Date, y = Triage_count, group = 1)) +
  geom_hline(aes(yintercept = process_mean),
             colour = "#264852",
             lwd = .8) +
  geom_line(colour = '#999999') +
  geom_point(aes(fill =  top_label,
                 colour = top_label), 
             size = 4, 
             shape = 21) +
  geom_hline(aes(yintercept = lower_control_limit),
             colour = "#A8423F",
             linetype="dotted",
             lwd = .7) +
  geom_hline(aes(yintercept = upper_control_limit),
             colour = "#A8423F",
             linetype="dotted",
             lwd = .7) +
  geom_hline(aes(yintercept = two_sigma_uci),
             colour = "#3d2b65",
             linetype="dashed",
             lwd = .7) +
  geom_hline(aes(yintercept = two_sigma_lci),
             colour = "#3d2b65",
             linetype="dashed",
             lwd = .7) +
  geom_hline(aes(yintercept = one_sigma_uci),
             colour = "#45748d",
             linetype="solid",
             lwd = .4) +
  geom_hline(aes(yintercept = one_sigma_lci),
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


ggplot(data = wsx_spc, aes(x = Date, y = Triage_count, group = 1)) +
annotate('rect',
         xmin = min(nhs_pathways$Date) ,
         xmax = max(nhs_pathways$Date) ,
         ymin = wsx_spc$one_sigma_lci,
         ymax = wsx_spc$one_sigma_uci,
         fill = '#d2e8f5',
         alpha = .01) +
  annotate('rect',
           xmin = min(nhs_pathways$Date) ,
           xmax = max(nhs_pathways$Date) ,
           ymin = wsx_spc$one_sigma_uci,
           ymax = wsx_spc$two_sigma_uci,
           fill = '#ffecd4',
           alpha = .01) +
  annotate('rect',
           xmin = min(nhs_pathways$Date),
           xmax = max(nhs_pathways$Date),
           ymin = wsx_spc$one_sigma_lci,
           ymax = wsx_spc$two_sigma_lci,
           fill = '#ffecd4',
           alpha = .01) +
  annotate('rect',
           xmin = min(nhs_pathways$Date) ,
           xmax = max(nhs_pathways$Date) ,
           ymin = wsx_spc$two_sigma_uci,
           ymax = wsx_spc$upper_control_limit,
           fill = '#edcf66',
           alpha = .01) +
  annotate('rect',
           xmin = min(nhs_pathways$Date) ,
           xmax = max(nhs_pathways$Date) ,
           ymin = wsx_spc$two_sigma_lci,
           ymax = wsx_spc$lower_control_limit,
           fill = '#edcf66',
           alpha = .01) +
  geom_hline(aes(yintercept = process_mean),
             colour = "#264852",
             lwd = .8) +
  geom_hline(aes(yintercept = lower_control_limit),
             colour = "#A8423F",
             linetype="dotted",
             lwd = .7) +
  geom_hline(aes(yintercept = upper_control_limit),
             colour = "#A8423F",
             linetype="dotted",
             lwd = .7) +
  geom_line(colour = '#999999') +
  geom_point(aes(fill =  top_label,
                 colour = top_label), 
             size = 4, 
             shape = 21) +
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
  labs(caption = "Note: Y axis does not start at zero.\nThe red dotted lines represent 99% control limits (3σ, moving range) control limits respectively\nThe solid line represents the long term average.") +
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

# to do group_by(process_number) to show step change

# This data is based on potential COVID-19 symptoms reported by members of the public to NHS Pathways through NHS 111 or 999 and 111 online,  and is not based on the outcomes of tests for coronavirus.
# This is not a count of people. In 111 online, any user that starts and launches the COVID-19 assessment services is indicating they may have symptoms of coronavirus. They may have accessed the service multiple times with different symptoms.
# The North East, West Midlands, South East Coast, South Central, and Isle of Wight Ambulance Services use NHS Pathways to triage calls to 999. The North West, Yorkshire, East Midlands, East of England, London, and South Western Ambulance Services use another system to triage calls to 999. Therefore, for CCGs in those areas, data here will not include most 999 calls related to COVID-19.
# NHS Pathways data is sourced from a live system that is updated every 15 minutes. The data is extracted for the dashboard and open data files with as little delay as possible but there can be a time delay between the extraction processes meaning that the dashboard and open data files may have different totals.
# Users of 111 online can change answers and reach multiple dispositions so the data indicates those users that have started an assessment and completed a final disposition.
# Users enter their current location which may differ from their home postcode.
# 111 online updated the service on the 9th April so that under 16s are directed to use the normal 111 online triage. Due to small numbers data for 17 and 18 year olds has been suppressed and therefore does not appear in the data. This means that data for the 0-18 age band is no longer available in the 111 online data and is not included within the overall totals for 111 online.
# 111 online updated the service on the 23rd April so that there is now a separate covid assessment for 5 - 15 year olds. This means that from data for 23rd April 2020 onwards the 0-18 age band will be reinstated into the 111 online data and will cover ages from 5 to 18 years old.
# Following the changes to the assessment of COVID-19 in NHS Pathways release 19.3.8 (on 18th May) those receiving a specific COVID-19 disposition will be reduced due to the following reasons:
#   Previously anyone with a symptom that was thought to be COVID (e.g. cold of flu like symptoms) would be assessed via a specific COVID pathway and would only receive a COVID disposition, whereas in release 19.3.8 those with cold or flu like symptoms will only receive a COVID specific disposition if they meet the case definition of breathlessness, continuous cough, loss of smell or fever.  All other symptoms will be assessed and a non COVID disposition reached.
# Previously all children under 5 were assessed using the COVID specific pathways, in release 19.3.8 this is no longer the case and will receive a non COVID disposition on assessment as their risk of COVID is low but higher risk of a non COVID related illness and therefore requires further assessment. 
# Those Adults calling with Chest Pain would have previously received a COVID specific disposition now they will only receive a COVID specific disposition if chest pain with fever or cough.
# Also, there were some random calls such as those with injuries receiving COVID as the question was asked ahead of illness and injury split.
