
height_sm = 210
width_sm = 380

var request = new XMLHttpRequest();
request.open("GET", "./ltla_case_change_daily.json", false);
request.send(null);
var ltla_data = JSON.parse(request.responseText);

var request = new XMLHttpRequest();
request.open("GET", "./ltla_case_change_dates.json", false);
request.send(null);
var ltla_data_dates = JSON.parse(request.responseText).map(function(d){return d.Date_label});



chosen_utla_area = 'West Sussex'

var chosen_ltla_df = ltla_data.filter(function(d) {
  return d.UTLA19NM === chosen_utla_area
});

var areas_for_sm_1 = d3.nest()
  .key(function(d) { return d.Name;})
  .entries(chosen_ltla_df);

// Which areas are present
small_areas = areas_for_sm_1.map(function(d){return d.key})

// Add an svg element for each group. The will be one beside each other and will go on the next row when no more room available
var sm_svg_1 = d3.select("#my_sm_dataviz")
   .selectAll("small_multiples")
   .data(areas_for_sm_1)
   .enter()
   .append("svg")
   .attr("width", width_sm)
   .attr("height", height_sm + 60)
   .append("g")
   .attr("transform", "translate(" + 50 + "," + 20 + ")");

// Add X axis --> it is a date format
var x_sm_1 = d3.scaleBand()
   .domain(chosen_ltla_df.map(function(d) {return (d.Date_label);}))
   .range([0, width_sm - 60]);

sm_svg_1
  .append("g")
  .attr("transform", "translate(0," + height_sm + ")")
  .call(d3.axisBottom(x_sm_1).tickValues(ltla_data_dates));

//Add Y axis
var y_sm_1 = d3.scaleLinear()
    .domain([0, d3.max(chosen_ltla_df, function(d) { return +d.Seven_day_average_new_cases; })])
    .range([height_sm, 0 ])
    .nice();

sm_svg_1.append("g")
    .call(d3.axisLeft(y_sm_1).ticks(5));

// color palette
var case_change_colour = d3.scaleOrdinal()
  .domain(['No change in average cases','Increasing average number of cases over past 7 days', 'Decreasing average number of cases over past 7 days', 'Less than half the previous 7-day average', 'No confirmed cases in past 7 days'])
  .range(['#aaaaaa','#721606', '#005bd6', '#1fbfbb', '#c2f792'])

 // Draw the line
sm_svg_1
  .append("path")
  .attr("fill", "none")
  .attr("stroke", function(d){ return case_change_colour(d.Colour_key) })
  .attr("stroke-width", 1.9)
  .attr("d", function(d){
    return d3.line()
      .defined(d => !isNaN(d.Seven_day_average_new_cases))
      .x(function(d) { return x_sm_1(d.Date_label); })
      .y(function(d) { return y_sm_1(+d.Seven_day_average_new_cases); })
      (d.values)
      })



// Add plot headings
sm_svg_1
  .append("text")
  .attr("text-anchor", "start")
  .attr("y", 10)
  .attr("x", 10)
  .text(function(d){ return(d.key)})
  .style('fill', '#999999')
  // .style("fill", function(d){ return case_change_colour(d.key) })
