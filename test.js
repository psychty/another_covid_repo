
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

// This will be to highlight a particular line on the figure (and show some key figures)
d3.select("#select_line_3_area_button")
  .selectAll('myOptions')
  .data(['Brighton and Hove', 'East Sussex', 'West Sussex', 'England', 'Bracknell Forest', 'Buckinghamshire', 'Hampshire', 'Isle of Wight', 'Kent', 'Medway', 'Milton Keynes', 'Oxfordshire', 'Portsmouth', 'Reading', 'Slough', 'Southampton', 'Surrey', 'West Berkshire', 'Windsor and Maidenhead', 'Wokingham'])
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
  .call(d3.axisLeft(y_c3_ts).tickFormat(d3.format(',.0f')).tickValues([10, 50, 100, 200, 1000, 2000]));

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
    .html("<h5>" + d.Name + '</h5><p><b>' + d.Date_label + '</b></p><p class = "side">' + d.double_time_label_1 + '.</p><p class = "side">' + d.double_time_label_2 + '</p>')
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
    .style("stroke","#d2d2d2")
    .attr('stroke-width', 1)
  }

// function toggle_scale_c3_func() {
//   var type_scale = document.getElementsByName('toggle_c3_scale');
//   if (type_scale[0].checked) {
//     console.log("We'll put the loglinear version on for you")
//
// var y_c3_ts = d3.scaleLog()
//   .domain([1, d3.max(df_3, function(d) {
//     return +d.Cumulative_cases;
//   })])
//   .range([height_line - 50, 0])
//   .base(10);
//
// y_c3_ts_axis.selectAll(".y")
//   .transition()
//   .duration(1000)
//   .call(d3.axisLeft(y_c3_ts).tickFormat(d3.format(',.0f')).tickValues([0,10,50,100,250, 500, 1000, 5000]));
//
// d3.select("#selected_line_3_log_title")
//   .html(function(d) {
//     return 'Covid-19 cumulative cases over time; days since case 10; loglinear scale'
// });
//
//   } else if (type_scale[1].checked) {
//     console.log("We'll put the linear version on for you")
//
// var y_c3_ts = d3.scaleLinear()
//   .domain([1, d3.max(df_3, function(d) {
//     return +d.Cumulative_cases;
//   })])
//   .range([height_line - 50, 0]);
//
// y_c3_ts_axis.selectAll(".y")
//   .transition()
//   .duration(1000)
//   .call(d3.axisLeft(y_c3_ts).tickFormat(d3.format(',.0f')));
//
// // Update text based on selected area
// d3.select("#selected_line_3_log_title")
//   .html(function(d) {
//     return 'Covid-19 cumulative cases over time; days since case 10; linear scale'
// });;
// }
// };

// toggle_scale_c3_func()

// all areas on same chart except SE and England
// transition between log and linear scale on axis.
// on.mousemove highlight area, change colour.
// on change of dropdown, highlight area, change colour, and add blurb.

var lines_c3 = svg_cumulative_actual_log
.selectAll(".line")
.data(c3_ts_group)

lines_c3
.enter()
.append("path")
.attr('id', 'c3_lines')
.attr('class', 'c3_all_lines')
.attr("d", function(d){
    return d3.line()
  .x(function(d) { return x_c3(d.Days_since_case_x); })
  .y(function(d) { return y_c3_ts(+d.Cumulative_cases); })
  (d.values)
})
.on('mousemove', showTooltip_c3)
.on('mouseout', mouseleave_c3)

// var ghost_lines_c3 = svg_cumulative_actual_log
// .selectAll(".line")
// .data(c3_ts_group)
// .enter()
// .append("path")
// .attr('class', 'c3_ghost_lines')
// .attr("d", function(d){
//     return d3.line()
//   .x(function(d) { return x_c3(d.Days_since_case_x); })
//   .y(function(d) { return y_c3_ts(+d.Cumulative_cases); })
//   (d.values)
// })
// .on('mousemove', showTooltip_c3)
// .on('mouseout', mouseleave_c3)





// lines_tf
// .on("mouseover", function(){return tooltip.style("visibility", "visible");})
// .on("mousemove", function(){return tooltip.style("top", (event.pageY-10)+"px").style("left",(event.pageX+10)+"px");})
// .on("mouseout", function(){return tooltip.style("visibility", "hidden");});

// see why SE missing doubling time in R

d3.select("#select_line_3_area_button").on("change", function(d) {
  var selected_line_2_area_option = d3.select('#select_line_2_area_button').property("value")
  toggle_scale_c3_func()
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
