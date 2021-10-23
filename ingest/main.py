import finnhub
from secrets import finn_hub_key
import json
import ast
import psycopg2
from pgcopy import CopyManager
from datetime import datetime, timedelta
CONNECTION = "postgres://root:password@localhost:5432/quantx"

# this probably needs to be changed
symbols = ['AAPL']

def main():
    datetimes = calculate_increments()
    responses = api_call(datetimes)
    write_db(datetimes, responses)
    


def calculate_increments():
    '''Return two list of (start, end) for all 1-min increments in the past hour, both as datetime objects'''
    present = datetime.now()
    hour_ago = present - timedelta(hours = 1)
    current_hour = hour_ago.isoformat(timespec='hours')
    datetimes = []
    for t in range(60):
        current_minute = datetime.fromisoformat(current_hour) + timedelta(minutes = t)
        datetimes.append(current_minute)
    #print(datetimes)
    return datetimes


def api_call(datetimes):

    responses = []
    start_time = int(datetimes[0].timestamp())
    end_time = int((datetimes[-1]+timedelta(minutes=1)).timestamp()) # adding one extra minute to go to the end
    
    # make the call
    finnhub_client = finnhub.Client(api_key=finn_hub_key)
    for symbol in symbols:
        response = finnhub_client.stock_candles('AAPL', '1', start_time, end_time)
        #print(response)
        responses.append(response)


    # for debugging purposes, write to a file
    # with open("response.txt", "a") as f:
    #     for response in responses:
    #         f.write(json.dumps(response))
    # read in test response for now:
    # with open('response.txt') as f:
    #     lines = f.readlines()
    # response_text = lines[0].strip()
    return responses

def write_db(datetimes, responses):
    conn = psycopg2.connect(CONNECTION)
    cursor  = conn.cursor
    cols=['time', 'symbol', 'price_open', 'price_high', 'price_low', 'price_close']
    mgr = CopyManager(conn, 'quote', cols)
    for i, symbol in enumerate(symbols):
        response = responses[i]
        if response['s'] != 'ok': # out of market time, etc.
            continue
        data = [list(a) for a in zip(
            datetimes, 
            [symbol]*len(datetimes), 
            response['o'], response['h'], response['l'], response['c'])]
        mgr.copy(data)
    conn.commit()


if __name__ == "__main__":
    main()
