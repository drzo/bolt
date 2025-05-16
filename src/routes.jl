# HTTP routes for the JuliaBolt application

"""
Set up all HTTP routes
"""
function setup_routes()
    # Route for static files
    Genie.config.server_document_root = joinpath(dirname(@__DIR__), "public")
    
    # Home page route
    route("/") do
        serve_file("index.html")
    end
    
    # API routes
    route("/api/providers", method=GET) do
        JSON3.write(available_providers())
    end
    
    route("/api/chat", method=POST) do
        try
            # Parse request body
            payload = JSON3.read(rawpayload())
            provider = payload.provider
            model = payload.model
            messages = payload.messages
            
            # Validate request
            if !haskey(available_providers(), provider)
                return Genie.Renderer.Json.json(Dict(
                    "error" => "Provider not available or not configured"
                ), status=400)
            end
            
            # Call LLM provider
            response = complete_chat(provider, model, messages)
            
            # Return response
            return Genie.Renderer.Json.json(Dict(
                "text" => response.text,
                "model" => response.model,
                "provider" => response.provider,
                "tokens" => response.tokens
            ))
        catch e
            @error "Error in /api/chat" exception=(e, catch_backtrace())
            return Genie.Renderer.Json.json(Dict(
                "error" => "An error occurred while processing your request",
                "details" => string(e)
            ), status=500)
        end
    end
    
    # Configuration routes
    route("/api/config", method=GET) do
        # Return only providers that have API keys
        return Genie.Renderer.Json.json(Dict(
            "providers" => keys(available_providers())
        ))
    end
    
    route("/api/config/save", method=POST) do
        try
            # Parse request body
            payload = JSON3.read(rawpayload())
            
            # Update .env file with new API keys
            update_env_file(payload)
            
            # Reload environment variables
            load_env()
            
            return Genie.Renderer.Json.json(Dict(
                "success" => true
            ))
        catch e
            @error "Error in /api/config/save" exception=(e, catch_backtrace())
            return Genie.Renderer.Json.json(Dict(
                "error" => "An error occurred while saving configuration",
                "details" => string(e)
            ), status=500)
        end
    end
end

"""
Update .env file with new API keys
"""
function update_env_file(config::Any)
    env_path = joinpath(dirname(@__DIR__), ".env")
    
    # Read existing content or create default content
    content = isfile(env_path) ? readlines(env_path) : String[]
    
    # Update or add each key in the config
    for (key, value) in pairs(config)
        key_str = uppercase(string(key)) * "_API_KEY"
        key_line = "$key_str=$value"
        
        # Try to find and update existing line
        found = false
        for (i, line) in enumerate(content)
            if startswith(line, key_str * "=")
                content[i] = key_line
                found = true
                break
            end
        end
        
        # Add new line if not found
        if !found
            push!(content, key_line)
        end
    end
    
    # Write back to file
    open(env_path, "w") do io
        for line in content
            println(io, line)
        end
    end
end

"""
Serve a static file from the public directory
"""
function serve_file(filename)
    filepath = joinpath(Genie.config.server_document_root, filename)
    if isfile(filepath)
        return Genie.Renderer.Html.html(read(filepath, String))
    else
        return Genie.Renderer.Html.html("File not found", status=404)
    end
end