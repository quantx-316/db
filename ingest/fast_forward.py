import ingest
from datetime import datetime, timedelta
from dateutil.relativedelta import relativedelta

start_time = datetime(2021, 2, 12, 16, 0)
end_time = None

def main():
    global start_time, end_time
    if end_time is None:
        end_time = datetime.now()
    current_time = start_time
    while current_time < end_time:
        current_time = advance_one_month(current_time)


def advance_one_month(current_start):
    '''Advance one month per api call because of FinnHub restrictions'''
    current_end = current_start + relativedelta(months=+1, minutes=-1)
    print(f"Retreiving data from {current_start} to {current_end}")
    responses = ingest.api_call([current_start, current_end])
    ingest.write_db(responses)
    return current_end + timedelta(minutes = 1)


if __name__ == "__main__":
    main()