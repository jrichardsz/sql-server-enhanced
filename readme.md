# SQL Server - Enhanced

A minimal enhancement of the official https://hub.docker.com/_/microsoft-mssql-server because it lacks of some features

<img src="https://github.com/user-attachments/assets/6ebb5c74-d20d-4521-a20e-b9034ad52ab0" width=300>

## Source code and issues

- https://github.com/jrichardsz/sql-server-enhanced

## Dockerhub

- https://hub.docker.com/repository/docker/jrichardsz/sql-server-enhanced/

## Missing features in the official image

|Feature|description| 
|:--|:--|
|/docker-entrypoint-initdb.d| Almost all the databases ported to docker offer this feature to allow the user mount a volume with sql scripts to be executed at the startup. Feature was required but the owners [close](https://github.com/microsoft/mssql-docker/pull/645#issuecomment-1546474824) it T_T|
|Healtcheck|There is not an official health check and the [proposed](https://github.com/microsoft/mssql-docker/blob/master/linux/preview/examples/mssql-customize/configure-db.sh) script is just iterate 60 times XD|

## Notes

- If you are concerned about the things happening in the background, go to this repository https://github.com/jrichardsz/sql-server-enhanced , check the **Dockerfile** and build your own image

## Docker image tags

|tag| operative system| sql server version | Edition|
|:--|:--|:--|:--|
|ubuntu-22.04-sql.2022.rtm-cu15-1.0.2|Ubuntu 22.04.5 LTS|Microsoft SQL Server 2022 (RTM-CU15-GDR) (KB5046059) - 16.0.4150.1 (X64)| Developer Edition (64-bit) <X64>|
|ubuntu-22.04-sql.2022.rtm-cu3-1.0.1|ubuntu-22.04|Microsoft SQL Server 2022 (RTM-CU3) (KB5024396) - 16.0.4025.1 (X64)| Developer Edition (64-bit) <X64>|
|ubuntu-22.04-sql.2022.rtm-cu3-1.0.0|ubuntu-22.04|Microsoft SQL Server 2022 (RTM-CU3) (KB5024396) - 16.0.4025.1 (X64)| Developer Edition (64-bit) <X64>|

## Environment Variables

|name|sample value|description| 
|:--|:--|:--|
|ACCEPT_EULA| 1| Confirms the acceptance of [End-User Licensing Agreement.](https://go.microsoft.com/fwlink/?linkid=857698)|
|MSSQL_PID |Developer| Is the Product ID (PID) or Edition that the container will run with | 
|MSSQL_USER |sa| Default **sa** user |
|MSSQL_SA_PASSWORD| ****| Is the database system administrator (userid = 'sa')|
|IGNORE_ALREADY_EXECUTED_SCRIPTS|true|If you want to execute the startup scripts no matter if were executed in the previous startup|
|TZ|America/Lima|Your preffered timezone|


More details here: https://hub.docker.com/_/microsoft-mssql-server

## /docker-entrypoint-initdb.d

Opposite to the [official](https://hub.docker.com/r/microsoft/mssql-server) version, I added this feature and it works as does it with mysql, postgress, etc. Just mount a local folder.

> When a script (example foo.sql) is successfully executed, a file (/var/opt/mssql/log/foo.sql.executed) is created to prevent execute again the same script on restart. Use this variable `IGNORE_ALREADY_EXECUTED_SCRIPTS=true` to ignore this feature

## Download

```
docker pull jrichardsz/sql-server-enhanced:latest
```

## Run

```
services:
 sql-server-enhanced:
    image: jrichardsz/sql-server-enhanced:latest
    container_name: sql-server-enhanced
    shm_size: 1g
    ports:
     - "1433:1433"
    environment:
      ACCEPT_EULA: 1
      MSSQL_PID: Developer
      MSSQL_USER: sa
      MSSQL_SA_PASSWORD: 70quasWNl*o#nu4U
      TZ: America/Lima
    volumes:
      - ./scripts:/docker-entrypoint-initdb.d
    healthcheck:
      test: cat /var/log/docker/sqlserver_db_init.log | grep [db_init_completed]
      interval: 10s
      timeout: 3s
      retries: 10
      start_period: 10s 
```

> Set your own password

## IDE

And use these parameters to connect from your favourite ide: 
  
- https://github.com/jrichardsz/sql-server-enhanced/wiki/IDE

## Acknowledgments

- Image base from https://hub.docker.com/_/microsoft-mssql-server
- Logo image from https://www.jenx.si/2022/02/20/sql-server-and-docker/

## Contributors

<table>
  <tbody>
    <td style="text-align:center">
      <img src="https://avatars0.githubusercontent.com/u/3322836?s=460&v=4" width="100px;"/>
      <br />
      <a href="http://jrichardsz.github.io/">JRichardsz</a>
    </td>    
  </tbody>
</table>
