# NETRAX AI Gateway

**Your team gets AI. Your clients' data stays private.**

NETRAX sits between your staff and AI tools such as ChatGPT, Claude and Gemini. Before a request leaves your network it finds names, emails, account numbers, API keys and other sensitive data, then either:

- **Masks it**: the AI provider sees placeholders, and the real values are put back in the answer, or
- **Routes it to a local model**: requests that contain sensitive data go to an AI model running on your own machine, and everything else goes to the cloud.

Every request is logged on your machine, so you can show what was protected and where each request went.

NETRAX AI is built by [TechX Labs](https://techx.dev).

## Quick start (Docker)

```bash
git clone https://github.com/TechX-Resources/netrax-gateway.git
cd netrax-gateway
cp config.example.yaml config.yaml
docker compose up -d --build
```

- Health check: http://localhost:3000/health
- Dashboard: http://localhost:3000/dashboard
- OpenAI-compatible endpoint: http://localhost:3000/openai/v1/chat/completions
- Anthropic-compatible endpoint: http://localhost:3000/anthropic/v1/messages

Point any OpenAI- or Anthropic-compatible app at these URLs instead of the provider's URL.

## Keep sensitive requests on your own machine

1. Install [Ollama](https://ollama.com) and pull a model, for example `ollama pull llama3.2`.
2. In `config.yaml`, set `mode: route` and set `local.base_url` to your Ollama address (`http://host.docker.internal:11434` when NETRAX runs in Docker).
3. Restart: `docker compose up -d`.

Requests that contain sensitive data are answered by the local model, and the rest go to your cloud provider.

### Local-only mode

To keep every request on your own machine, add `local_only: true` under `local:` (route mode). NETRAX still checks and logs each request, but the local model answers all of them, and `/openai/v1/models` lists only the local model, so chat apps work without any cloud API key.

## Development

Requires [Bun](https://bun.sh).

```bash
bun install
docker compose --profile dev up detector -d   # PII detector on port 5002
DETECTOR_URL=http://localhost:5002 bun run dev
bun test && bun run typecheck && bun run check
```

## Staying in sync with PasteGuard

This repository started from [PasteGuard](https://github.com/sgasser/pasteguard). The original project is kept as the `upstream` remote:

```bash
git remote add upstream https://github.com/sgasser/pasteguard.git   # once
git fetch upstream
git checkout -b sync/upstream-$(date +%Y%m%d) main
git merge upstream/main          # resolve conflicts, then run the tests
```

To keep merges small, NETRAX-specific code lives in its own files wherever possible. The original README is in [docs/PASTEGUARD_README.md](docs/PASTEGUARD_README.md).

## License

Apache License 2.0. See [LICENSE](LICENSE) and [NOTICE](NOTICE).
