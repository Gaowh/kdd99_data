#!/bin/sh

function get_service {
#通过端口得到服务类型的函数, 传入两个参数（端口号），返回和某种服务匹配的服务
#测试ok

    if [ $# -ne 2 ]
    then
	echo Usage: need port1 port2
	return
    fi

    port1=$1
    port2=$2

    res=`sed -n '/:'$port1'$/p' ./include/pro_types | awk -F: '{print $1}'`
    if [ -n "$res" ]
    then
	echo $res
	return
    fi
    
    res=`sed -n '/:'$port2'$/p' ./include/pro_types | awk -F: '{print $1}'`
    if [ -n "$res" ]
    then
	echo $res
	return
    fi
}

function get_tcp_flag {
#获得tcp标志的状态，传入的参数是一个tcp流的文件，暂时还没有处理

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
#获取一个tcp流从源端到目的端的数据大小，传入的参数是一个tcp流文件
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
#获取一个tcp流从目的端到源端的数据大小，传入的参数是一个tcp流文件
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
#返回tcp流中错误分段的数量，传入的参数是tcp流文件
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
#返回tcp流中被标记为紧急数据的数据包的数量，传入的参数是一个tcp流文件

#测试ok

    if [ $# -ne 1 ] ; then
	echo Usage: need infile
	return
    fi

    file=$1

    total=`awk -F# -v tot=0 '{if(strtonum("$9") >= 32) tot=tot+1; print tot}' $file | sed -n '$p'`
    echo $total
}

function pre_sort {
#这个函数对初步的数据按照时间先后对文件数据排序
#该文件是由ipv4_get_pre_data.sh 和 ipv6_get_pre_data.sh处理后的数据

    if [ $# -ne 1 ]
    then
	echo Usage: need infile
	return
    fi

    data=$1
    
#   LC_TIME=en_US.UTF-8
#   export LC_TIME
#   sed -n 's/,//; s/ /#/gp' $data | sort -t '#' -k 3n -k 1M -k 2n -k 4 -o $data
#   LC_TIME=zh_CN.UTF-8
#   export LC_TIME

    sort -t '#' -k 1n $data -o $data
}

function get_kdd99_all {
#绝对时间，源地址， 目的地址， 源端口  ，接下来的就是kdd99当中的特征了

	if [ $# -ne 2 ]
	then
	    echo Usage: need infile and oufile
	    return
	fi

	file=$1
	outfile=$2

	i=1
	tot_line=`wc -l $file | awk '{print $1}'`
	#echo totle line: $tot_line

	while [ $i -le $tot_line ] 
	do
		
		nowstream=`sed -n ''$i'p' $file`
		echo nowstream: $nowstream
			
		pro=`echo $nowstream | awk -F# '{print $6}'`
		time=`echo $nowstream | awk -F# '{print $1}'`
		dst=`echo $nowstream | awk -F# '{print $3}'`
		srv=`echo $nowstream | awk -F# '{print $7}'`
		#echo time: $time 
		
		# 对于icmp没有连接概念，也没有服务类型概念，所以这里所有的特征全部不处理
		if [ "$pro" = "icmp" ]
		then
			s=23
			while [ $s -le 41 ]
			do
				nowstream=$nowstream#-1
				s=`expr $s + 1`
			done
			echo $nowstream >> $outfile
			i=`expr $i + 1`
			continue
		fi

		tot_stream=0
		count=0
		srv_count=0
		serror=0
		srv_serror=0
		rerror=0
		srv_rerror=0
		same_srv=0
		diff_srv=0
		src_diff_host=0

		j=`expr $i - 1`
		while [ $j -gt 0 ]
		do
			pre=`sed -n ''$j'p' $file`
			prepro=`echo $pre | awk -F# '{print $6}'`
			pretime=`echo $pre | awk -F# '{print $1}'`
			presrv=`echo $pre | awk -F# '{print $7}'`
			preflag=`echo $pre | awk -F# '{print $8}'`
			predst=`echo $pre | awk -F# '{print $3}'`

			#echo pretime: $pretime
			timeabs=`expr $time - $pretime`
			#echo $timeabs

			if [ $timeabs -gt 2 ]
			then
				echo out of range
				break
			fi
			
			#前2s内总的流数量
			tot_stream=`expr $tot_stream + 1`
			j=`expr $j - 1`

			#判断是否是icmp，如果是的话直接不用考虑
			if [ "$presrv" = "icmp" ]
			then
				continue
			fi
			
			# 判断和当前的流是否是一个传输协议（udp或tcp）
			if [ "$pro" != "$prepro" ] 
			then
				continue
			fi
			
			#下面是基于时间的网络流量统计特征， 一共9种
			if [ "$dst" == "$predst" ] 
			then
				count=`expr $count + 1`
			fi

			if [ "$srv" == "$presrv" ]
			then
				srv_count=`expr $srv_count + 1`
			fi

			#接下来4种需要tcp标志的暂时不处理
			#
			#
			#
			#

			if [ "$dst" = "$predst" ] && [ "$srv" = "$presrv" ]
			then
				same_srv=`expr $same_srv + 1`
			fi

			if [ "$dst" == "$predst" ] && [ "$srv" != "$presrv" ]
			then
				diff_srv=`expr $diff_srv + 1`
			fi

			if [ "$srv" == "$presrv" ] && [ "$dst" != "$predst" ] 
			then
				src_diff_host=`expr $src_diff_host + 1`
			fi
		done
		
		
		echo tot_stream: $tot_stream
		echo count: $count
		echo srv_count: $srv_count
		echo serror: $serror
		echo srv_serror: $srv_serror
		echo rerror: $rerror
		echo srv_rerror: $srv_rerror
		echo same_srv: $same_srv
		echo diff_srv: $diff_srv
		echo src_diff_host: $src_diff_host
		
		#23th
		nowstream=$nowstream#$count

		#24th
		nowstream=$nowstream#$srv_count

		#25th - 28th,这四种和tcp的flags有关，暂时不处理
		nowstream=$nowstream#-1
		nowstream=$nowstream#-1
		nowstream=$nowstream#-1
		nowstream=$nowstream#-1

		#29th
		tmp=`awk -v tot=$tot_stream -v val=$same_srv 'BEGIN{if(tot==0) printf("%.2f", 0); else printf("%.2f", val/tot)}'`
		nowstream=$nowstream#$tmp

		#30th
		tmp=`awk -v tot=$tot_stream -v val=$diff_srv 'BEGIN{if(tot==0) printf("%.2f", 0); else printf("%.2f", val/tot)}'`
		nowstream=$nowstream#$tmp

		#31th
		tmp=`awk -v tot=$tot_stream -v val=$srv_diff_host 'BEGIN{if(tot==0) printf("%.2f", 0); else printf("%.2f", val/tot)}'`
		nowstream=$nowstream#$tmp 


		#下面的内容是给予主机的网络流量统计特征,总共10种
		tot_stream=0
		dst_host_count=0
		dst_host_srv_count=0
		dst_host_same_srv=0
		dst_host_diff_srv=0
		dst_host_same_src_port=0
		dst_host_srv_diff_host=0
		dst_host_serror=0
		dst_host_srv_serror=0
		dst_host_rerror=0
		dst_host_srv_rerror=0
		
		sport=`echo $nowstream | awk -F# '{print $4}'`
		pro=`echo $nowstream | awk -F# '{print $6}'`
		src=`echo $nowstream | awk -F# '{print $2}'`
		dst=`echo $nowstream | awk -F# '{print $3}'`
		srv=`echo $nowstream | awk -F# '{print $7}'`

		j=`expr $i - 1`
		c=100
		while [ $c -gt 0 ] && [ $j -gt 0 ]
		do
			#echo c: $c
			#echo j: $j
			tot_stream=`expr $tot_stream + 1`
			c=`expr $c - 1`
			pre=`sed -n ''$j'p' $file`
			#echo pre: $pre

			presport=`echo $pre | awk -F# '{print $4}'`
			prepro=`echo $pre | awk -F# '{print $6}'`
			presrc=`echo $pre | awk -F# '{print $2}'`
			predst=`echo $pre | awk -F# '{print $3}'`
			presrv=`echo $pre | awk -F# '{print $7}'`
			j=`expr $j - 1`
			
			#判断是否是icmp，如果是的话直接不用考虑
			if [ "$presrv" = "icmp" ]
			then
				continue
			fi
			
			# 判断和当前的流是否是一个传输协议（udp或tcp）
			if [ "$pro" != "$prepro" ] 
			then
				continue
			fi


			if [ "$dst" = "$predst" ]
			then
				dst_host_count=`expr $dst_host_count + 1`
			fi

			if [ "$dst" = "$predst" ] && [ "$srv" = "$presrv" ]
			then
				dst_host_srv_count=`expr $dst_host_srv_count + 1`
			fi

			if [ "$dst" = "$predst" ] && [ "$srv" != "$presrv" ]
			then
				dst_host_diff_srv=`expr $dst_host_diff_srv + 1`
			fi
			
			if [ "$dst" = "$predst" ] && [ "$sport" = "$presport" ]
			then
				dst_host_same_src_port=`expr $dst_host_same_port + 1`
			fi

			if [ "$dst" = "$predst" ] && [ "$srv" = "$presrv" ] && [ "$src" != "$presrc" ]
			then
				dst_host_srv_diff_host=`expr $dst_host_srv_diff_host + 1`
			fi
		done
		
		echo tot_stream: $tot_stream
		echo dst_host_count: $dst_host_count
		echo dst_host_srv_count: $dst_host_srv_count
		echo dst_host_same_srv: $dst_host_same_srv
		echo dst_host_diff_srv: $dst_host_diff_srv
		echo dst_host_same_port: $dst_host_same_src_port
		echo dst_host_srv_diff_host: $dst_host_srv_diff_host
		echo dst_host_serror: $dst_host_serror
		echo dst_host_srv_serror: $dst_host_srv_serror
		echo dst_host_rerror: $dst_host_rerror
		echo dst_host_srv_rerror: $dst_host_srv_rerror
		# 32th
		nowstream=$nowstream#$dst_host_count
		
		# 33th
		nowstream=$nowstream#$dst_host_srv_count

		# 34th
		tmp=`awk -v tot=$tot_stream -v val=$dst_host_srv_count 'BEGIN{if(val==0) printf("%.2f",0); else printf("%.2f", val/tot)}'`
		nowstream=$nowstream#$tmp

		#35th
		tmp=`awk -v tot=$tot_stream -v val=$dst_host_diff_srv 'BEGIN{if(tot==0) printf("%.2f",0); else printf("%.2f",val/tot)}'`
		nowstream=$nowstream#$tmp

		#36th
		tmp=`awk -v tot=$tot_stream -v val=$dst_host_same_src_port 'BEGIN{if(tot==0) printf("%.2f", 0); else printf("%.2f", val/tot)}'`
		nowstream=$nowstream#$tmp

		#37th
		tmp=`awk -v tot=$tot_stream -v val=$dst_host_srv_diff_host 'BEGIN{if(tot==0) printf("%.2f" ,0); else printf("%.2f", val/tot)}'`
		nowstream=$nowstream#$tmp

		#38-41th
		nowstream=$nowstream#0
		nowstream=$nowstream#0
		nowstream=$nowstream#0
		nowstream=$nowstream#0
		i=`expr $i + 1`

		echo all: $nowstream 
		echo
		echo $nowstream | cut -d '#' -f 5- >> $outfile 
	done
}
