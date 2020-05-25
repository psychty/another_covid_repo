var request = new XMLHttpRequest();
request.open("GET", "./google_mobility_data.json", false);
request.send(null);
var mobility_data = JSON.parse(request.responseText);

var request = new XMLHttpRequest();
request.open("GET", "./google_mobility_data_accessed.json", false);
request.send(null);
var mobility_data_accessed_date = JSON.parse(request.responseText);

d3.select("#attribution_mobility_google")
  // .data(mobility_data)
  .html(function(d) {
    return 'Google LLC "Google COVID-19 Community Mobility Reports". https://www.google.com/covid19/mobility/ Accessed: ' + mobility_data_accessed_date[0]});

var svg_mobility_trends = d3.select("#mobility_trends_google")
  .append("svg")
  .attr("width", width_hm)
  .attr("height", height_line)
  .append("g")
  .attr("transform", "translate(" + 50 + "," + 20 + ")");
