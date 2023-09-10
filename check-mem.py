#!/usr/bin/env python3

from pathlib import Path
import sys

MINIMUM_MEM = 16
MINIMUM_AVAIL = 1
BYTES_IN_GB = 1024**3 # should be GiB, but matches system info display

def get_available_bytes():
	meminfo = Path('/proc/meminfo').read_text()
	active = None
	total = None
	for line in meminfo.split('\n'):
		if ':' not in line:
			continue
		name, rest = line.split(':')
		num = int(rest.strip().split(' ')[0]) * 1024
		if name == 'Active(anon)':
			active = num
		if name == 'MemTotal':
			total = num
	return total - active

def get_used_bytes():
	stat = Path('/sys/fs/cgroup/memory.stat').read_text()
	for line in stat.split('\n'):
		name, rest = line.split(' ')
		if name == 'anon':
			return int(rest.strip()[0])

try:
	used_gb = get_used_bytes() / BYTES_IN_GB
	available_gb = get_available_bytes() / BYTES_IN_GB
except Exception as e:
	print(e, file=sys.stderr)
	exit(60)

if used_gb + available_gb < MINIMUM_MEM:
	print(f'Not enough usable memory ({used_gb + available_gb:.2f}GB). Try stopping other services.', file=sys.stderr)
	exit(1)

if used_gb > MINIMUM_MEM and available_gb < MINIMUM_AVAIL:
	print(f'Using too much memory ({used_gb:.2f}GB). Try a smaller model or lower settings.', file=sys.stderr)
	exit(2)

