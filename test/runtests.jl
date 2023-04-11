using CommonDataModel
using Test

@testset "CommonDataModel" begin
    include("test_conversion.jl")
    include("test_empty.jl")
    include("test_scaling.jl")
end

