"""
    n_queens(path::String)

Create a JuMP model for the N-Queens problem.

## Arguments
- `N`: the size of the board.
"""
function n_queens(N)
    model = JuMP.Model()

    @variable(model, 1<=Q[1:N]<=N, Int)
    @constraint(model, Q in AllDifferent())

    for i in 1:N, j in (i + 1):N
        @constraint(model, [Q[i], Q[j]] in Predicate(x -> x[1] != x[2] + i - j))
        @constraint(model, [Q[i], Q[j]] in Predicate(x -> x[1] != x[2] + j - i))
    end

    return model, Q
end
