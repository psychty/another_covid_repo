

var request = new XMLHttpRequest();
request.open("GET", "./england_latest_mortality.json", false);
request.send(null);
var eng_mortality_figures = JSON.parse(request.responseText);

d3.select("#latest_national_deaths_confirmed")
  .data(eng_mortality_figures)
  .html(function(d) {
    return 'In England as at ' + d.Date_label + ', ' + d3.format(',.0f')(d['Cumulative deaths']) + ' people have been reported to have died where the person had tested positive for Covid-19 by an NHS or Public Health laboratory. These figures include hospital deaths as well as care home deaths and deaths in the community (e.g. at home).'
  });

var request = new XMLHttpRequest();
request.open("GET", "./ons_weekly_mortality_dates.json", false);
request.send(null);
var ons_mortality_figures_dates = JSON.parse(request.responseText);

d3.select("#ons_dates_mortality")
.data(ons_mortality_figures_dates)
.html(function(d) {
  return 'The tables include deaths that occurred up to Friday ' + d.Occurring_week_ending + ' but were registered up to ' + d.Reported_week_ending + '. Figures by place of death may differ to previously published figures due to improvements in the way we code place of death.'
});

var death_places = ["Home", "Care home", "Hospital", "Hospice", 'Elsewhere (including other communal establishments)']

var death_place_label = d3.scaleOrdinal()
  .domain(death_places)
  .range(['at home', 'in a care home', 'in hospital', 'in a hospice', 'elsewhere (which includes other communal establishments)'])

var death_place_tag = d3.scaleOrdinal()
  .domain(death_places)
  .range(['home', 'carehome','hospital','hospice','elsewhere'])

var colour_place_of_death = d3.scaleOrdinal()
  .domain(death_places)
  .range(["#f6de6c", "#ed8a46", "#be3e2b","#34738f", '#4837bc'])

var covid_causes = ['Not attributed to Covid-19', 'Covid-19']

var attribute_label = d3.scaleOrdinal()
  .domain(['Not attributed to Covid-19', 'Covid-19'])
  .range(['not attributed to Covid-19', 'where Covid-19 was mentioned as an underlying or contributing factor'])

var colour_covid_non_covid = d3.scaleOrdinal()
  .domain(covid_causes)
  .range(['#006d90','#003343'])

/////////////////////////////////
// x = week = cause category //
/////////////////////////////////

var request = new XMLHttpRequest();
    request.open("GET", "./deaths_all_settings_SE.json", false);
    request.send(null);
var deaths_by_week = JSON.parse(request.responseText); // parse the fetched json data into a variable

// We need to create a dropdown button for the user to choose which area to be displayed on the figure.
d3.select("#select_mortality_1_area_button")
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
var chosen_m1_area = d3.select('#select_mortality_1_area_button').property("value")

var chosen_m1_df = deaths_by_week.filter(function(d) {
  return d.Name === chosen_m1_area
});

var chosen_latest = chosen_m1_df.filter(function(d) {
  return d.Week_number === d3.max(chosen_m1_df, function(d) {return +d.Week_number;})
})

// Create a tooltip for the lines and functions for displaying the tooltips as well as highlighting certain lines.
var tooltip_m1 = d3.select("#covid_non_covid_mortality_all_settings")
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

var showTooltip_m1 = function(d, i) {
    var causeName = d3.select(this.parentNode).datum().key;
    var causeValue = d.data[causeName];

tooltip_m1
  .html("<h5>" + d.data.Name + '</h5><p class = "side">Week number ' + d.data.Week_number + ' - ' + d.data.Date_label + '</p><p> <b>' + d3.format(',.0f')(causeValue) + ' deaths </b>' + attribute_label(causeName) + '</p><p class = "side">' + d.data.Deaths_in_week_label + '</p><p class = "side">' + d.data.Cumulative_deaths_label + '</p>' )
  .style("opacity", 1)
  .attr('visibility', 'visible')
  .style("top", (event.pageY - 10) + "px")
  .style("left", (event.pageX + 10) + "px")
  .style("visibility", "visible");

}

var mouseleave_m1 = function(d) {
tooltip_m1
  .style("visibility", "hidden")
}

var stackedData_m1 = d3.stack()
    .keys(covid_causes)
    (chosen_m1_df)

weeks = chosen_m1_df.map(function(d) {return (d.Date_label);});

// append the svg object to the body of the page
var svg_fg_mortality_1 = d3.select("#covid_non_covid_mortality_all_settings")
 .append("svg")
  .attr("width", width_hm)
  .attr("height", height_line)
  .append("g")
  .attr("transform", "translate(" + 50 + "," + 20 + ")");

var x_m1 = d3.scaleBand()
  .domain(weeks)
  .range([0, width_hm * .6]) // this is the 50 that was pushed over from the left plus another 10 so that the chart does not get cut off
  .padding([0.2]);

var xAxis_mortality_1 = svg_fg_mortality_1
  .append("g")
  .attr("transform", 'translate(0,' + (height_line - 90) + ")")
  .call(d3.axisBottom(x_m1).tickSizeOuter(0));

xAxis_mortality_1
  .selectAll("text")
  .attr("transform", 'translate(-10,10)rotate(-90)')
  .style("text-anchor", "end")

var y_m1_ts = d3.scaleLinear()
  .domain([0, d3.max(chosen_m1_df, function(d) {return +d['All causes'];})])
  .range([height_line - 90, 0])
  .nice()

var y_m1_ts_axis = svg_fg_mortality_1
  .append("g")
  .attr("transform", 'translate(0,0)')
  .call(d3.axisLeft(y_m1_ts).tickFormat(d3.format(',.0f')));

var bars_m1 = svg_fg_mortality_1
 .append("g")
 .selectAll("g")
 .data(stackedData_m1)
 .enter().append("g")
 .attr("fill", function(d) { return colour_covid_non_covid(d.key); })
 .selectAll("rect")
 .data(function(d) { return d; })
 .enter().append("rect")
 .attr("x", function(d) { return x_m1(d.data.Date_label); })
 .attr("y", function(d) { return y_m1_ts(d[1]); })
 .attr("height", function(d) { return y_m1_ts(d[0]) - y_m1_ts(d[1]); })
 .attr("width",x_m1.bandwidth())
 .on('mousemove', showTooltip_m1)
 .on('mouseout', mouseleave_m1)

svg_fg_mortality_1
  .append("text")
  .attr("x", width_hm * .65)
  .attr("y", 40)
  .attr('id', 'm1_chosen_area')
  .attr("text-anchor", "start")
  .text(chosen_m1_area)
  .style('font-weight', 'bold')
  .style("font-size", "18px")

svg_fg_mortality_1
  .append("text")
  .attr("x", width_hm * .65)
  .attr("y", 80)
  .attr('id', 'm1_selected_cumulative_covid')
  .attr("text-anchor", "start")
  .text(d3.format(',.0f')(chosen_latest[0]['Cumulative_covid_deaths']))
  .style('font-weight', 'bold')
  .style("font-size", "22px")

svg_fg_mortality_1
  .append("text")
  .attr('id', 'm1_place_1')
  .attr("x", function(d) {
    if ( chosen_latest[0]['Cumulative_covid_deaths'] > 10000){
      return width_hm * .65 + 75 }
      else if ( chosen_latest[0]['Cumulative_covid_deaths'] > 1000) {
      return width_hm * .65 + 65 }
      else if ( chosen_latest[0]['Cumulative_covid_deaths'] > 100) {
      return width_hm * .65 + 45 }
      else {
      return width_hm * .65 + 35
    }})
  .attr("y", 70)
  .attr("text-anchor", "start")
  .text('deaths attributed to Covid-19')

svg_fg_mortality_1
  .append("text")
  .attr('id', 'm1_place_2')
  .attr("x", function(d) {
    if ( chosen_latest[0]['Cumulative_covid_deaths'] > 10000){
      return width_hm * .65 + 75 }
      else if ( chosen_latest[0]['Cumulative_covid_deaths'] > 1000) {
      return width_hm * .65 + 65 }
      else if ( chosen_latest[0]['Cumulative_covid_deaths'] > 100) {
      return width_hm * .65 + 45 }
      else {
      return width_hm * .65 + 35
    }})
  .attr("y", 80)
  .attr("text-anchor", "start")
  .text('so far in 2020 up to ' + ons_mortality_figures_dates[0].Occurring_week_ending)

svg_fg_mortality_1
  .append("text")
  .attr('id', 'm1_place_3')
  .attr("x", width_hm * .65)
  .attr("y", 112)
  .attr("text-anchor", "start")
  .text('out of ')

svg_fg_mortality_1
  .append("text")
  .attr("x", width_hm * .65 + 32)
  .attr("y", 120)
  .attr('id', 'm1_selected_cumulative_all')
  .attr("text-anchor", "start")
  .text(d3.format(',.0f')(chosen_latest[0]['Cumulative_deaths_all_cause']))
  .style('font-weight', 'bold')
  .style("font-size", "22px")

svg_fg_mortality_1
  .append("text")
  .attr("x", function(d) {
      if ( chosen_latest[0]['Cumulative_deaths_all_cause'] > 100000){
      return width_hm * .65 + 115 }
      else if ( chosen_latest[0]['Cumulative_deaths_all_cause'] > 10000){
      return width_hm * .65 + 105 }
      else if ( chosen_latest[0]['Cumulative_deaths_all_cause'] > 1000) {
      return width_hm * .65 + 95 }
      else if ( chosen_latest[0]['Cumulative_deaths_all_cause'] > 100) {
      return width_hm * .65 + 75 }
      else {
      return width_hm * .65 + 65
    }})
  .attr("y", 110)
  .attr('id', 'm1_selected_cumulative_all_text_1')
  .attr("text-anchor", "start")
  .text('total deaths registered up')

svg_fg_mortality_1
  .append("text")
  .attr("x", function(d) {
      if ( chosen_latest[0]['Cumulative_deaths_all_cause'] > 100000){
      return width_hm * .65 + 115 }
      else if ( chosen_latest[0]['Cumulative_deaths_all_cause'] > 10000){
      return width_hm * .65 + 105 }
      else if ( chosen_latest[0]['Cumulative_deaths_all_cause'] > 1000) {
      return width_hm * .65 + 95 }
      else if ( chosen_latest[0]['Cumulative_deaths_all_cause'] > 100) {
      return width_hm * .65 + 75 }
      else {
      return width_hm * .65 + 65
    }})
  .attr("y", 122)
  .attr('id', 'm1_selected_cumulative_all_text_2')
  .attr("text-anchor", "start")
  .text('to ' + ons_mortality_figures_dates[0].Reported_week_ending)

svg_fg_mortality_1
  .append("text")
  .attr("x", width_hm * .65)
  .attr("y", 145)
  .attr('id', 'm1_selected_cumulative_all_text_3')
  .attr("text-anchor", "start")
  .text('The total deaths attributed to Covid-19')

svg_fg_mortality_1
  .append("text")
  .attr("x", width_hm * .65)
  .attr("y", 157)
  .attr('id', 'm1_selected_cumulative_all_text_4')
  .attr("text-anchor", "start")
  .text('represent ' + d3.format('0.1%')(chosen_latest[0]['Cumulative_covid_deaths']/ chosen_latest[0]['Cumulative_deaths_all_cause']) + ' of all deaths.')

function update_m1(){
var chosen_m1_area = d3.select('#select_mortality_1_area_button').property("value")
  d3.select("#selected_m1_title")
    .html(function(d) {
      return 'Deaths (all ages) by week of occurrence; 2020 up to ' + ons_mortality_figures_dates[0].Occurring_week_ending + '; ' + chosen_m1_area
    });

var chosen_m1_df = deaths_by_week.filter(function(d) {
  return d.Name === chosen_m1_area
});

var chosen_latest = chosen_m1_df.filter(function(d) {
  return d.Week_number === d3.max(chosen_m1_df, function(d) {return +d.Week_number;})
})

var stackedData_m1 = d3.stack()
    .keys(covid_causes)
    (chosen_m1_df)

y_m1_ts
  .domain([0, d3.max(chosen_m1_df, function(d) {return +d['All causes'];})])
  .range([height_line - 90, 0])
  .nice();

y_m1_ts_axis
.transition()
.duration(1000)
.call(d3.axisLeft(y_m1_ts).tickFormat(d3.format(',.0f')));

svg_fg_mortality_1
.selectAll("rect")
.remove();

var bars_m1 = svg_fg_mortality_1
 .append("g")
 .selectAll("g")
 .data(stackedData_m1)
 .enter().append("g")
 .attr("fill", function(d) { return colour_covid_non_covid(d.key); })
 .selectAll("rect")
 .data(function(d) { return d; })
 .enter().append("rect")
 .attr("x", function(d) { return x_m1(d.data.Date_label); })
 .attr("y", function(d) { return y_m1_ts(d[1]); })
 .attr("height", function(d) { return y_m1_ts(d[0]) - y_m1_ts(d[1]); })
 .attr("width",x_m1.bandwidth())

bars_m1
 .on('mousemove', showTooltip_m1)
 .on('mouseout', mouseleave_m1)

svg_fg_mortality_1
    .selectAll("#m1_chosen_area")
    .remove();

svg_fg_mortality_1
    .selectAll("#m1_selected_cumulative_covid")
    .remove();

svg_fg_mortality_1
    .selectAll("#m1_place_1")
    .remove();

svg_fg_mortality_1
    .selectAll("#m1_place_2")
    .remove();

svg_fg_mortality_1
    .selectAll("#m1_place_3")
    .remove();

svg_fg_mortality_1
    .selectAll("#m1_selected_cumulative_all")
    .remove();

svg_fg_mortality_1
    .selectAll("#m1_selected_cumulative_all_text_1")
    .remove();

svg_fg_mortality_1
    .selectAll("#m1_selected_cumulative_all_text_2")
    .remove();

svg_fg_mortality_1
    .selectAll("#m1_selected_cumulative_all_text_3")
    .remove();

svg_fg_mortality_1
    .selectAll("#m1_selected_cumulative_all_text_4")
    .remove();

svg_fg_mortality_1
  .append("text")
  .attr("x", width_hm * .65)
  .attr("y", 40)
  .attr('id', 'm1_chosen_area')
  .attr("text-anchor", "start")
  .text(chosen_m1_area)
  .style('font-weight', 'bold')
  .style("font-size", "18px")

svg_fg_mortality_1
  .append("text")
  .attr("x", width_hm * .65)
  .attr("y", 80)
  .attr('id', 'm1_selected_cumulative_covid')
  .attr("text-anchor", "start")
  .text(d3.format(',.0f')(chosen_latest[0]['Cumulative_covid_deaths']))
  .style('font-weight', 'bold')
  .style("font-size", "22px")

svg_fg_mortality_1
  .append("text")
  .attr('id', 'm1_place_1')
  .attr("x", function(d) {
    if ( chosen_latest[0]['Cumulative_covid_deaths'] > 10000){
      return width_hm * .65 + 75 }
      else if ( chosen_latest[0]['Cumulative_covid_deaths'] > 1000) {
      return width_hm * .65 + 65 }
      else if ( chosen_latest[0]['Cumulative_covid_deaths'] > 100) {
      return width_hm * .65 + 45 }
      else {
      return width_hm * .65 + 35
    }})
  .attr("y", 70)
  .attr("text-anchor", "start")
  .text('deaths attributed to Covid-19')

svg_fg_mortality_1
  .append("text")
  .attr('id', 'm1_place_2')
  .attr("x", function(d) {
    if ( chosen_latest[0]['Cumulative_covid_deaths'] > 10000){
      return width_hm * .65 + 75 }
      else if ( chosen_latest[0]['Cumulative_covid_deaths'] > 1000) {
      return width_hm * .65 + 65 }
      else if ( chosen_latest[0]['Cumulative_covid_deaths'] > 100) {
      return width_hm * .65 + 45 }
      else {
      return width_hm * .65 + 35
    }})
  .attr("y", 80)
  .attr("text-anchor", "start")
  .text('so far in 2020 up to ' + ons_mortality_figures_dates[0].Occurring_week_ending)

svg_fg_mortality_1
  .append("text")
  .attr('id', 'm1_place_3')
  .attr("x", width_hm * .65)
  .attr("y", 112)
  .attr("text-anchor", "start")
  .text('out of ')

svg_fg_mortality_1
  .append("text")
  .attr("x", width_hm * .65 + 30)
  .attr("y", 120)
  .attr('id', 'm1_selected_cumulative_all')
  .attr("text-anchor", "start")
  .text(d3.format(',.0f')(chosen_latest[0]['Cumulative_deaths_all_cause']))
  .style('font-weight', 'bold')
  .style("font-size", "22px")

svg_fg_mortality_1
  .append("text")
  .attr("x", function(d) {
      if ( chosen_latest[0]['Cumulative_deaths_all_cause'] > 100000){
      return width_hm * .65 + 115 }
      else if ( chosen_latest[0]['Cumulative_deaths_all_cause'] > 10000){
      return width_hm * .65 + 105 }
      else if ( chosen_latest[0]['Cumulative_deaths_all_cause'] > 1000) {
      return width_hm * .65 + 95 }
      else if ( chosen_latest[0]['Cumulative_deaths_all_cause'] > 100) {
      return width_hm * .65 + 75 }
      else {
      return width_hm * .65 + 65
    }})
  .attr("y", 110)
  .attr('id', 'm1_selected_cumulative_all_text_1')
  .attr("text-anchor", "start")
  .text('total deaths registered up')

svg_fg_mortality_1
  .append("text")
  .attr("x", function(d) {
      if ( chosen_latest[0]['Cumulative_deaths_all_cause'] > 100000){
      return width_hm * .65 + 115 }
      else if ( chosen_latest[0]['Cumulative_deaths_all_cause'] > 10000){
      return width_hm * .65 + 105 }
      else if ( chosen_latest[0]['Cumulative_deaths_all_cause'] > 1000) {
      return width_hm * .65 + 95 }
      else if ( chosen_latest[0]['Cumulative_deaths_all_cause'] > 100) {
      return width_hm * .65 + 75 }
      else {
      return width_hm * .65 + 65
    }})
  .attr("y", 122)
  .attr('id', 'm1_selected_cumulative_all_text_2')
  .attr("text-anchor", "start")
  .text('to ' + ons_mortality_figures_dates[0].Reported_week_ending)

svg_fg_mortality_1
  .append("text")
  .attr("x", width_hm * .65)
  .attr("y", 145)
  .attr('id', 'm1_selected_cumulative_all_text_3')
  .attr("text-anchor", "start")
  .text('The total deaths attributed to Covid-19')

svg_fg_mortality_1
  .append("text")
  .attr("x", width_hm * .65)
  .attr("y", 157)
  .attr('id', 'm1_selected_cumulative_all_text_4')
  .attr("text-anchor", "start")
  .text('represent ' + d3.format('0.1%')(chosen_latest[0]['Cumulative_covid_deaths']/ chosen_latest[0]['Cumulative_deaths_all_cause']) + ' of all deaths.')

}

update_m1()

d3.select("#select_mortality_1_area_button").on("change", function(d) {
var chosen_m1_area = d3.select('#select_mortality_1_area_button').property("value")
  update_m1()
})

///////////////////////////////
// x = week = place of death //
///////////////////////////////

var request = new XMLHttpRequest();
    request.open("GET", "./deaths_all_cause_by_place_SE.json", false);
    request.send(null);
var deaths_by_week_place = JSON.parse(request.responseText); // parse the fetched json data into a variable

var request = new XMLHttpRequest();
    request.open("GET", "./cumulative_deaths_all_cause_by_place_SE.json", false);
    request.send(null);
var cumulative_deaths_by_week_place = JSON.parse(request.responseText); // parse the fetched json data into a variable

// We need to create a dropdown button for the user to choose which area to be displayed on the figure.
d3.select("#select_mortality_2_area_button")
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
var chosen_m2_area = d3.select('#select_mortality_2_area_button').property("value")

var chosen_m2_df = deaths_by_week_place.filter(function(d) {
  return d.Name === chosen_m2_area
});

var chosen_latest_m2 = chosen_m2_df.filter(function(d) {
  return d.Week_number === d3.max(chosen_m2_df, function(d) {return +d.Week_number;})
})

var chosen_latest_m2_cumulative = cumulative_deaths_by_week_place.filter(function(d) {
  return d.Week_number === d3.max(chosen_m2_df, function(d) {return +d.Week_number;}) &
         d.Name === chosen_m2_area
})

var stackedData_m2 = d3.stack()
    .keys(death_places)
    (chosen_m2_df)

weeks_m2 = chosen_m2_df.map(function(d) {return (d.Date_label);});

d3.select("#selected_m2_title")
  .html(function(d) {
    return 'Deaths (all ages) by week of occurrence and place of death; 2020 up to ' + ons_mortality_figures_dates[0].Occurring_week_ending + '; ' + chosen_m2_area
    });

// Create a tooltip for the lines and functions for displaying the tooltips as well as highlighting certain lines.
var tooltip_m2 = d3.select("#all_cause_mortality_by_place")
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

var showTooltip_m2 = function(d, i) {
    var placeName = d3.select(this.parentNode).datum().key;
    var placeValue = d.data[placeName];

// // Reduce opacity of all rect to 0.2
//     d3.selectAll(".myRect")
//       .style("opacity", 0.5)
//     // Highlight all rects of this subgroup with opacity 0.8. It is possible to select them since they have a specific class = their name.
//     d3.selectAll("." + death_place_tag(placeName))
//       .style("opacity", 1)

tooltip_m2
  .html("<h5>" + d.data.Name + '</h5><p class = "side">Week number ' + d.data.Week_number + ' - ' + d.data.Date_label + '</p><p><b>' + placeName + '</b></p><p class = "side">There were <b>' + d3.format(',.0f')(placeValue) + ' deaths</b> occurring ' + death_place_label(placeName) + ' in ' + d.data.Date_label + ' that have been registered so far.</p><p>The deaths ' + death_place_label(placeName) + ' represent <b>' + d3.format('.1%')(placeValue / d.data['All places']) + ' </b>of deaths occurring in this week.</p>')
  .style("opacity", 1)
  .attr('visibility', 'visible')
  .style("top", (event.pageY - 10) + "px")
  .style("left", (event.pageX + 10) + "px")
  .style("visibility", "visible");
}

var mouseleave_m2 = function(d) {
tooltip_m2
  .style("visibility", "hidden")

 d3.selectAll(".myRect")
      .style("opacity",1)
}

// append the svg object to the body of the page
var svg_fg_mortality_2 = d3.select("#all_cause_mortality_by_place")
 .append("svg")
  .attr("width", width_hm)
  .attr("height", height_line)
  .append("g")
  .attr("transform", "translate(" + 50 + "," + 20 + ")");

var x_m2 = d3.scaleBand()
  .domain(weeks_m2)
  .range([0, width_hm * .6]) // this is the 50 that was pushed over from the left plus another 10 so that the chart does not get cut off
  .padding([0.2]);

var xAxis_mortality_2 = svg_fg_mortality_2
  .append("g")
  .attr("transform", 'translate(0,' + (height_line - 90) + ")")
  .call(d3.axisBottom(x_m2).tickSizeOuter(0));

xAxis_mortality_2
  .selectAll("text")
  .attr("transform", 'translate(-10,10)rotate(-90)')
  .style("text-anchor", "end")

var y_m2_ts = d3.scaleLinear()
  .domain([0, d3.max(chosen_m2_df, function(d) {return +d['All places'];})])
  .range([height_line - 90, 0])
  .nice()

var y_m2_ts_axis = svg_fg_mortality_2
  .append("g")
  .attr("transform", 'translate(0,0)')
  .call(d3.axisLeft(y_m2_ts).tickFormat(d3.format(',.0f')));

var bars_m2 = svg_fg_mortality_2
 .append("g")
 .selectAll("g")
 .data(stackedData_m2)
 .enter().append("g")
 .attr("fill", function(d) { return colour_place_of_death(d.key); })
 .attr("class", function(d){ return "myRect " + death_place_tag(d.key) }) // Add a class to each subgroup: their name
 .selectAll("rect")
 .data(function(d) { return d; })
 .enter().append("rect")
 .attr("x", function(d) { return x_m2(d.data.Date_label); })
 .attr("y", function(d) { return y_m2_ts(d[1]); })
 .attr("height", function(d) { return y_m2_ts(d[0]) - y_m2_ts(d[1]); })
 .attr("width",x_m2.bandwidth())
 .on('mousemove', showTooltip_m2)
 .on('mouseout', mouseleave_m2)

svg_fg_mortality_2
  .append("text")
  .attr("x", width_hm * .65)
  .attr("y", 10)
  .attr("text-anchor", "start")
  .text('All cause deaths')
  .style('font-weight', 'bold')
  .style("font-size", "18px")

svg_fg_mortality_2
  .append("text")
  .attr("x", width_hm * .65)
  .attr("y", 35)
  .attr('id', 'm2_chosen_area')
  .attr("text-anchor", "start")
  .text(chosen_m2_area)
  .style('font-weight', 'bold')
  .style("font-size", "18px")

svg_fg_mortality_2
  .append("text")
  .attr("x", width_hm * .65)
  .attr("y", 50)
  .attr("text-anchor", "start")
  .text('so far in 2020 up to ' + ons_mortality_figures_dates[0].Occurring_week_ending)

svg_fg_mortality_2
    .append("circle")
    .attr("cx", width_hm * .66)
    .attr("cy", 72)
    .attr("r", 10)
    .attr("fill", function(d) { return colour_place_of_death('Home'); })

svg_fg_mortality_2
  .append("text")
  .attr("x", width_hm * .66 + 15)
  .attr("y", 80)
  .attr('id', 'm2_home_latest_all_1')
  .attr("text-anchor", "start")
  .text(d3.format(',.0f')(chosen_latest_m2_cumulative[0]['Home']))
  .style('font-weight', 'bold')
  .style("font-size", "22px")

svg_fg_mortality_2
  .append("text")
  .attr('id', 'm2_home_latest_all_2')
  .attr("x", function(d) {
    if ( chosen_latest_m2_cumulative[0]['Home'] >= 10000){
      return width_hm * .66 + 90 }
      else if ( chosen_latest_m2_cumulative[0]['Home'] >= 1000) {
      return width_hm * .66 + 80 }
      else if ( chosen_latest_m2_cumulative[0]['Home'] >= 100) {
      return width_hm * .66 + 60 }
      else {
      return width_hm * .66 + 50
    }})
  .attr("y", 70)
  .attr("text-anchor", "start")
  .text('deaths occurring at home')

svg_fg_mortality_2
  .append("text")
  .attr('id', 'm2_home_latest_all_3')
  .attr("x", function(d) {
    if (chosen_latest_m2_cumulative[0]['Home'] >= 10000){
      return width_hm * .66 + 90 }
      else if (chosen_latest_m2_cumulative[0]['Home'] >= 1000) {
      return width_hm * .66 + 80 }
      else if (chosen_latest_m2_cumulative[0]['Home'] >= 100) {
      return width_hm * .66 + 60 }
      else {
      return width_hm * .66 + 50
    }})
  .attr("y", 80)
  .attr("text-anchor", "start")
  .text('this is ' + d3.format('.1%')(chosen_latest_m2_cumulative[0]['Home']/ chosen_latest_m2_cumulative[0]['All places']) + ' of all deaths in 2020.')

svg_fg_mortality_2
    .append("circle")
    .attr("cx", width_hm * .66)
    .attr("cy", 102)
    .attr("r", 10)
    .attr("fill", function(d) { return colour_place_of_death('Care home'); })

svg_fg_mortality_2
  .append("text")
  .attr("x", width_hm * .66 + 15)
  .attr("y", 110)
  .attr('id', 'm2_carehome_latest_all_1')
  .attr("text-anchor", "start")
  .text(d3.format(',.0f')(chosen_latest_m2_cumulative[0]['Care home']))
  .style('font-weight', 'bold')
  .style("font-size", "22px")

svg_fg_mortality_2
  .append("text")
  .attr('id', 'm2_carehome_latest_all_2')
  .attr("x", function(d) {
    if ( chosen_latest_m2_cumulative[0]['Care home'] >= 10000){
      return width_hm * .66 + 90 }
      else if ( chosen_latest_m2_cumulative[0]['Care home'] >= 1000) {
      return width_hm * .66 + 80 }
      else if ( chosen_latest_m2_cumulative[0]['Care home'] >= 100) {
      return width_hm * .66 + 60 }
      else {
      return width_hm * .66 + 50
    }})
  .attr("y", 100)
  .attr("text-anchor", "start")
  .text('deaths occurring in a care home')

svg_fg_mortality_2
  .append("text")
  .attr('id', 'm2_carehome_latest_all_3')
  .attr("x", function(d) {
    if ( chosen_latest_m2_cumulative[0]['Care home'] >= 10000){
      return width_hm * .66 + 90 }
      else if (chosen_latest_m2_cumulative[0]['Care home'] >= 1000) {
      return width_hm * .66 + 80 }
      else if (chosen_latest_m2_cumulative[0]['Care home'] >= 100) {
      return width_hm * .66 + 60 }
      else {
      return width_hm * .66 + 50
    }})
  .attr("y", 110)
  .attr("text-anchor", "start")
  .text('this is ' + d3.format('.1%')(chosen_latest_m2_cumulative[0]['Care home']/ chosen_latest_m2_cumulative[0]['All places']) + ' of all deaths in 2020.')

svg_fg_mortality_2
    .append("circle")
    .attr("cx", width_hm * .66)
    .attr("cy", 132)
    .attr("r", 10)
    .attr("fill", function(d) { return colour_place_of_death('Hospital'); })

svg_fg_mortality_2
  .append("text")
  .attr("x", width_hm * .66 + 15)
  .attr("y", 140)
  .attr('id', 'm2_hospital_latest_all_1')
  .attr("text-anchor", "start")
  .text(d3.format(',.0f')(chosen_latest_m2_cumulative[0]['Hospital']))
  .style('font-weight', 'bold')
  .style("font-size", "22px")

svg_fg_mortality_2
  .append("text")
  .attr('id', 'm2_hospital_latest_all_2')
  .attr("x", function(d) {
    if ( chosen_latest_m2_cumulative[0]['Hospital'] >= 10000){
      return width_hm * .66 + 90 }
      else if ( chosen_latest_m2_cumulative[0]['Hospital'] >= 1000) {
      return width_hm * .66 + 80 }
      else if ( chosen_latest_m2_cumulative[0]['Hospital'] >= 100) {
      return width_hm * .66 + 60 }
      else {
      return width_hm * .66 + 50
    }})
  .attr("y", 130)
  .attr("text-anchor", "start")
  .text('deaths occurring in hospital')

svg_fg_mortality_2
  .append("text")
  .attr('id', 'm2_hospital_latest_all_3')
  .attr("x", function(d) {
    if ( chosen_latest_m2_cumulative[0]['Hospital'] >= 10000){
      return width_hm * .66 + 90 }
      else if (chosen_latest_m2_cumulative[0]['Hospital'] >= 1000) {
      return width_hm * .66 + 80 }
      else if (chosen_latest_m2_cumulative[0]['Hospital'] >= 100) {
      return width_hm * .66 + 60 }
      else {
      return width_hm * .66 + 50
    }})
  .attr("y", 140)
  .attr("text-anchor", "start")
  .text('this is ' + d3.format('.1%')(chosen_latest_m2_cumulative[0]['Hospital']/ chosen_latest_m2_cumulative[0]['All places']) + ' of all deaths in 2020.')

svg_fg_mortality_2
    .append("circle")
    .attr("cx", width_hm * .66)
    .attr("cy", 162)
    .attr("r", 10)
    .attr("fill", function(d) { return colour_place_of_death('Hospice'); })

svg_fg_mortality_2
  .append("text")
  .attr("x", width_hm * .66 + 15)
  .attr("y", 170)
  .attr('id', 'm2_hospice_latest_all_1')
  .attr("text-anchor", "start")
  .text(d3.format(',.0f')(chosen_latest_m2_cumulative[0]['Hospice']))
  .style('font-weight', 'bold')
  .style("font-size", "22px")

svg_fg_mortality_2
  .append("text")
  .attr('id', 'm2_hospice_latest_all_2')
  .attr("x", function(d) {
    if ( chosen_latest_m2_cumulative[0]['Hospice'] >= 10000){
      return width_hm * .66 + 90 }
      else if ( chosen_latest_m2_cumulative[0]['Hospice'] >= 1000) {
      return width_hm * .66 + 80 }
      else if ( chosen_latest_m2_cumulative[0]['Hospice'] >= 100) {
      return width_hm * .66 + 60 }
      else {
      return width_hm * .66 + 50
    }})
  .attr("y", 160)
  .attr("text-anchor", "start")
  .text('deaths occurring in a hospice')

svg_fg_mortality_2
  .append("text")
  .attr('id', 'm2_hospice_latest_all_3')
  .attr("x", function(d) {
    if ( chosen_latest_m2_cumulative[0]['Hospice'] >= 10000){
      return width_hm * .66 + 90 }
      else if (chosen_latest_m2_cumulative[0]['Hospice'] >= 1000) {
      return width_hm * .66 + 80 }
      else if (chosen_latest_m2_cumulative[0]['Hospice'] >= 100) {
      return width_hm * .66 + 60 }
      else {
      return width_hm * .66 + 50
    }})
  .attr("y", 170)
  .attr("text-anchor", "start")
  .text('this is ' + d3.format('.1%')(chosen_latest_m2_cumulative[0]['Hospice']/ chosen_latest_m2_cumulative[0]['All places']) + ' of all deaths in 2020.')

svg_fg_mortality_2
    .append("circle")
    .attr("cx", width_hm * .66)
    .attr("cy", 192)
    .attr("r", 10)
    .attr("fill", function(d) { return colour_place_of_death('Elsewhere (including other communal establishments)'); })

svg_fg_mortality_2
  .append("text")
  .attr("x", width_hm * .66 + 15)
  .attr("y", 200)
  .attr('id', 'm2_elsewhere_latest_all_1')
  .attr("text-anchor", "start")
  .text(d3.format(',.0f')(chosen_latest_m2_cumulative[0]['Elsewhere (including other communal establishments)']))
  .style('font-weight', 'bold')
  .style("font-size", "22px")

svg_fg_mortality_2
  .append("text")
  .attr('id', 'm2_elsewhere_latest_all_2')
  .attr("x", function(d) {
    if ( chosen_latest_m2_cumulative[0]['Elsewhere (including other communal establishments)'] >= 10000){
      return width_hm * .66 + 90 }
      else if ( chosen_latest_m2_cumulative[0]['Elsewhere (including other communal establishments)'] >= 1000) {
      return width_hm * .66 + 80 }
      else if ( chosen_latest_m2_cumulative[0]['Elsewhere (including other communal establishments)'] >= 100) {
      return width_hm * .66 + 60 }
      else {
      return width_hm * .66 + 50
    }})
  .attr("y", 190)
  .attr("text-anchor", "start")
  .text('deaths occurring somewhere else')

svg_fg_mortality_2
  .append("text")
  .attr('id', 'm2_elsewhere_latest_all_3')
  .attr("x", function(d) {
    if ( chosen_latest_m2_cumulative[0]['Elsewhere (including other communal establishments)'] >= 10000){
      return width_hm * .66 + 90 }
      else if (chosen_latest_m2_cumulative[0]['Elsewhere (including other communal establishments)'] >= 1000) {
      return width_hm * .66 + 80 }
      else if (chosen_latest_m2_cumulative[0]['Elsewhere (including other communal establishments)'] >= 100) {
      return width_hm * .66 + 60 }
      else {
      return width_hm * .66 + 50
    }})
  .attr("y", 200)
  .attr("text-anchor", "start")
  .text('this is ' + d3.format('.1%')(chosen_latest_m2_cumulative[0]['Elsewhere (including other communal establishments)']/ chosen_latest_m2_cumulative[0]['All places']) + ' of all deaths in 2020.')

function update_m2_all_cause_place(){
var chosen_m2_area = d3.select('#select_mortality_2_area_button').property("value")

var chosen_m2_df = deaths_by_week_place.filter(function(d) {
  return d.Name === chosen_m2_area
});

var chosen_latest_m2 = chosen_m2_df.filter(function(d) {
  return d.Week_number === d3.max(chosen_m2_df, function(d) {return +d.Week_number;})
})

var chosen_latest_m2_cumulative = cumulative_deaths_by_week_place.filter(function(d) {
  return d.Week_number === d3.max(chosen_m2_df, function(d) {return +d.Week_number;}) &
         d.Name === chosen_m2_area
})

var stackedData_m2 = d3.stack()
    .keys(death_places)
    (chosen_m2_df)

weeks_m2 = chosen_m2_df.map(function(d) {return (d.Date_label);});

d3.select("#selected_m2_title")
  .html(function(d) {
    return 'Deaths (all ages) by week of occurrence and place of death; 2020 up to ' + ons_mortality_figures_dates[0].Occurring_week_ending + '; ' + chosen_m2_area
    });

y_m2_ts
  .domain([0, d3.max(chosen_m2_df, function(d) {return +d['All places'];})])
  .nice()

y_m2_ts_axis
  .transition()
  .duration(1000)
  .call(d3.axisLeft(y_m2_ts).tickFormat(d3.format(',.0f')));

svg_fg_mortality_2
.selectAll("rect")
.remove();

var bars_m2 = svg_fg_mortality_2
 .append("g")
 .selectAll("g")
 .data(stackedData_m2)
 .enter().append("g")
 .attr("fill", function(d) { return colour_place_of_death(d.key); })
 .attr("class", function(d){ return "myRect " + death_place_tag(d.key) }) // Add a class to each subgroup: their name
 .selectAll("rect")
 .data(function(d) { return d; })
 .enter().append("rect")
 .attr("x", function(d) { return x_m2(d.data.Date_label); })
 .attr("y", function(d) { return y_m2_ts(d[1]); })
 .attr("height", function(d) { return y_m2_ts(d[0]) - y_m2_ts(d[1]); })
 .attr("width",x_m2.bandwidth())
 .on('mousemove', showTooltip_m2)
 .on('mouseout', mouseleave_m2)

svg_fg_mortality_2
    .selectAll("#m2_chosen_area")
    .remove();
svg_fg_mortality_2
    .selectAll("#m2_home_latest_all_1")
    .remove();
svg_fg_mortality_2
    .selectAll("#m2_home_latest_all_2")
    .remove();
svg_fg_mortality_2
    .selectAll("#m2_home_latest_all_3")
    .remove();
svg_fg_mortality_2
    .selectAll("#m2_carehome_latest_all_1")
    .remove();
svg_fg_mortality_2
    .selectAll("#m2_carehome_latest_all_2")
    .remove();
svg_fg_mortality_2
    .selectAll("#m2_carehome_latest_all_3")
    .remove();
svg_fg_mortality_2
    .selectAll("#m2_hospital_latest_all_1")
    .remove();
svg_fg_mortality_2
    .selectAll("#m2_hospital_latest_all_2")
    .remove();
svg_fg_mortality_2
    .selectAll("#m2_hospital_latest_all_3")
    .remove();
svg_fg_mortality_2
    .selectAll("#m2_hospice_latest_all_1")
    .remove();
svg_fg_mortality_2
    .selectAll("#m2_hospice_latest_all_2")
    .remove();
svg_fg_mortality_2
    .selectAll("#m2_hospice_latest_all_3")
    .remove();
svg_fg_mortality_2
    .selectAll("#m2_elsewhere_latest_all_1")
    .remove();
svg_fg_mortality_2
    .selectAll("#m2_elsewhere_latest_all_2")
    .remove();
svg_fg_mortality_2
    .selectAll("#m2_elsewhere_latest_all_3")
    .remove();

svg_fg_mortality_2
  .append("text")
  .attr("x", width_hm * .65)
  .attr("y", 35)
  .attr('id', 'm2_chosen_area')
  .attr("text-anchor", "start")
  .text(chosen_m2_area)
  .style('font-weight', 'bold')
  .style("font-size", "18px")

svg_fg_mortality_2
  .append("text")
  .attr("x", width_hm * .66 + 15)
  .attr("y", 80)
  .attr('id', 'm2_home_latest_all_1')
  .attr("text-anchor", "start")
  .text(d3.format(',.0f')(chosen_latest_m2_cumulative[0]['Home']))
  .style('font-weight', 'bold')
  .style("font-size", "22px")

svg_fg_mortality_2
  .append("text")
  .attr('id', 'm2_home_latest_all_2')
  .attr("x", function(d) {
    if ( chosen_latest_m2_cumulative[0]['Home'] >= 10000){
      return width_hm * .66 + 90 }
      else if ( chosen_latest_m2_cumulative[0]['Home'] >= 1000) {
      return width_hm * .66 + 80 }
      else if ( chosen_latest_m2_cumulative[0]['Home'] >= 100) {
      return width_hm * .66 + 60 }
      else {
      return width_hm * .66 + 50
    }})
  .attr("y", 70)
  .attr("text-anchor", "start")
  .text('deaths occurring at home')

svg_fg_mortality_2
  .append("text")
  .attr('id', 'm2_home_latest_all_3')
  .attr("x", function(d) {
    if (chosen_latest_m2_cumulative[0]['Home'] >= 10000){
      return width_hm * .66 + 90 }
      else if (chosen_latest_m2_cumulative[0]['Home'] >= 1000) {
      return width_hm * .66 + 80 }
      else if (chosen_latest_m2_cumulative[0]['Home'] >= 100) {
      return width_hm * .66 + 60 }
      else {
      return width_hm * .66 + 50
    }})
  .attr("y", 80)
  .attr("text-anchor", "start")
  .text('this is ' + d3.format('.1%')(chosen_latest_m2_cumulative[0]['Home']/ chosen_latest_m2_cumulative[0]['All places']) + ' of all deaths in 2020.')

svg_fg_mortality_2
  .append("text")
  .attr("x", width_hm * .66 + 15)
  .attr("y", 110)
  .attr('id', 'm2_carehome_latest_all_1')
  .attr("text-anchor", "start")
  .text(d3.format(',.0f')(chosen_latest_m2_cumulative[0]['Care home']))
  .style('font-weight', 'bold')
  .style("font-size", "22px")

svg_fg_mortality_2
  .append("text")
  .attr('id', 'm2_carehome_latest_all_2')
  .attr("x", function(d) {
    if ( chosen_latest_m2_cumulative[0]['Care home'] >= 10000){
      return width_hm * .66 + 90 }
      else if ( chosen_latest_m2_cumulative[0]['Care home'] >= 1000) {
      return width_hm * .66 + 80 }
      else if ( chosen_latest_m2_cumulative[0]['Care home'] >= 100) {
      return width_hm * .66 + 60 }
      else {
      return width_hm * .66 + 50
    }})
  .attr("y", 100)
  .attr("text-anchor", "start")
  .text('deaths occurring in a care home')

svg_fg_mortality_2
  .append("text")
  .attr('id', 'm2_carehome_latest_all_3')
  .attr("x", function(d) {
    if ( chosen_latest_m2_cumulative[0]['Care home'] >= 10000){
      return width_hm * .66 + 90 }
      else if (chosen_latest_m2_cumulative[0]['Care home'] >= 1000) {
      return width_hm * .66 + 80 }
      else if (chosen_latest_m2_cumulative[0]['Care home'] >= 100) {
      return width_hm * .66 + 60 }
      else {
      return width_hm * .66 + 50
    }})
  .attr("y", 110)
  .attr("text-anchor", "start")
  .text('this is ' + d3.format('.1%')(chosen_latest_m2_cumulative[0]['Care home']/ chosen_latest_m2_cumulative[0]['All places']) + ' of all deaths in 2020.')

svg_fg_mortality_2
  .append("text")
  .attr("x", width_hm * .66 + 15)
  .attr("y", 140)
  .attr('id', 'm2_hospital_latest_all_1')
  .attr("text-anchor", "start")
  .text(d3.format(',.0f')(chosen_latest_m2_cumulative[0]['Hospital']))
  .style('font-weight', 'bold')
  .style("font-size", "22px")

svg_fg_mortality_2
  .append("text")
  .attr('id', 'm2_hospital_latest_all_2')
  .attr("x", function(d) {
    if ( chosen_latest_m2_cumulative[0]['Hospital'] >= 10000){
      return width_hm * .66 + 90 }
      else if ( chosen_latest_m2_cumulative[0]['Hospital'] >= 1000) {
      return width_hm * .66 + 80 }
      else if ( chosen_latest_m2_cumulative[0]['Hospital'] >= 100) {
      return width_hm * .66 + 60 }
      else {
      return width_hm * .66 + 50
    }})
  .attr("y", 130)
  .attr("text-anchor", "start")
  .text('deaths occurring in hospital')

svg_fg_mortality_2
  .append("text")
  .attr('id', 'm2_hospital_latest_all_3')
  .attr("x", function(d) {
    if ( chosen_latest_m2_cumulative[0]['Hospital'] >= 10000){
      return width_hm * .66 + 90 }
      else if (chosen_latest_m2_cumulative[0]['Hospital'] >= 1000) {
      return width_hm * .66 + 80 }
      else if (chosen_latest_m2_cumulative[0]['Hospital'] >= 100) {
      return width_hm * .66 + 60 }
      else {
      return width_hm * .66 + 50
    }})
  .attr("y", 140)
  .attr("text-anchor", "start")
  .text('this is ' + d3.format('.1%')(chosen_latest_m2_cumulative[0]['Hospital']/ chosen_latest_m2_cumulative[0]['All places']) + ' of all deaths in 2020.')

svg_fg_mortality_2
  .append("text")
  .attr("x", width_hm * .66 + 15)
  .attr("y", 170)
  .attr('id', 'm2_hospice_latest_all_1')
  .attr("text-anchor", "start")
  .text(d3.format(',.0f')(chosen_latest_m2_cumulative[0]['Hospice']))
  .style('font-weight', 'bold')
  .style("font-size", "22px")

svg_fg_mortality_2
  .append("text")
  .attr('id', 'm2_hospice_latest_all_2')
  .attr("x", function(d) {
    if ( chosen_latest_m2_cumulative[0]['Hospice'] >= 10000){
      return width_hm * .66 + 90 }
      else if ( chosen_latest_m2_cumulative[0]['Hospice'] >= 1000) {
      return width_hm * .66 + 80 }
      else if ( chosen_latest_m2_cumulative[0]['Hospice'] >= 100) {
      return width_hm * .66 + 60 }
      else {
      return width_hm * .66 + 50
    }})
  .attr("y", 160)
  .attr("text-anchor", "start")
  .text('deaths occurring in a hospice')

svg_fg_mortality_2
  .append("text")
  .attr('id', 'm2_hospice_latest_all_3')
  .attr("x", function(d) {
    if ( chosen_latest_m2_cumulative[0]['Hospice'] >= 10000){
      return width_hm * .66 + 90 }
      else if (chosen_latest_m2_cumulative[0]['Hospice'] >= 1000) {
      return width_hm * .66 + 80 }
      else if (chosen_latest_m2_cumulative[0]['Hospice'] >= 100) {
      return width_hm * .66 + 60 }
      else {
      return width_hm * .66 + 50
    }})
  .attr("y", 170)
  .attr("text-anchor", "start")
  .text('this is ' + d3.format('.1%')(chosen_latest_m2_cumulative[0]['Hospice']/ chosen_latest_m2_cumulative[0]['All places']) + ' of all deaths in 2020.')

svg_fg_mortality_2
  .append("text")
  .attr("x", width_hm * .66 + 15)
  .attr("y", 200)
  .attr('id', 'm2_elsewhere_latest_all_1')
  .attr("text-anchor", "start")
  .text(d3.format(',.0f')(chosen_latest_m2_cumulative[0]['Elsewhere (including other communal establishments)']))
  .style('font-weight', 'bold')
  .style("font-size", "22px")

svg_fg_mortality_2
  .append("text")
  .attr('id', 'm2_elsewhere_latest_all_2')
  .attr("x", function(d) {
    if ( chosen_latest_m2_cumulative[0]['Elsewhere (including other communal establishments)'] >= 10000){
      return width_hm * .66 + 90 }
      else if ( chosen_latest_m2_cumulative[0]['Elsewhere (including other communal establishments)'] >= 1000) {
      return width_hm * .66 + 80 }
      else if ( chosen_latest_m2_cumulative[0]['Elsewhere (including other communal establishments)'] >= 100) {
      return width_hm * .66 + 60 }
      else {
      return width_hm * .66 + 50
    }})
  .attr("y", 190)
  .attr("text-anchor", "start")
  .text('deaths occurring somewhere else')

svg_fg_mortality_2
  .append("text")
  .attr('id', 'm2_elsewhere_latest_all_3')
  .attr("x", function(d) {
    if ( chosen_latest_m2_cumulative[0]['Elsewhere (including other communal establishments)'] >= 10000){
      return width_hm * .66 + 90 }
      else if (chosen_latest_m2_cumulative[0]['Elsewhere (including other communal establishments)'] >= 1000) {
      return width_hm * .66 + 80 }
      else if (chosen_latest_m2_cumulative[0]['Elsewhere (including other communal establishments)'] >= 100) {
      return width_hm * .66 + 60 }
      else {
      return width_hm * .66 + 50
    }})
  .attr("y", 200)
  .attr("text-anchor", "start")
  .text('this is ' + d3.format('.1%')(chosen_latest_m2_cumulative[0]['Elsewhere (including other communal establishments)']/ chosen_latest_m2_cumulative[0]['All places']) + ' of all deaths in 2020.')

}

d3.select("#select_mortality_2_area_button").on("change", function(d) {
var chosen_m2_area = d3.select('#select_mortality_2_area_button').property("value")
  update_m2_all_cause_place()
})


// place for covid-19 deaths //

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
