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
  return local_areas_compare.indexOf(d.Name) >= 0
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
    return 'Details of the postcode of residence are matched to Office for National Statistics (ONS) administrative geography codes. As of ' + latest_date + ', ' + d3.format(',.0f')(d.Unconfirmed) + ' cases (' + d3.format('.0%')(d.Proportion_unconfirmed) + ') of the ' + d3.format(',.0f')(d.England) + ' cases in England were not attributed to a local area. It is possible that some of these unconfirmed cases are from the areas analysed here.'
  });
