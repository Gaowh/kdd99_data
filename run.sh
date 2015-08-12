#!/bin/sh

source ./scripts/get_fields.sh
source ./scripts/ipv4_get_pre_data.sh
source ./scripts/ipv6_get_pre_data.sh
source ./scripts/func.sh

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

#下面三个目录用来保存iPv4的三类数据
mkdir ./ipv4/tcpstream
mkdir ./ipv4/udpstream
mkdir ./ipv4/icmpstream


#下面三个目录用来保存ipv6的三类数据
mkdir ./ipv6/tcpstream
mkdir ./ipv6/udpstream
mkdir ./ipv6/icmpstream

#分离ipv4和ipv6的数据
tshark -r $infile -R "ip" -w ./ipv4/ipv4dat
tshark -r $infile -R "ipv6" -w ./ipv6/ipv6dat

ipv4dat=./ipv4/ipv4dat
ipv6dat=./ipv6/ipv6dat


#对ipv4的三类数据包进行分离
tshark -r $ipv4dat -R "tcp" -w ./ipv4/tcpdat
tshark -r $ipv4dat -R "udp" -w ./ipv4/udpdat
tshark -r $ipv4dat -R "icmp" -w ./ipv4/icmpdat

tcpdat=./ipv4/tcpdat
udpdat=./ipv4/udpdat
icmpdat=./ipv4/icmpdat

tcpstreampath=./ipv4/tcpstream
udpstreampath=./ipv4/udpstream
icmpstreampath=./ipv4/icmpstream


#将tcp数据分流
i=1
while [ "$i" ];do
    cmd="tcp.stream eq $i"
    tshark -r $tcpdat -R "$cmd" -w $tcpstreampath/tcpstream_$i
    res=`ls -l $tcpstreampath/tcpstream_$i | awk '{print $5}'`
    if [ "$res" -eq 112 ]
    then	
	rm -rf $tcpstreampath/tcpstream_$i
	break
    fi
    i=`expr $i + 1`
done

#将udp数据以单独的一个包进行分流
editcap -c 1 $udpdat $udpstreampath/udpstream

#将icmp数据以单独的一个包进行分流
editcap -c 1 $icmpdat $icmpstreampath/icmpstream

rm -rf $tcpdat
rm -rf $udpdat
rm -rf $icmpdat

#对ipv6的三类数据包进行分流
tshark -r $ipv6dat -R "tcp" -w ./ipv6/tcpdat
tshark -r $ipv6dat -R "udp" -w ./ipv6/udpdat
tshark -r $ipv6dat -R "icmpv6" -w ./ipv6/icmpdat

tcpdat=./ipv6/tcpdat
udpdat=./ipv6/udpdat
icmpdat=./ipv6/icmpdat

tcpstreampath6=./ipv6/tcpstream
udpstreampath6=./ipv6/udpstream
icmpstreampath6=./ipv6/icmpstream


#将ipv6的tcp进行分流
i=1
while [ "$i" ];do
    cmd="tcp.stream eq $i"
    tshark -r $tcpdat -R "$cmd" -w $tcpstreampath6/tcpstream_$i
    res=`ls -l $tcpstreampath6/tcpstream_$i | awk '{print $5}'`
    if [ "$res" -eq 112 ]
    then	
	rm -rf $tcpstreampath6/tcpstream_$i
	break
    fi
    i=`expr $i + 1`
done

#将ipv6的udp和icmp进行分流
editcap -c 1 $udpdat $udpstreampath6/udpstream
editcap -c 1 $icmpdat $icmpstreampath6/icmpstream

rm -rf $tcpdat
rm -rf $udpdat
rm -rf $icmpdat

rm -rf $ipv4dat
rm -rf $ipv6dat

echo Split_stream Done!
echo call fields func!


#下面从每个流中提取出某些特征，该特征用于之后的kdd99特征的提取
mkdir ./fields_ipv4
mkdir ./fields_ipv6
ipv4_get_fields $tcpstreampath $udpstreampath $icmpstreampath ./fields_ipv4
ipv6_get_fields $tcpstreampath6 $udpstreampath6 $icmpstreampath6 ./fields_ipv6


#从上面提取的特征中提取出一部分kdd99特征和一些辅助的特征
ipv4_tcp_get_kdd99 ./fields_ipv4/tcpfields ./pre_kdd99.dat
ipv4_udp_get_kdd99 ./fields_ipv4/udpfields ./pre_kdd99.dat
ipv4_icmp_get_kdd99 ./fields_ipv4/icmpfields ./pre_kdd99.dat
ipv6_tcp_get_kdd99 ./fields_ipv6/tcpfields ./pre_kdd99.dat
ipv6_udp_get_kdd99 ./fields_ipv6/udpfields ./pre_kdd99.dat
ipv6_icmp_get_kdd99 ./fields_ipv6/icmpfields ./pre_kdd99.dat

#将流按照时间排序
pre_sort ./pre_kdd99.dat

get_kdd99_all ./pre_kdd99.dat ./kdd99_all.dat

rm -rf ./fields_ipv4
rm -rf ./fields_ipv6

rm -rf ./ipv4
rm -rf ./ipv6
