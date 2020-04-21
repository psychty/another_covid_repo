// log or linear plus doubled cases;

// select for area

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

d3.select("#selected_line_4_log_title")
  .html(function(d) {
    return 'Covid-19 cumulative cases over time including doubling time visualised; days since case 10; ' + chosen_c4_area + '; ' + 'loglinear' + ' scale'
});

function toggle_scale_func() {
  var type_scale = document.getElementsByName('toggle_scale');
  if (type_scale[0].checked) {

d3.select("#selected_line_4_log_title")
  .html(function(d) {
    return 'Covid-19 cumulative cases over time including doubling time visualised; days since case 10; ' + chosen_c4_area + '; ' + 'loglinear' + ' scale'
});

  } else if (type_scale[1].checked) {

d3.select("#selected_line_4_log_title")
  .html(function(d) {
    return 'Covid-19 cumulative cases over time including doubling time visualised; days since case 10; ' + chosen_c4_area + '; ' + 'linear' + ' scale'
});
}
};

// var df_4_linear_log = daily_cases.filter(function(d) {
//   return d.Days_since_case_x >= 0
// });

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
  // .each(function(d,i) { // find the text in that tick and removing it: Thanks Gerardo Furtado on stackoverflow
  //   if (i%2 != 1) d3.select(this).remove(); // This is switched from != 0 to != 1 so that the last date is displayed.
  //   });

// Log scale for y axis - we will hopefully be able to toggle between log and linear for people to see the difference it makes.
// var y_c4_ts = d3.scaleLog()
//   .domain([1, d3.max(chosen_4_predicted_double, function(d) {return +d.Cumulative_cases;})])
//   .range([height_line - 50, 0])
//   .base(10);

var y_c4_ts = d3.scaleLinear()
  .domain([0, d3.max(chosen_4_predicted_double, function(d) {
    return +d.Cumulative_cases;
  })])
  .range([height_line - 90, 0]);

// Append the y axis
var y_c4_ts_axis = svg_cumulative_double_added
  .append("g")
  .attr("transform", 'translate(0,0)')
  .call(d3.axisLeft(y_c4_ts).tickFormat(d3.format(',.0f')));

var actual_lines_c4 = svg_cumulative_double_added
  .append("path")
  .datum(chosen_4_linear_log)
  .attr("d", d3.line()
    .x(function(d) {
      return x_c4(d3.timeParse("%Y-%m-%d")(d.Date))
    })
    .y(function(d) {
      return y_c4_ts(d.Cumulative_cases)
    })
  )
  .attr("stroke", function(d){ return Area_colours(chosen_c4_area) })
  .style("fill", "none")
  .style("stroke-width", 2)

var dots_c4 = svg_cumulative_double_added
  .selectAll('myCircles')
  .data(chosen_4_linear_log)
  .enter()
  .append("circle")
  .attr("cx", function(d) {
    return x_c4(d3.timeParse("%Y-%m-%d")(d.Date))
  })
  .attr("cy", function(d) {
    return y_c4_ts(d.Cumulative_cases)
  })
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
  .attr("d", d3.line()
    .x(function(d) {
      return x_c4(d3.timeParse("%Y-%m-%d")(d.Date))
    })
    .y(function(d) {
      return y_c4_ts(d.Cumulative_cases)
    })
  )
  .style("fill", "none")
  .style("stroke-width", 2)
  .style("stroke", '#000000')
  .attr("stroke-dasharray", ("3, 3"))

var double_dots_c4 = svg_cumulative_double_added
  .selectAll('myCircles')
  .data(chosen_4_predicted_double)
  .enter()
  .append("circle")
  .attr("cx", function(d) {
    return x_c4(d3.timeParse("%Y-%m-%d")(d.Date))
  })
  .attr("cy", function(d) {
    return y_c4_ts(d.Cumulative_cases)
  })
  .attr("r", 3)
  .style("fill", function(d) {
    return '#c9c9c9'
  })
  .attr("stroke", "#000000")


function update_c4_lines() {

var chosen_c4_area = d3.select('#select_line_4_area_button').property("value")

d3.select("#selected_line_4_log_title")
  .html(function(d) {
    return 'Covid-19 cumulative cases over time including doubling time visualised; days since case 10; ' + chosen_c4_area + '; ' + 'loglinear' + ' scale'
});

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

y_c4_ts
  .domain([0, d3.max(chosen_4_predicted_double, function(d) { return +d.Cumulative_cases; })])

// Redraw axis
y_c4_ts_axis
  .transition()
  .duration(1000)
  .call(d3.axisLeft(y_c4_ts));

xAxis_line_4
  .transition()
  .duration(1000)
  .call(d3.axisBottom(x_c4).tickFormat(d3.timeFormat("%d-%B")).tickValues(c4_dates));

xAxis_line_4
  .selectAll("text")
  .attr("transform", 'translate(-10,10)rotate(-90)')
  .style("text-anchor", "end")

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

// Fix missing dots after transition
// Add a label to bottom right saying, a double date further into the future shows slowing down 

d3.select("#select_line_4_area_button").on("change", function(d) {
var chosen_c4_area = d3.select('#select_line_4_area_button').property("value")
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
