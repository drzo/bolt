# LLM provider implementations

"""
Base abstract type for LLM providers
"""
abstract type LLMProvider end

"""
Generic response structure for chat completion
"""
struct ChatResponse
    text::String
    model::String
    provider::String
    tokens::Dict{String, Int}
end

"""
OpenAI provider implementation
"""
struct OpenAIProvider <: LLMProvider
    api_key::String
    base_url::String
    OpenAIProvider(api_key::String) = new(api_key, "https://api.openai.com/v1")
    OpenAIProvider(api_key::String, base_url::String) = new(api_key, base_url)
end

"""
Chat completion with OpenAI API
"""
function chat_completion(provider::OpenAIProvider, model::String, messages::Vector{Dict{String, Any}})
    client = OpenAI.OpenAIClient(provider.api_key; base_url=provider.base_url)
    response = OpenAI.create_chat(client, model, messages)
    
    return ChatResponse(
        response.choices[1].message.content,
        model,
        "openai",
        Dict("prompt" => response.usage.prompt_tokens, 
             "completion" => response.usage.completion_tokens,
             "total" => response.usage.total_tokens)
    )
end

"""
Ollama provider implementation
"""
struct OllamaProvider <: LLMProvider
    base_url::String
    OllamaProvider() = new("http://127.0.0.1:11434")
    OllamaProvider(base_url::String) = new(base_url)
end

"""
Chat completion with Ollama API
"""
function chat_completion(provider::OllamaProvider, model::String, messages::Vector{Dict{String, Any}})
    url = "$(provider.base_url)/api/chat"
    
    # Convert messages to Ollama format
    ollama_messages = [Dict("role" => msg["role"], "content" => msg["content"]) for msg in messages]
    
    body = Dict(
        "model" => model,
        "messages" => ollama_messages,
        "stream" => false
    )
    
    headers = ["Content-Type" => "application/json"]
    
    response = HTTP.post(url, headers, JSON3.write(body))
    result = JSON3.read(String(response.body))
    
    # Ollama doesn't return token counts in the same way, so we estimate
    prompt_tokens = sum(length.(getindex.(messages, "content"))) ÷ 4
    completion_tokens = length(result.message.content) ÷ 4
    
    return ChatResponse(
        result.message.content,
        model,
        "ollama",
        Dict("prompt" => prompt_tokens, 
             "completion" => completion_tokens,
             "total" => prompt_tokens + completion_tokens)
    )
end

"""
Factory function to create provider based on name
"""
function create_provider(provider_name::String)
    keys = get_api_keys()
    
    if provider_name == "openai"
        return OpenAIProvider(keys["openai"])
    elseif provider_name == "openai_like"
        return OpenAIProvider(keys["openai_like"]["api_key"], keys["openai_like"]["base_url"])
    elseif provider_name == "ollama"
        return OllamaProvider(keys["ollama_base_url"])
    else
        error("Provider $provider_name not implemented yet")
    end
end

"""
Generic chat completion function that routes to the appropriate provider
"""
function complete_chat(provider_name::String, model::String, messages::Vector{Dict{String, Any}})
    provider = create_provider(provider_name)
    return chat_completion(provider, model, messages)
end