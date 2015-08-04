#!/bin/sh

function ipv4_tcp_get_kdd99 {
    if [ $# -ne 2 ]
    then
	echo "Usage: must specified stream fields path and outfile"
	return
    fi

#fieldspath 是tcp流存放的目录
#outfile 是生成的数据保存的文件
    fieldspath=$1
    oufile=$2

    for file in `ls $fieldspath`
    do
	
	#因为之后计算要用到相对时间，所以这里每个数据中必须要将没个流的起始时间保存下来
	abstime=`sed -n '1p' $fieldspath/$file | awk -F# '{print $1}'`
	kdd99data=$abstime

	#  1、持续时间(现在假设是一个流的起始时间和结束时间都在一天之内，不会跨越天)
	start=` sed -n '1p' $fieldspath/$file | awk -F# '{print $2}'`
	end=`sed -n '$p' $fieldspath/$file | awk -F# '{print $2}'`
	
	time=`awk -v s=$start -v e=$end 'BEGIN{print(e-s)}'| awk -F. '{print $1}'`
#	echo time: $time
	kdd99data=$kdd99data#$time

	#   2、协议类型，这里是tcp
#echo protocol: tcp
	kdd99data=$kdd99data#tcp

	#   3、服务类型
	port=`sed -n '1p' $fieldspath/$file | awk -F# '{print($4,$6)}'`
	port1=`echo $port | awk '{print $1}'`
	port2=`echo $port | awk '{print $2}'`
	service=`get_tcp_service $port1 $port2`

#	echo sevice: $service
	kdd99data=$kdd99data#$service

	#   4 tcp状态标志

	flag=`get_tcp_flag $fieldspath/$file`
#	echo flag: $flag
	kdd99data=$kdd99data#$flag

	#   5 src_bytes 从源主机到目的主机的字节数

	src_bytes=`get_tcp_srcbytes $fieldspath/$file`
#	echo src_bytes: $src_bytes
	kdd99data=$kdd99data#$src_bytes
	
	#   6 dst_bytes  从目的主机到源主机的字节数
	dst_bytes=`get_tcp_dstbytes $fieldspath/$file`
#	echo dst_bytes: $dst_bytes
	kdd99data=$kdd99data#$dst_bytes

	#   7 land (这个标志暂时不处理)
	kdd99data=$kdd99data#-1

	#   8 wrong_fragment  tcp的错误分段数
	wrong_fragment=`get_tcp_wrong_fragment $fieldspath/$file`
#	echo wrong_fragment: $wrong_fragment
	kdd99data=$kdd99data#$wrong_fragment
	
	#   9 urgent tcp加急包的个数
	urgent=`get_tcp_urgent_packets $fieldspath/$file`
#	echo urgent: $urgent
	kdd99data=$kdd99data#$urgent

	########## 以上是tcp连接的9个基本特征 ############
	

	########## 下面是13个tcp连接的内容特征 暂时不处理  #######

	i=1
	while [ $i -lt 14 ]
	do
	    kdd99data=$kdd99data#-1
	    i=`expr $i + 1`
	done

	# 接下来是tcp基于时间和基于流量的特征 一共19种
	# 但是这些特征要在把所有的基本特征提取完成之后才进行统计的
	# 所以这里并不处理	
	
	echo $kdd99data
	echo Done!

    done
}

function get_tcp_service {
#通过端口得到服务类型的函数
#测试ok

    if [ $# -ne 2 ]
    then
	echo Usage: need port1 port2
	return
    fi

    port1=$1
    port2=$2

    res=`sed -n '/:'$port1'$/p' ../include/pro_types | awk -F: '{print $1}'`
    if [ -n "$res" ]
    then
	echo $res
	return
    fi
    
    res=`sed -n '/:'$port2'$/p' ../include/pro_types | awk -F: '{print $1}'`
    if [ -n "$res" ]
    then
	echo $res
	return
    fi
}

function get_tcp_flag {
#获得tcp标志的状态

    #暂时先不处理， 用-1代替
    if [ $# -ne 1 ]
    then
	echo Usage: need infile
	return
    fi
    
    file=$1

    echo -1
}

function get_tcp_srcbytes {
#测试ok
    
    if [ $# -ne 1 ]
    then
	echo Usage: need infile
	return
    fi

    file=$1

    ip_src=`sed -n '1p' $file | awk -F# '{print $3}'`  #取得源地址
    
    src_bytes=`awk -F# -v srcbytes=0 -v ipsrc=$ip_src '$3==ipsrc{srcbytes = srcbytes+$7; print srcbytes}' $file | sed -n '$p'`
    echo $src_bytes
}


function get_tcp_dstbytes {
#测试ok
    if [ $# -ne 1 ]
    then 
	return
    fi

    file=$1
    
    ip_dst=`sed -n '1p' $file | awk -F# '{print $5}'`  #取得目的地址
    
    dst_bytes=`awk -F# -v dstbytes=0 -v ipdst=$ip_dst '$3==ipdst{dstbytes = dstbytes+$7; print dstbytes}' $file | sed -n '$p'`
    if [ -z "$dst_bytes" ] #这里处理的是流中只有一条syn包的时候， 上一条命令会返回一个空的dst_bytes, 但是期望的是这种情况返回0
    then
	echo 0
    else
	echo $dst_bytes
    fi
}

function get_tcp_wrong_fragment {
#测试ok
    if [ $# -ne 1 ] ; then
	echo Usage: need infile
	return
    fi

    file=$1

    total=`awk -F# -v tot=0 '{tot = tot+$8; print tot}' $file | sed -n '$p'`
    echo $total
}

function get_tcp_urgent_packets {
#测试ok

    if [ $# -ne 1 ] ; then
	echo Usage: need infile
	return
    fi

    file=$1

    total=`awk -F# -v tot=0 '{if(strtonum("$9") >= 32) tot=tot+1; print tot}' $file | sed -n '$p'`
    echo $total
} 

