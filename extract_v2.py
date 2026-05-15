import json
import re

log_path = r'C:\Users\pacoh\.gemini\antigravity\brain\43a43bcf-5c17-4536-bdc9-0adea84bcbc2\.system_generated\logs\overview.txt'
with open(log_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    try:
        data = json.loads(line)
        content = data.get('content', '')
        if 'PADDLE_WIDTH' in content and 'ENTITY ball' in content:
            print(f"Found at line {i+1}")
            # This might be a view_file output
            # Clean up line numbers if present
            clean_content = re.sub(r'^\d+: ', '', content, flags=re.MULTILINE)
            with open(f'recovered_v2_{i+1}.vhd', 'w', encoding='utf-8') as f_out:
                f_out.write(clean_content)
    except:
        pass
