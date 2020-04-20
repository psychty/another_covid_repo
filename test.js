
// Trajectory multiline series

// Remove the aggregated areas
var df_3 = daily_cases.filter(function(d) {
  return d.Days_since_case_x >= 0 &
    d.Name !== 'England' &
    d.Name !== 'South East region' &
    d.Name !== 'Sussex areas combined'
});

// This is based on all cases we know about (even though we believe the data for the last five says are underestimates even of confirmed cases)

// Group the data: I want to draw one line per group
var c3_ts_group = d3.nest() // nest function allows to group the calculation per level of a factor
.key(function(d) { return d.Name;})
.entries(df_3);

var c3_countdays = d3.nest()
.key(function(d) { return d.Name;})
.rollup(function(days) { return days.length -1; })
.entries(df_3);

// This will be to highlight a particular line on the figure (and show some key figures)
d3.select("#select_line_3_area_button")
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
var chosen_c3_highlight_area = d3.select('#select_line_3_area_button').property("value")

// Add the svg
var svg_cumulative_actual_log = d3.select("#cumulative_log")
.append("svg")
.attr("width", width_hm)
.attr("height", height_line)
.append("g")
.attr("transform", "translate(" + 50 + "," + 20 + ")");

// Get the max number of days since case 10 (or x)
var max_days_case_x = d3.max(df_3, function (d) {
  return (d.Days_since_case_x)
  })

// This will be the x axis scale for days since case x - note this is NOT the date as in previous timeseries. We have used this to compare each area over the same time period.
var x_c3 = d3.scaleLinear()
  .domain([0, max_days_case_x])
  .range([0, width_hm - 60]); // margin left (we pushed the start of the axis over by 50) + another 10 so things do not get cut off

// Append the x axis
var xAxis_line_3 = svg_cumulative_actual_log
  .append("g")
  .attr("transform", 'translate(0,' + (height_line - 50) + ")")
  .call(d3.axisBottom(x_c3).ticks(max_days_case_x));

// Log scale for y axis - we will hopefully be able to toggle between log and linear for people to see the difference it makes.
var y_c3_ts = d3.scaleLog()
  .domain([1, d3.max(df_3, function(d) {return +d.Cumulative_cases;})])
  .range([height_line - 50, 0])
  .base(10);

// Append the y axis
var y_c3_ts_axis = svg_cumulative_actual_log
  .append("g")
  .attr("transform", 'translate(0,0)')
  .call(d3.axisLeft(y_c3_ts).tickFormat(d3.format(',.0f')).tickValues([10, 50, 100, 200, 1000, 2000, 4000]));

// Create a tooltip for the lines and functions for displaying the tooltips as well as highlighting certain lines.
var tooltip_c3 = d3.select("#cumulative_log")
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

var showTooltip_c3 = function(d) {
  tooltip_c3
    .html("<h5>" + d.values[0].Name + '</h5><p class = "side">The current cumulative total for ' + d.values[0].Name + ' as at (latest date) ' + d.values[0]['Date_label'] + ' is ' +  d3.format(',.0f')(d.values[0]['Cumulative_cases']) + '.</p><p class = "side">It has been<b> ' + 'x days' + ' days</b> since the number of confirmed cases exceeded 10 cases.</p><p class = "side">The latest doubling time calculation suggests that confirmed cases in ' + d.values[0]['Name'] + ' are doubling every ' + ' doubling days '+ ' days.</p>')
    .style("opacity", 1)
    .style("top", (event.pageY - 10) + "px")
    .style("left", (event.pageX + 10) + "px")
    .style("visibility", "visible");

  var selection = d3.select(this);
  selection
      .transition()
      .delay("50")
      .duration("10")
      .attr('stroke-width', 3)
      .style("stroke", function(d){ return Area_colours(d.key) })

// It might be useful to also show a single circle at the end of the line
}

var mouseleave_c3 = function(d) {
tooltip_c3
  .style("visibility", "hidden")

var selection = d3.select(this)
    selection
    .transition()
    .delay("50")
    .duration("10")
.style('stroke', function(d){
  if (d.values[0]['Name'] === chosen_c3_highlight_area) {
      return  Area_colours(chosen_c3_highlight_area)}
      else {
      return '#d2d2d2'}
            })
.attr('stroke-width', function(d){
  if (d.values[0]['Name'] === chosen_c3_highlight_area) {
      return  3}
      else {
      return 1}
            })
  }

function update_highlight_c3() {

var chosen_c3_highlight_area = d3.select('#select_line_3_area_button').property("value")

ghost_line_c3
.transition()
.duration(200)
.style('stroke', function(d){
  if (d.values[0]['Name'] === chosen_c3_highlight_area) {
      return  Area_colours(chosen_c3_highlight_area)}
      else {
      return '#dbdbdb'}
            })
.attr('stroke-width', function(d){
  if (d.values[0]['Name'] === chosen_c3_highlight_area) {
      return  3}
      else {
      return 1}
            })
}

var lines_c3 = svg_cumulative_actual_log
.selectAll(".line")
.data(c3_ts_group)
.enter()
.append("path")
.attr('id', 'c3_lines')
.attr('class', 'c3_all_lines')

var ghost_line_c3 = svg_cumulative_actual_log
.selectAll(".line")
.data(c3_ts_group)
.enter()
.append("path")
.attr('class', 'c3_ghost_lines')

var defined_x = width_hm * 75
var defined_y = height_line - 180

function toggle_scale_c3_func() {

update_summary_c3()

var chosen_c3_highlight_area = d3.select('#select_line_3_area_button').property("value")
var type_scale = document.getElementsByName('toggle_c3_scale');
  if (type_scale[0].checked) {

var y_c3_ts = d3.scaleLog()
  .domain([1, d3.max(df_3, function(d) {
    return +d.Cumulative_cases;
  })])
  .range([height_line - 50, 0])
  .base(10);

y_c3_ts_axis
.transition()
.duration(1000)
.call(d3.axisLeft(y_c3_ts).tickFormat(d3.format(',.0f')).tickValues([10,50,100,250, 500, 1000, 5000]));

d3.select("#selected_line_3_log_title")
  .html(function(d) {
    return 'Covid-19 cumulative cases over time; days since case 10; loglinear scale; ' + chosen_c3_highlight_area + ' highlighted'
});

lines_c3
.transition()
.duration(500)
.attr("d", function(d){
    return d3.line()
  .x(function(d) { return x_c3(d.Days_since_case_x); })
  .y(function(d) { return y_c3_ts(+d.Cumulative_cases); })
  (d.values)
})

lines_c3
.on('mousemove', showTooltip_c3)
.on('mouseout', mouseleave_c3)

ghost_line_c3
.transition()
.duration(500)
.attr("d", function(d){
    return d3.line()
  .x(function(d) { return x_c3(d.Days_since_case_x); })
  .y(function(d) { return y_c3_ts(+d.Cumulative_cases); })
  (d.values)
})
.style('fill', 'none')
.style('stroke', function(d){
  if (d.values[0]['Name'] === chosen_c3_highlight_area) {
      return  Area_colours(chosen_c3_highlight_area)}
      else {
      return '#dbdbdb'}
            })
.attr('stroke-width', function(d){
  if (d.values[0]['Name'] === chosen_c3_highlight_area) {
      return  3}
      else {
      return 1}
            })

ghost_line_c3
.on('mousemove', showTooltip_c3)
.on('mouseout', mouseleave_c3)

  } else if (type_scale[1].checked) {


y_c3_ts = d3.scaleLinear()
  .domain([1, d3.max(df_3, function(d) {
    return +d.Cumulative_cases;
  })])
  .range([height_line - 50, 0]);

y_c3_ts_axis
.transition()
.duration(1000)
.call(d3.axisLeft(y_c3_ts).tickFormat(d3.format(',.0f')));

// Update text based on selected area
d3.select("#selected_line_3_log_title")
  .html(function(d) {
    return 'Covid-19 cumulative cases over time; days since case 10; linear scale; ' + chosen_c3_highlight_area + ' highlighted'
});
}

lines_c3
.transition()
.duration(500)
.attr("d", function(d){
    return d3.line()
  .x(function(d) { return x_c3(d.Days_since_case_x); })
  .y(function(d) { return y_c3_ts(+d.Cumulative_cases); })
  (d.values)
})

lines_c3
.on('mousemove', showTooltip_c3)
.on('mouseout', mouseleave_c3)

ghost_line_c3
.transition()
.duration(500)
.attr("d", function(d){
    return d3.line()
  .x(function(d) { return x_c3(d.Days_since_case_x); })
  .y(function(d) { return y_c3_ts(+d.Cumulative_cases); })
  (d.values)
})
.style('fill', 'none')
.style('stroke', function(d){
  if (d.values[0]['Name'] === chosen_c3_highlight_area) {
      return  Area_colours(chosen_c3_highlight_area)}
      else {
      return '#dbdbdb'}
            })
.attr('stroke-width', function(d){
  if (d.values[0]['Name'] === chosen_c3_highlight_area) {
      return  3}
      else {
      return 1}
            })

ghost_line_c3
.on('mousemove', showTooltip_c3)
.on('mouseout', mouseleave_c3)

};

toggle_scale_c3_func()

function update_summary_c3() {

var type_scale = document.getElementsByName('toggle_c3_scale');
  if (type_scale[0].checked) {

var defined_x = width_hm * .75
var defined_y = height_line - 180

  } else if (type_scale[1].checked) {

var defined_x = width_hm * .1
var defined_y = height_line - 280
}

var chosen_c3_highlight_area = d3.select('#select_line_3_area_button').property("value")
chosen_summary = df_3.filter(function(d){
  return d.Name === chosen_c3_highlight_area })

chosen_summary = chosen_summary.filter(function(d){
  return d.Days_since_case_x === d3.max(chosen_summary, function(d) {
           return +d.Days_since_case_x; })
})

chosen_doubling_summary = double_df.filter(function(d){
  return d.Name === chosen_c3_highlight_area &&
         d.period_in_reverse === 1; })

svg_cumulative_actual_log
  .selectAll("#highlight_area")
  .transition()
  .duration(100)
  .remove();
svg_cumulative_actual_log
  .selectAll("#highlight_area_t1")
  .transition()
  .duration(100)
  .remove();
svg_cumulative_actual_log
  .selectAll("#highlight_area_t2")
  .transition()
  .duration(100)
  .remove();
svg_cumulative_actual_log
  .selectAll("#highlight_area_t3")
  .transition()
  .duration(100)
  .remove();
svg_cumulative_actual_log
  .selectAll("#highlight_area_t4")
  .transition()
  .duration(100)
  .remove();

svg_cumulative_actual_log
  .append("text")
  .attr('id', 'highlight_area')
  .attr("x", defined_x)
  .attr("y", defined_y)
  .text(chosen_c3_highlight_area)
  .attr("text-anchor", "start")
  .style('font-weight', 'bold')
  .style("font-size", "12px")
  .attr('opacity', 0)
  .transition()
  .duration(500)
  .attr('opacity', 1)

svg_cumulative_actual_log
  .append("text")
  .attr('id', 'highlight_area_t1')
  .attr("x", defined_x)
  .attr("y", defined_y + 15)
  .text(chosen_summary[0].Days_since_case_x + ' days since confirmed case 10')
  .attr("text-anchor", "start")
  .attr('opacity', 0)
  .transition()
  .duration(500)
  .attr('opacity', 1)

svg_cumulative_actual_log
  .append("text")
  .attr('id', 'highlight_area_t2')
  .attr("x", defined_x)
  .attr("y", defined_y + 30)
  .text(d3.format(',.0f')(chosen_summary[0].Cumulative_cases) + ' confirmed cases so far ('+ d3.format(',.0f')(chosen_summary[0].Cumulative_per_100000) + ' per 100,000)')
  .attr("text-anchor", "start")
  .attr('opacity', 0)
  .transition()
  .duration(500)
  .attr('opacity', 1)

svg_cumulative_actual_log
  .append("text")
  .attr('id', 'highlight_area_t3')
  .attr("x", defined_x)
  .attr("y", defined_y + 50)
  .text('Confirmed cases doubling every ' + d3.format(',.1f')(chosen_doubling_summary[0].Double_time) +  ' days')
  .attr("text-anchor", "start")
  .attr('opacity', 0)
  .transition()
  .duration(500)
  .attr('opacity', 1)

svg_cumulative_actual_log
  .append("text")
  .attr('id', 'highlight_area_t4')
  .attr("x", defined_x)
  .attr("y", defined_y + 65)
  .text('(based on cases between ' + chosen_doubling_summary[0].long_date_label +')')
  .attr("text-anchor", "start")
  .attr('opacity', 0)
  .transition()
  .duration(500)
  .attr('opacity', 1)
}

// Initialise the summary text
update_summary_c3()

// on change of dropdown, highlight area, change colour, and add blurb.

// see why SE missing doubling time in R

d3.select("#select_line_3_area_button").on("change", function(d) {
var chosen_c3_highlight_area = d3.select('#select_line_3_area_button').property("value")
  toggle_scale_c3_func()
  update_highlight_c3()
  update_summary_c3()
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
