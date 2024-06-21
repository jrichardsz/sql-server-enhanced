# SQL Server - Enhanced

A minimal enhancement of the official https://hub.docker.com/_/microsoft-mssql-server

<img src="https://github.com/usil/mssql-docker-enhanced/assets/3322836/81497954-f10b-4847-9702-8b101ecbd707" width=300>

## Source code and issues

- https://github.com/jrichardsz/sql-server-enhanced

## Dockerhub

- https://hub.docker.com/repository/docker/jrichardsz/sql-server-enhanced/


## Notes

- If you are concerned about the things happening in the background, go to this repository https://github.com/jrichardsz/sql-server-enhanced , check the **Dockerfile** and build your own image

## Tags

|tag| operative system| sql server version | Edition|
|:--|:--|:--|:--|
|ubuntu-22.04|Microsoft SQL Server 2022 (RTM-CU3) (KB5024396) - 16.0.4025.1 (X64)| Developer Edition (64-bit) <X64>|

## Environment Variables

|name|sample value|description| 
|:--|:--|:--|
|ACCEPT_EULA| 1| Confirms the acceptance of [End-User Licensing Agreement.](https://go.microsoft.com/fwlink/?linkid=857698)|
|MSSQL_PID |Developer| Is the Product ID (PID) or Edition that the container will run with | 
|MSSQL_USER |sa| Default **sa** user |
|MSSQL_SA_PASSWORD| ****| Is the database system administrator (userid = 'sa')|
|TZ|America/Lima|Your preffered timezone|

More details here: https://hub.docker.com/_/microsoft-mssql-server

## Download

```
docker pull jrichardsz/sql-server-enhanced:ubuntu-22.04-sql.2022.rtm-cu3
```

## Local build

```
docker build -t sql-server-enhanced:ubuntu-22.04-sql.2022.rtm-cu3 .
```

## Tag

```
docker tag sql-server-enhanced:ubuntu-22.04-sql.2022.rtm-cu3 jrichardsz/sql-server-enhanced:ubuntu-22.04-sql.2022.rtm-cu3
```


## Push

```
docker push jrichardsz/sql-server-enhanced:ubuntu-22.04-sql.2022.rtm-cu3
```


## docker-compose

```
version: '3.7'

services:
 mssql-docker-enhanced:
    image: jrichardsz/sql-server-enhanced
    container_name: mssql-docker-enhanced
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
      - ./my/scripts:/docker-entrypoint-initdb.d
    healthcheck:
      test: cat /var/log/docker/sqlserver_db_init.log | grep [db_init_completed]
      interval: 10s
      timeout: 3s
      retries: 10
      start_period: 10s 
```

> Set your own password
  
And use these parameters to connect from your favourite ide: 
  
![image](https://github.com/usil/mssql-docker-enhanced/assets/3322836/5e87ecd8-d79b-4ea2-a8e9-e2671faa7683)

## Features

- Execute sql scripts at the database start `./my/scripts:/docker-entrypoint-initdb.d`

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
