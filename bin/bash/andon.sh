# !/bin/bash
# xtranghero
# 2018-02-08

PATH=$PATH:/c/xampp/mysql/bin

DATE2EXTRACT=`date +%Y-%m-%d`
CURRENT_TIME=`date +"%T"`
AM_OR_PM=`date +"%p"`

now=$(date +%s)
AM_start_of_shift=$(date --date="Today 06:40:00" +%s)
AM_end_of_shift=$(date --date="Today 18:39:59" +%s)
PM_start_of_shift=$(date --date="Today 18:40:00" +%s)
PM_premid_shift=$(date --date="Today 23:59:00" +%s)
PM_postmid_shift=$(date --date="Today 00:00:00" +%s)
PM_end_of_shift=$(date --date="Today 06:39:59" +%s)

HOST="localhost"
USER="root"
PASS="2qhls34r"
DB="dbauth"

MESHOST=$(mysql -h$HOST -u $USER -p$PASS $DB -s<<<"SELECT hostname FROM tbl_mes_details  WHERE id = 2;") #AWS MES DB
MESUSER=$(mysql -h$HOST -u $USER -p$PASS $DB -s<<<"SELECT user FROM tbl_mes_details  WHERE id = 2;") 
MESPASS=$(mysql -h$HOST -u $USER -p$PASS $DB -s<<<"SELECT pass FROM tbl_mes_details  WHERE id = 2;")
MESDB=$(mysql -h$HOST -u $USER -p$PASS $DB -s<<<"SELECT db FROM tbl_mes_details WHERE id = 2;")

CLOUDHOST=$(mysql -h$HOST -u $USER -p$PASS $DB -s<<<"SELECT hostname FROM tbl_cloud_details;") #AWS APPS DB
CLOUDUSER=$(mysql -h$HOST -u $USER -p$PASS $DB -s<<<"SELECT user FROM tbl_cloud_details;") 
CLOUDPASS=$(mysql -h$HOST -u $USER -p$PASS $DB -s<<<"SELECT pass FROM tbl_cloud_details;")
CLOUDDB=$(mysql -h$HOST -u $USER -p$PASS $DB -s<<<"SELECT db FROM tbl_cloud_details;")

PROCESSLIST=$(mysql -h$CLOUDHOST -u $CLOUDUSER -p$CLOUDPASS $CLOUDDB -s<<<"SELECT process FROM tbl_process_list;") # process list array

L_hourly_AM(){ # Hourly Outs for Linearity
    
    mysql -h$MESHOST -u $MESUSER -p$MESPASS $MESDB -e "SET time_zone = '+08:00'; SELECT process_id, SUM(out_qty) AS out_qty, HOUR(DATE_ADD(date_time, INTERVAL -390 MINUTE)) + 1 AS fab_hour , count(*) AS num_moves FROM MES_OUT_DETAILS WHERE process_id = '$process' AND DATE(DATE_ADD(date_time, INTERVAL -390 MINUTE)) = DATE(DATE_ADD('$DATE2EXTRACT', INTERVAL -0 MINUTE)) GROUP BY process_id, HOUR(DATE_ADD(date_time, INTERVAL -390 MINUTE));" | sed 's/\t/,/g' > ../draw/$DATE2EXTRACT-$shift-hourlyouts-$process.csv 
    
    cp ../draw/$DATE2EXTRACT-$shift-hourlyouts-$process.csv ../L/$DATE2EXTRACT-$shift-hourlyouts-$process.csv
}

L_hourly_PREPM(){ # Hourly Outs for Linearity
    
    mysql -h$MESHOST -u $MESUSER -p$MESPASS $MESDB -e "SET time_zone = '+08:00'; SELECT process_id, SUM(out_qty) AS out_qty, HOUR(DATE_ADD(date_time, INTERVAL -1110 MINUTE)) + 1 AS fab_hour , count(*) AS num_moves FROM MES_OUT_DETAILS WHERE process_id = '$process' AND DATE(DATE_ADD(date_time, INTERVAL -1110 MINUTE)) = DATE(DATE_ADD('$DATE2EXTRACT', INTERVAL -0 MINUTE)) GROUP BY process_id, HOUR(DATE_ADD(date_time, INTERVAL -1110 MINUTE));" | sed 's/\t/,/g' > ../draw/$DATE2EXTRACT-$shift-hourlyouts-$process.csv 
    
    cp ../draw/$DATE2EXTRACT-$shift-hourlyouts-$process.csv ../L/$DATE2EXTRACT-$shift-hourlyouts-$process.csv
}

L_hourly_POSTPM(){ # Hourly Outs for Linearity
    
    mysql -h$MESHOST -u $MESUSER -p$MESPASS $MESDB -e "SET time_zone = '+08:00'; SELECT process_id, SUM(out_qty) AS out_qty, HOUR(DATE_ADD(date_time, INTERVAL -1110 MINUTE)) + 1 AS fab_hour , count(*) AS num_moves FROM MES_OUT_DETAILS WHERE process_id = '$process' AND DATE(DATE_ADD(date_time, INTERVAL -1110 MINUTE)) = DATE(DATE_ADD('$DATE2EXTRACT', INTERVAL -1 DAY)) GROUP BY process_id, HOUR(DATE_ADD(date_time, INTERVAL -1110 MINUTE));" | sed 's/\t/,/g' > ../draw/$DATE2EXTRACT-$shift-hourlyouts-$process.csv 
    
    cp ../draw/$DATE2EXTRACT-$shift-hourlyouts-$process.csv ../L/$DATE2EXTRACT-$shift-hourlyouts-$process.csv
}

Y_outsAndScrap_AM(){ # Outs and Scrap for Yield per tool

    mysql -h$MESHOST -u $MESUSER -p$MESPASS $MESDB -e "SET time_zone = '+08:00'; SELECT A.eq_name AS eq_name, A.scrap_qty AS scrap_qty, B.out_qty AS out_qty FROM   (SELECT B.eq_name, SUM(A.scrap_qty) AS scrap_qty    FROM MES_SCRAP_DETAILS A      JOIN MES_EQ_INFO B  ON A.eq_id = B.eq_id     WHERE DATE(DATE_ADD(A.date_time, INTERVAL -390 MINUTE)) = DATE(DATE_ADD('$DATE2EXTRACT', INTERVAL -0 MINUTE))   AND A.process_id = '$process'     GROUP BY B.eq_name ) A JOIN   (SELECT B.eq_name, SUM(A.out_qty) AS out_qty     FROM MES_OUT_DETAILS A     JOIN MES_EQ_INFO B   ON A.eq_id = B.eq_id    WHERE DATE(DATE_ADD(A.date_time, INTERVAL -390 MINUTE)) = DATE(DATE_ADD('$DATE2EXTRACT', INTERVAL -0 MINUTE))   AND A.process_id = '$process'  GROUP BY B.eq_name ) B ON A.eq_name = B.eq_name;" | sed 's/\t/,/g' > ../draw/$DATE2EXTRACT-$shift-outsAndScrap-$process.csv 

    cp ../draw/$DATE2EXTRACT-$shift-outsAndScrap-$process.csv ../Y/$DATE2EXTRACT-$shift-outsAndScrap-$process.csv
}

Y_outsAndScrap_PREPM(){ # Outs and Scrap for Yield per tool

    mysql -h$MESHOST -u $MESUSER -p$MESPASS $MESDB -e "SET time_zone = '+08:00'; SELECT A.eq_name AS eq_name, A.scrap_qty AS scrap_qty, B.out_qty AS out_qty FROM   (SELECT B.eq_name, SUM(A.scrap_qty) AS scrap_qty    FROM MES_SCRAP_DETAILS A      JOIN MES_EQ_INFO B  ON A.eq_id = B.eq_id     WHERE DATE(DATE_ADD(A.date_time, INTERVAL -1110 MINUTE)) = DATE(DATE_ADD('$DATE2EXTRACT', INTERVAL -0 MINUTE))   AND A.process_id = '$process'     GROUP BY B.eq_name ) A JOIN   (SELECT B.eq_name, SUM(A.out_qty) AS out_qty     FROM MES_OUT_DETAILS A     JOIN MES_EQ_INFO B   ON A.eq_id = B.eq_id    WHERE DATE(DATE_ADD(A.date_time, INTERVAL -1110 MINUTE)) = DATE(DATE_ADD('$DATE2EXTRACT', INTERVAL -0 MINUTE))   AND A.process_id = '$process'  GROUP BY B.eq_name ) B ON A.eq_name = B.eq_name;" | sed 's/\t/,/g' > ../draw/$DATE2EXTRACT-$shift-outsAndScrap-$process.csv 

    cp ../draw/$DATE2EXTRACT-$shift-outsAndScrap-$process.csv ../Y/$DATE2EXTRACT-$shift-outsAndScrap-$process.csv
}

Y_outsAndScrap_POSTPM(){ # Outs and Scrap for Yield per tool

    mysql -h$MESHOST -u $MESUSER -p$MESPASS $MESDB -e "SET time_zone = '+08:00'; SELECT A.eq_name AS eq_name, A.scrap_qty AS scrap_qty, B.out_qty AS out_qty FROM   (SELECT B.eq_name, SUM(A.scrap_qty) AS scrap_qty    FROM MES_SCRAP_DETAILS A      JOIN MES_EQ_INFO B  ON A.eq_id = B.eq_id     WHERE DATE(DATE_ADD(A.date_time, INTERVAL -1110 MINUTE)) = DATE(DATE_ADD('$DATE2EXTRACT', INTERVAL -1 DAY))   AND A.process_id = '$process'     GROUP BY B.eq_name ) A JOIN   (SELECT B.eq_name, SUM(A.out_qty) AS out_qty     FROM MES_OUT_DETAILS A     JOIN MES_EQ_INFO B   ON A.eq_id = B.eq_id    WHERE DATE(DATE_ADD(A.date_time, INTERVAL -1110 MINUTE)) = DATE(DATE_ADD('$DATE2EXTRACT', INTERVAL -1 DAY))   AND A.process_id = '$process'  GROUP BY B.eq_name ) B ON A.eq_name = B.eq_name" | sed 's/\t/,/g' > ../draw/$DATE2EXTRACT-$shift-outsAndScrap-$process.csv 

    cp ../draw/$DATE2EXTRACT-$shift-outsAndScrap-$process.csv ../Y/$DATE2EXTRACT-$shift-outsAndScrap-$process.csv
}

S_scrap_qty_AM(){ # Scrap qty for Scrap dppm

    mysql -h$MESHOST -u $MESUSER -p$MESPASS $MESDB -e "SET time_zone = '+08:00'; SELECT scrap_code, SUM(scrap_qty) AS scrap_qty FROM MES_SCRAP_DETAILS WHERE DATE(DATE_ADD(date_time, INTERVAL -390 MINUTE)) = DATE(DATE_ADD('$DATE2EXTRACT', INTERVAL -0 MINUTE)) AND process_id = '$process' GROUP BY scrap_code ORDER BY SUM(scrap_qty) DESC LIMIT 5;" | sed 's/\t/,/g' > ../draw/$DATE2EXTRACT-$shift-scrap-$process.csv 

    cp ../draw/$DATE2EXTRACT-$shift-scrap-$process.csv ../S/$DATE2EXTRACT-$shift-scrap-$process.csv

}

S_scrap_qty_PREPM(){ # Scrap qty for Scrap dppm

    mysql -h$MESHOST -u $MESUSER -p$MESPASS $MESDB -e "SET time_zone = '+08:00'; SELECT scrap_code, SUM(scrap_qty) AS scrap_qty FROM MES_SCRAP_DETAILS WHERE DATE(DATE_ADD(date_time, INTERVAL -1110 MINUTE)) = DATE(DATE_ADD('$DATE2EXTRACT', INTERVAL -0 MINUTE)) AND process_id = '$process' GROUP BY scrap_code ORDER BY SUM(scrap_qty) DESC LIMIT 5;" | sed 's/\t/,/g' > ../draw/$DATE2EXTRACT-$shift-scrap-$process.csv 

    cp ../draw/$DATE2EXTRACT-$shift-scrap-$process.csv ../S/$DATE2EXTRACT-$shift-scrap-$process.csv

}

S_scrap_qty_POSTPM(){ # Scrap qty for Scrap dppm

    mysql -h$MESHOST -u $MESUSER -p$MESPASS $MESDB -e "SET time_zone = '+08:00'; SELECT scrap_code, SUM(scrap_qty) AS scrap_qty FROM MES_SCRAP_DETAILS WHERE DATE(DATE_ADD(date_time, INTERVAL -1110 MINUTE)) = DATE(DATE_ADD('$DATE2EXTRACT', INTERVAL -1 DAY)) AND process_id = '$process' GROUP BY scrap_code ORDER BY SUM(scrap_qty) DESC LIMIT 5;" | sed 's/\t/,/g' > ../draw/$DATE2EXTRACT-$shift-scrap-$process.csv 

    cp ../draw/$DATE2EXTRACT-$shift-scrap-$process.csv ../S/$DATE2EXTRACT-$shift-scrap-$process.csv

}

S_out_qty_AM(){

    mysql -h$MESHOST -u $MESUSER -p$MESPASS $MESDB -e "SET time_zone = '+08:00'; SELECT A.proc_id , SUM(C.out_qty) AS out_qty FROM		 (SELECT eq_id, proc_id  FROM MES_EQ_PROCESS   GROUP BY eq_id ) A     JOIN   MES_EQ_INFO B   ON A.eq_id = B.eq_id   JOIN   MES_OUT_DETAILS C     ON A.eq_id = C.eq_id   WHERE C.process_id = '$process' AND C.date_time >= CONCAT('$DATE2EXTRACT',' 06:30:00') && C.date_time <= CONCAT('$DATE2EXTRACT' + INTERVAL 0 DAY,' 18:29:59');" | sed 's/\t/,/g' > ../draw/$DATE2EXTRACT-$shift-outs-$process.csv 

    cp ../draw/$DATE2EXTRACT-$shift-outs-$process.csv ../S/$DATE2EXTRACT-$shift-outs-$process.csv

}

S_out_qty_PREPM(){

    mysql -h$MESHOST -u $MESUSER -p$MESPASS $MESDB -e "SET time_zone = '+08:00'; SELECT A.proc_id , SUM(C.out_qty) AS out_qty FROM		 (SELECT eq_id, proc_id  FROM MES_EQ_PROCESS   GROUP BY eq_id ) A     JOIN   MES_EQ_INFO B   ON A.eq_id = B.eq_id   JOIN   MES_OUT_DETAILS C     ON A.eq_id = C.eq_id   WHERE C.process_id = '$process' AND C.date_time >= CONCAT('$DATE2EXTRACT', '18:30:00') && C.date_time <= CONCAT('$DATE2EXTRACT' + INTERVAL 0 DAY,' 23:59:59');" | sed 's/\t/,/g' > ../draw/$DATE2EXTRACT-$shift-outs-$process.csv 

    cp ../draw/$DATE2EXTRACT-$shift-outs-$process.csv ../S/$DATE2EXTRACT-$shift-outs-$process.csv

}

S_out_qty_POSTPM(){

    mysql -h$MESHOST -u $MESUSER -p$MESPASS $MESDB -e "SET time_zone = '+08:00'; SELECT A.proc_id , SUM(C.out_qty) AS out_qty FROM		 (SELECT eq_id, proc_id  FROM MES_EQ_PROCESS   GROUP BY eq_id ) A     JOIN   MES_EQ_INFO B   ON A.eq_id = B.eq_id   JOIN   MES_OUT_DETAILS C     ON A.eq_id = C.eq_id   WHERE C.process_id = '$process' AND C.date_time >= CONCAT('$DATE2EXTRACT' + INTERVAL -1 DAY, ' 18:30:00') && C.date_time <= CONCAT('$DATE2EXTRACT' + INTERVAL 0 DAY,' 06:29:59');" | sed 's/\t/,/g' > ../draw/$DATE2EXTRACT-$shift-outs-$process.csv 

    cp ../draw/$DATE2EXTRACT-$shift-outs-$process.csv ../S/$DATE2EXTRACT-$shift-outs-$process.csv

}

echo "on going ..."
for process_name in ${PROCESSLIST[@]}
do  
    process="${process_name//[$'\t\r\n ']}" # remove carriage return !important

    if (( $now > $AM_start_of_shift )) && (( $now < $AM_end_of_shift )) ; then
        shift='AM'

        echo $process - "AM shift"
        L_hourly_AM # AM "Hourly Outs"
        Y_outsAndScrap_AM # AM "Outs and Scrap"
        S_scrap_qty_AM # Scrap qty
        S_out_qty_AM # Outs qty

    elif (( $now > $PM_start_of_shift  )) && (( $now < $PM_premid_shift )) ; then
        shift='PM'

        echo $process - "PREPM shift"
        L_hourly_PREPM # PREPM Hourly Outs
        Y_outsAndScrap_PREPM # PREPM "Outs and Scrap"
        S_scrap_qty_PREPM # Scrap qty
        S_out_qty_PREPM # Outs qty


    elif (( $now > $PM_postmid_shift )) && (( $now < $PM_end_of_shift )); then
        shift='PM'

        echo $process - "POSTPM shift"
        L_hourly_POSTPM # POSTPM hourly outs
        Y_outsAndScrap_POSTPM # POSTPM "Outs and Scrap"
        S_scrap_qty_POSTPM # Scrap qty
        S_out_qty_POSTPM # Outs qty

        
    fi


done
echo "done..."


$(mysql -u $USER -p$PASS -e 'SHOW PROCESSLIST' | grep dbauth | awk {'print "kill "$1";"'}| mysql -u $USER -p$PASS) # kill all existing connections @ dbauth db
SLEEP 5