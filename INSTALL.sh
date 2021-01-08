#!/bin/ash
# INSTALL.sh

######################################################################
#
# Copyright (C) 2021 Shant Patrick Tchatalbachian
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>
#
######################################################################

mkdir /root/logs
printf "\033[92m\nStarting Installer for EAPD...\n\n\033[0m" && printf "Starting Installer for EAPD at $(date '+%r on %x')\n" >> /root/logs/install.log
read -s -n 1 -p "On models before the MK7, or other openwrt, please look at the wiki under Requirements. Turn off PineAP then Press any key to continue . . . or ctrl+c to stop" && printf "\n\n"
opkg update && opkg install mariadb-server --force-overwrite && opkg install mariadb-client --force-overwrite
opkg install python --force-overwrite && opkg install python-pip --force-overwrite
#python -m pip install --upgrade pip
python -m pip install wheel netaddr scapy
/etc/init.d/cron stop && /etc/init.d/cron disable
mkdir -p /pineapple/modules/EAPD/src/lib/modules/material
mkdir -p /pineapple/modules/EAPD/src/lib/components
mkdir -p /pineapple/modules/EAPD/src/lib/services
cp -f -r MODULE/* /pineapple/modules/EAPD/
cp -f EAPD.py /root/eapd.py && cp -f CRONTABS /etc/crontabs/root && cp -f EAPDD /etc/init.d/eapdd
chmod 744 /etc/init.d/eapdd && chmod +x /etc/init.d/eapdd
chmod 3400 /root/eapd.py && chmod +x /root/eapd.py
printf 'innodb_use_native_aio = 0\n' >> /etc/mysql/conf.d/50-server.cnf
uci set mysqld.general.enabled='1' && uci commit
rm /etc/rc.local && printf '/etc/init.d/eapdd stop\n' > /etc/rc.local && sleep 10
/etc/init.d/eapdd disable && mysql_install_db --force && opkg install python-mysql
/etc/init.d/mysqld start && sleep 10 && printf "\nMYSQL Securing Started...\n\n"
rootpass=$(openssl rand -base64 16)
mysql -u root <<-EOF
UPDATE mysql.user SET Password=PASSWORD('$rootpass') WHERE User='root';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';
FLUSH PRIVILEGES;
EOF
sleep 1 && /etc/init.d/mysqld stop && printf "MySQL Stopped and Secured...\n\n"
sed -i "23i###################################\n" /etc/init.d/eapdd
sed -i "23ipassword='$rootpass'\n" /etc/init.d/eapdd
interface=1
frequency=2
time=120
read -n 1 -p "Please select an interface Wlan[0-9]: " interface && printf "\n\n"
sed -i "23iinterface=wlan$interface" /etc/init.d/eapdd
read -n 1 -p "Please select the frequency your card supports [2(Ghz)/5(Ghz)]: " frequency && printf "\n\n"
sed -i "23ifrequency=$frequency" /etc/init.d/eapdd
read -n 3 -p "Please select the scan length in seconds [1-120]: " time && printf "\n"
sed -i "23itime=$time" /etc/init.d/eapdd
sed -i "23i###############VARS################\n" /etc/init.d/eapdd
chmod 3400 /etc/init.d/eapdd && chmod +x /etc/init.d/eapdd
printf "Installer Complete.\n\n" && printf "Installer Complete at $(date '+%r on %x')\n" >> /root/logs/install.log
printf "|-----------------------------------------README!-----------------------------------------|\n\n"
printf "Log file saved to /root/logs/install.log.\n\n"
printf "Just run '/etc/init.d/eapdd L' to start learning mode.\n\n"
printf "|-------------------------------------------END-------------------------------------------|\n" >> /root/logs/install.log
exit
