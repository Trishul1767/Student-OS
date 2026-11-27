from __future__ import annotations

import csv
import io
import os
from datetime import date, datetime, timedelta
from pathlib import Path
from typing import Any

import streamlit as st
from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine

# -----------------------------------------------------------------------------
# Student OS — a personal semester and placement-preparation dashboard.
# -----------------------------------------------------------------------------

st.set_page_config(
    page_title="Student OS | Semester 4",
    page_icon="🎓",
    layout="wide",
    initial_sidebar_state="expanded",
)

APP_VERSION = "0.1.0"
APP_DIR = Path(__file__).resolve().parent

# This curriculum is a starting framework. Edit it as faculty releases the
# official course syllabi and as your placement preparation evolves.
CURRICULUM: dict[str, dict[str, Any]] = {
    "DSA · Python": {
        "group": "Placement core",
        "goal": "Solve unfamiliar Easy/Medium problems by understanding patterns, not memorising code.",
        "focus": "Arrays + hashing; then two pointers, sliding window and prefix sums.",
        "milestones": [
            ("complexity", "Complexity analysis", "Big-O, time vs space, auxiliary space, amortised analysis, recursion complexity."),
            ("arrays_hash", "Arrays, strings and hashing", "Traversal, in-place work, frequency maps, dictionaries, sets, Counter, subarrays and matrices."),
            ("two_pointer", "Two pointers, sliding window and prefix sums", "Fixed/variable windows, left-right pointers, prefix sums and Kadane's algorithm."),
            ("binary_search", "Searching and binary search", "Lower/upper bound, rotated arrays and binary search on answer."),
            ("sorting", "Sorting and selection", "Merge sort, quicksort, counting sort basics and QuickSelect."),
            ("linked_lists", "Linked lists", "Singly/doubly linked lists, reverse, middle, merge, intersections and Floyd cycle detection."),
            ("stacks_queues", "Stacks, queues and deques", "Monotonic stack/queue, balanced brackets, next greater element and sliding-window maximum."),
            ("recursion", "Recursion and backtracking", "Call stack, base cases, recursion trees, subsets, permutations and combinations."),
            ("trees", "Trees and binary search trees", "Traversals, DFS, BFS, height/depth, LCA, diameter and balanced-tree checks."),
            ("heaps", "Heaps and priority queues", "heapq, min/max heap patterns, Top K, Kth largest and merge K sorted lists."),
            ("graphs", "Graphs", "Representations, BFS/DFS, cycle detection, connected components, topological sort and Dijkstra."),
            ("greedy", "Greedy algorithms and intervals", "Activity selection, interval merge, scheduling and knowing when greedy is valid."),
            ("dp", "Dynamic programming", "Memoisation, tabulation, 1D/2D DP, grid DP, knapsack, LCS and LIS."),
            ("bit_trie", "Bit manipulation and tries", "Bit operations, set bits, power-of-two checks, trie insertion/search/prefixes."),
            ("advanced_graphs", "Advanced graphs and range structures", "DSU, Kruskal/Prim, Bellman-Ford, Floyd-Warshall, SCC, segment/Fenwick trees."),
        ],
        "mastery_rule": "For each topic: explain the idea, implement the basics, state complexity, trace manually, solve 2–3 problems without a solution, then try an unfamiliar variation.",
    },
    "Python · OOP": {
        "group": "Engineering foundations",
        "goal": "Write and explain clean Python, especially object-oriented code used in backend projects.",
        "focus": "Rebuild OOP syntax and object behaviour until it feels natural.",
        "milestones": [
            ("python_refresh", "Python refresh", "Functions, scope, mutability, lists/dicts/sets/tuples, comprehensions, type hints and modules."),
            ("classes", "Classes, objects and constructors", "class, object, self, __init__, instance attributes and instance methods."),
            ("inheritance", "Inheritance and super()", "Parent/child classes, overriding, super(), MRO and when inheritance is appropriate."),
            ("encapsulation", "Encapsulation and attribute conventions", "Public names, _protected convention, __name mangling and keeping object state valid."),
            ("properties", "Getters, setters and @property", "Property decorators, validation and Pythonic attribute access."),
            ("method_types", "Instance, class and static methods", "@classmethod, @staticmethod, class attributes and common use cases."),
            ("polymorphism", "Polymorphism and duck typing", "Method overriding, consistent interfaces and protocol-style thinking."),
            ("abstraction", "Abstraction and abstract base classes", "abc, ABC, @abstractmethod and defining required behaviour."),
            ("dunders", "Dunder methods", "__repr__, __str__, __eq__, __len__, __iter__ and object representations."),
            ("errors", "Exceptions, testing and code organisation", "try/except/finally, custom exceptions, imports, venv, pytest and clean modules."),
            ("composition", "Composition and a small OOP project", "Build a small domain model; compare composition with inheritance and refactor thoughtfully."),
        ],
        "mastery_rule": "Do not just memorise syntax. Predict what each line does, run it, inspect object state, and explain why a method belongs on a class or object.",
    },
    "PostgreSQL · DBMS": {
        "group": "Engineering foundations",
        "goal": "Move from basic SELECT/FROM/WHERE to confident relational database design and querying.",
        "focus": "SQL joins, GROUP BY/HAVING and subqueries are the next gaps to close.",
        "milestones": [
            ("sql_basics", "SELECT, WHERE and ordering", "SELECT, FROM, WHERE, DISTINCT, ORDER BY, LIMIT, aliases and NULL basics."),
            ("joins", "Joins", "INNER, LEFT, RIGHT, FULL joins; self joins and understanding row multiplication."),
            ("aggregates", "Aggregates, GROUP BY and HAVING", "COUNT/SUM/AVG/MIN/MAX, grouping, filtering groups and common mistakes."),
            ("subqueries", "Subqueries and CTEs", "IN, EXISTS, correlated subqueries and WITH clauses."),
            ("schema", "Tables, keys and constraints", "Data types, primary/foreign keys, UNIQUE, NOT NULL, CHECK and referential integrity."),
            ("normalisation", "Relational design and normalisation", "Functional dependencies and 1NF/2NF/3NF at a practical level."),
            ("indexes", "Indexes and query plans", "B-tree index intuition, trade-offs and reading EXPLAIN at a beginner level."),
            ("transactions", "Transactions and ACID", "BEGIN/COMMIT/ROLLBACK, isolation intuition and consistency."),
            ("python_db", "Using PostgreSQL from Python", "Connect a Python/FastAPI application safely; parameterised queries and connection handling."),
        ],
        "mastery_rule": "For each SQL concept, write queries against a small schema yourself and explain which rows survive each clause.",
    },
    "FastAPI · Backend": {
        "group": "Backend development",
        "goal": "Build, test and deploy an end-to-end API that you can explain in an interview.",
        "focus": "Start after the Python OOP and SQL foundations are comfortable; learn by building one API.",
        "milestones": [
            ("http", "HTTP and API foundations", "Client/server, methods, status codes, headers, JSON and REST resource design."),
            ("first_api", "First FastAPI application", "Path operations, path/query parameters, request bodies and automatic docs."),
            ("pydantic", "Validation with Pydantic", "Models, types, optional fields, validation and response models."),
            ("routers", "Routers and project structure", "APIRouter, separating routes, schemas, services and configuration."),
            ("errors", "Errors and dependencies", "HTTPException, dependency injection, reusable dependencies and settings."),
            ("crud", "CRUD API", "Create/read/update/delete endpoints and sensible status codes."),
            ("database", "Database integration", "PostgreSQL, SQLAlchemy/SQLModel concepts, sessions and migrations."),
            ("auth", "Authentication and authorisation", "Password hashing, tokens, protected routes and user ownership."),
            ("tests", "Testing and quality", "pytest, TestClient, fixtures, edge cases, linting and type-aware code."),
            ("deploy", "Deploy a complete backend", "Environment variables, production server, logs, database connection and documentation."),
        ],
        "mastery_rule": "Build one feature end-to-end, test normal and failure cases, and be able to explain the request lifecycle.",
    },
    "Git · GitHub": {
        "group": "Engineering workflow",
        "goal": "Work confidently with branches, remotes and collaborative version control.",
        "focus": "You already know basic commit/push; now learn the workflow around them.",
        "milestones": [
            ("git_basics", "Working tree and commits", "status, add, commit, log, diff, restore and .gitignore."),
            ("remote", "Remotes and synchronising", "remote -v, fetch, pull, push and tracking branches."),
            ("branches", "Branches and merging", "branch, switch, merge, merge commits and resolving conflicts."),
            ("pr", "GitHub pull requests", "Feature branches, PR descriptions, reviews and small commits."),
            ("history", "Undoing and rewriting safely", "revert vs reset, amend, cherry-pick and a basic rebase mental model."),
            ("workflow", "A repeatable project workflow", "Issues, branches, meaningful commits, PRs, README and release tags."),
        ],
        "mastery_rule": "Practise each command inside a disposable repository and inspect git status/log after every operation.",
    },
    "Cloud · DevOps": {
        "group": "Later-stage / optional",
        "goal": "Deploy and operate your backend before going deep into orchestration.",
        "focus": "Docker first, then AWS fundamentals and CI/CD; Kubernetes comes after you can deploy a containerised app.",
        "milestones": [
            ("linux", "Linux and networking basics", "Filesystem, permissions, processes, environment variables, ports, DNS and HTTP basics."),
            ("docker", "Docker fundamentals", "Images, containers, Dockerfile, volumes, networks and Compose."),
            ("aws_basics", "AWS foundations", "IAM, regions, EC2, S3, RDS, networking and billing awareness."),
            ("deploy_backend", "Deploy your FastAPI + PostgreSQL project", "Secrets, managed database, networking, logs and a repeatable deployment."),
            ("cicd", "CI/CD with GitHub Actions", "Run tests and checks automatically; understand build and deploy stages."),
            ("observability", "Logs and monitoring", "Application logs, health checks, metrics and diagnosing failures."),
            ("kubernetes", "Kubernetes introduction", "Pods, Deployments, Services, ConfigMaps and Secrets after Docker is comfortable."),
        ],
        "mastery_rule": "Do not collect tool names. Deploy one working service and learn each tool when it solves a real problem.",
    },
    "DAA · University": {
        "group": "Semester 4 academics",
        "goal": "Understand algorithm design and analysis, and connect theory to the DSA work.",
        "focus": "Follow the exact sequence and depth given by your faculty/course outline.",
        "milestones": [
            ("daa_analysis", "Asymptotic analysis and recurrences", "Big-O/Theta/Omega, recurrence solving and analysis of algorithms."),
            ("daa_dc", "Divide and conquer", "Design pattern, recurrence analysis and standard examples."),
            ("daa_greedy", "Greedy method", "Greedy-choice property, proof intuition and course examples."),
            ("daa_dp", "Dynamic programming", "Optimal substructure, overlapping subproblems, memoisation and tabulation."),
            ("daa_graph", "Graph algorithms", "Graph representation, traversals, shortest paths and spanning trees as prescribed."),
            ("daa_revision", "Course problem sets and revision", "Tutorials, previous questions and explaining algorithm correctness."),
        ],
        "mastery_rule": "Keep lecture notes and faculty-provided questions as the authority; this is a planning scaffold, not an official syllabus.",
    },
    "DBMS · University": {
        "group": "Semester 4 academics",
        "goal": "Connect DBMS theory with hands-on PostgreSQL practice.",
        "focus": "Use the faculty syllabus as the authority; practise the matching SQL in PostgreSQL.",
        "milestones": [
            ("dbms_model", "Relational model and algebra", "Relations, tuples, attributes, keys and relational operations."),
            ("dbms_sql", "SQL and joins", "Queries, joins, grouping and subqueries from the course."),
            ("dbms_design", "Functional dependencies and normalisation", "Keys, anomalies and normal forms."),
            ("dbms_tx", "Transactions and concurrency", "ACID, schedules, serialisability and concurrency control as taught."),
            ("dbms_recovery", "Recovery and indexing", "Log/recovery concepts, indexes and query processing as taught."),
            ("dbms_revision", "Labs and exam revision", "SQL lab practice, written answers and past questions."),
        ],
        "mastery_rule": "This is a general tracker. Add or rename milestones to match the official course handout.",
    },
    "OS · University": {
        "group": "Semester 4 academics",
        "goal": "Understand operating-system concepts well enough to explain their trade-offs.",
        "focus": "Study the taught unit first; use the tracker to keep concepts and lab work connected.",
        "milestones": [
            ("os_intro", "OS foundations and processes", "OS roles, process states, PCB and context switching."),
            ("os_threads", "Threads and CPU scheduling", "Threads, scheduling algorithms and evaluation criteria."),
            ("os_sync", "Synchronisation", "Critical section, mutexes, semaphores and classic problems."),
            ("os_deadlocks", "Deadlocks", "Necessary conditions, prevention, avoidance and detection."),
            ("os_memory", "Memory management", "Paging, segmentation and address translation."),
            ("os_vm", "Virtual memory", "Demand paging, page replacement and thrashing."),
            ("os_files", "File systems and I/O", "Files, directories, allocation and I/O concepts as taught."),
            ("os_revision", "OS lab and exam revision", "Trace algorithms, finish lab work and practise written explanations."),
        ],
        "mastery_rule": "Use your lecturer's unit plan and lab manual to decide exact coverage and depth.",
    },
    "Calculus · University": {
        "group": "Semester 4 academics",
        "goal": "Keep mathematical methods current through regular worked practice.",
        "focus": "The listed items are broad placeholders; replace them with the exact course units from your handout.",
        "milestones": [
            ("calc_limits", "Limits and continuity", "Course-specific concepts and representative problem types."),
            ("calc_diff", "Differentiation", "Rules, applications and worked problems in the prescribed syllabus."),
            ("calc_int", "Integration", "Methods, applications and problem practice as prescribed."),
            ("calc_de", "Differential equations", "Methods and applications covered by the course."),
            ("calc_practice", "Problem sets and revision", "Tutorial sheets, formula recall and timed practice."),
        ],
        "mastery_rule": "Replace these placeholders with the official syllabus; do not assume they match every unit in your course.",
    },
}

TRACK_NAMES = list(CURRICULUM.keys())
TRACK_BY_GROUP = {
    "Placement core": ["DSA · Python"],
    "Engineering foundations": ["Python · OOP", "PostgreSQL · DBMS"],
    "Backend development": ["FastAPI · Backend"],
    "Engineering workflow": ["Git · GitHub"],
    "Later-stage / optional": ["Cloud · DevOps"],
    "Semester 4 academics": ["DAA · University", "DBMS · University", "OS · University", "Calculus · University"],
}

SYSTEM_PROMPT = """You are the built-in tutor inside Trishul's personal Student OS. Teach like a patient, rigorous computer-science mentor.

STUDENT CONTEXT
- CSE student at GITAM Hyderabad, entering 4th semester.
- Placement goal: become a strong software-engineering candidate for campus placements; target is ambitious, but never promise a job or salary.
- Current baseline: Python fundamentals and partial OOP; inheritance/super() are familiar at a basic level, but encapsulation, properties/getters/setters, method types and Python OOP syntax need careful reinforcement.
- PostgreSQL: beginner, currently knows basic SELECT/FROM/WHERE; JOINs are familiar at a basic level, while GROUP BY/HAVING/subqueries need work.
- Git: knows basic add/commit/push; needs branch, fetch/pull, merge, conflicts and PR workflow.
- DSA: beginner-to-early-intermediate. Has practised arrays, hashing, dictionaries, sets, Counter and some LeetCode Easy problems. Needs to build reasoning and Big-O fluency.
- Backend path: Python/OOP + SQL -> FastAPI -> end-to-end project -> Docker -> AWS fundamentals -> Kubernetes later, not before the foundations.
- Semester subjects: DAA, DBMS, OS and Calculus. Faculty handouts are the authority for exact syllabus coverage.

TEACHING RULES
1. Start from the student's stated level. Define unfamiliar words before using them. Never assume a prerequisite is known.
2. Explain the intuition first, then a small concrete example, then syntax/code, then trace the code line by line, then complexity/trade-offs when relevant.
3. For code, use readable Python by default unless the student asks for another language. Explain what each important line changes in memory/state.
4. When the student shares an attempt, inspect their actual code carefully. Identify what is correct first, then the exact logical or syntax issue, give a minimal hint/fix, and explain why. Do not silently replace their approach with a completely different solution.
5. For LeetCode/DSA, prefer attempt-first teaching: ask a focused question or give a progressive hint before revealing a full solution. Do not paste a full solution unless they explicitly ask for it.
6. Use dry runs, edge cases and counterexamples. Make time and auxiliary-space complexity precise; do not call input-dependent memory O(1).
7. Be honest about uncertainty and distinguish standard knowledge from the student's official course syllabus.
8. Keep lessons structured but not overwhelming. Teach one concept at a time and end with one small check-for-understanding or practice task.
9. Do not claim the student has mastered a topic just because they have read an explanation. Mastery requires independent recall and problem solving.
10. Tone: encouraging, direct, natural and patient. Avoid hype, generic motivational speeches and unnecessary jargon.
"""


def setting(name: str, default: str | None = None) -> str | None:
    """Read a Streamlit secret first, then an environment variable."""
    try:
        value = st.secrets.get(name, None)
    except Exception:
        value = None
    return value or os.getenv(name, default)


@st.cache_resource(show_spinner=False)
def get_engine() -> Engine:
    database_url = setting("DATABASE_URL")
    if database_url:
        if database_url.startswith("postgres://"):
            database_url = database_url.replace("postgres://", "postgresql://", 1)
        return create_engine(database_url, pool_pre_ping=True, pool_recycle=1800)
    sqlite_path = APP_DIR / "student_os.db"
    return create_engine(
        f"sqlite:///{sqlite_path.as_posix()}",
        connect_args={"check_same_thread": False},
        pool_pre_ping=True,
    )


@st.cache_resource(show_spinner=False)
def initialise_database() -> Engine:
    engine = get_engine()
    is_sqlite = engine.dialect.name == "sqlite"
    id_column = "INTEGER PRIMARY KEY AUTOINCREMENT" if is_sqlite else "BIGSERIAL PRIMARY KEY"
    statements = [
        """CREATE TABLE IF NOT EXISTS progress (
            track VARCHAR(120) NOT NULL,
            item_id VARCHAR(120) NOT NULL,
            done INTEGER NOT NULL DEFAULT 0,
            updated_at VARCHAR(40) NOT NULL,
            PRIMARY KEY (track, item_id)
        )""",
        f"""CREATE TABLE IF NOT EXISTS tasks (
            id {id_column},
            title TEXT NOT NULL,
            track VARCHAR(120) NOT NULL,
            due_date VARCHAR(20) NOT NULL,
            estimate REAL NOT NULL DEFAULT 0.5,
            completed INTEGER NOT NULL DEFAULT 0,
            created_at VARCHAR(40) NOT NULL
        )""",
        f"""CREATE TABLE IF NOT EXISTS study_sessions (
            id {id_column},
            studied_on VARCHAR(20) NOT NULL,
            track VARCHAR(120) NOT NULL,
            minutes INTEGER NOT NULL,
            note TEXT NOT NULL DEFAULT '',
            created_at VARCHAR(40) NOT NULL
        )""",
        f"""CREATE TABLE IF NOT EXISTS chat_messages (
            id {id_column},
            session_key VARCHAR(80) NOT NULL,
            role VARCHAR(20) NOT NULL,
            content TEXT NOT NULL,
            created_at VARCHAR(40) NOT NULL
        )""",
        """CREATE TABLE IF NOT EXISTS app_settings (
            setting_key VARCHAR(120) PRIMARY KEY,
            setting_value TEXT NOT NULL
        )""",
    ]
    with engine.begin() as conn:
        for statement in statements:
            conn.execute(text(statement))
    return engine


ENGINE = initialise_database()


def query_all(sql: str, params: dict[str, Any] | None = None) -> list[dict[str, Any]]:
    with ENGINE.connect() as conn:
        rows = conn.execute(text(sql), params or {}).fetchall()
        return [dict(row._mapping) for row in rows]


def execute(sql: str, params: dict[str, Any] | None = None) -> None:
    with ENGINE.begin() as conn:
        conn.execute(text(sql), params or {})


def progress_map(track: str) -> dict[str, bool]:
    rows = query_all("SELECT item_id, done FROM progress WHERE track = :track", {"track": track})
    return {row["item_id"]: bool(row["done"]) for row in rows}


def set_progress(track: str, item_id: str, done: bool) -> None:
    now = datetime.utcnow().isoformat(timespec="seconds")
    with ENGINE.begin() as conn:
        conn.execute(text("DELETE FROM progress WHERE track=:track AND item_id=:item_id"), {"track": track, "item_id": item_id})
        conn.execute(
            text("INSERT INTO progress(track, item_id, done, updated_at) VALUES (:track, :item_id, :done, :updated_at)"),
            {"track": track, "item_id": item_id, "done": int(done), "updated_at": now},
        )


def add_task(title: str, track: str, due: date, estimate: float) -> None:
    execute(
        "INSERT INTO tasks(title, track, due_date, estimate, completed, created_at) VALUES (:title, :track, :due, :estimate, 0, :created)",
        {"title": title.strip(), "track": track, "due": due.isoformat(), "estimate": estimate, "created": datetime.utcnow().isoformat(timespec="seconds")},
    )


def get_setting_value(key: str, default: str) -> str:
    rows = query_all("SELECT setting_value FROM app_settings WHERE setting_key=:key", {"key": key})
    return str(rows[0]["setting_value"]) if rows else default


def save_setting_value(key: str, value: str) -> None:
    with ENGINE.begin() as conn:
        conn.execute(text("DELETE FROM app_settings WHERE setting_key=:key"), {"key": key})
        conn.execute(text("INSERT INTO app_settings(setting_key, setting_value) VALUES (:key, :value)"), {"key": key, "value": value})


def record_study(track: str, minutes: int, note: str) -> None:
    execute(
        "INSERT INTO study_sessions(studied_on, track, minutes, note, created_at) VALUES (:day, :track, :minutes, :note, :created)",
        {"day": date.today().isoformat(), "track": track, "minutes": minutes, "note": note.strip(), "created": datetime.utcnow().isoformat(timespec="seconds")},
    )


def get_chat() -> list[dict[str, Any]]:
    return query_all("SELECT role, content FROM chat_messages WHERE session_key='main' ORDER BY id DESC LIMIT 30") [::-1]


def save_chat(role: str, content: str) -> None:
    execute(
        "INSERT INTO chat_messages(session_key, role, content, created_at) VALUES ('main', :role, :content, :created)",
        {"role": role, "content": content, "created": datetime.utcnow().isoformat(timespec="seconds")},
    )


def clear_chat() -> None:
    execute("DELETE FROM chat_messages WHERE session_key='main'")


def overall_progress() -> tuple[int, int]:
    total = sum(len(track["milestones"]) for track in CURRICULUM.values())
    rows = query_all("SELECT COUNT(*) AS n FROM progress WHERE done=1")
    done = int(rows[0]["n"]) if rows else 0
    return min(done, total), total


def safe_openai_client():
    api_key = setting("OPENAI_API_KEY")
    if not api_key:
        return None
    from openai import OpenAI
    return OpenAI(api_key=api_key, timeout=90.0, max_retries=2)


def require_password() -> bool:
    password = setting("APP_PASSWORD")
    if not password:
        return True
    if st.session_state.get("authenticated"):
        return True
    st.markdown("<div class='login-wrap'>", unsafe_allow_html=True)
    st.title("Your Student OS")
    st.caption("Private access")
    with st.form("login_form"):
        entered = st.text_input("App password", type="password")
        submitted = st.form_submit_button("Unlock Student OS", use_container_width=True)
    if submitted:
        if entered == password:
            st.session_state["authenticated"] = True
            st.rerun()
        else:
            st.error("That password does not match.")
    st.markdown("</div>", unsafe_allow_html=True)
    return False


# -----------------------------------------------------------------------------
# Visual styling
# -----------------------------------------------------------------------------

st.markdown(
    """
    <style>
      @import url('https://fonts.googleapis.com/css2?family=DM+Mono:wght@400;500&family=DM+Sans:wght@400;500;600;700&family=Space+Grotesk:wght@500;600;700&display=swap');
      html, body, [class*="css"] { font-family: 'DM Sans', sans-serif; }
      .stApp { background: #0b0d12; color: #edf0f7; }
      [data-testid="stSidebar"] { background: #10141d; border-right: 1px solid #252b38; }
      [data-testid="stSidebar"] * { color: #e9edf5; }
      h1, h2, h3 { font-family: 'Space Grotesk', sans-serif !important; letter-spacing: -0.035em; }
      h1 { font-size: 2.25rem !important; }
      h2 { font-size: 1.55rem !important; }
      h3 { font-size: 1.12rem !important; }
      p, li, label { color: #cbd2e0; }
      [data-testid="stMetric"] { background: #141a25; border: 1px solid #293243; padding: 14px 16px; border-radius: 14px; }
      [data-testid="stMetricLabel"] { color: #8995aa !important; }
      [data-testid="stMetricValue"] { color: #f4f6fb !important; font-family: 'Space Grotesk', sans-serif; }
      .hero { background: radial-gradient(circle at 90% 0%, #23385b 0%, #151c2a 33%, #131722 75%); border: 1px solid #2a3850; border-radius: 20px; padding: 26px 28px; margin-bottom: 18px; }
      .eyebrow { font-family: 'DM Mono', monospace; color: #8ca9ff; font-size: .72rem; letter-spacing: .16em; text-transform: uppercase; }
      .hero-title { font-family: 'Space Grotesk', sans-serif; font-size: 2rem; line-height: 1.15; font-weight: 700; color: #f6f8ff; margin: 8px 0; }
      .hero-sub { color: #aeb9cc; max-width: 780px; font-size: .98rem; }
      .panel { background: #131924; border: 1px solid #283244; border-radius: 15px; padding: 17px 18px; margin: 8px 0 13px 0; }
      .panel-title { font-family: 'Space Grotesk', sans-serif; color: #f1f4fb; font-weight: 600; font-size: 1rem; margin-bottom: 6px; }
      .muted { color: #8f9bb0; font-size: .88rem; }
      .tag { display: inline-block; font-family: 'DM Mono', monospace; font-size: .68rem; color: #b9c8ff; border: 1px solid #36496e; background: #17243a; border-radius: 999px; padding: 4px 8px; margin: 2px 4px 2px 0; }
      .small-code { font-family: 'DM Mono', monospace; color: #a9bfff; }
      div.stButton > button, div[data-testid="stFormSubmitButton"] > button { border-radius: 10px; border: 1px solid #435b8a; background: #253b61; color: #f7f9ff; font-weight: 600; }
      div.stButton > button:hover, div[data-testid="stFormSubmitButton"] > button:hover { border-color: #8daaff; color: white; }
      [data-baseweb="tab-list"] { gap: 8px; }
      [data-baseweb="tab"] { background: #141a25; border-radius: 9px 9px 0 0; padding: 8px 14px; }
      hr { border-color: #2a3343; }
      .stAlert { border-radius: 12px; }
      .login-wrap { max-width: 520px; margin: 12vh auto; }
    </style>
    """,
    unsafe_allow_html=True,
)

if not require_password():
    st.stop()

# -----------------------------------------------------------------------------
# Sidebar navigation and shared settings
# -----------------------------------------------------------------------------

st.sidebar.markdown("<div class='eyebrow'>PERSONAL LEARNING SYSTEM</div>", unsafe_allow_html=True)
st.sidebar.markdown("# Student OS")
st.sidebar.caption(f"Semester 4 · v{APP_VERSION}")
page = st.sidebar.radio(
    "Workspace",
    ["Command Center", "Roadmaps", "Daily Planner", "AI Tutor", "Settings & Export"],
    label_visibility="collapsed",
)
st.sidebar.divider()

daily_target_default = get_setting_value("daily_target_hours", "4")
try:
    daily_target = float(daily_target_default)
except ValueError:
    daily_target = 4.0
st.sidebar.metric("Daily study target", f"{daily_target:g} hrs")
st.sidebar.caption("Change this in Settings. The 4-hour default is only a starting point.")

# Data source indicator
if ENGINE.dialect.name == "sqlite":
    st.sidebar.warning("Local SQLite storage\n\nGreat for testing on your laptop. Configure DATABASE_URL (PostgreSQL) before relying on hosted persistence.")
else:
    st.sidebar.success("PostgreSQL connected")

# -----------------------------------------------------------------------------
# COMMAND CENTER
# -----------------------------------------------------------------------------

if page == "Command Center":
    done, total = overall_progress()
    tasks_open = query_all("SELECT COUNT(*) AS n FROM tasks WHERE completed=0")
    due_today = query_all("SELECT COUNT(*) AS n FROM tasks WHERE completed=0 AND due_date<=:today", {"today": date.today().isoformat()})
    today_minutes = query_all("SELECT COALESCE(SUM(minutes),0) AS n FROM study_sessions WHERE studied_on=:today", {"today": date.today().isoformat()})
    week_minutes = query_all("SELECT COALESCE(SUM(minutes),0) AS n FROM study_sessions WHERE studied_on>=:start", {"start": (date.today()-timedelta(days=6)).isoformat()})

    st.markdown(
        "<div class='hero'><div class='eyebrow'>SEMESTER 04 / PLACEMENT FOUNDATION</div>"
        "<div class='hero-title'>Build the engineer.<br>One focused session at a time.</div>"
        "<div class='hero-sub'>Your personal command centre for DSA, Python, databases, backend engineering and GITAM semester subjects. Track evidence of learning — not just hours spent.</div></div>",
        unsafe_allow_html=True,
    )
    c1, c2, c3, c4 = st.columns(4)
    c1.metric("Roadmap checkpoints", f"{done}/{total}", "marked complete")
    c2.metric("Open tasks", str(tasks_open[0]["n"]))
    c3.metric("Due today / overdue", str(due_today[0]["n"]))
    c4.metric("Study time today", f"{today_minutes[0]['n']/60:.1f} h")

    st.subheader("Your current priorities")
    p1, p2, p3 = st.columns(3)
    with p1:
        st.markdown("<div class='panel'><div class='tag'>01 · DSA</div><div class='panel-title'>Arrays + hashing</div><div class='muted'>Frequency maps, sets/dicts, two pointers, sliding window and Big-O.</div></div>", unsafe_allow_html=True)
    with p2:
        st.markdown("<div class='panel'><div class='tag'>02 · PYTHON</div><div class='panel-title'>OOP syntax + object model</div><div class='muted'>Inheritance, super(), encapsulation, properties and method types.</div></div>", unsafe_allow_html=True)
    with p3:
        st.markdown("<div class='panel'><div class='tag'>03 · DATABASE</div><div class='panel-title'>SQL query fluency</div><div class='muted'>Build from SELECT/WHERE to JOIN, GROUP BY, HAVING and subqueries.</div></div>", unsafe_allow_html=True)

    st.subheader("Open tasks")
    tasks = query_all("SELECT id, title, track, due_date, estimate FROM tasks WHERE completed=0 ORDER BY due_date ASC, id DESC LIMIT 8")
    if not tasks:
        st.info("Your task list is empty. Open **Daily Planner** and add the next small, concrete action.")
    else:
        for task in tasks:
            due = date.fromisoformat(task["due_date"])
            overdue = due < date.today()
            label = f"{'⚠️ ' if overdue else ''}{task['title']}  ·  {task['track']}  ·  {due.strftime('%d %b')}  ·  {task['estimate']:g}h"
            col_a, col_b = st.columns([7, 1])
            col_a.write(label)
            if col_b.button("Done", key=f"dash_done_{task['id']}"):
                execute("UPDATE tasks SET completed=1 WHERE id=:id", {"id": task["id"]})
                st.rerun()

    st.subheader("Weekly study rhythm")
    st.metric("Logged in the last 7 days", f"{week_minutes[0]['n']/60:.1f} hours", f"Target reference: {daily_target:g} h/day")
    st.caption("Log actual focused time in Daily Planner. Do not inflate time; a 45-minute deep session is more useful than a distracted 3-hour block.")

    st.subheader("Your sequence")
    st.markdown("**Now:** DSA arrays/hashing + Python OOP repair + SQL fundamentals.  \n**Next:** FastAPI foundations and a small CRUD API.  \n**After a working backend:** Docker → AWS fundamentals → CI/CD → Kubernetes introduction.")
    st.warning("Do not try to master FastAPI, AWS, Docker and Kubernetes simultaneously. The order above protects your fundamentals and gives you a real project to deploy.")

# -----------------------------------------------------------------------------
# ROADMAPS
# -----------------------------------------------------------------------------

elif page == "Roadmaps":
    st.title("Roadmaps")
    st.caption("Check off a milestone only when you can demonstrate it without simply rereading the notes.")
    selected_track = st.selectbox("Choose a learning track", TRACK_NAMES)
    details = CURRICULUM[selected_track]
    status = progress_map(selected_track)
    milestones = details["milestones"]
    completed_count = sum(1 for item_id, _, _ in milestones if status.get(item_id, False))
    percentage = completed_count / len(milestones) if milestones else 0

    st.markdown(f"<span class='tag'>{details['group']}</span>", unsafe_allow_html=True)
    st.subheader(selected_track)
    st.write(details["goal"])
    st.info(f"**Current focus:** {details['focus']}")
    st.progress(percentage, text=f"{completed_count} of {len(milestones)} milestones complete · {percentage:.0%}")

    if selected_track == "Python · OOP":
        with st.expander("A few things I noticed in your pasted OOP code", expanded=True):
            st.markdown("""
            - Your `Vehicle` → `Truck` inheritance and `super().__init__(...)` use are a good starting point.
            - In `Dog`, `walk()` checks `self.walking`, but the constructor creates `self.waking`. Those names do not match, so `walk()` can raise `AttributeError`.
            - In `Person`, `self.awake` is assigned twice. The repeated assignment is unnecessary.
            - `print(p.sleep())` prints the method's own message and then `None`, because `sleep()` prints but has no `return` statement.
            - `__age` uses Python name-mangling. It discourages direct access, but it is not security-grade privacy. We will learn `@property` for controlled, Pythonic access.
            """)
            st.caption("We'll use your Vehicle/Person/Dog examples as exercises in the OOP tutor, rather than replacing them with unrelated examples.")

    if selected_track == "DAA · University" or selected_track.endswith("· University"):
        st.caption("University tracker note: use your faculty's official handout, lecture sequence and lab manual as the source of truth. The checkpoints here are scaffolding, not an official syllabus.")

    for item_id, title, description in milestones:
        checked = status.get(item_id, False)
        c1, c2 = st.columns([0.7, 10])
        new_value = c1.checkbox(" ", value=checked, key=f"progress_{selected_track}_{item_id}", label_visibility="collapsed")
        c2.markdown(f"**{title}**  {'<span class=tag>DONE</span>' if checked else ''}\n\n<small style='color:#9aa6ba'>{description}</small>", unsafe_allow_html=True)
        if new_value != checked:
            set_progress(selected_track, item_id, new_value)
            st.rerun()

    st.divider()
    st.markdown("**Mastery standard**")
    st.write(details["mastery_rule"])
    if selected_track == "DSA · Python":
        st.markdown("**DSA order from your roadmap:** Complexity → Arrays/Strings/Hashing → Two Pointers/Sliding Window/Prefix Sums → Binary Search → Sorting/Selection → Linked Lists → Stacks/Queues → Recursion/Backtracking → Trees → Heaps → Graphs → Greedy → DP → advanced topics.")

# -----------------------------------------------------------------------------
# DAILY PLANNER
# -----------------------------------------------------------------------------

elif page == "Daily Planner":
    st.title("Daily Planner")
    st.caption("Turn a big syllabus into the next action you can finish.")
    with st.form("add_task_form", clear_on_submit=True):
        st.subheader("Add a task")
        title = st.text_input("What exactly will you do?", placeholder="Example: Solve one Two Sum variation without looking at notes")
        col1, col2, col3 = st.columns(3)
        track = col1.selectbox("Track", TRACK_NAMES)
        due = col2.date_input("Due date", value=date.today())
        estimate = col3.selectbox("Estimated focus time", [0.25, 0.5, 0.75, 1.0, 1.5, 2.0], index=1, format_func=lambda x: f"{x:g} hour{'s' if x != 1 else ''}")
        submitted = st.form_submit_button("Add to my plan", use_container_width=True)
    if submitted:
        if title.strip():
            add_task(title, track, due, float(estimate))
            st.success("Task added.")
            st.rerun()
        else:
            st.error("Give the task a clear action, not just a topic name.")

    st.divider()
    st.subheader("Tasks")
    filter_value = st.selectbox("Show", ["All open tasks", "Due today / overdue", "Completed tasks"])
    if filter_value == "All open tasks":
        tasks = query_all("SELECT id,title,track,due_date,estimate,completed FROM tasks WHERE completed=0 ORDER BY due_date,id")
    elif filter_value == "Due today / overdue":
        tasks = query_all("SELECT id,title,track,due_date,estimate,completed FROM tasks WHERE completed=0 AND due_date<=:today ORDER BY due_date,id", {"today": date.today().isoformat()})
    else:
        tasks = query_all("SELECT id,title,track,due_date,estimate,completed FROM tasks WHERE completed=1 ORDER BY id DESC LIMIT 50")

    if not tasks:
        st.info("No tasks in this view yet.")
    for task in tasks:
        due_date = date.fromisoformat(task["due_date"])
        is_overdue = (not task["completed"]) and due_date < date.today()
        left, mid, right = st.columns([0.7, 7, 1.4])
        with left:
            st.write("✅" if task["completed"] else ("⚠️" if is_overdue else "◻️"))
        with mid:
            st.markdown(f"**{task['title']}**")
            st.caption(f"{task['track']} · {due_date.strftime('%a, %d %b %Y')} · {task['estimate']:g}h")
        with right:
            if not task["completed"]:
                if st.button("Complete", key=f"complete_{task['id']}"):
                    execute("UPDATE tasks SET completed=1 WHERE id=:id", {"id": task["id"]})
                    st.rerun()
            else:
                if st.button("Reopen", key=f"reopen_{task['id']}"):
                    execute("UPDATE tasks SET completed=0 WHERE id=:id", {"id": task["id"]})
                    st.rerun()

    st.divider()
    st.subheader("Log a focused study session")
    with st.form("study_log_form", clear_on_submit=True):
        l1, l2 = st.columns(2)
        study_track = l1.selectbox("What did you work on?", TRACK_NAMES, key="log_track")
        minutes = l2.number_input("Focused minutes", min_value=5, max_value=600, value=45, step=5)
        note = st.text_input("What did you actually complete?", placeholder="Example: Understood why dict lookup is average O(1); solved one new problem")
        log_submit = st.form_submit_button("Log session", use_container_width=True)
    if log_submit:
        record_study(study_track, int(minutes), note)
        st.success("Study session logged.")
        st.rerun()

    sessions = query_all("SELECT studied_on,track,minutes,note FROM study_sessions ORDER BY id DESC LIMIT 10")
    if sessions:
        st.subheader("Recent sessions")
        for session in sessions:
            st.write(f"**{session['studied_on']} · {session['track']} · {session['minutes']} min**")
            if session["note"]:
                st.caption(session["note"])

# -----------------------------------------------------------------------------
# AI TUTOR
# -----------------------------------------------------------------------------

elif page == "AI Tutor":
    st.title("AI Tutor")
    st.caption("A patient tutor that starts from your current level, traces code and helps you reason independently.")

    api_key = setting("OPENAI_API_KEY")
    if not api_key:
        st.warning("AI is not connected yet. Add OPENAI_API_KEY to Streamlit secrets to enable the tutor. The rest of Student OS works without it.")
        st.code('OPENAI_API_KEY = "your-api-key"\nOPENAI_MODEL = "gpt-5.5"', language="toml")
        st.markdown("See [Streamlit secrets setup](https://docs.streamlit.io/deploy/concepts/secrets) before deploying. Never paste your key into app.py or commit it to GitHub.")

    t1, t2 = st.columns([1, 1])
    with t1:
        tutor_track = st.selectbox("What are we learning?", TRACK_NAMES, index=0)
    with t2:
        tutor_mode = st.selectbox("How should the tutor help?", ["Explain from scratch", "Debug my code", "Review my attempt", "Quiz me", "Plan my next study session"])

    code = st.text_area("Paste code or your attempt (optional)", height=150, placeholder="Paste your Python / SQL / DSA attempt here...")
    chat_rows = get_chat()
    for item in chat_rows:
        with st.chat_message(item["role"]):
            st.markdown(item["content"])

    prompt = st.chat_input("Ask your tutor... e.g. Explain @property from zero using my Person class")
    if prompt:
        if not api_key:
            st.error("Add OPENAI_API_KEY in Secrets first, then restart or rerun the app.")
        else:
            user_message = f"TRACK: {tutor_track}\nMODE: {tutor_mode}\nSTUDENT REQUEST: {prompt}"
            if code.strip():
                user_message += f"\n\nSTUDENT'S CODE / ATTEMPT:\n```\n{code}\n```"
            save_chat("user", user_message)
            with st.chat_message("user"):
                st.markdown(prompt)
                if code.strip():
                    st.caption("Code attached to this question.")
            mode_guidance = {
                "Explain from scratch": "Teach the selected topic from the absolute prerequisites, with intuition, example, syntax, trace and one small check.",
                "Debug my code": "Debug the exact submitted code. Explain the first actual failure and the minimal fix before suggesting refactors.",
                "Review my attempt": "Review correctness, edge cases, complexity and readability. Give a progressive hint before a full rewrite.",
                "Quiz me": "Ask only one question at a time. Wait for the student's answer before revealing the explanation.",
                "Plan my next study session": "Choose a realistic next session based on the stated baseline. Give a small sequence and a clear finish condition.",
            }
            instructions = SYSTEM_PROMPT + f"\n\nCURRENT TRACK: {tutor_track}.\nCURRENT MODE: {tutor_mode}.\nMODE INSTRUCTION: {mode_guidance[tutor_mode]}"
            context_rows = get_chat()[-14:]
            try:
                from openai import OpenAI
                client = OpenAI(api_key=api_key, timeout=90.0, max_retries=2)
                with st.chat_message("assistant"):
                    with st.spinner("Thinking through it..."):
                        response = client.responses.create(
                            model=setting("OPENAI_MODEL", "gpt-5.5"),
                            instructions=instructions,
                            input=[{"role": row["role"], "content": row["content"]} for row in context_rows],
                        )
                    answer = response.output_text or "I couldn't produce a text response. Please try again."
                    st.markdown(answer)
                save_chat("assistant", answer)
            except Exception as exc:
                st.error(f"The AI request failed: {exc}")
                st.caption("Check that the API key is valid, API billing is enabled, and OPENAI_MODEL is available to your account.")

    with st.expander("How this tutor is instructed to teach"):
        st.markdown("- Starts from the level you have actually described.\n- Explains intuition before syntax.\n- Traces code and checks edge cases.\n- Prefers hints before complete LeetCode answers.\n- Reviews your exact attempt instead of replacing it blindly.\n- Keeps official university syllabi separate from general topic suggestions.")
    if st.button("Clear tutor conversation", type="secondary"):
        clear_chat()
        st.rerun()

# -----------------------------------------------------------------------------
# SETTINGS AND EXPORT
# -----------------------------------------------------------------------------

elif page == "Settings & Export":
    st.title("Settings & Export")
    st.caption("Tune the system and keep a copy of your progress.")
    current_target = float(get_setting_value("daily_target_hours", "4"))
    new_target = st.slider("Daily focused-study target (hours)", min_value=1.0, max_value=8.0, value=max(1.0, min(8.0, current_target)), step=0.5)
    if st.button("Save study target"):
        save_setting_value("daily_target_hours", str(new_target))
        st.success("Study target saved.")
        st.rerun()

    st.subheader("AI configuration")
    if setting("OPENAI_API_KEY"):
        st.success(f"API key detected · model: {setting('OPENAI_MODEL', 'gpt-5.5')}")
    else:
        st.warning("No API key detected. Add OPENAI_API_KEY in your local secrets file or Streamlit Cloud app secrets.")
    st.code('OPENAI_API_KEY = "your-api-key"\nOPENAI_MODEL = "gpt-5.5"\nAPP_PASSWORD = "choose-a-strong-private-password"\nDATABASE_URL = "postgresql+psycopg://USER:PASSWORD@HOST:5432/DATABASE"', language="toml")
    st.caption("Only add DATABASE_URL once you have a PostgreSQL database. The app uses local SQLite when it is absent.")

    st.subheader("Export your data")
    progress_rows = query_all("SELECT track,item_id,done,updated_at FROM progress ORDER BY track,item_id")
    task_rows = query_all("SELECT id,title,track,due_date,estimate,completed,created_at FROM tasks ORDER BY id")
    study_rows = query_all("SELECT studied_on,track,minutes,note,created_at FROM study_sessions ORDER BY id")
    export_payload = {
        "exported_at": datetime.utcnow().isoformat(timespec="seconds"),
        "progress": progress_rows,
        "tasks": task_rows,
        "study_sessions": study_rows,
    }
    st.download_button("Download progress backup (JSON)", data=__import__("json").dumps(export_payload, indent=2), file_name="student_os_backup.json", mime="application/json")

    st.subheader("Deployment and privacy checklist")
    st.markdown("""
    1. Keep `OPENAI_API_KEY` in Streamlit Secrets, never in source code or GitHub.
    2. Set `APP_PASSWORD` before deploying this personal app. It is a simple shared-password gate, not full multi-user authentication.
    3. Use a PostgreSQL `DATABASE_URL` for persistent hosted progress. Local SQLite is intended for development/testing.
    4. Do not upload private credentials, personal records or sensitive documents into the tutor.
    5. The API key is billed by the API provider separately from a ChatGPT subscription. Start with short questions and check usage/billing limits.
    """)
    st.markdown("[Streamlit Secrets documentation](https://docs.streamlit.io/deploy/concepts/secrets) · [OpenAI Python SDK](https://github.com/openai/openai-python)")

st.sidebar.divider()
st.sidebar.caption("Built around your Semester 4 plan. Edit the roadmap as your real course handouts arrive.")
