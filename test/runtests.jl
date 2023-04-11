using CommonDataModel
using Test

@testset "CommonDataModel" begin
    include("test_conversion.jl")
    include("test_empty.jl")
end

