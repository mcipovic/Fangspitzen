#! /bin/bash

i=1
for script in `find *-install.sh | sed "s:-install.sh::"`; do
	echo "$i) $script"
	let i++
done
