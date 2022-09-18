#!/usr/bin/env python3
from notebook.auth import passwd
from pathlib import Path

password_hash = passwd('raspberry')
password_file = Path('/home/pi/.jupyter/password')
password_file.parent.mkdir(parents = True, exist_ok = True)
with open(password_file, 'w') as fp:
    fp.write(password_hash)
