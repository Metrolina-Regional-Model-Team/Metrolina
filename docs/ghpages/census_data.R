# Load census data and activate API#################################

packages <- c("dplyr", "tidyr", "readxl", "tidycensus", "tidyverse", "ggplot2", "scales", "tigris", "devtools")
lapply(packages, library, character.only=TRUE)

#census_api_key("76b669aa0084c8879da31fcc0257912a2b2beeaf")
census_api_key("76b669aa0084c8879da31fcc0257912a2b2beeaf", install = TRUE, overwrite = TRUE)

# Set timeout option
options(timeout = 300)

# Enable tigris caching
options(tigris_use_cache = TRUE)
#readRenviron("~/.Renviron")



## Set Geographies ================================

bg <- read_excel("C:/MRM/extras/TAZCrosswalk/mrm_geoid.xlsx", sheet = "BG") %>% 
  rowwise() %>%
  rename_all(tolower) %>%
  select(geoid, name) %>%
  arrange(name) %>%
  ungroup()

tract <- read_excel("C:/MRM/extras/TAZCrosswalk/mrm_geoid.xlsx", sheet = "Tract") %>% 
  rename_all(tolower)

geoid_v = as.vector(bg$geoid)
tract_v = as.vector(tract$name22)

nc_counties = c("Cabarrus", "Rowan",  "Gaston",  "Cleveland", "Lincoln", "Iredell", "Mecklenburg", "Union", "Anson", "Stanly", "Catawba")
sc_counties = c("York", "Lancaster")

mrm_stcnty = c('37007','37025','37035','37045','37071','37097','37109','37119','37159','45167','45179')

httr::GET("https://api.census.gov/data")

#census variables
acs_variables <-  read_excel("C:/MRM/extras/CensusCrosswalk/variables.xlsx")

ncsize <- get_acs(
  geography = "block group",
  state = "NC",
  county = nc_counties,
  variables = acs_variables$variable,
  output = "wide",
  year = 2022
)

## Size ================================

census_vars <- c(
  "B11016_001", # Total households
  "B11016_010", # 1-person households
  "B11016_003", # 2-person family households
  "B11016_011", # 2-person nonfamily households
  "B11016_004", # 3-person family households
  "B11016_012", # 3-person nonfamily households
  "B11016_005", # 4-person family households
  "B11016_013"  # 4-person nonfamily households
)

# Pull NC and SC data
ncsize <- get_acs(
  geography = "block group",
  state = "NC",
  county = nc_counties,
  variables = census_vars,
  output = "wide",
  year = 2022
)

scsize <- get_acs(
  geography = "block group",
  state = "SC",
  county = sc_counties,
  variables = census_vars,
  output = "wide",
  year = 2022
)

# Combine and process data more efficiently
dfHH <- bind_rows(ncsize, scsize) %>%
  transmute(
    geoid = GEOID,
    name = NAME,
    totHH = B11016_001E,
    one_HH = B11016_010E,
    two_HH = B11016_003E + B11016_011E,
    three_HH = B11016_004E + B11016_012E,
    four_HH = B11016_005E + B11016_013E) %>%
  mutate(
    five_HH = totHH - one_HH - two_HH - three_HH - four_HH,  
    avg_HH = (one_HH + 
                (two_HH * 2) + 
                (three_HH* 3) + 
                (four_HH * 4) + 
                (five_HH * 5)) / totHH,
    oneHH_share = one_HH/totHH,
    twoHH_share = two_HH/totHH,
    threeHH_share = three_HH/totHH,
    fourHH_share = four_HH/totHH,
    fiveHH_share = five_HH/totHH
  ) %>%
  filter(totHH > 0) %>% 
  arrange(name)

hhsize <- dfHH %>%
  filter(geoid %in% geoid_v) %>% 
  select(avg_HH, oneHH_share, twoHH_share, threeHH_share, fourHH_share, fiveHH_share) %>%
  pivot_longer(
    cols = ends_with("_share"),
    names_to = "size",
    values_to = "percent"
  ) %>%
  mutate(
    percent = as.numeric(as.character(percent)),
    percent = round(percent, 2), 
    avg_HH = round(avg_HH, 2),
    size = factor(size, 
                  levels = c("oneHH_share", "twoHH_share", "threeHH_share", "fourHH_share", "fiveHH_share"),
                  labels = c("1 Person", "2 Person", "3 Person", "4 Person", "5+ Person"))
  ) %>% 
  filter(!is.na(percent)) %>% 
  filter(avg_HH >= 1) 

# First ensure avg_HH is numeric
hhsize <- hhsize %>%
  mutate(avg_HH = as.numeric(avg_HH))

# Calculate trend lines with explicit error checking
trend_lines <- hhsize %>%
  group_by(size) %>%
  do({
    tryCatch({
      model <- lm(percent ~ poly(avg_HH, 3), data = .)
      data.frame(
        avg_HH = sort(.$avg_HH), 
        fitted = predict(model, newdata = data.frame(avg_HH = sort(.$avg_HH)))
      )
    }, error = function(e) {
      print(paste("Error in trend line calculation for size:", unique(.$size)))
      print(e)
      data.frame(avg_HH = numeric(0), fitted = numeric(0))
    })
  })

p <- plot_ly(hhsize, 
             x = ~avg_HH, 
             y = ~percent, 
             color = ~size,
             type = "scatter", 
             mode = "markers",
             marker = list(
               opacity = .5,
               size = 6),
             name = ~size,  # Add names for legend
             legendgroup = ~size) %>%  
  add_trace(data = trend_lines,
            x = ~avg_HH,
            y = ~fitted,
            color = ~size,
            type = "scatter",
            mode = "lines",
            line = list(shape = "spline", width =3),
            name = ~size,
            legendgroup = ~size,
            showlegend = FALSE) %>%
  layout(
    xaxis = list(title = "Average Household Size",
                 range = c(1, 4)),
    yaxis = list(title = "Percent",
                 tickformat = ".1",
                 range = c(0, 1)),
    hovermode = "closest",
    showlegend = TRUE)  # Ensure legend is visible

# Display the plot
p

## Income ================================

median_income_v <- "B19013_001"

nc_medinc <- get_acs(
  geography = "tract",
  state = c("NC"),
  county = nc_counties,
  variables = median_income_v,
  output = "wide",
  year = 2022,
  # geometry = TRUE
) 

sc_medinc <- get_acs(
  geography = "tract",
  state = c("SC"),
  county = sc_counties,
  variables = median_income_v,
  output = "wide",
  year = 2022)

dfMEDINC<- rbind(nc_medinc, sc_medinc) %>%
  as_tibble() %>%
  rowwise() %>%
  mutate(
    median_income = B19013_001E,
    MOE = B19013_001M,
  ) %>%
  select(GEOID,NAME, median_income, MOE) %>%
  rename_all(tolower) %>% 
  arrange(name) %>%
  ungroup()

#MedINC<- subset(dfINC, GEOID %in% GeoID_v)
MEDINC <- subset(dfMEDINC, name %in% tract_v )

## current income categories 1-4 defined by lowest 10%, 10-25%, 25%-50%,>50%

reg_med_inc = 77462

hh <- "B19001_001"
inc1 <- c("B19001_002","B19001_003","B19001_004")
inc2 <- c("B19001_005","B19001_006","B19001_007","B19001_008")
inc3 <- c("B19001_009","B19001_010","B19001_011","B19001_012")
inc4 <- c("B19001_013","B19001_014","B19001_015","B19001_016","B19001_017")

ncincome <- get_acs(
  geography = "block group",
  state = c("NC"),
  county = nc_counties,
  variables = c(hh, inc1, inc2, inc3, inc4),
  output = "wide",
  year = 2022,
  # geometry = TRUE
) 

scincome <- get_acs(
  geography = "block group",
  state = c("SC"),
  county = sc_counties,
  variables = c(hh, inc1, inc2, inc3, inc4),
  output = "wide",
  year = 2022)

dfINC<- rbind(ncincome, scincome) %>%
  as_tibble() %>%
  rowwise() %>%
  mutate(
    hh = B19001_001E,
    inc1 = sum(B19001_002E, B19001_003E, B19001_004E),
    inc2 = sum(B19001_005E,B19001_006E,B19001_007E,B19001_008E),
    inc3 = sum(B19001_009E,B19001_010E,B19001_011E,B19001_012E),
    inc4 = sum(B19001_013E,B19001_014E,B19001_015E,B19001_016E,B19001_017E),
    tract = str_sub(GEOID, 1, -2)) %>%
  rename_all(tolower) %>% 
  select ( geoid, name, tract, hh, inc1, inc2, inc3, inc4) %>% 
  left_join(MEDINC %>%  select (geoid, median_income), by = c("tract" = "geoid")) %>% 
  filter(!is.na(median_income)) %>% 
  filter(hh!=0) %>% 
  mutate(
    inc1_share = inc1/ hh,
    inc2_share = inc2/ hh,
    inc3_share = inc3/ hh,
    inc4_share = inc4/ hh,
    inc_ratio =  median_income/reg_med_inc
  ) %>%
  ungroup() %>% 
  select (geoid, inc_ratio, inc1_share, inc2_share, inc3_share, inc4_share) %>% 
  mutate(across(-1, ~ round(.x, 2)))

dfINC <- subset(dfINC, geoid %in% geoid_v)


