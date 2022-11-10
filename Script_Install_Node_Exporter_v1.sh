#!/bin/bash
#made by jonathan ORTEGA 
#Script qui permet de récupérer et installer Node exporter
#####################################################################
#####################################################################

#####Variables prédéclarées

USER_NODE="node_exporter"
CONTENU_SERVICE="[Unit]\nDescription=Node Exporter\nAfter=network-online.target\n[Service]\nUser=node_exporter\nGroup=node_exporter\nType=simple\nExecStart=/usr/local/bin/node_exporter\n[Install]\nWantedBy=multi-user.target"
SERVICE=node_exporter.service
TEST=test.txt
CHEMIN_SERVICE=/etc/systemd/system/$SERVICE
CHEMIN_TEST=/etc/systemd/system/$TEST




#####Fonction imposant utilisation en tant qu utilisateur sudoers
fonction_sudoers_needed() {
        if [ $(id -u) -ne 0 ]
        then
                echo "Ce script doit être lancé en tant que sudoers"
                exit 1
        else
                echo "ce script peut commencer car utilisateur qui l a executé est sudoers"
        fi
}

#####Fonction vérfiant si service Node Exporter est actif
fonction_verif_serv_nodexp_actif() {
	VERIF_NODEXP_ACTIF="yes"
	while [ "$VERIF_NODEXP_ACTIF" = "yes" ]
	do
        	pgrep -x "node_exporter"
        	if [ $? -eq 0 ]
       		then
	  		fonction_yes_no_NODEXP_ACTIF_q7	
        	else
                	echo "le service \" node exporter \" n'est pas actif sur cette machine"
			VERIF_NODEXP_ACTIF="no"
        	fi
	done
}

#####Fonction si service Node exp déjà actif avant installation pour l'arreter 
fonction_yes_no_NODEXP_ACTIF_q7() {
	QUESTION_7=""
        while [ "$QUESTION_7" != "yes" ] && [ "$QUESTION_7" != "no" ]
        do
        	echo "\"node exporter\" est un service déjà actif sur cette machine, vous devez l'arreter avant d'installer cette version"
                echo "Souhaitez-vous l arreter et continuer l installation? [yes/no]"
                echo "répondre \"no\" annulera l'installation de node exporter"
                read -p "Réponse : " QUESTION_7
        done

        if [ $QUESTION_7 = "no" ]
        then
                echo "installation de \" node exporter \" annulée "
                exit 0
        elif [ $QUESTION_7 = "yes" ]
        then
                echo "le service sera arrété"
                systemctl stop node_exporter
        fi
}

#####Fonction vérifiant si un fichier bin de node exporter existe déjà
fonction_verif_bin_nodexp_exist() {
        which node_exporter
        if [ $? -eq 0 ]
        then
                echo "un \" fichier bin de node exporter \" existe sur cette machine, possible qu une version de node exporter soit déjà installée"
                echo "vous devez le supprimer avant d'installer cette version et d'utiliser ce script"
                echo "l'installation de node exporter est annulée"
		echo "utillisez la commande \" which node_exporter \" pour localiser le fichier bin à supprimer"
                exit 0
        else
                echo "aucun fichier bin de node exporter n'est présent sur cette machine"
                echo "Début de l'installation de node exporter"
        fi
}


#####Fonction si archive conforme demande si retente

fonction_yes_no_ARCHIVE_CONFORME_q10() {
        QUESTION_10=""
        while [ "$QUESTION_10" != "yes" ] && [ "$QUESTION_10" != "no" ]
        do
                echo "le nom d'archive indiqué n'est pas de type \" .tar.gz \" et n'est donc pas conforme"
                echo "Souhaitez vous retenter avec un nouveau nom d'archive ? [yes/no]"
                echo "si \" no \" est sélectionné, cela annulera l'installation de node exporter"
                read -p "Reponse : " QUESTION_10
        done

        if [ $QUESTION_10 = "no" ]
        then
                echo "l'installation de node exporter est annulée"
                exit 1
        fi
}


######Fonction si echec de recup de node exporter sur le serveur distant

fonction_yes_no_recup_serveur_echec_q() {
        QUESTION=""
        while [ "$QUESTION" != "yes" ] && [ "$QUESTION" != "no" ]
        do
                echo "la tentative de récupération de l'archive sur le serveur distant a échoué"
                echo "le serveur distant est peut etre inaccessible ou l'archive non présente dans le dossier ~ de l'utilisateur"
                echo "Souhaitez-vous tout de même retenter? [yes/no]"
                echo "si vous selectionner \"no\" vous pourrez tenter de télécharger l'archive par Internet"
                read -p "Réponse : " QUESTION
        done
}

#####Fonction demandant si on tente le téléchargement de node exporter depuis internet

fonction_yes_no_download_from_internet_q2() {
        QUESTION_2=""
        while [ "$QUESTION_2" != "yes" ] && [ "$QUESTION_2" != "no" ]
        do
                echo "Le transfert a échoué, mais vous pouvez tenter de télécharger l'archive Node_Exporter depuis Internet. Le souhaitez vous ? [yes/no]"
                echo "si no est sélectionné, cela annulera l'installation de node exporter"
                read -p "Reponse : " QUESTION_2
        done
}


#####Fonction qui permet de télecharger l'archive depuis internet
fonction_download_nodexp_from_internet() {
        while [ $QUESTION_2 = "yes" ]
        do
                echo "entrez le lien de téléchargement de l'archive Node exporter"
                echo "Avertissement, vérifiez bien que le lien soit le bon"
                read  -p "Lien : " LIEN_TELECHARGEMENT

                wget -T 5 -t 1 --no-http-keep-alive --no-cache --no-cookies -P /usr/share $LIEN_TELECHARGEMENT

                if [ $? -eq 0 ]
                then
                        RETURN_CODE="success"
                else
                        RETURN_CODE="fail"
                fi

                if [ -f /usr/share/$ARCHIVE -a $RETURN_CODE = "success" ]
                then
                        QUESTION_2="pursue"
                elif [ ! -f /usr/share/$ARCHIVE -a $RETURN_CODE = "success" ]
                then
			fonction_yes_no_diff_name_archive_q2_again
                elif [ ! -f /usr/share/$ARCHIVE -a $RETURN_CODE = "fail" ]
                then
			fonction_yes_no_echec_download_q2_again
                fi
        done
}

#####fonction si archive téléchargé pas le bon nom demande si retente

fonction_yes_no_diff_name_archive_q2_again() {
        QUESTION_2=""
        while [ "$QUESTION_2" != "yes" ] && [ "$QUESTION_2" != "no" ]
        do
                echo "Un fichier a bien été téléchargé dans \" /usr/share \" mais ne possède pas le même nom que $ARCHIVE"
                echo "Il est possible que vous n'ayez pas indiqué le bon lien"
                echo "Etait-ce une erreur ?"
                echo "répondre \"yes\" pour retenter le téléchargement"
                echo "répondre \"no\" pour annuler l'installation de node exporter"
                read -p "Réponse : " QUESTION_2
        done
 }

#####Fonction si echec telechargement archive

fonction_yes_no_echec_download_q2_again() {
        QUESTION_2=""
        while [ "$QUESTION_2" != "yes" ] && [ "$QUESTION_2" != "no" ]
        do
                echo "la tentative de téléchargement a échoué. Souhaitez-vous retentez? [yes/no]"
                read -p "Réponse : " QUESTION_2
        done
}


#####Verifie si utilisateur a bien été crée après essai de création de l'utilisateur sinon appelle autre fonction
fonction_verif_user_creation() {
        getent passwd $USER_NODE
        if [ $? -eq 0 ]
        then
                echo "l'utilisateur \" $USER_NODE \" a bien été créé"
                USER_EXISTENCE="success"
        else
                fonction_yes_no_user_NoCreate_q4
        fi
}

#####Question yes/no si retente
fonction_yes_no_user_NoCreate_q4() {
        QUESTION_4=""
        while [ "$QUESTION_4" != "yes" ] && [ "$QUESTION_4" != "no" ]
        do
                echo "le processus de création de l'utilisateur \" $USER_NODE \" a rencontré un problème"
                echo "l'utilisateur \" $USER_NODE \" n' a donc pas été créé"
                echo "Souhaitez-vous rééssayer? [yes/no]"
                echo "répondre \"yes\" pour retenter la création de \" $USER_NODE \" "
                echo "répondre \"no\" pour annuler l'installation de node exporter"
                read -p "Réponse : " QUESTION_2
        done

        if [ $QUESTION_4 = "no" ]
        then
                USER_EXISTENCE="definitive_failure"
        fi
}

#####affiche le statut d installation de l utilisateur node_exporter selon variable USER_EXISTENCE
fonction_user_install_status() {
        if [ $USER_EXISTENCE = "direct_success" ]
        then
                echo "l'utilisateur \" $USER_NODE \" existe déjà"
        elif [ $USER_EXISTENCE = "success" ]
        then
                echo "l'utilisateur \" $USER_NODE \" a bien été créé"
        elif [ $USER_EXISTENCE = "definitive_failure" ]
        then
                echo "l'installation de node exporter a été annulé car l'utilisateur \" $USER_NODE \" n'a pas pu être installé"
                exit 1
        fi
}

#####Fonction de comparaison
fonction_testcompar_nodexp_serv() {
        if [ -e $CHEMIN_TEST ]
        then
                echo "le fichier test existe déjà, il sera effacé"
                rm $CHEMIN_TEST
                echo "le fichier test a été effacé"
        else
                echo "le fichier test n'existe pas et sera créé"
        fi

        touch $CHEMIN_TEST
        echo "le fichier $TEST a été créé"
        echo $CONTENU_SERVICE > $CHEMIN_TEST
        diff -q $CHEMIN_TEST $CHEMIN_SERVICE

        if [ $? -eq 0 ]
        then
                echo "$SERVICE et $TEST sont similaire, donc $SERVICE est conforme"
        else
                echo "le service existe mais est différent du défaut, il sera  copié sous nom $SERVICE.old et un nouveau service sera créé"
                cp $CHEMIN_SERVICE /etc/systemd/system/$SERVICE.old
                echo $CONTENU_SERVICE > $CHEMIN_SERVICE
        fi
}

###############################################
##############################################

#####Verif si utilisé par sudoers
fonction_sudoers_needed

#####Vérifie si Node exporter est déjà présent dans la machine

fonction_verif_serv_nodexp_actif

fonction_verif_bin_nodexp_exist


######Entrez nom d'archive et verif si archive est en .tar.gz

ARCHIVE_CONFORM="no"
while [ "$ARCHIVE_CONFORM" = "no" ]
do
        echo "Indiquez le nom de l'archive de node exporter (obligatoirement en .tar.gz)"
        read -p "Nom de l'archive: "  ARCHIVE

        case $ARCHIVE in
            *.tar.gz )
                echo "l'archive est de type \" .tar.gz \" elle est donc conforme"
                ARCHIVE_CONFORM="yes"
                ;;
            * )
		fonction_yes_no_ARCHIVE_CONFORME_q10
                ;;
        esac
done

####Vérifie si l'archive de Node_Exporter est déjà présente ou la prend depuis un serveur local distant ou la prend depuis Internet

if [ ! -f /usr/share/$ARCHIVE ]
then
        QUESTION="yes"

        while [ "$QUESTION" = "yes" ]
        do
                echo "l'archive n'est pas présente dans le repertoire \" /usr/share\"  de cette machine et doit être récupéré"
                echo "Indiquez l'adresse IP du serveur où récupérer l'archive"
                read -p "Adresse IP : " IP_SERVER_RECUP
                echo "Indiquez nom d'utilisateur au sein du serveur distant où récupérer l'archive"
                read -p "nom utilisateur: " USER_RECUP

                scp -r -q -p -o ConnectTimeout=30 $USER_RECUP@$IP_SERVER_RECUP:~/$ARCHIVE /usr/share/$ARCHIVE

                if [ $? -eq 0 ]
                then
                        QUESTION="pursue"
                        QUESTION_2="pursue"
                else
			fonction_yes_no_recup_serveur_echec_q
                fi
        done

        if [ $QUESTION = "no" ]
        then
		fonction_yes_no_download_from_internet_q2

                if [ $QUESTION_2 = "no" ]
                then
                        echo "Annulation de l'installation de node exporter"
                        exit 0
                else
			fonction_download_nodexp_from_internet 
                fi
        fi

        if [ $QUESTION_2 = "no" ]
        then
		echo "l'installation de \" node exporter \" est annulée"
                exit 0
        elif [ $QUESTION_2 = "pursue" ]
        then
                echo "l'archive $ARCHIVE est maintenant présente dans le repertoire \" /usr/share \" "
        fi
else
        QUESTION="pursue" #archive déjà présente
        echo "l'archive $ARCHIVE  existe déjà dans le repertoire  \" /usr/share \" "
fi



#####Désarchive Node_Exporter
NODE_EXPORTER=${ARCHIVE%???????}
if [ ! -e $NODE_EXPORTER ]
then
	echo "le repertoire \" $NODE_EXPORTER \" sera créé à partir de l'archive \" $ARCHIVE \" "
else
	COPY_NODE_EXPORTER=$NODE_EXPORTER.old
	echo "un repertoire \" $NODE_EXPORTER \" existe déjà dans /usr/share"
	echo "il sera copié dans \" /usr/share \" sous le nom \" $COPY_NODE_EXPORTER \" "
	cp -r /usr/share/$NODE_EXPORTER /usr/share/$COPY_NODE_EXPORTER
	echo "le repertoire \" $NODE_EXPORTER \" sera maintenant créé à partir de l'archive \" $ARCHIVE \" "
fi
 
tar -xvzf /usr/share/$ARCHIVE -C /usr/share
	
mv /usr/share/$NODE_EXPORTER/node_exporter /usr/local/bin/



#####Vérifie si un utilisateur pour node exporter existe déjà ou en crée un

getent passwd $USER_NODE
if [ $? -eq 0 ]
then
        USER_EXISTENCE="direct_success"
else
        USER_EXISTENCE="fail"
fi

while [ $USER_EXISTENCE = "fail" ]
do
        echo "l'utilisateur nommé \" $USER_NODE \" qui sera attribué à Node Exporter n'existe pas encore et sera créé"
        useradd -rs /bin/false $USER_NODE
        fonction_verif_user_creation
done

fonction_user_install_status



#####Vérifie si le service Node exporter est déjà existant dans /etc/systemd/system, sinon en crée un , si oui compare à un fichier test

if [ ! -e $CHEMIN_SERVICE ]
then
        echo "le service $SERVICE n'existe pas encore"
        touch $CHEMIN_SERVICE
        echo $CONTENU_SERVICE >> $CHEMIN_SERVICE
else
        echo "le service existe déjà"
        fonction_testcompar_nodexp_serv
fi
echo "le service est pret chemin : $CHEMIN_SERVICE"


#####Charge Node exporter et fait redémarrer les services nécessaires

systemctl daemon-reload
systemctl enable node_exporter
sudo systemctl start node_exporter

if [ $( systemctl show -p ActiveState --value node_exporter ) = "active" ]
then
        echo "le service node exporter est actif"
        echo "l'installation est terminé"
        echo "la page web de node exporter devrait être accessible depuis le port 9100"
        echo "Node exporter fonctionne en général avec prometheus aussi n'oubliez pas de compléter le fichier .yml de prmetheus"
        echo "FLAWLESS VICTORY INDEEEEEEED"
else
        echo "il y a eu un probleme, node exporter n'est pas actif"
        echo "etrange que ça échoue à ce stade tout de même..."
        echo "................................................"
        echo "ce script ne peut plus rien pour vous, il va falloir trouver à la main pourquoi ça marche pas, GOOD LUCK"
fi
