
var width_hm = 900
var height_hm = 25
var height_hm_title = 45

var request = new XMLHttpRequest();
    request.open("GET", "./se_case_summary.json", false);
    request.send(null);

var json_case_summary = JSON.parse(request.responseText); // parse the fetched json data into a variable

json_case_summary.sort(function(a, b) {
    return d3.descending(a['Total cases'], b['Total cases']);
    });

var request = new XMLHttpRequest();
    request.open("GET", "./se_daily_cases.json", false);
    request.send(null);

var json_daily_cases = JSON.parse(request.responseText); // parse the fetched json data into a variable

var latest_date = d3.max(json_daily_cases, function (d) {
  return d.Date;}).split('-');
latest_date = new Date(latest_date[0], latest_date[1] - 1, latest_date[2]);

var first_date = d3.min(json_daily_cases, function (d) {
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

var dates = d3.map(json_daily_cases, function(d){
return(d.Date)})
.keys()

d3.select("#data_recency")
    .html(function(d) {
        return 'The latest available data in this analysis are for <b>' + latest_date.toDateString().split(' ').slice(1).join(' ') +'</b>.'});

// Build X scale
var x = d3.scaleBand()
  .range([410, width_hm])
  .domain(dates)
  .padding(0.05);

order_areas = d3.map(json_case_summary, function(d){
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

// Create a function for tabulating the data
function new_case_daily_plot(area_x_chosen, svg_x) {

area_x = json_daily_cases.filter(function (d) { // gets a subset of the json data
    return d.Name === area_x_chosen
})

area_x_case_summary = json_case_summary.filter(function (d) { // gets a subset of the json data
    return d.Name === area_x_chosen
})

var svg = d3.select('#new_cases_plotted')
  .append('svg')
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
