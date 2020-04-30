

var request = new XMLHttpRequest();
request.open("GET", "./england_latest_mortality.json", false);
request.send(null);
var eng_mortality_figures = JSON.parse(request.responseText);

d3.select("#latest_national_deaths_confirmed")
  .data(eng_mortality_figures)
  .html(function(d) {
    return 'In England as at ' + d.Date_label + ', ' + d3.format(',.0f')(d.Cumulative_deaths) + ' people have been reported to have died where the person had tested positive for Covid-19 by an NHS or Public Health laboratory. These figures include hospital deaths as well as care home deaths and deaths in the community (e.g. at home).'
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

var colour_place_of_death = d3.scaleOrdinal()
  .domain(["Home", "Care home", "Hospital", "Hospice"])
  .range(["#f6de6c", "#ed8a46", "#be3e2b","#34738f"])

var covid_causes = ['Not attributed to Covid-19', 'Covid-19']

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

tooltip_m1
  .html("<h5>" + d.data.Name + '</h5><p class = "side">Week number ' + d.data.Week_number + ' - ' + d.data.Date_label + '</p><p class = "side">' + d.data.Deaths_in_week_label + '</p><p class = "side">' + d.data.Cumulative_deaths_label + '</p>' )
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
  .range([height_line - 90, 0]);

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
