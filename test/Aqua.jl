@testset "Code quality (Aqua.jl)" begin
    Aqua.test_all(
        ConstraintsTranslator,
        ambiguities = (broken = false,),
        deps_compat = false,
        piracies = (broken = false,),
        unbound_args = (broken = false),
    )
end
