
while :
do 
a=$(ls -al |grep -c 'aptx')
if [ $a -gt 1 ];
then
break
fi
sleep 1
echo 'a'
done
