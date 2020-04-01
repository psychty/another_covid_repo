

// Components of change
var request = new XMLHttpRequest();
    request.open("GET", "./se_case_summary.json", false);
    request.send(null);

var json_case_summary = JSON.parse(request.responseText); // parse the fetched json data into a variable

json_case_summary.sort(function(a, b) {
    return d3.descending(a['Total cases'], b['Total cases']);
    });

// Components of change
var request = new XMLHttpRequest();
    request.open("GET", "./se_daily_cases.json", false);
    request.send(null);

var json_daily_cases = JSON.parse(request.responseText); // parse the fetched json data into a variable

var latest_date = d3.max(json_daily_cases, function (d) {
  return d.Date;}).split('-');

latest_date = new Date(latest_date[0], latest_date[1] - 1, latest_date[2]);

d3.select("#data_recency")
    .text(function(d) {
        return 'This latest available data in this analysis is for ' + latest_date.toDateString() +'.'});

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

tabulate_case_summary(json_case_summary, ['Name', "Total cases", "Total cases per 100,000 population", "New cases in past 24 hours", "New cases per 100,000 population"]);

var width_hm = 400
var height_hm = 25
// hacking a heatmap

var color_new_cases = d3.scaleOrdinal()
.domain(['Starting cases', 'Data revised down', 'No new cases', '1-5', '6-10', '11-15', '16-20', 'Above 20'])
.range(['#dcf3f5','#a6b4d8','#ffffb2','#fed976','#feb24c','#fd8d3c','#f03b20','#bd0026'])

var svg = d3.select('#new_cases_plotted')
  .append('svg')
  .attr('width', width_hm)
  .attr('height', height_hm)
  .append('g')

var dates = d3.map(json_daily_cases, function(d){
return(d.Date)})
.keys()

area_x = json_daily_cases.filter(function (d) { // gets a subset of the json data
    return d.Name === "West Sussex"
})

// Build X scales and axis:
var x = d3.scaleBand()
  .range([ 0, width_hm])
  .domain(dates)
  .padding(0.05);

svg
.append("g")
.style("font-size", 15)
.attr("transform", "translate(0," + height_hm + ")")
.call(d3.axisBottom(x).tickSize(0))
.select(".domain").remove()

svg
.selectAll()
.data(area_x)
.enter()
.append("rect")
.attr("x", function(d) { return x(d.Date) })
// .attr("y", height_hm * .5) // we want to put this from the top (0)
.attr("rx", 4)
.attr("ry", 4)
.attr("width", x.bandwidth() )
.attr("height", height_hm)
.style("fill", function(d) { return color_new_cases(d.new_case_key)} )
.style("stroke-width", 4)
.style("stroke", "none")
.style("opacity", 0.8)
