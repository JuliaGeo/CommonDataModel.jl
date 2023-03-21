module AbstractDatasets

"""

`AbstractDataset` is a collection of multidimensional variables (for example a
NetCDF or GRIB file)

A data set `ds` of a type derived from `AbstractDatasets` should implemented at minimum:

* `Base.key(ds)`: return a list of variable names a strings
* `Base.getindex(ds,varname::String)`: return an array-like data structure (derived from `AbstractDatasetVariable`) of the variables corresponding to `varname`. This array-like data structure should follow the CF semantics.
* `ds.attrib`: should be a Dict-like data structure with all global attribute names as keys and the corresponding value
* `ds.dim`: should be a Dict-like data structure with all dimension names as keys and the corresponding length
"""
abstract type AbstractDataset
end


"""
`AbstractDatasetVariable{T,N}` is a subclass of `AbstractArray{T, N}`. A variable `v` of a type derived from `AbstractDatasetVariable` should implement:

* `v.attrib`: should be a Dict-like data structure with all variable attribute names as keys and the corresponding value
"""
abstract type AbstractDatasetVariable{T,N} <: AbstractArray{T, N}
end


dimnames(av::AbstractDatasetVariable) = String[]

# specialize this function if there are unlimited dimenions
unlimited(ad::AbstractDataset) = ()

end # module AbstractDatasets
