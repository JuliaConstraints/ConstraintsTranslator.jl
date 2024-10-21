using CBLS
using CSV
using DataFrames
using JuMP

"""
    tsp(distances_file::String)

Create a JuMP model for the Traveling Salesman Problem (TSP).

## Arguments
- `distances_file::String`: path to the CSV file containing the distances between cities.
"""
function tsp(distances_file::String)
    df = CSV.read(distances_file, DataFrame)
    cities = unique(vcat(df.from, df.to))
    n = length(cities)
    city_index = Dict(c => i for (i, c) in enumerate(cities))
    distances = zeros(n, n)
    for row in eachrow(df)
        i = city_index[row.from]
        j = city_index[row.to]
        distances[i, j] = row.distance
    end

    model = JuMP.Model()

    @variable(model, 1<=X[1:n]<=n, Int)

    @constraint(model, X in AllDifferent())

    total_distance = x -> sum(distances[x[i], x[i + 1]] for i in 1:(n - 1)) +
                          distances[x[n], x[1]]

    @objective(model, Min, ScalarFunction(total_distance))

    return model, X
end

function make_tsp_instance(n_cities)
    coords = rand(n_cities, 2)
    from = []
    to = []
    distance = []
    for src in 1:n_cities
        for dst in 1:n_cities
            if src == dst
                continue
            end
            push!(from, src)
            push!(to, dst)
            coord_from = coords[src]
            coord_to = coords[dst]
            push!(distance, sqrt(sum((coord_from .- coord_to) .^ 2)))
        end
    end
    df = DataFrame(from = from, to = to, distance = distance)
    return df
end
