// var width_hm = 900
var width_hm = document.getElementById("content_size").offsetWidth;

var height_hm = 25
var height_hm_title = 45
var height_hm_explainer = 15

var incomplete_colour = '#999999'

var areas = ['Brighton and Hove', 'Bracknell Forest', 'Buckinghamshire', 'East Sussex', 'Hampshire', 'Isle of Wight', 'Kent', 'Medway', 'Milton Keynes', 'Oxfordshire', 'Portsmouth', 'Reading', 'Slough', 'Southampton', 'Surrey', 'West Berkshire', 'West Sussex', 'Windsor and Maidenhead', 'Wokingham']

var local_areas_compare = ['Brighton and Hove', 'East Sussex', 'West Sussex', 'Sussex areas combined', 'South East region', 'England']

var request = new XMLHttpRequest();
request.open("GET", "./se_case_summary.json", false);
request.send(null);
var case_summary = JSON.parse(request.responseText); // parse the fetched json data into a variable

var sussex_summary = case_summary.filter(function(d, i) {
  return d.Name === 'Sussex areas combined'
})

var se_summary = case_summary.filter(function(d, i) {
  return areas.indexOf(d.Name) >= 0
})

var request = new XMLHttpRequest();
request.open("GET", "./se_daily_cases.json", false);
request.send(null);

var daily_cases = JSON.parse(request.responseText); // parse the fetched json data into a variable

var request = new XMLHttpRequest();
request.open("GET", "./daily_cases_bands.json", false);
request.send(null);

var new_cases_bands = JSON.parse(request.responseText); // parse the fetched json data into a variable
var new_cases_colours = ['#ffffb2','#fed976','#feb24c','#fd8d3c','#fc4e2a','#e31a1c','#b10026']
var color_new_cases = d3.scaleOrdinal()
  .domain(new_cases_bands)
  .range(new_cases_colours)

var request = new XMLHttpRequest();
request.open("GET", "./daily_cases_per_100000_bands.json", false);
request.send(null);

var new_cases_per_100000_bands = JSON.parse(request.responseText); // parse the fetched json data into a variable
var new_cases_colours = ['#ffffb2', '#fed976', '#feb24c', '#fd8d3c', '#f03b20', '#bd0026']
var color_new_per_100000_cases = d3.scaleOrdinal()
  .domain(new_cases_per_100000_bands)
  .range(new_cases_colours)

var dates = d3.map(daily_cases, function(d) {
    return (d.Date_label)
  })
  .keys()

var request = new XMLHttpRequest();
request.open("GET", "./se_daily_cases_doubling_shown.json", false);
request.send(null);
var doubling_shown_df = JSON.parse(request.responseText); // parse the fetched json data into a variable

var request = new XMLHttpRequest();
request.open("GET", "./range_dates.json", false);
request.send(null);

var first_date = JSON.parse(request.responseText).filter(function(d) {
  return d.Order == 'First'
})[0]['Date_label']

var complete_date = JSON.parse(request.responseText).filter(function(d) {
  return d.Order == 'Complete'
})[0]['Date_label']

var complete_date_actual = JSON.parse(request.responseText).filter(function(d) {
  return d.Order == 'Complete'
})[0]['Date']

var first_incomplete_date = JSON.parse(request.responseText).filter(function(d) {
  return d.Order == 'First_incomplete'
})[0]['Date_label']

var first_incomplete_date_actual = JSON.parse(request.responseText).filter(function(d) {
  return d.Order == 'First_incomplete'
})[0]['Date']

var latest_date = JSON.parse(request.responseText).filter(function(d) {
  return d.Order == 'Last'
})[0]['Date_label']

var most_recent = JSON.parse(request.responseText).filter(function(d) {
  return d.Order == 'Last'
})[0]['Date']

d3.select("#data_recency")
  .html(function(d) {
    return 'The latest available data in this analysis are for <b>' + latest_date + '</b>. However, as data for recent days are likely to change significantly, <b> only data up to <b>' + complete_date + ' should be treated as complete</b>.'
  });

var request = new XMLHttpRequest();
request.open("GET", "./unconfirmed_latest.json", false);
request.send(null);
var unconfirmed_latest = JSON.parse(request.responseText);

d3.select("#unconfirmed_cases_count")
  .data(unconfirmed_latest)
  .html(function(d) {
    return 'The first section explores the number of diagnosed coronavirus (Covid-19) cases recorded daily by Public Health England (PHE) for Upper Tier Local Authority and Unitary Authority (UTLA) areas. Details of the postcode of residence are matched to Office for National Statistics (ONS) administrative geography codes. As of ' + latest_date + ', ' + d3.format(',.0f')(d.Unconfirmed) + ' cases (' + d3.format('.0%')(d.Proportion_unconfirmed) + ') of the ' + d3.format(',.0f')(d.England) + ' cases in England were not attributed to a local area. It is possible that some of these unconfirmed cases are from the areas analysed here.'
  });

d3.select("#sussex_latest_figures")
  .data(sussex_summary)
  .html(function(d) {
    return 'The total number of confirmed Covid-19 cases so far across Sussex areas combined is <b>' + d3.format(',.0f')(d['Total confirmed cases so far'])  + '</b>. This is ' + d3.format(',.0f')(d['Total cases per 100,000 population']) + ' cases per 100,000 population. The current daily case count (using data from ' + complete_date + ') is ' + d3.format(',.0f')(d['Confirmed cases swabbed on most recent complete day']) + ' new confirmed cases swabbed (' + d3.format(',.1f')(d['Confirmed cases swabbed per 100,000 population on most recent complete day']) + ' per 100,000).' });

d3.select("#doubling_time_sussex_narrative")
  .data(sussex_summary)
  .html(function(d) {
    return 'The table also shows the length of time it takes the total (cumulative) number of confirmed cases to double over the specified time period (in this case <u>five days</u>). In the three Sussex areas combined, ' + d.summary_label_doubling.replace('In','in') });
