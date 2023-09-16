#!/usr/bin/env python

import requests
import hashlib
import subprocess
from pathlib import Path
from functools import partial
from sys import argv
from serveprogress import ready_server

# Status file name and paths
status_filename = "download-model-status.txt"
status_path = Path(status_filename)
new_status_path = Path(status_filename + '.new')

def status(text):
    new_status_path.write_text(text)
    new_status_path.replace(status_path)

# Delete the status file
if status_path.exists():
    if status_path.read_text() != 'OK':
        status_path.unlink()

# Start the status webserver
status_server = ready_server('Downloading Model', status_path)

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

        # Make sure the status server is up
        if not status_server.is_alive():
            status_server.start()

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
                status(f'PROGRESS {line.strip()} {out_of}')
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
                    status(f'PROGRESS {line.split()[-1]} {out_of}')
            assert curl.wait() == 0, f'{curl.stderr.read().strip()}'
        elif download_with == 'requests':
            # Start downloading the file with streaming enabled
            response = requests.get(url, stream=True)
            response.raise_for_status()  # Raise an exception if the request was not successful

            # Get the total size of the file from the response headers
            total_size = int(response.headers.get("content-length", 0))
            bytes_written = 0

            # Actually save to the file
            with file_path.open("wb") as file:
                for data in response.iter_content(chunk_size=1024**2):
                    file.write(data)
                    bytes_written += len(data)

                    # Calculate and print the progress
                    progress = (bytes_written / total_size) * 100
                    print(f'{progress:.2f}')
                    status(f'PROGRESS {progress:.2f}% {out_of}')
        else:
            assert False

        status(f'PROGRESS Verifying {out_of}')
        # Calculate the hash of the downloaded file
        downloaded_hash = check_sha and hashlib.sha256(file_path.read_bytes()).hexdigest()

        # Check if the downloaded file has the correct hash
        if check_sha and downloaded_hash != expected_hash:
            status("ERROR corrupted")
            status_server.terminate()
            status_server.join()
            exit(1)
    except requests.exceptions.RequestException as e:
        status("ERROR failed")
        status_server.terminate()
        status_server.join()
        exit(1)
    except Exception as e:
        print(e)
        status(f"ERROR {e}")
        status_server.terminate()
        status_server.join()
        exit(1)

status_server.terminate()
status_server.join()
status("OK")
