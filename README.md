# ConstraintsTranslator

[![Build Status](https://github.com/Azzaare/ConstraintsTranslator.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/Azzaare/ConstraintsTranslator.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/Azzaare/ConstraintsTranslator.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/Azzaare/ConstraintsTranslator.jl)
[![Aqua](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

A package for translating natural-language descriptions of optimization problems into Constraint Programming models using Large Language Models (LLMs). For this pre-stable version stage, our target is to have models solved via [`CBLS.jl`](https://github.com/JuliaConstraints/CBLS.jl). Eventually, we expect this library to work for most of Julia CP ecosystem, alongside toher CP modeling languages such as MiniZinc, OR-Tools, etc.

This package acts as a light wrapper around common LLM API endpoints, supplying appropriate system prompts and context informations to the LLMs to generate CP models. Specifically, we first prompt the model for generating an high-level representation of the problem in editable Markdown format, and then we prompt the model to generate Julia code.

We currently support the following LLM APIs:
- Groq (https://groq.com)
- Google Gemini (https://ai.google.dev)
- llama.cpp (https://github.com/ggerganov/llama.cpp/blob/master/examples/server/README.md)

## Why not OpenAI / Anthropic / etc.?
Groq and Gemini are currently offering rate-limited free access to their APIs, and llama.cpp is free and open-source. We are still actively experimenting with this package, and we are not in a position to pay for API access. We might consider adding support for other APIs in the future.

## Workflow example
To begin playing with the package, you can start from the example below:

```julia
using ConstraintsTranslator

llm = GoogleLLM("gemini-1.5-pro")

# Optional setup of a terminal editor (uncomment and select a viable editor on your machine such as vim, nano, emacs, ...)
ENV["EDITOR"] = "vim"


description = """
We need to determine the shortest possible route for a salesman who must visit a set of cities exactly once and return to the starting city.
The objective is to minimize the total travel distance while ensuring that each city is visited exactly once.

Example input data:
1. cities.csv
city_id,city_name
1,CityA
2,CityB

2. distances.csv
from,to,distance
CityA,CityB,10
CityA,CityC,8
"""

response = translate(llm, description)
```

The `translate` function will first produce a Markdown representation of the problem, and then return the generated Julia code for parsing the input data and building the model.

This example uses Google Gemini as an LLM. You will need an API key and a model id to access proprietary API endpoints. Use `help?>` in the Julia REPL to learn more about the available models.

At each generation step, it will prompt the user in an interactive menu to accept the answer, edit the prompt and/or the generated text, or generate another answer with the same prompt.

The LLM expects the user to provide examples of the input data format. If no examples are present, the LLM will make assumptions about the data format based on the problem description.

