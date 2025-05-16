# JuliaBolt

A Julia implementation of bolt.diy - a platform for interacting with various LLM providers including OpenAI, Anthropic, Groq, Mistral, Ollama, and more.

## Features

- 🚀 Simple web interface for interacting with different LLMs
- 🔄 Support for multiple LLM providers
- 💬 Chat interface with markdown support
- 🔌 Local model integration via Ollama
- ⚡ WebSocket-based streaming responses
- 🔧 Easy configuration of API keys

## Requirements

- Julia 1.9+
- Required Julia packages:
  - Genie.jl (web framework)
  - HTTP.jl
  - JSON3.jl
  - WebSockets.jl
  - OpenAI.jl

## Getting Started

1. Clone this repository
2. Install dependencies:
   ```
   julia -e 'using Pkg; Pkg.activate("."); Pkg.instantiate()'
   ```
3. Start the server:
   ```
   julia scripts/run.jl
   ```
4. Open your browser to http://localhost:8000

## Configuration

Configure your LLM provider API keys in the web interface or by editing the `.env` file directly.

### Supported Providers

- OpenAI (GPT models)
- Anthropic (Claude models)
- Groq
- Mistral AI
- Local models via Ollama
- GitHub models (gpt-4o, gpt-4o-mini)

## Architecture

JuliaBolt is built using:

- Genie.jl for web server functionality
- WebSockets.jl for real-time streaming
- HTTP.jl for API communication
- OpenAI.jl for OpenAI API integration

## License

MIT