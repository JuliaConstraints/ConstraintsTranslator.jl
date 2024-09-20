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
        code = m.captures[2]
        if !isnothing(code)
            code = strip(code)
            if haskey(code_dict, lang)
                code_dict[lang] *= "\n" * code
            else
                code_dict[lang] = code
            end
        end
    end

    return code_dict
end

"""
    check_syntax_errors(s::String)
Parses the string `s` as Julia code. In the case of syntax errors, it returns the error 
message of the parser as a string. Otherwise, it returns an empty string.
"""
function check_syntax_errors(s::String)
    parsed_expr = Meta.parse(s, raise = false)
    error_message = ""
    if parsed_expr.head == :incomplete || parsed_expr.head == :error
        parse_error = parsed_expr.args[1]
        error_message = string(parse_error)
    end
    return error_message
end

"""
    edit_in_vim(s::String)
Edits the input string `s` in a temporary file using the Vim editor.
Returns the modified string after the editor is closed.
"""
function edit_in_editor(initial_text::String; editor = "vim")
    temp_filename = tempname()
    write(temp_filename, initial_text)
    InteractiveUtils.edit(temp_filename)
    # run(`vim $temp_filename`
    edited_text = read(temp_filename, String)
    rm(temp_filename)
    return edited_text
end
