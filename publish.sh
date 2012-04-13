#!/bin/bash

# ---------------------------------
# ATENÇÃO: NÃO ALTERE ESTE ARQUIVO!
# ---------------------------------

# TODO: how can I find cywin? 
PATH=$PATH:/c/cygwin/bin/
REMOTE_DESTINATION="cepa@arquivos.atp.usp.br:/work/PUBLICACAO/atividades-interativas"
LOG_FILE="$(pwd)/publish.log"
FROM="./deployment/"

# TODO: how can I improve this?
origin_url=$(git remote -v | grep fetch | awk '{if ($1 == "origin") print $2}')
reponame=$(echo $origin_url | awk -F: '{print $NF}' | awk -F/ '{print $NF}' | sed -e "s/.git//g")

if [ "$reponame" != "" ]; then
	to="$REMOTE_DESTINATION/$reponame"

	echo "Copying from $(pwd) to $to" | tee "$LOG_FILE"

	# TODO: how can I get a return code?
	rsync -rvlt -e "ssh -p 2222" --chmod=u=rwx,g=rwx,o=rx --force --prune-empty-dirs "$FROM" "$to" | tee -a "$LOG_FILE"
else
	echo "Unable to find a remote repository named 'origin' in $(pwd)." | tee -a "$LOG_FILE"
fi

exit 0

# File: publish.sh
# Author: Ivan Ramos Pagnossin at Centro de Ensino e Pesquisa Aplicada (CEPA)
# This script is the client side of the midia.atp.usp.br publishing process.