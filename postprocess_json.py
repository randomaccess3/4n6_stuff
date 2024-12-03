import json
import os
import argparse

"""
Script to process JSON files by adding a new entry to each element in the JSON array.
Version: 1.0
Author: Phill Moore
Date: 2024-12-03
Description:
- Reads a JSON file or a directory containing JSON files.
- Adds a new entry to each element in the JSON array.
- The new entry key is "item_hostname" and its value is provided as an argument.
- Saves the modified JSON to a new file with "_haystack" appended to the original filename.
"""

def process_json_file(filename, item):
    """
    Process a single JSON file by adding a new entry to each element in the JSON array.
    
    :param filename: Path to the JSON file.
    :param item: Value to be used for the new "item_hostname" entry.
    """
    # Read the JSON file
    with open(filename, 'r') as file:
        data = json.load(file)
    
    # New entry to add
    new_entry = {"item_hostname": item}
    
    # Add the new entry to each element in the JSON array
    for item in data:
        item.update(new_entry)
    
    # Create the new filename
    base, ext = os.path.splitext(filename)
    new_filename = f"{base}_haystack{ext}"
    
    # Write the modified JSON to the new file
    with open(new_filename, 'w') as file:
        json.dump(data, file, indent=2)
    
    print(f"Modified JSON saved as {new_filename}")

def process_directory(directory, item):
    """
    Process all JSON files in a directory by adding a new entry to each element in each file.
    
    :param directory: Path to the directory containing JSON files.
    :param item: Value to be used for the new "item_hostname" entry.
    """
    # Iterate through all files in the directory
    for filename in os.listdir(directory):
        if filename.endswith('.json'):
            process_json_file(os.path.join(directory, filename), item)

def main():
    """
    Main function to handle command-line arguments for processing JSON files or directories.
    """
    parser = argparse.ArgumentParser(description="Process JSON files by adding a new entry to each element.")
    parser.add_argument('-f', '--file', type=str, help="Path to a JSON file")
    parser.add_argument('-d', '--directory', type=str, help="Path to a directory containing JSON files")
    parser.add_argument('-i', '--item', type=str, required=True, help="Value for the new 'item_hostname' entry")

    args = parser.parse_args()

    if args.file:
        process_json_file(args.file, args.item)
    elif args.directory:
        process_directory(args.directory, args.item)
    else:
        parser.print_help()

if __name__ == "__main__":
    main()

