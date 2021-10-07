import requests 
import json 
import os 
import time 
import sqlparse 

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

CREATE_SQL_FILE_NAME = 'create.sql'
CREATE_SQL_FILE = os.path.join(BASE_DIR, CREATE_SQL_FILE_NAME) 

HOST = 'http://localhost:9000'

def run_query(sql_query):
    query_params = {
        'query': sql_query,
        'fmt': 'json'
    }
    res = requests.post(f"{HOST}/exec", params = query_params)
    json_res = json.loads(res.text)
    print(f"RAN {sql_query}\n RESULT: {json_res}")
    if 'error' in json_res or res.status_code != 200:
        raise Exception("ERROR IN EXECUTION")

def get_create_sql_cmds():
    with open(CREATE_SQL_FILE) as f: 
        info = f.read() 
        sql_cmds = sqlparse.split(info.strip().replace("\n", "").replace("\r", ""))
    
    return sql_cmds 

def create():
    sql_cmds = get_create_sql_cmds()
    for cmd in sql_cmds:
        try: 
            run_query(cmd)
        except Exception as e: 
            print(f"ERROR RUNNING {cmd}\n ERROR: {e}")

def wait_for_server():
    time1 = time.time() 
    while True:
        time2 = time.time() 
        if (time2-time1) > 5:
            raise Exception("ERROR: Server took over 5 seconds to setup")
        try: 
            res = requests.get(HOST)
            if (res.status_code == 200): break 
        except Exception: 
            pass 

def main():
    print("BEGINNING TIME SERIES DB SETUP")
    print("WAITING FOR SERVER...")
    wait_for_server()
    create() 
    print("FINISHED TIME SERIES DB SETUP")

if __name__ == "__main__":
    main() 