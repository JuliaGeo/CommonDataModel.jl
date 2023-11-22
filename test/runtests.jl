using CommonDataModel
using Test

include("memory_dataset.jl")

@testset "CommonDataModel" begin
    include("test_conversion.jl")
    include("test_empty.jl")
    include("test_scaling.jl")
end

@testset "Multi-file" begin
    include("test_multifile.jl")
end


@testset "@select macro" begin
    include("test_select.jl")
    include("test_multifile_select.jl")
end
