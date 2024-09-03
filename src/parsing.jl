"""
    parse_code(s::String)
Parse the code blocks in the input string `s` delimited by triple backticks and an optional language annotation.
Returns a dictionary keyed by language. Code blocks from the same language are concatenated.
"""
function parse_code(s::String)
    # Regular expression to match code blocks with optional language annotation
    pattern = r"```(\w*)\n(.*?)```"s

    # Find all matches
    matches = eachmatch(pattern, s)

    # Initialize a dictionary to store code blocks by language
    code_dict = Dict{String, String}()

    # Extract the code blocks and their language annotations
    for m in matches
        lang = m.captures[1] == "" ? "plain" : m.captures[1]
        code = strip(m.captures[2])
        if haskey(code_dict, lang)
            code_dict[lang] *= "\n" * code
        else
            code_dict[lang] = code
        end
    end

    return code_dict
end