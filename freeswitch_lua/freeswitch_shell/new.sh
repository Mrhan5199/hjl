###number####
###passwd####
###passwd和number长度大小相等
###配置多个xml文件
for i in `cat number`; do sed -e s/10086/$i/g 10086.xml > $i.xml ; done
###修改每个xml的密码

#!/bin/bash
b=1
c=1
for j in `cat passwd`; do
        array[$b]=$j
        let b++
done
for i in `cat number`; do
        sed -i s/wedd86/${array[$c]}/g $i.xml
        let c++
done
