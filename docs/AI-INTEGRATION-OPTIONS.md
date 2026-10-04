# Local AI Model Integration Options for Super Man

## Overview

This document outlines options for integrating local AI models into Super Man for advanced natural language to bash command translation.

## Why Local AI Models?

- **Privacy**: All processing happens on your machine
- **Offline**: Works without internet connection
- **Fast**: No API latency once model is loaded
- **Free**: No API costs
- **Customizable**: Can fine-tune for specific use cases

## Recommended: Ollama (Best for Super Man)

### Why Ollama?

- ✅ Easy to install and use
- ✅ Runs locally with simple API
- ✅ Multiple model options (CodeLlama, Mistral, Llama 3)
- ✅ Good balance of speed and quality
- ✅ Active development and community
- ✅ Already mentioned in Phase 3 proposal

### Installation

```bash
# Install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Pull a code-focused model (7B parameter - good balance)
ollama pull codellama:7b

# Or use Llama 3 (better general understanding)
ollama pull llama3:8b

# Or use smaller/faster model
ollama pull codellama:7b-code
```

### Model Comparison

| Model | Size | RAM Needed | Speed | Code Quality | NL Understanding |
|-------|------|------------|-------|--------------|------------------|
| codellama:7b | 4GB | 8GB | Fast | Excellent | Good |
| codellama:13b | 7GB | 16GB | Medium | Excellent | Very Good |
| llama3:8b | 4.7GB | 8GB | Fast | Very Good | Excellent |
| deepseek-coder:6.7b | 3.8GB | 8GB | Fast | Excellent | Good |

### Integration Example

```bash
# Query Ollama for bash command
query_ollama() {
  local user_query="$1"

  local prompt="Convert this request into a bash command. Only output the command, no explanation:

Request: $user_query

Bash command:"

  curl -s http://localhost:11434/api/generate -d '{
    "model": "codellama:7b",
    "prompt": "'"$prompt"'",
    "stream": false
  }' | jq -r '.response'
}

# Usage
super-man ai "find all python files modified in last week"
```

### Performance

- **First query**: 1-5 seconds (model loading + generation)
- **Subsequent queries**: 0.5-2 seconds
- **With caching**: <100ms for repeated queries

## Alternative Options

### 1. ShellGPT with Local Models

**GitHub**: https://github.com/TheR1D/shell_gpt

```bash
# Install
pip install shell-gpt

# Configure for local model (Ollama)
sgpt --model ollama/codellama:7b "find large files"
```

**Pros:**
- Purpose-built for shell commands
- Good prompt engineering
- Shell integration

**Cons:**
- Requires Python
- Another dependency layer
- Less control over prompts

### 2. LocalAI

**GitHub**: https://github.com/mudler/LocalAI

```bash
# Docker installation
docker run -p 8080:8080 --name local-ai \
  -v /path/to/models:/models \
  localai/localai:latest
```

**Pros:**
- OpenAI-compatible API
- Multiple model backends
- REST API

**Cons:**
- Requires Docker
- More complex setup
- Heavier than Ollama

### 3. LM Studio

**Website**: https://lmstudio.ai/

**Pros:**
- GUI for model management
- Easy to use
- Local API server
- Cross-platform

**Cons:**
- GUI application (not CLI-first)
- Closed source
- Requires more resources

### 4. llama.cpp (Direct)

**GitHub**: https://github.com/ggerganov/llama.cpp

```bash
# Build llama.cpp
git clone https://github.com/ggerganov/llama.cpp
cd llama.cpp
make

# Download model
wget https://huggingface.co/TheBloke/CodeLlama-7B-GGUF/resolve/main/codellama-7b.Q4_K_M.gguf

# Run inference
./main -m codellama-7b.Q4_K_M.gguf -p "Convert to bash: find large files"
```

**Pros:**
- Pure C++ (fast)
- Minimal dependencies
- Full control

**Cons:**
- Manual model management
- More complex integration
- Requires building from source

### 5. GPT4All

**Website**: https://gpt4all.io/

```bash
# Install
pip install gpt4all

# Python script
from gpt4all import GPT4All
model = GPT4All("orca-mini-3b.ggmlv3.q4_0.bin")
output = model.generate("Convert to bash: find large files")
```

**Pros:**
- Easy Python integration
- Multiple models
- GUI available

**Cons:**
- Python dependency
- Smaller model selection
- Less actively developed than Ollama

## Specialized NL2Bash Models

### 1. NL2Bash Research Models

**Paper**: https://arxiv.org/abs/1802.08979
**GitHub**: https://github.com/TellinaTool/nl2bash

**Note**: Research project, requires training data and model setup. Not production-ready for direct integration.

### 2. AI-Shell

**GitHub**: https://github.com/BuilderIO/ai-shell

```bash
npm install -g @builder.io/ai-shell
```

**Note**: Requires OpenAI API key (not fully local), but excellent prompt engineering. Could adapt prompts for local models.

## Recommendation for Super Man

**Use Ollama with CodeLlama 7B**

### Reasons:
1. **Easy Setup**: Single command installation
2. **Good Performance**: Fast enough for interactive use
3. **Quality Results**: CodeLlama trained specifically for code
4. **Active Development**: Regular updates and improvements
5. **Community Support**: Large user base, good documentation
6. **Flexible**: Easy to swap models for experimentation

### Implementation Plan (Phase 3)

```bash
# New mode in super-man.sh
super-man ai "find all log files modified today and compress them"

# Workflow:
# 1. Check if Ollama is running
# 2. Send query with optimized prompt
# 3. Parse response for bash command
# 4. Validate command exists
# 5. Show command with explanation
# 6. Optional: Ask user to execute or copy
# 7. Cache response for future identical queries
```

### Prompt Engineering Template

```
You are a bash command expert. Convert natural language requests into bash commands.

Rules:
- Output ONLY the bash command, nothing else
- Use common, widely available commands
- Include necessary flags for safety
- Make commands portable (work on most Linux systems)
- Add brief inline comments for complex commands

Request: {user_query}

Bash command:
```

### Caching Strategy

```bash
# Cache location
~/.cache/super-man/ai-responses/

# Cache key: MD5 of query
# Cache value: JSON with command, explanation, timestamp

# Cache duration: 30 days
# Cache invalidation: Manual or by version update
```

## Performance Targets (Phase 3)

| Metric | Target | Expected with Ollama |
|--------|--------|----------------------|
| First query | <5s | 2-4s |
| Cached query | <100ms | 10-50ms |
| Model load time | <10s | 3-8s |
| Memory usage | <2GB | 1-1.5GB |

## Testing Models

To test different models for bash command generation:

```bash
# Test script
for model in codellama:7b llama3:8b deepseek-coder:6.7b; do
  echo "Testing $model..."
  time ollama run $model "Convert to bash: find files larger than 100MB"
  echo "---"
done
```

## Future Enhancements

1. **Multi-Step Commands**: Break complex requests into multiple steps
2. **Validation**: Check if generated command is safe to run
3. **Learning**: Remember user preferences and common patterns
4. **Explanation**: Always explain what the command does
5. **Interactive**: Ask for clarification on ambiguous requests

## Security Considerations

- **Validate Generated Commands**: Never auto-execute AI-generated commands
- **Sandbox Testing**: Consider dry-run mode
- **User Confirmation**: Always show command and ask before execution
- **Dangerous Command Detection**: Warn on `rm -rf`, `dd`, etc.
- **Path Validation**: Ensure generated paths are safe

## Conclusion

**For Phase 3 implementation, use Ollama with CodeLlama 7B**

It provides the best balance of:
- Easy setup and maintenance
- Good performance (1-5s first query, <100ms cached)
- High quality bash command generation
- Local operation (privacy + offline)
- Reasonable resource usage (~1.5GB RAM)

The current Phase 1 keyword-based search handles 80% of use cases in <100ms. Phase 3 AI integration will handle the remaining 20% of complex queries that need true natural language understanding.

---

**Ready to implement when Phase 3 is requested!**
