var height_line = 400;

// List of years in the dataset
var areas_line = ['Sussex areas combined', 'Brighton and Hove', 'East Sussex', 'West Sussex', 'South East region', 'England', 'Bracknell Forest', 'Buckinghamshire', 'Hampshire', 'Isle of Wight', 'Kent', 'Medway', 'Milton Keynes', 'Oxfordshire', 'Portsmouth', 'Reading', 'Slough', 'Southampton', 'Surrey', 'West Berkshire', 'Windsor and Maidenhead', 'Wokingham']

var Area_colours = d3.scaleOrdinal()
  .domain(areas_line)
  .range(["#d34a2a","#56b851","#bc4bb8","#9bb835","#7b62d0","#c0aa40","#5e74bf","#e27d3c","#5ea3d9","#d2404e","#4fb89c","#d73f7c","#42793c","#e270b7","#90a658","#975088","#d69a45","#c490d4","#846f2e","#a84b5e","#a55730","#e28882"]);


// Number of outbreaks reported in care homes
var request = new XMLHttpRequest();
request.open("GET", "./care_home_outbreaks.json", false);
request.send(null);
var ch_outbreak_data = JSON.parse(request.responseText);

var request = new XMLHttpRequest();
request.open("GET", "./care_home_outbreak_dates.json", false);
request.send(null);
var ch_outbreak_data_date = JSON.parse(request.responseText);

var svg_carehome_outbreak_number = d3.select('#carehome_outbreak_number')
  .append("svg")
  .attr("width", width_hm)
  .attr("height", height_line)
  .append("g")
  .attr("transform", "translate(" + 50 + "," + 20 + ")");

// We need to create a dropdown button for the user to choose which area to be displayed on the figure.
d3.select("#select_carehome_outbreak_area_button")
  .selectAll('myOptions')
  .data(['Sussex areas combined','Brighton and Hove', 'East Sussex', 'West Sussex', 'Bracknell Forest', 'Buckinghamshire', 'Hampshire', 'Isle of Wight', 'Kent', 'Medway', 'Milton Keynes', 'Oxfordshire', 'Portsmouth', 'Reading', 'Slough', 'Southampton', 'Surrey', 'West Berkshire', 'Windsor and Maidenhead', 'Wokingham'])
  .enter()
  .append('option')
  .text(function(d) {
    return d;
  })
  .attr("value", function(d) {
    return d;
  })

// Retrieve the selected area name
var chosen_ch_outbreak_area = d3.select('#select_carehome_outbreak_area_button').property("value")

d3.select("#carehome_outbreak_title")
  .html(function(d) {
    return 'Number of care homes reporting suspected or confirmed Covid-19; 2020 to ' + ch_outbreak_data_date[1]['Week_beginning'] + '; ' + chosen_ch_outbreak_area });

var chosen_ch_outbreak_df = ch_outbreak_data.filter(function(d) {
  return d.Name === chosen_ch_outbreak_area
});

weeks_outbreak_ch = chosen_ch_outbreak_df.map(function(d) {return (d.Week_beginning);});

var ch_number_in_area = d3.map(chosen_ch_outbreak_df, function(d){return d['Number of care homes'];}).keys()[0]

ch_with_outbreaks_so_far =  d3.max(chosen_ch_outbreak_df, function(d) {return +d.Cumulative_outbreaks;})

var x_ch_outbreaks = d3.scaleBand()
  .domain(weeks_outbreak_ch)
  .range([0, width_hm - 60]) // this is the 50 that was pushed over from the left plus another 10 so that the chart does not get cut off

var xAxis_ch_outbreaks = svg_carehome_outbreak_number
  .append("g")
  .attr("transform", 'translate(0,' + (height_line - 120 ) + ")")
  .call(d3.axisBottom(x_ch_outbreaks).tickSizeOuter(0));

xAxis_ch_outbreaks
  .selectAll("text")
  .attr("transform", 'translate(-12,10)rotate(-90)')
  .style("text-anchor", "end");

var y_ch_outbreaks = d3.scaleLinear()
  .domain([0, +ch_number_in_area])
  .range([height_line - 120 , 0])
  .nice();

var y_ch_outbreaks_axis = svg_carehome_outbreak_number
  .append("g")
  .attr("transform", 'translate(0,0)')
  .call(d3.axisLeft(y_ch_outbreaks));

svg_carehome_outbreak_number
  .append('line')
  .attr('id', 'carehomes_baseline')
  .attr('x1', 0)
  .attr('y1', y_ch_outbreaks(+ch_number_in_area))
  .attr('x2', width_hm - 60)
  .attr('y2', y_ch_outbreaks(+ch_number_in_area))
  .attr('stroke', '#000000')
  .attr("stroke-dasharray", ("3, 3"))

svg_carehome_outbreak_number
  .append('text')
  .attr('id', 'carehomes_baseline_value')
  .attr('x', 10)
  .attr('y', y_ch_outbreaks(+ch_number_in_area) + 10)
  .text(ch_number_in_area + ' CQC registered settings')
  .attr("text-anchor", 'start')
  .style('font-weight', 'bold')
  .style("font-size", "10px")

var tooltip_ch_outbreaks = d3.select("#carehome_outbreak_number")
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

var showTooltip_ch_outbreaks = function(d) {

  tooltip_ch_outbreaks
    .html("<h5>" + d.Name + '</h5><p><b>' + d.Week_beginning + '</b></p><p>This week ' + d3.format(',.0f')(d.Outbreaks) + ' new care homes* reported suspected or confirmed outbreaks to PHE.</p><p>The total number of care home settings which have reported at least one suspected or confirmed Covid-19 outbreak to PHE as at ' + d.Week_beginning + ' is ' + d3.format(',.0f')(d.Cumulative_outbreaks) + ' homes.</p><p>* Care homes are only included in the release once and subsequent outbreaks are not currently identified as new outbreaks.</p>')
    .style("opacity", 1)
    .style("top", (event.pageY - 10) + "px")
    .style("left", (event.pageX + 10) + "px")
    .style('opacity', 1)
    .style("visibility", "visible")
}

var mouseleave_ch_outbreak = function(d) {
  tooltip_ch_outbreaks
    .style('opacity', 0)
    .style("visibility", "hidden")
}


var lines_outbreaks = svg_carehome_outbreak_number
    .append('g')
    .append("path")
    .datum(chosen_ch_outbreak_df)
    .attr("d", d3.line()
        .x(function (d) {
            return x_ch_outbreaks(d.Week_beginning) + (x_ch_outbreaks.bandwidth() /2)
        })
        .y(function (d) {
            return y_ch_outbreaks(+d.Cumulative_outbreaks)
        }))
    .attr("stroke", function (d) {
        return Area_colours(chosen_ch_outbreak_area)
    })
    .style("stroke-width", 2)
    .style("fill", "none");

var dots_outbreaks = svg_carehome_outbreak_number
  .selectAll('myoutbreakCircles')
  .data(chosen_ch_outbreak_df)
  .enter()
  .append("circle")
  .attr("cx", function(d) { return x_ch_outbreaks(d.Week_beginning) + (x_ch_outbreaks.bandwidth() /2) } )
  .attr("cy", function(d) { return y_ch_outbreaks(+d.Cumulative_outbreaks) } )
  .attr("r", 6)
  .style("fill", function(d){ return Area_colours(chosen_ch_outbreak_area)})
  .attr("stroke", "white")
  .on('mousemove', showTooltip_ch_outbreaks)
  .on('mouseout', mouseleave_ch_outbreak)

var bars_weekly_outbreaks = svg_carehome_outbreak_number
  .selectAll("myoutbreakbar")
  .data(chosen_ch_outbreak_df)
  .enter()
  .append("rect")
  .attr("x", function(d) { return x_ch_outbreaks(d.Week_beginning) +  (x_ch_outbreaks.bandwidth() / 4); })
  .attr("y", function(d) { return y_ch_outbreaks(+d.Outbreaks); })
  .attr("width", x_ch_outbreaks.bandwidth() / 2)
  .attr("height", function(d) { return (height_line - 120 ) - y_ch_outbreaks(+d.Outbreaks); })
  .style("fill", function(d){ return Area_colours(chosen_ch_outbreak_area)})
  .on('mousemove', showTooltip_ch_outbreaks)
  .on('mouseout', mouseleave_ch_outbreak)

svg_carehome_outbreak_number
  .append('text')
  .attr('id', 'carehomes_so_far_text')
  .attr('x', 15)
  .attr('y', 60)
  .text(ch_with_outbreaks_so_far)
  .attr("text-anchor", 'start')
  .style('font-weight', 'bold')
  .style("font-size", "16px")

svg_carehome_outbreak_number
  .append('text')
  .attr('x', 15)
  .attr('y', 75)
  .text('care home settings')
  .attr("text-anchor", 'start')
  .style("font-size", "10px")

svg_carehome_outbreak_number
  .append('text')
  .attr('x', 15)
  .attr('y', 90)
  .text('with outbreaks reported')
  .attr("text-anchor", 'start')
  .style("font-size", "10px")

function update_ch_outbreaks(chosen_ch_outbreak_area){
var chosen_ch_outbreak_area = d3.select('#select_carehome_outbreak_area_button').property("value")
d3.select("#carehome_outbreak_title")
  .html(function(d) {
    return 'Number of care homes reporting suspected or confirmed Covid-19; 2020 to ' + ch_outbreak_data_date[1]['Week_beginning'] + '; ' + chosen_ch_outbreak_area });

var chosen_ch_outbreak_df = ch_outbreak_data.filter(function(d) {
  return d.Name === chosen_ch_outbreak_area
});

var ch_number_in_area = d3.map(chosen_ch_outbreak_df, function(d){return d['Number of care homes'];}).keys()[0]
var weeks_outbreak_ch = chosen_ch_outbreak_df.map(function(d) {return (d.Week_beginning);})
ch_with_outbreaks_so_far =  d3.max(chosen_ch_outbreak_df, function(d) {return +d.Cumulative_outbreaks;})

y_ch_outbreaks
  .domain([0, +ch_number_in_area])
  .nice()

y_ch_outbreaks_axis
  .transition()
  .duration(1000)
  .call(d3.axisLeft(y_ch_outbreaks).tickFormat(d3.format(',.0f')));

svg_carehome_outbreak_number
    .selectAll("#carehomes_baseline")
    .transition()
    .duration(500)
    .style("opacity", 0)
    .remove();

svg_carehome_outbreak_number
    .selectAll("#carehomes_baseline_value")
    .transition()
    .duration(500)
    .style("opacity", 0)
    .remove();

svg_carehome_outbreak_number
    .selectAll("#carehomes_so_far_text")
    .transition()
    .duration(500)
    .style("opacity", 0)
    .remove();

svg_carehome_outbreak_number
  .append('text')
  .attr('id', 'carehomes_so_far_text')
  .attr('x', 15)
  .attr('y', 60)
  .text(ch_with_outbreaks_so_far)
  .attr("text-anchor", 'start')
  .style('font-weight', 'bold')
  .style("font-size", "16px")

svg_carehome_outbreak_number
  .append('line')
  .attr('id', 'carehomes_baseline')
  .attr('x1', 0)
  .attr('y1', y_ch_outbreaks(+ch_number_in_area))
  .attr('x2', width_hm - 60)
  .attr('y2', y_ch_outbreaks(+ch_number_in_area))
  .attr('stroke', '#000000')
  .attr("stroke-dasharray", ("3, 3"))
  .style("opacity", 0)
  .transition()
  .duration(500)
  .style("opacity", 1)

svg_carehome_outbreak_number
  .append('text')
  .attr('id', 'carehomes_baseline_value')
  .attr('x', 10)
  .attr('y', y_ch_outbreaks(+ch_number_in_area) + 10)
  .text(ch_number_in_area + ' CQC registered settings')
  .attr("text-anchor", 'start')
  .style('font-weight', 'bold')
  .style("font-size", "10px")
  .style("opacity", 0)
  .transition()
  .duration(500)
  .style("opacity", 1)

lines_outbreaks
.datum(chosen_ch_outbreak_df)
.transition()
.duration(1000)
.attr("d", d3.line()
    .x(function (d) {
          return x_ch_outbreaks(d.Week_beginning) + (x_ch_outbreaks.bandwidth() /2)
        })
    .y(function (d) {
          return y_ch_outbreaks(+d.Cumulative_outbreaks)
        }))
.attr("stroke", function (d) {
        return Area_colours(chosen_ch_outbreak_area)
    })

dots_outbreaks
  .data(chosen_ch_outbreak_df)
  .transition()
  .duration(1000)
  .attr("cx", function(d) { return x_ch_outbreaks(d.Week_beginning) + (x_ch_outbreaks.bandwidth() /2) } )
  .attr("cy", function(d) { return y_ch_outbreaks(+d.Cumulative_outbreaks) } )
  .style("fill", function(d){ return Area_colours(chosen_ch_outbreak_area)})

dots_outbreaks
  .on('mousemove', showTooltip_ch_outbreaks)
  .on('mouseout', mouseleave_ch_outbreak)

bars_weekly_outbreaks
  .data(chosen_ch_outbreak_df)
  .transition()
  .duration(1000)
  .attr("y", function(d) { return y_ch_outbreaks(+d.Outbreaks); })
  .attr("height", function(d) { return (height_line - 120 ) - y_ch_outbreaks(+d.Outbreaks); })
  .style("fill", function(d){ return Area_colours(chosen_ch_outbreak_area)})

bars_weekly_outbreaks
  .on('mousemove', showTooltip_ch_outbreaks)
  .on('mouseout', mouseleave_ch_outbreak)

}

update_ch_outbreaks()

d3.select("#select_carehome_outbreak_area_button").on("change", function(d) {
var chosen_ch_outbreak_area = d3.select('#select_carehome_outbreak_area_button').property("value")
  update_ch_outbreaks(chosen_ch_outbreak_area)
})

// Line graph one - actual cases - linear scale


var svg_cumulative_actual_linear = d3.select("#cumulative_ts_actual_linear")
  .append("svg")
  .attr("width", width_hm)
  .attr("height", height_line)
  .append("g")
  .attr("transform", "translate(" + 50 + "," + 20 + ")");


// We need to create a dropdown button for the user to choose which area to be displayed on the figure.
d3.select("#select_line_1_area_button")
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
var selected_line_1_area_option = d3.select('#select_line_1_area_button').property("value")

// Update text based on selected area
d3.select("#selected_line_1_compare_title")
  .html(function(d) {
    return 'Covid-19 cumulative cases over time; ' + selected_line_1_area_option
  });

var line_1_chosen = daily_cases.filter(function(d) {
  return d.Name === selected_line_1_area_option
});

var average_line_1_chosen = daily_cases.filter(function(d) {
    return d.Name === selected_line_1_area_option
  })
  .filter(function(d) {
    if (isNaN(d.Seven_day_average_cumulative_cases)) {
      return false;
    }
    return true;
  });

var new_n = line_1_chosen.filter(function(d) {
  return d.Date === most_recent;
})[0]['Cumulative_cases']

var x_c1 = d3.scaleLinear()
  .domain(d3.extent(line_1_chosen, function(d) {
    return d3.timeParse("%Y-%m-%d")(d.Date);
  }))
  .range([0, width_hm - 60]); // margin left (we pushed the start of the axis over by 50) + another 10 so things do not get cut off

var xAxis_line = svg_cumulative_actual_linear
  .append("g")
  .attr("transform", 'translate(0,' + (height_line - 120 ) + ")")
  .call(d3.axisBottom(x_c1).tickFormat(d3.timeFormat("%d-%B")).tickValues(line_1_chosen.map(function(d) {
    return d3.timeParse("%Y-%m-%d")(d.Date);
  })));

xAxis_line
  .selectAll("text")
  .attr("transform", 'translate(-10,10)rotate(-90)')
  .style("text-anchor", "end")
  .each(function(d,i) { // find the text in that tick and removing it: Thanks Gerardo Furtado on stackoverflow
    if (i%2 == 0) d3.select(this).remove();
    });

var y_c1_ts = d3.scaleLinear()
  .domain([0, d3.max(line_1_chosen, function(d) {
    return +d.Cumulative_cases;
  })])
  .range([height_line - 120 , 0]);

var y_c1_ts_axis = svg_cumulative_actual_linear
  .append("g")
  .attr("transform", 'translate(0,0)')
  .call(d3.axisLeft(y_c1_ts));

var tooltip_c1 = d3.select("#cumulative_ts_actual_linear")
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

var showTooltip_c1 = function(d) {

  tooltip_c1
    .html("<h5>" + d.Name + '</h5><p><b>' + d.Date_label + '</b></p><p class = "side">' + d.double_time_label_1 + '.</p><p class = "side">' + d.Seven_day_ave_cumulative_label + '. </p><p><i>Note: the rolling average has been rounded to the nearest whole number</i>.</p><p class = "side">' + d.double_time_label_2 + '</p>')
    .style("opacity", 1)
    .style("top", (event.pageY - 10) + "px")
    .style("left", (event.pageX + 10) + "px")
    .style('opacity', 1)
    .style("visibility", "visible")
}

var mouseleave_c1 = function(d) {
  tooltip_c1
    .style('opacity', 0)
    .style("visibility", "hidden")
}

svg_cumulative_actual_linear
  .append('line')
  .attr('x1', x_c1(d3.timeParse('%Y-%m-%d')(first_incomplete_date_actual)))
  .attr('y1', 0)
  .attr('x2', x_c1(d3.timeParse('%Y-%m-%d')(first_incomplete_date_actual)))
  .attr('y2', height_line - 120 )
  .attr('stroke', incomplete_colour)
  .attr("stroke-dasharray", ("3, 3"))

svg_cumulative_actual_linear
  .append('rect')
  .attr('x', x_c1(d3.timeParse('%Y-%m-%d')(first_incomplete_date_actual)))
  .attr('y1', 0)
  .attr('width', x_c1(d3.timeParse('%Y-%m-%d')(most_recent)) - x_c1(d3.timeParse('%Y-%m-%d')(first_incomplete_date_actual)))
  .attr('height', height_line - 120 )
  .style('fill', incomplete_colour)
  .style('stroke', 'none')
  .style('opacity', 0.2)

var lines_c1 = svg_cumulative_actual_linear
  .append("path")
  .datum(line_1_chosen)
  .attr("d", d3.line()
    .x(function(d) {
      return x_c1(d3.timeParse("%Y-%m-%d")(d.Date))
    })
    .y(function(d) {
      return y_c1_ts(d.Cumulative_cases)
    })
  )
  .style("fill", "none")
  .style("stroke-width", 1.5)
  .attr("stroke", '#646464')

var dots_c1 = svg_cumulative_actual_linear
  .selectAll('myCircles')
  .data(line_1_chosen)
  .enter()
  .append("circle")
  .attr("cx", function(d) {
    return x_c1(d3.timeParse("%Y-%m-%d")(d.Date))
  })
  .attr("cy", function(d) {
    return y_c1_ts(d.Cumulative_cases)
  })
  .attr("r", 3)
  .style("fill", function(d) {
    return Area_colours(d.Name)
  })
  .attr("stroke", function(d) {
    return Area_colours(d.Name)
  })
  .on("mousemove", showTooltip_c1)
  .on('mouseout', mouseleave_c1);

var lines_c1_seven_day_smooth = svg_cumulative_actual_linear
  .append("path")
  .datum(average_line_1_chosen)
  .attr("stroke", '#000000')
  .attr("stroke-width", 1)
  .attr("stroke-dasharray", ("3, 3"))
  .style("fill", "none")
  .attr("d", d3.line()
    .x(function(d) {
      return x_c1(d3.timeParse("%Y-%m-%d")(d.Date))
    })
    .y(function(d) {
      return y_c1_ts(d.Seven_day_average_cumulative_cases)
    })
  );

var dots_c1_seven_day_smooth = svg_cumulative_actual_linear
  .selectAll('myCircles')
  .data(average_line_1_chosen)
  .enter()
  .append("circle")
  .attr("cx", function(d) {
    return x_c1(d3.timeParse("%Y-%m-%d")(d.Date))
  })
  .attr("cy", function(d) {
    return y_c1_ts(d.Seven_day_average_cumulative_cases)
  })
  .attr("r", 3)
  .style("fill", function(d) {
    return '#c9c9c9'
  })
  .attr("stroke", "#000000")
  .on("mousemove", showTooltip_c1)
  .on('mouseout', mouseleave_c1);

var number_cumulative_cases_total = svg_cumulative_actual_linear
  .append("text")
  .attr("x", width_hm * .03)
  .attr("y", 40)
  .attr('id', 'number_within_2542')
  .attr("text-anchor", "start")
  .style('font-weight', 'bold')
  .style("font-size", "22px")

var i_change = d3.interpolate(0, new_n);

number_cumulative_cases_total
  .transition()
  .duration(1500)
  .tween("interventions", function() {
    return function(t) {
      current_n = i_change(t);
      number_cumulative_cases_total.text(d3.format(",.0f")(current_n));
    };
  });

svg_cumulative_actual_linear
  .append("text")
  .attr("x", width_hm * .03)
  .attr("y", 50)
  .text('cases confirmed so far')
  .attr("text-anchor", "start")

svg_cumulative_actual_linear
  .append("text")
  .attr('id', 'area_c1')
  .attr("x", width_hm * .03)
  .attr("y", 60)
  .text('in ' + selected_line_1_area_option)
  .attr("text-anchor", "start")

svg_cumulative_actual_linear
  .append("text")
  .attr('id', 'area_c1')
  .attr("x", x_c1(d3.timeParse('%Y-%m-%d')(complete_date_actual)))
  .attr("y", height_line - 135)
  .text('Incomplete data')
  .attr("text-anchor", "end")

svg_cumulative_actual_linear
  .append("text")
  .attr('id', 'area_c1')
  .attr("x", x_c1(d3.timeParse('%Y-%m-%d')(complete_date_actual)))
  .attr("y", height_line - 120)
  .text('' + first_incomplete_date.substring(4, first_incomplete_date.length) + '-' + latest_date.substring(4, latest_date.length))
  .attr("text-anchor", "end")

function update_cumulative_actual_linear() {

  var tooltip_c1 = d3.select("#cumulative_ts_actual_linear")
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

  var showTooltip_c1 = function(d) {
    tooltip_c1
      .html("<h5>" + d.Name + '</h5><p><b>' + d.Date_label + '</b></p><p class = "side">' + d.double_time_label_1 + '.</p><p class = "side">The cumulative total averaged over the last seven days (rounded) is ' + d3.format(',.0f')(d.Seven_day_average_cumulative_cases) + ' cases.<p class = "side">' + d.double_time_label_2 + '</p>')
      .style("opacity", 1)
      .style("top", (event.pageY - 10) + "px")
      .style("left", (event.pageX + 10) + "px")
      .style('opacity', 1)
      .style("visibility", "visible")
  }

  var mouseleave_c1 = function(d) {
    tooltip_c1
      .style('opacity', 0)
      .style("visibility", "hidden")
  }

  var selected_line_1_area_option = d3.select('#select_line_1_area_button').property("value")

  d3.select("#selected_line_1_compare_title")
    .html(function(d) {
      return 'Covid-19 cumulative cases over time; ' + selected_line_1_area_option
    });

  var old_n = line_1_chosen.filter(function(d) {
    return d.Date === most_recent;
  })[0]['Cumulative_cases']

  line_1_chosen = daily_cases.filter(function(d) {
    return d.Name === selected_line_1_area_option
  });

  var average_line_1_chosen = daily_cases.filter(function(d) {
      return d.Name === selected_line_1_area_option
    })
    .filter(function(d) {
      if (isNaN(d.Seven_day_average_cumulative_cases)) {
        return false;
      }
      return true;
    });

  var new_n = line_1_chosen.filter(function(d) {
    return d.Date === most_recent;
  })[0]['Cumulative_cases']

  y_c1_ts
    .domain([0, d3.max(line_1_chosen, function(d) {
      return +d.Cumulative_cases;
    })])

  // Redraw axis
  y_c1_ts_axis
    .transition()
    .duration(1000)
    .call(d3.axisLeft(y_c1_ts));

  lines_c1
    .datum(line_1_chosen)
    .transition()
    .delay(1000)
    .duration(1000)
    .attr("d", d3.line()
      .x(function(d) {
        return x_c1(d3.timeParse("%Y-%m-%d")(d.Date))
      })
      .y(function(d) {
        return y_c1_ts(d.Cumulative_cases)
      })
    )

  dots_c1
    .data(line_1_chosen)
    .transition()
    .delay(1000)
    .duration(1000)
    .attr("cx", function(d) {
      return x_c1(d3.timeParse("%Y-%m-%d")(d.Date))
    })
    .attr("cy", function(d) {
      return y_c1_ts(d.Cumulative_cases)
    })
    .style("fill", function(d) {
      return Area_colours(d.Name)
    })
    .style("stroke", function(d) {
      return Area_colours(d.Name)
    })

  lines_c1_seven_day_smooth
    .datum(average_line_1_chosen)
    .transition()
    .delay(1000)
    .duration(1000)
    .attr("d", d3.line()
      .x(function(d) {
        return x_c1(d3.timeParse("%Y-%m-%d")(d.Date))
      })
      .y(function(d) {
        return y_c1_ts(d.Seven_day_average_cumulative_cases)
      }));

  dots_c1_seven_day_smooth
    .data(average_line_1_chosen)
    .transition()
    .delay(1000)
    .duration(1000)
    .attr("cx", function(d) {
      return x_c1(d3.timeParse("%Y-%m-%d")(d.Date))
    })
    .attr("cy", function(d) {
      return y_c1_ts(d.Seven_day_average_cumulative_cases)
    })

  var i_change = d3.interpolate(current_n, new_n);

  number_cumulative_cases_total
    .transition()
    .duration(2500)
    .tween("interventions", function() {
      return function(t) {
        current_n = i_change(t);
        number_cumulative_cases_total.text(d3.format(",.0f")(current_n));
      };
    });

  svg_cumulative_actual_linear
    .selectAll("#area_c1")
    .remove();

  svg_cumulative_actual_linear
    .append("text")
    .attr('id', 'area_c1')
    .attr("x", width_hm * .03)
    .attr("y", 60)
    .text('in ' + selected_line_1_area_option)
    .attr("text-anchor", "start")

svg_cumulative_actual_linear
  .append("text")
  .attr('id', 'area_c1')
  .attr("x", x_c1(d3.timeParse('%Y-%m-%d')(complete_date_actual)))
  .attr("y", height_line - 135)
  .text('Incomplete data')
  .attr("text-anchor", "end")

svg_cumulative_actual_linear
  .append("text")
  .attr('id', 'area_c1')
  .attr("x", x_c1(d3.timeParse('%Y-%m-%d')(complete_date_actual)))
  .attr("y", height_line - 120)
  .text('' + first_incomplete_date.substring(4, first_incomplete_date.length) + '-' + latest_date.substring(4, latest_date.length))
  .attr("text-anchor", "end")
}

d3.select("#select_line_1_area_button").on("change", function(d) {
  var selected_line_1_area_option = d3.select('#select_line_1_area_button').property("value")
  update_cumulative_actual_linear()
})

// Line graph two - per 100,000 cases - linear scale
var svg_cumulative_rate_linear = d3.select("#cumulative_ts_per100000_linear")
  .append("svg")
  .attr("width", width_hm)
  .attr("height", height_line)
  .append("g")
  .attr("transform", "translate(" + 50 + "," + 20 + ")");

// We need to create a dropdown button for the user to choose which area to be displayed on the figure.
d3.select("#select_line_2_area_button")
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

// We need to create a dropdown button for the user to choose which area to be displayed on the figure.
d3.select("#select_line_2_comp_area_button")
  .selectAll('myOptions')
  .data(['England', 'Sussex areas combined', 'Brighton and Hove', 'East Sussex', 'West Sussex', 'Bracknell Forest', 'Buckinghamshire', 'Hampshire', 'Isle of Wight', 'Kent', 'Medway', 'Milton Keynes', 'Oxfordshire', 'Portsmouth', 'Reading', 'Slough', 'Southampton', 'Surrey', 'West Berkshire', 'Windsor and Maidenhead', 'Wokingham'])
  .enter()
  .append('option')
  .text(function(d) {
    return d;
  })
  .attr("value", function(d) {
    return d;
  })

var selected_line_2_area_option = d3.select('#select_line_2_area_button').property("value")
var selected_line_2_comp_area_option = d3.select('#select_line_2_comp_area_button').property("value")

// Update text based on selected area
d3.select("#selected_line_2_compare_title")
  .html(function(d) {
    return 'Covid-19 cumulative cases over time; rate per 100,000 population; ' + selected_line_2_area_option + ' compared to ' + selected_line_2_comp_area_option
  });

var line_2_chosen = daily_cases.filter(function(d) {
  return d.Name === selected_line_2_area_option
});

var line_2_comp_chosen = daily_cases.filter(function(d) {
  return d.Name === selected_line_2_comp_area_option
});

var tooltip_area_c2 = d3.select("#cumulative_ts_per100000_linear")
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

var tooltip_area_comp_c2 = d3.select("#cumulative_ts_per100000_linear")
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

  var showTooltip_area_c2 = function(d) {
    tooltip_area_c2
    .html("<h5>" + d.Name + '</h5><p><b>' + d.Date_label + '</b></p><p class = "side">' + d.double_time_label_1 + '.</p><p class = "side">' + d.double_time_label_2 + '</p>')
    .style("opacity", 1)
    .style("top", (event.pageY - 10) + "px")
    .style("left", (event.pageX + 10) + "px")
    .style("visibility", "visible")
  }

  var showTooltip_comp_area_c2 = function(d) {
    tooltip_area_comp_c2
    .html("<h5>" + d.Name + '</h5><p><b>' + d.Date_label + '</b></p><p class = "side">' + d.double_time_label_1 + '.</p><p class = "side">' + d.double_time_label_2 + '</p>')
    .style("opacity", 1)
    .style("top", (event.pageY - 10) + "px")
    .style("left", (event.pageX + 10) + "px")
    .style("visibility", "visible")
  }

  var mouseleave_c2 = function(d) {
  tooltip_area_c2
      .style("visibility", "hidden")

  tooltip_area_comp_c2
      .style("visibility", "hidden")
  }

var x_c2 = d3.scaleLinear()
  .domain(d3.extent(line_2_chosen, function(d) {
    return d3.timeParse("%Y-%m-%d")(d.Date);
  }))
  .range([0, width_hm - 60]); // this is the 50 that was pushed over from the left plus another 10 so that the chart does not get cut off

var xAxis_line_2 = svg_cumulative_rate_linear
  .append("g")
  .attr("transform", 'translate(0,' + (height_line - 120) + ")")
  .attr('class', 'ticked_off')
  .call(d3.axisBottom(x_c2).tickFormat(d3.timeFormat("%d-%B")).tickValues(line_2_chosen.map(function(d) {
    return d3.timeParse("%Y-%m-%d")(d.Date);
  })));

xAxis_line_2
  .selectAll("text")
  .attr("transform", 'translate(-10,10)rotate(-90)')
  .style("text-anchor", "end")
  .each(function(d,i) { // find the text in that tick and removing it: Thanks Gerardo Furtado on stackoverflow
    if (i%2 == 0) d3.select(this).remove();
    });

var y_c2_ts = d3.scaleLinear()
  .domain([0, d3.max([d3.max(line_2_chosen, function(d) {
    return +d.Cumulative_per_100000;
  }), d3.max(line_2_comp_chosen, function(d) {
    return +d.Cumulative_per_100000;
  })])])
  .range([height_line - 120 , 0])
  .nice();

var y_c2_ts_axis = svg_cumulative_rate_linear
  .append("g")
  .attr("transform", 'translate(0,0)')
  .call(d3.axisLeft(y_c2_ts));

svg_cumulative_rate_linear
  .append('line')
  .attr('x1', x_c2(d3.timeParse('%Y-%m-%d')(first_incomplete_date_actual)))
  .attr('y1', 0)
  .attr('x2', x_c2(d3.timeParse('%Y-%m-%d')(first_incomplete_date_actual)))
  .attr('y2', height_line - 120 )
  .attr('stroke', incomplete_colour)
  .attr("stroke-dasharray", ("3, 3"))

svg_cumulative_rate_linear
  .append('rect')
  .attr('x', x_c2(d3.timeParse('%Y-%m-%d')(first_incomplete_date_actual)))
  .attr('y1', 0)
  .attr('width', x_c2(d3.timeParse('%Y-%m-%d')(most_recent)) - x_c1(d3.timeParse('%Y-%m-%d')(first_incomplete_date_actual)))
  .attr('height', height_line - 120 )
  .style('fill', incomplete_colour)
  .style('stroke', 'none')
  .style('opacity', 0.2)

var lines_area_c2 = svg_cumulative_rate_linear
  .append("path")
  .datum(line_2_chosen)
  .attr("d", d3.line()
    .x(function(d) {
      return x_c2(d3.timeParse("%Y-%m-%d")(d.Date))
    })
    .y(function(d) {
      return y_c2_ts(d.Cumulative_per_100000)
    })
  )
  .style("fill", "none")
  .style("stroke-width", 1.5)
  .attr("stroke", '#5e106d')

var dots_area_c2 = svg_cumulative_rate_linear
  .selectAll('myCircles')
  .data(line_2_chosen)
  .enter()
  .append("circle")
  .attr("cx", function(d) {
    return x_c2(d3.timeParse("%Y-%m-%d")(d.Date))
  })
  .attr("cy", function(d) {
    return y_c2_ts(d.Cumulative_per_100000)
  })
  .attr("r", 3)
  .style("fill", '#5e106d')
  .attr("stroke", '#5e106d')
  .on("mousemove", showTooltip_area_c2)
  .on('mouseout', mouseleave_c2);

var lines_comp_area_c2 = svg_cumulative_rate_linear
  .append("path")
  .datum(line_2_comp_chosen)
  .attr("d", d3.line()
    .x(function(d) {
      return x_c2(d3.timeParse("%Y-%m-%d")(d.Date))
    })
    .y(function(d) {
      return y_c2_ts(d.Cumulative_per_100000)
    })
  )
  .style("fill", "none")
  .style("stroke-width", 1.5)
  .attr("stroke", '#f69602')

var dots_comp_area_c2 = svg_cumulative_rate_linear
  .selectAll('myCircles')
  .data(line_2_comp_chosen)
  .enter()
  .append("circle")
  .attr("cx", function(d) {
    return x_c2(d3.timeParse("%Y-%m-%d")(d.Date))
  })
  .attr("cy", function(d) {
    return y_c2_ts(d.Cumulative_per_100000)
  })
  .attr("r", 3)
  .style("fill", '#f69602')
  .attr("stroke", '#f69602')
  .on("mousemove", showTooltip_comp_area_c2)
  .on('mouseout', mouseleave_c2);

svg_cumulative_rate_linear
    .append("circle")
    .attr("cx", width_hm * .03)
    .attr("cy", 40)
    .attr("r", 3)
    .style("fill", '#5e106d')

svg_cumulative_rate_linear
    .append("circle")
    .attr("cx", width_hm * .03)
    .attr("cy", 55)
    .attr("r", 3) 
    .style("fill", '#f69602')

svg_cumulative_rate_linear
    .append("text")
    .attr('id', 'area_c2')
    .attr("x", width_hm * .03 + 10)
    .attr("y", 43)
    .text(selected_line_2_area_option)
    .attr("text-anchor", "start")

svg_cumulative_rate_linear
    .append("text")
    .attr('id', 'area_comp_c2')
    .attr("x", width_hm * .03 + 10)
    .attr("y", 58)
    .text(selected_line_2_comp_area_option)
    .attr("text-anchor", "start")

svg_cumulative_rate_linear
  .append("text")
  .attr('id', 'area_c1')
  .attr("x", x_c2(d3.timeParse('%Y-%m-%d')(complete_date_actual)))
  .attr("y", height_line - 135)
  .text('Incomplete data')
  .attr("text-anchor", "end")

svg_cumulative_rate_linear
  .append("text")
  .attr('id', 'area_c1')
  .attr("x", x_c2(d3.timeParse('%Y-%m-%d')(complete_date_actual)))
  .attr("y", height_line - 120)
  .text('' + first_incomplete_date.substring(4, first_incomplete_date.length) + '-' + latest_date.substring(4, latest_date.length))
  .attr("text-anchor", "end")

function update_cumulative_actual_rate_per_100000() {
  var selected_line_2_area_option = d3.select('#select_line_2_area_button').property("value")
  var selected_line_2_comp_area_option = d3.select('#select_line_2_comp_area_button').property("value")

  d3.select("#selected_line_2_compare_title")
    .html(function(d) {
      return 'Covid-19 cumulative cases over time; rate per 100,000 population; ' + selected_line_2_area_option + ' compared to ' + selected_line_2_comp_area_option
    });

  var line_2_chosen = daily_cases.filter(function(d) {
    return d.Name === selected_line_2_area_option
  });

  var line_2_comp_chosen = daily_cases.filter(function(d) {
    return d.Name === selected_line_2_comp_area_option
  });

  y_c2_ts
    .domain([0, d3.max([d3.max(line_2_chosen, function(d) {
      return +d.Cumulative_per_100000;
    }), d3.max(line_2_comp_chosen, function(d) {
      return +d.Cumulative_per_100000;
    })])])

  // Redraw axis
  y_c2_ts_axis
    .transition()
    .duration(1000)
    .call(d3.axisLeft(y_c2_ts));

  lines_area_c2
    .datum(line_2_chosen)
    .transition()
    .duration(1000)
    .attr("d", d3.line()
      .x(function(d) {
        return x_c2(d3.timeParse("%Y-%m-%d")(d.Date))
      })
      .y(function(d) {
        return y_c2_ts(d.Cumulative_per_100000)
      })
    )

  dots_area_c2
  .data(line_2_chosen)
  .transition()
  .duration(1000)
  .attr("cx", function(d) {
    return x_c2(d3.timeParse("%Y-%m-%d")(d.Date))
  })
  .attr("cy", function(d) {
    return y_c2_ts(d.Cumulative_per_100000)
  })

  lines_comp_area_c2
    .datum(line_2_comp_chosen)
    .transition()
    .duration(1000)
    .attr("d", d3.line()
      .x(function(d) {
        return x_c2(d3.timeParse("%Y-%m-%d")(d.Date))
      })
      .y(function(d) {
        return y_c2_ts(d.Cumulative_per_100000)
      })
    )

  dots_comp_area_c2
  .data(line_2_comp_chosen)
  .transition()
  .duration(1000)
  .attr("cx", function(d) {
    return x_c2(d3.timeParse("%Y-%m-%d")(d.Date))
  })
  .attr("cy", function(d) {
    return y_c2_ts(d.Cumulative_per_100000)
  })

svg_cumulative_rate_linear
    .selectAll("#area_c2")
    .remove();

svg_cumulative_rate_linear
    .selectAll("#area_comp_c2")
    .remove();

svg_cumulative_rate_linear
    .append("text")
    .attr('id', 'area_c2')
    .attr("x", width_hm * .03 + 10)
    .attr("y", 43)
    .text(selected_line_2_area_option)
    .attr("text-anchor", "start")

svg_cumulative_rate_linear
    .append("text")
    .attr('id', 'area_comp_c2')
    .attr("x", width_hm * .03 + 10)
    .attr("y", 58)
    .text(selected_line_2_comp_area_option)
    .attr("text-anchor", "start")

}

d3.select("#select_line_2_area_button").on("change", function(d) {
  var selected_line_2_area_option = d3.select('#select_line_2_area_button').property("value")
  var selected_line_2_comp_area_option = d3.select('#select_line_2_comp_area_button').property("value")
  update_cumulative_actual_rate_per_100000()
})

d3.select("#select_line_2_comp_area_button").on("change", function(d) {
  var selected_line_2_area_option = d3.select('#select_line_2_area_button').property("value")
  var selected_line_2_comp_area_option = d3.select('#select_line_2_comp_area_button').property("value")
  update_cumulative_actual_rate_per_100000()
})


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
  .call(d3.axisBottom(x_c3).ticks(max_days_case_x/2));

// Log scale for y axis - we will hopefully be able to toggle between log and linear for people to see the difference it makes.
var y_c3_ts = d3.scaleLog()
  .domain([1, d3.max(df_3, function(d) {return +d.Cumulative_cases;})])
  .range([height_line - 50, 0])
  .base(10)
  .nice();

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

var showTooltip_c3 = function(d, i) {

  tooltip_c3
    .html("<h5>" + d.values[(d.values.length)-1]['Name'] + '</h5><p class = "side">The current cumulative total for ' + d.values[(d.values.length)-1]['Name'] + ' as at ' + d.values[(d.values.length)-1]['Date_label'] + ' is <b>' +  d3.format(',.0f')(d.values[(d.values.length)-1]['Cumulative_cases']) + '</b>.</p><p class = "side">It has been<b> ' + d.values[(d.values.length)-1]['Days_since_case_x'] + ' days</b> since the number of confirmed cases exceeded 10 cases.</p><p class = "side">The latest doubling time calculation (based on data from ' + doubling_week_1_label + ') suggests that confirmed cases in ' + d.values[0]['Name'] + ' are doubling every ' +  d3.format(',.1f')(d.values[(d.values.length)-6]['Double_time']) + ' days.</p>')
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

update_highlight_c3()

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
var type_c3_scale = document.getElementsByName('toggle_c3_scale');
  if (type_c3_scale[0].checked) {

var y_c3_ts = d3.scaleLog()
  .domain([1, d3.max(df_3, function(d) {
    return +d.Cumulative_cases;
  })])
  .range([height_line - 50, 0])
  .base(10);

y_c3_ts_axis
.transition()
.duration(1000)
.call(d3.axisLeft(y_c3_ts).tickFormat(d3.format(',.0f')).tickValues([10,50,100,250, 500, 1000, 2500, 5000]));

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

  } else if (type_c3_scale[1].checked) {


y_c3_ts = d3.scaleLinear()
  .domain([0, d3.max(df_3, function(d) {
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

var type_c3_scale = document.getElementsByName('toggle_c3_scale');
  if (type_c3_scale[0].checked) {

if(width_hm < 1200) {
var defined_x = width_hm * .55
}
if(width_hm >= 1200) {
var defined_x = width_hm * .65
}
var defined_y = height_line - 180

  } else if (type_c3_scale[1].checked) {

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
  .attr("y", defined_y + 30)
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
  .attr("y", defined_y + 15)
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

// see why SE missing doubling time in R

d3.select("#select_line_3_area_button").on("change", function(d) {
var chosen_c3_highlight_area = d3.select('#select_line_3_area_button').property("value")
  toggle_scale_c3_func()
  update_highlight_c3()
  update_summary_c3()
})

// log or linear plus doubled cases;
//
// // We need to create a dropdown button for the user to choose which area to be displayed on the figure.
// d3.select("#select_line_4_area_button")
//   .selectAll('myOptions')
//   .data(areas_line)
//   .enter()
//   .append('option')
//   .text(function(d) {
//     return d;
//   })
//   .attr("value", function(d) {
//     return d;
//   })
//
// // Retrieve the selected area name
// var chosen_c4_area = d3.select('#select_line_4_area_button').property("value")
//
// var chosen_4_linear_log = daily_cases.filter(function(d) {
//   return d.Days_since_case_x >= 0 &&
//          d.Name === chosen_c4_area
// });
//
// var chosen_4_predicted_double = doubling_shown_df.filter(function(d) {
//   return d.Name === chosen_c4_area
// });
//
// var svg_cumulative_double_added = d3.select("#cumulative_log_double_time_added")
// .append("svg")
// .attr("width", width_hm)
// .attr("height", height_line)
// .append("g")
// .attr("transform", "translate(" + 50 + "," + 20 + ")");
//
// var c4_dates = chosen_4_linear_log.map(function(d) {return d3.timeParse("%Y-%m-%d")(d.Date);});
// c4_dates.push(d3.max(chosen_4_predicted_double, function(d) { return d3.timeParse("%Y-%m-%d")(d.Date);}))
//
// var x_c4 = d3.scaleLinear()
//   .domain([d3.min(c4_dates, function(d) { return d;}), d3.max(c4_dates, function(d) { return d;})])
//   .range([0, width_hm - 60]); // this is the 50 that was pushed over from the left plus another 10 so that the chart does not get cut off
//
// var xAxis_line_4 = svg_cumulative_double_added
//   .append("g")
//   .attr('id', 'old_c4_x_axis')
//   .attr("transform", 'translate(0,' + (height_line - 120 ) + ")")
//   .attr('class', 'ticked_off')
//   .call(d3.axisBottom(x_c4).tickFormat(d3.timeFormat("%d-%B")).tickValues(c4_dates));
//
// xAxis_line_4
//   .selectAll("text")
//   .attr("transform", 'translate(-10,10)rotate(-90)')
//   .style("text-anchor", "end")
//
// // Log scale for y axis - we will hopefully be able to toggle between log and linear for people to see the difference it makes.
// var y_c4_ts = d3.scaleLog()
//   .domain([1, d3.max(chosen_4_predicted_double, function(d) {return +d.Cumulative_cases;})])
//   .range([height_line - 120 , 0])
//   .base(10);
//
// // Append the y axis
// var y_c4_ts_axis = svg_cumulative_double_added
//   .append("g")
//   .attr("transform", 'translate(0,0)')
//   .call(d3.axisLeft(y_c4_ts).tickFormat(d3.format(',.0f')).tickValues([10, 50, 100, 200, 1000, 2000, 4000, 8000, 10000, 50000, 100000, 200000]));
//
// var actual_lines_c4 = svg_cumulative_double_added
//   .append("path")
//   .datum(chosen_4_linear_log)
//   .attr("stroke", function(d){ return Area_colours(chosen_c4_area) })
//   .style("fill", "none")
//   .style("stroke-width", 2)
//
// var dots_c4 = svg_cumulative_double_added
//   .selectAll('myCircles')
//   .data(chosen_4_linear_log)
//   .enter()
//   .append("circle")
//   .attr("r", 3)
//   .style("fill", function(d) {
//     return Area_colours(chosen_c4_area)
//   })
//   .attr("stroke", function(d) {
//     return Area_colours(chosen_c4_area)
//   })
//
// var double_lines_c4 = svg_cumulative_double_added
//   .append("path")
//   .datum(chosen_4_predicted_double)
//   .style("fill", "none")
//   .style("stroke-width", 2)
//   .style("stroke", '#000000')
//   .attr("stroke-dasharray", ("3, 3"))
//
// var double_dots_c4 = svg_cumulative_double_added
//   .selectAll('myCircles')
//   .data(chosen_4_predicted_double)
//   .enter()
//   .append("circle")
//   .attr("r", 3)
//   .style("fill", function(d) {
//     return '#c9c9c9'
//   })
//   .attr("stroke", "#000000")
//
// // Create a tooltip for the lines and functions for displaying the tooltips as well as highlighting certain lines.
// var tooltip_c4 = d3.select("#cumulative_log_double_time_added")
//   .append("div")
//   .style("opacity", 0)
//   .attr("class", "tooltip_class")
//   .style("position", "absolute")
//   .style("z-index", "10")
//   .style("background-color", "white")
//   .style("border", "solid")
//   .style("border-width", "1px")
//   .style("border-radius", "5px")
//   .style("padding", "10px")
//
// // Create a tooltip for the lines and functions for displaying the tooltips as well as highlighting certain lines.
// var tooltip_c4_doubled = d3.select("#cumulative_log_double_time_added")
//   .append("div")
//   .style("opacity", 0)
//   .attr("class", "tooltip_class")
//   .style("position", "absolute")
//   .style("z-index", "10")
//   .style("background-color", "white")
//   .style("border", "solid")
//   .style("border-width", "1px")
//   .style("border-radius", "5px")
//   .style("padding", "10px")
//
// var showTooltip_c4 = function(d, i) {
//
//   tooltip_c4
//     .html("<h5>" + d.Name + '</h5><p class = "side">'+ d.Period + '</p><p class = "side">' +d.Case_label + '</p><p class = "side">' + d.double_time_label_2 + '</p>' )
//     .style("opacity", 1)
//     .style("top", (event.pageY - 10) + "px")
//     .style("left", (event.pageX + 10) + "px")
//     .style("visibility", "visible");
//
// }
//
// var predict_label = d3.scaleOrdinal()
//   .domain(['Recorded', 'Predicted'])
//   .range(['This is the cumulative total on the last complete day of data (', 'This value is based on doubling the number of confirmed cases on the last complete day of data ('])
//
// var showTooltip_c4_doubled = function(d, i) {
//
//   tooltip_c4_doubled
//     .html("<h5>" + d.Name + '</h5><p class = "side">'+ d.Period + '</p><p class = "side"><b>' + d3.format(',.0f')(d.Cumulative_cases) + ' ' + d.Data_type.toLowerCase() + ' confirmed cases</b>.</p><p class = "side">' + predict_label(d.Data_type) + d.Period + ').</p>')
//     .style("opacity", 1)
//     .style("top", (event.pageY - 10) + "px")
//     .style("left", (event.pageX + 10) + "px")
//     .style("visibility", "visible");
//
// }
//
// var mouseleave_c4 = function(d) {
// tooltip_c4
//   .style("visibility", "hidden")
//
// tooltip_c4_doubled
//   .style("visibility", "hidden")
// }
//
// function update_c4_lines() {
//
// var chosen_c4_area = d3.select('#select_line_4_area_button').property("value")
//
// var chosen_4_linear_log = daily_cases.filter(function(d) {
//   return d.Days_since_case_x >= 0 &&
//          d.Name === chosen_c4_area
// });
//
// var chosen_4_predicted_double = doubling_shown_df.filter(function(d) {
//   return d.Name === chosen_c4_area
// });
//
// var c4_dates = chosen_4_linear_log.map(function(d) {return d3.timeParse("%Y-%m-%d")(d.Date);});
// c4_dates.push(d3.max(chosen_4_predicted_double, function(d) { return d3.timeParse("%Y-%m-%d")(d.Date);}))
//
// x_c4
//   .domain([d3.min(c4_dates, function(d) { return d;}), d3.max(c4_dates, function(d) { return d;})])
//
// xAxis_line_4
//   .transition()
//   .duration(1000)
//   .call(d3.axisBottom(x_c4).tickFormat(d3.timeFormat("%d-%B")).tickValues(c4_dates));
//
// xAxis_line_4
//   .selectAll("text")
//   .attr("transform", 'translate(-10,10)rotate(-90)')
//   .style("text-anchor", "end")
//
// var type_c4_scale = document.getElementsByName('toggle_c4_scale');
// if (type_c4_scale[0].checked) {
//
// // Log scale for y axis - we will hopefully be able to toggle between log and linear for people to see the difference it makes.
// var y_c4_ts = d3.scaleLog()
//   .domain([1, d3.max(chosen_4_predicted_double, function(d) {return +d.Cumulative_cases;})])
//   .range([height_line - 120 , 0])
//   .base(10);
// y_c4_ts_axis
// .transition()
// .duration(1000)
// .call(d3.axisLeft(y_c4_ts).tickFormat(d3.format(',.0f')));
//   } else if (type_c4_scale[1].checked) {
// y_c4_ts = d3.scaleLinear()
//   .domain([1, d3.max(chosen_4_predicted_double, function(d) {return +d.Cumulative_cases;})])
//   .range([height_line - 120 , 0]);
// y_c4_ts_axis
// .transition()
// .duration(1000)
// .call(d3.axisLeft(y_c4_ts).tickFormat(d3.format(',.0f')).tickValues([10, 50, 100, 200, 1000, 2000, 4000, 8000, 10000, 50000, 100000, 200000]));
// }
//
// actual_lines_c4
//   .datum(chosen_4_linear_log)
//   .transition()
//   .duration(1000)
//   .attr("d", d3.line()
//     .x(function(d) {
//       return x_c4(d3.timeParse("%Y-%m-%d")(d.Date))
//     })
//     .y(function(d) {
//       return y_c4_ts(d.Cumulative_cases)
//     })
//   )
//   .attr("stroke", function(d){ return Area_colours(chosen_c4_area) })
//
// dots_c4
//   .transition()
//   .attr("r", 0)
//
// dots_c4
//   .data(chosen_4_linear_log)
//   // .append("circle")
//   .transition()
//   .duration(1000)
//   .attr("cx", function(d) {
//     return x_c4(d3.timeParse("%Y-%m-%d")(d.Date))
//   })
//   .attr("cy", function(d) {
//     return y_c4_ts(d.Cumulative_cases)
//   })
//   .style("fill", function(d) {
//     return Area_colours(chosen_c4_area)
//   })
//   .attr("stroke", function(d) {
//     return Area_colours(chosen_c4_area)
//   })
//   .attr("r", 3)
//
// dots_c4
// .on('mousemove', showTooltip_c4)
// .on('mouseout', mouseleave_c4)
//
// double_lines_c4
//   .datum(chosen_4_predicted_double)
//   .transition()
//   .duration(1000)
//   .attr("d", d3.line()
//     .x(function(d) {
//       return x_c4(d3.timeParse("%Y-%m-%d")(d.Date))
//     })
//     .y(function(d) {
//       return y_c4_ts(d.Cumulative_cases)
//     })
//   )
//
// double_dots_c4
//   .data(chosen_4_predicted_double)
//   .transition()
//   .duration(1000)
//   .attr("cx", function(d) {
//     return x_c4(d3.timeParse("%Y-%m-%d")(d.Date))
//   })
//   .attr("cy", function(d) {
//     return y_c4_ts(d.Cumulative_cases)
//   })
//   .attr("r", 3)
//
// double_dots_c4
// .on('mousemove', showTooltip_c4_doubled)
// .on('mouseout', mouseleave_c4)
//
// update_summary_c4()
//
// }
//
// function toggle_scale_c4_func() {
//
// update_summary_c4()
//
// var type_c4_scale = document.getElementsByName('toggle_c4_scale');
// if (type_c4_scale[0].checked) {
//
// // Retrieve the selected area name
// var chosen_c4_area = d3.select('#select_line_4_area_button').property("value")
//
// var chosen_4_linear_log = daily_cases.filter(function(d) {
//   return d.Days_since_case_x >= 0 &&
//          d.Name === chosen_c4_area
// });
//
// var chosen_4_predicted_double = doubling_shown_df.filter(function(d) {
//   return d.Name === chosen_c4_area
// });
//
// d3.select("#selected_line_4_log_title")
//   .html(function(d) {
//     return 'Covid-19 cumulative cases over time including doubling time visualised; days since confirmed case 10; ' + chosen_c4_area + '; ' + 'loglinear' + ' scale'
// });
//
// // Log scale for y axis - we will hopefully be able to toggle between log and linear for people to see the difference it makes.
// var y_c4_ts = d3.scaleLog()
//   .domain([1, d3.max(chosen_4_predicted_double, function(d) {return +d.Cumulative_cases;})])
//   .range([height_line - 120 , 0])
//   .base(10);
//
// y_c4_ts_axis
// .transition()
// .duration(1000)
// .call(d3.axisLeft(y_c4_ts).tickFormat(d3.format(',.0f')).tickValues([10, 50, 100, 200, 1000, 2000, 4000, 8000, 10000, 50000, 100000, 200000]));
//
// actual_lines_c4
//   .datum(chosen_4_linear_log)
//   .transition()
//   .duration(1000)
//   .attr("d", d3.line()
//     .x(function(d) {
//       return x_c4(d3.timeParse("%Y-%m-%d")(d.Date))
//     })
//     .y(function(d) {
//       return y_c4_ts(d.Cumulative_cases)
//     })
//   )
//   .attr("stroke", function(d){ return Area_colours(chosen_c4_area) })
//
// dots_c4
//   .transition()
//   .attr("r", 0)
//
// dots_c4
//   .data(chosen_4_linear_log)
//   // .append("circle")
//   .transition()
//   .duration(1000)
//   .attr("cx", function(d) {
//     return x_c4(d3.timeParse("%Y-%m-%d")(d.Date))
//   })
//   .attr("cy", function(d) {
//     return y_c4_ts(d.Cumulative_cases)
//   })
//   .style("fill", function(d) {
//     return Area_colours(chosen_c4_area)
//   })
//   .attr("stroke", function(d) {
//     return Area_colours(chosen_c4_area)
//   })
//   .attr("r", 3)
//
// dots_c4
// .on('mousemove', showTooltip_c4)
// .on('mouseout', mouseleave_c4)
//
// double_lines_c4
//   .datum(chosen_4_predicted_double)
//   .transition()
//   .duration(1000)
//   .attr("d", d3.line()
//     .x(function(d) {
//       return x_c4(d3.timeParse("%Y-%m-%d")(d.Date))
//     })
//     .y(function(d) {
//       return y_c4_ts(d.Cumulative_cases)
//     })
//   )
//
// double_dots_c4
//   .data(chosen_4_predicted_double)
//   .transition()
//   .duration(1000)
//   .attr("cx", function(d) {
//     return x_c4(d3.timeParse("%Y-%m-%d")(d.Date))
//   })
//   .attr("cy", function(d) {
//     return y_c4_ts(d.Cumulative_cases)
//   })
//   .attr("r", 3)
//
// double_dots_c4
// .on('mousemove', showTooltip_c4_doubled)
// .on('mouseout', mouseleave_c4)
//
//
//   } else if (type_c4_scale[1].checked) {
//
// var chosen_c4_area = d3.select('#select_line_4_area_button').property("value")
//
// var chosen_4_linear_log = daily_cases.filter(function(d) {
//   return d.Days_since_case_x >= 0 &&
//          d.Name === chosen_c4_area
// });
//
// var chosen_4_predicted_double = doubling_shown_df.filter(function(d) {
//   return d.Name === chosen_c4_area
// });
//
// d3.select("#selected_line_4_log_title")
//   .html(function(d) {
//     return 'Covid-19 cumulative cases over time including doubling time visualised; days since confirmed case 10; ' + chosen_c4_area + '; ' + 'linear' + ' scale'
// });
//
// y_c4_ts = d3.scaleLinear()
//   .domain([1, d3.max(chosen_4_predicted_double, function(d) {return +d.Cumulative_cases;})])
//   .range([height_line - 120 , 0]);
//
// y_c4_ts_axis
// .transition()
// .duration(1000)
// .call(d3.axisLeft(y_c4_ts).tickFormat(d3.format(',.0f')));
//
// actual_lines_c4
//   .datum(chosen_4_linear_log)
//   .transition()
//   .duration(1000)
//   .attr("d", d3.line()
//     .x(function(d) {
//       return x_c4(d3.timeParse("%Y-%m-%d")(d.Date))
//     })
//     .y(function(d) {
//       return y_c4_ts(d.Cumulative_cases)
//     })
//   )
//   .attr("stroke", function(d){ return Area_colours(chosen_c4_area) })
//
// dots_c4
//   .transition()
//   .attr("r", 0)
//
// dots_c4
//   .data(chosen_4_linear_log)
//   // .append("circle")
//   .transition()
//   .duration(1000)
//   .attr("cx", function(d) {
//     return x_c4(d3.timeParse("%Y-%m-%d")(d.Date))
//   })
//   .attr("cy", function(d) {
//     return y_c4_ts(d.Cumulative_cases)
//   })
//   .style("fill", function(d) {
//     return Area_colours(chosen_c4_area)
//   })
//   .attr("stroke", function(d) {
//     return Area_colours(chosen_c4_area)
//   })
//   .attr("r", 3)
//
// dots_c4
// .on('mousemove', showTooltip_c4)
// .on('mouseout', mouseleave_c4)
//
// double_lines_c4
//   .datum(chosen_4_predicted_double)
//   .transition()
//   .duration(1000)
//   .attr("d", d3.line()
//     .x(function(d) {
//       return x_c4(d3.timeParse("%Y-%m-%d")(d.Date))
//     })
//     .y(function(d) {
//       return y_c4_ts(d.Cumulative_cases)
//     })
//   )
//
// double_dots_c4
//   .data(chosen_4_predicted_double)
//   .transition()
//   .duration(1000)
//   .attr("cx", function(d) {
//     return x_c4(d3.timeParse("%Y-%m-%d")(d.Date))
//   })
//   .attr("cy", function(d) {
//     return y_c4_ts(d.Cumulative_cases)
//   })
//   .attr("r", 3)
//
// double_dots_c4
// .on('mousemove', showTooltip_c4_doubled)
// .on('mouseout', mouseleave_c4)
//
// }
// };
//
// function update_summary_c4() {
//
// var chosen_c4_area = d3.select('#select_line_4_area_button').property("value")
//
// var chosen_4_linear_log = daily_cases.filter(function(d) {
//   return d.Days_since_case_x >= 0 &&
//          d.Name === chosen_c4_area
// });
//
// var chosen_4_predicted_double = doubling_shown_df.filter(function(d) {
//   return d.Name === chosen_c4_area
// });
//
// chosen_doubling_summary_c4 = double_df.filter(function(d){
//   return d.Name === chosen_c4_area &&
//          d.period_in_reverse === 1; })
//
// var type_c4_scale = document.getElementsByName('toggle_c4_scale');
//   if (type_c4_scale[0].checked) {
//
// var defined_x = width_hm * .6
// var defined_y = height_line - 200
// // Log scale for y axis - we will hopefully be able to toggle between log and linear for people to see the difference it makes.
// var y_c4_ts = d3.scaleLog()
//   .domain([1, d3.max(chosen_4_predicted_double, function(d) {return +d.Cumulative_cases;})])
//   .range([height_line - 120 , 0])
//   .base(10);
// y_c4_ts_axis
// .transition()
// .duration(1000)
// .call(d3.axisLeft(y_c4_ts).tickFormat(d3.format(',.0f')).tickValues([10, 50, 100, 200, 1000, 2000, 4000, 8000, 10000, 50000, 100000, 200000]));
//
//   } else if (type_c4_scale[1].checked) {
//
// var defined_x = width_hm * .05
// var defined_y = height_line - 300
// y_c4_ts = d3.scaleLinear()
//   .domain([1, d3.max(chosen_4_predicted_double, function(d) {return +d.Cumulative_cases;})])
//   .range([height_line - 120 , 0]);
// y_c4_ts_axis
// .transition()
// .duration(1000)
// .call(d3.axisLeft(y_c4_ts).tickFormat(d3.format(',.0f')));
// }
//
// svg_cumulative_double_added
//   .selectAll("#c4_area")
//   .transition()
//   .duration(100)
//   .remove();
// svg_cumulative_double_added
//   .selectAll("#c4_area_t2")
//   .transition()
//   .duration(100)
//   .remove();
// svg_cumulative_double_added
//   .selectAll("#c4_area_t3")
//   .transition()
//   .duration(100)
//   .remove();
// svg_cumulative_double_added
//   .selectAll("#c4_area_t4")
//   .transition()
//   .duration(100)
//   .remove();
// svg_cumulative_double_added
//   .selectAll("#c4_area_t5")
//   .transition()
//   .duration(100)
//   .remove();
// svg_cumulative_double_added
//   .selectAll("#c4_area_t6")
//   .transition()
//   .duration(100)
//   .remove();
// svg_cumulative_double_added
//   .selectAll("#c4_area_t7")
//   .transition()
//   .duration(100)
//   .remove();
//
// svg_cumulative_double_added
//   .append("text")
//   .attr('id', 'c4_area')
//   .attr("x", defined_x)
//   .attr("y", defined_y)
//   .text(chosen_c4_area)
//   .attr("text-anchor", "start")
//   .style('font-weight', 'bold')
//   .style("font-size", "12px")
//   .attr('opacity', 0)
//   .transition()
//   .duration(500)
//   .attr('opacity', 1)
//
// svg_cumulative_double_added
//   .append("text")
//   .attr('id', 'c4_area_t2')
//   .attr("x", defined_x)
//   .attr("y", defined_y + 15)
//   .text(d3.format(',.0f')(chosen_4_predicted_double.filter(function(d){ return d.Data_type === 'Recorded'})[0]['Cumulative_cases']) + ' confirmed cases as at '+ chosen_4_predicted_double.filter(function(d){ return d.Data_type === 'Recorded'})[0]['Period'] + " (latest 'complete' date)")
//   .attr("text-anchor", "start")
//   .attr('opacity', 0)
//   .transition()
//   .duration(500)
//   .attr('opacity', 1)
//
// svg_cumulative_double_added
//   .append("text")
//   .attr('id', 'c4_area_t3')
//   .attr("x", defined_x)
//   .attr("y", defined_y + 35)
//   .text('Based on data from ' + date_range_doubling[0]['long_date_label'].replace('and','to') +', confirmed')
//   .attr("text-anchor", "start")
//   .attr('opacity', 0)
//   .transition()
//   .duration(500)
//   .attr('opacity', 1)
//
// svg_cumulative_double_added
//   .append("text")
//   .attr('id', 'c4_area_t3')
//   .attr("x", defined_x)
//   .attr("y", defined_y + 50)
//   .text('cases were doubling every ' + d3.format(',.1f')(chosen_doubling_summary_c4[0].Double_time) +  ' days')
//   .attr("text-anchor", "start")
//   .attr('opacity', 0)
//   .transition()
//   .duration(500)
//   .attr('opacity', 1)
//
// svg_cumulative_double_added
//   .append("text")
//   .attr('id', 'c4_area_t4')
//   .attr("x", defined_x)
//   .attr("y", defined_y + 70)
//   .text('This means the number of confirmed cases')
//   .attr("text-anchor", "start")
//   .attr('opacity', 0)
//   .transition()
//   .duration(500)
//   .attr('opacity', 1)
//
// svg_cumulative_double_added
//   .append("text")
//   .attr('id', 'c4_area_t5')
//   .attr("x", defined_x)
//   .attr("y", defined_y + 85)
//   .text('could reach ' + d3.format(',.0f')(chosen_4_predicted_double.filter(function(d){ return d.Data_type === 'Predicted'})[0]['Cumulative_cases']) + ' (double) by ' + chosen_4_predicted_double.filter(function(d){ return d.Data_type === 'Predicted'})[0]['Period'])
//   .attr("text-anchor", "start")
//   .attr('opacity', 0)
//   .transition()
//   .duration(500)
//   .attr('opacity', 1)
//
// svg_cumulative_double_added
//   .append("text")
//   .attr('id', 'c4_area_t6')
//   .attr("x", x_c4(d3.timeParse("%Y-%m-%d")(chosen_4_predicted_double.filter(function(d){ return d.Data_type === 'Recorded'})[0]['Date'])))
//   .attr("y", y_c4_ts(chosen_4_predicted_double.filter(function(d){ return d.Data_type === 'Recorded'})[0]['Cumulative_cases']) + 25)
//   .text('Note that the last five data points')
//   .attr("text-anchor", "start")
//   .attr('opacity', 0)
//   .transition()
//   .duration(500)
//   .attr('opacity', 1)
//
// svg_cumulative_double_added
//   .append("text")
//   .attr('id', 'c4_area_t7')
//   .attr("x", x_c4(d3.timeParse("%Y-%m-%d")(chosen_4_predicted_double.filter(function(d){ return d.Data_type === 'Recorded'})[0]['Date'])))
//   .attr("y", y_c4_ts(chosen_4_predicted_double.filter(function(d){ return d.Data_type === 'Recorded'})[0]['Cumulative_cases']) + 40)
//   .text('are not included in the calculation.')
//   .attr("text-anchor", "start")
//   .attr('opacity', 0)
//   .transition()
//   .duration(500)
//   .attr('opacity', 1)
//
// }
//
// toggle_scale_c4_func()
// update_summary_c4()
//
// d3.select("#select_line_4_area_button").on("change", function(d) {
// var chosen_c4_area = d3.select('#select_line_4_area_button').property("value")
//   toggle_scale_c4_func()
//   update_summary_c4()
//   update_c4_lines()
// })

// Daily cases bar chart

// peaks
var request = new XMLHttpRequest();
request.open("GET", "./peak_average_SE.json", false);
request.send(null);
var peak_average = JSON.parse(request.responseText);

bh_peak_average = peak_average.filter(function(d){
  return d.Name == 'Brighton and Hove'
})

esx_peak_average = peak_average.filter(function(d){
  return d.Name == 'East Sussex'
})

wsx_peak_average = peak_average.filter(function(d){
  return d.Name == 'West Sussex'
})

d3.select("#sussex_peaks")
  .html(function(d) {
    return "A key feature of this figure is the ability to see roughly the dates at which different areas appear to have 'peaks' in new cases. For example, in Brighton and Hove, the first peak of average daily cases occured on " + bh_peak_average[0]['Period'] + ' with ' + d3.format(',.0f')(bh_peak_average[0]['Seven_day_average_new_cases']) + ' cases diagnosed each day on average in the last seven days. East Sussex had its highest rolling average number of cases (' + d3.format(',.0f')(esx_peak_average[0]['Seven_day_average_new_cases']) + ') on ' + esx_peak_average[0]['Period'] + ' and West Sussex peaked on ' + wsx_peak_average[0]['Period'] + ' with ' + d3.format(',.0f')(wsx_peak_average[0]['Seven_day_average_new_cases']) + ' cases on average each day in the previous seven days.'});

var svg_daily_new_case_bars = d3.select("#daily_new_case_bars")
.append("svg")
.attr("width", width_hm)
.attr("height", height_line)
.append("g")
.attr("transform", "translate(" + 50 + "," + 20 + ")");

// We need to create a dropdown button for the user to choose which area to be displayed on the figure.
d3.select("#select_bars_daily_cases_1_area_button")
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
var selected_line_5_area_option = d3.select('#select_bars_daily_cases_1_area_button').property("value")

// Update text based on selected area
d3.select("#selected_daily_cases_bars_1_compare_title")
  .html(function(d) {
    return 'Covid-19 new daily confirmed cases over time; ' + selected_line_5_area_option
  });

var bars_daily_cases_1_chosen = daily_cases.filter(function(d) {
  return d.Name === selected_line_5_area_option
});

var total_cases_daily_chosen = bars_daily_cases_1_chosen.filter(function(d){
  return d.Period === most_recent_period})[0]['Cumulative_cases']

var peak_daily_cases_1_chosen = peak_average.filter(function(d) {
  return d.Name === selected_line_5_area_option
});

var x_daily_cases = d3.scaleBand()
    .domain(bars_daily_cases_1_chosen.map(function(d) {
      return d.Period}))
    .range([0, width_hm - 60])

var xAxis_daily_cases = svg_daily_new_case_bars
  .append("g")
  .attr("transform", 'translate(0,' + (height_line - 120 ) + ")")
  .call(d3.axisBottom(x_daily_cases));

xAxis_daily_cases
  .selectAll("text")
  .attr("transform", 'translate(-' + x_daily_cases.bandwidth() + ',10)rotate(-90)')
  .style("text-anchor", "end")
  .each(function(d,i) { // find the text in that tick and remove it: Thanks Gerardo Furtado on stackoverflow
    if (i%2 == 0) d3.select(this).remove();
    });

var y_daily_cases = d3.scaleLinear()
  .domain([0, d3.max(bars_daily_cases_1_chosen, function(d) {
    return +d.New_cases;
  })])
  .range([height_line - 120 , 0])
.nice();

var yAxis_daily_cases = svg_daily_new_case_bars
.append("g")
.call(d3.axisLeft(y_daily_cases));

// testing policy timelines
var request = new XMLHttpRequest();
request.open("GET", "./uk_testing_key_dates.json", false);
request.send(null);
var uk_testing_key_dates = JSON.parse(request.responseText);

var tooltip_testing_key_dates = d3.select("#daily_new_case_bars")
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

var showTooltip_testing_key_dates = function(d) {
  tooltip_testing_key_dates
    .html("<h5>" + d.Period + '</h5><p>On this date it was announced that ' + d.Change + ' would now be included in the UK Covid-19 swab testing eligible population.</p>')
    .style("opacity", 1)
    .style("top", (event.pageY - 10) + "px")
    .style("left", (event.pageX + 10) + "px")
    .style('opacity', 1)
    .style("visibility", "visible")
}

var mouseleave_testing_key_dates = function(d) {
  tooltip_testing_key_dates
    .style('opacity', 0)
    .style("visibility", "hidden")
}

// We can treat this as a set of thin bars. With tooltips (maybe adding a dot or symbol at the top of each line as a easier thing to mouseover)
svg_daily_new_case_bars
.selectAll("testing_timeline")
.data(uk_testing_key_dates)
.enter()
.append("rect")
.attr("x", function(d) { return x_daily_cases(d.Period) + (x_daily_cases.bandwidth()/2)})
.attr("y", 0)
.attr("width", 2)
.attr("height", function(d) { return (height_line - 120 )})
.style("fill", incomplete_colour)
.on("mousemove", showTooltip_testing_key_dates)
.on('mouseout', mouseleave_testing_key_dates);

// We can treat this like a set of thin bars. With tooltips (maybe adding a dot or symbol at the top of each line as a easier thing to mouseover)
svg_daily_new_case_bars
.selectAll("testing_timeline")
.data(uk_testing_key_dates)
.enter()
.append("circle")
.attr("cx", function(d) { return x_daily_cases(d.Period) + (x_daily_cases.bandwidth()/2)})
.attr("y", 0)
.attr("r", 6)
.style("fill", incomplete_colour)
.on("mousemove", showTooltip_testing_key_dates)
.on('mouseout', mouseleave_testing_key_dates);

svg_daily_new_case_bars
  .append("text")
  .attr('id', 'test_milestones')
  .attr("x", function(d) { return x_daily_cases('26 March') + (x_daily_cases.bandwidth()/2)})
  .attr("y", 2)
  .text('Testing eligibility changes -')
  .attr("text-anchor", "end")

var tooltip_daily_case_1 = d3.select("#daily_new_case_bars")
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


var showTooltip_daily_case_1 = function(d) {
  tooltip_daily_case_1
    .html("<h5>" + d.Name + '</h5><p><b>' + d.Date_label + '</b></p><p class = "side">In ' + d.Name + ' there were <b>' + d3.format(',.0f')(d.New_cases) + ' </b>specimens taken on this date which resulted in a positive result for Covid-19.</p><p class = "side">The new cases swabbed on this day represent ' + d3.format('0.1%')(d.New_cases / total_cases_daily_chosen) + ' of the total number of cases confirmed so far (' + d3.format(',.0f')(total_cases_daily_chosen) + ') </p><p class = "side">' + d.Seven_day_ave_new_label + '</p>')
    .style("opacity", 1)
    .style("top", (event.pageY - 10) + "px")
    .style("left", (event.pageX + 10) + "px")
    .style('opacity', 1)
    .style("visibility", "visible")
}

var mouseleave_daily_case_1 = function(d) {
  tooltip_daily_case_1
    .style('opacity', 0)
    .style("visibility", "hidden")
}

svg_daily_new_case_bars
  .append('line')
  .attr('x1', x_daily_cases('23 March') + (x_daily_cases.bandwidth() / 2))
  .attr('y1', 30)
  .attr('x2', x_daily_cases('23 March') + (x_daily_cases.bandwidth() / 2))
  .attr('y2', height_line - 120 )
  .attr('stroke', 'red')
  .attr("stroke-dasharray", ("3, 3"))

svg_daily_new_case_bars
  .append("text")
  .attr("x", x_daily_cases('23 March'))
  .attr("y", 31)
  .text('lockdown starts -')
  .attr("text-anchor", "end")

svg_daily_new_case_bars
  .append('line')
  .attr('x1', x_daily_cases(first_incomplete_period))
  .attr('y1', 0)
  .attr('x2', x_daily_cases(first_incomplete_period))
  .attr('y2', height_line - 120 )
  .attr('stroke', incomplete_colour)
  .attr("stroke-dasharray", ("3, 3"))

svg_daily_new_case_bars
  .append('rect')
  .attr('x', x_daily_cases(first_incomplete_period))
  .attr('y1', 0)
  .attr('width', (x_daily_cases(most_recent_period) + x_daily_cases.bandwidth()) - x_daily_cases(first_incomplete_period))
  .attr('height', height_line - 120 )
  .style('fill', incomplete_colour)
  .style('stroke', 'none')
  .style('opacity', 0.2)

// daily case bars
var daily_new_case_bars = svg_daily_new_case_bars
.selectAll("mybar")
.data(bars_daily_cases_1_chosen)
.enter()
.append("rect")
.attr("x", function(d) { return x_daily_cases(d.Period)})
.attr("y", function(d) { return y_daily_cases(d.New_cases); })
.attr("width", x_daily_cases.bandwidth())
.attr("height", function(d) { return (height_line - 120 ) - y_daily_cases(d.New_cases); })
  .style("fill", function(d) {
    return Area_colours(d.Name)
  })
  .on("mousemove", showTooltip_daily_case_1)
  .on('mouseout', mouseleave_daily_case_1);

var svg_daily_average_case_bars = svg_daily_new_case_bars
.append("path")
.datum(bars_daily_cases_1_chosen)
.attr("fill", "none")
.attr("stroke", "#000000")
.attr("stroke-width", 2)
.attr("d", d3.line()
.defined(d => !isNaN(d.Seven_day_average_new_cases))
.x(function(d) { return x_daily_cases(d.Period) + (x_daily_cases.bandwidth() /2)})
.y(function(d) { return y_daily_cases(d.Seven_day_average_new_cases) }))

svg_daily_new_case_bars
  .append("text")
  .attr('id', 'test_milestones')
  .attr("x", function(d) { return x_daily_cases('31 January') + (x_daily_cases.bandwidth()/2)})
  .attr("y", function(d) { return height_line - 150 })
  .text('The black line represents seven day average new cases')
  .attr("text-anchor", "start")

svg_daily_new_case_bars
  .append("text")
  .attr("x", width_hm * .03 + 10)
  .attr("y", 40)
  .text('The peak new case rolling average')
  .attr("text-anchor", "start")

svg_daily_new_case_bars
  .append("text")
  .attr('id', 'area_peak_average_1')
  .attr("x", width_hm * .03 + 10)
  .attr("y", 53)
  .text('in ' + selected_line_5_area_option + ' was')
  .attr("text-anchor", "start")

svg_daily_new_case_bars
  .append("text")
  .attr('id', 'area_peak_average_2')
  .attr("x", width_hm * .03 + 10)
  .attr("y", 66)
  .text(d3.format(',.0f')(peak_daily_cases_1_chosen[0]['Seven_day_average_new_cases']) + ' cases on ' + peak_daily_cases_1_chosen[0]['Period'])
  .attr("text-anchor", "start")

function update_daily_bars() {

var selected_line_5_area_option = d3.select('#select_bars_daily_cases_1_area_button').property("value")

d3.select("#selected_daily_cases_bars_1_compare_title")
  .html(function(d) {
    return 'Covid-19 new daily confirmed cases over time; ' + selected_line_5_area_option
  });

var bars_daily_cases_1_chosen = daily_cases.filter(function(d) {
  return d.Name === selected_line_5_area_option
});

var total_cases_daily_chosen = bars_daily_cases_1_chosen.filter(function(d){
  return d.Period === most_recent_period})[0]['Cumulative_cases']

var peak_daily_cases_1_chosen = peak_average.filter(function(d) {
  return d.Name === selected_line_5_area_option
});

var showTooltip_daily_case_1 = function(d) {
  tooltip_daily_case_1
    .html("<h5>" + d.Name + '</h5><p><b>' + d.Date_label + '</b></p><p class = "side">In ' + d.Name + ' there were <b>' + d3.format(',.0f')(d.New_cases) + ' </b>specimens taken on this date which resulted in a positive result for Covid-19.</p><p class = "side">The new cases swabbed on this day represent ' + d3.format('0.1%')(d.New_cases / total_cases_daily_chosen) + ' of the total number of cases confirmed so far (' + d3.format(',.0f')(total_cases_daily_chosen) + ') </p><p class = "side">' + d.Seven_day_ave_new_label + '</p>')
    .style("opacity", 1)
    .style("top", (event.pageY - 10) + "px")
    .style("left", (event.pageX + 10) + "px")
    .style('opacity', 1)
    .style("visibility", "visible")
}

y_daily_cases
  .domain([0, d3.max(bars_daily_cases_1_chosen, function(d) {
    return +d.New_cases;
  })])

// Redraw axis
yAxis_daily_cases
  .transition()
  .duration(1000)
  .call(d3.axisLeft(y_daily_cases));

svg_daily_average_case_bars
  .datum(bars_daily_cases_1_chosen)
  .transition()
  .duration(1000)
  .attr("d", d3.line()
.defined(d => !isNaN(d.Seven_day_average_new_cases))
.x(function(d) { return x_daily_cases(d.Period) + (x_daily_cases.bandwidth() /2)})
.y(function(d) { return y_daily_cases(d.Seven_day_average_new_cases) }))


daily_new_case_bars
.data(bars_daily_cases_1_chosen)
.transition()
.duration(1000)
.attr("x", function(d) { return x_daily_cases(d.Period)})
.attr("y", function(d) { return y_daily_cases(d.New_cases); })
// .attr("width", x_daily_cases.bandwidth())
.attr("height", function(d) { return (height_line - 120 ) - y_daily_cases(d.New_cases); })
  .style("fill", function(d) {
    return Area_colours(d.Name)
  })

daily_new_case_bars
  .on("mousemove", showTooltip_daily_case_1)
  .on('mouseout', mouseleave_daily_case_1);

svg_daily_new_case_bars
  .selectAll("#area_peak_average_1")
  .remove();

svg_daily_new_case_bars
  .selectAll("#area_peak_average_2")
  .remove();

svg_daily_new_case_bars
  .append("text")
  .attr('id', 'area_peak_average_1')
  .attr("x", width_hm * .03 + 10)
  .attr("y", 53)
  .text('in ' + selected_line_5_area_option + ' was')
  .attr("text-anchor", "start")

svg_daily_new_case_bars
  .append("text")
  .attr('id', 'area_peak_average_2')
  .attr("x", width_hm * .03 + 10)
  .attr("y", 66)
  .text(d3.format(',.0f')(peak_daily_cases_1_chosen[0]['Seven_day_average_new_cases']) + ' cases on ' + peak_daily_cases_1_chosen[0]['Period'])
  .attr("text-anchor", "start")

}

d3.select("#select_bars_daily_cases_1_area_button").on("change", function(d) {
  var selected_line_5_area_option = d3.select('#select_bars_daily_cases_1_area_button').property("value")
  update_daily_bars()
})
