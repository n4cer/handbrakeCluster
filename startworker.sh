#!/bin/bash
cd /storage/share
gearman -w -h <master_ipaddress> -f encode xargs /storage/share/transcode2mkv.sh
