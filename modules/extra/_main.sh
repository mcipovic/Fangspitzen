#! /bin/bash

log "\nForcing extras installer scripts to run!"
cd $BASE/modules/extra

echo "Yes or No? [y/n]"
i=1
for script in `find *-install.sh | sed "s:-install.sh::"`; do
	echo 
	read -p "$i) $script  > Install: "
	let i++
done


if [[ $force_mod_extra=1 ]]; then
	exit 0
fi
