#!/bin/bash

function drop_database() {
	case $TEE in
		strongbox )
			;;
		vanilla )
			[[ ! $(rm -r "$FOLDER_PROXY/database" 2> /dev/null) ]] \
			  && logi "Failed to drop the core database, maybe it doesn't exists..." \
			  || logi "Dropping core's database...done!"
			;;
		nitro )
			[[ ! $(rm -r "$FOLDER_PROXY/mydb.dat" 2> /dev/null) ]] \
			  && logi "Failed to drop the core database, maybe it doesn't exists..." \
			  || logi "Dropping core's database...done!"
			;;
	esac
}

function drop_mongo_database() {
	local mongo_cmd

	# shellcheck disable=SC2089
	mongo_cmd='db = db.getSiblingDB("'$MONGO_DATABASE_NAME'");db.dropDatabase().ok'

  [[ ! $(mongo --eval "$mongo_cmd" > /dev/null) ]] \
	  && logi "Failed to drop mongo db, maybe it doesn't exists..." \
	  || logi "Dropping mongo db...done!"
}
