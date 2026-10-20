from fastapi import FastAPI
import os
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import pandas as pd
import json
from google import genai # NEW IMPORT SYNTAX
from risk_engine import process_data
from datetime import datetime, timedelta

# --- CONFIGURE GEMINI ---

client = genai.Client(api_key=os.environ.get("GEMINI_API_KEY"))
app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

global_df = process_data("employee_dataset.csv")
action_logs = []

@app.get("/api/dashboard")
def get_dashboard():
    global global_df
    df = global_df.copy()
    high_risk_df = df[df['Risk Band'] == 'High']
    
    high_risk = len(high_risk_df)
    baseline_cost = high_risk * 100000
    
    dept_counts = high_risk_df['Department'].value_counts().to_dict()
    
    drivers_list = []
    for drivers in high_risk_df['Top Drivers']:
        drivers_list.extend([d.strip() for d in str(drivers).split(",") if d.strip()])
    driver_counts = pd.Series(drivers_list).value_counts().head(5).to_dict()
    
    top_employees = df.sort_values(by='Risk Score', ascending=False).head(5).to_dict(orient='records')
    
    return {
        "kpis": {"high": high_risk, "medium": len(df[df['Risk Band'] == 'Medium']), "low": len(df[df['Risk Band'] == 'Low']), "cost": baseline_cost},
        "chart": dept_counts,
        "driver_chart": driver_counts,
        "table": top_employees
    }

@app.get("/api/employees")
def get_all_employees():
    global global_df
    all_emps = global_df.sort_values(by='Risk Score', ascending=False).to_dict(orient='records')
    return {"employees": all_emps}

class ChatRequest(BaseModel):
    message: str

@app.post("/api/chatbot")
def chat(req: ChatRequest):
    global global_df
    
    df_summary = global_df[['Employee ID', 'Department', 'Risk Band', 'Risk Score', 'Top Drivers']].to_csv(index=False)
    
    prompt = f"""
    You are an elite HR Retention AI Advisor for a system called RETAINIQ.
    Here is the current real-time employee dataset:
    {df_summary}
    
    The HR manager asks: "{req.message}"
    
    Analyze the dataset to answer their question. 
    You MUST respond ONLY in raw JSON format with exactly these keys:
    - "diagnosis": A 1-sentence analysis of the problem or situation.
    - "questions": A list of 3 specific stay interview questions the HR manager should ask.
    - "action": A 1-5 word suggested intervention (e.g. "Career Path", "Comp Review", "Manager Coaching").
    
    Do NOT include markdown formatting like ```json.
    """
    
    try:
        # NEW GENERATION SYNTAX
        response = client.models.generate_content(
            model='gemini-3.5-flash-lite',
            contents=prompt,
        )
        raw_text = response.text.strip().replace('```json', '').replace('```', '')
        ai_data = json.loads(raw_text)
        return ai_data
    except Exception as e:
        print("Gemini Error:", e)
        return {
            "diagnosis": "Error processing request. Ensure your Gemini API key is valid.",
            "questions": ["Check terminal for errors.", "Did you insert your API key?"],
            "action": "System Error"
        }

class SimRequest(BaseModel):
    intervention: str

@app.post("/api/simulate")
def simulate(req: SimRequest):
    global global_df
    df = global_df.copy() 
    baseline_cost = len(df[df['Risk Band'] == 'High']) * 100000
    intervention = req.intervention
    
    for index, row in df.iterrows():
        drivers = str(row['Top Drivers'])
        if intervention == "Career Path" and "Low Growth" in drivers:
            df.at[index, 'Risk Score'] = max(0, row['Risk Score'] - 2)
        elif intervention == "Manager Coaching" and "Manager Change" in drivers:
            df.at[index, 'Risk Score'] = max(0, row['Risk Score'] - 2)
        elif intervention == "Comp Review" and "Low Pay" in drivers:
            df.at[index, 'Risk Score'] = max(0, row['Risk Score'] - 1)
            
        score = df.at[index, 'Risk Score']
        df.at[index, 'Risk Band'] = "High" if score >= 6 else "Medium" if score >= 3 else "Low"
        
    new_high_risk = len(df[df['Risk Band'] == 'High'])
    return {"new_high_risk": new_high_risk, "savings": baseline_cost - (new_high_risk * 100000)}

class LogRequest(BaseModel):
    emp_id: str
    intervention: str
    owner: str

@app.get("/api/logs")
def get_logs():
    return {"logs": action_logs}

@app.post("/api/log_action")
def log_action(req: LogRequest):
    global global_df
    follow_up_date = (datetime.now() + timedelta(days=30)).strftime("%Y-%m-%d")
    
    if req.emp_id in global_df['Employee ID'].values:
        idx = global_df[global_df['Employee ID'] == req.emp_id].index[0]
        current_score = global_df.at[idx, 'Risk Score']
        new_score = max(0, current_score - 3) 
        global_df.at[idx, 'Risk Score'] = new_score
        global_df.at[idx, 'Risk Band'] = "High" if new_score >= 6 else "Medium" if new_score >= 3 else "Low"

    action_logs.insert(0, {"emp_id": req.emp_id, "intervention": req.intervention, "owner": req.owner, "follow_up": follow_up_date, "status": "Pending"}) 
    return {"logs": action_logs}
