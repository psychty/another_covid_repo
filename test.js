
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

var x_ch_outbreaks = d3.scaleBand()
  .domain(weeks_outbreak_ch)
  .range([0, width_hm - 60]) // this is the 50 that was pushed over from the left plus another 10 so that the chart does not get cut off
  .padding([0.2]);

var xAxis_ch_outbreaks = svg_carehome_outbreak_number
  .append("g")
  .attr("transform", 'translate(0,' + (height_line - 90) + ")")
  .call(d3.axisBottom(x_ch_outbreaks).tickSizeOuter(0));

xAxis_ch_outbreaks
  .selectAll("text")
  .attr("transform", 'translate(-12,10)rotate(-90)')
  .style("text-anchor", "end");

var y_ch_outbreaks = d3.scaleLinear()
  .domain([0, +ch_number_in_area])
  .range([height_line - 90, 0])
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

var lines_outbreaks = svg_carehome_outbreak_number
    .append('g')
    .append("path")
    .datum(chosen_ch_outbreak_df)
    .attr("d", d3.line()
        .x(function (d) {
            return x_ch_outbreaks(d.Week_beginning)
        })
        .y(function (d) {
            return y_ch_outbreaks(+d.Cumulative_outbreaks)
        }))
    .attr("stroke", function (d) {
        return Area_colours(chosen_ch_outbreak_area)
    })
    .style("stroke-width", 2)
    .style("fill", "none");

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
          return x_ch_outbreaks(d.Week_beginning)
        })
    .y(function (d) {
          return y_ch_outbreaks(+d.Cumulative_outbreaks)
        }))
.attr("stroke", function (d) {
        return Area_colours(chosen_ch_outbreak_area)
    })


}

update_ch_outbreaks()

d3.select("#select_carehome_outbreak_area_button").on("change", function(d) {
var chosen_ch_outbreak_area = d3.select('#select_carehome_outbreak_area_button').property("value")
  update_ch_outbreaks(chosen_ch_outbreak_area)
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
