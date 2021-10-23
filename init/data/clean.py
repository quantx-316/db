# Convert 1m quote data from row,date,open,high,low,close,volume,average,barCount to date,symbol,open,high,low,close
# Usage:
# python3 clean.py <symbol> <input_file> [output_file: optional, default to (input_file)_clean.csv]

import sys 
import pandas as pd

def main():
    # Get arguments
    symbol = sys.argv[1]
    input_file = sys.argv[2]
    output_file = sys.argv[3] if len(sys.argv) > 3 else input_file.split('.')[0] + "_clean.csv"

    # Read data
    df = pd.read_csv(input_file, sep=',', header=0, names=['row', 'date', 'open', 'high', 'low', 'close', 'volume', 'average', 'barCount'])

    # Print out the first 5 rows 
    print(df.head())

    print("Converting...")

    # Convert to symbol,date,open,high,low,close
    for col in ['row', 'volume', 'average', 'barCount']:
        df.pop(col)

    # Set the symbol to AAPL for every row
    df['symbol'] = symbol 

    df = df[['date', 'symbol', 'open', 'high', 'low', 'close']]

    # Write to file
    df.to_csv(output_file, index=False)

    # Print out the first 5 rows 
    print(df.head())

if __name__ == "__main__":
    main()
