# RETAINIQ — HR Retention Decision Support System

RETAINIQ is an AI-powered human resources intelligence dashboard designed to predict attrition, identify key turnover drivers, simulate financial outcomes of retention programs, and provide conversational advisory support for HR teams.

---

## Architecture Overview

The system consists of two primary layers:

1. **Backend (Python / FastAPI):**
* **`risk_engine.py`**: Computes attrition risk scores and classifies employees into bands using weighted rules based on tenure, engagement, growth opportunities, compensation satisfaction, work-life balance, and recent managerial changes.
* **`api.py`**: REST API exposing metrics, employee records, an intervention simulator, stay-interview logging, and integration with the Gemini API for natural-language retention advisory.
* **`employee_dataset.csv`**: Baseline employee data source.


2. **Frontend (Flutter):**
* Cross-platform desktop/web UI (`retainiq_app/`) built with Flutter, featuring analytics dashboards (`fl_chart`), directory search and filters, an interactive intervention impact calculator, and an AI HR advisory console.



---

## Risk Scoring Model

The risk engine applies a weighted point rubric:

$$\text{Risk Score} = 2(\text{Tenure} < 12\text{m}) + 3(\text{Engagement} < 6) + 2(\text{Manager Change}) + 2(\text{Growth} < 5) + 1(\text{Pay} < 5) + 1(\text{Work-Life} < 5)$$

### Risk Bands

* **High Risk**: Score $\ge 6$ (assumed baseline attrition replacement cost: $100,000 / employee)
* **Medium Risk**: $3 \le \text{Score} < 6$
* **Low Risk**: $\text{Score} < 3$

---

## API Endpoints

| Method | Endpoint | Description |
| --- | --- | --- |
| `GET` | `/api/dashboard` | KPI totals (High, Medium, Low, Cost at Risk), risk breakdown by department, top attrition drivers, and top at-risk employees. |
| `GET` | `/api/employees` | Complete employee directory sorted by risk score. |
| `POST` | `/api/chatbot` | Accepts `{"message": "..."}` and generates diagnosis, stay-interview questions, and intervention tactics via Gemini. |
| `POST` | `/api/simulate` | Simulates risk band reductions and cost savings based on chosen interventions (`Career Path`, `Manager Coaching`, `Comp Review`). |
| `GET` | `/api/logs` | Retrieves active retention action plans. |
| `POST` | `/api/log_action` | Assigns an intervention to an employee, reduces their risk score by 3 points, and schedules a 30-day pulse check. |

---

## Getting Started

### 1. Prerequisites

* Python 3.10+
* Flutter 3.27+ / Dart 3.13+
* A Google Gemini API Key

---

### 2. Backend Setup

1. **Clone the repository and navigate to the root directory:**
```bash
cd retainiq

```


2. **Create and activate a virtual environment:**
```bash
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

```


3. **Install dependencies:**
```bash
pip install fastapi uvicorn pandas google-genai pydantic

```


4. **Export your Gemini API Key:**
```bash
export GEMINI_API_KEY="your-api-key-here"
# On Windows PowerShell:
# $env:GEMINI_API_KEY="your-api-key-here"

```


5. **Start the API server:**
```bash
uvicorn api:app --reload --port 8000

```


The backend will be available at `[http://127.0.0.1:8000](http://127.0.0.1:8000)`.

---

### 3. Frontend Setup (Flutter)

1. **Navigate to the Flutter app directory:**
```bash
cd retainiq_app

```


2. **Fetch dependencies:**
```bash
flutter pub get

```


3. **Run the application:**
* **macOS Desktop:**
```bash
flutter run -d macos

```


* **Chrome / Web:**
```bash
flutter run -d chrome

```


* **Windows Desktop:**
```bash
flutter run -d windows

```





---

## Project Structure

```text
├── api.py                    # FastAPI server & Gemini integration
├── risk_engine.py            # Rule-based risk calculation logic
├── employee_dataset.csv      # Sample HR metrics dataset
└── retainiq_app/             # Flutter frontend application
    ├── lib/
    │   └── main.dart         # Dashboard, Directory, and AI Agent views
    ├── pubspec.yaml          # Flutter dependencies (fl_chart, http, etc.)
    └── macos/ / web/ / windows/ / android/ / ios/

```
