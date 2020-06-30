
# Small multiples plot with daily cases bars and rolling average.

# This is inspired by work of Brennan Klein

# whole time series colours by whether the last 14 days has:
#   
#   more than the previous 14-day average
# fewer than the previous 14-day average
# fewer than half of the previous 14-day average
# fewer than 50 cases per day
# 
# these will need to be carefully considered locally when cases are fairly low.