#######jump.sh
#!/bin/bash
key_value(){
declare -A mapcount=()
while read line
do
key=`echo $line|cut -d ' ' -f 1`
value=`echo $line|cut -d ' ' -f 2`
mapcount["${key}"]="${value}"
done < file
if [ ! -s ./text ]; then
for g in ${!mapcount[@]}
do
    echo $g"|"${mapcount[$g]} >>text
done
fi
cat<<EOF
================Host List==============
$(cat text)
================Host End===============
EOF
read -p "Pls input a num.:" num
for g in ${!mapcount[@]}
do
case "$num" in
    ${g})
        echo "login in ${mapcount[$g]}."
        ssh ${mapcount[$g]}
        ;;
    *)
        echo"select error."
        esac
done
}

trapper(){
    trap ':'INT EXIT TSTP TERM HUP
}

main(){
while :
do
      trapper
      clear
      key_value
done
}
main