import json

with open('lib/l10n/app_en.arb', 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []
skip = False
for line in lines:
    if line.startswith('<<<<<<<'):
        skip = True
    elif line.startswith('======='):
        skip = False
    elif line.startswith('>>>>>>>'):
        pass
    else:
        if not skip:
            new_lines.append(line)

content = ''.join(new_lines)
try:
    d = json.loads(content)
except Exception as e:
    print('JSON ERROR:', e)

with open('lib/l10n/app_en.arb', 'w', encoding='utf-8') as f:
    f.write(content)
