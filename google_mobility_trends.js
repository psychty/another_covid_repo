var request = new XMLHttpRequest();
request.open("GET", "./google_mobility_data.json", false);
request.send(null);
var mobility_data = JSON.parse(request.responseText);

var request = new XMLHttpRequest();
request.open("GET", "./google_mobility_data_accessed.json", false);
request.send(null);
var mobility_data_accessed_date = JSON.parse(request.responseText);

d3.select("#attribution_mobility_google")
  .html(function(d) {
    return 'Google LLC "Google COVID-19 Community Mobility Reports". https://www.google.com/covid19/mobility/ Accessed: ' + mobility_data_accessed_date[0]});

var svg_mobility_trends = d3.select("#mobility_trends_google")
  .append("svg")
  .attr("width", width_hm)
  .attr("height", height_line)
  .append("g")
  .attr("transform", "translate(" + 50 + "," + 20 + ")");

// We need to create a dropdown button for the user to choose which area to be displayed on the figure.
d3.select("#select_mobility_area_button")
  .selectAll('myOptions')
  .data(['Brighton and Hove', 'East Sussex', 'West Sussex', 'Bracknell Forest', 'Buckinghamshire', 'Hampshire', 'Isle of Wight', 'Kent', 'Medway', 'Milton Keynes', 'Oxfordshire', 'Portsmouth', 'Reading', 'Slough', 'Southampton', 'Surrey', 'West Berkshire', 'Windsor and Maidenhead', 'Wokingham'])
  .enter()
  .append('option')
  .text(function(d) {
    return d;
  })
  .attr("value", function(d) {
    return d;
  })

// Retrieve the selected area name
var chosen_mobility_area = d3.select('#select_mobility_area_button').property("value")

var chosen_mobility_df = deaths_by_week.filter(function(d) {
  return d.Name === chosen_m1_area
});

var chosen_mobility_df_latest = chosen_mobility_df.filter(function(d) {
  return d.Date === d3.max(chosen_mobility_df, function(d) {return +d.Date;})
})

console.log(chosen_mobility_df_latest)

  // d3.select("#selected_m1_title")
  //   .html(function(d) {
  //     return 'Changes in mobility  ' + ons_mortality_figures_dates[0].Occurring_week_ending + '; ' + chosen_mobility_area
  //   });
