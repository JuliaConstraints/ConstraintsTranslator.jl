abstract type AbstractPrompt end

"""
    Prompt

Simple data structure encapsulating a system prompt and a user prompt for LLM generation.

## Fields
- `system`: the system prompt.
- `user`: the user prompt.
"""
struct Prompt <: AbstractPrompt
    system::String
    user::String
end
