#!/bin/sh

source ./ipv4_get_kdd99.sh

#file=$1
#get_tcp_srcbytes $file
#get_tcp_dstbytes $file

#get_tcp_wrong_fragment $file
#get_tcp_urgent_packets $file

#get_tcp_service $port1 $port2

ipv4_tcp_get_kdd99 ../fields_ipv4/tcpfields ./out.dat

