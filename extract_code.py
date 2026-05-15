import json

log_path = r'C:\Users\pacoh\.gemini\antigravity\brain\d9944b96-104b-433f-a454-6aa260d3362b\.system_generated\logs\overview.txt'
with open(log_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Line 126 (0-indexed is 125)
target_line = lines[125]
data = json.loads(target_line)
for tc in data.get('tool_calls', []):
    if tc['name'] == 'multi_replace_file_content':
        print(json.dumps(tc['args'], indent=2))
