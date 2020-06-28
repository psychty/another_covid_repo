
# Walkthrough to identify range of health outcomes and wider determinents for BAME groups.
# tracking mortality
library(easypackages)

libraries(c("readxl", "readr", "plyr", "dplyr", "ggplot2", "tidyverse", "reshape2", "scales", 'jsonlite', 'zoo', 'stats', 'aweek', 'epitools', 'fingertipsR', 'PHEindicatormethods'))

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
# Infographic on ICU audit and ONS slides of deaths 

# https://www.icnarc.org/Our-Audit/Audits/Cmp/Reports 

# https://www.ons.gov.uk/peoplepopulationandcommunity/birthsdeathsandmarriages/deaths/articles/coronavirusrelateddeathsbyethnicgroupenglandandwales/2march2020to10april2020

# https://www.ons.gov.uk/peoplepopulationandcommunity/birthsdeathsandmarriages/deaths/methodologies/coronavirusrelateddeathsbyethnicgroupenglandandwalesmethodology

# https://www.imperial.ac.uk/media/imperial-college/medicine/mrc-gida/2020-04-29-COVID19-Report-17.pdf

# infant and maternal mortality

mortality_neonatal <- PHEindicatormethods::phe_rate(read_csv(paste0(github_repo_dir, '/infant_mortality_rates_ons_2017_birthcohort.csv')), `Neonatal deaths`, `Live births`, multiplier = 1000)%>% 
  write.csv(., paste0(github_repo_dir, '/neo_morality.csv'))

mortality_infant <- PHEindicatormethods::phe_rate(read_csv(paste0(github_repo_dir, '/infant_mortality_rates_ons_2017_birthcohort.csv')), `Infant deaths`, `Live births`, multiplier = 1000) %>% 
  write.csv(., paste0(github_repo_dir, '/infant_morality.csv'))


# low birthweight - not available by ethnicity
# breastfeeding - Number of live babies born in the period whose mothers are resident within the local authority (residence based on mother's postcode), whose first feed is known to be breastmilk, including expressed and donor milk (BabyFirstFeedBreastMilkStatus is '1' or '2') - indicator 93580
fingertips_data(IndicatorID = 93580, AreaTypeID = 202, categorytype = TRUE) %>% 
  filter(CategoryType == 'Ethnic groups') %>% 
  mutate(Label = paste0(round(Value, 1), '% (95% CI: ', round(LowerCI95.0limit, 1), '-', round(UpperCI95.0limit, 1), ')')) %>% 
  select(Category, Label)


# readiness for school

# download.file('https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/877992/EYFSP_pupil_characteristics_2019_underlying_data.zip', paste0(github_repo_dir, '/eyfsp_pupil.zip'), mode = 'wb')
# unzip(paste0(github_repo_dir,'/eyfsp_pupil.zip'), exdir = github_repo_dir)

readiness_ks1 <- read_excel(paste0(github_repo_dir, '/EYFSP_LA_1_key_measures_additional_tables_2013_2019.xlsx')) %>% 
  filter(time_period == '201819') %>% 
  filter(is.na(la_name) | la_name %in% c('Brighton and Hove','East Sussex','West Sussex')) %>% 
  filter(is.na(region_name) | region_name == 'South East') %>% 
  filter(gender == 'Total') %>% 
  filter(characteristic == 'Ethnicity') %>% 
  mutate(la_name = ifelse(is.na(region_name), 'England', ifelse(is.na(la_name), region_name, la_name))) %>% 
  select(la_name, characteristic_type, number_of_pupils, elg_number, elg_percent) %>% 
  mutate(number_of_pupils = as.numeric(number_of_pupils),
         elg_number = as.numeric(elg_number)) %>% 
  mutate(elg_recalculated = elg_number / number_of_pupils,
         elg_lci = PHEindicatormethods:::wilson_lower(elg_number, number_of_pupils),
         elg_uci = PHEindicatormethods:::wilson_upper(elg_number, number_of_pupils)) %>% 
  mutate(label = paste0(round(elg_recalculated * 100, 1), '% (', round(elg_lci * 100, 1), '-', round(elg_uci * 100, 1),'%)')) %>% 
  mutate(la_name = factor(la_name, levels = c('Brighton and Hove', 'East Sussex','West Sussex', 'South East', 'England')))

readiness_ks1_total <- readiness_ks1 %>% 
  filter(characteristic_type == 'Total')

readiness_ks1_table <- readiness_ks1 %>% 
  select(characteristic_type, la_name, label) %>% 
  spread(characteristic_type, label) %>% 
  select(la_name, White, Asian, Black, Chinese, Mixed, Total) %>% 
  arrange(la_name) %>% 
  write.csv(., paste0(github_repo_dir, '/readiness_ks1.csv'))

# Overall, West Sussex has similar readiness for school rates compared to England and Brighton and Hover, but has significantly lower rates of children meeting or exceeding the expected levels of development compared to East Sussex and the South East region.

# achieving good level development at ks2

gld_ks2 <- read_excel(paste0(github_repo_dir, '/ks2_2019_revised_la_ud.xlsx'), col_types = c("numeric", "text", "text", "text", "text", "text", "text", "numeric", "numeric", "text", "text", "text", "text", "text", "text", "text", "text", "text", "text", "text", "text", "text", "text", "text", "text", "text", "numeric","numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "text", "text", "text", "text", "text", "text", "numeric", "numeric", "numeric", "numeric", "text", "text", "text", "text", "numeric", "text", "text", "text", "text", "numeric", "text", "text", "text", "text")) %>% 
  filter(time_period == '201819') %>% 
  mutate(la_name = ifelse(is.na(region_name), 'England', ifelse(is.na(la_name), region_name, la_name))) %>% 
  filter(la_name %in% c('Brighton and Hove','East Sussex','West Sussex', 'South East', 'England')) %>% 
  filter(gender == 'Total',
         breakdown == 'ethnic_major') %>% 
  select(la_name, ethnic_major,  t_rwm_elig,	t_rwm_exp,	pt_rwm_exp) %>% 
  mutate(t_rwm_elig = as.numeric(t_rwm_elig),
         t_rwm_exp = as.numeric(t_rwm_exp)) %>% 
  mutate(gld_recalculated = t_rwm_exp / t_rwm_elig,
         gld_lci = PHEindicatormethods:::wilson_lower(t_rwm_exp, t_rwm_elig),
         gld_uci = PHEindicatormethods:::wilson_upper(t_rwm_exp, t_rwm_elig)) %>% 
  mutate(label = paste0(round(gld_recalculated * 100, 1), '% (', round(gld_lci * 100, 1), '-', round(gld_uci * 100, 1),'%)'))

gld_ks2_table <- gld_ks2 %>% 
  select(ethnic_major, la_name, label) %>% 
  spread(ethnic_major, label) %>% 
  # select(la_name, White, Asian, Black, Chinese, Mixed, Total) %>% 
  arrange(la_name) %>% 
  write.csv(., paste0(github_repo_dir, '/gld_ks2.csv'))


fingertips_data(IndicatorID = 20601, AreaTypeID = 202, categorytype = TRUE) %>% 
  filter(CategoryType == 'Ethnic groups') %>% 
  mutate(Label = paste0(round(Value, 1), '% (95% CI: ', round(LowerCI95.0limit, 1), '-', round(UpperCI95.0limit, 1), ')')) %>% 
  select(Category, Label, IndicatorName, Timeperiod) %>% 
  write.csv(., paste0(github_repo_dir, '/overweight_Reception.csv'))




fingertips_data(IndicatorID = 20602, AreaTypeID = 202, categorytype = TRUE) %>% 
  filter(CategoryType == 'Ethnic groups') %>% 
  mutate(Label = paste0(round(Value, 1), '% (95% CI: ', round(LowerCI95.0limit, 1), '-', round(UpperCI95.0limit, 1), ')')) %>% 
  select(Category, Label, IndicatorName, Timeperiod) %>% 
  write.csv(., paste0(github_repo_dir, '/overweight_yearsix.csv'))

# achieving good level development at ks4

attainment_8_ks4 <-  read_excel("~/Documents/Repositories/another_covid_repo/2019_KS4_Revised_Local_authority_characteristics_data.xlsx", sheet = "KS4 LA characteristics data") %>% 
  filter(time_period == '201819') %>% 
  mutate(la_name = ifelse(is.na(region_name), 'England', ifelse(is.na(la_name), region_name, la_name))) %>% 
  filter(la_name %in% c('Brighton and Hove','East Sussex','West Sussex', 'South East', 'England')) %>% 
  filter(breakdown == 'Ethnic major') %>% 
  filter(characteristic_gender == 'Total') %>% 
  select(la_name, characteristic_Ethnic_major, avg_att8) %>% 
  spread(characteristic_Ethnic_major, avg_att8) %>% 
  select(la_name, WHITE, ASIAN, BLACK, CHINESE, MIXED) %>% 
  write.csv(., paste0(github_repo_dir, '/attainment_8.csv'))

# child poverty
Child_poverty_UK_under_16 <- data.frame(Ethnicity_hoh = c('White','Mixed/Multiple ethnic groups','Asian/Asian British','Black/African/Caribbean/Black British', 'Other ethnic groups'),Percentage_in_low_income = c(10,21,15,21,22), Percentage_in_severe_low_income = c(4,8,7,10,7))%>% 
  write.csv(., paste0(github_repo_dir, '/child_pov.csv'))




# No data
# unintentional_injuries <- fingertips_data(93224,  AreaTypeID = 101, categorytype = TRUE) #%>% 
  # filter(CategoryType == 'Ethnic groups')

# No data on teenage pregnancy

Smoking <- fingertips_data(92443, AreaTypeID = 101, categorytype = TRUE) %>% 
  filter(CategoryType == 'Ethnic groups') %>% 
  filter(Timeperiod == 2018) %>% 
  View()



# White and mixed groups significantly higher current smoking prevalence compared to other groups. Black, Chinese, and Asian groups have the lowest current smoking prevalence.

# NEET

neet <- fingertips_data(IndicatorID = 93203,  AreaTypeID = 202, categorytype = TRUE) %>% 
  filter(CategoryType == 'Ethnic groups') %>% 
  filter(Timeperiod == 2018)

indicator_metadata(93203) %>% 
  View()


fingertips_data(IndicatorID = 93088,  AreaTypeID = 202, categorytype = TRUE) %>% 
  filter(CategoryType == 'Ethnic groups') %>% 
  filter(Timeperiod == '2018/19') %>% 
  mutate(Label = paste0(round(Value, 1), '% (95% CI: ', round(LowerCI95.0limit, 1), '-', round(UpperCI95.0limit, 1), ')')) %>% 
  select(Category, Label, IndicatorName, Timeperiod) %>% 
  write.csv(., paste0(github_repo_dir, '/overweightadult.csv'))




# first_time_criminal_system <- fingertips_data(IndicatorID = 10401,  AreaTypeID = 101, categorytype = TRUE)

# mental health indicators

# Prevalence common MH disorder
# Pecentage in treatment



# housing and overcrowding
# lack of car in household

gpps_prevalence <- read_csv(paste0(github_repo_dir, '/prevalence_ltcs_gp_patient_survey_england_2019.csv'))

hypertension_diabetes <- gpps_prevalence %>% 
  select(Q56, `Weighted Base`, Diabetes,`A breathing condition, such as asthma or COPD`, `High blood pressure`) %>% 
  rename(Ethnicity = Q56,
         Denominator = `Weighted Base`) %>% 
  gather(key = 'Condition', value = 'Patients', Diabetes:`High blood pressure`) %>% 
  mutate(Prevalence = paste0(round(Patients / Denominator * 100,1),'%')) %>% 
  mutate(Prevalence_lci = paste0(round(PHEindicatormethods:::wilson_lower(Patients, Denominator) *100,2), '%'),
         Prevalence_uci = paste0(round(PHEindicatormethods:::wilson_upper(Patients, Denominator) *100,2), '%'))

# hypertension
# diabetes
# screening uptake and health checks
# flu vaccination uptake

# % bame by occupation (JC says elementary occupation)
# % bame in NHS senior roles compared to overall workforce
# access to primary care

# manage own condition

# similar

manage_condition <- read_excel("/Users/richtyler/Downloads/nhs-out-fram-feb-20-xslx/NHSOF_2.1_I00706_D.xlsx", 
                               sheet = "Indicator data", skip = 13) %>% 
  filter(Breakdown == 'Ethnicity') %>% 
  filter(Year == '2018/19') %>% 
  mutate(Prevalence = paste0(round(Numerator / Denominator * 100,1),'%')) %>% 
  mutate(Prevalence_lci = paste0(round(PHEindicatormethods:::wilson_lower(Numerator, Denominator) *100,2), '%'),
         Prevalence_uci = paste0(round(PHEindicatormethods:::wilson_upper(Numerator, Denominator) *100,2), '%')) %>% 
  mutate(label = paste0(Prevalence, '(',Prevalence_lci, '-', Prevalence_uci,')')) %>% 
  write.csv(., paste0(github_repo_dir, '/ltc_manage.csv'))



gp_satis <- read_excel("/Users/richtyler/Downloads/nhs-out-fram-feb-20-xslx/NHSOF_4a.i_I00739_D.xlsx", 
                               sheet = "Indicator data", skip = 13) %>% 
  filter(Breakdown == 'Ethnicity') %>% 
  filter(Year == '2018/19') %>% 
  mutate(Prevalence = paste0(round(Numerator / Denominator * 100,1),'%')) %>% 
  mutate(Prevalence_lci = paste0(round(PHEindicatormethods:::wilson_lower(Numerator, Denominator) *100,2), '%'),
         Prevalence_uci = paste0(round(PHEindicatormethods:::wilson_upper(Numerator, Denominator) *100,2), '%')) %>% 
  mutate(label = paste0(Prevalence, '(',Prevalence_lci, '-', Prevalence_uci,')')) %>% 
  write.csv(., paste0(github_repo_dir, '/gp_satisfaction.csv'))

# slide on ICU data ethnicity

ethnicity_icnarc <- read_excel("~/Documents/Repositories/another_covid_repo/Table Appendix 2020-05-29.xlsx.xlsx", sheet = "Ethnicity", skip = 2) %>% 
  gather(key = 'Population', value = 'Percentage', 'COVID-19':'Matched to local population') %>% 
  mutate(Patients = c('5,690', '145', '1,275', '831', '555', NA, NA, NA, NA, NA))

ggplot(ethnicity_icnarc, aes(x = Population, y = `Percentage`, fill = Ethnicity)) +
  geom_bar(position = 'stack',
           stat = 'identity') +
  coord_flip()

icnarc_ethnicity <-  ggplot(ethnicity_icnarc, 
       aes(x = Ethnicity,
           y = Percentage,
           fill = Population)) +
  geom_bar(stat = 'identity',
           position = 'dodge') +
  labs(title = 'Ethnicity groups of 8,496 patients critically ill with confirmed Covid-19; ',
       subtitle = 'ICNARC Case Mix Programme Database 29/05/2020',
       y = 'Percentage of patients') +
  scale_y_continuous(limits = c(0,80),
                     breaks = seq(0, 100, 10),
                     labels = unit_format(suffix = '%')) +
  scale_fill_manual(values = c('#4c2954', '#7ea6f8'),
                    name = '') +
  geom_text(size = 3.5,
            vjust = -1,
            position = position_dodge(width = 1),
            aes(label = Patients)) +
  ph_theme() +
  theme(axis.text.x = element_text(hjust = 0.5))

png(paste0(github_repo_dir, "/icnarc_ethnicicty_patients.png"), width = 900, height = 650, res = 150)
icnarc_ethnicity
dev.off()

# PHE data 

# download.file('https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/889167/Disparities_risks_outcomes_of_COVID19_data_pack.ods', paste0(github_repo_dir, '/Covid_datapack_phe.ods'), mode = 'wb')
# 
# library('readODS')
# 
# age_standardised_confirmed_cases <- read_ods(paste0(github_repo_dir, '/Covid_datapack_phe.ods'), sheet = "Table_2a", skip = 6, col_names = FALSE) 
# 
# age_standardised_confirmed_cases <- age_standardised_confirmed_cases %>%  
#   select(-`Region Code`)#, `Region Name`)) #%>% 
#   colnames(., c('Area_code', 'Area_name',	'Males_cases','Males_population','Males_rate','Males_lci', 'Males_uci', 'Females_cases', 'Females_population', 'Females_rate', 'Females_lci', 'Females_uci', 'Total_cases', 'Total_population', 'Total_rate', 'Total_lci', 'Total_uci'))
