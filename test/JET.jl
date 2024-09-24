@testset "Code linting (JET.jl)" begin
    if VERSION ≤ v"1.10"
        JET.test_package(ConstraintsTranslator; target_defined_modules = true)
    end
end
