#!/bin/sh

while getopts :r: opt
do
    case "$opt" in
	r) infile=$OPTARG;;
	*) echo "Unknown options"
    esac
done

if [ -z "$infile" ]
then
    echo "No infile specified"
    echo "Specified infile whit -r"
    exit
fi

# 创建两个目录  分别用来保存ipv4和ipv6的数据包
mkdir ./ipv4
mkdir ./ipv6

mkdir ./ipv4/tcpstream
mkdir ./ipv4/udpstream
mkdir ./ipv4/icmpstream

mkdir ./ipv6/tcpstream
mkdir ./ipv6/udpstream
mkdir ./ipv6/icmpstream

#分ipv4和ipv6的数据

tshark -r $infile -R "ip" -w ./ipv4/ipv4dat
tshark -r $infile -R "ipv6" -w ./ipv6/ipv6dat

ipv4dat=./ipv4/ipv4dat
ipv6dat=./ipv6/ipv6dat


#对ipv4数据包分流

tshark -r $ipv4dat -R "tcp" -w ./ipv4/tcpdat
tshark -r $ipv4dat -R "udp" -w ./ipv4/udpdat
tshark -r $ipv4dat -R "icmp" -w ./ipv4/icmpdat

tcpdat=./ipv4/tcpdat
udpdat=./ipv4/udpdat
icmpdat=./ipv4/icmpdat

tcpstreampath=./ipv4/tcpstream
udpstreampath=./ipv4/udpstream
icmpstreampath=./ipv4/icmpstream

i=1
while [ "$i" ];do
    cmd="tcp.stream eq $i"
    tshark -r $tcpdat -R "$cmd" -w $tcpstreampath/tcpstream_$i
    res=`ls -l $tcpstreampath/tcpstream_$i | awk '{print $5}'`
    if [ "$res" -eq 112 ]
    then	
	echo tcpstream_$i is empty
	rm -rf $tcpstreampath/tcpstream_$i
	break
    else 
	echo create tcpstream_$i
    fi
    i=`expr $i + 1`
done

editcap -c 1 $udpdat $udpstreampath/udpstream
editcap -c 1 $icmpdat $icmpstreampath/icmpstream

#对ipv6数据包分流
tshark -r $ipv6dat -R "tcp" -w ./ipv6/tcpdat
tshark -r $ipv6dat -R "udp" -w ./ipv6/udpdat
tshark -r $ipv6dat -R "icmp" -w ./ipv6/icmpdat

tcpdat=./ipv6/tcpdat
udpdat=./ipv6/udpdat
icmpdat=./ipv6/icmpdat

tcpstreampath=./ipv6/tcpstream
udpstreampath=./ipv6/udpstream
icmpstreampath=./ipv6/icmpstream

i=1
while [ "$i" ];do
    cmd="tcp.stream eq $i"
    tshark -r $tcpdat -R "$cmd" -w $tcpstreampath/tcpstream_$i
    res=`ls -l $tcpstreampath/tcpstream_$i | awk '{print $5}'`
    if [ "$res" -eq 112 ]
    then	
	echo tcpstream_$i is empty
	rm -rf $tcpstreampath/tcpstream_$i
	break
    else 
	echo create tcpstream_$i
    fi
    i=`expr $i + 1`
done

editcap -c 1 $udpdat $udpstreampath/udpstream
editcap -c 1 $icmpdat $icmpstreampath/icmpstream


