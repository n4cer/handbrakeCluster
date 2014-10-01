#!/bin/bash

gearman -h <master_ipaddress> -b -f encode "'$1' /storage/share/output/ source '$2' '$3'"
