#!/usr/bin/env python3

# this should be replaced with a typescript service which calls to serveprogress.py

from pathlib import Path
import sys

status_path = Path('/stable-diffusion-webui/download-model-status.txt')

try:
    if not status_path.exists():
        print('Downloading default checkpoint', file=sys.stderr)
        exit(61)
    status = status_path.read_text().split(' ', 1)
    if status[0] == 'OK':
        exit(0)
    if status[0] == 'ERROR':
        if len(status) > 1:
            print(f'Error: {status[1]}', file=sys.stderr)
        else:
            print('Unknown error downloading', file=sys.stderr)
        exit(1)
    if status[0] == 'PROGRESS' and len(status) > 1:
        print(f'Downloading default checkpoint {status[1]}', file=sys.stderr)
    else:
        print('Downloading default checkpoint', file=sys.stderr)
    exit(61)
except Exception as e:
	print(e, file=sys.stderr)
	exit(60)
