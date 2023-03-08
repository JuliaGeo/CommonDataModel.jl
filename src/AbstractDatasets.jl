module AbstractDatasets

abstract type AbstractDataset
end

abstract type AbstractDatasetVariable{T,N} <: AbstractArray{T, N}
end


dimnames(av::AbstractDatasetVariable) = String[]

# specialize this function if there are unlimited dimenions
unlimited(ad::AbstractDataset) = ()

end # module AbstractDatasets
