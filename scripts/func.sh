#!/bin/sh

function get_service {
#通过端口得到服务类型的函数
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

function pre_sort {
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



#时间格式：Jul#16#2015#20:25:12.625988000
#函数功能是对两个这样的时间进行相减，判断是否时间差在两秒之内
function time_sub {
    if [ $# -ne 2 ] 
    then
	echo -1
	return 
    fi

    time1=$1
    time2=$2
    
    sub=`expr $time1 - $time2`
    echo $sub
}
