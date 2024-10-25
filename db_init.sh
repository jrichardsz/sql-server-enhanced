#!/bin/bash

export DB_INIT_FOLDER="/docker-entrypoint-initdb.d"
export DB_INIT_LOG_FILE="/var/log/docker/sqlserver_db_init.log"
export EXECUTED_SCRIPTS_LOG_FOLDER="/var/opt/mssql/log"

function echo_log {
  DATE='date +%Y/%m/%d:%H:%M:%S'
  echo `$DATE`" $1"
  echo `$DATE`" $1" >> "$DB_INIT_LOG_FILE"
}

function rotate_init_log {
  filename=$(date '+%Y-%m-%d_%H-%M-%S')
  cp $DB_INIT_LOG_FILE "/var/log/docker/sqlserver_db_init-$filename.log"
  echo "" > "$DB_INIT_LOG_FILE"
}

############
# Entrypoint
############

start_time_seconds=$SECONDS
rotate_init_log
echo_log "DB initilization start"
export STATUS=1
i=0

# The suggestion of official image is to only wait 60 seconds o_0
# https://github.com/microsoft/mssql-docker/blob/master/linux/preview/examples/mssql-customize/configure-db.sh
# In a more elegant way, I execute a sql query to detect if sql server is ready
# Max 80 iterations to prevent an infinite loop
# https://www.softwaredeveloper.blog/initialize-mssql-in-docker-container
while [[ $STATUS -ne 0 ]] && [[ $i -lt 80 ]]; do
    echo_log "Waiting sql server availability: #iteration: $i"
	i=$((i+1))
	
    { # try
        /opt/mssql-tools18/bin/sqlcmd -C -t 1 -U ${MSSQL_USER} -P ${MSSQL_SA_PASSWORD} -Q "select 1"
        STATUS=$?    
        #save your output
    } || { # catch
        # save log for exception 
        echo "warning: Connection validation failed"
    }
    sleep 2
done
if [ $STATUS -ne 0 ]; then 
	echo_log "Error: MSSQL SERVER took more than 80 iterations to start up."
	exit 1
fi

echo_log "SQL Server is available"
sql_files_count=$(find $DB_INIT_FOLDER -mindepth 1 -type f -name "*.sql" -printf x | wc -c)
# TODO: /opt/mssql-tools18/bin/sqlcmd returns 0 as exit code in case of syntax errors
# Because of this, even on errors log says was executed successfully
# Only on low level connection errors the exit code is non zero
# TODO: Move the execution to a function
if [ $sql_files_count -eq 0 ]; then
   echo_log "there are not any *.sql script in $DB_INIT_FOLDER"
else
    for script_absolute_location in $DB_INIT_FOLDER/*.sql; do
        if [ "$IGNORE_ALREADY_EXECUTED_SCRIPTS" == "true" ]; then
            echo_log "script $script_absolute_location : execution started"
            /opt/mssql-tools18/bin/sqlcmd -C -S localhost -U ${MSSQL_USER} -P ${MSSQL_SA_PASSWORD} -d master -i "$script_absolute_location"
            if [ $? -eq 0 ]
            then
                echo_log "script $script_absolute_location : executed successfully"
            else
                echo_log "sql execution returned an error"
                break
            fi
        else
            filename=$(basename -- "$script_absolute_location")
            extension="${filename##*.}"
            filename="${filename%.*}"
            if [ -f "$EXECUTED_SCRIPTS_LOG_FOLDER/$filename.$extension.executed" ]; then
                echo_log "script $script_absolute_location : was already executed"                
            else
                echo_log "script $script_absolute_location : execution started"
                /opt/mssql-tools18/bin/sqlcmd -C -S localhost -U ${MSSQL_USER} -P ${MSSQL_SA_PASSWORD} -d master -i "$script_absolute_location"
                if [ $? -eq 0 ]
                then
                    echo_log "script $script_absolute_location : executed successfully"
                    echo "" >> "$EXECUTED_SCRIPTS_LOG_FOLDER/$filename.$extension.executed"
                else
                    echo_log "sql execution returned an error"
                    break
                fi
            fi    
        fi
    done
fi

elapsed_seconds=$(( SECONDS - start_time_seconds ))
echo_log "Elapsed time: $((elapsed_seconds / 3600)) hours, $((elapsed_seconds / 60)) minutes, $((elapsed_seconds % 60)) seconds elapsed."
echo_log "[db_init_completed]"
