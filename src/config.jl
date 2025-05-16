# Configuration for JuliaBolt

"""
Load environment variables from .env file if it exists
"""
function load_env()
    env_path = joinpath(dirname(@__DIR__), ".env")
    if isfile(env_path)
        for line in readlines(env_path)
            if !startswith(line, "#") && contains(line, "=")
                key, value = split(line, "=", limit=2)
                ENV[strip(key)] = strip(value)
            end
        end
    end
end

"""
Get LLM API keys from environment variables
"""
function get_api_keys()
    return Dict(
        "openai" => get(ENV, "OPENAI_API_KEY", ""),
        "anthropic" => get(ENV, "ANTHROPIC_API_KEY", ""),
        "groq" => get(ENV, "GROQ_API_KEY", ""),
        "google" => get(ENV, "GOOGLE_GENERATIVE_AI_API_KEY", ""),
        "openrouter" => get(ENV, "OPEN_ROUTER_API_KEY", ""),
        "huggingface" => get(ENV, "HuggingFace_API_KEY", ""),
        "mistral" => get(ENV, "MISTRAL_API_KEY", ""),
        "ollama_base_url" => get(ENV, "OLLAMA_API_BASE_URL", "http://127.0.0.1:11434"),
        "openai_like" => Dict(
            "api_key" => get(ENV, "OPENAI_LIKE_API_KEY", ""),
            "base_url" => get(ENV, "OPENAI_LIKE_API_BASE_URL", "http://localhost:4000")
        )
    )
end

"""
Check if API keys are set for a provider
"""
function has_api_key(provider)
    keys = get_api_keys()
    if provider == "ollama"
        return !isempty(keys["ollama_base_url"])
    elseif provider == "openai_like"
        return !isempty(keys["openai_like"]["api_key"]) && !isempty(keys["openai_like"]["base_url"])
    else
        return haskey(keys, provider) && !isempty(keys[provider])
    end
end

"""
Available LLM providers and their models
"""
function available_providers()
    providers = Dict(
        "openai" => ["gpt-4o", "gpt-4o-mini", "gpt-4-turbo", "gpt-3.5-turbo"],
        "anthropic" => ["claude-3-opus", "claude-3-sonnet", "claude-3-haiku"],
        "groq" => ["llama-3.1-70b-versatile", "llama-3.1-8b-versatile", "mixtral-8x7b"],
        "google" => ["gemini-1.5-pro", "gemini-1.5-flash"],
        "mistral" => ["mistral-large", "mistral-medium", "mistral-small"],
        "ollama" => ["qwen2.5-coder:32b", "qwen2.5-coder:14b", "qwen2.5-coder:7b", 
                     "qwen2.5-coder:3b", "qwen2.5-coder:1.5b", "qwen2.5-coder:0.5b"],
        "openai_like" => ["github/gpt-4o", "github/gpt-4o-mini"]
    )
    
    # Filter out providers without API keys
    return Dict(k => v for (k, v) in providers if has_api_key(k))
end

# Load environment variables when module is loaded
load_env()