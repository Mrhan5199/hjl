host="127.0.0.1"
user="root"
password="Zswitch69686996"
dbName=$1
backupFileName="$1_`date +%Y-%m-%d`.sql"
tarFileName="$1_`date +%Y-%m-%d`.tar.gz"
echo $backupFileName
mysqldump   --quick  -u$user -h$host -p$password $dbName >/usr/local/freeswitch/recordings/backup/$backupFileName
cd /usr/local/freeswitch/recordings/backup/
tar -czvf $tarFileName $backupFileName
rm -f $backupFileName
 
fileToDelete="/usr/local/freeswitch/recordings/backup/$1_`date -d "7 days ago" +%Y-%m-%d`.tar.gz"
echo $fileToDelete
if [ -f "$fileToDelete" ]; then
rm $fileToDelete
fi
