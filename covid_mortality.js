

var request = new XMLHttpRequest();
request.open("GET", "./england_latest_mortality.json", false);
request.send(null);
var eng_mortality_figures = JSON.parse(request.responseText);

d3.select("#latest_national_deaths_confirmed")
  .data(eng_mortality_figures)
  .html(function(d) {
    return 'In England as at ' + d.Date_label + ', ' + d3.format(',.0f')(d.Cumulative_deaths) + ' people have been reported to have died where the person had tested positive for Covid-19 by an NHS or Public Health laboratory. These figures include hospital deaths as well as care home deaths and deaths in the community (e.g. at home).'
  });

var request = new XMLHttpRequest();
request.open("GET", "./ons_weekly_mortality_dates.json", false);
request.send(null);
var ons_mortality_figures_dates = JSON.parse(request.responseText);

d3.select("#ons_dates_mortality")
.data(ons_mortality_figures_dates)
.html(function(d) {
  return 'The tables include deaths that occurred up to Friday ' + d.Occurring_week_ending + ' but were registered up to ' + d.Reported_week_ending + '. Figures by place of death may differ to previously published figures due to improvements in the way we code place of death.'
});
