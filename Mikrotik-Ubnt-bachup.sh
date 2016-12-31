#!/bin/bash
datum=`date "+%Y-%m-%d"`
HOME_PATH=/home/ubntbackup
BACKUP_PATH=$HOME_PATH/backup/$datum
lista=$HOME_PATH/lista_mikrtikubnt.lst
IFS=$'\n'
greska=0
error_log=/tmp/ubnt-backup.tmp
date > $error_log
sshopcije="-oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null"
defuserubnt="ubnt"
defpassubnt="ubnt"
defusermikrotik="admin"
defpassmikrorik=""


if [ ! -d $BACKUP_PATH ]; then
	mkdir -p $BACKUP_PATH
fi

function mtikbackup {
####
#	mtikbackup $IME $ADRESA $PORT $MIKUSER $PASS
#komanda="ssh -p $PORT $sshopcije backup@$ADRESA /export file=$IME"

####
        if [ -z $4 ]; then #ako nema usera, user je admin i defaltni pass ide
		mtik_user=$defusermikrotik
                mtik_pass=$defpassmikrorik
        else	#ako postoji user, i postoji pass onde ide pass, inace ide po kljucu
                mtik_user=$4
		if [ -z $5 ]; then #ako nema pass, onda  ide defaltni pass, inače ide po ključu sa userom koji je upisani 
                	mtik_pass="kljuc"
        	else
                	mtik_pass=$5
        	fi
        fi


	if [ $mtik_pass != "kljuc" ]; then
		komanda="sshpass -p $mtik_pass /usr/bin/ssh -p $3 $sshopcije $mtik_user@$2 /export "
	else
		komanda="ssh -p $3 $sshopcije $mtik_user@$2 /export"
	fi
	echo "$komanda >> $BACKUP_PATH/M-$1-$datum.rsc 2>> $error_log"
	echo $komanda >> $error_log
	$komanda >> $BACKUP_PATH/M-$1-$datum.rsc 2>> $error_log
	izlaz=$?
	if [ $izlaz -ne 0 ]; then
		greska=1
	fi
	echo Izlaz: $izlaz >>$error_log
	echo >> $error_log

}

function ubntbackup {
        if [ -z $4 ]; then #ako nema usera, user je admin i defaltni pass ide
                ubnt_user=$defuserubnt
                ubnt_pass=$defpassubnt
        else    #ako postoji user, i postoji pass onde ide pass, inace ide po kljucu
                ubnt_user=$4
                if [ -z $5 ]; then #ako nema pass, onda  ide defaltni pass, inače ide po ključu sa userom koji je upisani 
                        ubnt_pass="kljuc"
                else
                        ubnt_pass=$5
                fi
        fi


        if [ $ubnt_pass != "kljuc" ]; then
                komanda="sshpass -p $ubnt_pass /usr/bin/scp -P $PORT -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null  $ubnt_user@$ADRESA:/tmp/system.cfg $BACKUP_PATH/U-$IME-$datum.cfg "
        else
                komanda="scp -P $PORT -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null  $ubnt_user@$ADRESA:/tmp/system.cfg $BACKUP_PATH/U-$IME-$datum.cfg"
        fi

#	echo "$komanda"
	echo $komanda >> $error_log
	$komanda >> $error_log 2>> $error_log
	izlaz=$?
	if [ $izlaz -ne 0 ]; then
		greska=1
	fi
	echo Izlaz: $izlaz >>$error_log
	echo >> $error_log
	if [ "$REBOOT" == "REBOOT" ]; then
		komanda="ssh  $ubnt_user@$ADRESA -p $PORT reboot"
		echo $komanda >> $error_log
		$komanda >> $error_log 2>> $error_log
		izlaz=$?
		if [ $izlaz -ne 0 ]; then
			greska=1
		fi

	echo Izlaz: $izlaz >>$error_log
	echo >> $error_log
	komanda="sleep 350"
	echo $komanda >> $error_log
	$komanda
	fi #ent if REBOOT
}






function listbackup {
for i in `cat $lista`; do
	TIP=`echo $i | awk '{print $1}'`
	IME=`echo $i | awk '{print $2}'`
	ADRESA=`echo $i | awk '{print $3}'`
	PORT=`echo $i | awk '{print $4}'`
	BUSER=`echo $i | awk '{print $5}'`
	PASS=`echo $i | awk '{print $6}'`
	unset IFS
	echo $IME, $ADRESA, $PORT, $PASS >> $error_log
	echo >> $error_log

	if [ "$TIP" == "U" ]; then
		ubntbackup $IME $ADRESA $PORT $BUSER $PASS
	elif [ "$TIP" == "M" ]; then
		mtikbackup $IME $ADRESA $PORT $BUSER $PASS
	fi

done
}


if [ "$1" == "M" ]; then
	mtikbackup $2 $3 $4 $5
elif [ "$1" == "U" ]; then
	ubntbackup $2 $3 $4 $5
else
	listbackup
fi



if [ $greska -ne 0 ]; then
	cat $error_log | mail -s "UBNT BAckup error" backup@entitas.hr
fi

rm $error_log

