"""
    get_package_path()

Returns the absolute path of the root directory of `ConstraintsTranslator.jl`.
"""
function get_package_path()
    package_path = pkgdir(@__MODULE__)
    if isnothing(package_path)
        error("The path of the package could not be found. This should never happen!")
    end
    return package_path
end
