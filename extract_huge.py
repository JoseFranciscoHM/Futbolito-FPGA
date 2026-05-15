import json

log_path = r'C:\Users\pacoh\.gemini\antigravity\brain\43a43bcf-5c17-4536-bdc9-0adea84bcbc2\.system_generated\logs\overview.txt'
with open(log_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

data = json.loads(lines[51]) # Line 52
print(json.dumps(data, indent=2))
