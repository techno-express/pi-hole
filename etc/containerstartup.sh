#!/bin/bash
export IPV4
export IPV6
export DNS1
export DNS2
export DNSPORT
export INTERFACE
export WEBMINPORT

if [ -f "/etc/letsencrypt/archive/$HOSTNAME/cert1.pem" ]
then
    ln -sf "/etc/letsencrypt/archive/$HOSTNAME/cert1.pem" /etc/pki/tls/certs/localhost.crt
    ln -sf "/etc/letsencrypt/archive/$HOSTNAME/privkey1.pem" /etc/pki/tls/private/localhost.key
fi

setting_changed='false'
source <( grep port /etc/dnsmasq.conf ) 
if [ "$port" != "$DNSPORT" ]
then         
    sed -i "s#':53 '#:\$DNSPORT #" /etc/.pihole/pihole
    sed -i "s#':53 '#:\$DNSPORT #" /usr/local/bin/pihole
    sed -i "s#--dport 53#--dport \$DNSPORT#g" /etc/.pihole/automated\ install/basic-install.sh
    sed -i "s@"\${PI_HOLE_GIT_URL}\"@" \${PI_HOLE_GIT_URL} \"\nsed -i \"s#':53 '#:\\\\\$DNSPORT #\" \${PI_HOLE_FILES_DIR}/pihole\nsed -i \"s#--dport 53#--dport \\\\\$DNSPORT#g\" \${PI_HOLE_FILES_DIR}/automated\\\ install/basic-install.sh@g"  /etc/.pihole/advanced/Scripts/update.sh
    sed -i "s@"\${PI_HOLE_GIT_URL}\"@" \${PI_HOLE_GIT_URL} \"\nsed -i \"s#':53 '#:\\\\\$DNSPORT #\" \${PI_HOLE_FILES_DIR}/pihole\nsed -i \"s#--dport 53#--dport \\\\\$DNSPORT#g\" \${PI_HOLE_FILES_DIR}/automated\\\ install/basic-install.sh@g"  /opt/pihole/update.sh
    systemctl stop dnsmasq
    sed -i "s#$port#$DNSPORT#" /etc/dnsmasq.conf
    systemctl start dnsmasq
    setting_changed='true'
fi
source /opt/pihole/webpage.sh
source /etc/pihole/setupVars.conf

setup_dnsmasq_dns() {
    local DNS1="${1:-8.8.8.8}"
    local DNS2="${2:-8.8.4.4}"
    local dnsType='default'
    if [ "$DNS1" != '8.8.8.8' ] || [ "$DNS2" != '8.8.4.4' ] ; then
      dnsType='custom'
    fi;

    echo "Using $dnsType DNS servers: $DNS1 & $DNS2"
	if [ -n "$DNS1" ] ; then 
        change_setting "PIHOLE_DNS_1" "${DNS1}"
	fi;
    if [ -n "$DNS2" ] ; then
        change_setting "PIHOLE_DNS_2" "${DNS2}"
    fi;
}

setup_dnsmasq_interface() {
    local INTERFACE="${1:-eth0}"
    local interfaceType='default'
    if [ "$INTERFACE" != 'eth0' ] ; then
      interfaceType='custom'
    fi;
    echo "DNSMasq binding to $interfaceType interface: $INTERFACE"
	if [ -n "$INTERFACE" ] ; then 
        change_setting "PIHOLE_INTERFACE" "${INTERFACE}"
    fi;
}

setup_dnsmasq_config_if_missing() {
    # When fresh empty directory volumes are used we miss this file
    if [ ! -f /etc/dnsmasq.d/01-pihole.conf ] ; then
        cp /etc/.pihole/advanced/01-pihole.conf /etc/dnsmasq.d/
    fi;
}

setup_dnsmasq() {
    # Coordinates 
    setup_dnsmasq_config_if_missing
    setup_dnsmasq_dns "$DNS1" "$DNS2" 
    setup_dnsmasq_interface "$INTERFACE"
    ProcessDNSSettings
}

nc_error='Name or service not known'
if [ "$IPV4" == "0.0.0.0" ] || nc -w1 -z -v "$IPV4" 53 2>&1 | grep -q "$nc_error" 
then
    export IPV4="$(ip route get 8.8.8.8 | awk '{ print $NF; exit }')"   
    change_setting "IPV4_ADDRESS" "$IPV4"
    setting_changed='true'
elif [ -n "$IPV4" ] && [ "$IPV4_ADDRESS" != "$IPV4" ]
then 
    change_setting "IPV4_ADDRESS" "$IPV4"
    setting_changed='true'
fi
if [ "$IPV6" == "::0" ] && [ "$IPV6_ADDRESS" == "" ]
then
    export IPV6="$(ip -6 route get 2001:4860:4860::8888 | awk '{ print $10; exit }')"
    if [ "$IPV6" == 'kernel' ]
    then
        unset IPV6
    else
        change_setting "IPV6_ADDRESS" "$IPV6"
        setting_changed='true'
    fi
elif [ -n "$IPV6" ] && [ "$IPV6_ADDRESS" != "$IPV6" ] && [ ip route get "$IPV6" ] && ! nc -w1 -z -v "$IPV6" 53 2>&1 | grep -q "$nc_error" 
then
    change_setting "IPV6_ADDRESS" "$IPV6"
    setting_changed='true' 
fi 

if [ "$PIHOLE_DNS_1" != "$DNS1" ] || [ "$PIHOLE_DNS_2" != "$DNS2" ] || [ "$PIHOLE_INTERFACE" != "$INTERFACE" ]
then
    setup_dnsmasq "$DNS1" "$DNS2" 
    setting_changed='true'    
fi 

if [ "$setting_changed" == 'true' ]
then 	
    pihole -g restartdns
fi

source <( grep listen /etc/webmin/miniserv.conf ) 
if [[ $WEBMINPORT =~ ^[0-9]+$ ]] && [ "$WEBMINPORT" != "$listen" ]
then  
    systemctl stop webmin
    sed -i "s#$listen#$WEBMINPORT#" /etc/webmin/miniserv.conf
    systemctl start webmin
elif [ "$WEBMINPORT" == "off" ]
then
    systemctl.original disable webmin.service   
    systemctl stop webmin
elif [[ $WEBMINPORT =~ ^[0-9]+$ ]] && ! pgrep -x "miniserv.pl" > /dev/null
then   
    systemctl.original enable webmin.service 
    systemctl start webmin 
fi
