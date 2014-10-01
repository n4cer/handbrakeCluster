#/bin/bash

gearmand -d -L <listen_ipaddress> --libpq-conninfo 'hostaddr=<dbserver_ipaddress> port=5432 dbname=gearman user=postgres' --libpq-table='hc_queue' -q Postgres &
