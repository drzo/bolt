#!/usr/bin/env julia

# Add the current directory to the load path
push!(LOAD_PATH, "@.")

# Include the JuliaBolt module
include(joinpath(dirname(@__DIR__), "src", "JuliaBolt.jl"))

using JuliaBolt

# Parse command line arguments
import Pkg.TOML

# Default configuration
config = Dict(
    "host" => "127.0.0.1",
    "port" => 8000
)

# Override with command line arguments
for arg in ARGS
    if startswith(arg, "--port=")
        config["port"] = parse(Int, split(arg, "=")[2])
    elseif startswith(arg, "--host=")
        config["host"] = split(arg, "=")[2]
    end
end

println("Starting JuliaBolt server...")
println("Host: $(config["host"])")
println("Port: $(config["port"])")

# Start the server
JuliaBolt.start_server(
    host=config["host"],
    port=config["port"]
)