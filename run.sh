#!/bin/sh

source ./scripts/get_fields.sh
source ./scripts/ipv4_get_kdd99.sh


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

export tcpstream4

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

rm -rf $tcpdat
rm -rf $udpdat
rm -rf $icmpdat

#对ipv6数据包分流
tshark -r $ipv6dat -R "tcp" -w ./ipv6/tcpdat
tshark -r $ipv6dat -R "udp" -w ./ipv6/udpdat
tshark -r $ipv6dat -R "icmpv6" -w ./ipv6/icmpdat

tcpdat=./ipv6/tcpdat
udpdat=./ipv6/udpdat
icmpdat=./ipv6/icmpdat

tcpstreampath6=./ipv6/tcpstream
udpstreampath6=./ipv6/udpstream
icmpstreampath6=./ipv6/icmpstream

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

rm -rf $tcpdat
rm -rf $udpdat
rm -rf $icmpdat

rm -rf $ipv4dat
rm -rf $ipv6dat

echo Split_stream Done!
echo call fields func!

mkdir ./fields_ipv4
mkdir ./fields_ipv6
ipv4_get_fields $tcpstreampath $udpstreampath $icmpstreampath ./fields_ipv4
ipv6_get_fields $tcpstreampath6 $udpstreampath6 $icmpstreampath6 ./fields_ipv6

ipv4_tcp_get_kdd99 ./fields_ipv4/tcpfields ./pre_kdd99.dat
#ipv4_udp_get_kdd99 ./fields_ipv4/udpfields/fields_udp_all ./pre_kdd99.dat
#ipv4_icmp_get_kdd99 ./fields_ipv4/icmpfields/fields_icmp_all ./pre_kdd99.dat

