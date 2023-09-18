#!/usr/bin/env python

import hashlib
import subprocess
from pathlib import Path
from functools import partial
from sys import argv
from datetime import datetime
import json

# Status file name and paths
status_filename = "download-model-status.json"
status_path = Path(status_filename)
new_status_path = Path(status_filename + '.new')

def status(state, message=None):
    if state != 'PROGRESS':
        done = datetime.now().isoformat()
    else:
        done = None
    new_status_path.write_text(json.dumps({
        'message': message,
        'state': state,
        'done': done,
    }))
    new_status_path.replace(status_path)

# Delete the status file
if status_path.exists():
    try:
        assert json.loads(status_path.read_text())['state'] == 'OK'
    except Exception:
        status_path.unlink()

# Make sure the download dir exists
Path(argv[1]).mkdir(parents=True, exist_ok=True)

# Download parameters
download_with = 'curl'
check_sha = True

# URL of the file to download
model_index_range = range(0, (len(argv)-2)//3)
for model_index in model_index_range:
    # Filename and hash information
    url = argv[model_index*3+2]
    expected_hash = argv[model_index*3+3]
    filename = argv[model_index*3+4]
    file_path = Path(argv[1]) / Path(filename)
    out_of = f'{model_index+1}/{len(model_index_range)}'

    try:
        # Check if the file exists and has the correct hash
        if file_path.exists():
            file_hash = check_sha and hashlib.sha256(file_path.read_bytes()).hexdigest()

            if not check_sha or file_hash == expected_hash:
                continue

        # Start writing the downloaded data into the file
        if download_with == 'wget':
            wget = subprocess.Popen(
                ["wget", url, "-O", str(file_path), "--progress=dot", "--show-progress", "-q"],
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
            )
            for line in iter(wget.stdout.readline, ''):
                #print(line, end='')
                status('PROGRESS',  f'Downloading default model {line.strip()} {out_of}')
            assert wget.wait() == 0, 'download failed'
        elif download_with == 'curl':
            curl = subprocess.Popen(
                ["curl", "-L", url, "-o", str(file_path), "--progress-bar", "-f"],
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
            )
            for line in iter(curl.stdout.readline, ''):
                #print(line, end='')
                line = line.strip()
                if line != '':
                    status('PROGRESS', f'Downloading default model {line.split()[-1]} {out_of}')
            assert curl.wait() == 0, f'{curl.stderr.read().strip()}'
        else:
            assert False

        status('PROGRESS', f'Verifying model {out_of}')
        # Calculate the hash of the downloaded file
        downloaded_hash = check_sha and hashlib.sha256(file_path.read_bytes()).hexdigest()

        # Check if the downloaded file has the correct hash
        if check_sha and downloaded_hash != expected_hash:
            status('ERROR', 'Model corrupted')
            exit(1)
    except KeyboardInterrupt:        
        status('ERROR', f'Interruped downloading model')
        exit(1)
    except Exception as e:
        print(e)
        status('ERROR', f'Error downloading model: {e}')
        exit(1)

status('OK')
