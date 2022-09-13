user=xxxx
password=xxxx
dst_ip=xxxx



# 数据汇总的csv文件的路径
csv_path=./out.csv
# 重复迁移的次数
n_mig=5

for ((i=0;i<$n_mig;i++))
do

# echo "$(date) ---> no container 101, waiting"

mkdir ./$i


# 每5s查询一次，如果有容器实例名称为101，则向后进行
while :
do 
a=$(vzlist -a |grep '101'|grep -c 'running')
if [ $a -gt 0 ]; then
  break
else
  echo "$(date) ---> no container 101, waiting"
fi
sleep 5
# echo "$(date) ---> no container 101"
done


echo -e "\n\n\nprepare to migrate"
sleep 5

# do some migration
vzmigrate --online --keep-images $user:$password@$dst_ip 101 && echo "done"

# phaul.log路径
log=/var/log/phaul.log
cp $log ./$i/


img_path=`tail -1 $log |awk {'printf $8'}`
echo $img_path

# echo $img_path
# echo $fs_trans

# 输出文件系统数据量
# fs_data=`cat $log|sed -n 27p|awk {'printf $7'}`
tmp=`cat $log|grep 'Fs driver transfer'|awk '{print $7,'\n'}'`
pre_fs_data=`echo $tmp|awk '{print $1}'`
fs_data=`echo $tmp|awk -F " " '{ for(i=1;i<=NF;i++) sum+=$i; print sum}'`
echo pre_fs_data $pre_fs_data
echo fs_data $fs_data

# 输出镜像数据量
img_data=`du -sh $img_path|awk '{print $1}'|tail -1`
echo img_data $img_data


# 输出 total time
tmp=`cat $log|grep 'total time'|awk '{print $7,'\n'}'`
total_time=${tmp#*~}
echo total_time $total_time


# 输出 frozen time
tmp=`cat $log|grep 'frozen time'|awk '{print $7,'\n'}'`
frozen_time=${tmp#*~}
echo frozen_time $frozen_time

# 输出 restore time
tmp=`cat $log|grep 'restore time'|awk '{print $7,'\n'}'`
restore_time=${tmp#*~}
echo restore_time $restore_time

# 输出 img sync time
tmp=`cat $log|grep 'img sync time'|awk '{print $8,'\n'}'`
img_time=${tmp#*~}
echo img_time $img_time


if [ ! -f "$csv_path" ]; then
  echo 'img_path, pre_fs_data, fs_data, img_data, total_time, frozen_time, restore_time, img_time'>$csv_path
fi

echo $img_path, $pre_fs_data, $fs_data, $img_data, $total_time, $frozen_time, $restore_time, $img_time>>$csv_path


# 备份img文件
cp -r $(dirname "$img_path") ./$i/$(basename $(dirname "$img_path"))

# 删除phaul.log
rm -f $log

echo -e "\n\n\n"

done