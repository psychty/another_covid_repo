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

nhs_pathways_all_ages_persons %>% 
  filter(CCG_Name == 'NHS West Sussex CCG') %>% 
  View()

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
