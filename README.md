# SQL Server TIG Stack (STIG)
STIG is a way for anyone to test-drive the TIG stack (telegraf/influxbd/grafana) for base-lining SQL Server performance.

> STIG is based on docker-compose, so a working install of docker-compose is required.

## Usage
Getting started is simple:
 
 * Create a new user on all boxes you would like to monitor:

 ```
USE master;
GO
CREATE LOGIN [telegraf] WITH PASSWORD = N'<your_strong_password>';
GO
GRANT VIEW SERVER STATE TO [telegraf];
GO
GRANT VIEW ANY DEFINITION TO [telegraf];
GO
 ```

 * Alter `config/userconfig.yml` and add the host(s) you would like to monitor, and the username/password you created above
 * Run `docker-compose up`
 * Connect to http://localhost:8080 and sign into Grafana with the following credentials:
    * User: stig
    * Pass: stigPass!

## Configuration
This is *NOT* meant to be a full production monitoring stack. The only user configuration needed happens in `config/userconfig.yml`. Here is an example:

```
telegraf:
  sql_plugin:
    hosts:
      - host: stigtest
        port: 1433
        username: telegraf
        password: TelegrafPassword0!      
```

> **NOTE:** When configuring the host to connect to, you have to either use a hostname that is resolvable on your network, an IP address, or the hostname of a docker container on the same network as the TIG stack (`stig_net`). If you are trying to connect to a SQL instance on your local workstation, you MUST use the network address, `localhost` will **NOT** work. 

You can adjust other settings by altering environment variables in the `docker-compose.yml` file, but again, this was not meant to run as a production monitoring stack. STIG was meant to run on a local workstation as a way to play with Grafana, or to do local dev/test work on a SQL Server without having to tie that test system into your existing monitoring infrastructure.