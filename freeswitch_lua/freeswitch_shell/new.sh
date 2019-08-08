###passwd和number长度大小相等
###配置多个xml文件
##for i in `cat number`; do sed -e s/10086/$i/g 10086.xml > $i.xml ; done
###修改每个xml的密码
##example.xml
#!/bin/bash
passwd=`cat $1.xml|grep password|awk '{print $3}'|cut -d = -f2| tr -d -c "[a-zA-z0-9]\n"`
for i in `cat number`; do sed -e s/$1/$i/g $1.xml > $i.xml ; done
b=1
c=1
for j in `cat passwd`; do
        array[$b]=$j
        let b++
done
for i in `cat number`; do
        sed -i s/${passwd}/${array[$c]}/g $i.xml
        let c++
done
