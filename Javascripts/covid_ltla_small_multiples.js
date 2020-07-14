
height_sm = 210
width_sm = 380

var request = new XMLHttpRequest();
request.open("GET", "./ltla_case_change_daily.json", false);
request.send(null);
var ltla_data = JSON.parse(request.responseText);

var request = new XMLHttpRequest();
request.open("GET", "./ltla_case_change_dates.json", false);
request.send(null);
var ltla_data_dates = JSON.parse(request.responseText).map(function(d){return d.Date_label});

var request = new XMLHttpRequest();
request.open("GET", "./ltla_case_change_date_range.json", false);
request.send(null);
var ltla_data_date_range = JSON.parse(request.responseText);

// We need to create a dropdown button for the user to choose which area to be displayed on the figure.
d3.select("#select_small_multiples_area_button")
  .selectAll('mysmOptions')
  .data(['West Sussex', 'Brighton and Hove', 'East Sussex', 'Bracknell Forest', 'Buckinghamshire', 'Hampshire', 'Isle of Wight', 'Kent', 'Medway', 'Milton Keynes', 'Oxfordshire', 'Portsmouth', 'Reading', 'Slough', 'Southampton', 'Surrey', 'West Berkshire', 'Windsor and Maidenhead', 'Wokingham'])
  .enter()
  .append('option')
  .text(function(d) {
    return d;
  })
  .attr("value", function(d) {
    return d;
  })

var tooltip_area_sm = d3.select("#my_sm_dataviz")
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

  var showTooltip_sm1 = function(d) {
    tooltip_area_sm
    .html("<h4>" + d.Name + "</h4><p><b>" + d.Date_label + "</b></p><p>Current change status: <b>" + change_case_label(d.Colour_key) + "</b></p><p>" + d.Case_label + '</p>')
    .style("opacity", 1)
    .style("top", (event.pageY - 10) + "px")
    .style("left", (event.pageX + 10) + "px")
    .style("visibility", "visible")
  }

  var mouseleave_sm = function(d) {
  tooltip_area_sm
      .style("visibility", "hidden")
}
// Retrieve the selected area name
var chosen_utla_area = d3.select('#select_small_multiples_area_button').property("value")

d3.select("#selected_ltla_sm_title")
  .html(function(d) {
    return 'Covid-19 pillar 1 and 2 confirmed new daily confirmed cases over time; areas within ' +  chosen_utla_area + '; ' + first_date + ' - ' + latest_date});

d3.select("#case_key_title")
  .html(function(d) {
    return 'The bars on each figure are also coloured to show the most recent changes in case growth, by comparing the average number of cases in the last complete seven day period (' + ltla_data_date_range[0]['range'] + ') with the average number of cases in the seven day period prior to that (' + ltla_data_date_range[1]['range'] + '). Areas with bars coloured in red indicate that there is an increase in cases, whilst blue areas show a decline in confirmed cases and green areas indicate no confirmed cases in the most recent 7 day period (excluding incomplete days - see right).'});

var chosen_ltla_df = ltla_data.filter(function(d) {
  return d.UTLA19NM === chosen_utla_area
});

var areas_for_sm_1 = d3.nest()
  .key(function(d) { return d.Name;})
  .entries(chosen_ltla_df);

var small_areas = areas_for_sm_1.map(function(d){return d.key})
var date_points_n = d3.map(chosen_ltla_df, function(d){return(d.Date_label)}).keys()

var x_sm_1 = d3.scaleBand()
   .domain(date_points_n)
   .range([0, width_sm - 65]);

//Add Y axis
var y_sm_1 = d3.scaleLinear()
    .domain([0, d3.max(chosen_ltla_df, function(d) { return +d.New_cases; })])
    .range([height_sm, 0 ])
    .nice();

case_change_values = ['No change in average cases','Increasing average number of cases over past 7 days', 'Decreasing average number of cases over past 7 days', 'Less than half the previous 7-day average', 'No confirmed cases in past 7 days']

// color palette
var case_change_colour = d3.scaleOrdinal()
  .domain(case_change_values)
  .range(['#aaaaaa','#721606', '#005bd6', '#1fbfbb', '#c2f792'])

var change_case_label = d3.scaleOrdinal()
  .domain(case_change_values)
  .range(['the average number of cases has not changed','7 day average cases appear to be increasing', '7 day average cases appear to be decreasing', 'average number of cases half what it was in previous 7 days', 'no confirmed cases in most recent complete 7 day period'])


// Add an svg element for each group. The will be one beside each other and will go on the next row when no more room available
var sm_svg_1 = d3.select("#my_sm_dataviz")
   .selectAll("small_multiples")
   .data(areas_for_sm_1)
   .enter()
   .append("svg")
   .attr("width", width_sm)
   .attr("height", height_sm + 65)
   .append("g")
   .attr("transform", "translate(" + 50 + "," + 20 + ")");

// Add axes
 sm_svg_1_y_axis = sm_svg_1
   .append("g")
   .call(d3.axisLeft(y_sm_1).ticks(6));

 sm_svg_1_x_axis = sm_svg_1
   .append("g")
   .attr("transform", "translate(0," + height_sm + ")")
   .call(d3.axisBottom(x_sm_1).tickValues(ltla_data_dates));

sm_svg_1_x_axis
  .selectAll("text")
  .attr("transform", 'translate(-10,10)rotate(-90)')
  .style("text-anchor", "end")
  // .each(function(d,i) {
    // if (i%2 != 0) d3.select(this).remove();
    // });

// Accessing nested data: https://groups.google.com/forum/#!topic/d3-js/kummm9mS4EA
// data(function(d) {return d.values;}) will dereference the values for nested data for each group
sm_svg_1_bars = sm_svg_1.selectAll(".bar")
      .data(function(d) {return d.values;})
      .enter()
      .append("rect")
      .attr("class", "bar")
      .attr("x", function(d) { return x_sm_1(d.Date_label); })
      .attr("width", x_sm_1.bandwidth())
      .attr("y", function(d) { return y_sm_1(d.New_cases); })
      .attr("height", function(d) { return height_sm - y_sm_1(d.New_cases); })
      .attr("fill", function(d) {return case_change_colour(d.Colour_key)})
  .on("mousemove", showTooltip_sm1)
  .on('mouseout', mouseleave_sm);

 // Draw the line
sm_svg_1_lines = sm_svg_1
  .append("path")
  .attr("fill", "none")
  .attr("stroke", '#000000')
  .attr("stroke-width", 1.9)
  .attr("d", function(d){
    return d3.line()
      .defined(d => !isNaN(d.Seven_day_average_new_cases))
      .x(function(d) { return x_sm_1(d.Date_label); })
      .y(function(d) { return y_sm_1(+d.Seven_day_average_new_cases); })
      (d.values)
      })

// Add plot headings
sm_svg_1_titles = sm_svg_1
  .append("text")
  .attr("text-anchor", "start")
  .attr("y", 10)
  .attr("x", 10)
  .text(function(d){ return(d.key)})
  .style('fill', '#000000')


// Add plot headings
sm_svg_1
  .append("text")
  .attr("text-anchor", "start")
  .attr("y", 25)
  .attr("x", 10)
  .text(function(d){ return(d3.format(',.1f')(d.values[date_points_n.length - 6]['Seven_day_average_new_cases']) + ' cases in last 7 complete days')})
  .style('fill', '#999999')

function update_ltla_sm(chosen_utla_area){
var chosen_utla_area = d3.select('#select_small_multiples_area_button').property("value")

d3.select("#selected_ltla_sm_title")
  .html(function(d) {
    return 'Covid-19 pillar 1 and 2 confirmed new daily confirmed cases over time; areas within ' +  chosen_utla_area + '; ' + first_date + ' - ' + latest_date});

var chosen_ltla_df = ltla_data.filter(function(d) {
  return d.UTLA19NM === chosen_utla_area
});

var areas_for_sm_1 = d3.nest()
  .key(function(d) { return d.Name;})
  .entries(chosen_ltla_df);

// Which areas are present
small_areas = areas_for_sm_1.map(function(d){return d.key})

d3.selectAll('.sm-container svg').remove();

//Add Y axis
var y_sm_1 = d3.scaleLinear()
    .domain([0, d3.max(chosen_ltla_df, function(d) { return +d.New_cases; })])
    .range([height_sm, 0 ])
    .nice();

sm_svg_1 = d3.select("#my_sm_dataviz")
   .selectAll("small_multiples")
   .data(areas_for_sm_1)
   .enter()
   .append("svg")
   .attr("width", width_sm)
   .attr("height", height_sm + 65)
   .append("g")
   .attr("transform", "translate(" + 50 + "," + 20 + ")");

 sm_svg_1_y_axis = sm_svg_1
   .append("g")
   .call(d3.axisLeft(y_sm_1).ticks(6));

 sm_svg_1_x_axis = sm_svg_1
   .append("g")
   .attr("transform", "translate(0," + height_sm + ")")
   .call(d3.axisBottom(x_sm_1).tickValues(ltla_data_dates));

sm_svg_1_x_axis
  .selectAll("text")
  .attr("transform", 'translate(-10,10)rotate(-90)')
  .style("text-anchor", "end")

sm_svg_1_bars = sm_svg_1.selectAll(".bar")
      .data(function(d) {return d.values;})
      .enter()
      .append("rect")
      .attr("class", "bar")
      .attr("x", function(d) { return x_sm_1(d.Date_label); })
      .attr("width", x_sm_1.bandwidth())
      .attr("y", function(d) { return y_sm_1(d.New_cases); })
      .attr("height", function(d) { return height_sm - y_sm_1(d.New_cases); })
      .attr("fill", function(d) {return case_change_colour(d.Colour_key)})
.on("mousemove", showTooltip_sm1)
.on('mouseout', mouseleave_sm);

sm_svg_1_lines = sm_svg_1
  .append("path")
  .attr("fill", "none")
  .attr("stroke", '#000000')
  .attr("stroke-width", 1.9)
  .attr("d", function(d){
    return d3.line()
      .defined(d => !isNaN(d.Seven_day_average_new_cases))
      .x(function(d) { return x_sm_1(d.Date_label); })
      .y(function(d) { return y_sm_1(+d.Seven_day_average_new_cases); })
      (d.values)
      })

sm_svg_1_titles = sm_svg_1
  .append("text")
  .attr("text-anchor", "start")
  .attr("y", 10)
  .attr("x", 10)
  .text(function(d){ return(d.key)})
  .style('fill', '#000000')

sm_svg_1
  .append("text")
  .attr("text-anchor", "start")
  .attr("y", 25)
  .attr("x", 10)
  .text(function(d){ return(d3.format(',.1f')(d.values[date_points_n.length - 6]['Seven_day_average_new_cases']) + ' cases in last 7 complete days')})
  .style('fill', '#999999')
}


  function key_2_sm_cases() {
    case_change_values.forEach(function(item, index) {
      var list = document.createElement("li");
      list.innerHTML = item;
      list.className = 'key_list';
      list.style.borderColor = case_change_colour(index);
      var tt = document.createElement('div');
      tt.className = 'side_tt';
      tt.style.borderColor = case_change_colour(index);
      var tt_h3_1 = document.createElement('h3');
      tt_h3_1.innerHTML = item.Cause;

      tt.appendChild(tt_h3_1);
      var div = document.getElementById("ltla_sm_key_figure");
      div.appendChild(list);
    })
  }

  key_2_sm_cases();

d3.select("#select_small_multiples_area_button").on("change", function(d) {
var chosen_utla_area = d3.select('#select_small_multiples_area_button').property("value")

  update_ltla_sm(chosen_utla_area)
})
