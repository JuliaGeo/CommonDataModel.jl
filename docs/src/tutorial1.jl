# # Select, group and reduce data sets with CommonDataModel
#
# As an example we use the NOAA OISST v2 dataset available at:
# [https://psl.noaa.gov/thredds/fileServer/Datasets/noaa.oisst.v2.highres/sst.day.mean.2023.nc](https://psl.noaa.gov/thredds/fileServer/Datasets/noaa.oisst.v2.highres/sst.day.mean.2023.nc)

using CommonDataModel: @select, @CF_str, @groupby, groupby
using Dates
using Downloads: download
using CairoMakie # use GLMakie for interactive plots
#using GLMakie
using IntervalSets
using NCDatasets
using Statistics

# Some helper functions for plotting with Makie

function nicemaps(v; timeindex = 1, lon = v["lon"][:], lat = v["lat"][:], title = nothing)

    fig, ax, hm = heatmap(lon,lat,v[:,:,timeindex],aspect_ratio = 1/cosd(mean(lat)))
    if !isnothing(title)
        ax.title[] = title
    end
    Colorbar(fig[1,2],hm)
    return fig
end

function nicetimeseries(v::AbstractVector; time = v["time"][:], title = nothing,
                  timefmt = "yyyy-mm-dd")
    fig, ax, ln = lines(Dates.value.(time),v[:])
    if !isnothing(title)
        ax.title[] = title
    end
    timeticks = DateTime.(2023,1:2:12,1)
    ax.xticks = Dates.value.(timeticks),Dates.format.(timeticks,timefmt)
    ax.xticklabelrotation = π/4
    return fig
end

# Download the data file (unless already downloaded)
# The dataset contains the variables `lon` (longitude), `lat` (latitude), `time`
# and `sst` (sea surface temperature).

url = "https://psl.noaa.gov/thredds/fileServer/Datasets/noaa.oisst.v2.highres/sst.day.mean.2023.nc"

fname = "sst.day.mean.2023.nc"
if !isfile(fname)
    download(url,fname)
end

# Open the dataset and access the variable sst
ds = NCDataset(fname)
ncsst = ds["sst"]
lon = ds[CF"longitude"]

ncsst2 = @select(ncsst,300 <= lon <= 360 && 0 <= lat <= 46 && time ≈ DateTime(2023,12,24))

nicemaps(ncsst2, title = "NA SST")


# select by indices and by values
ncsst_first = view(ncsst,:,:,1)
ncsst_na = @select(ncsst_first,300 <= lon <= 360 && 0 <= lat <= 46)
nicemaps(ncsst_na)

# Select by month
ncsst_march = @select(ncsst,Dates.month(time) == 3)
nicemaps(ncsst_march,title = "SST 1st March 2023")


# Select by interval
ncsst_march_april = @select(ncsst,Dates.month(time) ∈ 3..4)
nicemaps(ncsst_march_april)

# Use julia functions to extract data; here the `abs` function
# polar regions north of 60°N and south of 60°S
ncsst_polar = @select(ncsst,abs(lat) > 60)
fig, ax, hm = heatmap(ncsst_polar[:,:,1])
ax.title[] = "regions north of 60°N and south of 60°S ($(ncsst_polar[:time][1]))"
Colorbar(fig[1,2],hm)


# extract the time series of the closest point
ncsst_timeseries = @select(ncsst,lon ≈ 330 && lat ≈ 38)
lon = ncsst_timeseries["lon"][:]
lat = ncsst_timeseries["lat"][:]
nicetimeseries(ncsst_timeseries, title = "SST at $(lon) °E and $(lat) °N")

# extract the time series of the closest point with a specified tolerance
# If there is no data nearby an empty array is returned
ncsst_outside = @select(ncsst,lon ≈ 330 && lat ≈ 93 ± 0.1)
isempty(ncsst_outside)
size(ncsst_outside)

# Rather than selecting SST based on coordinates, we can also do the reverse:
# select the longitude based on SST
ds_equator = @select(ds,lat ≈ 0 && time ≈ DateTime(2023,1,1))
lon_equator = @select(ds_equator,coalesce(sst > 30,false))["lon"]

# the first 3 longitude where SST exceeds 30°C at the equator 2023-01-01

lon_equator[1:3]


# group the SST by month and average
sst_mean = mean(@groupby(ncsst,Dates.Month(time)))
# or
# sst_mean = mean(groupby(ncsst,:time => Dates.Month))

nicemaps(sst_mean, timeindex = 1, title = "Mean January SST")


# Use custom julia function for grouping:
# The [Atlantic hurricane season](https://en.wikipedia.org/w/index.php?title=Atlantic_hurricane_season&oldid=1189144955) is the period in a year, from June 1 through November 30, when tropical or subtropical cyclones are most likely to form in the North Atlantic Ocean.

sst_na = @select(ncsst,300 <= lon <= 360 && 0 <= lat <= 46)
sst_hs = mean(@groupby(sst_na,DateTime(year(time),6,1) <= time <= DateTime(year(time),11,30)))

nicemaps(sst_hs,timeindex = 2, title = "mean SST during the Atlantic hurricane season")


# Use a function without the `@groupby` macro

is_atlantic_hurricane_season(time) =
    DateTime(year(time),6,1) <= time <= DateTime(year(time),11,30)

sst_std_hs = std(groupby(sst_na,:time => is_atlantic_hurricane_season));

nicemaps(sst_std_hs,timeindex = 2, title = "std SST during the Atlantic hurricane season")

# Use a custom aggregation function:
# estimate the probability that the temperature exceeds 26°C during
# the Atlantic hurricane season

using CommonDataModel: GroupedVariable
prob_hot(x; dims=:) = mean(coalesce.(x .> 26,false); dims=dims)
prob_hot(gv::GroupedVariable) = reduce(prob_hot,gv)

is_atlantic_hurricane_season(time) =
    DateTime(year(time),6,1) <= time <= DateTime(year(time),11,30)

sst_my_mean = prob_hot(groupby(ncsst,:time => is_atlantic_hurricane_season));

nicemaps(sst_my_mean,timeindex=2, title = "probability that temp. > 26°C during Atlantic hurricane season")
