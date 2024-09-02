abstract type AbstractPrompt end

struct Prompt <: AbstractPrompt
    system::String
    user::String
end
