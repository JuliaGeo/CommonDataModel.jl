module CommonDataModel

using CFTime
using Dates
using Printf
using Preferences
import Base: isopen, show, display, close
using DataStructures

"""

`AbstractDataset` is a collection of multidimensional variables (for example a
NetCDF or GRIB file)

A data set `ds` of a type derived from `AbstractDataset` should implemented at minimum:

* `Base.key(ds)`: return a list of variable names a strings
* `Base.getindex(ds,varname::String)`: return an array-like data structure (derived from `AbstractVariable`) of the variables corresponding to `varname`. This array-like data structure should follow the CF semantics.
* `attribnames(ds)`: should be an iterable with all attribute names
* `attrib(ds,name)`: attribute value corresponding to name
* `dimnames(ds)`: should be an iterable with all dimension names in the data set  `ds`
* `dim(ds,name)`: dimension value corresponding to name

"""
abstract type AbstractDataset
end


"""
`AbstractVariable{T,N}` is a subclass of `AbstractArray{T, N}`. A variable `v` of a type derived from `AbstractVariable` should implement:

* `v.attrib`: should be a Dict-like data structure with all variable attribute names as keys and the corresponding value
* `name(v)`: should be the name of variable within the dataset
* `dimnames(v)`: should be a iterable data structure with all dimension names of the variable `v`
"""
abstract type AbstractVariable{T,N} <: AbstractArray{T, N}
end


include("dataset.jl")
include("variable.jl")
include("cfvariable.jl")
include("attribute.jl")
include("dimension.jl")

end # module CommonDataModel
