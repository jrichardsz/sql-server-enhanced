#!/bin/bash

_DIRNAME=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export DB_INIT_FOLDER="/docker-entrypoint-initdb.d"
export DB_INIT_LOG_FILE="/var/log/docker/sqlserver_db_init.log"
export EXECUTED_SCRIPTS_LOG_FOLDER="/var/opt/mssql/log"
export SEED_ORDER_FILE_LOCATION="$DB_INIT_FOLDER/_seed.order.txt"

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

echo_log "SQL Server started"

##############################
# Automatic sql scripts execution at startup
##############################

sql_files=

if [ -e "$SEED_ORDER_FILE_LOCATION" ]; then
  echo_log "_seed.order.txt was detected. Custom order will be used instead the alphabetical sort"
  sql_files=$(cat "$SEED_ORDER_FILE_LOCATION")
else
  if [ "$INCLUDE_SUB_FOLDERS" = "true" ]; then
    sql_files=$(find $DB_INIT_FOLDER -mindepth 1  -name '*.sql' )
    PREVENT_REPEAT_EXECUTIONS_ON_RESTART=false
    echo_log "When INCLUDE_SUB_FOLDERS is true, is not possible to save the executed scripts names. So PREVENT_REPEAT_EXECUTIONS_ON_RESTART will be false"
  else
    sql_files=$(find $DB_INIT_FOLDER -mindepth 1 -maxdepth 1  -name '*.sql' )
  fi
fi

cd $_DIRNAME
echo_log "Workspace: $(pwd)"

if [ -z "${sql_files}" ]; then
  echo_log "sql files are not found on $DB_INIT_FOLDER"
else
  # TODO: /opt/mssql-tools18/bin/sqlcmd returns 0 as exit code in case of syntax errors
  # Because of this, even on errors log says was executed successfully
  # Only on low level connection errors the exit code is non zero

  # TODO: Move the execution to a function

  echo_log "Executing the following sql scripts from folder: $DB_INIT_FOLDER"
  echo -e "\n$sql_files\n\n"

  while read script_location; do 

      if [ -z "${script_location}" ]; then
        continue
      fi

      script_absolute_location=
      if [ -e "$SEED_ORDER_FILE_LOCATION" ]; then
        script_absolute_location="$DB_INIT_FOLDER/$script_location"
      else
        script_absolute_location="$script_location"
      fi

      script_absolute_location=$(echo "$script_absolute_location"  | xargs echo -n )

      if [ "$PREVENT_REPEAT_EXECUTIONS_ON_RESTART" == "false" ]; then
          echo_log ""
          echo_log ""
          echo_log "##############"
          echo_log "script $script_absolute_location : execution started"
          stdout=$(/opt/mssql-tools18/bin/sqlcmd -C -S localhost -U ${MSSQL_USER} -P ${MSSQL_SA_PASSWORD} -d master -i "$script_absolute_location")
          echo_log "$stdout"
          if [[ "$SKIP_ERRORS" == "" || "$SKIP_ERRORS" == "false" ]]; then
              if [[ $stdout == *"Syntax error "* ||  $stdout == *"Invalid column name"* ||   $stdout == *"statement failed"* || $stdout == *"Invalid object"* || $stdout == *"does not exist"* || $stdout == *"invalid data type"* || $stdout == *"Cannot find data type"*  || $stdout == *"Must declare"*  || $stdout == *"depends on the missing object"* || $stdout == *"failed because"* ]]; then
                  echo_log "Error detected in log. To ignore the log-based error analysis, set the env variable: SKIP_ERRORS=true"
                  break;
              else
                echo_log "script $script_absolute_location : execution completed"
              fi
          else
            echo_log "script $script_absolute_location : execution completed"
          fi       
      else
          filename=$(basename -- "$script_absolute_location")
          extension="${filename##*.}"
          filename="${filename%.*}"
          if [ -f "$EXECUTED_SCRIPTS_LOG_FOLDER/$filename.$extension.executed" ]; then
              echo_log ""
              echo_log ""
              echo_log "##############"        
              echo_log "script $script_absolute_location : was already executed"                
          else
              echo_log ""
              echo_log ""
              echo_log "##############"        
              echo_log "script $script_absolute_location : execution started"
              stdout=$(/opt/mssql-tools18/bin/sqlcmd -C -S localhost -U ${MSSQL_USER} -P ${MSSQL_SA_PASSWORD} -d master -i "$script_absolute_location")
              echo_log "$stdout"
              
              if [[ "$SKIP_ERRORS" == "" || "$SKIP_ERRORS" == "false" ]]; then
                  if [[ $stdout == *"Syntax error "* ||  $stdout == *"Invalid column name"* ||   $stdout == *"statement failed"* || $stdout == *"Invalid object"* || $stdout == *"does not exist"* || $stdout == *"invalid data type"* || $stdout == *"Cannot find data type"*  || $stdout == *"Must declare"*  || $stdout == *"depends on the missing object"* || $stdout == *"failed because"* ]]; then
                     echo_log "Error detected in log. To ignore the log-based error analysis, set the env variable: SKIP_ERRORS=true"
                     break;
                  else
                    echo_log "script $script_absolute_location : execution completed"
                    echo "" >> "$EXECUTED_SCRIPTS_LOG_FOLDER/$filename.$extension.executed"
                  fi
              else
                echo_log "script $script_absolute_location : execution completed"
                echo "" >> "$EXECUTED_SCRIPTS_LOG_FOLDER/$filename.$extension.executed"
              fi 
          fi    
      fi
  done <<< $sql_files
fi

elapsed_seconds=$(( SECONDS - start_time_seconds ))
echo_log "Elapsed time: $((elapsed_seconds / 3600)) hours, $((elapsed_seconds / 60)) minutes, $((elapsed_seconds % 60)) seconds elapsed."
echo_log "[db_init_completed]"