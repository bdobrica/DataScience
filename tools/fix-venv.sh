#!/bin/bash
find ~/.local/ -name kernel.json | while read file; do
	venv=$(echo $file | awk -F '/' '{print $(NF-1)}')
	cat << EOF > ${file}
{
 "argv": [
  "~/DataScience/tools/run-venv.sh",
  "${venv}",
  "-m",
  "ipykernel_launcher",
  "-f",
  "{connection_file}"
 ],
 "display_name": "${venv}",
 "language": "python"
}
EOF
done
