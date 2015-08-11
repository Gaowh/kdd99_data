#!/bin/sh

#绝对时间，源地址， 目的地址， 源端口  ，接下来的就是kdd99当中的特征了

file=$1

i=1
tot_line=`wc -l $file | awk '{print $1}'`
echo totle line: $tot_line

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

    #25th - 28th
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
    echo --31th: $nowstream 
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
	echo c: $c
	echo j: $j
	tot_stream=`expr $tot_stream + 1`
	c=`expr $c - 1`
	pre=`sed -n ''$j'p' $file`
	echo pre: $pre

	presport=`echo $pre | awk -F# '{print $4}'`
	prepro=`echo $pre | awk -F# '{print $6}'`
        presrc=`echo $pre | awk -F# '{print $2}'`
	predst=`echo $pre | awk -F# '{print $3}'`
	presrv=`echo $pre | awk -F# '{print $7}'`

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
	j=`expr $j - 1`
    done
    
    echo here
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
    i=`expr $i + 1`

    echo all: $nowstream 
    echo $nowstream | cut -d '#' -f 5- >> v1
done
