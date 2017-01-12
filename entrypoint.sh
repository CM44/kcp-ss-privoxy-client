#!/usr/bin/env bash

set -e

KCPTUN_CONF="$BASE_DIR/$KCPTUN_DIR/config.json"
SS_CONF="$BASE_DIR/ss-client-config.json"
# ======= KCPTUN CONFIG ======
KCPTUN_SERVER_ADDR=${KCPTUN_SERVER_ADDR:-127.0.0.1}           #"server listen addr": "127.0.0.1"
KCPTUN_SERVER_PORT=${KCPTUN_SERVER_PORT:-8388}                #"server listen port": "8388"
KCPTUN_CLIENT_ADDR=${KCPTUN_CLIENT_ADDR:-127.0.0.1}           #"client listen addr": "127.0.0.1"
KCPTUN_CLIENT_PORT=${KCPTUN_CLIENT_PORT:-8388}                #"client listen addr": "8388"
KCPTUN_KEY=${KCPTUN_KEY:-password}                            #"key": "password",
KCPTUN_CRYPT=${KCPTUN_CRYPT:-aes}                             #"crypt": "aes",
KCPTUN_MODE=${KCPTUN_MODE:-fast2}                             #"mode": "fast2",
KCPTUN_CONN=${KCPTUN_CONN:-1}                                 #"conn": 1,
KCPTUN_AUTO_EXPIRE=${KCPTUN_AUTO_EXPIRE:0}                    #"autoexpire": 0,
KCPTUN_MTU=${KCPTUN_MTU:-1350}                                #"mtu": 1350,
KCPTUN_SNDWND=${KCPTUN_SNDWND:-1024}                          #"sndwnd": 1024,
KCPTUN_RCVWND=${KCPTUN_RCVWND:-1024}                          #"rcvwnd": 1024,
KCPTUN_DATASHARD=${KCPTUN_DATASHARD:-10}                      #"datashard": 10,
KCPTUN_PARITYSHARD=${KCPTUN_PARITYSHARD:-10}                  #"parityshard": 3,
KCPTUN_DSCP=${KCPTUN_DSCP:-46}                                #"dscp": 46
KCPTUN_NOCOMP=${KCPTUN_NOCOMP:-true}                          #"nocomp": true
KCPTUN_LOG=${KCPTUN_LOG:-/dev/null}                           #"log": /dev/null
# ======= SS CONFIG ======
SS_SERVER_ADDR=${SS_SERVER_ADDR:-127.0.0.1}                   #"server": "127.0.0.1",
SS_SERVER_PORT=${SS_SERVER_PORT:-8388}                        #"server_port": 8388,
SS_CLIENT_ADDR=${SS_CLIENT_ADDR:-0.0.0.0}                     #"client": "0.0.0.0",
SS_CLIENT_PORT=${SS_CLIENT_PORT:-1080}                        #"client_port": 1080,
SS_PASSWORD=${SS_PASSWORD:-password}                          #"password":"password",
SS_METHOD=${SS_METHOD:-rc4-md5}                               #"method":"rc4-md5",
SS_TIMEOUT=${SS_TIMEOUT:-600}                                 #"timeout":600,
SS_UDP=${SS_UDP:-true}                                        #-u support,
SS_ONETIME_AUTH=${SS_ONETIME_AUTH:-true}                      #-A support,
SS_FAST_OPEN=${SS_FAST_OPEN:-false}                           #--fast-open support,
SS_LOG=${SS_LOG:-/dev/null}                                   #"stderr": /dev/null

cat > ${SS_CONF}<<-EOF
{
    "server":"${SS_SERVER_ADDR}",
    "server_port":${SS_SERVER_PORT},
    "local_address":"${SS_CLIENT_ADDR}",
    "local_port":${SS_CLIENT_PORT},
    "password":"${SS_PASSWORD}",
    "timeout":${SS_TIMEOUT},
    "method":"${SS_METHOD}"
}
EOF
if [[ "${SS_UDP}" =~ ^[Tt][Rr][Uu][Ee]|[Yy][Ee][Ss]|1|[Ee][Nn][Aa][Bb][Ll][Ee]$ ]]; then
    SS_UDP_FLAG="-u "
else
    SS_UDP_FLAG=""
fi
if [[ "${SS_ONETIME_AUTH}" =~ ^[Tt][Rr][Uu][Ee]|[Yy][Ee][Ss]|1|[Ee][Nn][Aa][Bb][Ll][Ee]$ ]]; then
    SS_ONETIME_AUTH_FLAG="-A "
else
    SS_ONETIME_AUTH_FLAG=""
fi
if [[ "${SS_FAST_OPEN}" =~ ^[Tt][Rr][Uu][Ee]|[Yy][Ee][Ss]|1|[Ee][Nn][Aa][Bb][Ll][Ee]$ ]]; then
    SS_FAST_OPEN_FLAG="--fast-open "
else
    SS_FAST_OPEN_FLAG=""
fi

cat > ${KCPTUN_CONF}<<-EOF
{
    "localaddr": "${KCPTUN_CLIENT_ADDR}:${KCPTUN_CLIENT_PORT}",
    "remoteaddr": "${KCPTUN_SERVER_ADDR}:${KCPTUN_SERVER_PORT}",
    "key": "${KCPTUN_KEY}",
    "crypt": "${KCPTUN_CRYPT}",
    "mode": "${KCPTUN_MODE}",
    "conn": ${KCPTUN_CONN},
    "autoexpire": ${KCPTUN_AUTO_EXPIRE},
    "mtu": ${KCPTUN_MTU},
    "sndwnd": ${KCPTUN_SNDWND},
    "rcvwnd": ${KCPTUN_RCVWND},
    "datashard": ${KCPTUN_DATASHARD},
    "parityshard": ${KCPTUN_PARITYSHARD},
    "dscp": ${KCPTUN_DSCP},
    "nocomp": ${KCPTUN_NOCOMP},
    "log": "${KCPTUN_LOG}"
}
EOF

echo "Starting privoxy..."
cd /etc/privoxy
privoxy
sleep 0.3
echo "privoxy (pid `pidof privoxy`)is running."
netstat -ntlup | grep privoxy
echo "Starting Shadowsocks-libev..."
nohup ss-local -c ${SS_CONF} ${SS_UDP_FLAG}${SS_ONETIME_AUTH_FLAG}${SS_FAST_OPEN_FLAG} >${SS_LOG} 2>&1 &
sleep 0.3
echo "ss-local (pid `pidof ss-local`)is running."
netstat -ntlup | grep ss-local
echo "Starting Kcptun for Shadowsocks-libev..."
$BASE_DIR/$KCPTUN_DIR/client_linux_amd64 -v
echo "+---------------------------------------------------------+"
echo "KCP Listen     : ${KCPTUN_CLIENT_ADDR}:${KCPTUN_CLIENT_PORT}"
echo "KCP Parameter: --crypt ${KCPTUN_CRYPT} --key ${KCPTUN_KEY} --mtu ${KCPTUN_MTU} --sndwnd ${KCPTUN_SNDWND} --rcvwnd ${KCPTUN_RCVWND} --mode ${KCPTUN_MODE} --nocomp ${KCPTUN_NOCOMP}" --dscp ${KCPTUN_DSCP}
echo "+---------------------------------------------------------+"
exec "$BASE_DIR/$KCPTUN_DIR/client_linux_amd64" -c ${KCPTUN_CONF}
