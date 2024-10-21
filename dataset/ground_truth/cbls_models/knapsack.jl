using CBLS
using CSV
using DataFrames
using JuMP
using Random

"""
knapsack(items_file::String, weight_file::String)

Create a JuMP model for the Knapsack Problem.

## Arguments
- `items_file::String`: path to the CSV file containing item data.
- `weight_file::String`: path to the CSV file containing the weight limit.
"""
function knapsack(items_file::String, weight_file::String)
    items = CSV.read(items_file, DataFrame)
    weight_limit = CSV.read(weight_file, DataFrame).weight_limit[1]

    model = JuMP.Model()

    @variable(model, 0<=x[1:nrow(items)]<=1, Int)

    @objective(model, Max, sum(items.utility .* x))

    @constraint(model, items.weight' * x in Sum(op = <=, val = weight_limit))

    return model
end

function make_knapsack_instance(n_items, weight_range, profit_range, capacity)
    min_weight, max_weight = weight_range
    min_profit, max_profit = profit_range

    weights = rand(min_weight:max_weight, n_items)
    profits = rand(min_profit:max_profit, n_items)

    df_items = DataFrame(weight = weights, utility = profits)
    df_weight_limit = DataFrame(weight_limit = [capacity])

    return df_items, df_weight_limit
end
