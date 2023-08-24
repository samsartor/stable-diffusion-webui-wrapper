#!/usr/bin/env python

import requests
import hashlib
from pathlib import Path

# URL of the file to download
url = "https://huggingface.co/stabilityai/stable-diffusion-2-1/resolve/main/v2-1_768-ema-pruned.safetensors"

# Filename and hash information
filename = url.split('/')[-1]
expected_hash = "dcd690123cfc64383981a31d955694f6acf2072a80537fdb612c8e58ec87a8ac"

# Status file name
status_filename = "download-model-status.txt"

# Paths for the file and status file
file_path = Path(filename)
status_path = Path(status_filename)

# Delete the status file
if status_path.exists():
    status_path.unlink()

try:
    # Check if the file exists and has the correct hash
    if file_path.exists():
        file_hash = hashlib.sha256(file_path.read_bytes()).hexdigest()

        if file_hash == expected_hash:
            status_path.write_text("OK")
            exit()

    # Start downloading the file with streaming enabled
    response = requests.get(url, stream=True)
    response.raise_for_status()  # Raise an exception if the request was not successful

    # Get the total size of the file from the response headers
    total_size = int(response.headers.get("content-length", 0))
    bytes_written = 0

    # Start writing the downloaded data into the file
    with file_path.open("wb") as file:
        for data in response.iter_content(chunk_size=1024**2):
            file.write(data)
            bytes_written += len(data)

            # Calculate and print the progress
            progress = (bytes_written / total_size) * 100
            status_path.write_text(f'PROGRESS {progress:.2f}%')

    # Calculate the hash of the downloaded file
    downloaded_hash = hashlib.sha256(file_path.read_bytes()).hexdigest()

    # Check if the downloaded file has the correct hash
    if downloaded_hash == expected_hash:
        status_path.write_text("OK")
    else:    
        status_path.write_text("ERROR corrupted")
except requests.exceptions.RequestException as e:
    status_path.write_text("ERROR failed")
    raise e
except Exception as e:
    status_path.write_text(f"ERROR error {e}")
    raise e
