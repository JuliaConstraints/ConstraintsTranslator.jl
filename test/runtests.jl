using ConstraintsTranslator
using Test
using Aqua
using JET

@testset "ConstraintsTranslator.jl" begin
    @testset "Code quality (Aqua.jl)" begin
        Aqua.test_all(ConstraintsTranslator)
    end
    @testset "Code linting (JET.jl)" begin
        JET.test_package(ConstraintsTranslator; target_defined_modules = true)
    end
    # Write your tests here.
end
