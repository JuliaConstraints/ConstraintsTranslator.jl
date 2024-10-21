# Example for a Magic Square problem
```julia
"""
    magic_square(n)

Create a JuMP model for an n x n magic square.

## Arguments
- `n::Int`: size of the magic square.
"""
function magic_square(n)
    N = n^2
    model = JuMP.Model()
    magic_constant = n * (N + 1) / 2

    @variable(model, 1 ≤ X[1:n, 1:n] ≤ N, Int)
    @constraint(model, vec(X) in AllDifferent())

    for i in 1:n
        @constraint(model, X[i, :] in AllEqual(; val=magic_constant))
        @constraint(model, X[:, i] in AllEqual(; val=magic_constant))
    end
    @constraint(model, [X[i, i] for i in 1:n] in AllEqual(; val=magic_constant))
    @constraint(model, [X[i, n+1-i] for i in 1:n] in AllEqual(; val=magic_constant))

    return model, X
end
```