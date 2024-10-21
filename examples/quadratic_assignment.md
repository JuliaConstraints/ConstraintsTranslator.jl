# Example for the Quadratic Assignment Problem
```julia
"""
qap(n, W, D)

Create a JuMP model for the Quadratic Assignment Problem (QAP).

## Arguments
- `n::Int`: problem size.
- `W::Matrix`: flow matrix.
- `D::Matrix`: distance matrix.
"""
function qap(n, W, D)
    model = JuMP.Model()

    @variable(model, 1 ≤ X[1:n] ≤ n, Int)
    @constraint(model, X in AllDifferent())

    Σwd = p -> sum(sum(W[p[i], p[j]] * D[i, j] for j in 1:n) for i in 1:n)

    @objective(model, Min, ScalarFunction(Σwd))

    return model, X
end
```