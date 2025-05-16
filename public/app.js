// JuliaBolt Frontend

// DOM Elements
const providerSelect = document.getElementById('provider');
const modelSelect = document.getElementById('model');
const userInput = document.getElementById('userInput');
const sendBtn = document.getElementById('sendBtn');
const chatHistory = document.getElementById('chatHistory');
const configBtn = document.getElementById('configBtn');
const configModal = document.getElementById('configModal');
const cancelConfigBtn = document.getElementById('cancelConfigBtn');
const saveConfigBtn = document.getElementById('saveConfigBtn');

// API keys input elements
const openaiKey = document.getElementById('openaiKey');
const anthropicKey = document.getElementById('anthropicKey');
const groqKey = document.getElementById('groqKey');
const mistralKey = document.getElementById('mistralKey');
const ollamaUrl = document.getElementById('ollamaUrl');

// State
let providers = {};
let ws = null;
let currentConversation = [];

// Initialize the app
async function init() {
    try {
        // Load available providers
        const response = await fetch('/api/providers');
        providers = await response.json();
        
        // Populate provider dropdown
        populateProviders();
        
        // Set up event listeners
        setupEventListeners();
        
        // Connect WebSocket
        connectWebSocket();
    } catch (error) {
        console.error('Failed to initialize app:', error);
        addSystemMessage('Failed to initialize app. Please check your connection and try again.');
    }
}

// Connect to WebSocket server
function connectWebSocket() {
    // Close existing connection if any
    if (ws) {
        ws.close();
    }
    
    // Create new WebSocket connection
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const wsUrl = `${protocol}//${window.location.host}/ws`;
    
    ws = new WebSocket(wsUrl);
    
    ws.onopen = () => {
        console.log('WebSocket connection established');
        // Send ping to keep connection alive
        setInterval(() => {
            if (ws.readyState === WebSocket.OPEN) {
                ws.send(JSON.stringify({
                    type: 'ping',
                    timestamp: Date.now()
                }));
            }
        }, 30000);
    };
    
    ws.onmessage = (event) => {
        const message = JSON.parse(event.data);
        
        if (message.type === 'chat_chunk') {
            appendToLatestAssistantMessage(message.text);
            
            if (message.done) {
                finishLatestAssistantMessage();
            }
        } else if (message.type === 'chat_complete') {
            // Update token count or other metadata
            console.log('Chat complete:', message);
        } else if (message.type === 'error') {
            addSystemMessage(`Error: ${message.error}`);
        }
    };
    
    ws.onclose = () => {
        console.log('WebSocket connection closed');
        // Try to reconnect after a delay
        setTimeout(connectWebSocket, 5000);
    };
    
    ws.onerror = (error) => {
        console.error('WebSocket error:', error);
    };
}

// Populate provider dropdown
function populateProviders() {
    providerSelect.innerHTML = '<option value="">Select a provider</option>';
    
    for (const [provider, models] of Object.entries(providers)) {
        const option = document.createElement('option');
        option.value = provider;
        option.textContent = formatProviderName(provider);
        providerSelect.appendChild(option);
    }
}

// Format provider name for display
function formatProviderName(provider) {
    const names = {
        'openai': 'OpenAI',
        'anthropic': 'Anthropic',
        'groq': 'Groq',
        'ollama': 'Ollama (Local)',
        'openai_like': 'GitHub',
        'mistral': 'Mistral AI'
    };
    
    return names[provider] || provider;
}

// Update model dropdown based on selected provider
function updateModelOptions(provider) {
    modelSelect.innerHTML = '<option value="">Select a model</option>';
    
    if (!provider || !providers[provider]) {
        return;
    }
    
    for (const model of providers[provider]) {
        const option = document.createElement('option');
        option.value = model;
        option.textContent = model;
        modelSelect.appendChild(option);
    }
}

// Set up event listeners
function setupEventListeners() {
    // Provider selection
    providerSelect.addEventListener('change', () => {
        updateModelOptions(providerSelect.value);
    });
    
    // Send message button
    sendBtn.addEventListener('click', sendMessage);
    
    // Send message on Enter key (with Shift+Enter for new line)
    userInput.addEventListener('keydown', (e) => {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            sendMessage();
        }
    });
    
    // Configuration modal
    configBtn.addEventListener('click', () => {
        configModal.classList.remove('hidden');
        loadConfiguration();
    });
    
    cancelConfigBtn.addEventListener('click', () => {
        configModal.classList.add('hidden');
    });
    
    saveConfigBtn.addEventListener('click', saveConfiguration);
}

// Load configuration values
async function loadConfiguration() {
    try {
        const response = await fetch('/api/config');
        const config = await response.json();
        
        // We don't get the actual API keys back for security reasons,
        // but we can show which providers are configured
        const configuredProviders = config.providers;
        
        // Update UI to show which providers are configured
        if (configuredProviders.includes('openai')) {
            openaiKey.placeholder = '•••• (configured)';
        }
        
        if (configuredProviders.includes('anthropic')) {
            anthropicKey.placeholder = '•••• (configured)';
        }
        
        if (configuredProviders.includes('groq')) {
            groqKey.placeholder = '•••• (configured)';
        }
        
        if (configuredProviders.includes('mistral')) {
            mistralKey.placeholder = '•••• (configured)';
        }
        
        if (configuredProviders.includes('ollama')) {
            // Ollama URL is stored, so we can show it
            const ollamaResponse = await fetch('/api/config/ollama');
            const ollamaConfig = await ollamaResponse.json();
            ollamaUrl.value = ollamaConfig.base_url;
        }
    } catch (error) {
        console.error('Failed to load configuration:', error);
    }
}

// Save configuration
async function saveConfiguration() {
    const config = {};
    
    if (openaiKey.value) {
        config.openai = openaiKey.value;
    }
    
    if (anthropicKey.value) {
        config.anthropic = anthropicKey.value;
    }
    
    if (groqKey.value) {
        config.groq = groqKey.value;
    }
    
    if (mistralKey.value) {
        config.mistral = mistralKey.value;
    }
    
    if (ollamaUrl.value) {
        config.ollama_base_url = ollamaUrl.value;
    }
    
    try {
        const response = await fetch('/api/config/save', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(config)
        });
        
        const result = await response.json();
        
        if (result.success) {
            configModal.classList.add('hidden');
            
            // Reload providers
            const providersResponse = await fetch('/api/providers');
            providers = await providersResponse.json();
            populateProviders();
            
            addSystemMessage('Configuration saved successfully. Provider list has been updated.');
        } else {
            addSystemMessage(`Failed to save configuration: ${result.error}`);
        }
    } catch (error) {
        console.error('Failed to save configuration:', error);
        addSystemMessage('Failed to save configuration. Please check the console for details.');
    }
}

// Send a message to the LLM
function sendMessage() {
    const message = userInput.value.trim();
    const provider = providerSelect.value;
    const model = modelSelect.value;
    
    if (!message) {
        return;
    }
    
    if (!provider || !model) {
        addSystemMessage('Please select a provider and model first.');
        return;
    }
    
    // Add user message to conversation
    addUserMessage(message);
    
    // Clear input
    userInput.value = '';
    
    // Create placeholder for assistant response
    addAssistantMessage('');
    
    // Add to conversation history
    currentConversation.push({
        role: 'user',
        content: message
    });
    
    // Send to WebSocket
    if (ws && ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify({
            type: 'chat',
            provider: provider,
            model: model,
            messages: currentConversation
        }));
    } else {
        addSystemMessage('WebSocket connection is not open. Trying to reconnect...');
        connectWebSocket();
    }
}

// Add a user message to the chat
function addUserMessage(message) {
    const msgElement = document.createElement('div');
    msgElement.className = 'mb-4';
    msgElement.innerHTML = `
        <div class="flex items-start">
            <div class="bg-blue-100 rounded-lg p-3 flex-1">
                <p class="font-medium text-blue-800">You</p>
                <div class="prose max-w-none">
                    ${marked.parse(message)}
                </div>
            </div>
        </div>
    `;
    
    chatHistory.appendChild(msgElement);
    chatHistory.scrollTop = chatHistory.scrollHeight;
}

// Add an assistant message to the chat
function addAssistantMessage(message) {
    const msgElement = document.createElement('div');
    msgElement.className = 'mb-4 assistant-message';
    msgElement.innerHTML = `
        <div class="flex items-start">
            <div class="bg-gray-100 rounded-lg p-3 flex-1">
                <p class="font-medium text-gray-800">JuliaBolt</p>
                <div class="prose max-w-none assistant-content">
                    ${marked.parse(message)}
                </div>
            </div>
        </div>
    `;
    
    chatHistory.appendChild(msgElement);
    chatHistory.scrollTop = chatHistory.scrollHeight;
    
    // Apply syntax highlighting
    msgElement.querySelectorAll('pre code').forEach((block) => {
        hljs.highlightElement(block);
    });
}

// Add a system message to the chat
function addSystemMessage(message) {
    const msgElement = document.createElement('div');
    msgElement.className = 'mb-4 text-center';
    msgElement.innerHTML = `
        <div class="inline-block bg-yellow-100 rounded-lg p-2 text-sm text-yellow-800">
            ${message}
        </div>
    `;
    
    chatHistory.appendChild(msgElement);
    chatHistory.scrollTop = chatHistory.scrollHeight;
}

// Append text to the latest assistant message
function appendToLatestAssistantMessage(text) {
    const assistantMessages = document.querySelectorAll('.assistant-message');
    if (assistantMessages.length === 0) {
        return;
    }
    
    const latestMessage = assistantMessages[assistantMessages.length - 1];
    const contentDiv = latestMessage.querySelector('.assistant-content');
    
    // Get current content and append new text
    const currentContent = contentDiv.textContent;
    const newContent = currentContent + text;
    
    // Update content with rendered markdown
    contentDiv.innerHTML = marked.parse(newContent);
    
    // Re-apply syntax highlighting
    latestMessage.querySelectorAll('pre code').forEach((block) => {
        hljs.highlightElement(block);
    });
    
    chatHistory.scrollTop = chatHistory.scrollHeight;
}

// Finalize the latest assistant message
function finishLatestAssistantMessage() {
    const assistantMessages = document.querySelectorAll('.assistant-message');
    if (assistantMessages.length === 0) {
        return;
    }
    
    const latestMessage = assistantMessages[assistantMessages.length - 1];
    const contentDiv = latestMessage.querySelector('.assistant-content');
    
    // Get the final content
    const content = contentDiv.textContent;
    
    // Add to conversation history
    currentConversation.push({
        role: 'assistant',
        content: content
    });
}

// Initialize the app when DOM is loaded
document.addEventListener('DOMContentLoaded', init);