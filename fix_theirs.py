import re
with open('lib/l10n/app_en.arb', 'r', encoding='utf-8') as f:
    text = f.read()

# Replace the conflict block with the 'theirs' part (from ======= to >>>>>>>)
pattern = r'<<<<<<< HEAD.*?=======\n(.*?)\n>>>>>>> origin/flutter'
match = re.search(pattern, text, flags=re.DOTALL)
if match:
    theirs_content = match.group(1)
    new_text = text[:match.start()] + theirs_content + text[match.end():]
    
    import json
    new_text = new_text.strip()
    # The file starts with { but the conflict might have removed it if it was at the very start?
    if not new_text.startswith('{'):
        new_text = '{\n' + new_text
    
    data = json.loads(new_text)
    data['ccs811AirQuality'] = 'CCS811 Air Quality'
    
    with open('lib/l10n/app_en.arb', 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=4)
        print("Success")
else:
    print("Conflict not found")
