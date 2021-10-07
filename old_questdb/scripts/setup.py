import os 
import subprocess 

CURR_DIR = os.path.dirname(os.path.abspath(__file__))
BASE_DIR = os.path.dirname(CURR_DIR)

def main():
    subprocess.call(os.path.join(CURR_DIR, "start.sh"))
    subprocess.call(os.path.join(CURR_DIR, "dbsetup.py"))

if __name__ == "__main__":
    main()