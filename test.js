// log or linear plus doubled cases;

// We need to create a dropdown button for the user to choose which area to be displayed on the figure.
d3.select("#select_line_4_area_button")
  .selectAll('myOptions')
  .data(areas_line)
  .enter()
  .append('option')
  .text(function(d) {
    return d;
  })
  .attr("value", function(d) {
    return d;
  })

// Retrieve the selected area name
var chosen_c4_area = d3.select('#select_line_4_area_button').property("value")

var chosen_4_linear_log = daily_cases.filter(function(d) {
  return d.Days_since_case_x >= 0 &&
         d.Name === chosen_c4_area
});

var chosen_4_predicted_double = doubling_shown_df.filter(function(d) {
  return d.Name === chosen_c4_area
});

var svg_cumulative_double_added = d3.select("#cumulative_log_double_time_added")
.append("svg")
.attr("width", width_hm)
.attr("height", height_line)
.append("g")
.attr("transform", "translate(" + 50 + "," + 20 + ")");

var c4_dates = chosen_4_linear_log.map(function(d) {return d3.timeParse("%Y-%m-%d")(d.Date);});
c4_dates.push(d3.max(chosen_4_predicted_double, function(d) { return d3.timeParse("%Y-%m-%d")(d.Date);}))

var x_c4 = d3.scaleLinear()
  .domain([d3.min(c4_dates, function(d) { return d;}), d3.max(c4_dates, function(d) { return d;})])
  .range([0, width_hm - 60]); // this is the 50 that was pushed over from the left plus another 10 so that the chart does not get cut off

var xAxis_line_4 = svg_cumulative_double_added
  .append("g")
  .attr('id', 'old_c4_x_axis')
  .attr("transform", 'translate(0,' + (height_line - 90) + ")")
  .attr('class', 'ticked_off')
  .call(d3.axisBottom(x_c4).tickFormat(d3.timeFormat("%d-%B")).tickValues(c4_dates));

xAxis_line_4
  .selectAll("text")
  .attr("transform", 'translate(-10,10)rotate(-90)')
  .style("text-anchor", "end")

// Log scale for y axis - we will hopefully be able to toggle between log and linear for people to see the difference it makes.
var y_c4_ts = d3.scaleLog()
  .domain([1, d3.max(chosen_4_predicted_double, function(d) {return +d.Cumulative_cases;})])
  .range([height_line - 90, 0])
  .base(10);

// Append the y axis
var y_c4_ts_axis = svg_cumulative_double_added
  .append("g")
  .attr("transform", 'translate(0,0)')
  .call(d3.axisLeft(y_c4_ts).tickFormat(d3.format(',.0f')).tickValues([10, 50, 100, 200, 1000, 2000, 4000, 8000, 10000, 50000, 100000, 200000]));

var actual_lines_c4 = svg_cumulative_double_added
  .append("path")
  .datum(chosen_4_linear_log)
  .attr("stroke", function(d){ return Area_colours(chosen_c4_area) })
  .style("fill", "none")
  .style("stroke-width", 2)

var dots_c4 = svg_cumulative_double_added
  .selectAll('myCircles')
  .data(chosen_4_linear_log)
  .enter()
  .append("circle")
  .attr("r", 3)
  .style("fill", function(d) {
    return Area_colours(chosen_c4_area)
  })
  .attr("stroke", function(d) {
    return Area_colours(chosen_c4_area)
  })

var double_lines_c4 = svg_cumulative_double_added
  .append("path")
  .datum(chosen_4_predicted_double)
  .style("fill", "none")
  .style("stroke-width", 2)
  .style("stroke", '#000000')
  .attr("stroke-dasharray", ("3, 3"))

var double_dots_c4 = svg_cumulative_double_added
  .selectAll('myCircles')
  .data(chosen_4_predicted_double)
  .enter()
  .append("circle")
  .attr("r", 3)
  .style("fill", function(d) {
    return '#c9c9c9'
  })
  .attr("stroke", "#000000")

// Create a tooltip for the lines and functions for displaying the tooltips as well as highlighting certain lines.
var tooltip_c4 = d3.select("#cumulative_log_double_time_added")
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

var showTooltip_c4 = function(d, i) {

  tooltip_c4
    .html("<h5>" + d.Name + '</h5><p class = "side"></p>')
    .style("opacity", 1)
    .style("top", (event.pageY - 10) + "px")
    .style("left", (event.pageX + 10) + "px")
    .style("visibility", "visible");

}

var mouseleave_c4 = function(d) {
tooltip_c4
  .style("visibility", "hidden")
}

function update_c4_lines() {

var chosen_c4_area = d3.select('#select_line_4_area_button').property("value")

var chosen_4_linear_log = daily_cases.filter(function(d) {
  return d.Days_since_case_x >= 0 &&
         d.Name === chosen_c4_area
});

var chosen_4_predicted_double = doubling_shown_df.filter(function(d) {
  return d.Name === chosen_c4_area
});

var c4_dates = chosen_4_linear_log.map(function(d) {return d3.timeParse("%Y-%m-%d")(d.Date);});
c4_dates.push(d3.max(chosen_4_predicted_double, function(d) { return d3.timeParse("%Y-%m-%d")(d.Date);}))

x_c4
  .domain([d3.min(c4_dates, function(d) { return d;}), d3.max(c4_dates, function(d) { return d;})])

xAxis_line_4
  .transition()
  .duration(1000)
  .call(d3.axisBottom(x_c4).tickFormat(d3.timeFormat("%d-%B")).tickValues(c4_dates));

xAxis_line_4
  .selectAll("text")
  .attr("transform", 'translate(-10,10)rotate(-90)')
  .style("text-anchor", "end")

var type_c4_scale = document.getElementsByName('toggle_c4_scale');
if (type_c4_scale[0].checked) {

// Log scale for y axis - we will hopefully be able to toggle between log and linear for people to see the difference it makes.
var y_c4_ts = d3.scaleLog()
  .domain([1, d3.max(chosen_4_predicted_double, function(d) {return +d.Cumulative_cases;})])
  .range([height_line - 90, 0])
  .base(10);
y_c4_ts_axis
.transition()
.duration(1000)
.call(d3.axisLeft(y_c4_ts).tickFormat(d3.format(',.0f')));
  } else if (type_c4_scale[1].checked) {
y_c4_ts = d3.scaleLinear()
  .domain([1, d3.max(chosen_4_predicted_double, function(d) {return +d.Cumulative_cases;})])
  .range([height_line - 90, 0]);
y_c4_ts_axis
.transition()
.duration(1000)
.call(d3.axisLeft(y_c4_ts).tickFormat(d3.format(',.0f')));
}

actual_lines_c4
  .datum(chosen_4_linear_log)
  .transition()
  .duration(1000)
  .attr("d", d3.line()
    .x(function(d) {
      return x_c4(d3.timeParse("%Y-%m-%d")(d.Date))
    })
    .y(function(d) {
      return y_c4_ts(d.Cumulative_cases)
    })
  )
  .attr("stroke", function(d){ return Area_colours(chosen_c4_area) })

dots_c4
  .transition()
  .attr("r", 0)

dots_c4
  .data(chosen_4_linear_log)
  // .append("circle")
  .transition()
  .duration(1000)
  .attr("cx", function(d) {
    return x_c4(d3.timeParse("%Y-%m-%d")(d.Date))
  })
  .attr("cy", function(d) {
    return y_c4_ts(d.Cumulative_cases)
  })
  .style("fill", function(d) {
    return Area_colours(chosen_c4_area)
  })
  .attr("stroke", function(d) {
    return Area_colours(chosen_c4_area)
  })
  .attr("r", 3)

dots_c4
.on('mousemove', showTooltip_c4)
.on('mouseout', mouseleave_c4)

double_lines_c4
  .datum(chosen_4_predicted_double)
  .transition()
  .duration(1000)
  .attr("d", d3.line()
    .x(function(d) {
      return x_c4(d3.timeParse("%Y-%m-%d")(d.Date))
    })
    .y(function(d) {
      return y_c4_ts(d.Cumulative_cases)
    })
  )

double_dots_c4
  .data(chosen_4_predicted_double)
  .transition()
  .duration(1000)
  .attr("cx", function(d) {
    return x_c4(d3.timeParse("%Y-%m-%d")(d.Date))
  })
  .attr("cy", function(d) {
    return y_c4_ts(d.Cumulative_cases)
  })
  .attr("r", 3)

update_summary_c4()

}

function toggle_scale_c4_func() {

update_summary_c4()

var type_c4_scale = document.getElementsByName('toggle_c4_scale');
if (type_c4_scale[0].checked) {

// Retrieve the selected area name
var chosen_c4_area = d3.select('#select_line_4_area_button').property("value")

var chosen_4_linear_log = daily_cases.filter(function(d) {
  return d.Days_since_case_x >= 0 &&
         d.Name === chosen_c4_area
});

var chosen_4_predicted_double = doubling_shown_df.filter(function(d) {
  return d.Name === chosen_c4_area
});

d3.select("#selected_line_4_log_title")
  .html(function(d) {
    return 'Covid-19 cumulative cases over time including doubling time visualised; days since confirmed case 10; ' + chosen_c4_area + '; ' + 'loglinear' + ' scale'
});

// Log scale for y axis - we will hopefully be able to toggle between log and linear for people to see the difference it makes.
var y_c4_ts = d3.scaleLog()
  .domain([1, d3.max(chosen_4_predicted_double, function(d) {return +d.Cumulative_cases;})])
  .range([height_line - 90, 0])
  .base(10);

y_c4_ts_axis
.transition()
.duration(1000)
.call(d3.axisLeft(y_c4_ts).tickFormat(d3.format(',.0f')));

actual_lines_c4
  .datum(chosen_4_linear_log)
  .transition()
  .duration(1000)
  .attr("d", d3.line()
    .x(function(d) {
      return x_c4(d3.timeParse("%Y-%m-%d")(d.Date))
    })
    .y(function(d) {
      return y_c4_ts(d.Cumulative_cases)
    })
  )
  .attr("stroke", function(d){ return Area_colours(chosen_c4_area) })

dots_c4
  .transition()
  .attr("r", 0)

dots_c4
  .data(chosen_4_linear_log)
  // .append("circle")
  .transition()
  .duration(1000)
  .attr("cx", function(d) {
    return x_c4(d3.timeParse("%Y-%m-%d")(d.Date))
  })
  .attr("cy", function(d) {
    return y_c4_ts(d.Cumulative_cases)
  })
  .style("fill", function(d) {
    return Area_colours(chosen_c4_area)
  })
  .attr("stroke", function(d) {
    return Area_colours(chosen_c4_area)
  })
  .attr("r", 3)

dots_c4
.on('mousemove', showTooltip_c4)
.on('mouseout', mouseleave_c4)

double_lines_c4
  .datum(chosen_4_predicted_double)
  .transition()
  .duration(1000)
  .attr("d", d3.line()
    .x(function(d) {
      return x_c4(d3.timeParse("%Y-%m-%d")(d.Date))
    })
    .y(function(d) {
      return y_c4_ts(d.Cumulative_cases)
    })
  )

double_dots_c4
  .data(chosen_4_predicted_double)
  .transition()
  .duration(1000)
  .attr("cx", function(d) {
    return x_c4(d3.timeParse("%Y-%m-%d")(d.Date))
  })
  .attr("cy", function(d) {
    return y_c4_ts(d.Cumulative_cases)
  })
  .attr("r", 3)

  } else if (type_c4_scale[1].checked) {

var chosen_c4_area = d3.select('#select_line_4_area_button').property("value")

var chosen_4_linear_log = daily_cases.filter(function(d) {
  return d.Days_since_case_x >= 0 &&
         d.Name === chosen_c4_area
});

var chosen_4_predicted_double = doubling_shown_df.filter(function(d) {
  return d.Name === chosen_c4_area
});

d3.select("#selected_line_4_log_title")
  .html(function(d) {
    return 'Covid-19 cumulative cases over time including doubling time visualised; days since confirmed case 10; ' + chosen_c4_area + '; ' + 'linear' + ' scale'
});

y_c4_ts = d3.scaleLinear()
  .domain([1, d3.max(chosen_4_predicted_double, function(d) {return +d.Cumulative_cases;})])
  .range([height_line - 90, 0]);

y_c4_ts_axis
.transition()
.duration(1000)
.call(d3.axisLeft(y_c4_ts).tickFormat(d3.format(',.0f')));

actual_lines_c4
  .datum(chosen_4_linear_log)
  .transition()
  .duration(1000)
  .attr("d", d3.line()
    .x(function(d) {
      return x_c4(d3.timeParse("%Y-%m-%d")(d.Date))
    })
    .y(function(d) {
      return y_c4_ts(d.Cumulative_cases)
    })
  )
  .attr("stroke", function(d){ return Area_colours(chosen_c4_area) })

dots_c4
  .transition()
  .attr("r", 0)

dots_c4
  .data(chosen_4_linear_log)
  // .append("circle")
  .transition()
  .duration(1000)
  .attr("cx", function(d) {
    return x_c4(d3.timeParse("%Y-%m-%d")(d.Date))
  })
  .attr("cy", function(d) {
    return y_c4_ts(d.Cumulative_cases)
  })
  .style("fill", function(d) {
    return Area_colours(chosen_c4_area)
  })
  .attr("stroke", function(d) {
    return Area_colours(chosen_c4_area)
  })
  .attr("r", 3)

dots_c4
.on('mousemove', showTooltip_c4)
.on('mouseout', mouseleave_c4)

double_lines_c4
  .datum(chosen_4_predicted_double)
  .transition()
  .duration(1000)
  .attr("d", d3.line()
    .x(function(d) {
      return x_c4(d3.timeParse("%Y-%m-%d")(d.Date))
    })
    .y(function(d) {
      return y_c4_ts(d.Cumulative_cases)
    })
  )

double_dots_c4
  .data(chosen_4_predicted_double)
  .transition()
  .duration(1000)
  .attr("cx", function(d) {
    return x_c4(d3.timeParse("%Y-%m-%d")(d.Date))
  })
  .attr("cy", function(d) {
    return y_c4_ts(d.Cumulative_cases)
  })
  .attr("r", 3)
}
};

function update_summary_c4() {

var chosen_c4_area = d3.select('#select_line_4_area_button').property("value")

var chosen_4_linear_log = daily_cases.filter(function(d) {
  return d.Days_since_case_x >= 0 &&
         d.Name === chosen_c4_area
});

var chosen_4_predicted_double = doubling_shown_df.filter(function(d) {
  return d.Name === chosen_c4_area
});

var type_c4_scale = document.getElementsByName('toggle_c4_scale');
  if (type_c4_scale[0].checked) {

var defined_x = width_hm * .7
var defined_y = height_line - 200
// Log scale for y axis - we will hopefully be able to toggle between log and linear for people to see the difference it makes.
var y_c4_ts = d3.scaleLog()
  .domain([1, d3.max(chosen_4_predicted_double, function(d) {return +d.Cumulative_cases;})])
  .range([height_line - 90, 0])
  .base(10);
y_c4_ts_axis
.transition()
.duration(1000)
.call(d3.axisLeft(y_c4_ts).tickFormat(d3.format(',.0f')));

  } else if (type_c4_scale[1].checked) {

var defined_x = width_hm * .05
var defined_y = height_line - 300
y_c4_ts = d3.scaleLinear()
  .domain([1, d3.max(chosen_4_predicted_double, function(d) {return +d.Cumulative_cases;})])
  .range([height_line - 90, 0]);
y_c4_ts_axis
.transition()
.duration(1000)
.call(d3.axisLeft(y_c4_ts).tickFormat(d3.format(',.0f')));
}

svg_cumulative_double_added
  .selectAll("#c4_area")
  .transition()
  .duration(100)
  .remove();
svg_cumulative_double_added
  .selectAll("#c4_area_t2")
  .transition()
  .duration(100)
  .remove();
svg_cumulative_double_added
  .selectAll("#c4_area_t3")
  .transition()
  .duration(100)
  .remove();
svg_cumulative_double_added
  .selectAll("#c4_area_t4")
  .transition()
  .duration(100)
  .remove();
svg_cumulative_double_added
  .selectAll("#c4_area_t5")
  .transition()
  .duration(100)
  .remove();
svg_cumulative_double_added
  .selectAll("#c4_area_t6")
  .transition()
  .duration(100)
  .remove();
svg_cumulative_double_added
  .selectAll("#c4_area_t7")
  .transition()
  .duration(100)
  .remove();

svg_cumulative_double_added
  .append("text")
  .attr('id', 'c4_area')
  .attr("x", defined_x)
  .attr("y", defined_y)
  .text(chosen_c4_area)
  .attr("text-anchor", "start")
  .style('font-weight', 'bold')
  .style("font-size", "12px")
  .attr('opacity', 0)
  .transition()
  .duration(500)
  .attr('opacity', 1)

svg_cumulative_double_added
  .append("text")
  .attr('id', 'c4_area_t2')
  .attr("x", defined_x)
  .attr("y", defined_y + 15)
  .text(d3.format(',.0f')(chosen_4_predicted_double.filter(function(d){ return d.Data_type === 'Recorded'})[0]['Cumulative_cases']) + ' confirmed cases as at '+ chosen_4_predicted_double.filter(function(d){ return d.Data_type === 'Recorded'})[0]['Period'] + " (latest 'complete' date)")
  .attr("text-anchor", "start")
  .attr('opacity', 0)
  .transition()
  .duration(500)
  .attr('opacity', 1)

svg_cumulative_double_added
  .append("text")
  .attr('id', 'c4_area_t3')
  .attr("x", defined_x)
  .attr("y", defined_y + 35)
  .text('Based on data from ' + date_range_doubling[0]['long_date_label'].replace('and','to') +', confirmed')
  .attr("text-anchor", "start")
  .attr('opacity', 0)
  .transition()
  .duration(500)
  .attr('opacity', 1)

svg_cumulative_double_added
  .append("text")
  .attr('id', 'c4_area_t3')
  .attr("x", defined_x)
  .attr("y", defined_y + 50)
  .text('cases were doubling every ' + d3.format(',.1f')(chosen_doubling_summary[0].Double_time) +  ' days')
  .attr("text-anchor", "start")
  .attr('opacity', 0)
  .transition()
  .duration(500)
  .attr('opacity', 1)

svg_cumulative_double_added
  .append("text")
  .attr('id', 'c4_area_t4')
  .attr("x", defined_x)
  .attr("y", defined_y + 70)
  .text('This means the number of confirmed cases')
  .attr("text-anchor", "start")
  .attr('opacity', 0)
  .transition()
  .duration(500)
  .attr('opacity', 1)

svg_cumulative_double_added
  .append("text")
  .attr('id', 'c4_area_t5')
  .attr("x", defined_x)
  .attr("y", defined_y + 85)
  .text('could reach ' + d3.format(',.0f')(chosen_4_predicted_double.filter(function(d){ return d.Data_type === 'Predicted'})[0]['Cumulative_cases']) + ' (double) by ' + chosen_4_predicted_double.filter(function(d){ return d.Data_type === 'Predicted'})[0]['Period'])
  .attr("text-anchor", "start")
  .attr('opacity', 0)
  .transition()
  .duration(500)
  .attr('opacity', 1)

svg_cumulative_double_added
  .append("text")
  .attr('id', 'c4_area_t6')
  .attr("x", x_c4(d3.timeParse("%Y-%m-%d")(chosen_4_predicted_double.filter(function(d){ return d.Data_type === 'Recorded'})[0]['Date'])))
  .attr("y", y_c4_ts(chosen_4_predicted_double.filter(function(d){ return d.Data_type === 'Recorded'})[0]['Cumulative_cases']) + 25)
  .text('Note that the last five data points')
  .attr("text-anchor", "start")
  .attr('opacity', 0)
  .transition()
  .duration(500)
  .attr('opacity', 1)

svg_cumulative_double_added
  .append("text")
  .attr('id', 'c4_area_t7')
  .attr("x", x_c4(d3.timeParse("%Y-%m-%d")(chosen_4_predicted_double.filter(function(d){ return d.Data_type === 'Recorded'})[0]['Date'])))
  .attr("y", y_c4_ts(chosen_4_predicted_double.filter(function(d){ return d.Data_type === 'Recorded'})[0]['Cumulative_cases']) + 40)
  .text('are not included in the calculation.')
  .attr("text-anchor", "start")
  .attr('opacity', 0)
  .transition()
  .duration(500)
  .attr('opacity', 1)

}

toggle_scale_c4_func()
update_summary_c4()

d3.select("#select_line_4_area_button").on("change", function(d) {
var chosen_c4_area = d3.select('#select_line_4_area_button').property("value")
  toggle_scale_c4_func()
  update_summary_c4()
  update_c4_lines()
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
