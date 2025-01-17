import pandas as pd
import json
import argparse
import datetime
import os

def xlsx_to_jsonl(input_file, output_dir):
    # Load the Excel file
    xls = pd.ExcelFile(input_file)
    
    # Ensure the output directory exists
    os.makedirs(output_dir, exist_ok=True)
    
    # Loop through each sheet name
    for sheet_name in xls.sheet_names:
        # Load the sheet into a DataFrame
        df = pd.read_excel(xls, sheet_name=sheet_name)
        # Replace NaN values with an empty string
        df = df.fillna('')
        # Convert Timestamp, datetime, and time objects to strings
        df = df.apply(lambda x: x.map(lambda y: y.strftime('%Y-%m-%d %H:%M:%S') if isinstance(y, (pd.Timestamp, datetime.datetime)) else 
                                      y.strftime('%H:%M:%S') if isinstance(y, datetime.time) else y))
        # Convert the DataFrame to a list of dictionaries
        records = df.to_dict(orient='records')
        
        # Define the output file path for the current sheet
        output_file = os.path.join(output_dir, f"{sheet_name}.jsonl")
        
        # Write the records to the JSONL file
        with open(output_file, 'w') as jsonl_file:
            for record in records:
                jsonl_file.write(json.dumps(record) + '\n')

def main():
    parser = argparse.ArgumentParser(description='Convert XLSX to individual JSONL files for each sheet.')
    parser.add_argument('-f', '--file', required=True, help='Input XLSX file path')
    parser.add_argument('-d', '--directory', required=True, help='Output directory path')
    args = parser.parse_args()

    xlsx_to_jsonl(args.file, args.directory)

if __name__ == '__main__':
    main()
