TS="`date +%d_%B_%Y-%Hh-%Mm-%Ss`"

Master_dir="/var/log/scripts/master_check/"

Master_log="$Master_dir$TS.master"



echo "---------------------------------------------------------------------" >> $Master_log



uptime >> $Master_log



echo "---------------------------------------------------------------------" >> $Master_log



mysql -e "show slave status \G" >> $Master_log



echo "---------------------------------------------------------------------" >> $Master_log



mysql -e "select * from information_schema.processlist where command!='sleep' \G show engine innodb status \G" >> $Master_log



echo "---------------------------------------------------------------------" >> $Master_log



echo "Users connected from hosts" >> $Master_log



mysql -e "select count(*) , user, substring_index(host,':',1) HOSTS from information_schema.processlist group by user,HOSTS;;" >> $Master_log

mysql -e "select count(*), user from information_schema.processlist  group by user;" >> $Master_log



echo "-------------SLEEPING USERS ---------------" >> $Master_log

mysql -e "select count(*), user from information_schema.processlist  where command='sleep' group by user;" >> $Master_log

echo "---------------------------------------------------------------------" >> $Master_log



mysql -e "select count(*) from information_schema.processlist;" >> $Master_log



echo "---------------------------------------------------------------------" >> $Master_log



MORON=`mysql --skip-column-names -e "select IFNULL(max(TIME),0) as MQ from information_schema.processlist where command!='sleep' and time>3 and COMMAND!='Binlog Dump' and COMMAND!='Connect';"`

if [ $MORON -gt 3 ]

then

msg="`hostname` Master Secs Query Ran greater than $MORON - `date `"

db_health_sms_string="`echo $msg | sed 's/ /%20/g' | awk NF=NF RS= OFS=%0A`"

echo $db_health_sms_string

#curl -i "http://mysql-monitoring-notif-sms.olacabs.net/notif/send_sms.php?msg=$db_health_sms_string"

fi

mysql -e "SELECT GROUP_CONCAT(TIMESTAMPDIFF(SECOND, b.trx_started, CURRENT_TIMESTAMP)order by b.trx_started ASC) AS block_time,GROUP_CONCAT(b.trx_mysql_thread_id order by b.trx_mysql_thread_id ASC) AS blocking_thread,GROUP_CONCAT(b.trx_query order by b.trx_query ASC) AS blocking_query, GROUP_CONCAT(TIMESTAMPDIFF(SECOND, r.trx_wait_started, CURRENT_TIMESTAMP)order by r.trx_wait_started ASC) AS wait_time,GROUP_CONCAT(r.trx_mysql_thread_id order by r.trx_mysql_thread_id ASC) AS waiting_thread, GROUP_CONCAT(r.trx_query order by r.trx_query asc) AS waiting_query FROM INFORMATION_SCHEMA.INNODB_LOCK_WAITS AS w INNER JOIN INFORMATION_SCHEMA.INNODB_TRX AS b ON b.trx_id = w.blocking_trx_id INNER JOIN INFORMATION_SCHEMA.INNODB_TRX AS r ON r.trx_id = w.requesting_trx_id INNER JOIN INFORMATION_SCHEMA.INNODB_LOCKS AS l ON w.requested_lock_id = l.lock_id LEFT JOIN INFORMATION_SCHEMA.PROCESSLIST AS p ON p.id = b.trx_mysql_thread_id \G" >> $Master_log



find /var/log/scripts/master_check/ -mtime +30 -exec rm -f {} \;
