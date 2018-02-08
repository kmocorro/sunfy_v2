# !/bin/bash
# xtranghero
# 2018-02-08

PATH=$PATH:/c/xampp/mysql/bin

DATE2EXTRACT=`date +%Y-%m-%d`
DATE2EXTRACT_POSTPM=`date +%Y-%m-%d -d "yesterday"`
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
    # remove after copy
    rm ../draw/$DATE2EXTRACT-$shift-hourlyouts-$process.csv
}

L_hourly_PREPM(){ # Hourly Outs for Linearity
    
    mysql -h$MESHOST -u $MESUSER -p$MESPASS $MESDB -e "SET time_zone = '+08:00'; SELECT process_id, SUM(out_qty) AS out_qty, HOUR(DATE_ADD(date_time, INTERVAL -1110 MINUTE)) + 1 AS fab_hour , count(*) AS num_moves FROM MES_OUT_DETAILS WHERE process_id = '$process' AND DATE(DATE_ADD(date_time, INTERVAL -1110 MINUTE)) = DATE(DATE_ADD('$DATE2EXTRACT', INTERVAL -0 MINUTE)) GROUP BY process_id, HOUR(DATE_ADD(date_time, INTERVAL -1110 MINUTE));" | sed 's/\t/,/g' > ../draw/$DATE2EXTRACT-$shift-hourlyouts-$process.csv 
    
    cp ../draw/$DATE2EXTRACT-$shift-hourlyouts-$process.csv ../L/$DATE2EXTRACT-$shift-hourlyouts-$process.csv

    rm ../draw/$DATE2EXTRACT-$shift-hourlyouts-$process.csv
}

L_hourly_POSTPM(){ # Hourly Outs for Linearity
    
    mysql -h$MESHOST -u $MESUSER -p$MESPASS $MESDB -e "SET time_zone = '+08:00'; SELECT process_id, SUM(out_qty) AS out_qty, HOUR(DATE_ADD(date_time, INTERVAL -1110 MINUTE)) + 1 AS fab_hour , count(*) AS num_moves FROM MES_OUT_DETAILS WHERE process_id = '$process' AND DATE(DATE_ADD(date_time, INTERVAL -1110 MINUTE)) = DATE(DATE_ADD('$DATE2EXTRACT', INTERVAL -1 DAY)) GROUP BY process_id, HOUR(DATE_ADD(date_time, INTERVAL -1110 MINUTE));" | sed 's/\t/,/g' > ../draw/$DATE2EXTRACT_POSTPM-$shift-hourlyouts-$process.csv 
    
    cp ../draw/$DATE2EXTRACT_POSTPM-$shift-hourlyouts-$process.csv ../L/$DATE2EXTRACT_POSTPM-$shift-hourlyouts-$process.csv

    rm ../draw/$DATE2EXTRACT_POSTPM-$shift-hourlyouts-$process.csv
}

Y_outsAndScrap_AM(){ # Outs and Scrap for Yield per tool

    mysql -h$MESHOST -u $MESUSER -p$MESPASS $MESDB -e "SET time_zone = '+08:00'; SELECT A.eq_name AS eq_name, A.scrap_qty AS scrap_qty, B.out_qty AS out_qty FROM   (SELECT B.eq_name, SUM(A.scrap_qty) AS scrap_qty    FROM MES_SCRAP_DETAILS A      JOIN MES_EQ_INFO B  ON A.eq_id = B.eq_id     WHERE DATE(DATE_ADD(A.date_time, INTERVAL -390 MINUTE)) = DATE(DATE_ADD('$DATE2EXTRACT', INTERVAL -0 MINUTE))   AND A.process_id = '$process'     GROUP BY B.eq_name ) A JOIN   (SELECT B.eq_name, SUM(A.out_qty) AS out_qty     FROM MES_OUT_DETAILS A     JOIN MES_EQ_INFO B   ON A.eq_id = B.eq_id    WHERE DATE(DATE_ADD(A.date_time, INTERVAL -390 MINUTE)) = DATE(DATE_ADD('$DATE2EXTRACT', INTERVAL -0 MINUTE))   AND A.process_id = '$process'  GROUP BY B.eq_name ) B ON A.eq_name = B.eq_name;" | sed 's/\t/,/g' > ../draw/$DATE2EXTRACT-$shift-outsAndScrap-$process.csv 

    cp ../draw/$DATE2EXTRACT-$shift-outsAndScrap-$process.csv ../Y/$DATE2EXTRACT-$shift-outsAndScrap-$process.csv

    rm ../draw/$DATE2EXTRACT-$shift-outsAndScrap-$process.csv
}

Y_outsAndScrap_PREPM(){ # Outs and Scrap for Yield per tool

    mysql -h$MESHOST -u $MESUSER -p$MESPASS $MESDB -e "SET time_zone = '+08:00'; SELECT A.eq_name AS eq_name, A.scrap_qty AS scrap_qty, B.out_qty AS out_qty FROM   (SELECT B.eq_name, SUM(A.scrap_qty) AS scrap_qty    FROM MES_SCRAP_DETAILS A      JOIN MES_EQ_INFO B  ON A.eq_id = B.eq_id     WHERE DATE(DATE_ADD(A.date_time, INTERVAL -1110 MINUTE)) = DATE(DATE_ADD('$DATE2EXTRACT', INTERVAL -0 MINUTE))   AND A.process_id = '$process'     GROUP BY B.eq_name ) A JOIN   (SELECT B.eq_name, SUM(A.out_qty) AS out_qty     FROM MES_OUT_DETAILS A     JOIN MES_EQ_INFO B   ON A.eq_id = B.eq_id    WHERE DATE(DATE_ADD(A.date_time, INTERVAL -1110 MINUTE)) = DATE(DATE_ADD('$DATE2EXTRACT', INTERVAL -0 MINUTE))   AND A.process_id = '$process'  GROUP BY B.eq_name ) B ON A.eq_name = B.eq_name;" | sed 's/\t/,/g' > ../draw/$DATE2EXTRACT-$shift-outsAndScrap-$process.csv 

    cp ../draw/$DATE2EXTRACT-$shift-outsAndScrap-$process.csv ../Y/$DATE2EXTRACT-$shift-outsAndScrap-$process.csv

    rm ../draw/$DATE2EXTRACT-$shift-outsAndScrap-$process.csv
}

Y_outsAndScrap_POSTPM(){ # Outs and Scrap for Yield per tool

    mysql -h$MESHOST -u $MESUSER -p$MESPASS $MESDB -e "SET time_zone = '+08:00'; SELECT A.eq_name AS eq_name, A.scrap_qty AS scrap_qty, B.out_qty AS out_qty FROM   (SELECT B.eq_name, SUM(A.scrap_qty) AS scrap_qty    FROM MES_SCRAP_DETAILS A      JOIN MES_EQ_INFO B  ON A.eq_id = B.eq_id     WHERE DATE(DATE_ADD(A.date_time, INTERVAL -1110 MINUTE)) = DATE(DATE_ADD('$DATE2EXTRACT', INTERVAL -1 DAY))   AND A.process_id = '$process'     GROUP BY B.eq_name ) A JOIN   (SELECT B.eq_name, SUM(A.out_qty) AS out_qty     FROM MES_OUT_DETAILS A     JOIN MES_EQ_INFO B   ON A.eq_id = B.eq_id    WHERE DATE(DATE_ADD(A.date_time, INTERVAL -1110 MINUTE)) = DATE(DATE_ADD('$DATE2EXTRACT', INTERVAL -1 DAY))   AND A.process_id = '$process'  GROUP BY B.eq_name ) B ON A.eq_name = B.eq_name" | sed 's/\t/,/g' > ../draw/$DATE2EXTRACT_POSTPM-$shift-outsAndScrap-$process.csv 

    cp ../draw/$DATE2EXTRACT_POSTPM-$shift-outsAndScrap-$process.csv ../Y/$DATE2EXTRACT_POSTPM-$shift-outsAndScrap-$process.csv

    rm ../draw/$DATE2EXTRACT_POSTPM-$shift-outsAndScrap-$process.csv
}

S_scrap_qty_AM(){ # Scrap qty for Scrap dppm

    mysql -h$MESHOST -u $MESUSER -p$MESPASS $MESDB -e "SET time_zone = '+08:00'; SELECT scrap_code, SUM(scrap_qty) AS scrap_qty FROM MES_SCRAP_DETAILS WHERE DATE(DATE_ADD(date_time, INTERVAL -390 MINUTE)) = DATE(DATE_ADD('$DATE2EXTRACT', INTERVAL -0 MINUTE)) AND process_id = '$process' GROUP BY scrap_code ORDER BY SUM(scrap_qty) DESC LIMIT 5;" | sed 's/\t/,/g' > ../draw/$DATE2EXTRACT-$shift-scrap-$process.csv 

    cp ../draw/$DATE2EXTRACT-$shift-scrap-$process.csv ../S/$DATE2EXTRACT-$shift-scrap-$process.csv

    rm ../draw/$DATE2EXTRACT-$shift-scrap-$process.csv

}

S_scrap_qty_PREPM(){ # Scrap qty for Scrap dppm

    mysql -h$MESHOST -u $MESUSER -p$MESPASS $MESDB -e "SET time_zone = '+08:00'; SELECT scrap_code, SUM(scrap_qty) AS scrap_qty FROM MES_SCRAP_DETAILS WHERE DATE(DATE_ADD(date_time, INTERVAL -1110 MINUTE)) = DATE(DATE_ADD('$DATE2EXTRACT', INTERVAL -0 MINUTE)) AND process_id = '$process' GROUP BY scrap_code ORDER BY SUM(scrap_qty) DESC LIMIT 5;" | sed 's/\t/,/g' > ../draw/$DATE2EXTRACT-$shift-scrap-$process.csv 

    cp ../draw/$DATE2EXTRACT-$shift-scrap-$process.csv ../S/$DATE2EXTRACT-$shift-scrap-$process.csv

    rm ../draw/$DATE2EXTRACT-$shift-scrap-$process.csv

}

S_scrap_qty_POSTPM(){ # Scrap qty for Scrap dppm

    mysql -h$MESHOST -u $MESUSER -p$MESPASS $MESDB -e "SET time_zone = '+08:00'; SELECT scrap_code, SUM(scrap_qty) AS scrap_qty FROM MES_SCRAP_DETAILS WHERE DATE(DATE_ADD(date_time, INTERVAL -1110 MINUTE)) = DATE(DATE_ADD('$DATE2EXTRACT', INTERVAL -1 DAY)) AND process_id = '$process' GROUP BY scrap_code ORDER BY SUM(scrap_qty) DESC LIMIT 5;" | sed 's/\t/,/g' > ../draw/$DATE2EXTRACT_POSTPM-$shift-scrap-$process.csv 

    cp ../draw/$DATE2EXTRACT_POSTPM-$shift-scrap-$process.csv ../S/$DATE2EXTRACT_POSTPM-$shift-scrap-$process.csv

    rm ../draw/$DATE2EXTRACT_POSTPM-$shift-scrap-$process.csv

}

S_out_qty_AM(){ # Out qty for Scrap dppm

    mysql -h$MESHOST -u $MESUSER -p$MESPASS $MESDB -e "SET time_zone = '+08:00'; SELECT A.proc_id , SUM(C.out_qty) AS out_qty FROM		 (SELECT eq_id, proc_id  FROM MES_EQ_PROCESS   GROUP BY eq_id ) A     JOIN   MES_EQ_INFO B   ON A.eq_id = B.eq_id   JOIN   MES_OUT_DETAILS C     ON A.eq_id = C.eq_id   WHERE C.process_id = '$process' AND C.date_time >= CONCAT('$DATE2EXTRACT',' 06:30:00') && C.date_time <= CONCAT('$DATE2EXTRACT' + INTERVAL 0 DAY,' 18:29:59');" | sed 's/\t/,/g' > ../draw/$DATE2EXTRACT-$shift-outs-$process.csv 

    cp ../draw/$DATE2EXTRACT-$shift-outs-$process.csv ../S/$DATE2EXTRACT-$shift-outs-$process.csv

    rm ../draw/$DATE2EXTRACT-$shift-outs-$process.csv

}

S_out_qty_PREPM(){ # Out qty for Scrap dppm

    mysql -h$MESHOST -u $MESUSER -p$MESPASS $MESDB -e "SET time_zone = '+08:00'; SELECT A.proc_id , SUM(C.out_qty) AS out_qty FROM		 (SELECT eq_id, proc_id  FROM MES_EQ_PROCESS   GROUP BY eq_id ) A     JOIN   MES_EQ_INFO B   ON A.eq_id = B.eq_id   JOIN   MES_OUT_DETAILS C     ON A.eq_id = C.eq_id   WHERE C.process_id = '$process' AND C.date_time >= CONCAT('$DATE2EXTRACT', '18:30:00') && C.date_time <= CONCAT('$DATE2EXTRACT' + INTERVAL 0 DAY,' 23:59:59');" | sed 's/\t/,/g' > ../draw/$DATE2EXTRACT-$shift-outs-$process.csv 

    cp ../draw/$DATE2EXTRACT-$shift-outs-$process.csv ../S/$DATE2EXTRACT-$shift-outs-$process.csv

    rm ../draw/$DATE2EXTRACT-$shift-outs-$process.csv

}

S_out_qty_POSTPM(){ # Out qty for Scrap dppm

    mysql -h$MESHOST -u $MESUSER -p$MESPASS $MESDB -e "SET time_zone = '+08:00'; SELECT A.proc_id , SUM(C.out_qty) AS out_qty FROM		 (SELECT eq_id, proc_id  FROM MES_EQ_PROCESS   GROUP BY eq_id ) A     JOIN   MES_EQ_INFO B   ON A.eq_id = B.eq_id   JOIN   MES_OUT_DETAILS C     ON A.eq_id = C.eq_id   WHERE C.process_id = '$process' AND C.date_time >= CONCAT('$DATE2EXTRACT' + INTERVAL -1 DAY, ' 18:30:00') && C.date_time <= CONCAT('$DATE2EXTRACT' + INTERVAL 0 DAY,' 06:29:59');" | sed 's/\t/,/g' > ../draw/$DATE2EXTRACT_POSTPM-$shift-outs-$process.csv 

    cp ../draw/$DATE2EXTRACT_POSTPM-$shift-outs-$process.csv ../S/$DATE2EXTRACT_POSTPM-$shift-outs-$process.csv

    rm ../draw/$DATE2EXTRACT_POSTPM-$shift-outs-$process.csv

}

O_out_qty_per_tool_AM(){ # Out qty per tool for OEE

    if [ $process == 'BSGDEP' ]; then

        mysql -h$MESHOST -u $MESUSER -p$MESPASS $MESDB -e "SET time_zone = '+08:00'; SELECT eq_outs.eq_id, all_eq_name.eq_id, all_eq_name.eq_name, coalesce(eq_outs.out_sum,0) as out_qty  FROM (SELECT B.eq_id, B.eq_name FROM MES_EQ_PROCESS A JOIN MES_EQ_INFO B ON A.eq_id = B.eq_id WHERE proc_id = '$process' GROUP BY B.eq_id) AS all_eq_name  JOIN (SELECT eq_id, SUM(out_qty) as out_sum FROM MES_OUT_DETAILS WHERE DATE(DATE_ADD(date_time, INTERVAL -390 MINUTE)) = DATE(DATE_ADD('$DATE2EXTRACT', INTERVAL -0 MINUTE)) AND process_id = '$process' GROUP BY eq_id) AS eq_outs ON all_eq_name.eq_id = eq_outs.eq_id ORDER BY all_eq_name.eq_name;" | sed 's/\t/,/g' > ../draw/$DATE2EXTRACT-$shift-outspertool-$process.csv 

        cp ../draw/$DATE2EXTRACT-$shift-outspertool-$process.csv ../O/$DATE2EXTRACT-$shift-outspertool-$process.csv

        rm ../draw/$DATE2EXTRACT-$shift-outspertool-$process.csv

    else

        mysql -h$MESHOST -u $MESUSER -p$MESPASS $MESDB -e "SET time_zone = '+08:00'; SELECT all_eq_name.eq_name, coalesce(eq_outs.out_sum,0) as out_qty  FROM (SELECT B.eq_id, B.eq_name FROM MES_EQ_PROCESS A JOIN MES_EQ_INFO B ON A.eq_id = B.eq_id WHERE proc_id = '$process' GROUP BY B.eq_name) AS all_eq_name LEFT JOIN (SELECT eq_id, COALESCE(SUM(out_qty),0) as out_sum FROM MES_OUT_DETAILS WHERE DATE(DATE_ADD(date_time, INTERVAL -390 MINUTE)) = DATE(DATE_ADD('$DATE2EXTRACT', INTERVAL -0 MINUTE)) AND process_id = '$process' GROUP BY eq_id) AS eq_outs ON all_eq_name.eq_id = eq_outs.eq_id;" | sed 's/\t/,/g' > ../draw/$DATE2EXTRACT-$shift-outspertool-$process.csv 

        cp ../draw/$DATE2EXTRACT-$shift-outspertool-$process.csv ../O/$DATE2EXTRACT-$shift-outspertool-$process.csv

        rm ../draw/$DATE2EXTRACT-$shift-outspertool-$process.csv
    fi
}

O_out_qty_per_tool_PREPM(){ # Out qty per tool for OEE


    if [ $process == 'BSGDEP' ]; then

        mysql -h$MESHOST -u $MESUSER -p$MESPASS $MESDB -e "SET time_zone = '+08:00'; SELECT eq_outs.eq_id, all_eq_name.eq_id, all_eq_name.eq_name, coalesce(eq_outs.out_sum,0) as out_qty  FROM (SELECT B.eq_id, B.eq_name FROM MES_EQ_PROCESS A JOIN MES_EQ_INFO B ON A.eq_id = B.eq_id WHERE proc_id = '$process' GROUP BY B.eq_id) AS all_eq_name  JOIN (SELECT eq_id, SUM(out_qty) as out_sum FROM MES_OUT_DETAILS WHERE DATE(DATE_ADD(date_time, INTERVAL -1110 MINUTE)) = DATE(DATE_ADD('$DATE2EXTRACT', INTERVAL -0 MINUTE)) AND process_id = '$process' GROUP BY eq_id) AS eq_outs ON all_eq_name.eq_id = eq_outs.eq_id ORDER BY all_eq_name.eq_name;" | sed 's/\t/,/g' > ../draw/$DATE2EXTRACT-$shift-outspertool-$process.csv 

        cp ../draw/$DATE2EXTRACT-$shift-outspertool-$process.csv ../O/$DATE2EXTRACT-$shift-outspertool-$process.csv

        rm ../draw/$DATE2EXTRACT-$shift-outspertool-$process.csv
    else

        mysql -h$MESHOST -u $MESUSER -p$MESPASS $MESDB -e "SET time_zone = '+08:00'; SELECT all_eq_name.eq_name, coalesce(eq_outs.out_sum,0) as out_qty  FROM (SELECT B.eq_id, B.eq_name FROM MES_EQ_PROCESS A JOIN MES_EQ_INFO B ON A.eq_id = B.eq_id WHERE proc_id = '$process' GROUP BY B.eq_name) AS all_eq_name LEFT JOIN (SELECT eq_id, COALESCE(SUM(out_qty),0) as out_sum FROM MES_OUT_DETAILS WHERE DATE(DATE_ADD(date_time, INTERVAL -1110 MINUTE)) = DATE(DATE_ADD('$DATE2EXTRACT', INTERVAL -0 MINUTE)) AND process_id = '$process' GROUP BY eq_id) AS eq_outs ON all_eq_name.eq_id = eq_outs.eq_id;" | sed 's/\t/,/g' > ../draw/$DATE2EXTRACT-$shift-outspertool-$process.csv 

        cp ../draw/$DATE2EXTRACT-$shift-outspertool-$process.csv ../O/$DATE2EXTRACT-$shift-outspertool-$process.csv

        rm ../draw/$DATE2EXTRACT-$shift-outspertool-$process.csv
    fi

}

O_out_qty_per_tool_POSTPM(){ # Out qty per tool for OEE


    if [ $process == 'BSGDEP' ]; then

        mysql -h$MESHOST -u $MESUSER -p$MESPASS $MESDB -e "SET time_zone = '+08:00'; SELECT eq_outs.eq_id, all_eq_name.eq_id, all_eq_name.eq_name, coalesce(eq_outs.out_sum,0) as out_qty  FROM (SELECT B.eq_id, B.eq_name FROM MES_EQ_PROCESS A JOIN MES_EQ_INFO B ON A.eq_id = B.eq_id WHERE proc_id = '$process' GROUP BY B.eq_id) AS all_eq_name  JOIN (SELECT eq_id, SUM(out_qty) as out_sum FROM MES_OUT_DETAILS WHERE DATE(DATE_ADD(date_time, INTERVAL -1110 MINUTE)) = DATE(DATE_ADD('$DATE2EXTRACT', INTERVAL -1 DAY)) AND process_id = '$process' GROUP BY eq_id) AS eq_outs ON all_eq_name.eq_id = eq_outs.eq_id ORDER BY all_eq_name.eq_name;" | sed 's/\t/,/g' > ../draw/$DATE2EXTRACT_POSTPM-$shift-outspertool-$process.csv 

        cp ../draw/$DATE2EXTRACT_POSTPM-$shift-outspertool-$process.csv ../O/$DATE2EXTRACT_POSTPM-$shift-outspertool-$process.csv

        rm ../draw/$DATE2EXTRACT_POSTPM-$shift-outspertool-$process.csv
    else

        mysql -h$MESHOST -u $MESUSER -p$MESPASS $MESDB -e "SET time_zone = '+08:00'; SELECT all_eq_name.eq_name, coalesce(eq_outs.out_sum,0) as out_qty  FROM (SELECT B.eq_id, B.eq_name FROM MES_EQ_PROCESS A JOIN MES_EQ_INFO B ON A.eq_id = B.eq_id WHERE proc_id = '$process' GROUP BY B.eq_name) AS all_eq_name LEFT JOIN (SELECT eq_id, COALESCE(SUM(out_qty),0) as out_sum FROM MES_OUT_DETAILS WHERE DATE(DATE_ADD(date_time, INTERVAL -1110 MINUTE)) = DATE(DATE_ADD('$DATE2EXTRACT', INTERVAL -1 DAY)) AND process_id = '$process' GROUP BY eq_id) AS eq_outs ON all_eq_name.eq_id = eq_outs.eq_id;" | sed 's/\t/,/g' > ../draw/$DATE2EXTRACT_POSTPM-$shift-outspertool-$process.csv 

        cp ../draw/$DATE2EXTRACT_POSTPM-$shift-outspertool-$process.csv ../O/$DATE2EXTRACT_POSTPM-$shift-outspertool-$process.csv

        rm ../draw/$DATE2EXTRACT_POSTPM-$shift-outspertool-$process.csv
    fi

}

O_status_per_tool_AM(){

    mysql -h$MESHOST -u $MESUSER -p$MESPASS $MESDB -e "SELECT pretty_table.eq_name, COALESCE(P,0) AS P,  COALESCE(SU,0) AS SU,   COALESCE(SD,0) AS SD,  COALESCE(D,0) AS D,  COALESCE(E,0) AS E, COALESCE(SB,0) AS SB  FROM (SELECT extended_table.eq_name,   SUM(P) AS P,    SUM(SU) AS SU,   SUM(SD) AS SD,    SUM(D) AS D,    SUM(E) AS E,  SUM(SB) AS SB FROM  (SELECT base_table.*,   CASE WHEN base_table.stat_id = 'P' THEN base_table.duration END AS P,   CASE WHEN base_table.stat_id = 'SU' THEN base_table.duration END AS SU,   CASE WHEN base_table.stat_id = 'SD' THEN base_table.duration END AS SD,   CASE WHEN base_table.stat_id = 'D' THEN base_table.duration END AS D,  CASE WHEN base_table.stat_id = 'E' THEN base_table.duration END AS E,   CASE WHEN base_table.stat_id = 'SB' THEN base_table.duration END AS SB  FROM (SELECT G.eq_name,  G.stat_id,  SUM(ROUND(TIME_TO_SEC(TIMEDIFF(G.time_out,G.time_in))/3600,2)) as duration FROM  (SELECT  C.eq_name,    B.stat_id,    IF(B.time_in <= CONCAT('$DATE2EXTRACT',' 06:30:00') && B.time_out >= CONCAT('$DATE2EXTRACT',' 06:30:00'),CONCAT('$DATE2EXTRACT',' 06:30:00'),IF(B.time_in <= CONCAT('$DATE2EXTRACT', ' 06:30:00'),CONCAT('$DATE2EXTRACT',' 06:30:00'),IF(B.time_in >= CONCAT('$DATE2EXTRACT' + INTERVAL 1 DAY, ' 06:30:00'),CONCAT('$DATE2EXTRACT' + INTERVAL 1 DAY,' 06:30:00'),B.time_in))) AS time_in ,    IF(B.time_in <= CONCAT('$DATE2EXTRACT' + INTERVAL 1 DAY,' 06:30:00') && B.time_out >= CONCAT('$DATE2EXTRACT' + INTERVAL 1 DAY, ' 06:30:00'),CONCAT('$DATE2EXTRACT' + INTERVAL 1 DAY, ' 06:30:00'),IF(B.time_out <= CONCAT('$DATE2EXTRACT' , ' 06:30:00'),CONCAT('$DATE2EXTRACT',' 06:30:00'),IF(B.time_out >= CONCAT('$DATE2EXTRACT' + INTERVAL 1 DAY, ' 06:30:00'),CONCAT('$DATE2EXTRACT' + INTERVAL 1 DAY,' 06:30:00'),IF(B.time_out IS NULL && B.time_in < CONCAT('$DATE2EXTRACT' + INTERVAL 1 DAY,' 06:30:00') ,CONVERT_TZ(NOW(),@@SESSION.TIME_ZONE,'+08:00'),B.time_out)))) AS time_out   FROM  (SELECT eq_id, proc_id    FROM MES_EQ_PROCESS    WHERE proc_id = '$process' GROUP BY eq_id) A   JOIN      MES_EQ_CSTAT_HEAD B    ON A.eq_id = B.eq_id   JOIN     MES_EQ_INFO C   ON A.eq_id = C.eq_id    WHERE    B.time_in >= CONCAT('$DATE2EXTRACT' - INTERVAL 2 DAY,' 00:00:00')   AND A.proc_id = '$process') G GROUP BY G.eq_name, G.stat_id) base_table) extended_table  GROUP BY extended_table.eq_name) pretty_table  ;" | sed 's/\t/,/g' > ../draw/$DATE2EXTRACT-$shift-statuspertool-$process.csv 

    cp ../draw/$DATE2EXTRACT-$shift-statuspertool-$process.csv ../O/$DATE2EXTRACT-$shift-statuspertool-$process.csv

    rm ../draw/$DATE2EXTRACT-$shift-statuspertool-$process.csv
}

O_status_per_tool_PREPM(){

    mysql -h$MESHOST -u $MESUSER -p$MESPASS $MESDB -e "SELECT pretty_table.eq_name, COALESCE(P,0) AS P,  COALESCE(SU,0) AS SU,   COALESCE(SD,0) AS SD,  COALESCE(D,0) AS D,  COALESCE(E,0) AS E, COALESCE(SB,0) AS SB  FROM (SELECT extended_table.eq_name,   SUM(P) AS P,    SUM(SU) AS SU,   SUM(SD) AS SD,    SUM(D) AS D,    SUM(E) AS E,  SUM(SB) AS SB FROM  (SELECT base_table.*,   CASE WHEN base_table.stat_id = 'P' THEN base_table.duration END AS P,   CASE WHEN base_table.stat_id = 'SU' THEN base_table.duration END AS SU,   CASE WHEN base_table.stat_id = 'SD' THEN base_table.duration END AS SD,   CASE WHEN base_table.stat_id = 'D' THEN base_table.duration END AS D,  CASE WHEN base_table.stat_id = 'E' THEN base_table.duration END AS E,   CASE WHEN base_table.stat_id = 'SB' THEN base_table.duration END AS SB  FROM (SELECT G.eq_name,  G.stat_id,  SUM(ROUND(TIME_TO_SEC(TIMEDIFF(G.time_out,G.time_in))/3600,2)) as duration FROM  (SELECT  C.eq_name,    B.stat_id,    IF(B.time_in <= CONCAT('$DATE2EXTRACT',' 18:30:00') && B.time_out >= CONCAT('$DATE2EXTRACT',' 18:30:00'),CONCAT('$DATE2EXTRACT',' 18:30:00'),IF(B.time_in <= CONCAT('$DATE2EXTRACT', ' 18:30:00'),CONCAT('$DATE2EXTRACT',' 18:30:00'),IF(B.time_in >= CONCAT('$DATE2EXTRACT' + INTERVAL 1 DAY, ' 18:30:00'),CONCAT('$DATE2EXTRACT' + INTERVAL 1 DAY,' 18:30:00'),B.time_in))) AS time_in ,    IF(B.time_in <= CONCAT('$DATE2EXTRACT' + INTERVAL 1 DAY,' 18:30:00') && B.time_out >= CONCAT('$DATE2EXTRACT' + INTERVAL 1 DAY, ' 18:30:00'),CONCAT('$DATE2EXTRACT' + INTERVAL 1 DAY, ' 18:30:00'),IF(B.time_out <= CONCAT('$DATE2EXTRACT' , ' 18:30:00'),CONCAT('$DATE2EXTRACT',' 18:30:00'),IF(B.time_out >= CONCAT('$DATE2EXTRACT' + INTERVAL 1 DAY, ' 18:30:00'),CONCAT('$DATE2EXTRACT' + INTERVAL 1 DAY,' 18:30:00'),IF(B.time_out IS NULL && B.time_in < CONCAT('$DATE2EXTRACT' + INTERVAL 1 DAY,' 18:30:00') ,CONVERT_TZ(NOW(),@@SESSION.TIME_ZONE,'+08:00'),B.time_out)))) AS time_out   FROM  (SELECT eq_id, proc_id    FROM MES_EQ_PROCESS    WHERE proc_id = '$process' GROUP BY eq_id) A   JOIN      MES_EQ_CSTAT_HEAD B    ON A.eq_id = B.eq_id   JOIN     MES_EQ_INFO C   ON A.eq_id = C.eq_id    WHERE    B.time_in >= CONCAT('$DATE2EXTRACT' - INTERVAL 2 DAY,' 00:00:00')   AND A.proc_id = '$process') G GROUP BY G.eq_name, G.stat_id) base_table) extended_table  GROUP BY extended_table.eq_name) pretty_table ;" | sed 's/\t/,/g' > ../draw/$DATE2EXTRACT-$shift-statuspertool-$process.csv 

    cp ../draw/$DATE2EXTRACT-$shift-statuspertool-$process.csv ../O/$DATE2EXTRACT-$shift-statuspertool-$process.csv

    rm ../draw/$DATE2EXTRACT-$shift-statuspertool-$process.csv
}

O_status_per_tool_POSTPM(){

    mysql -h$MESHOST -u $MESUSER -p$MESPASS $MESDB -e "SELECT pretty_table.eq_name, COALESCE(P,0) AS P,  COALESCE(SU,0) AS SU,   COALESCE(SD,0) AS SD,  COALESCE(D,0) AS D,  COALESCE(E,0) AS E, COALESCE(SB,0) AS SB  FROM (SELECT extended_table.eq_name,   SUM(P) AS P,    SUM(SU) AS SU,   SUM(SD) AS SD,    SUM(D) AS D,    SUM(E) AS E,  SUM(SB) AS SB FROM  (SELECT base_table.*,   CASE WHEN base_table.stat_id = 'P' THEN base_table.duration END AS P,   CASE WHEN base_table.stat_id = 'SU' THEN base_table.duration END AS SU,   CASE WHEN base_table.stat_id = 'SD' THEN base_table.duration END AS SD,   CASE WHEN base_table.stat_id = 'D' THEN base_table.duration END AS D,  CASE WHEN base_table.stat_id = 'E' THEN base_table.duration END AS E,   CASE WHEN base_table.stat_id = 'SB' THEN base_table.duration END AS SB  FROM (SELECT G.eq_name,  G.stat_id,  SUM(ROUND(TIME_TO_SEC(TIMEDIFF(G.time_out,G.time_in))/3600,2)) as duration FROM  (SELECT  C.eq_name,    B.stat_id,    IF(B.time_in <= CONCAT('$DATE2EXTRACT'  + INTERVAL -1 DAY,' 18:30:00') && B.time_out >= CONCAT('$DATE2EXTRACT'  + INTERVAL -1 DAY,' 18:30:00'),CONCAT('$DATE2EXTRACT'  + INTERVAL -1 DAY,' 18:30:00'),IF(B.time_in <= CONCAT('$DATE2EXTRACT'  + INTERVAL -1 DAY, ' 18:30:00'),CONCAT('$DATE2EXTRACT'  + INTERVAL -1 DAY,' 18:30:00'),IF(B.time_in >= CONCAT('$DATE2EXTRACT' + INTERVAL 0 DAY, ' 18:30:00'),CONCAT('$DATE2EXTRACT' + INTERVAL 0 DAY,' 18:30:00'),B.time_in))) AS time_in ,    IF(B.time_in <= CONCAT('$DATE2EXTRACT' + INTERVAL 0 DAY,' 18:30:00') && B.time_out >= CONCAT('$DATE2EXTRACT' + INTERVAL 0 DAY, ' 18:30:00'),CONCAT('$DATE2EXTRACT' + INTERVAL 0 DAY, ' 18:30:00'),IF(B.time_out <= CONCAT('$DATE2EXTRACT'  + INTERVAL -1 DAY, ' 18:30:00'),CONCAT('$DATE2EXTRACT'  + INTERVAL -1 DAY,' 18:30:00'),IF(B.time_out >= CONCAT('$DATE2EXTRACT' + INTERVAL 0 DAY, ' 18:30:00'),CONCAT('$DATE2EXTRACT' + INTERVAL 0 DAY,' 18:30:00'),IF(B.time_out IS NULL && B.time_in < CONCAT('$DATE2EXTRACT' + INTERVAL 0 DAY,' 18:30:00') ,CONVERT_TZ(NOW(),@@SESSION.TIME_ZONE,'+08:00'),B.time_out)))) AS time_out   FROM  (SELECT eq_id, proc_id    FROM MES_EQ_PROCESS    WHERE proc_id = '$process' GROUP BY eq_id) A   JOIN      MES_EQ_CSTAT_HEAD B    ON A.eq_id = B.eq_id   JOIN     MES_EQ_INFO C   ON A.eq_id = C.eq_id    WHERE    B.time_in >= CONCAT('$DATE2EXTRACT' - INTERVAL 3 DAY,' 00:00:00')   AND A.proc_id = '$process') G GROUP BY G.eq_name, G.stat_id) base_table) extended_table  GROUP BY extended_table.eq_name) pretty_table  ;" | sed 's/\t/,/g' > ../draw/$DATE2EXTRACT_POSTPM-$shift-statuspertool-$process.csv 

    cp ../draw/$DATE2EXTRACT_POSTPM-$shift-statuspertool-$process.csv ../O/$DATE2EXTRACT_POSTPM-$shift-statuspertool-$process.csv

    rm ../draw/$DATE2EXTRACT_POSTPM-$shift-statuspertool-$process.csv
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
        O_out_qty_per_tool_AM # Outs per tool
        O_status_per_tool_AM 

    elif (( $now > $PM_start_of_shift  )) && (( $now < $PM_premid_shift )) ; then
        shift='PM'

        echo $process - "PREPM shift"
        L_hourly_PREPM # PREPM Hourly Outs
        Y_outsAndScrap_PREPM # PREPM "Outs and Scrap"
        S_scrap_qty_PREPM # Scrap qty
        S_out_qty_PREPM # Outs qty
        O_out_qty_per_tool_PREPM # Outs per tool
        O_status_per_tool_PREPM


    elif (( $now > $PM_postmid_shift )) && (( $now < $PM_end_of_shift )); then
        shift='PM'

        echo $process - "POSTPM shift"
        L_hourly_POSTPM # POSTPM hourly outs
        Y_outsAndScrap_POSTPM # POSTPM "Outs and Scrap"
        S_scrap_qty_POSTPM # Scrap qty
        S_out_qty_POSTPM # Outs qty
        O_out_qty_per_tool_POSTPM # Outs per tool
        O_status_per_tool_POSTPM

        
    fi


done
echo "done..."


$(mysql -u $USER -p$PASS -e 'SHOW PROCESSLIST' | grep dbauth | awk {'print "kill "$1";"'}| mysql -u $USER -p$PASS) # kill all existing connections @ dbauth db
SLEEP 5