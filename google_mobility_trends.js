var height_line_mobility = height_line + 150

var request = new XMLHttpRequest();
request.open("GET", "./google_mobility_data.json", false);
request.send(null);
var mobility_data = JSON.parse(request.responseText);

var mobility_change_range = d3.max([Math.abs(d3.min(mobility_data, function(d) {return +d.Comparison_to_baseline;})), d3.max(mobility_data, function(d) {return +d.Comparison_to_baseline;})])

mobility_change_range = Math.ceil(mobility_change_range / 10) *10

var request = new XMLHttpRequest();
request.open("GET", "./google_mobility_data_accessed.json", false);
request.send(null);
var mobility_data_accessed_date = JSON.parse(request.responseText);

var request = new XMLHttpRequest();
request.open("GET", "./google_mobility_earliest_date.json", false);
request.send(null);
var mobility_data_earliest_date = JSON.parse(request.responseText);

var request = new XMLHttpRequest();
request.open("GET", "./google_mobility_latest_date.json", false);
request.send(null);
var mobility_data_latest_date = JSON.parse(request.responseText);

d3.select("#attribution_mobility_google")
  .html(function(d) {
    return 'Google LLC "Google COVID-19 Community Mobility Reports". https://www.google.com/covid19/mobility/ Accessed: ' + mobility_data_accessed_date[0]});

var svg_mobility_trends = d3.select("#mobility_trends_google")
  .append("svg")
  .attr("width", width_hm)
  .attr("height", height_line_mobility)
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

var chosen_mobility_df = mobility_data.filter(function(d) {
  return d.Area === chosen_mobility_area
});

var latest_chosen_mobility = chosen_mobility_df.filter(function(d) {
  return d.Date === mobility_data_latest_date[0]
})

latest_grocery = latest_chosen_mobility.filter(function(d) {
  return d.Place === 'Grocery and pharmacy'
})[0]['Comparison_to_baseline']

latest_parks = latest_chosen_mobility.filter(function(d) {
  return d.Place === 'Parks'
})[0]['Comparison_to_baseline']

latest_public_transport = latest_chosen_mobility.filter(function(d) {
  return d.Place === 'Public transport'
})[0]['Comparison_to_baseline']

latest_retail = latest_chosen_mobility.filter(function(d) {
  return d.Place === 'Retail and recreation'
})[0]['Comparison_to_baseline']

latest_residential = latest_chosen_mobility.filter(function(d) {
  return d.Place === 'Residential'
})[0]['Comparison_to_baseline']

latest_workplace = latest_chosen_mobility.filter(function(d) {
  return d.Place === 'Workplaces'
})[0]['Comparison_to_baseline']


var grouped_mobility = d3.nest() // nest function allows to group the calculation per level of a factor
  .key(function(d) { return d.Place;})
  .entries(chosen_mobility_df);

// color palette
var colour_mobility = d3.scaleOrdinal()
  .domain(['Grocery and pharmacy', 'Public transport', 'Parks', 'Retail and recreation', 'Residential', 'Workplaces'])
  .range(['#D7457A', '#26589D', '#DDA241', '#612762', '#7D9B5A', '#DBB2E2'])

days_mobility = chosen_mobility_df.map(function(d) {return (d.Date);});

var x_mobility = d3.scaleBand()
  .domain(days_mobility)
  .range([0, width_hm * .6]) // this is the 50 that was pushed over from the left plus another 10 so that the chart does not get cut off
  .padding([0.2]);

var xAxis_mobility = svg_mobility_trends
  .append("g")
  .attr("transform", 'translate(0,' + (height_line_mobility - 120) + ")")
  .call(d3.axisBottom(x_mobility).tickSizeOuter(0));

xAxis_mobility
  .selectAll("text")
  .attr("transform", 'translate(-10,10)rotate(-90)')
  .style("text-anchor", "end")
  .each(function(d,i) {
    if (i%2 == 0) d3.select(this).remove();
    });

var y_mobility_ts = d3.scaleLinear()
  .domain([0 - mobility_change_range, mobility_change_range])
  .range([height_line_mobility - 120, 0])
  .nice()

var y_mobility_ts_axis = svg_mobility_trends
  .append("g")
  .attr("transform", 'translate(0,0)')
  .call(d3.axisLeft(y_mobility_ts).tickFormat(d3.format(',.0f')));

svg_mobility_trends
  .append('line')
  .attr('id', 'mobility_baseline')
  .attr('x1', 0)
  .attr('y1', y_mobility_ts(0))
  .attr('x2', width_hm * .6)
  .attr('y2', y_mobility_ts(0))
  .attr('stroke', '#000000')
  .attr("stroke-dasharray", ("3, 3"))

svg_mobility_trends
  .append("text")
  .attr("x", width_hm * .65)
  .attr("y", 20)
  .attr('id', 'mobility_chosen_area_label')
  .attr("text-anchor", "start")
  .text(chosen_mobility_area)
  .style('font-weight', 'bold')
  .style("font-size", "18px")

svg_mobility_trends
  .append("text")
  .attr("x", width_hm * .65)
  .attr("y", 40)
  .attr("text-anchor", "start")
  .text(mobility_data_latest_date[0])
  // .style('font-weight', 'bold')
  .style("font-size", "14px")

svg_mobility_trends
    .append("circle")
    .attr("cx", width_hm * .66)
    .attr("cy", 65)
    .attr("r", 10)
    .attr("fill", function(d) { return colour_mobility('Grocery and Pharmacy'); })

svg_mobility_trends
  .append("text")
  .attr("x", width_hm * .66 + 15)
  .attr("y", 70)
  // .attr('id', 'm2_home_latest_all_1')
  .attr("text-anchor", "start")
  .text('Grocery & Pharmacy')
  .style('font-weight', 'bold')
  .style("font-size", "12px")



svg_mobility_trends
    .append("circle")
    .attr("cx", width_hm * .66)
    .attr("cy", 95)
    .attr("r", 10)
    .attr("fill", function(d) { return colour_mobility('Parks'); })

svg_mobility_trends
  .append("text")
  .attr("x", width_hm * .66 + 15)
  .attr("y", 100)
  // .attr('id', 'm2_home_latest_all_1')
  .attr("text-anchor", "start")
  .text('Parks')
  .style('font-weight', 'bold')
  .style("font-size", "12px")

svg_mobility_trends
    .append("circle")
    .attr("cx", width_hm * .66)
    .attr("cy", 125)
    .attr("r", 10)
    .attr("fill", function(d) { return colour_mobility('Public transport'); })

svg_mobility_trends
  .append("text")
  .attr("x", width_hm * .66 + 15)
  .attr("y", 130)
  // .attr('id', 'm2_home_latest_all_1')
  .attr("text-anchor", "start")
  .text('Public transport')
  .style('font-weight', 'bold')
  .style("font-size", "12px")

svg_mobility_trends
    .append("circle")
    .attr("cx", width_hm * .66)
    .attr("cy", 155)
    .attr("r", 10)
    .attr("fill", function(d) { return colour_mobility('Retail and recreation'); })

svg_mobility_trends
  .append("text")
  .attr("x", width_hm * .66 + 15)
  .attr("y", 160)
  // .attr('id', 'm2_home_latest_all_1')
  .attr("text-anchor", "start")
  .text('Retail & recreation')
  .style('font-weight', 'bold')
  .style("font-size", "12px")

svg_mobility_trends
    .append("circle")
    .attr("cx", width_hm * .66)
    .attr("cy", 185)
    .attr("r", 10)
    .attr("fill", function(d) { return colour_mobility('Residential'); })

svg_mobility_trends
  .append("text")
  .attr("x", width_hm * .66 + 15)
  .attr("y", 190)
  // .attr('id', 'm2_home_latest_all_1')
  .attr("text-anchor", "start")
  .text('Residential')
  .style('font-weight', 'bold')
  .style("font-size", "12px")

svg_mobility_trends
    .append("circle")
    .attr("cx", width_hm * .66)
    .attr("cy", 215)
    .attr("r", 10)
    .attr("fill", function(d) { return colour_mobility('Workplaces'); })

svg_mobility_trends
  .append("text")
  .attr("x", width_hm * .66 + 15)
  .attr("y", 220)
  // .attr('id', 'm2_home_latest_all_1')
  .attr("text-anchor", "start")
  .text('Workplace')
  .style('font-weight', 'bold')
  .style("font-size", "12px")


svg_mobility_trends
  .append("text")
  .attr("x", width_hm * .66 + 145)
  .attr("y", 70)
  .attr('id', 'mobility_latest_grocery')
  .attr("text-anchor", "start")
  .text(function(d) {
  if ( typeof latest_grocery != 'number'){
    return 'no data'}
    else if ( latest_grocery >= 0){
      return '+' + latest_grocery + '%' }
      return latest_grocery + '%'
    })
  .style('font-weight', 'bold')
  .style("font-size", "16px")

svg_mobility_trends
  .append("text")
  .attr("x", width_hm * .66 + 50)
  .attr("y", 100)
  .attr('id', 'mobility_latest_parks')
  .attr("text-anchor", "start")
  .text(function(d) {
  if ( typeof latest_parks != 'number'){
    return 'no data'}
    else if ( latest_parks >= 0){
      return '+' + latest_parks + '%' }
      return latest_parks + '%'
    })
  .style('font-weight', 'bold')
  .style("font-size", "16px")

svg_mobility_trends
  .append("text")
  .attr("x", width_hm * .66 + 115)
  .attr("y", 130)
  .attr('id', 'mobility_latest_public')
  .attr("text-anchor", "start")
  .text(function(d) {
  if ( typeof latest_public_transport != 'number'){
    return 'no data'}
    else if ( latest_public_transport >= 0){
      return '+' + latest_public_transport + '%' }
      return latest_public_transport + '%'
    })
  .style('font-weight', 'bold')
  .style("font-size", "16px")

svg_mobility_trends
  .append("text")
  .attr("x", width_hm * .66 + 135)
  .attr("y", 160)
  .attr('id', 'mobility_latest_retail')
  .attr("text-anchor", "start")
  .text(function(d) {
  if ( typeof latest_retail != 'number'){
    return 'no data'}
    else if ( latest_retail >= 0){
      return '+' + latest_retail + '%' }
      return latest_retail + '%'
    })
  .style('font-weight', 'bold')
  .style("font-size", "16px")

svg_mobility_trends
  .append("text")
  .attr("x", width_hm * .66 + 85)
  .attr("y", 190)
  .attr('id', 'mobility_latest_residential')
  .attr("text-anchor", "start")
  .text(function(d) {
  if ( typeof latest_residential != 'number'){
    return 'no data'}
    else if ( latest_residential >= 0){
      return '+' + latest_residential + '%' }
      return latest_residential + '%'
    })
  .style('font-weight', 'bold')
  .style("font-size", "16px")

svg_mobility_trends
  .append("text")
  .attr("x", width_hm * .66 + 85)
  .attr("y", 220)
  .attr('id', 'mobility_latest_workplace')
  .attr("text-anchor", "start")
  .text(function(d) {
  if ( typeof latest_workplace != 'number'){
    return 'no data'}
    else if ( latest_workplace >= 0){
      return '+' + latest_workplace + '%' }
      return latest_workplace + '%'
    })
  .style('font-weight', 'bold')
  .style("font-size", "16px")

function update_mobility(chosen_mobility_area){
var chosen_mobility_area = d3.select('#select_mobility_area_button').property("value")

var chosen_mobility_df = mobility_data.filter(function(d) {
  return d.Area === chosen_mobility_area
});

var latest_chosen_mobility = chosen_mobility_df.filter(function(d) {
  return d.Date === mobility_data_latest_date[0]
})

latest_grocery = latest_chosen_mobility.filter(function(d) {
  return d.Place === 'Grocery and pharmacy'
})[0]['Comparison_to_baseline']

latest_parks = latest_chosen_mobility.filter(function(d) {
  return d.Place === 'Parks'
})[0]['Comparison_to_baseline']

latest_public_transport = latest_chosen_mobility.filter(function(d) {
  return d.Place === 'Public transport'
})[0]['Comparison_to_baseline']

latest_retail = latest_chosen_mobility.filter(function(d) {
  return d.Place === 'Retail and recreation'
})[0]['Comparison_to_baseline']

latest_residential = latest_chosen_mobility.filter(function(d) {
  return d.Place === 'Residential'
})[0]['Comparison_to_baseline']

latest_workplace = latest_chosen_mobility.filter(function(d) {
  return d.Place === 'Workplaces'
})[0]['Comparison_to_baseline']

days_mobility = chosen_mobility_df.map(function(d) {return (d.Date);});

d3.select("#selected_mobility_title")
  .html(function(d) {
    return 'Changes in mobility behaviours; Google location history data; ' +  chosen_mobility_area + '; ' + mobility_data_earliest_date[0] + ' - ' + mobility_data_latest_date[0]
  });

// group the data: I want to draw one line per group
var grouped_mobility = d3.nest() // nest function allows to group the calculation per level of a factor
  .key(function(d) { return d.Place;})
  .entries(chosen_mobility_df);

// Create a update selection: bind to the new data
var update_mobility_trend = svg_mobility_trends.selectAll(".lineTest")
  .data(grouped_mobility);

// Updata the line
update_mobility_trend
  .enter()
  .append("path")
  .attr("class","lineTest")
  .merge(update_mobility_trend)
  .transition()
  .duration(1000)
  .attr("fill", "none")
  .attr("stroke", function(d){ return colour_mobility(d.key) })
  .attr("stroke-width", 1.5)
  .attr("d", function(d){
      return d3.line()
      .defined(d => !isNaN(d.Comparison_to_baseline))
      .x(function(d) { return x_mobility(d.Date); })
      .y(function(d) { return y_mobility_ts(+d.Comparison_to_baseline); })
      (d.values)
        })

svg_mobility_trends
    .selectAll("#mobility_chosen_area_label")
    .remove();
svg_mobility_trends
    .selectAll("#mobility_latest_grocery")
    .remove();
svg_mobility_trends
    .selectAll("#mobility_latest_parks")
    .remove();
svg_mobility_trends
    .selectAll("#mobility_latest_retail")
    .remove();
svg_mobility_trends
    .selectAll("#mobility_latest_public")
    .remove();
svg_mobility_trends
    .selectAll("#mobility_latest_residential")
    .remove();
svg_mobility_trends
    .selectAll("#mobility_latest_workplace")
    .remove();

svg_mobility_trends
  .append("text")
  .attr("x", width_hm * .65)
  .attr("y", 20)
  .attr('id', 'mobility_chosen_area_label')
  .attr("text-anchor", "start")
  .text(chosen_mobility_area)
  .style('font-weight', 'bold')
  .style("font-size", "18px")

svg_mobility_trends
  .append("text")
  .attr("x", width_hm * .66 + 145)
  .attr("y", 70)
  .attr('id', 'mobility_latest_grocery')
  .attr("text-anchor", "start")
  .text(function(d) {
  if ( typeof latest_grocery != 'number'){
    return 'no data'}
    else if ( latest_grocery >= 0){
      return '+' + latest_grocery + '%' }
      return latest_grocery + '%'
    })
  .style('font-weight', 'bold')
  .style("font-size", "16px")

svg_mobility_trends
  .append("text")
  .attr("x", width_hm * .66 + 50)
  .attr("y", 100)
  .attr('id', 'mobility_latest_parks')
  .attr("text-anchor", "start")
  .text(function(d) {
  if ( typeof latest_parks != 'number'){
    return 'no data'}
    else if ( latest_parks >= 0){
      return '+' + latest_parks + '%' }
      return latest_parks + '%'
    })
  .style('font-weight', 'bold')
  .style("font-size", "16px")

svg_mobility_trends
  .append("text")
  .attr("x", width_hm * .66 + 115)
  .attr("y", 130)
  .attr('id', 'mobility_latest_public')
  .attr("text-anchor", "start")
  .text(function(d) {
  if ( typeof latest_public_transport != 'number'){
    return 'no data'}
    else if ( latest_public_transport >= 0){
      return '+' + latest_public_transport + '%' }
      return latest_public_transport + '%'
    })
  .style('font-weight', 'bold')
  .style("font-size", "16px")

svg_mobility_trends
  .append("text")
  .attr("x", width_hm * .66 + 135)
  .attr("y", 160)
  .attr('id', 'mobility_latest_retail')
  .attr("text-anchor", "start")
  .text(function(d) {
  if ( typeof latest_retail != 'number'){
    return 'no data'}
    else if ( latest_retail >= 0){
      return '+' + latest_retail + '%' }
      return latest_retail + '%'
    })
  .style('font-weight', 'bold')
  .style("font-size", "16px")

svg_mobility_trends
  .append("text")
  .attr("x", width_hm * .66 + 85)
  .attr("y", 190)
  .attr('id', 'mobility_latest_residential')
  .attr("text-anchor", "start")
  .text(function(d) {
  if ( typeof latest_residential != 'number'){
    return 'no data'}
    else if ( latest_residential >= 0){
      return '+' + latest_residential + '%' }
      return latest_residential + '%'
    })
  .style('font-weight', 'bold')
  .style("font-size", "16px")

svg_mobility_trends
  .append("text")
  .attr("x", width_hm * .66 + 85)
  .attr("y", 220)
  .attr('id', 'mobility_latest_workplace')
  .attr("text-anchor", "start")
  .text(function(d) {
  if ( typeof latest_workplace != 'number'){
    return 'no data'}
    else if ( latest_workplace >= 0){
      return '+' + latest_workplace + '%' }
      return latest_workplace + '%'
    })
  .style('font-weight', 'bold')
  .style("font-size", "16px")
}

update_mobility()

d3.select("#select_mobility_area_button").on("change", function(d) {
var chosen_mobility_area = d3.select('#select_mobility_area_button').property("value")

  update_mobility(chosen_mobility_area)
})
