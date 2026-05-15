import sys
with open('VGA_BALL.bdf', 'r') as f:
    lines = f.readlines()

out = []
i = 0
while i < len(lines):
    if '(port' in lines[i] and 'SW0' in ''.join(lines[i:i+7]):
        i += 7
    else:
        out.append(lines[i])
        i += 1

with open('VGA_BALL.bdf', 'w') as f:
    f.writelines(out)
