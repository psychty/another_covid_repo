
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

