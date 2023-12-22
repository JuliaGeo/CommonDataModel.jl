import timeit
import xarray as xr
import numpy

# xarray-2023.12.0
# Python 3.10.12

# mean
# minimum runtime of 30 trials
# 0.7370511470362544 seconds

# std
# 3.9330708980560303 seconds
tests = [
    """vm = ds["data"].groupby("time.month").mean().to_numpy();""",
    """vm = ds["data"].groupby("time.month").std().to_numpy();""",
    ]


print("runtime")

for tt in tests:
    t = timeit.repeat(tt,
                      setup="""
import xarray as xr
fname = "/home/abarth/sample_perf2.nc"
ds = xr.open_dataset(fname)
""",
                      number=1,
                      repeat=30,
                      )

    print("timeit ",min(t),tt)


fname = "/home/abarth/sample_perf2.nc"
ds = xr.open_dataset(fname)

month = ds["time.month"].to_numpy()

print("accuracy")


mean_ref = numpy.stack(
    [ds["data"].data[(month == mm).nonzero()[0],:,:].mean(axis=0) for mm in range(1,13)],axis=0)

std_ref = numpy.stack(
    [ds["data"].data[(month == mm).nonzero()[0],:,:].std(axis=0,ddof=1) for mm in range(1,13)],axis=0)


vm = ds["data"].groupby("time.month").mean().to_numpy();

print("accuracy of mean",
      numpy.sqrt(numpy.mean((mean_ref -  vm)**2)))
# output 0

vs = ds["data"].groupby("time.month").std()


print("accuracy of std",
      numpy.sqrt(numpy.mean((std_ref -  vs)**2)))

# 0.00053720415
