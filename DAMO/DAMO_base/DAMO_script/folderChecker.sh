#!/bin/bash

frontend=$(git diff HEAD HEAD~ --name-only | grep -Fc 'frontend' )
backend=$(git diff HEAD HEAD~ --name-only | grep -Fc 'backend' )
echo $frontend
echo $backend
[[ $frontend > 0 ]] && echo  "##vso[task.setvariable variable=BuildFrontend]true"
[[ $backend > 0 ]] && echo  "##vso[task.setvariable variable=BuildBackend]true"
echo "check finished"
