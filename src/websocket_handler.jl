# WebSocket handling for streaming responses

"""
Set up WebSocket server
"""
function setup_websocket_server()
    # Add WebSocket route
    Genie.Router.channel("/ws") do ws
        try
            @info "WebSocket connection established"
            
            # Keep connection alive
            while isopen(ws)
                # Wait for a message
                message = WebSockets.receive(ws)
                
                # Parse message
                payload = JSON3.read(message)
                
                if payload.type == "chat"
                    # Handle chat message
                    handle_chat_message(ws, payload)
                elseif payload.type == "ping"
                    # Respond to ping
                    WebSockets.send(ws, JSON3.write(Dict(
                        "type" => "pong",
                        "timestamp" => time()
                    )))
                end
            end
        catch e
            @error "WebSocket error" exception=(e, catch_backtrace())
        end
    end
end

"""
Handle a chat message and stream the response
"""
function handle_chat_message(ws, payload)
    provider_name = payload.provider
    model = payload.model
    messages = payload.messages
    
    try
        # Create provider
        provider = create_provider(provider_name)
        
        # For now, we'll just use non-streaming API and simulate streaming
        response = chat_completion(provider, model, messages)
        
        # Send response in chunks to simulate streaming
        text = response.text
        chunk_size = 20  # characters per chunk
        
        for i in 1:chunk_size:length(text)
            chunk = text[i:min(i+chunk_size-1, length(text))]
            
            WebSockets.send(ws, JSON3.write(Dict(
                "type" => "chat_chunk",
                "text" => chunk,
                "done" => i+chunk_size > length(text)
            )))
            
            # Small delay to simulate streaming
            sleep(0.05)
        end
        
        # Send final message with tokens
        WebSockets.send(ws, JSON3.write(Dict(
            "type" => "chat_complete",
            "model" => response.model,
            "provider" => response.provider,
            "tokens" => response.tokens
        )))
        
    catch e
        @error "Error in chat handler" exception=(e, catch_backtrace())
        WebSockets.send(ws, JSON3.write(Dict(
            "type" => "error",
            "error" => "Failed to generate response: $(string(e))"
        )))
    end
end