#!/bin/bash

current_dir="$(dirname "$0")"
project_root="$(cd "$current_dir" && pwd)"
sql_file="$project_root/create.sql"

db_host=$1
db_port=$2
db_name=$3
db_user=$4
db_password=$5

pgpassword=$db_password psql -h $db_host -p $db_port -U $db_user -d $db_name -f $sql_file
