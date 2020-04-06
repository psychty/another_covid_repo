
var width_hm = 900
var height_hm = 25
var height_hm_title = 45

var areas = ['Brighton and Hove', 'Bracknell Forest', 'Buckinghamshire', 'East Sussex', 'Hampshire', 'Isle of Wight', 'Kent', 'Medway', 'Milton Keynes', 'Oxfordshire', 'Portsmouth', 'Reading', 'Slough', 'Southampton', 'Surrey', 'West Berkshire', 'West Sussex', 'Windsor and Maidenhead', 'Wokingham']

var local_areas_compare = ['Brighton and Hove', 'East Sussex', 'West Sussex', 'Sussex areas combined', 'South East region', 'England']

var request = new XMLHttpRequest();
    request.open("GET", "./se_case_summary.json", false);
    request.send(null);
var case_summary = JSON.parse(request.responseText); // parse the fetched json data into a variable

var sussex_summary = case_summary.filter(function(d,i){ return local_areas_compare.indexOf(d.Name) >= 0 })
var se_summary = case_summary.filter(function(d,i){ return areas.indexOf(d.Name) >= 0 })

var request = new XMLHttpRequest();
    request.open("GET", "./se_daily_cases.json", false);
    request.send(null);

var daily_cases = JSON.parse(request.responseText); // parse the fetched json data into a variable

var latest_date = d3.max(daily_cases, function (d) {
  return d.Date;}).split('-');
latest_date = new Date(latest_date[0], latest_date[1] - 1, latest_date[2]);

var first_date = d3.min(daily_cases, function (d) {
  return d.Date;}).split('-');
first_date = new Date(first_date[0], first_date[1] - 1, first_date[2]);

var request = new XMLHttpRequest();
    request.open("GET", "./daily_cases_bands.json", false);
    request.send(null);

var new_cases_bands = JSON.parse(request.responseText); // parse the fetched json data into a variable
var new_cases_colours = ['#dcf3f5','#a6b4d8','#ffffb2','#fed976','#feb24c','#fd8d3c','#f03b20','#bd0026']
var color_new_cases = d3.scaleOrdinal()
.domain(new_cases_bands)
.range(new_cases_colours)

var request = new XMLHttpRequest();
    request.open("GET", "./daily_cases_per_100000_bands.json", false);
    request.send(null);

var new_cases_per_100000_bands = JSON.parse(request.responseText); // parse the fetched json data into a variable
var new_cases_colours = ['#dcf3f5','#a6b4d8','#ffffb2','#fed976','#feb24c','#fd8d3c','#f03b20','#bd0026']
var color_new_per_100000_cases = d3.scaleOrdinal()
.domain(new_cases_per_100000_bands)
.range(new_cases_colours)

var dates = d3.map(daily_cases, function(d){
return(d.Date)})
.keys()

d3.select("#data_recency")
    .html(function(d) {
        return 'Data collection started on 09 March 2020 and is usually updated at 6pm each day for the previous days figures. The latest available data in this analysis are for <b>' + latest_date.toDateString().split(' ').slice(1).join(' ') +'</b>.'});

var request = new XMLHttpRequest();
    request.open("GET", "./unconfirmed_latest.json", false);
    request.send(null);

var unconfirmed_latest = JSON.parse(request.responseText);

d3.select("#unconfirmed_cases_count")
   .data(unconfirmed_latest)
   .html(function(d) {
        return 'Counts are based on cases reported to PHE by diagnostic laboratories and details of the postcode of residence are matched to Office for National Statistics (ONS) administrative geography codes. As of ' + latest_date.toDateString().split(' ').slice(1).join(' ') + ', ' + d3.format(',.0f')(d.Unconfirmed) + ' cases ('+ d3.format('.0%')(d.Proportion_unconfirmed) +') of the ' + d3.format(',.0f')(d.England) + ' cases in England were not attributed to a local area. It is possible that some of these unconfirmed cases are from the areas analysed here.'});

var x = d3.scaleBand()
  .range([410, width_hm])
  .domain(dates)
  .padding(0.05);

order_areas = d3.map(se_summary, function(d){
return(d.Name)})
.keys()

var svg_title = d3.select('#new_case_headings')
.append('svg')
.attr('width', width_hm)
.attr('height', height_hm_title)
.append('g')

svg_title
.append("text")
.attr("x", 1)
.attr("y", 10)
.text('Area')
.attr("text-anchor", "start")
// .attr('fill', '#256cb2')
.style('font-weight', 'bold')
.style("font-size", "10px")

svg_title
.append("text")
.attr("x", 125)
.attr("y", 10)
.text('Total')
.attr("text-anchor", "start")
// .attr('fill', '#256cb2')
.style('font-weight', 'bold')
.style("font-size", "10px")

svg_title
.append("text")
.attr("x", 125)
.attr("y", 25)
.text('cases')
.attr("text-anchor", "start")
// .attr('fill', '#256cb2')
.style('font-weight', 'bold')
.style("font-size", "10px")

svg_title
.append("text")
.attr("x", 175)
.attr("y", 10)
.text('Total cases')
.attr("text-anchor", "start")
// .attr('fill', '#256cb2')
.style('font-weight', 'bold')
.style("font-size", "10px")

svg_title
.append("text")
.attr("x", 175)
.attr("y", 25)
.text('per 100,000')
.attr("text-anchor", "start")
// .attr('fill', '#256cb2')
.style('font-weight', 'bold')
.style("font-size", "10px")

svg_title
.append("text")
.attr("x", 175)
.attr("y", 40)
.text('population')
.attr("text-anchor", "start")
// .attr('fill', '#256cb2')
.style('font-weight', 'bold')
.style("font-size", "10px")

svg_title
.append("text")
.attr("x", 250)
.attr("y", 10)
.text('New cases')
.attr("text-anchor", "start")
// .attr('fill', '#256cb2')
.style('font-weight', 'bold')
.style("font-size", "10px")

svg_title
.append("text")
.attr("x", 250)
.attr("y", 25)
.text('in past')
.attr("text-anchor", "start")
// .attr('fill', '#256cb2')
.style('font-weight', 'bold')
.style("font-size", "10px")

svg_title
.append("text")
.attr("x", 250)
.attr("y", 40)
.text('24 hours')
.attr("text-anchor", "start")
// .attr('fill', '#256cb2')
.style('font-weight', 'bold')
.style("font-size", "10px")

svg_title
.append("text")
.attr("x", 320)
.attr("y", 10)
.text('New cases per')
.attr("text-anchor", "start")
// .attr('fill', '#256cb2')
.style('font-weight', 'bold')
.style("font-size", "10px")

svg_title
.append("text")
.attr("x", 320)
.attr("y", 25)
.text('100,000 in')
.attr("text-anchor", "start")
// .attr('fill', '#256cb2')
.style('font-weight', 'bold')
.style("font-size", "10px")

svg_title
.append("text")
.attr("x", 320)
.attr("y", 40)
.text('past 24 hours')
.attr("text-anchor", "start")
// .attr('fill', '#256cb2')
.style('font-weight', 'bold')
.style("font-size", "10px")

svg_title
.append("text")
.attr("x", 410)
.attr("y", 10)
.attr('id', 'what_am_i_showing_tiles')
.text('New cases by day')
.attr("text-anchor", "start")
// .attr('fill', '#256cb2')
.style('font-weight', 'bold')
.style("font-size", "10px")

svg_title
.append("text")
.attr("x", 410)
.attr("y", 40)
.text(first_date.toDateString().split(' ').slice(1).join(' '))
.attr("text-anchor", "start")
.style("font-size", "8px")

svg_title
.append("text")
.attr("x", width_hm)
.attr("y", 40)
.text(latest_date.toDateString().split(' ').slice(1).join(' '))
.attr("text-anchor", "end")
.style("font-size", "8px")

svg_title
.append('line')
  .attr('x1', 0)
  .attr('y1', 0)
  .attr('x2', width_hm)
  .attr('y2', 0)
  .attr('stroke', '#000000')

svg_title
.append('line')
  .attr('x1', 0)
  .attr('y1', height_hm_title)
  .attr('x2', width_hm)
  .attr('y2', height_hm_title)
  .attr('stroke', '#000000')

function counts_new_cases_tile_plot() {

// Create a function for tabulating the data
function new_case_daily_plot(area_x_chosen, svg_x) {

area_x = daily_cases.filter(function (d) { // gets a subset of the json data
    return d.Name === area_x_chosen
})

area_x_case_summary = case_summary.filter(function (d) { // gets a subset of the json data
    return d.Name === area_x_chosen
})

var svg = d3.select('#new_cases_plotted')
  .append('svg')
  .attr('id', 'catch_me_svg')
  .attr('width', width_hm)
  .attr('height', height_hm)
  .append('g')

var tooltip_new_case_day = d3.select("#new_cases_plotted")
.append("div")
.style("opacity", 0)
.attr("class", "tooltip_class")
.style("position", "absolute")
.style("z-index", "10")
.style("background-color", "white")
.style("border", "solid")
.style('font-size', '12px')
.style("border-width", "1px")
.style("border-radius", "5px")
.style("padding", "10px")

var mouseover = function(d) {
  d3.select(this)
    .style("stroke", "black")
    .style('stroke-width', '1px')
  }

var mousemove = function(d) {
tooltip_new_case_day
.html('<h4>' + d.Name + ' - ' + d.Period + '</h4><p>'+ d.label_1 + '</p><p>' +d.label_2 + '</p><p>' + d.label_3 + '</p>')
  .style("top", (event.pageY - 10) + "px")
  .style("left", (event.pageX + 10) + "px")
.style('opacity', 1)

}

var mouseleave = function(d) {
tooltip_new_case_day
.style("opacity", 0)

d3.select(this)
.style("stroke", "none")
}

svg
.append("text")
.attr("x", 1)
.attr("y", height_hm * .5)
.text(area_x_chosen)
.attr("text-anchor", "start")
.attr('font-weight', function(d) {
  if (area_x_chosen === 'West Sussex' || area_x_chosen == 'East Sussex' || area_x_chosen == 'Brighton and Hove') {
    return ('bold')}
    else {
    return ('normal')}})
.style("font-size", "10px")

svg
.append("text")
.attr("x", 125)
.attr("y", height_hm * .5)
.text(function(d) {
        return d3.format(",.0f")(area_x_case_summary[0]['Total cases'])})
.attr("text-anchor", "start")
.attr('font-weight', function(d) {
  if (area_x_chosen === 'West Sussex' || area_x_chosen == 'East Sussex' || area_x_chosen == 'Brighton and Hove') {
    return ('bold')}
    else {
    return ('normal')}})
.style("font-size", "10px")

svg
.append("text")
.attr("x", 175)
.attr("y", height_hm * .5)
.text(function(d) {
        return d3.format(",.0f")(area_x_case_summary[0]['Total cases per 100,000 population'])})
.attr("text-anchor", "start")
.attr('font-weight', function(d) {
  if (area_x_chosen === 'West Sussex' || area_x_chosen == 'East Sussex' || area_x_chosen == 'Brighton and Hove') {
    return ('bold')}
    else {
    return ('normal')}})
.style("font-size", "10px")

svg
.append("text")
.attr("x", 250)
.attr("y", height_hm * .5)
.text(function(d) {
        return d3.format(",.0f")(area_x_case_summary[0]['New cases in past 24 hours'])})
.attr("text-anchor", "start")
.attr('font-weight', function(d) {
  if (area_x_chosen === 'West Sussex' || area_x_chosen == 'East Sussex' || area_x_chosen == 'Brighton and Hove') {
    return ('bold')}
    else {
    return ('normal')}})
.style("font-size", "10px")

svg
.append("text")
.attr("x", 320)
.attr("y", height_hm * .5)
.text(function(d) {
        return d3.format(",.0f")(area_x_case_summary[0]['New cases per 100,000 population'])})
.attr("text-anchor", "start")
.attr('font-weight', function(d) {
  if (area_x_chosen === 'West Sussex' || area_x_chosen == 'East Sussex' || area_x_chosen == 'Brighton and Hove') {
    return ('bold')}
    else {
    return ('normal')}})
.style("font-size", "10px")

svg
.selectAll()
.data(area_x)
.enter()
.append("rect")
.attr("x", function(d) { return x(d.Date) })
.attr("rx", 4)
.attr("ry", 4)
.attr("width", x.bandwidth() )
.attr("height", height_hm - 4)
.style("fill", function(d) { return color_new_cases(d.new_case_key)} )
.style("stroke-width", 4)
.style("stroke", "none")
.style("opacity", 0.8)
 .on("mouseover", mouseover)
 .on("mousemove", mousemove)
 .on("mouseleave", mouseleave)

svg
.append('line')
  .attr('x1', 0)
  .attr('y1', height_hm)
  .attr('x2', width_hm)
  .attr('y2', height_hm)
  .attr('stroke', '#c9c9c9')

}

new_case_daily_plot(order_areas[0])
new_case_daily_plot(order_areas[1])
new_case_daily_plot(order_areas[2])
new_case_daily_plot(order_areas[3])
new_case_daily_plot(order_areas[4])
new_case_daily_plot(order_areas[5])
new_case_daily_plot(order_areas[6])
new_case_daily_plot(order_areas[7])
new_case_daily_plot(order_areas[8])
new_case_daily_plot(order_areas[9])
new_case_daily_plot(order_areas[10])
new_case_daily_plot(order_areas[11])
new_case_daily_plot(order_areas[12])
new_case_daily_plot(order_areas[13])
new_case_daily_plot(order_areas[14])
new_case_daily_plot(order_areas[15])
new_case_daily_plot(order_areas[16])
new_case_daily_plot(order_areas[17])
new_case_daily_plot(order_areas[18])

function key_1_new_cases() {
    new_cases_bands.forEach(function (item, index) {
        var list = document.createElement("li");
        list.innerHTML = item;
        list.className = 'key_list';
        list.style.borderColor = color_new_cases(index);
        var tt = document.createElement('div');
        tt.className = 'side_tt';
        tt.style.borderColor = color_new_cases(index);
        var tt_h3_1 = document.createElement('h3');
        tt_h3_1.innerHTML = item.Cause;

        tt.appendChild(tt_h3_1);
        var div = document.getElementById("new_case_key_figure");
        div.appendChild(list);
    })
}

key_1_new_cases();

}

function counts_new_cases_rates_tile_plot() {

function new_case_daily_plot(area_x_chosen, svg_x) {

area_x = daily_cases.filter(function (d) { // gets a subset of the json data
    return d.Name === area_x_chosen
})

area_x_case_summary = case_summary.filter(function (d) { // gets a subset of the json data
    return d.Name === area_x_chosen
})

var svg = d3.select('#new_cases_plotted')
  .append('svg')
  .attr('id', 'catch_me_svg')
  .attr('width', width_hm)
  .attr('height', height_hm)
  .append('g')

var tooltip_new_case_day = d3.select("#new_cases_plotted")
.append("div")
.style("opacity", 0)
.attr("class", "tooltip_class")
.style("position", "absolute")
.style("z-index", "10")
.style("background-color", "white")
.style("border", "solid")
.style('font-size', '12px')
.style("border-width", "1px")
.style("border-radius", "5px")
.style("padding", "10px")

var mouseover = function(d) {
  d3.select(this)
    .style("stroke", "black")
    .style('stroke-width', '1px')
  }

var mousemove = function(d) {
tooltip_new_case_day
.html('<h4>' + d.Name + ' - ' + d.Period + '</h4><p>'+ d.label_1 + '</p><p>' +d.label_2 + '</p><p>' + d.label_3 + '</p>')
  .style("top", (event.pageY - 10) + "px")
  .style("left", (event.pageX + 10) + "px")
.style('opacity', 1)

}

var mouseleave = function(d) {
tooltip_new_case_day
.style("opacity", 0)

d3.select(this)
.style("stroke", "none")
}

svg
.append("text")
.attr("x", 1)
.attr("y", height_hm * .5)
.text(area_x_chosen)
.attr("text-anchor", "start")
.attr('font-weight', function(d) {
  if (area_x_chosen === 'West Sussex' || area_x_chosen == 'East Sussex' || area_x_chosen == 'Brighton and Hove') {
    return ('bold')}
    else {
    return ('normal')}})
.style("font-size", "10px")

svg
.append("text")
.attr("x", 125)
.attr("y", height_hm * .5)
.text(function(d) {
        return d3.format(",.0f")(area_x_case_summary[0]['Total cases'])})
.attr("text-anchor", "start")
.attr('font-weight', function(d) {
  if (area_x_chosen === 'West Sussex' || area_x_chosen == 'East Sussex' || area_x_chosen == 'Brighton and Hove') {
    return ('bold')}
    else {
    return ('normal')}})
.style("font-size", "10px")

svg
.append("text")
.attr("x", 175)
.attr("y", height_hm * .5)
.text(function(d) {
        return d3.format(",.0f")(area_x_case_summary[0]['Total cases per 100,000 population'])})
.attr("text-anchor", "start")
.attr('font-weight', function(d) {
  if (area_x_chosen === 'West Sussex' || area_x_chosen == 'East Sussex' || area_x_chosen == 'Brighton and Hove') {
    return ('bold')}
    else {
    return ('normal')}})
.style("font-size", "10px")

svg
.append("text")
.attr("x", 250)
.attr("y", height_hm * .5)
.text(function(d) {
        return d3.format(",.0f")(area_x_case_summary[0]['New cases in past 24 hours'])})
.attr("text-anchor", "start")
.attr('font-weight', function(d) {
  if (area_x_chosen === 'West Sussex' || area_x_chosen == 'East Sussex' || area_x_chosen == 'Brighton and Hove') {
    return ('bold')}
    else {
    return ('normal')}})
.style("font-size", "10px")

svg
.append("text")
.attr("x", 320)
.attr("y", height_hm * .5)
.text(function(d) {
        return d3.format(",.0f")(area_x_case_summary[0]['New cases per 100,000 population'])})
.attr("text-anchor", "start")
.attr('font-weight', function(d) {
  if (area_x_chosen === 'West Sussex' || area_x_chosen == 'East Sussex' || area_x_chosen == 'Brighton and Hove') {
    return ('bold')}
    else {
    return ('normal')}})
.style("font-size", "10px")

svg
.selectAll()
.data(area_x)
.enter()
.append("rect")
.attr("x", function(d) { return x(d.Date) })
.attr("rx", 4)
.attr("ry", 4)
.attr("width", x.bandwidth() )
.attr("height", height_hm - 4)
.style("fill", function(d) { return color_new_per_100000_cases(d.new_case_per_100000_key)} )
.style("stroke-width", 4)
.style("stroke", "none")
.style("opacity", 0.8)
 .on("mouseover", mouseover)
 .on("mousemove", mousemove)
 .on("mouseleave", mouseleave)

svg
.append('line')
  .attr('x1', 0)
  .attr('y1', height_hm)
  .attr('x2', width_hm)
  .attr('y2', height_hm)
  .attr('stroke', '#c9c9c9')

}

new_case_daily_plot(order_areas[0])
new_case_daily_plot(order_areas[1])
new_case_daily_plot(order_areas[2])
new_case_daily_plot(order_areas[3])
new_case_daily_plot(order_areas[4])
new_case_daily_plot(order_areas[5])
new_case_daily_plot(order_areas[6])
new_case_daily_plot(order_areas[7])
new_case_daily_plot(order_areas[8])
new_case_daily_plot(order_areas[9])
new_case_daily_plot(order_areas[10])
new_case_daily_plot(order_areas[11])
new_case_daily_plot(order_areas[12])
new_case_daily_plot(order_areas[13])
new_case_daily_plot(order_areas[14])
new_case_daily_plot(order_areas[15])
new_case_daily_plot(order_areas[16])
new_case_daily_plot(order_areas[17])
new_case_daily_plot(order_areas[18])

function key_1_new_cases() {
    new_cases_per_100000_bands.forEach(function (item, index) {
        var list = document.createElement("li");
        list.innerHTML = item;
        list.className = 'key_list';
        list.style.borderColor = color_new_per_100000_cases(index);
        var tt = document.createElement('div');
        tt.className = 'side_tt';
        tt.style.borderColor = color_new_cases(index);
        var tt_h3_1 = document.createElement('h3');
        tt_h3_1.innerHTML = item.Cause;

        tt.appendChild(tt_h3_1);
        var div = document.getElementById("new_case_key_figure");
        div.appendChild(list);
    })
}

key_1_new_cases();

}

counts_new_cases_tile_plot()

function toggle_count_rate_func() {
var type = document.getElementsByName('toggle_count_rate');
if(type[0].checked){
console.log("We'll put the count version on for you")

$('.key_list').remove();

$('#catch_me_svg').remove();
$('#catch_me_svg').remove();
$('#catch_me_svg').remove();
$('#catch_me_svg').remove();
$('#catch_me_svg').remove();
$('#catch_me_svg').remove();
$('#catch_me_svg').remove();
$('#catch_me_svg').remove();
$('#catch_me_svg').remove();
$('#catch_me_svg').remove();
$('#catch_me_svg').remove();
$('#catch_me_svg').remove();
$('#catch_me_svg').remove();
$('#catch_me_svg').remove();
$('#catch_me_svg').remove();
$('#catch_me_svg').remove();
$('#catch_me_svg').remove();
$('#catch_me_svg').remove();
$('#catch_me_svg').remove();

counts_new_cases_tile_plot()

svg_title
.selectAll("#what_am_i_showing_tiles")
.remove();

svg_title
.append("text")
.attr("x", 410)
.attr("y", 10)
.attr('id', 'what_am_i_showing_tiles')
.text('New cases by day')
.attr("text-anchor", "start")
.style('font-weight', 'bold')
.style("font-size", "10px")

}
else if(type[1].checked)
{console.log("We'll put the rate version on for you")


$('.key_list').remove();

$('#catch_me_svg').remove();
$('#catch_me_svg').remove();
$('#catch_me_svg').remove();
$('#catch_me_svg').remove();
$('#catch_me_svg').remove();
$('#catch_me_svg').remove();
$('#catch_me_svg').remove();
$('#catch_me_svg').remove();
$('#catch_me_svg').remove();
$('#catch_me_svg').remove();
$('#catch_me_svg').remove();
$('#catch_me_svg').remove();
$('#catch_me_svg').remove();
$('#catch_me_svg').remove();
$('#catch_me_svg').remove();
$('#catch_me_svg').remove();
$('#catch_me_svg').remove();
$('#catch_me_svg').remove();
$('#catch_me_svg').remove();

counts_new_cases_rates_tile_plot()

svg_title
.selectAll("#what_am_i_showing_tiles")
.remove();

svg_title
.append("text")
.attr("x", 410)
.attr("y", 10)
.attr('id', 'what_am_i_showing_tiles')
.text('New cases per 100,000 population by day')
.attr("text-anchor", "start")
.style('font-weight', 'bold')
.style("font-size", "10px")
}
};

// Line graph one - actual cases - linear scale
// var height_line = 350;
//
// var svg_cumulative_actual_linear = d3.select("#cumulative_ts_actual_linear")
// .append("svg")
// .attr("width", width_hm)
// .attr("height", height_line)
// .append("g")
// .attr("transform", "translate(" + 30 + "," + 30 + ")");
//
// var estimate_key = d3.scaleOrdinal()
//   .domain(['Mid year estimate', 'Projection'])
//   .range(['#460061', '#966fa6'])
//
// var estimate_key_eng = d3.scaleOrdinal()
//   .domain(['Mid year estimate', 'Projection'])
//   .range(['#666666', '#9f9f9f'])
//
// // List of years in the dataset
// var areas_line = ['Brighton and Hove', 'East Sussex', 'West Sussex', 'Sussex areas combined', 'England', 'Bracknell Forest', 'Buckinghamshire', 'Hampshire', 'Isle of Wight', 'Kent', 'Medway', 'Milton Keynes', 'Oxfordshire', 'Portsmouth', 'Reading', 'Slough', 'Southampton', 'Surrey', 'West Berkshire','Windsor and Maidenhead', 'Wokingham']
//
// // We need to create a dropdown button for the user to choose which area to be displayed on the figure.
// d3.select("#select_line_1_area_button")
//   .selectAll('myOptions')
//   .data(areas_line)
//   .enter()
//   .append('option')
//   .text(function (d) {
//         return d; }) // text to appear in the menu - this does not have to be as it is in the data (you can concatenate other values).
//   .attr("value", function (d) {
//         return d; }) // corresponding value returned by the button
//
// var x_line = d3.scaleLinear()
// .domain(dates)
// .range([0, width_hm - 60]);
//
// var xAxis_line = svg_cumulative_actual_linear
// .append("g")
// .attr("transform", "translate(0," + 290 + ")")
//
// xAxis_line
// .call(d3.axisBottom(x_line))
//
// xAxis_line
// .selectAll("text")
// .attr("transform", "rotate(-45)")
// .style("text-anchor", "end")
//
// function update_cumulative_actual_linear(){
//
// var selected_line_1_area_option = d3.select('#select_line_1_area_button').property("value")
//
// d3.select("#selected_line_1_compare_title")
//    .html(function(d) {
//         return 'Covid-19 cumulative cases over time; ' + selected_line_1_area_option});
//
// line_1_chosen = daily_cases.filter(function (d) { // gets a subset of the json data - This time it excludes SE and England values
//     return d.Name === selected_line_1_area_option
// });


//
// var maxOADR = Math.max(
//   d3.max(json_oadr, function(d) { return d.OADR + 50; })
// );
//
// // Add Y axis
// var y_oadr = d3.scaleLinear()
// .domain([0, 750]) // Add the ceiling
// .range([290, 0]);
//
// var yAxis_oadr = svg_oadr
// .append("g")
// .call(d3.axisLeft(y_oadr).ticks(20));
//
// var tooltip_oadr = d3.select("#oadr_ts_viz")
//     .append("div")
//     .style("opacity", 0)
//     .attr("class", "tooltip_pyramid_bars")
//     .style("position", "absolute")
//     .style("z-index", "10")
//     .style("background-color", "white")
//     .style("border", "solid")
//     .style("border-width", "1px")
//     .style("border-radius", "5px")
//     .style("padding", "10px")
//
// var showTooltip_OADR = function(d) {
//
// tooltip_oadr
//   .html("<h3>" + d.Area + ' - ' + d.Year + '</h3><p class = "side"><font color = "#1e4b7a"><b>' + d3.format(',.0f')(d.OADR) + '</font></b> state pension age population per 1,000 working age population.</p><p class = "side"><font color = "#1e4b7a"><b>' + d3.format(',.0f')(d.Number_SPA) + '</font></b> estimated state pension age population</p><p class = "side"><font color = "#1e4b7a"><b>'  +  d3.format(',.0f')(d.Number_Workers) + '</font></b> estimated working age (16-SPA) population.</p>')
//   .style("opacity", 1)
//   .style("top", (event.pageY - 10) + "px")
//   .style("left", (event.pageX + 10) + "px")
//   .style("visibility", "visible")
//         }
//
// var mouseleave_oadr = function(d) {
//
// tooltip_oadr
// .style("visibility", "hidden")
//     }
//
// var lines_oadr = svg_oadr
//     .append('g')
//     .append("path")
//     .datum(json_oadr.filter(function (d) {
//         return d.Area === selected_oadr_area_option
//     }))
//     .attr("d", d3.line()
//         .x(function (d) {
//             return x_oadr(d.Year)
//         })
//         .y(function (d) {
//             return y_oadr(+d.OADR)
//         }))
//     .attr("stroke", function (d) {
//         return estimate_key(d.Estimate)
//     })
//     .style("stroke-width", 2)
//     .style("fill", "none");
//
// var dots_oadr = svg_oadr
//   .selectAll('myCircles')
//   .data(json_oadr.filter(function (d) {
//       return d.Area === selected_oadr_area_option
//     }))
//   .enter()
//   .append("circle")
//   .attr("cx", function(d) { return x_oadr(d.Year) } )
//   .attr("cy", function(d) { return y_oadr(+d.OADR) } )
//   .attr("r", 6)
//   .style("fill", function(d){ return estimate_key(d.Estimate)})
//   .attr("stroke", "white")
//   .on("mousemove", showTooltip_OADR)
//   .on('mouseout', mouseleave_oadr);
//
//   var lines_oadr_eng = svg_oadr
//       .append('g')
//       .append("path")
//       .datum(json_oadr.filter(function (d) {
//           return d.Area === 'England'
//       }))
//       .attr("d", d3.line()
//           .x(function (d) {
//               return x_oadr(d.Year)
//           })
//           .y(function (d) {
//               return y_oadr(+d.OADR)
//           }))
//       .attr("stroke", '#dbdbdb')
//       .style("stroke-width", 2)
//       .style("fill", "none");
//
//       var dots_oadr_eng = svg_oadr
//         .selectAll('myCircles')
//         .data(json_oadr.filter(function (d) {
//             return d.Area === 'England'
//           }))
//         .enter()
//         .append("circle")
//         .attr("cx", function(d) { return x_oadr(d.Year) } )
//         .attr("cy", function(d) { return y_oadr(+d.OADR) } )
//         .attr("r", 6)
//         .style("fill", function(d){ return estimate_key_eng(d.Estimate)})
//         .attr("stroke", "white")
//         .on("mousemove", showTooltip_OADR)
//         .on('mouseout', mouseleave_oadr);
//
// eng_41 = json_oadr.filter(function (d) {
//         return d.Area === 'England' &
//                d.Year === 2041})
//
// svg_oadr
// .append("text")
// .attr("text-anchor", "start")
// .attr("y", y_oadr(65))
// .attr("x", x_oadr('2011'))
// .attr('opacity', 1)
// .attr('class', 'pop_65_text')
// .text('Data for 2010 to 2018');
//
// svg_oadr
// .append("text")
// .attr("text-anchor", "start")
// .attr("y", y_oadr(40))
// .attr("x", x_oadr('2011'))
// .attr('opacity', 1)
// .attr('class', 'pop_65_text')
// .text('are based on ONS estimates.');
//
// svg_oadr
// .append("text")
// .attr("text-anchor", "end")
// .attr("y", y_oadr(eng_41[0]['OADR'] - 65))
// .attr("x", x_oadr('2041'))
// .attr('opacity', 1)
// .text('England');
//
// chosen_41 = json_oadr.filter(function (d) {
//         return d.Area === selected_oadr_area_option &
//                d.Year === 2041})
//
// svg_oadr
// .append("text")
// .attr("text-anchor", "end")
// .attr('id', 'area_x_oadr_label')
// .attr("y", y_oadr(chosen_41[0]['OADR'] + 50))
// .attr("x", x_oadr('2041'))
// .attr('opacity', 1)
// .text(selected_oadr_area_option);
//
// function update_oadr(selected_oadr_area_option) {
//
// svg_oadr
// .selectAll("#area_x_oadr_label")
// .transition()
// .duration(750)
// .attr('opacity', 0)
// .remove();
//
//
// var selected_oadr_area_option = d3.select('#select_oadr_area_button').property("value")
//
// oadr_chosen = json_oadr.filter(function (d) {
//     return d.Area === selected_oadr_area_option
// })
//     .sort(function (a, b) {
//         return d3.ascending(a.Year, b.Year);
//     });
//
// lines_oadr
// .datum(oadr_chosen)
// .transition()
// .duration(1000)
// .attr("d", d3.line()
// .x(function (d) {
//   return x_oadr(d.Year)
//   })
// .y(function (d) {
//   return y_oadr(+d.OADR)
//   }))
// .attr("stroke", function (d) {
//   return estimate_key(d.Estimate)
//   })
//
// dots_oadr
// .data(oadr_chosen)
// .transition()
// .duration(1000)
// .attr("cx", function(d) { return x_oadr(d.Year) } )
// .attr("cy", function(d) { return y_oadr(+d.OADR) } )
// .attr("r", 6)
// .style("fill", function(d){ return estimate_key(d.Estimate)})
// .attr("stroke", "white")
//
// chosen_41 = json_oadr.filter(function (d) {
//         return d.Area === selected_oadr_area_option &
//                d.Year === 2041})
//
// setTimeout(function(){
// svg_oadr
// .append("text")
// .attr("text-anchor", "end")
// .attr('id', 'area_x_oadr_label')
// .attr("y", function(d) {
//   if (chosen_41[0]['OADR'] < eng_41[0]['OADR']) {
//     return y_oadr(chosen_41[0]['OADR'] - 65) }
//     else {
//     return y_oadr(chosen_41[0]['OADR'] + 50) }
//           })
// .attr("x", x_oadr('2041'))
// .attr('opacity', 0)
// .transition()
// .duration(1000)
// .attr('opacity', 1)
// .text(selected_oadr_area_option);
// }, 500);
//
// }
//
//
// }
//
// update_cumulative_actual_linear()
//
//
// d3.select("#select_line_1_area_button").on("change", function (d) {
// var selected_line_1_area_option = d3.select('#select_line_1_area_button').property("value")
//     update_cumulative_actual_linear()
// })
//
// // Line graph two - per 100,000 cases - linear scale
//
// var svg_cumulative_actual_linear = d3.select("#cumulative_ts_per100000_linear")
// .append("svg")
// .attr("width", width_hm)
// .attr("height", height_line)
// .append("g")
// .attr("transform", "translate(" + 30 + "," + 30 + ")");
//
// // Log scale - doubling time
//
// var svg_cumulative_actual_linear = d3.select("#cumulative_log")
// .append("svg")
// .attr("width", width_hm)
// .attr("height", height_line)
// .append("g")
// .attr("transform", "translate(" + 30 + "," + 30 + ")");
