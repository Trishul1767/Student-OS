# Student OS — Semester 4

A personal Streamlit dashboard for Trishul's CSE Semester 4 and placement preparation.

## What's included

- **Command Center:** overall roadmap progress, task queue, study-time log and current priorities.
- **Roadmaps:** DSA, Python/OOP, PostgreSQL, FastAPI, Git/GitHub, Cloud/DevOps and semester subjects (DAA, DBMS, OS, Calculus).
- **Daily Planner:** add tasks, due dates, estimated time, completion and actual focused-study logs.
- **AI Tutor:** persistent chat using the OpenAI Responses API, with teaching modes for explanations, debugging, attempt review, quizzes and session planning.
- **Settings & Export:** daily study target, configuration guidance and JSON backup.

The curriculum is a **personal planning scaffold**, not an official GITAM course syllabus. Replace university checkpoints with the faculty handouts and lab manuals when available.

## Run locally (Windows / PowerShell)

```powershell
cd student_os
py -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
Copy-Item .streamlit\secrets.toml.example .streamlit\secrets.toml
notepad .streamlit\secrets.toml
streamlit run app.py
```

Paste your API key into `.streamlit/secrets.toml` only if you want the AI Tutor enabled. The rest of the dashboard works without an API key.

## Run locally (Linux / WSL)

```bash
cd student_os
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .streamlit/secrets.toml.example .streamlit/secrets.toml
nano .streamlit/secrets.toml
streamlit run app.py
```
