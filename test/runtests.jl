using Aqua
using ConstraintsTranslator
using JET
using Test
using TestItemRunner
using TestItems

@testset "ConstraintsTranslator.jl" begin
    include("Aqua.jl")
    include("JET.jl")
    include("TestItemRunner.jl")
    include("parsing.jl")
end
