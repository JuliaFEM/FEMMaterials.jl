# This file is a part of project JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/Materials.jl/blob/master/LICENSE

using FEMMaterials, Pkg, Documenter, Literate, Dates

# automatically generate documentation from examples

"""
    add_datetime(content)
Add page generation time to the end of the content.
"""
function add_datetime(content)
    line =  "\n# Page generated at " * string(DateTime(now())) * "."
    content = content * line
    return content
end

"""
    remove_license(content)
Remove licence strings from source file.
"""
function remove_license(content)
    lines = split(content, '\n')
    function islicense(line)
        occursin("# This file is a part of JuliaFEM.", line) && return false
        occursin("# License is MIT:", line) && return false
        return true
    end
    content = join(filter(islicense, lines), '\n')
    return content
end

function generate_docs(pkg)

    function preprocess(content)
        content = add_datetime(content)
        content = remove_license(content)
    end

    pkg_dir = dirname(dirname(pathof(pkg)))
    exampledir = joinpath(pkg_dir, "examples")
    outdir = joinpath(pkg_dir, "docs", "src", "examples")
    example_pages = []
    for example_file in ["3dbeam.jl"]
        Literate.markdown(joinpath(exampledir, example_file), outdir; documenter=true, preprocess=preprocess)
        generated_example_file = joinpath("examples", first(splitext(example_file)) * ".md")
        push!(example_pages, generated_example_file)
    end
    return example_pages

end

example_pages = generate_docs(FEMMaterials)

makedocs(modules=[FEMMaterials],
         format = Documenter.HTML(),
         checkdocs = :all,
         sitename = "FEMMaterials.jl",
         pages = [
                  "index.md",
                  "Examples" => example_pages
                 ]
        )
