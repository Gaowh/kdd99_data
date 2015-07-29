#!/bin/sh

while getopts :t:u:i:w: opt 
do
    case "$opt" in
	t) tcpstreampath=$OPTARG;;
	u) udpstreampath=$OPTARG;;
	i) icmpstreampath=$OPTARG;;
	w) outpath=$OPTARG;;
	*) echo  "Unknow options";;
    esac
done

if [ -z "$tcpstreampath" ] 
then
    tcpstreampath=./
fi

if [ -z "$udpstreampath" ]
then 
    udpstreampath=./
fi

if [ -z "$icmpstreampath" ]
then
    icmpstreampath=./
fi

if [ -z "$outpath" ]
then
    outpath=./
fi

mkdir $outpath/fields_ipv6

mkdir $outpath/fields_ipv6/tcpfields
mkdir $outpath/fields_ipv6/udpfields
mkdir $outpath/fields_ipv6/icmpfields


tcppath=$outpath/fields_ipv6/tcpfields
udppath=$outpath/fields_ipv6/udpfields
icmppath=$outpath/fields_ipv6/icmpfields

#提取tcp的字段

i=1
for file in `ls $tcpstreampath`
do
    #echo $file
    tshark -r $tcpstreampath/$file -T fields -E separator=, -e frame.time -e ipv6.src -e tcp.srcport\
	    -e ipv6.dst -e tcp.dstport -e tcp.len  -e tcp.segment.error -e tcp.flags >> $tcppath/fields_stream_$i
    i=`expr $i + 1`
done

i=1
for file in `ls $udpstreampath`
do
    #echo $file
    tshark -r $udpstreampath/$file -T fields -E separator=, -e frame.time -e ipv6.src -e udp.srcport\
					   -e ipv6.dst -e udp.dstport >> $udppath/fields_udp_all
done

for file in `ls $icmpstreampath`
do
    #echo $file
    tshark -r $icmpstreampath/$file -T fields -E separator=, -e frame.time -e ipv6.src -e ipv6.dst >> $icmppath/fields_icmp_all
done
