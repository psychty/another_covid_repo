///////////////////////////////
// x = week = place of death //
///////////////////////////////

var request = new XMLHttpRequest();
    request.open("GET", "./deaths_covid_by_place_SE.json", false);
    request.send(null);
var deaths_by_week_place_covid = JSON.parse(request.responseText); // parse the fetched json data into a variable

var request = new XMLHttpRequest();
    request.open("GET", "./cumulative_deaths_covid_by_place_SE.json", false);
    request.send(null);
var cumulative_deaths_by_week_place_covid = JSON.parse(request.responseText); // parse the fetched json data into a variable

// We need to create a dropdown button for the user to choose which area to be displayed on the figure.
d3.select("#select_mortality_3_area_button")
  .selectAll('myOptions')
  .data(['Sussex areas combined', 'England', 'Brighton and Hove', 'East Sussex', 'West Sussex', 'Bracknell Forest', 'Buckinghamshire', 'Hampshire', 'Isle of Wight', 'Kent', 'Medway', 'Milton Keynes', 'Oxfordshire', 'Portsmouth', 'Reading', 'Slough', 'Southampton', 'Surrey', 'West Berkshire', 'Windsor and Maidenhead', 'Wokingham'])
  .enter()
  .append('option')
  .text(function(d) {
    return d;
  })
  .attr("value", function(d) {
    return d;
  })

// Retrieve the selected area name
var chosen_m3_area = d3.select('#select_mortality_3_area_button').property("value")

var chosen_m3_df = deaths_by_week_place_covid.filter(function(d) {
  return d.Name === chosen_m3_area
});

var chosen_latest_m3 = chosen_m3_df.filter(function(d) {
  return d.Week_number === d3.max(chosen_m3_df, function(d) {return +d.Week_number;})
})

var chosen_latest_m3_cumulative = cumulative_deaths_by_week_place_covid.filter(function(d) {
  return d.Week_number === d3.max(chosen_m3_df, function(d) {return +d.Week_number;}) &
         d.Name === chosen_m3_area
})

var stackedData_m3 = d3.stack()
    .keys(death_places)
    (chosen_m3_df)

weeks_m3 = chosen_m3_df.map(function(d) {return (d.Date_label);});

d3.select("#selected_m3_title")
  .html(function(d) {
    return 'Covid-19 deaths (all ages) by week of occurrence and place of death; 2020 up to ' + ons_mortality_figures_dates[0].Occurring_week_ending + '; ' + chosen_m3_area
    });

// Create a tooltip for the lines and functions for displaying the tooltips as well as highlighting certain lines.
var tooltip_m3 = d3.select("#covid_mortality_by_place")
  .append("div")
  .style("opacity", 0)
  .attr("class", "tooltip_class")
  .style("position", "absolute")
  .style("z-index", "10")
  .style("background-color", "white")
  .style("border", "solid")
  .style("border-width", "1px")
  .style("border-radius", "5px")
  .style("padding", "10px")

var showTooltip_m3 = function(d, i) {
    var placeName_covid = d3.select(this.parentNode).datum().key;
    var placeValue_covid = d.data[placeName_covid];

// // Reduce opacity of all rect to 0.2
//     d3.selectAll(".myRect")
//       .style("opacity", 0.5)
//     // Highlight all rects of this subgroup with opacity 0.8. It is possible to select them since they have a specific class = their name.
//     d3.selectAll("." + death_place_tag(placeName))
//       .style("opacity", 1)

tooltip_m3
  .html("<h5>" + d.data.Name + '</h5><p class = "side">Week number ' + d.data.Week_number + ' - ' + d.data.Date_label + '</p><p><b>' + placeName_covid + '</b></p><p class = "side">There were <b>' + d3.format(',.0f')(placeValue_covid) + ' deaths</b> occurring ' + death_place_label(placeName_covid) + ' in ' + d.data.Date_label + ' that have been registered so far with some mention of Covid-19 on the death certificate.</p><p>The deaths ' + death_place_label(placeName_covid) + ' represent <b>' + d3.format('.1%')(placeValue_covid / d.data['All places']) + ' </b>of Covid-19 deaths occurring in this week.</p>')
  .style("opacity", 1)
  .attr('visibility', 'visible')
  .style("top", (event.pageY - 10) + "px")
  .style("left", (event.pageX + 10) + "px")
  .style("visibility", "visible");
}

var mouseleave_m3 = function(d) {
tooltip_m3
  .style("visibility", "hidden")

 d3.selectAll(".myRect")
      .style("opacity",1)
}

// append the svg object to the body of the page
var svg_fg_mortality_3 = d3.select("#covid_mortality_by_place")
 .append("svg")
  .attr("width", width_hm)
  .attr("height", height_line)
  .append("g")
  .attr("transform", "translate(" + 50 + "," + 20 + ")");

var x_m3 = d3.scaleBand()
  .domain(weeks_m3)
  .range([0, width_hm * .6]) // this is the 50 that was pushed over from the left plus another 10 so that the chart does not get cut off
  .padding([0.2]);

var xAxis_mortality_3 = svg_fg_mortality_3
  .append("g")
  .attr("transform", 'translate(0,' + (height_line - 90) + ")")
  .call(d3.axisBottom(x_m3).tickSizeOuter(0));

xAxis_mortality_3
  .selectAll("text")
  .attr("transform", 'translate(-10,10)rotate(-90)')
  .style("text-anchor", "end")

var y_m3_ts = d3.scaleLinear()
  .domain([0, d3.max(chosen_m3_df, function(d) {return +d['All places'];})])
  .range([height_line - 90, 0])
  .nice()

var y_m3_ts_axis = svg_fg_mortality_3
  .append("g")
  .attr("transform", 'translate(0,0)')
  .call(d3.axisLeft(y_m3_ts).tickFormat(d3.format(',.0f')));

var bars_m3 = svg_fg_mortality_3
 .append("g")
 .selectAll("g")
 .data(stackedData_m3)
 .enter().append("g")
 .attr("fill", function(d) { return colour_place_of_death(d.key); })
 .attr("class", function(d){ return "myRect " + death_place_tag(d.key) }) // Add a class to each subgroup: their name
 .selectAll("rect")
 .data(function(d) { return d; })
 .enter().append("rect")
 .attr("x", function(d) { return x_m3(d.data.Date_label); })
 .attr("y", function(d) { return y_m3_ts(d[1]); })
 .attr("height", function(d) { return y_m3_ts(d[0]) - y_m3_ts(d[1]); })
 .attr("width",x_m3.bandwidth())
 .on('mousemove', showTooltip_m3)
 .on('mouseout', mouseleave_m3)

svg_fg_mortality_3
  .append("text")
  .attr("x", width_hm * .65)
  .attr("y", 10)
  .attr("text-anchor", "start")
  .text('Covid-19 deaths')
  .style('font-weight', 'bold')
  .style("font-size", "18px")

svg_fg_mortality_3
  .append("text")
  .attr("x", width_hm * .65)
  .attr("y", 35)
  .attr('id', 'm3_chosen_area')
  .attr("text-anchor", "start")
  .text(chosen_m3_area)
  .style('font-weight', 'bold')
  .style("font-size", "18px")

svg_fg_mortality_3
  .append("text")
  .attr("x", width_hm * .65)
  .attr("y", 50)
  .attr("text-anchor", "start")
  .text('so far in 2020 up to ' + ons_mortality_figures_dates[0].Occurring_week_ending)

svg_fg_mortality_3
    .append("circle")
    .attr("cx", width_hm * .66)
    .attr("cy", 72)
    .attr("r", 10)
    .attr("fill", function(d) { return colour_place_of_death('Home'); })

svg_fg_mortality_3
  .append("text")
  .attr("x", width_hm * .66 + 15)
  .attr("y", 80)
  .attr('id', 'm3_home_latest_all_1')
  .attr("text-anchor", "start")
  .text(d3.format(',.0f')(chosen_latest_m3_cumulative[0]['Home']))
  .style('font-weight', 'bold')
  .style("font-size", "22px")

svg_fg_mortality_3
  .append("text")
  .attr('id', 'm3_home_latest_all_2')
  .attr("x", function(d) {
    if ( chosen_latest_m3_cumulative[0]['Home'] >= 10000){
      return width_hm * .66 + 90 }
      else if ( chosen_latest_m3_cumulative[0]['Home'] >= 1000) {
      return width_hm * .66 + 80 }
      else if ( chosen_latest_m3_cumulative[0]['Home'] >= 100) {
      return width_hm * .66 + 60 }
      else {
      return width_hm * .66 + 50
    }})
  .attr("y", 70)
  .attr("text-anchor", "start")
  .text('deaths occurring at home')

svg_fg_mortality_3
  .append("text")
  .attr('id', 'm3_home_latest_all_3')
  .attr("x", function(d) {
    if (chosen_latest_m3_cumulative[0]['Home'] >= 10000){
      return width_hm * .66 + 90 }
      else if (chosen_latest_m3_cumulative[0]['Home'] >= 1000) {
      return width_hm * .66 + 80 }
      else if (chosen_latest_m3_cumulative[0]['Home'] >= 100) {
      return width_hm * .66 + 60 }
      else {
      return width_hm * .66 + 50
    }})
  .attr("y", 80)
  .attr("text-anchor", "start")
  .text('this is ' + d3.format('.1%')(chosen_latest_m3_cumulative[0]['Home']/ chosen_latest_m3_cumulative[0]['All places']) + ' of all Covid-19 deaths in 2020.')

svg_fg_mortality_3
    .append("circle")
    .attr("cx", width_hm * .66)
    .attr("cy", 102)
    .attr("r", 10)
    .attr("fill", function(d) { return colour_place_of_death('Care home'); })

svg_fg_mortality_3
  .append("text")
  .attr("x", width_hm * .66 + 15)
  .attr("y", 110)
  .attr('id', 'm3_carehome_latest_all_1')
  .attr("text-anchor", "start")
  .text(d3.format(',.0f')(chosen_latest_m3_cumulative[0]['Care home']))
  .style('font-weight', 'bold')
  .style("font-size", "22px")

svg_fg_mortality_3
  .append("text")
  .attr('id', 'm3_carehome_latest_all_2')
  .attr("x", function(d) {
    if ( chosen_latest_m3_cumulative[0]['Care home'] >= 10000){
      return width_hm * .66 + 90 }
      else if ( chosen_latest_m3_cumulative[0]['Care home'] >= 1000) {
      return width_hm * .66 + 80 }
      else if ( chosen_latest_m3_cumulative[0]['Care home'] >= 100) {
      return width_hm * .66 + 60 }
      else {
      return width_hm * .66 + 50
    }})
  .attr("y", 100)
  .attr("text-anchor", "start")
  .text('Covid-19 deaths occurring in a care home')

svg_fg_mortality_3
  .append("text")
  .attr('id', 'm3_carehome_latest_all_3')
  .attr("x", function(d) {
    if ( chosen_latest_m3_cumulative[0]['Care home'] >= 10000){
      return width_hm * .66 + 90 }
      else if (chosen_latest_m3_cumulative[0]['Care home'] >= 1000) {
      return width_hm * .66 + 80 }
      else if (chosen_latest_m3_cumulative[0]['Care home'] >= 100) {
      return width_hm * .66 + 60 }
      else {
      return width_hm * .66 + 50
    }})
  .attr("y", 110)
  .attr("text-anchor", "start")
  .text('this is ' + d3.format('.1%')(chosen_latest_m3_cumulative[0]['Care home']/ chosen_latest_m3_cumulative[0]['All places']) + ' of all Covid-19 deaths in 2020.')

svg_fg_mortality_3
    .append("circle")
    .attr("cx", width_hm * .66)
    .attr("cy", 132)
    .attr("r", 10)
    .attr("fill", function(d) { return colour_place_of_death('Hospital'); })

svg_fg_mortality_3
  .append("text")
  .attr("x", width_hm * .66 + 15)
  .attr("y", 140)
  .attr('id', 'm3_hospital_latest_all_1')
  .attr("text-anchor", "start")
  .text(d3.format(',.0f')(chosen_latest_m3_cumulative[0]['Hospital']))
  .style('font-weight', 'bold')
  .style("font-size", "22px")

svg_fg_mortality_3
  .append("text")
  .attr('id', 'm3_hospital_latest_all_2')
  .attr("x", function(d) {
    if ( chosen_latest_m3_cumulative[0]['Hospital'] >= 10000){
      return width_hm * .66 + 90 }
      else if ( chosen_latest_m3_cumulative[0]['Hospital'] >= 1000) {
      return width_hm * .66 + 80 }
      else if ( chosen_latest_m3_cumulative[0]['Hospital'] >= 100) {
      return width_hm * .66 + 60 }
      else {
      return width_hm * .66 + 50
    }})
  .attr("y", 130)
  .attr("text-anchor", "start")
  .text('Covid-19 deaths occurring in hospital')

svg_fg_mortality_3
  .append("text")
  .attr('id', 'm3_hospital_latest_all_3')
  .attr("x", function(d) {
    if ( chosen_latest_m3_cumulative[0]['Hospital'] >= 10000){
      return width_hm * .66 + 90 }
      else if (chosen_latest_m3_cumulative[0]['Hospital'] >= 1000) {
      return width_hm * .66 + 80 }
      else if (chosen_latest_m3_cumulative[0]['Hospital'] >= 100) {
      return width_hm * .66 + 60 }
      else {
      return width_hm * .66 + 50
    }})
  .attr("y", 140)
  .attr("text-anchor", "start")
  .text('this is ' + d3.format('.1%')(chosen_latest_m3_cumulative[0]['Hospital']/ chosen_latest_m3_cumulative[0]['All places']) + ' of all Covid-19 deaths in 2020.')

svg_fg_mortality_3
    .append("circle")
    .attr("cx", width_hm * .66)
    .attr("cy", 162)
    .attr("r", 10)
    .attr("fill", function(d) { return colour_place_of_death('Hospice'); })

svg_fg_mortality_3
  .append("text")
  .attr("x", width_hm * .66 + 15)
  .attr("y", 170)
  .attr('id', 'm3_hospice_latest_all_1')
  .attr("text-anchor", "start")
  .text(d3.format(',.0f')(chosen_latest_m3_cumulative[0]['Hospice']))
  .style('font-weight', 'bold')
  .style("font-size", "22px")

svg_fg_mortality_3
  .append("text")
  .attr('id', 'm3_hospice_latest_all_2')
  .attr("x", function(d) {
    if ( chosen_latest_m3_cumulative[0]['Hospice'] >= 10000){
      return width_hm * .66 + 90 }
      else if ( chosen_latest_m3_cumulative[0]['Hospice'] >= 1000) {
      return width_hm * .66 + 80 }
      else if ( chosen_latest_m3_cumulative[0]['Hospice'] >= 100) {
      return width_hm * .66 + 60 }
      else {
      return width_hm * .66 + 50
    }})
  .attr("y", 160)
  .attr("text-anchor", "start")
  .text('Covid-19 deaths occurring in a hospice')

svg_fg_mortality_3
  .append("text")
  .attr('id', 'm3_hospice_latest_all_3')
  .attr("x", function(d) {
    if ( chosen_latest_m3_cumulative[0]['Hospice'] >= 10000){
      return width_hm * .66 + 90 }
      else if (chosen_latest_m3_cumulative[0]['Hospice'] >= 1000) {
      return width_hm * .66 + 80 }
      else if (chosen_latest_m3_cumulative[0]['Hospice'] >= 100) {
      return width_hm * .66 + 60 }
      else {
      return width_hm * .66 + 50
    }})
  .attr("y", 170)
  .attr("text-anchor", "start")
  .text('this is ' + d3.format('.1%')(chosen_latest_m3_cumulative[0]['Hospice']/ chosen_latest_m3_cumulative[0]['All places']) + ' of all Covid-19 deaths in 2020.')

svg_fg_mortality_3
    .append("circle")
    .attr("cx", width_hm * .66)
    .attr("cy", 192)
    .attr("r", 10)
    .attr("fill", function(d) { return colour_place_of_death('Elsewhere (including other communal establishments)'); })

svg_fg_mortality_3
  .append("text")
  .attr("x", width_hm * .66 + 15)
  .attr("y", 200)
  .attr('id', 'm3_elsewhere_latest_all_1')
  .attr("text-anchor", "start")
  .text(d3.format(',.0f')(chosen_latest_m3_cumulative[0]['Elsewhere (including other communal establishments)']))
  .style('font-weight', 'bold')
  .style("font-size", "22px")

svg_fg_mortality_3
  .append("text")
  .attr('id', 'm3_elsewhere_latest_all_2')
  .attr("x", function(d) {
    if ( chosen_latest_m3_cumulative[0]['Elsewhere (including other communal establishments)'] >= 10000){
      return width_hm * .66 + 90 }
      else if ( chosen_latest_m3_cumulative[0]['Elsewhere (including other communal establishments)'] >= 1000) {
      return width_hm * .66 + 80 }
      else if ( chosen_latest_m3_cumulative[0]['Elsewhere (including other communal establishments)'] >= 100) {
      return width_hm * .66 + 60 }
      else {
      return width_hm * .66 + 50
    }})
  .attr("y", 190)
  .attr("text-anchor", "start")
  .text('Covid-19 deaths occurring somewhere else')

svg_fg_mortality_3
  .append("text")
  .attr('id', 'm3_elsewhere_latest_all_3')
  .attr("x", function(d) {
    if ( chosen_latest_m3_cumulative[0]['Elsewhere (including other communal establishments)'] >= 10000){
      return width_hm * .66 + 90 }
      else if (chosen_latest_m3_cumulative[0]['Elsewhere (including other communal establishments)'] >= 1000) {
      return width_hm * .66 + 80 }
      else if (chosen_latest_m3_cumulative[0]['Elsewhere (including other communal establishments)'] >= 100) {
      return width_hm * .66 + 60 }
      else {
      return width_hm * .66 + 50
    }})
  .attr("y", 200)
  .attr("text-anchor", "start")
  .text('this is ' + d3.format('.1%')(chosen_latest_m3_cumulative[0]['Elsewhere (including other communal establishments)']/ chosen_latest_m3_cumulative[0]['All places']) + ' of all Covid-19 deaths in 2020.')

function update_m3_all_cause_place(){
var chosen_m3_area = d3.select('#select_mortality_3_area_button').property("value")

var chosen_m3_df = deaths_by_week_place_covid.filter(function(d) {
  return d.Name === chosen_m3_area
});

var chosen_latest_m3 = chosen_m3_df.filter(function(d) {
  return d.Week_number === d3.max(chosen_m3_df, function(d) {return +d.Week_number;})
})

var chosen_latest_m3_cumulative = cumulative_deaths_by_week_place_covid.filter(function(d) {
  return d.Week_number === d3.max(chosen_m3_df, function(d) {return +d.Week_number;}) &
         d.Name === chosen_m3_area
})

var stackedData_m3 = d3.stack()
    .keys(death_places)
    (chosen_m3_df)

weeks_m3 = chosen_m3_df.map(function(d) {return (d.Date_label);});

d3.select("#selected_m3_title")
  .html(function(d) {
    return 'Covid-19 deaths (all ages) by week of occurrence and place of death; 2020 up to ' + ons_mortality_figures_dates[0].Occurring_week_ending + '; ' + chosen_m3_area
    });



y_m3_ts
  .domain([0, d3.max(chosen_m3_df, function(d) {return +d['All places'];})])
  .nice()

y_m3_ts_axis
  .transition()
  .duration(1000)
  .call(d3.axisLeft(y_m3_ts).tickFormat(d3.format(',.0f')));

svg_fg_mortality_3
.selectAll("rect")
.remove();

var bars_m3 = svg_fg_mortality_3
 .append("g")
 .selectAll("g")
 .data(stackedData_m3)
 .enter().append("g")
 .attr("fill", function(d) { return colour_place_of_death(d.key); })
 .attr("class", function(d){ return "myRect " + death_place_tag(d.key) }) // Add a class to each subgroup: their name
 .selectAll("rect")
 .data(function(d) { return d; })
 .enter().append("rect")
 .attr("x", function(d) { return x_m3(d.data.Date_label); })
 .attr("y", function(d) { return y_m3_ts(d[1]); })
 .attr("height", function(d) { return y_m3_ts(d[0]) - y_m3_ts(d[1]); })
 .attr("width",x_m3.bandwidth())
 .on('mousemove', showTooltip_m3)
 .on('mouseout', mouseleave_m3)

svg_fg_mortality_3
    .selectAll("#m3_chosen_area")
    .remove();
svg_fg_mortality_3
    .selectAll("#m3_home_latest_all_1")
    .remove();
svg_fg_mortality_3
    .selectAll("#m3_home_latest_all_2")
    .remove();
svg_fg_mortality_3
    .selectAll("#m3_home_latest_all_3")
    .remove();
svg_fg_mortality_3
    .selectAll("#m3_carehome_latest_all_1")
    .remove();
svg_fg_mortality_3
    .selectAll("#m3_carehome_latest_all_2")
    .remove();
svg_fg_mortality_3
    .selectAll("#m3_carehome_latest_all_3")
    .remove();
svg_fg_mortality_3
    .selectAll("#m3_hospital_latest_all_1")
    .remove();
svg_fg_mortality_3
    .selectAll("#m3_hospital_latest_all_2")
    .remove();
svg_fg_mortality_3
    .selectAll("#m3_hospital_latest_all_3")
    .remove();
svg_fg_mortality_3
    .selectAll("#m3_hospice_latest_all_1")
    .remove();
svg_fg_mortality_3
    .selectAll("#m3_hospice_latest_all_2")
    .remove();
svg_fg_mortality_3
    .selectAll("#m3_hospice_latest_all_3")
    .remove();
svg_fg_mortality_3
    .selectAll("#m3_elsewhere_latest_all_1")
    .remove();
svg_fg_mortality_3
    .selectAll("#m3_elsewhere_latest_all_2")
    .remove();
svg_fg_mortality_3
    .selectAll("#m3_elsewhere_latest_all_3")
    .remove();

svg_fg_mortality_3
  .append("text")
  .attr("x", width_hm * .65)
  .attr("y", 35)
  .attr('id', 'm3_chosen_area')
  .attr("text-anchor", "start")
  .text(chosen_m3_area)
  .style('font-weight', 'bold')
  .style("font-size", "18px")

svg_fg_mortality_3
  .append("text")
  .attr("x", width_hm * .66 + 15)
  .attr("y", 80)
  .attr('id', 'm3_home_latest_all_1')
  .attr("text-anchor", "start")
  .text(d3.format(',.0f')(chosen_latest_m3_cumulative[0]['Home']))
  .style('font-weight', 'bold')
  .style("font-size", "22px")

svg_fg_mortality_3
  .append("text")
  .attr('id', 'm3_home_latest_all_2')
  .attr("x", function(d) {
    if ( chosen_latest_m3_cumulative[0]['Home'] >= 10000){
      return width_hm * .66 + 90 }
      else if ( chosen_latest_m3_cumulative[0]['Home'] >= 1000) {
      return width_hm * .66 + 80 }
      else if ( chosen_latest_m3_cumulative[0]['Home'] >= 100) {
      return width_hm * .66 + 60 }
      else {
      return width_hm * .66 + 50
    }})
  .attr("y", 70)
  .attr("text-anchor", "start")
  .text('Covid-19 deaths occurring at home')

svg_fg_mortality_3
  .append("text")
  .attr('id', 'm3_home_latest_all_3')
  .attr("x", function(d) {
    if (chosen_latest_m3_cumulative[0]['Home'] >= 10000){
      return width_hm * .66 + 90 }
      else if (chosen_latest_m3_cumulative[0]['Home'] >= 1000) {
      return width_hm * .66 + 80 }
      else if (chosen_latest_m3_cumulative[0]['Home'] >= 100) {
      return width_hm * .66 + 60 }
      else {
      return width_hm * .66 + 50
    }})
  .attr("y", 80)
  .attr("text-anchor", "start")
  .text('this is ' + d3.format('.1%')(chosen_latest_m3_cumulative[0]['Home']/ chosen_latest_m3_cumulative[0]['All places']) + ' of all Covid-19 deaths in 2020.')

svg_fg_mortality_3
  .append("text")
  .attr("x", width_hm * .66 + 15)
  .attr("y", 110)
  .attr('id', 'm3_carehome_latest_all_1')
  .attr("text-anchor", "start")
  .text(d3.format(',.0f')(chosen_latest_m3_cumulative[0]['Care home']))
  .style('font-weight', 'bold')
  .style("font-size", "22px")

svg_fg_mortality_3
  .append("text")
  .attr('id', 'm3_carehome_latest_all_2')
  .attr("x", function(d) {
    if ( chosen_latest_m3_cumulative[0]['Care home'] >= 10000){
      return width_hm * .66 + 90 }
      else if ( chosen_latest_m3_cumulative[0]['Care home'] >= 1000) {
      return width_hm * .66 + 80 }
      else if ( chosen_latest_m3_cumulative[0]['Care home'] >= 100) {
      return width_hm * .66 + 60 }
      else {
      return width_hm * .66 + 50
    }})
  .attr("y", 100)
  .attr("text-anchor", "start")
  .text('Covid-19 deaths occurring in a care home')

svg_fg_mortality_3
  .append("text")
  .attr('id', 'm3_carehome_latest_all_3')
  .attr("x", function(d) {
    if ( chosen_latest_m3_cumulative[0]['Care home'] >= 10000){
      return width_hm * .66 + 90 }
      else if (chosen_latest_m3_cumulative[0]['Care home'] >= 1000) {
      return width_hm * .66 + 80 }
      else if (chosen_latest_m3_cumulative[0]['Care home'] >= 100) {
      return width_hm * .66 + 60 }
      else {
      return width_hm * .66 + 50
    }})
  .attr("y", 110)
  .attr("text-anchor", "start")
  .text('this is ' + d3.format('.1%')(chosen_latest_m3_cumulative[0]['Care home']/ chosen_latest_m3_cumulative[0]['All places']) + ' of all Covid-19 deaths in 2020.')

svg_fg_mortality_3
  .append("text")
  .attr("x", width_hm * .66 + 15)
  .attr("y", 140)
  .attr('id', 'm3_hospital_latest_all_1')
  .attr("text-anchor", "start")
  .text(d3.format(',.0f')(chosen_latest_m3_cumulative[0]['Hospital']))
  .style('font-weight', 'bold')
  .style("font-size", "22px")

svg_fg_mortality_3
  .append("text")
  .attr('id', 'm3_hospital_latest_all_2')
  .attr("x", function(d) {
    if ( chosen_latest_m3_cumulative[0]['Hospital'] >= 10000){
      return width_hm * .66 + 90 }
      else if ( chosen_latest_m3_cumulative[0]['Hospital'] >= 1000) {
      return width_hm * .66 + 80 }
      else if ( chosen_latest_m3_cumulative[0]['Hospital'] >= 100) {
      return width_hm * .66 + 60 }
      else {
      return width_hm * .66 + 50
    }})
  .attr("y", 130)
  .attr("text-anchor", "start")
  .text('Covid-19 deaths occurring in hospital')

svg_fg_mortality_3
  .append("text")
  .attr('id', 'm3_hospital_latest_all_3')
  .attr("x", function(d) {
    if ( chosen_latest_m3_cumulative[0]['Hospital'] >= 10000){
      return width_hm * .66 + 90 }
      else if (chosen_latest_m3_cumulative[0]['Hospital'] >= 1000) {
      return width_hm * .66 + 80 }
      else if (chosen_latest_m3_cumulative[0]['Hospital'] >= 100) {
      return width_hm * .66 + 60 }
      else {
      return width_hm * .66 + 50
    }})
  .attr("y", 140)
  .attr("text-anchor", "start")
  .text('this is ' + d3.format('.1%')(chosen_latest_m3_cumulative[0]['Hospital']/ chosen_latest_m3_cumulative[0]['All places']) + ' of all deaths in 2020.')

svg_fg_mortality_3
  .append("text")
  .attr("x", width_hm * .66 + 15)
  .attr("y", 170)
  .attr('id', 'm3_hospice_latest_all_1')
  .attr("text-anchor", "start")
  .text(d3.format(',.0f')(chosen_latest_m3_cumulative[0]['Hospice']))
  .style('font-weight', 'bold')
  .style("font-size", "22px")

svg_fg_mortality_3
  .append("text")
  .attr('id', 'm3_hospice_latest_all_2')
  .attr("x", function(d) {
    if ( chosen_latest_m3_cumulative[0]['Hospice'] >= 10000){
      return width_hm * .66 + 90 }
      else if ( chosen_latest_m3_cumulative[0]['Hospice'] >= 1000) {
      return width_hm * .66 + 80 }
      else if ( chosen_latest_m3_cumulative[0]['Hospice'] >= 100) {
      return width_hm * .66 + 60 }
      else {
      return width_hm * .66 + 50
    }})
  .attr("y", 160)
  .attr("text-anchor", "start")
  .text('Covid-19 deaths occurring in a hospice')

svg_fg_mortality_3
  .append("text")
  .attr('id', 'm3_hospice_latest_all_3')
  .attr("x", function(d) {
    if ( chosen_latest_m3_cumulative[0]['Hospice'] >= 10000){
      return width_hm * .66 + 90 }
      else if (chosen_latest_m3_cumulative[0]['Hospice'] >= 1000) {
      return width_hm * .66 + 80 }
      else if (chosen_latest_m3_cumulative[0]['Hospice'] >= 100) {
      return width_hm * .66 + 60 }
      else {
      return width_hm * .66 + 50
    }})
  .attr("y", 170)
  .attr("text-anchor", "start")
  .text('this is ' + d3.format('.1%')(chosen_latest_m3_cumulative[0]['Hospice']/ chosen_latest_m3_cumulative[0]['All places']) + ' of all Covid-19 deaths in 2020.')

svg_fg_mortality_3
  .append("text")
  .attr("x", width_hm * .66 + 15)
  .attr("y", 200)
  .attr('id', 'm3_elsewhere_latest_all_1')
  .attr("text-anchor", "start")
  .text(d3.format(',.0f')(chosen_latest_m3_cumulative[0]['Elsewhere (including other communal establishments)']))
  .style('font-weight', 'bold')
  .style("font-size", "22px")

svg_fg_mortality_3
  .append("text")
  .attr('id', 'm3_elsewhere_latest_all_2')
  .attr("x", function(d) {
    if ( chosen_latest_m3_cumulative[0]['Elsewhere (including other communal establishments)'] >= 10000){
      return width_hm * .66 + 90 }
      else if ( chosen_latest_m3_cumulative[0]['Elsewhere (including other communal establishments)'] >= 1000) {
      return width_hm * .66 + 80 }
      else if ( chosen_latest_m3_cumulative[0]['Elsewhere (including other communal establishments)'] >= 100) {
      return width_hm * .66 + 60 }
      else {
      return width_hm * .66 + 50
    }})
  .attr("y", 190)
  .attr("text-anchor", "start")
  .text('Covid-19 deaths occurring somewhere else')

svg_fg_mortality_3
  .append("text")
  .attr('id', 'm3_elsewhere_latest_all_3')
  .attr("x", function(d) {
    if ( chosen_latest_m3_cumulative[0]['Elsewhere (including other communal establishments)'] >= 10000){
      return width_hm * .66 + 90 }
      else if (chosen_latest_m3_cumulative[0]['Elsewhere (including other communal establishments)'] >= 1000) {
      return width_hm * .66 + 80 }
      else if (chosen_latest_m3_cumulative[0]['Elsewhere (including other communal establishments)'] >= 100) {
      return width_hm * .66 + 60 }
      else {
      return width_hm * .66 + 50
    }})
  .attr("y", 200)
  .attr("text-anchor", "start")
  .text('this is ' + d3.format('.1%')(chosen_latest_m3_cumulative[0]['Elsewhere (including other communal establishments)']/ chosen_latest_m3_cumulative[0]['All places']) + ' of all Covid-19 deaths in 2020.')

}

d3.select("#select_mortality_3_area_button").on("change", function(d) {
var chosen_m3_area = d3.select('#select_mortality_3_area_button').property("value")
  update_m3_all_cause_place()
})

// var data = daily_cases.filter(function(d) {
//   return d.Name === 'West Sussex'
// });
//
// var svg_test = d3.select('#test_animated_line')
//   .append('svg')
//   .attr('width', width_hm)
//   .attr('height', height_line);
//
// line = d3.line()
//   .x(function(d) {
//     return x_c2(d3.timeParse("%Y-%m-%d")(d.Date))
//   })
//   .y(function(d) {
//     return y_c2_ts(d.Cumulative_per_100000)
//   })
//
// function pathTween() {
//   var interpolate = d3.scaleQuantile()
//       .domain([0,1])
//       .range(d3.range(1, data.length + 1));
//         return function(t) {
//             return line(data.slice(0, interpolate(t)));
//         };
//     }
//
// var path = svg_test
// .append("path")
// .datum(data)
// .attr("d", line)
// .style("fill", "none")
// .style("stroke-width", 1.5)
// .attr("stroke", '#5e106d')
// .transition()
// .duration(4000)
// .attrTween('d', pathTween);
//
// setTimeout(function(){
// dots_area_c22 = svg_test
//   .selectAll('myCircles')
//   .data(data)
//   .enter()
//   .append("circle")
//   .attr("cx", function(d) {
//     return x_c2(d3.timeParse("%Y-%m-%d")(d.Date))
//   })
//   .attr("cy", function(d) {
//     return y_c2_ts(d.Cumulative_per_100000)
//   })
//   .attr('r', 0)
//   .style("fill", '#5e106d')
//   .attr("stroke", '#5e106d');
//
// dots_area_c22
//   .transition()
//   .delay(function(d,i){ return i * 50 })
//   .duration(150)
//   .attr("r", 4)
//
// dots_area_c22
//   .on("mousemove", showTooltip_area_c2)
//   .on('mouseout', mouseleave_c2);
//
// }, 4000);
