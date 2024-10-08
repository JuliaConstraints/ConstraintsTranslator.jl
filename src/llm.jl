const GROQ_URL::String = "https://api.groq.com/openai/v1/chat/completions"
const GEMINI_URL::String = "https://generativelanguage.googleapis.com/v1beta/models/{{model_id}}"

abstract type AbstractLLM end
abstract type OpenAILLM <: AbstractLLM end

"""
    GroqLLM

Structure encapsulating the parameters for accessing the Groq LLM API.

- `api_key`: an API key for accessing the Groq API (https://groq.com), read from the environmental variable GROQ_API_KEY.
- `model_id`: a string identifier for the model to query. See https://console.groq.com/docs/models for the list of available models.
- `url`: URL for chat completions. Defaults to "https://api.groq.com/openai/v1/chat/completions".
"""
struct GroqLLM <: OpenAILLM
    api_key::String
    model_id::String
    url::String

    function GroqLLM(model_id::String = "llama-3.1-70b-versatile", url = GROQ_URL)
        api_key = get(ENV, "GROQ_API_KEY", "")
        if isempty(api_key)
            error("Environment variable GROQ_API_KEY is not set")
        end
        new(api_key, model_id, url)
    end
end

"""
    Google LLM

Structure encapsulating the parameters for accessing the Google LLM API.

- `api_key`: an API key for accessing the Google Gemini API (`https://ai.google.dev/gemini-api/docs/`), read from the environmental variable `GOOGLE_API_KEY`.
- `model_id`: a string identifier for the model to query. See `https://ai.google.dev/gemini-api/docs/models/gemini` for the list of available models.
- `url`: URL for chat completions. Defaults to `https://generativelanguage.googleapis.com/v1beta/models/{{model_id}}`.
"""
struct GoogleLLM <: AbstractLLM
    api_key::String
    model_id::String
    url::String

    function GoogleLLM(model_id::String = "gemini-1.5-flash-latest")
        api_key = get(ENV, "GOOGLE_API_KEY", "")
        if isempty(api_key)
            error("Environment variable GOOGLE_API_KEY is not set")
        end
        new(api_key, model_id, GEMINI_URL)
    end
end

"""
    LlamaCppLLM

Structure encapsulating the parameters for accessing the llama.cpp server API.

- `api_key`: an optional API key for accessing the server
- `model_id`: a string identifier for the model to query. Unused, kept for API compatibility.
- `url`: the URL of the llama.cpp server OpenAI API endpoint (e.g., http://localhost:8080)

NOTE: we do not apply the appropriate chat templates to the prompt. This must be handled either in an external code path or by the server.
"""
struct LlamaCppLLM <: OpenAILLM
    api_key::String
    model_id::String
    url::String

    function LlamaCppLLM(url::String)
        api_key = get(ENV, "LLAMA_CPP_API_KEY", "no-key")
        new(api_key, "hal-9000-v2", url)
    end
end

"""
    get_completion(llm::OpenAILLM, prompt::Prompt)

Returns a completion for the given prompt using an OpenAI API compatible LLM
"""
function get_completion(llm::OpenAILLM, prompt::Prompt)
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
    response = HTTP.post(llm.url, headers, body)
    body = JSON3.read(response.body)
    return body["choices"][1]["message"]["content"]
end

"""
    get_completion(llm::GoogleLLM, prompt::Prompt)

Returns a completion for the given prompt using the Google Gemini LLM API.
"""
function get_completion(llm::GoogleLLM, prompt::Prompt)
    url = replace(llm.url, "{{model_id}}" => llm.model_id)
    url *= ":generateContent"
    headers = [
        "x-goog-api-key" => "$(llm.api_key)",
        "Content-Type" => "application/json",
    ]
    body = JSON3.write(Dict(
        "contents" => Dict(
        "parts" => Dict("text" => join([prompt.system, prompt.user], "\n"))
    ),
    ))
    response = HTTP.post(url, headers, body)
    body = JSON3.read(response.body)
    return body["candidates"][1]["content"]["parts"][1]["text"]
end

"""
    stream_completion(llm::OpenAILLM, prompt::Prompt)

Returns a completion for the given prompt using an OpenAI API compatible model.
The completion is streamed to the terminal as it is generated.
"""
function stream_completion(llm::OpenAILLM, prompt::Prompt)
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

    HTTP.open(:POST, llm.url, headers; body = body) do io
        write(io, body)
        HTTP.closewrite(io)
        HTTP.startread(io)
        while !eof(io)
            chunk = String(readavailable(io))
            event_buffer *= chunk
            events = split(event_buffer, "\n\n")
            if !endswith(event_buffer, "\n\n")
                event_buffer = events[end]
                events = events[1:(end - 1)]
            else
                event_buffer = ""
            end

            for event in events
                for line in eachmatch(r"(?<=data: ).*", event)
                    if line.match == "[DONE]"
                        print("\n")
                        return accumulated_content
                    end
                    message = JSON3.read(line.match)
                    if !isempty(message["choices"][1]["delta"])
                        print(message["choices"][1]["delta"]["content"])
                        accumulated_content *= message["choices"][1]["delta"]["content"]
                    end
                end
            end
        end
        HTTP.closeread(io)
    end
    return accumulated_content
end

"""
    stream_completion(llm::GoogleLLM, prompt::Prompt)

Returns a completion for the given prompt using the Google Gemini LLM API.
The completion is streamed to the terminal as it is generated.
"""
function stream_completion(llm::GoogleLLM, prompt::Prompt)
    url = replace(llm.url, "{{model_id}}" => llm.model_id)
    url *= ":streamGenerateContent?alt=sse"
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
        HTTP.closewrite(io)
        HTTP.startread(io)
        while !eof(io)
            chunk = String(readavailable(io))
            for line in eachmatch(r"(?<=data: ).*", chunk)
                if isnothing(line)
                    print("\n")
                    continue
                end
                message = JSON3.read(line.match)
                print(message["candidates"][1]["content"]["parts"][1]["text"])
                accumulated_content *= String(message["candidates"][1]["content"]["parts"][1]["text"])
            end
        end
        HTTP.closeread(io)
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
function get_completion(::AbstractLLM, ::AbstractPrompt)
    return error("Not implemented for this LLM and/or prompt type.")
end
