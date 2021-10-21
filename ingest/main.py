import finnhub
from secrets import finn_hub_key
import json
import ast

def main():
    finnhub_client = finnhub.Client(api_key=finn_hub_key)
    #response = json.loads(finnhub_client.stock_candles('AAPL', 'D', 1590988249, 1591852249))
    # read in test response for now:
    with open('response.txt') as f:
        lines = f.readlines()
    response_text = lines[0].strip()
    response = ast.literal_eval(response_text)
    print(response["c"])

if __name__ == "__main__":
    main()
