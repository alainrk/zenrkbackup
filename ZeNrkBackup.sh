#!/bin/bash

#########################################################################
# Autore 	: Alain Di Chiappari						
# Data 		: 06/2011							
# Licenza	: GNU General Public License					
# Email		: alain.narko@gmail.com
# Info Licenza	: <http://www.gnu.org/licenses/>
#########################################################################

CONFIG_FOLDER=$HOME/.config_nrkback
OPTION=""
NAMEPROJ="__/IS/NOT/A/POSSIBLE/NAME/OF/FILE/__"
FOLDER="_/IS/NOT/OK/_"
CONFIG_FILE=""
NOTE=""
BACKUPPED=""
TRUE=1


# Parte attiva -> BACKUP
backup() {

	# Variabili utili al backup
	NAME=$1
	# Estrazione cartella sorgente dal file di configurazione
	SOURCE=`awk '{if ($1 ~ "Source:") {print $2}}' < $CONFIG_FOLDER/$NAME` >& /dev/null
	BASE=`basename $SOURCE`
	DATE=`date +%Y.%m.%d-%H:%M:%S`
	BACKUPNAME=$BASE-$DATE
	NOTEFILE=backup-$DATE
	# Estrazione di tutte le destinazioni per il backup
	DESTINATIONS=`awk '{if ($1 ~ "Backup_in:") {print $2}}' < $CONFIG_FOLDER/$NAME`

	NOTE=`zenity --entry \
							 --title="Description" \
							 --text="A little message for your backup" \
							 --entry-text="Insert here the message"`

	# Creazione file del messaggio
	echo $NOTE > $NOTEFILE

	# Aggiunta informazioni al file di configurazione riguardo l'ultimo backup
	echo "" >> $CONFIG_FOLDER/$NAME
	echo -e "$DATE\t$NOTE" >> $CONFIG_FOLDER/$NAME

	# Backupping per ogni destinazione specificata	
	for target in $DESTINATIONS
	do
		# Copio cartella
		cp -r $SOURCE $target
		# Rinomino con nome di backup
		mv $target/$BASE $target/$BACKUPNAME
		# Metto il file con il messaggio al suo interno
		cp $NOTEFILE $target/$BACKUPNAME

		ls -Rl $target/$BACKUPNAME | zenity --list --title "Backup" --text "Confirmed copy..." --column "Files" --width=500 --height=800
	done

	# Cancello il file del messaggio temporaneamente creato
	rm $NOTEFILE
}


resume() {
	# WARNING
	zenity --question --text='Are you sure to proceed?\nThis operation overwrites every files in your source project directory.\nFirst BACKUP your current project configuration!'

	if [[ $? -eq 1 ]]; then
		exit 1
	fi

	NAME=$1
	SOURCE=`awk '{if ($1 ~ "Source:") {print $2}}' < $CONFIG_FOLDER/$NAME` >& /dev/null
	DESTINATIONS=`awk '{if ($1 ~ "Backup_in:") {print $2}}' < $CONFIG_FOLDER/$NAME`
	for target in $DESTINATIONS
	do
		# Folder to resume
		WHEREIAM=`pwd`
		cd $target
		RESUMED=`zenity --file-selection \
							 --title="Choose the folder to resume" \
							 --directory`

		if [[ $? -eq 1 || -z $RESUMED ]]; then
			exit 1
		fi

		# Cancellazione vecchi file in sorgente
		cd $SOURCE
		rm -rf *
		# Copia nuovi file da un precedente backup
		cd $RESUMED
		cp -rf * $SOURCE

		ls -Rl $SOURCE | zenity --list --title "Resume" --text "Confirmed resume..." --column "Files" --width=500 --height=800

		cd $WHEREIAM
		break
	done
	
}


if [[ ! -e $CONFIG_FOLDER ]]; then
	echo "Creating configuration folder \"$CONFIG_FOLDER\" ..."
	mkdir $CONFIG_FOLDER
fi

while [[ $TRUE ]]; do

	LIST="`ls $CONFIG_FOLDER` ---REMOVE_ALL---"
	
	CHOICE=`zenity --list \
					--title="--- Easy Backup System ---" \
					--text="\tRelease under GPL v.2\n\tAlain Di Chiappari" \
					--column="Action" \
					--column="Description" \
					--width=400 \
					--height=280 \
					Backup "BACKUP your project!" \
					Resume "RESUME your project!" \
					New "Create a new configuration" \
					Remove "Remove an old configuration" \
					Info "Visualize informations about your projects" \
					Exit "Quit the program"`

	if [[ $? -eq 1 || $CHOICE = Exit ]]; then
		exit 1
	fi

	case "$CHOICE" in

	# Crea una nuova configurazione ------------------------------------------------------------
	New)
		until [[ -f CONFIG_FOLDER/NAMEPROJ ]]
		do
			NAMEPROJ=`zenity --entry \
								--title="Name" \
								--text="New project name" \
								--entry-text="Insert here the name"`

			if [[ $? -eq 1 || -z $NAMEPROJ ]]; then
				exit 1
			fi

			NAMEPROJ=`echo $NAMEPROJ | tr 'A-Z ' 'A-Z_'`

			if [[ ! -f $CONFIG_FOLDER/$NAMEPROJ ]]; then
				CONFIG_FILE=$CONFIG_FOLDER/$NAMEPROJ
				# Create the configuration file
				touch $CONFIG_FILE
				break
			else 
				zenity --error \
				--title="Name Error" \
				--text="Already exist this project"
			fi
		done

		# Folder to backup
		BACKUPPED=`zenity --file-selection \
							 --title="Choose the folder to backup" \
							 --directory`

		if [[ $? -eq 1 || -z $BACKUPPED ]]; then
			exit 1
		fi
		echo "Source: $BACKUPPED" >> $CONFIG_FILE

		zenity --info \
					 --title="Backup" \
					 --text="Choose each directory where you want the backup[s]\n[Annulla/Cancel] to stop your choice"
		
		# Backup folders dest
		while [[ $FOLDER != "ok" ]]
		do
			FOLDER=`zenity --file-selection \
							 --title="[Annulla/Cancel] to stop" \
							 --directory`

			if [[ $? -eq 1 ]]; then
				break
			fi

			echo "Backup_in: $FOLDER" >> $CONFIG_FILE

		done


		NOTE=`zenity --entry \
								 --title="Description" \
								 --text="A little description of your project" \
								 --entry-text="Insert here the note"`

		echo "Description: $NOTE" >> $CONFIG_FILE
	;;

	# Riporta in vita una backup, potendo scegliere la data ------------------------------------
	Resume)
		LIST=`ls $CONFIG_FOLDER`

		if [[ -z $LIST ]]; then
			zenity --info \
						 --title="List" \
						 --text="There are no project configurations"
			continue
		fi

		NAME=`zenity --list \
								 --title "Your projects" \
								 --column "Name" $LIST \
								 --text="Click to resume"`

	# Chiama la funzione di Resume
	resume $NAME
	;;

	# Cancella uno o tutti i file di configurazione --------------------------------------------
	Remove)
		LIST=`ls $CONFIG_FOLDER`

		if [[ -z $LIST ]]; then
			zenity --info \
						 --title="List" \
						 --text="There are no project configurations"
			continue
		fi

		DEL=`zenity --list \
				--title "Remove" \
				--column "Name" $LIST \
				--text="Insert the name of configuration to remove\nThis operation remove ONLY the script configuration"`

		rm $CONFIG_FOLDER/$DEL

	;;

	# Lista tutte le configurazioni esistenti --------------------------------------------------
	Info)
		LIST=`ls $CONFIG_FOLDER`

		if [[ -z $LIST ]]; then
			zenity --info \
						 --title="List" \
						 --text="There are no project configurations"
			continue
		fi

		NAME=`zenity --list \
								 --title "Your projects" \
								 --column "Name" $LIST \
								 --text="Click to obtain info"`

		# Estrazione informazioni da mostrare nella list (awk..)
		zenity --text-info \
					 --title=$NAME \
					 --filename=$CONFIG_FOLDER/$NAME \
	;;

	# Esegue il backup di un progetto ----------------------------------------------------------
	Backup)
		LIST=`ls $CONFIG_FOLDER`

		if [[ -z $LIST ]]; then
			zenity --info \
						 --title="List" \
						 --text="There are no project configurations"
			continue
		fi

		NAME=`zenity --list \
								 --title "Your projects" \
								 --column "Name" $LIST \
								 --text="Click to backup"`

	# Chiama la funzione di Backup
	backup $NAME

	;;

	# Esci dallo script ------------------------------------------------------------------------
	Exit)
		exit 0
	;;

	esac

done
