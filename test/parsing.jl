@testset "parse_code tests" begin
    input = """
    Here is some text.
    ```python
    code block 1
    ```
    More text.
    ```julia
    code block 2
    ```
    Even more text.
    ```
    code block 3
    ```
    """

    expected_output = Dict(
        "python" => "code block 1",
        "julia" => "code block 2",
        "plain" => "code block 3",
    )

    result = parse_code(input)

    @test haskey(result, "python")
    @test strip(result["python"]) == strip(expected_output["python"])

    @test haskey(result, "julia")
    @test strip(result["julia"]) == strip(expected_output["julia"])

    @test haskey(result, "plain")
    @test strip(result["plain"]) == strip(expected_output["plain"])
end