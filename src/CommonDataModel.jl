module CommonDataModel

using CFTime
using Dates
using Printf
using Preferences
import Base: isopen, show, display, close, filter
using DataStructures

"""

`AbstractDataset` is a collection of multidimensional variables (for example a
NetCDF or GRIB file)

A data set `ds` of a type derived from `AbstractDataset` should implemented at minimum:

* `Base.key(ds)`: return a list of variable names as strings
* `variable(ds,varname::String)`: return an array-like data structure (derived from `AbstractVariable`) of the variables corresponding to `varname`. This array-like data structure should follow the CF semantics.
* `dimnames(ds)`: should be an iterable with all dimension names in the data set  `ds`
* `dim(ds,name)`: dimension value corresponding to name

Optionally a data set can have attributes and groups:

* `attribnames(ds)`: should be an iterable with all attribute names
* `attrib(ds,name)`: attribute value corresponding to name
* `groupnames(ds)`: should be an iterable with all group names
* `group(ds,name)`: group corresponding to the name

For a writable-dataset, one should also implement:
* `defDim`: define a dimension
* `defAttrib`: define a attribute
* `defVar`: define a variable
* `defGroup`: define a group
"""
abstract type AbstractDataset
end


"""
`AbstractVariable{T,N}` is a subclass of `AbstractArray{T, N}`. A variable `v` of a type derived from `AbstractVariable` should implement:

* `name(v)`: should be the name of variable within the data set
* `dimnames(v)`: should be a iterable data structure with all dimension names of the variable `v`
* `dataset(v)`: the parent dataset containing `v`
* `Base.size(v)`: the size of the variable
* `Base.getindex(v,indices...)`: get the data of `v` at the provided indices

Optionally a variable can have attributes:

* `attribnames(v)`: should be an iterable with all attribute names
* `attrib(v,name)`: attribute value corresponding to name

For a writable-dataset, one should also implement:
* `defAttrib`: define a attribute
* `Base.setindex(v,data,indices...)`: set the data in `v` at the provided indices

"""
abstract type AbstractVariable{T,N} <: AbstractArray{T, N}
end


struct CFStdName
    name::Symbol
end

const SymbolOrString = Union{Symbol, AbstractString}

include("dataset.jl")
include("variable.jl")
include("cfvariable.jl")
include("attribute.jl")
include("dimension.jl")
include("cfconventions.jl")

end # module CommonDataModel

#  LocalWords:  AbstractDataset NetCDF GRIB ds AbstractVariable
#  LocalWords:  varname dimnames iterable attribnames attrib dataset
#  LocalWords:  groupnames AbstractArray
