abstract type AbstractMessage end
abstract type AbstractTemplate end

"""
    MetadataMessage

Represents the metadata information of a prompt template.
The templates follow the specifications of `PromptingTools.jl`.

# Fields
- `content::String`: The content of the metadata message.
- `description::String`: A description of the metadata message.
- `version::String`: The version of the metadata message.
"""
struct MetadataMessage <: AbstractMessage
    content::String
    description::String
    version::String
end

"""
Represents the prompt template of a system message.
The template can optionally contain string placeholders enclosed in double curly braces, e.g., `{{variable}}`.
Placeholders must be replaced with actual values when generating prompts.

# Fields
- `content::String`: The content of the system message.
- `variables::Vector{String}`: A list of variables used in the system message.
"""
struct SystemMessage <: AbstractMessage
    content::String
    variables::Vector{String}
end

"""
Represents the prompt template of a user message.
The template can optionally contain string placeholders enclosed in double curly braces, e.g., `{{variable}}`.
Placeholders must be replaced with actual values when generating prompts.

# Fields
- `content::String`: The content of the system message.
- `variables::Vector{String}`: A list of variables used in the system message.
"""
struct UserMessage <: AbstractMessage
    content::String
    variables::Vector{String}
end

"""
Represents a complete prompt template, comprising metadata, system, and user messages.

# Fields
- `metadata::MetadataMessage`: The metadata message of the prompt template.
- `system::SystemMessage`: The system message of the prompt template.
- `user::UserMessage`: The user message of the prompt template.
"""
struct PromptTemplate <: AbstractTemplate
    metadata::MetadataMessage
    system::SystemMessage
    user::UserMessage
end

"""
    read_template(data_path::String)

Reads a prompt template from a JSON file specified by `data_path`. 
The function parses the JSON data and constructs a `PromptTemplate` object containing metadata, system, and user messages.
TODO: validate the JSON data against a schema to ensure it is valid before parsing.

# Arguments
- `data_path::String`: The path to the JSON file containing the prompt template.

# Returns
- `PromptTemplate`: A `PromptTemplate` structure encapsulating the metadata, system, and user messages.

# Raises
- `ErrorException`: if the template does not match the specification format.
"""
function read_template(data_path::String)::PromptTemplate
    file_content = read(data_path, String)
    data = JSON.parse(file_content)

    metadata = nothing
    system = nothing
    user = nothing

    for item in data
        _type = item["_type"]
        if _type == "metadatamessage"
            metadata = MetadataMessage(
                item["content"],
                item["description"],
                item["version"],
            )
        elseif _type == "systemmessage"
            system = SystemMessage(
                item["content"],
                item["variables"],
            )
        elseif _type == "usermessage"
            user = UserMessage(
                item["content"],
                item["variables"],
            )
        else
            error("Unknown message type: $_type")
        end
    end

    if isnothing(metadata) || isnothing(system) || isnothing(user)
        error("Template must contain metadata, system, and user messages")
    end

    return PromptTemplate(metadata, system, user)
end

"""
    format_template(template::PromptTemplate; kwargs...)::Prompt

Formats a `PromptTemplate` by substituting all variables in the system and user messages with user-provided values.

# Arguments
- `template::PromptTemplate`: The prompt template containing metadata, system, and user messages.
- `kwargs...`: A variable number of keyword arguments where keys are variable names and values are the corresponding replacements.

# Returns
- `Prompt`: A `Prompt` struct with the system and user messages containing the substituted values.

# Raises
- `ErrorException`: If any variables specified in the system or user templates are not present in the `kwargs`.
- `Warning`: If there are extra `kwargs` that are not used in the templates.
"""
function format_template(template::PromptTemplate; kwargs...)
    system = template.system.content
    user = template.user.content

    template_vars = union(Set(template.system.variables), Set(template.user.variables))
    kwargs_keys = Set(keys(kwargs))

    # Check for missing variables in kwargs
    missing_vars = template_vars - kwargs_keys
    if !isempty(missing_vars)
        error("Missing variables in kwargs: $(collect(missing_vars))")
    end

    # Check for extra kwargs
    extra_kwargs = kwargs_keys - template_vars
    if !isempty(extra_kwargs)
        @warn "Extra kwargs will be ignored: $(collect(extra_kwargs))"
    end

    # Substitute variables in the system and user content
    for var in template.system.variables
        system = replace(system, "{{$(var)}}", kwargs[var])
    end

    for var in template.user.variables
        user = replace(user, "{{$(var)}}", kwargs[var])
    end

    return Prompt(system, user)
end