#!/bin/sh

function ipv4_tcp_get_kdd99 {
    if [ $# -ne 4]
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
	asbtime=`cat $file | sed -n '1p' | awk -F# '{print $1}'`
	kdd99data=$asbtime

	#  1、持续时间(现在假设是一个流的起始时间和结束时间都在一天之内，不会跨越天)
	start=`cat $file | sed -n '1p' | awk -F# '{print $2}'`
	end=`cat $file | sed -n '$p' | awk -F# '{print $2}'`
	
	time=`awk -v s=$start -v e=$end 'BEGIN{print(e-s)}'| awk -F. '{print $1}'`
	kdd99data=$kdd99data#$time

	#   2、协议类型，这里是tcp
	kdd99data=$kdd99data#tcp

	#   3、服务类型
	port=`cat $file | sed -n '1p' | awk -F# '{print($4,$6)}'`
	port1=`echo $port | awk '{print $1}'`
	port2=`echo $port | awk '{print $2}'`
	service=`get_tcp_service $port1 $port2`
	kdd99data=$kdd99data#$service

	#   4 tcp状态标志

	flag=`get_tcp_flag $fieldspath/$file`
	kdd99data=$kdd99data#$flag

	#   5 src_bytes 从源主机到目的主机的字节数

	src_bytes=`get_tcp_srcbytes $fieldspath/$file`
	kdd99data=$kdd99data#$src_bytes
	
	#   6 dst_bytes  从目的主机到源主机的字节数
	dst_bytes=`get_tcp_dstbytes $fieldspath/$file`
	kdd99data=$kdd99data#$dst_bytes

	#   7 land (这个标志暂时不处理)
	kdd99data=$kdd99data#-1

	#   8 wrong_fragment  tcp的错误分段数
	wrong_fragment=`get_tcp_wrong_fragment $fieldspath/$file`
	kdd99data=$kdd99data#
	
	#   9 urgent tcp加急包的个数
	urgent=`get_tcp_urgent_packets $fieldspath/$file`
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

    if [ $# -ne 2 ]
    then
	echo Usage:must specified two port
	return
    fi

    port1=$1
    port2=$2

    res=`sed /'$port1'/p pro_types`
}
