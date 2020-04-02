
var width_hm = 800
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

var color_new_cases = d3.scaleOrdinal()
.domain(['Starting cases', 'Data revised down', 'No new cases', '1-5', '6-10', '11-15', '16-20', 'Above 20'])
.range(['#dcf3f5','#a6b4d8','#ffffb2','#fed976','#feb24c','#fd8d3c','#f03b20','#bd0026'])

var dates = d3.map(json_daily_cases, function(d){
return(d.Date)})
.keys()

d3.select("#data_recency")
    .html(function(d) {
        return 'The latest available data in this analysis is for <b>' + latest_date.toDateString() +'</b>.'});

// Create a function for tabulating the data
function tabulate_case_summary(data, columns) {
var table = d3.select('#case_summary_table')
    .append('table')
    .attr('class', 'case_summary')
var thead = table
    .append('thead')
var tbody = table
    .append('tbody');

// append the header row
thead
.append('tr')
.selectAll('th')
.data(columns).enter()
.append('th')
.text(function (column) {
      return column;
          });

// create a row for each object in the data
var rows = tbody.selectAll('tr')
  .data(data)
  .enter()
  .append('tr');

// create a cell in each row for each column
var cells = rows.selectAll('td')
  .data(function (row) {
    return columns.map(function (column) {
    return {column: column, value: row[column]};
      });
      })
  .enter()
  .append('td')
  .text(function(d,i) {
    if(i >= 1) return d3.format(",.0f")(d.value);
               return d.value; })
    return table;
    }

// tabulate_case_summary(json_case_summary, ['Name', "Total cases", "Total cases per 100,000 population", "New cases in past 24 hours", "New cases per 100,000 population"]);

// Build X scales and axis:
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
.attr('fill', '#256cb2')
.style('font-weight', 'bold')
.style("font-size", "10px")

svg_title
.append("text")
.attr("x", 125)
.attr("y", 10)
.text('Total')
.attr("text-anchor", "start")
.attr('fill', '#256cb2')
.style('font-weight', 'bold')
.style("font-size", "10px")

svg_title
.append("text")
.attr("x", 125)
.attr("y", 25)
.text('cases')
.attr("text-anchor", "start")
.attr('fill', '#256cb2')
.style('font-weight', 'bold')
.style("font-size", "10px")

svg_title
.append("text")
.attr("x", 175)
.attr("y", 10)
.text('Total cases')
.attr("text-anchor", "start")
.attr('fill', '#256cb2')
.style('font-weight', 'bold')
.style("font-size", "10px")

svg_title
.append("text")
.attr("x", 175)
.attr("y", 25)
.text('per 100,000')
.attr("text-anchor", "start")
.attr('fill', '#256cb2')
.style('font-weight', 'bold')
.style("font-size", "10px")

svg_title
.append("text")
.attr("x", 175)
.attr("y", 40)
.text('population')
.attr("text-anchor", "start")
.attr('fill', '#256cb2')
.style('font-weight', 'bold')
.style("font-size", "10px")

svg_title
.append("text")
.attr("x", 250)
.attr("y", 10)
.text('New cases in')
.attr("text-anchor", "start")
.attr('fill', '#256cb2')
.style('font-weight', 'bold')
.style("font-size", "10px")

svg_title
.append("text")
.attr("x", 250)
.attr("y", 25)
.text('past 24 hours')
.attr("text-anchor", "start")
.attr('fill', '#256cb2')
.style('font-weight', 'bold')
.style("font-size", "10px")

svg_title
.append("text")
.attr("x", 320)
.attr("y", 10)
.text('New cases per')
.attr("text-anchor", "start")
.attr('fill', '#256cb2')
.style('font-weight', 'bold')
.style("font-size", "10px")

svg_title
.append("text")
.attr("x", 320)
.attr("y", 25)
.text('100,000 in')
.attr("text-anchor", "start")
.attr('fill', '#256cb2')
.style('font-weight', 'bold')
.style("font-size", "10px")

svg_title
.append("text")
.attr("x", 320)
.attr("y", 40)
.text('past 24 hours')
.attr("text-anchor", "start")
.attr('fill', '#256cb2')
.style('font-weight', 'bold')
.style("font-size", "10px")

svg_title
.append("text")
.attr("x", 410)
.attr("y", 10)
.text('New cases by day')
.attr("text-anchor", "start")
.attr('fill', '#256cb2')
.style('font-weight', 'bold')
.style("font-size", "10px")

svg_title
.append("text")
.attr("x", 410)
.attr("y", 40)
.text('Mar 09 2020')
.attr("text-anchor", "start")
.style("font-size", "8px")


// Create a function for tabulating the data
function new_case_daily_plot(area_x_chosen, svg_x) {

area_x = json_daily_cases.filter(function (d) { // gets a subset of the json data
    return d.Name === area_x_chosen
})

area_x_case_summary = json_case_summary.filter(function (d) { // gets a subset of the json data
    return d.Name === area_x_chosen
})

console.log(area_x_case_summary[0])

var svg = d3.select('#new_cases_plotted')
  .append('svg')
  .attr('width', width_hm)
  .attr('height', height_hm)
  .append('g')

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
.attr("rx", 5)
.attr("ry", 5)
.attr("width", x.bandwidth() )
.attr("height", height_hm)
.style("fill", function(d) { return color_new_cases(d.new_case_key)} )
.style("stroke-width", 4)
.style("stroke", "none")
.style("opacity", 0.8)

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
