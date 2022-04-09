env=dev
sed -e "s/\$env/"$env"/" < ./DAMO/parameter.json |\
sed -e "s/\$HardenAMI/"$HardenAMI"/" > ./DAMO/parameter.$env.json
cat ./DAMO/parameter.$env.json