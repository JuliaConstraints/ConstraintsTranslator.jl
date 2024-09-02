@testset "Code linting (JET.jl)" begin
    JET.test_package(ConstraintsTranslator; target_defined_modules = true)
end