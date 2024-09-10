"""
    extract_structure(model <: AbstractLLM, description <: AbstractString)
Extracts the parameters, decision variables and constraints of an optimization problem given a natural-language `description`.
Returns a plaintext Markdown-formatted document containing the above information.
"""
function extract_structure(
        model::AbstractLLM,
        description::AbstractString,
        constraints::AbstractString,
)
    package_path::String = pkgdir(@__MODULE__)
    template_path = joinpath(package_path, "templates", "ExtractStructure.json")
    template = read_template(template_path)
    prompt = format_template(template; description, constraints)
    response = stream_completion(model, prompt)

    options = [
        "Accept the response",
        "Edit the response",
        "Try again with a different prompt",
        "Try again with the same prompt",
    ]
    menu = RadioMenu(options; pagesize = 4)

    while true
        choice = request("What do you want to do?", menu)
        if choice == 1
            break
        elseif choice == 2
            response = edit_in_vim(response)
            println(response)
        elseif choice == 3
            description = edit_in_vim(description)
            prompt = format_template(template; description, constraints)
            response = stream_completion(model, prompt)
        elseif choice == 4
            response = stream_completion(model, prompt)
        elseif choice == -1
            InterruptException()
        end
    end
    return response
end

function jumpify_model(
        model::AbstractLLM,
        description::AbstractString,
        examples::AbstractString,
)
    package_path::String = pkgdir(@__MODULE__)
    template_path = joinpath(package_path, "templates", "JumpifyModel.json")
    template = read_template(template_path)
    prompt = format_template(template; description, examples)
    response = stream_completion(model, prompt)

    options = [
        "Accept the response",
        "Edit the response",
        "Try again with a different prompt",
        "Try again with the same prompt",
    ]
    menu = RadioMenu(options; pagesize = 4)
    while true
        choice = request("What do you want to do?", menu)
        if choice == 1
            break
        elseif choice == 2
            response = edit_in_vim(response)
            println(response)
        elseif choice == 3
            description = edit_in_vim(description)
            prompt = format_template(template; description, examples)
            response = stream_completion(model, prompt)
        elseif choice == 4
            response = stream_completion(model, prompt)
        elseif choice == -1
            InterruptException()
        end
    end
    return response
end

"""
    translate(description::String, model::String)
Translate the natural-language `description` of an optimization problem into a Constraint Programming model
by querying the Large Language Model `model`.
"""
function translate(model::AbstractLLM, description::AbstractString)
    constraints = String[]
    for (name, cons) in USUAL_CONSTRAINTS
        push!(constraints, "$(name): $(lstrip(cons.description))")
    end
    constraints = join(constraints, "\n")

    structure = extract_structure(model, description, constraints)

    package_path::String = pkgdir(@__MODULE__)
    examples_path = joinpath(package_path, "examples")
    examples_files = filter(x -> endswith(x, ".md"), readdir(examples_path))
    examples = []
    for file in examples_files
        example = read(joinpath(examples_path, file), String)
        push!(examples, example)
    end
    examples = join(examples, "\n")

    response = jumpify_model(model, structure, examples)

    return parse_code(response)["julia"]
end
