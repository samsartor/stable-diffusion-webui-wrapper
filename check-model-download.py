#!/usr/bin/env python3

from pathlib import Path

status_path = Path('download-model-status.txt')
try:
    if not status_path.exists():
        print('Downloading default checkpoint')
        exit(61)
    status = status_path.read_text().split(' ', 1)
    if status[0] == 'OK':
        exit(0)
    if status[0] == 'ERROR':        
        if len(status) > 1:
            print(f'Error downloading default checkpoint: {status[1]}')
        else:            
            print('Unknown error downloading default checkpoint')
        exit(1)
    if status[0] == 'PROGRESS' and len(status) > 1:
        print(f'Downloading default checkpoint {status[1]}')
    else:            
        print('Downloading default checkpoint')
    exit(61)
except Exception as e:
	print(e, file=sys.stderr)
	exit(60)
