import finnhub
from secrets import finn_hub_key
import json
import ast
import psycopg2
from pgcopy import CopyManager
from datetime import datetime, timedelta
from time import sleep
CONNECTION = "postgres://root:password@localhost:5432/quantx"

# this probably needs to be changed
symbols = ['AAPL']

def main():
    datetimes = calculate_increments()
    responses = api_call(datetimes)
    write_db(responses)
    


def calculate_increments():
    '''Return list of (start, end) for all 1-min increments in the past hour as datetime objects'''
    present = datetime.now()
    hour_ago = present - timedelta(hours = 1)
    start_hour = hour_ago.isoformat(timespec='hours')
    start_hour = datetime.fromisoformat(start_hour)
    print(start_hour)
    end_hour = start_hour + timedelta(minutes=59)
    print(end_hour)
    return [start_hour, end_hour]


def api_call(datetimes):

    responses = []
    assert len(datetimes) == 2, "More tha two datetimes are provided."
    start_time = int(datetimes[0].timestamp())
    end_time = int(datetimes[1].timestamp())
    finnhub_client = finnhub.Client(api_key=finn_hub_key)

    # make the call

    for symbol in symbols:
        for _ in range(10):
            try:
                response = finnhub_client.stock_candles(symbol, '1', start_time, end_time)
            except finnhub.FinnhubAPIException as e:
                if  e.status_code == 429:
                    sleep(60)
                    continue
                else:
                    raise e
            break
        else:
            raise RuntimeWarning(f"API Call Failed for symbol {symbol}, {start_time = }, {end_time = }.")
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

def write_db(responses):
    conn = psycopg2.connect(CONNECTION)
    cursor  = conn.cursor
    cols=['time', 'symbol', 'price_open', 'price_high', 'price_low', 'price_close']
    mgr = CopyManager(conn, 'quote', cols)
    for i, symbol in enumerate(symbols):
        response = responses[i]
        if response['s'] != 'ok': # out of market time, etc.
            continue
        datetimes = [datetime.fromtimestamp(x) for x in response['t']]
        data = [list(a) for a in zip(
            datetimes, 
            [symbol]*len(datetimes), 
            response['o'], response['h'], response['l'], response['c'])]
        mgr.copy(data)
    conn.commit()


if __name__ == "__main__":
    main()
