
struct VarianceWelfordAggegation{Ti,T}
    count::Ti
    mean::T
    M2::T
end

function VarianceWelfordAggegation(T)
    VarianceWelfordAggegation{Int,T}(0,zero(T),zero(T))
end

#function VarianceWelfordAggegation(::Type{<:Array{T,N}}) where {T,N}
#    VarianceWelfordAggegation(0,zero(T),zero(T))
#end

# Welford's online algorithm
@inline function update(ag::VarianceWelfordAggegation{Ti,T}, new_value) where {Ti,T}
    count = ag.count
    mean = ag.mean
    M2 = ag.M2

    count += 1
    delta = new_value - mean
    mean += delta / count
    delta2 = new_value - mean
    M2 += delta * delta2
    return VarianceWelfordAggegation{Ti,T}(count, mean, M2)
end

function result(ag::VarianceWelfordAggegation)
    sample_variance = ag.M2 / (ag.count - 1)
    return sample_variance
end
