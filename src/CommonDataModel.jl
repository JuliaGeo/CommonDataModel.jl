module CommonDataModel

using Printf
using Preferences
import Base: isopen

"""

`AbstractDataset` is a collection of multidimensional variables (for example a
NetCDF or GRIB file)

A data set `ds` of a type derived from `AbstractDataset` should implemented at minimum:

* `Base.key(ds)`: return a list of variable names a strings
* `Base.getindex(ds,varname::String)`: return an array-like data structure (derived from `AbstractVariable`) of the variables corresponding to `varname`. This array-like data structure should follow the CF semantics.
* `ds.attrib`: should be a Dict-like data structure with all global attribute names as keys and the corresponding value
* `ds.dim`: should be a Dict-like data structure with all dimension names as keys and the corresponding length
"""
abstract type AbstractDataset
end


"""
`AbstractVariable{T,N}` is a subclass of `AbstractArray{T, N}`. A variable `v` of a type derived from `AbstractVariable` should implement:

* `v.attrib`: should be a Dict-like data structure with all variable attribute names as keys and the corresponding value
* `name(v)`: should be the name of variable within the dataset
* `dimnames(v)`: should be a iterable data structure with all dimension names
"""
abstract type AbstractVariable{T,N} <: AbstractArray{T, N}
end


include("dataset.jl")
include("variable.jl")
include("attribute.jl")
include("dimension.jl")

end # module CommonDataModel
