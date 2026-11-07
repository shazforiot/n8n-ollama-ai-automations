# Free local AI automations: n8n + Ollama 🧠⚡

Run **n8n** (workflow automation) and **Ollama** (local AI models) together with one command, then use 3 ready-made AI workflows. No API keys, no cloud and no per-token bills: everything runs on your own computer.

| # | Workflow | What it does |
|---|---|---|
| 1 | **AI News Digest → Discord** | Reads a news feed, summarises the top 5 stories with a local model, posts the digest to Discord (manually or every morning at 8:00) |
| 2 | **GitHub Issue Triage** | Pulls the newest open issues of any public repo, labels them (bug / feature / question / docs), sets a priority and writes a one-line summary |
| 3 | **Chat with your PDFs** | Loads the PDFs in `files/docs`, embeds them locally and gives you a chat that answers from your documents (local RAG) |

> 🎥 Companion to the Thetips4you video *"Free AI Automations on Your PC: n8n + Ollama"*.

---

## What's inside

```
n8n-ollama-ai-automations/
├── docker-compose.yml        n8n + Postgres + Ollama (+ automatic model download and workflow import)
├── .env.example              settings (models, versions, secrets); the start script creates .env
├── scripts/
│   ├── start.sh  / start.ps1 start everything (cpu | gpu | host)
│   ├── check.sh  / check.ps1 health check + test answer from the model
│   └── stop.sh   / stop.ps1  stop (or --reset / -Reset to wipe all data)
├── n8n/
│   ├── credentials/ollama.json   the "Local Ollama" credential (imported automatically)
│   └── workflows/*.json          the 3 demo workflows (imported automatically)
└── files/docs/*.pdf          sample PDFs for workflow 3 (fictional company + product)
```

## Requirements

| | Minimum | Better |
|---|---|---|
| RAM | 8 GB | 16 GB |
| Disk | 10 GB free | SSD |
| GPU | not needed (CPU works, just slower) | NVIDIA GPU with recent drivers |
| Software | Docker with Compose v2 | Git |

Models used: `llama3.2` (3B, ~2 GB) for text and `nomic-embed-text` (~270 MB) for embeddings.

---

## Step 0 · Install Docker (pick your setup)

**Windows 10/11 (Docker Desktop)**
1. Install WSL2 once: open PowerShell **as Administrator** and run `wsl --install`, then reboot.
2. Install **Docker Desktop** from docker.com. In *Settings → General*, keep **"Use the WSL 2 based engine"** on.
3. Start Docker Desktop and wait for *"Engine running"*.

**WSL2 (Ubuntu)**: either
- use Docker Desktop and enable *Settings → Resources → WSL integration → Ubuntu*, or
- install Docker Engine inside Ubuntu: `curl -fsSL https://get.docker.com | sh && sudo usermod -aG docker $USER` (then close and reopen the terminal).

**Linux**: install Docker Engine + the Compose plugin (`curl -fsSL https://get.docker.com | sh`).

Check it works:
```bash
docker --version
docker compose version
```

## Step 1 · Get the files

```bash
git clone https://github.com/shazforiot/n8n-ollama-ai-automations.git
cd n8n-ollama-ai-automations
```
(or download the ZIP from GitHub and unzip it)

## Step 2 · Start everything

**Windows (PowerShell)**
```powershell
# once per machine, if scripts are blocked:
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
.\scripts\start.ps1              # CPU
.\scripts\start.ps1 -Mode gpu    # NVIDIA GPU
.\scripts\start.ps1 -Mode host   # use the Ollama app installed in Windows
```

**WSL2 / Linux / macOS**
```bash
./scripts/start.sh          # CPU
./scripts/start.sh gpu      # NVIDIA GPU
./scripts/start.sh host     # use the Ollama app installed on this computer
```

The script:
1. creates `.env` with random secrets,
2. runs `docker compose up -d`,
3. downloads the two models (first run only, ~2.3 GB),
4. imports the Ollama credential + the 3 workflows,
5. waits until n8n answers and prints **http://localhost:5678**.

<details><summary>Prefer to type the commands yourself?</summary>

```bash
cp .env.example .env          # then edit the change-me values
docker compose up -d          # COMPOSE_PROFILES in .env picks cpu / gpu-nvidia
docker logs -f ollama-pull    # wait for "MODELS READY"
```
</details>

Check the setup at any time:
```bash
./scripts/check.sh            # Windows: .\scripts\check.ps1
```
You should see `llama3.2` and `nomic-embed-text` listed and a short test answer.

## Step 3 · Open n8n

1. Open **http://localhost:5678**
2. Create the owner account (email, name, password). It stays on your computer.
3. On the overview you'll find the 3 workflows, and under **Credentials** the **Local Ollama** credential (`http://ollama:11434`).

## Step 4 · Workflow 1: AI News Digest → Discord

1. Open **1 · AI News Digest → Discord**.
2. *(optional)* Create a Discord webhook: in your server go to **Server Settings → Integrations → Webhooks → New Webhook → Copy Webhook URL**.
3. Double-click **Config** and paste the URL into `discord_webhook`. Leave it empty to just see the result inside n8n. You can also change `feed_url` to any RSS feed.
4. Click **Execute workflow**. Watch each node turn green; the *Summarise with local AI* node takes 20–90 s on a CPU.
5. Open **Format message** to read the digest, and check Discord.
6. To run it every morning at 8:00, click **Publish** (top right).

## Step 5 · Workflow 2: GitHub Issue Triage

1. Open **2 · GitHub Issue Triage**.
2. In **Config**, set `repo` to any public repo, for example `n8n-io/n8n` or `ollama/ollama`.
3. **Execute workflow**. The local model labels each issue (🐞 bug, ✨ feature, ❓ question, 📚 docs), sets a priority and summarises it.
4. Open **Build triage report** to see the table, or check Discord if you set the webhook.

> The GitHub API allows 60 requests per hour without a token, which is plenty for this demo.

## Step 6 · Workflow 3: Chat with your PDFs

1. Put your own PDFs into `files/docs/` (two sample PDFs are already there).
2. Open **3 · Chat with your PDFs**, then click **Execute workflow** while *Load PDFs* is selected. The PDFs are read, split, embedded with `nomic-embed-text` and stored in memory.
3. Click **Open chat** (bottom) and ask, for example:
   - *How many vacation days do I get?*
   - *What's the expense limit without approval?*
   - *How much does the TaskPilot Team plan cost?*
4. The agent calls the `company_docs` tool, finds the right passages and answers with the local model.

> The **Simple Vector Store** keeps data in RAM. After restarting n8n, run *Load PDFs* again. For permanent storage, swap it for Qdrant or PGVector.

---

## Options

**NVIDIA GPU**: much faster answers.
- *Windows*: install the latest NVIDIA driver; Docker Desktop with WSL2 supports GPUs out of the box. Start with `-Mode gpu`.
- *Linux*: install the **NVIDIA Container Toolkit**, then `./scripts/start.sh gpu`.
- Check with `docker exec ollama nvidia-smi`.

**Use the Ollama app installed on your computer** (`host` mode)
1. Install Ollama from ollama.com and run `ollama pull llama3.2` and `ollama pull nomic-embed-text`.
2. Start with `host` mode. n8n then talks to `http://host.docker.internal:11434`.
3. *Linux only*: make Ollama listen on all interfaces (`OLLAMA_HOST=0.0.0.0` in its service settings).

**Bigger or different models**: pull them and pick them in the **Ollama Chat Model** nodes:
```bash
docker exec ollama ollama pull qwen3:4b
```
Then also set `CHAT_MODEL` in `.env` (used for the automatic download).

**Pin versions**: set `N8N_VERSION` (for example `2.46.5`) and `OLLAMA_VERSION` in `.env`, then run `docker compose pull && docker compose up -d`.

## Troubleshooting

| Problem | Fix |
|---|---|
| `port is already allocated` (5678 or 11434) | Another n8n or Ollama is running. Stop it, or change the left port in `docker-compose.yml` (e.g. `"5679:5678"`). If the Ollama app runs on Windows, use `host` mode. |
| *Couldn't connect with these settings* on the Ollama credential | The base URL must be `http://ollama:11434` (Docker) or `http://host.docker.internal:11434` (host mode), **not** `localhost`. |
| `model "llama3.2" not found` | The model download hasn't finished. Run `docker logs ollama-pull`, or `docker exec ollama ollama pull llama3.2`. |
| AI node is very slow or times out | CPU mode is slow on long inputs. Lower `max_stories`, use a GPU, or keep `llama3.2`. |
| Workflows missing after start | They are imported only into an empty database. Run `docker compose run --rm n8n-import`, or import the JSON files via *Workflows → Import from file*. |
| PDF workflow finds no files | The PDFs must be in `files/docs/`. n8n 2.x can only read files under `/home/node/.n8n-files`, and this folder is mounted there. |
| Chat answers "could not find it" | Run *Load PDFs* again (the in-memory store is empty after a restart). |
| Secure cookie error when opening from another device | Use `http://localhost:5678`, or set `N8N_SECURE_COOKIE=false` in `.env` (only on a trusted network). |
| Windows: `start.ps1 cannot be loaded` | `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` |

## Stop / reset

```bash
./scripts/stop.sh            # stop, keep data      (Windows: .\scripts\stop.ps1)
./scripts/stop.sh --reset    # stop and delete workflows, models and database (Windows: -Reset)
```

## Security notes

- Everything listens on `localhost`. Don't expose ports 5678 or 11434 to the internet without HTTPS and authentication.
- The `.env` file holds your secrets; it's in `.gitignore`. Never commit it.
- Keep your Discord webhook URL private; anyone with it can post to your channel.

## Credits & licence

- Demo files: MIT licence (see `LICENSE`).
- [n8n](https://github.com/n8n-io/n8n) uses the Sustainable Use License (free to self-host for your own use); [Ollama](https://github.com/ollama/ollama) is MIT; models keep their own licences (Llama 3.2 Community License, nomic-embed-text Apache 2.0).
- Compose layout inspired by n8n's [self-hosted AI starter kit](https://github.com/n8n-io/self-hosted-ai-starter-kit) (Apache 2.0).
- The sample PDFs describe fictional companies.
- Built for n8n 2.x (checked against the n8n 2.47 source, November 2026).
