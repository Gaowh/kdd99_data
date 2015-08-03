#!/bin/sh

#tcp 提取的字段内容和顺序
#1绝对时间，2相对时间，3源地址，4源端口，5目的地址，6目的端口，7数据长度， 8tcp分段错误，9tcp状态标识

#udp 提取的字段内容和顺序
#1绝对时间，2相对时间，3源地址，4源端口，5目的地址，6目的端口，7dup数据长度

#icmp 提取的字段内容和顺序
#1绝对时间，2相对时间，3源地址，4目的地址


function ipv4_get_fields {    
#需要传入四个参数，tcp流所在的目录， udp流所在的目录， icmp流所在的目录， 输出文件的保存目录
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

    mkdir $outpath/tcpfields
    mkdir $outpath/udpfields
    mkdir $outpath/icmpfields

    tcppath=$outpath/tcpfields
    udppath=$outpath/udpfields
    icmppath=$outpath/icmpfields

#提取tcp的字段，由于每个流对应多条数据，所以每一条流保存在单独的文件中

    i=1
    for file in `ls $tcpstreampath`
    do
	#echo $file
        tshark -r $tcpstreampath/$file -T fields -E separator=# -e frame.time -e frame.time_relative -e ip.src -e tcp.srcport\
	    	    -e ip.dst -e tcp.dstport -e tcp.len  -e tcp.segment.error -e tcp.flags >> $tcppath/fields_stream_$i
	i=`expr $i + 1`
    done

    
#提取udp字段，保存在一个文件中
    for file in `ls $udpstreampath`
    do
	#echo $file
	tshark -r $udpstreampath/$file -T fields -E separator=# -e frame.time -e frame.time_relative -e ip.src -e udp.srcport\
					   -e ip.dst -e udp.dstport -e udp.len >> $udppath/fields_udp_all
    done

#提取icmp字段，保存在一个文件中
    for file in `ls $icmpstreampath`
    do
	#echo $file
	tshark -r $icmpstreampath/$file -T fields -E separator=# -e frame.time -e frame.time_relative \
							       -e ip.src -e ip.dst >> $icmppath/fields_icmp_all
    done

    echo function ipv4_get_fields done! 
}



function ipv6_get_fields {
#需要传入四个参数，tcp流所在的目录， udp流所在的目录， icmp流所在的目录， 输出文件的保存目录
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

    mkdir $outpath/tcpfields
    mkdir $outpath/udpfields
    mkdir $outpath/icmpfields


    tcppath=$outpath/tcpfields
    udppath=$outpath/udpfields
    icmppath=$outpath/icmpfields

#提取tcp的字段

    i=1
    for file in `ls $tcpstreampath`
    do
	#echo $file
	tshark -r $tcpstreampath/$file -T fields -E separator=# -e frame.time -e frame.time_relative -e ipv6.src -e tcp.srcport\
	    -e ipv6.dst -e tcp.dstport -e tcp.len  -e tcp.segment.error -e tcp.flags >> $tcppath/fields_stream_$i
	i=`expr $i + 1`
    done

    i=1
    for file in `ls $udpstreampath`
    do
	#echo $file
	tshark -r $udpstreampath/$file -T fields -E separator=# -e frame.time -e frame.time_relative -e ipv6.src -e udp.srcport\
					   -e ipv6.dst -e udp.dstport >> $udppath/fields_udp_all
    done

    for file in `ls $icmpstreampath`
    do
	#echo $file
	tshark -r $icmpstreampath/$file -T fields -E separator=# -e frame.time -e frame.time_relative\
							       -e ipv6.src -e ipv6.dst >> $icmppath/fields_icmp_all
    done
    
    echo function ipv6_get_fields done!
}

