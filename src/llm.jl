const GROQ_URL::String = "https://api.groq.com/openai/v1/chat/completions"
const GEMINI_URL::String = "https://generativelanguage.googleapis.com/v1beta/models/{{model_id}}:generateContent"
const GEMINI_URL_STREAM::String = "https://generativelanguage.googleapis.com/v1beta/models/{{model_id}}:streamGenerateContent?alt=sse"

abstract type AbstractLLM end

"""
    GroqLLM
Structure encapsulating the parameters for accessing the Groq LLM API.
- `api_key`: an API key for accessing the Groq API (https://groq.com), read from the environmental variable GROQ_API_KEY
- `model_id`: a string identifier for the model to query. See https://console.groq.com/docs/models for the list of available models.
"""
struct GroqLLM <: AbstractLLM
    api_key::String
    model_id::String

    function GroqLLM(model_id::String)
        api_key = get(ENV, "GROQ_API_KEY", "")
        if isempty(api_key)
            error("Environment variable GROQ_API_KEY is not set")
        end
        new(api_key, model_id)
    end
end

"""
    Google LLM
Structure encapsulating the parameters for accessing the Google LLM API.
- `api_key`: an API key for accessing the Google Gemini API (https://ai.google.dev/gemini-api/docs/), read from the environmental variable GOOGLE_API_KEY
- `model_id`: a string identifier for the model to query. See https://ai.google.dev/gemini-api/docs/models/gemini for the list of available models.
"""
struct GoogleLLM <: AbstractLLM
    api_key::String
    model_id::String

    function GoogleLLM(model_id::String)
        api_key = get(ENV, "GOOGLE_API_KEY", "")
        if isempty(api_key)
            error("Environment variable GOOGLE_API_KEY is not set")
        end
        new(api_key, model_id)
    end
end

"""
    get_completion(llm::GroqLLM, prompt::Prompt)
Returns a completion for the given prompt using the Groq LLM API.
"""
function get_completion(llm::GroqLLM, prompt::Prompt)
    headers = [
        "Authorization" => "Bearer $(llm.api_key)",
        "Content-Type" => "application/json",
    ]
    body = JSON3.write(Dict(
        "messages" => [
            Dict("role" => "system", "content" => prompt.system),
            Dict("role" => "user", "content" => prompt.user),
        ],
        "model" => llm.model_id,
    ))
    response = HTTP.post(GROQ_URL, headers, body)
    body = JSON3.read(response.body)
    return body["choices"][1]["message"]["content"]
end

"""
    get_completion(llm::GoogleLLM, prompt::Prompt)
Returns a completion for the given prompt using the Google Gemini LLM API.
"""
function get_completion(llm::GoogleLLM, prompt::Prompt)
    url = replace(GEMINI_URL, "{{model_id}}" => llm.model_id)
    headers = [
        "x-goog-api-key" => "$(llm.api_key)",
        "Content-Type" => "application/json",
    ]
    body = JSON3.write(Dict(
        "contents" => Dict(
        "parts" => Dict("text" => prompt.system * prompt.user)
    ),
    ))
    response = HTTP.post(url, headers, body)
    body = JSON3.read(response.body)
    return body["candidates"][1]["content"]["parts"][1]["text"]
end

"""
    stream_completion(llm::GroqLLM, prompt::Prompt)
Returns a completion for the given prompt using the Groq LLM API.
The completion is streamed to the terminal as it is generated.
"""
function stream_completion(llm::GroqLLM, prompt::Prompt)
    headers = [
        "Authorization" => "Bearer $(llm.api_key)",
        "Content-Type" => "application/json",
    ]
    body = JSON3.write(Dict(
        "messages" => [
            Dict("role" => "system", "content" => prompt.system),
            Dict("role" => "user", "content" => prompt.user),
        ],
        "model" => llm.model_id,
        "stream" => true,
    ))

    accumulated_content = ""
    event_buffer = ""

    HTTP.open(:POST, GROQ_URL, headers; body = body) do io
        write(io, body)
        while !eof(io)
            chunk = String(readavailable(io))
            events = split(chunk, "\n\n")
            if !endswith(event_buffer, "\n\n")
                event_buffer = events[end]
                events = events[1:(end - 1)]
            else
                event_buffer = ""
            end
            events = join(events, "\n")
            for line in eachmatch(r"(?<=data: ).*", events, overlap = true)
                if line.match == "[DONE]"
                    print("\n")
                    break
                end
                message = JSON3.read(line.match)
                if !isempty(message["choices"][1]["delta"])
                    print(message["choices"][1]["delta"]["content"])
                    accumulated_content *= message["choices"][1]["delta"]["content"]
                end
            end
        end
    end
    return accumulated_content
end

"""
    stream_completion(llm::GoogleLLM, prompt::Prompt)
Returns a completion for the given prompt using the Google Gemini LLM API.
The completion is streamed to the terminal as it is generated.
"""
function stream_completion(llm::GoogleLLM, prompt::Prompt)
    url = replace(GEMINI_URL_STREAM, "{{model_id}}" => llm.model_id)
    headers = [
        "x-goog-api-key" => "$(llm.api_key)",
        "Content-Type" => "application/json",
    ]
    body = JSON3.write(Dict(
        "contents" => Dict(
        "parts" => Dict("text" => prompt.system * prompt.user)
    ),
    ))

    accumulated_content = ""

    HTTP.open(:POST, url, headers; body = body) do io
        write(io, body)
        while !eof(io)
            chunk = String(readavailable(io))
            line = match(r"(?<=data: ).*", chunk)
            if isnothing(line)
                print("\n")
                break
            end
            message = JSON3.read(line.match)
            print(message["candidates"][1]["content"]["parts"][1]["text"])
            accumulated_content *= String(message["candidates"][1]["content"]["parts"][1]["text"])
        end
    end
    return accumulated_content
end

"""
    stream_completion(llm::AbstractLLM, prompt::AbstractPrompt)
Returns a completion for a `prompt` using the `llm` model API.
The completion is streamed to the terminal as it is generated.
"""
function stream_completion(llm::AbstractLLM, prompt::AbstractPrompt)
    @warn "Not implemented for this LLM and/or prompt type. Falling back to get_completion."
    return get_completion(llm, prompt)
end

"""
    get_completion(llm::AbstractLLM, prompt::AbstractPrompt)
Returns a completion for a `prompt` using the `llm` model API.
"""
function get_completion(llm::AbstractLLM, prompt::AbstractPrompt)
    error("Not implemented for this LLM and/or prompt type.")
end
