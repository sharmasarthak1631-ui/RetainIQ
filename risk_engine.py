import pandas as pd

def calculate_risk(row):
    """
    Applies the MVP Logic Weighted Rule:
    Risk = 2(Tenure<12) + 3(Engagement<6) + 2(Manager Change) + 2(Growth<5) + 1(Pay<5) + 1(Work-Life<5)
    """
    score = 0
    drivers = []

    if row['Tenure (months)'] < 12:
        score += 2
        drivers.append("Low Tenure")
    if row['Engagement (0-10)'] < 6:
        score += 3
        drivers.append("Low Engagement")
    if row['Manager Change'] == 'Yes':
        score += 2
        drivers.append("Manager Change")
    if row['Growth Score (0-10)'] < 5:
        score += 2
        drivers.append("Low Growth")
    if row['Pay Satisfaction (0-10)'] < 5:
        score += 1
        drivers.append("Low Pay")
    if row['Work-Life (0-10)'] < 5:
        score += 1
        drivers.append("Poor Work-Life")

    # Determine Band
    if score >= 6:
        band = "High"
    elif score >= 3:
        band = "Medium"
    else:
        band = "Low"

    return pd.Series([score, band, ", ".join(drivers)])

def process_data(filepath="employee_dataset.csv"):
    df = pd.read_csv(filepath)
    df[['Risk Score', 'Risk Band', 'Top Drivers']] = df.apply(calculate_risk, axis=1)
    return df