# DataScience

The repository for the data-science course.

# Install Notes

Run the scripts from tools/setup starting with install-first.sh.
In order to add Jupyter at startup, edit `/etc/rc.local` and append before `exit 0` the following:

```sh
su pi -c "/home/pi/DataScience/tools/run-jupyter.sh"
```

# Note

The repository was updated to use the Raspberry Pi OS 64-bit version.

# Copyright (C) 2021, 2022, 2023 Pro-Youth

DataScience copyright belongs to [Asociatia Pro-Youth](https://www.pro-youth.ro), a Romanian not-for-profit organization established under Romanian's Government Emergency Ordinance 26/2000 amended. Having full ownership over this repository, Pro-Youth decided to release DataScience as a free software under the GNU General Public License, version 3 as published by the Free Software Foundation: you can redistribute it and/or modify it under the terms of said license.

DataScience is distributed in the hope that it will be useful,  but WITHOUT ANY WARRANTY; without even the implied warranty of  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.