#!/bin/sh

function ipv4_get_fields {
    echo ####################################
    echo function ipv4_get_fields start......

    if [ $# -ne 4 ] 
    then
	echo Usage:ipv4_get_fields tcppath udppath icmppath outpath
	return -1
    fi

    tcpstreampath=$1
    udpstreampath=$2
    icmpstreampath=$3
    outpath=$4

    mkdir $outpath/fields_ipv4

    mkdir $outpath/fields_ipv4/tcpfields
    mkdir $outpath/fields_ipv4/udpfields
    mkdir $outpath/fields_ipv4/icmpfields


    tcppath=$outpath/fields_ipv4/tcpfields
    udppath=$outpath/fields_ipv4/udpfields
    icmppath=$outpath/fields_ipv4/icmpfields

#提取tcp的字段

    i=1
    for file in `ls $tcpstreampath`
    do
	#echo $file
        tshark -r $tcpstreampath/$file -T fields -E separator=, -e frame.time -e ip.src -e tcp.srcport\
	    	    -e ip.dst -e tcp.dstport -e tcp.len  -e tcp.segment.error -e tcp.flags >> $tcppath/fields_stream_$i
	i=`expr $i + 1`
    done

    i=1
    for file in `ls $udpstreampath`
    do
	#echo $file
	tshark -r $udpstreampath/$file -T fields -E separator=, -e frame.time -e ip.src -e udp.srcport\
					   -e ip.dst -e udp.dstport -e udp.len >> $udppath/fields_udp_all
    done

    for file in `ls $icmpstreampath`
    do
	#echo $file
	tshark -r $icmpstreampath/$file -T fields -E separator=, -e frame.time -e ip.src -e ip.dst >> $icmppath/fields_icmp_all
    done

    echo function ipv4_get_fields done! 
    echo #####################################
}

function ipv6_get_fields {
    echo #####################################
    echo functiong ipv6_get_fields start......
    
    if [ $# -ne 4 ] 
    then
	echo Usage:ipv6_get_fields tcppath udppath icmppath outpath
	return -1
    fi

    tcpstreampath=$1
    udpstreampath=$2
    icmpstreampath=$3
    outpath=$4

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
    
    echo function ipv6_get_fields done!
    echo ####################################
}
