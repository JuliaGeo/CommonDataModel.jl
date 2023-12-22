using BenchmarkTools
using NCDatasets
using Dates
using CommonDataModel: @groupby

fname = expanduser("~/sample_perf2.nc")
ds = NCDataset(fname)

v = ds[:data]

mean_ref = cat(
        [mean(v[:,:,findall(Dates.month.(ds[:time][:]) .== m)],dims=3)
         for m in 1:12]...,dims=3);

std_ref = cat(
        [std(v[:,:,findall(Dates.month.(ds[:time][:]) .== m)],dims=3)
         for m in 1:12]...,dims=3);


gm = @btime mean(@groupby(ds[:data],Dates.Month(time)))[:,:,:];
# 1.005 s (523137 allocations: 2.67 GiB)

@show sqrt(mean((gm - mean_ref).^2))

# Welford
gs = @btime std(@groupby(ds[:data],Dates.Month(time)))[:,:,:];
@show sqrt(mean((gs - std_ref).^2))
