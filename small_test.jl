using CommonDataModel
import DiskArrays
fname = tempname()
ds = CommonDataModel.MemoryDataset(fname, "c")
v = CommonDataModel.defVar(ds, "temperature", zeros(10,11), ("lon", "lat"))

m = iseven.(reshape(1:(10*11),(10,11)))
DiskArrays.eachchunk(view(v,m))
size(view(v,m)) == (count(m),)
v[m] .= 1
Array(v) == m