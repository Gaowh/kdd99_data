#!/bin/sh

#这里的到的是一部分特征和一些辅助的特征，顺序如下：

#绝对时间，源地址， 目的地址， 源端口  ，接下来的就是kdd99当中的特征了

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
	
	#因为之后计算要用到绝对时间，所以这里每个数据中必须要将没个流的起始时间保存下来
	abstime=`sed -n '1p' $fieldspath/$file | awk -F# '{print $1}'`
	abstime=`date +%s -d "$abstime"`
	kdd99data=$abstime

	#必须先保存下源地址
	sip=`sed -n '1p' $fieldspath/$file | awk -F# '{print $3}'`
	kdd99data=$kdd99data#$sip

	#同上，还必须保存当前连接的目的地址
	ip=`sed -n '1p' $fieldspath/$file | awk -F# '{print $5}'`
	kdd99data=$kdd99data#$ip

	#同上，源端口也必须保存下来
	sport=`sed -n '1p' $fieldspath/$file | awk -F# '{print $4}'`
	kdd99data=$kdd99data#$sport
	

	####下面开始是一部分特征的提取###

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
	service=`get_service $port1 $port2`

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
	
	echo $kdd99data >> $oufile

    done
}

function ipv4_udp_get_kdd99 {
    if [ $# -ne 2 ]
    then
	echo "Usage: must specified stream infile and outfile"
	return
    fi

#fieldspath 是tcp流存放的目录
#outfile 是生成的数据保存的文件
    fieldspath=$1
    oufile=$2
    
    for file in `ls $fieldspath`;
    do
	#因为之后计算要用到绝对时间，所以这里每个数据中必须要将没个流的起始时间保存下来
	abstime=`sed -n '1p' $fieldspath/$file | awk -F# '{print $1}'`
	abstime=`date +%s -d "$abstime"`
	kdd99data=$abstime

	#必须先保存下源地址
	sip=`sed -n '1p' $fieldspath/$file | awk -F# '{print $3}'`
	kdd99data=$kdd99data#$sip

	#同上，还必须保存当前连接的目的地址
	ip=`sed -n '1p' $fieldspath/$file | awk -F# '{print $5}'`
	kdd99data=$kdd99data#$ip

	#同上，源端口也必须保存下来
	sport=`sed -n '1p' $fieldspath/$file | awk -F# '{print $4}'`
	kdd99data=$kdd99data#$sport
	

	#1 持续时间为0
	kdd99data=$kdd99data#0
	echo time: 0
	#2 协议类型为udp
	kdd99data=$kdd99data#udp
	echo pro: udp
	#3 服务类型
	port=`sed -n '1p' $fieldspath/$file | awk -F# '{print($4,$6)}'`
	port1=`echo $port | awk '{print $1}'`
	port2=`echo $port | awk '{print $2}'`
	service=`get_service $port1 $port2`
	
	if [ -z "$service" ]
	then
	    service=unknown
	fi

	echo sevice: $service
	kdd99data=$kdd99data#$service
	
	# 接下来的4-22是用来描述tcp的，对于udp这里全部置0
    	i=4
	while [ $i -lt 23 ]
	do
	    kdd99data=$kdd99data#0
	    i=`expr $i + 1`
	done
	echo $kdd99data
	echo $kdd99data >> $oufile
    done
} 

function ipv4_icmp_get_kdd99 {
#对于icmp来说，所有的特征中只有协议类型字段有效，其余的全部置0 
    
    if [ $# -ne 2 ]
    then
	echo "Usage: must specified stream fields path and outfile"
	return
    fi

#fieldspath 是流存放的目录
#outfile 是生成的数据保存的文件
    fieldspath=$1
    oufile=$2
    
    for file in `ls $fieldspath`;
    do
	#因为之后计算要用到绝对时间，所以这里每个数据中必须要将没个流的起始时间保存下来
	abstime=`sed -n '1p' $fieldspath/$file | awk -F# '{print $1}'`
	abstime=`date +%s -d "$abstime"`
	kdd99data=$abstime

	#必须先保存下源地址
	sip=0
	kdd99data=$kdd99data#$sip

	#同上，还必须保存当前连接的目的地址
	ip=0
	kdd99data=$kdd99data#$ip

	#同上，源端口也必须保存下来
	sport=0
	kdd99data=$kdd99data#$sport

	#1 持续时间为0
	kdd99data=$kdd99data#0
	echo time: 0
	#2 协议类型为icmp
	kdd99data=$kdd99data#icmp
	echo pro: icmp

	#之后的所有特征对icmp无效，全部置为0
	i=3
	while [ $i -lt 23 ]
	do
	    kdd99data=$kdd99data#0
	    i=`expr $i + 1`
	done
	echo $kdd99data >> $oufile
    done
}

