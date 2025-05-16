module JuliaBolt

using Genie, Genie.Router, Genie.Renderer.Html
using HTTP
using JSON3
using WebSockets
using OpenAI

export start_server

include("config.jl")
include("llm_providers.jl")
include("routes.jl")
include("websocket_handler.jl")

function start_server(; host="127.0.0.1", port=8000)
    println("Starting JuliaBolt server on http://$host:$port")
    
    # Initialize Genie app
    Genie.config.server_host = host
    Genie.config.server_port = port
    
    # Set up routes
    @info "Setting up routes..."
    setup_routes()
    
    # Start WebSocket server
    @info "Setting up WebSocket server..."
    setup_websocket_server()
    
    # Start the server
    Genie.startup()
end

end # module