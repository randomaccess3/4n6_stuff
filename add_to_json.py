import json
import argparse
import os
import re

def to_pascal_case(s):
    s = re.sub(r'[^a-zA-Z0-9]', ' ', s)
    parts = s.split()
    return ''.join(word.capitalize() for word in parts)

def add_elements_to_jsonl(input_file, output_file, elements_to_add):
    # Convert element names in elements_to_add to PascalCase
    elements_to_add_pascal = {to_pascal_case(k): v for k, v in elements_to_add.items()}
    
    with open(input_file, 'r') as infile, open(output_file, 'w') as outfile:
        for line_num, line in enumerate(infile, start=1):
            try:
                entry = json.loads(line)
                # Convert existing element names to PascalCase
                entry_pascal = {to_pascal_case(k): v for k, v in entry.items()}
                # Update the entry with new elements (without converting new elements to PascalCase)
                entry_pascal.update(elements_to_add)
                outfile.write(json.dumps(entry_pascal) + '\n')
            except json.JSONDecodeError as e:
                print(f"Error decoding JSON on line {line_num}: {e}")
                continue

def main():
    elements_to_add = {
        'kape_hostname': "test",
        'kape_sourcepath': 'srum'
    }
    inputname = 'Network Data Usage.jsonl'
    outputname = 'Network Data Usage_fixed.jsonl'
    add_elements_to_jsonl(inputname, outputname, elements_to_add)

if __name__ == '__main__':
    main()