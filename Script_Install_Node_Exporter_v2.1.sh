#!/bin/sh
#made by jonathan ORTEGA
#Commande pour lancer le script :   sudo sh cheminduscript
#Script Shell langage qui permet de récupérer l'archive de l'agent Node Exporter depuis un serveur distant dans un premier temps
#et en cas d'echec essaiera de le telecharger depuis internet
#Ensuite il installera Node exporter sur la machine executant le Script
#Le script a été testé avec l'archive node_exporter-1.4.0.linux-amd64.tar.gz
#####################################################################
#####################################################################
#####Commande de Secu script

set -o nounset   #exit le code si exécute une variable non déclarée
#set -x   #indique chaque commande effectuée durant l'execution du script, utile pour debug, retirer le hashtag pour le rendre actif


#####Variables globales prédéclarées

user_node="node_exporter"
contenu_service="[Unit]\nDescription=Node Exporter\nAfter=network-online.target\n[Service]\nUser=node_exporter\nGroup=node_exporter\nType=simple\nExecStart=/usr/local/bin/node_exporter\n[Install]\nWantedBy=multi-user.target\n"
service="node_exporter.service"
test="test.txt"
chemin_service="/etc/systemd/system/"${service}""
chemin_test="/etc/systemd/system/"${test}""




#####Fonction imposant utilisation en tant qu utilisateur sudoers
fonction_sudoers_needed() {
        if [ "$(id -u)" -ne 0 ]
        then
                printf "Ce script doit être lancé en tant que sudoers\n"
                exit 10
        else
                printf "ce script peut commencer car utilisateur qui l a executé est sudoers\n"
        fi
}

#####Fonction vérfiant si service Node Exporter est actif
fonction_verif_serv_nodexp_actif() {
        verif_nodexp_actif="yes"
        while [ "${verif_nodexp_actif}" = "yes" ]
	do
        pgrep -x "node_exporter"
                if [ "$?" -eq 0 ]
       	        then
	                fonction_yes_no_NODEXP_ACTIF_q7
                else
                        printf "le service \" node exporter \" n'est pas actif sur cette machine\n"
		        verif_nodexp_actif="no"
        	fi
	done
}

#####Fonction si service Node exp déjà actif avant installation pour l'arreter
fonction_yes_no_NODEXP_ACTIF_q7() {
	question_7="empty"
        while [ "${question_7}" != "yes" ] && [ "${question_7}" != "no" ]
        do
              	printf "\"node exporter\" est un service déjà actif sur cette machine, vous devez l'arreter avant d'installer cette version\n"
                printf "Souhaitez-vous l arreter et continuer l installation? [yes/no]\n"
                printf "répondre \"no\" annulera l'installation de node exporter\n"
                printf "Réponse : "
                read question_7
        done
        case "${question_7}" in
                "yes" )
                        printf "le service sera arrété\n"
                        systemctl stop node_exporter
                        ;;
                "no" )
                        printf "installation de \" node exporter \" annulée\n "
                        exit 11
                        ;;
        esac
}

#####Fonction vérifiant si un fichier bin de node exporter existe déjà
fonction_verif_bin_nodexp_exist() {
        which node_exporter
        if [ "$?" -eq 0 ]
        then
                question_11="empty"
                while [ "${question_11}" != "yes" ] && [ "${question_11}" != "no" ]
                do
                        printf "un \" fichier bin de node exporter \" existe sur cette machine, possible qu une version de node exporter soit déjà installée\n"
                        printf "Il doit être supprimé pour continuer l'installation de Node Exporter\n"
                        printf "Souhaitez-vous le supprimer ? [yes/no]\n"
                        printf "si \" no \" est sélectionné, cela annulera l'installation de node exporter\n"
                        printf "Reponse : "
                        read question_11
                done
                case ${question_11} in
                        "yes" )
                                printf "le fichier bin sera suprimé\n"
                                rm $(which node_exporter)
                                ;;
                        "no" )
                                printf "Annulation de l'installation de Node Exporter\n"
                                exit 11
                                ;;
                esac
        else
                printf "aucun fichier bin de node exporter n'est présent sur cette machine\n"
        fi
        printf "Début de l'installation de node exporter\n"
}


#####Fonction si archive conforme demande si retente

fonction_yes_no_archive_conforme_q10() {
        question_10="empty"
        while [ "${question_10}" != "yes" ] && [ "${question_10}" != "no" ]
        do
                printf "le nom d'archive indiqué n'est pas de type \" .tar.gz \" et n'est donc pas conforme\n"
                printf "Souhaitez vous retenter avec un nouveau nom d'archive ? [yes/no]\n"
                printf "si \" no \" est sélectionné, cela annulera l'installation de node exporter\n"
                printf "Reponse : "
                read question_10
        done
        case ${question_10} in
                "no" )
                        printf "Annulation de l'installation de Node Exporter\n"
                        exit 11
                        ;;
        esac
}


######Fonction si echec de recup de node exporter sur le serveur distant

fonction_yes_no_recup_serveur_echec_q() {
        question="empty"
        while [ "${question}" != "yes" ] && [ "${question}" != "no" ]
        do
                printf "la tentative de récupération de l'archive sur le serveur distant a échoué\n"
                printf "le serveur distant est peut etre inaccessible ou l'archive non présente dans le dossier ~ de l'utilisateur\n"
                printf "Souhaitez-vous tout de même retenter? [yes/no]\n"
                printf "si vous selectionner \"no\" vous pourrez tenter de télécharger l'archive par Internet\n"
                printf "Reponse : "
                read question
        done
}

#####Fonction demandant si on tente le téléchargement de node exporter depuis internet

fonction_yes_no_download_from_internet_q2() {
        question_2="empty"
        while [ "${question_2}" != "yes" ] && [ "${question_2}" != "no" ]
        do
                printf "Le transfert depuis le serveur distant a échoué, mais vous pouvez tenter de télécharger l'archive Node_Exporter depuis Internet. Le souhaitez vous ? [yes/no]\n"
                printf "si no est sélectionné, cela annulera l'installation de node exporter\n"
                printf "Reponse : "
                read question_2
        done
}


#####Fonction qui permet de télecharger l'archive depuis internet
fonction_download_nodexp_from_internet() {
        while [ "${question_2}" = "yes" ]
        do
                printf "entrez le lien de téléchargement de l'archive Node exporter\n"
                printf "Avertissement, vérifiez bien que le lien soit le bon\n"
                printf "Lien URL : "
                read lien_telechargement

                wget -T 5 -t 1 --no-http-keep-alive --no-cache --no-cookies -P /usr/share "${lien_telechargement}"

                if [ "$?" -eq 0 ]
                then
                        return_code="success"
                else
                        return_code="fail"
                fi

                if [ -f /usr/share/"${archive}" ] && [ "${return_code}" = "success" ]
                then
                        question_2="pursue"
                elif [ ! -f /usr/share/"${archive}" ] && [ "${return_code}" = "success" ]
                then
	                fonction_yes_no_diff_name_archive_q2_again
                elif [ ! -f /usr/share/"${archive}" ] && [ "${return_code}" = "fail" ]
                then
		        fonction_yes_no_echec_download_q2_again
                fi
        done
}

#####fonction si archive téléchargé pas le bon nom demande si retente

fonction_yes_no_diff_name_archive_q2_again() {
        question_2="empty"
        while [ "${question_2}" != "yes" ] && [ "${question_2}" != "no" ]
        do
                printf "Un fichier a bien été téléchargé dans \" /usr/share \" mais ne possède pas le même nom que "${archive}"\n"
                printf "Il est possible que vous n'ayez pas indiqué le bon lien\n"
                printf "Etait-ce une erreur ?\n"
                printf "répondre \"yes\" pour retenter le téléchargement\n"
                printf "répondre \"no\" pour annuler l'installation de node exporter\n"
                printf "Reponse : "
                read question_2
        done
 }

#####Fonction si echec telechargement archive

fonction_yes_no_echec_download_q2_again() {
        question_2="empty"
        while [ "${question_2}" != "yes" ] && [ "${question_2}" != "no" ]
        do
                printf "la tentative de téléchargement a échoué. Souhaitez-vous retentez? [yes/no]\n"
                printf "Reponse : "
                read question_2
        done
}

#####Verifie si utilisateur a bien été crée après essai de création de l'utilisateur sinon appelle autre fonction
fonction_verif_user_creation() {
        getent passwd "${user_node}"
        if [ "$?" -eq 0 ]
        then
                printf "l'utilisateur \ "${user_node}" \" a bien été créé\n"
                user_existence="success"
        else
                fonction_yes_no_user_NoCreate_q4
        fi
}

#####question yes/no si retente
fonction_yes_no_user_NoCreate_q4() {
        question_4="empty"
        while [ "${question_4}" != "yes" ] && [ "${question_4}" != "no" ]
        do
                printf "le processus de création de l'utilisateur \" "${user_node}" \" a rencontré un problème\n"
                printf "l'utilisateur \" "${user_node}"\" n' a donc pas été créé\n"
                printf "Souhaitez-vous rééssayer? [yes/no]\n"
                printf "répondre \"yes\" pour retenter la création de \" "${user_node}" \" \n"
                printf "répondre \"no\" pour annuler l'installation de node exporter\n"
                printf "Reponse : "
                read question_4
        done
        case "${question_4}" in
                "no" )
                        user_existence="definitive_failure"
                        ;;
        esac
}

#####affiche le statut d installation de l utilisateur node_exporter selon variable user_existence
fonction_user_install_status() {
        case "${user_existence}" in
                "direct_success" )
                        printf "l'utilisateur \" "${user_node}" \" existe déjà\n"
                        ;;
                "success" )
                        printf "l'utilisateur \" "${user_node}" \" a bien été créé\n"
                        ;;
                "definitive_failure" )
                        printf "l'installation de node exporter a été annulé car l'utilisateur \" "${user_node}" \" n'a pas pu être installé\n"
                        exit 11
                        ;;
        esac
}

#####Fonction de comparaison
fonction_testcompar_nodexp_serv() {
        if [ -e "${chemin_test}" ]
        then
                printf "le fichier test existe déjà, il sera effacé\n"
                rm "${chemin_test}"
                printf "le fichier test a été effacé\n"
        else
                printf "le fichier test n'existe pas et sera créé\n"
        fi

        touch "${chemin_test}"
        printf "le fichier "${test}" a été créé\n"
        printf "${contenu_service}" > "${chemin_test}"
        diff -q "${chemin_test}" "${chemin_service}"

        if [ "$?" -eq 0 ]
        then
                printf ""${service}" et "${test}" sont similaire, donc "${service}" est conforme\n"
        else
                printf "le service existe mais est différent du défaut, il sera  copié sous nom "${service}".old et un nouveau service sera créé\n"
                cp "${chemin_service}" /etc/systemd/system/"${service}".old
                printf "${contenu_service}" > "${chemin_service}"
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

archive_conform="no"
while [ "${archive_conform}" = "no" ]
do
        printf "Indiquez le nom de l'archive de node exporter (obligatoirement en .tar.gz)\n"
        printf "Nom de l'archive : "
        read archive

        case "${archive}" in
            *.tar.gz )
                printf "l'archive est de type \" .tar.gz \" elle est donc conforme\n"
                archive_conform="yes"
                ;;
            * )
		            fonction_yes_no_archive_conforme_q10
                ;;
        esac
done

####Vérifie si l'archive de Node_Exporter est déjà présente ou la prend depuis un serveur local distant ou la prend depuis Internet

if [ ! -f /usr/share/"${archive}" ]
then
        question="yes"

        while [ "${question}" = "yes" ]
        do
                printf "l'archive n'est pas présente dans le repertoire \" /usr/share\"  de cette machine et doit être récupéré\n"
                printf "Indiquez l'adresse IP du serveur où récupérer l'archive\n"
                printf "Adresse IP : "
                read ip_server_recup
                printf "Indiquez nom d'utilisateur au sein du serveur distant où récupérer l'archive\n"
                printf "nom utilisateur : "
                read user_recup

                scp -r -q -p -o ConnectTimeout=30 "${user_recup}"@"${ip_server_recup}":~/"${archive}" /usr/share/"${archive}"

                if [ "$?" -eq 0 ]
                then
                        question="pursue"
                        question_2="pursue"
                else
	                fonction_yes_no_recup_serveur_echec_q
                fi
        done

        if [ "${question}" = "no" ]
        then
	        fonction_yes_no_download_from_internet_q2
                case "${question_2}" in
                        "yes" )
                                fonction_download_nodexp_from_internet
                                ;;
                        "no" )
                                printf "Annulation de l'installation de node exporter\n"
                                exit 11
                                ;;
                esac
        fi

        case "${question_2}" in
                "pursue" )
                        printf "l'archive "${archive}" est maintenant présente dans le repertoire \" /usr/share \" \n"
                        ;;
                "no" )
                        printf "l'installation de \" node exporter \" est annulée\n"
                        exit 11
                        ;;
        esac
else
        question="pursue" #archive déjà présente
        printf "l'archive "${archive}"  existe déjà dans le repertoire  \" /usr/share \" \n"
fi



#####Désarchive Node_Exporter
node_exporter=${archive%???????}
if [ ! -e "${node_exporter}" ]
then
	printf "le repertoire \" "${node_exporter}" \" sera créé à partir de l'archive \" "${archive}" \" "
else
	COPY_node_exporter=""${node_exporter}".old"
	printf "un repertoire \" "${node_exporter}" \" existe déjà dans /usr/share \n"
	printf "il sera copié dans \" /usr/share \" sous le nom \" "${COPY_node_exporter}" \" \n"
	cp -r /usr/share/"${node_exporter}" /usr/share/"${COPY_node_exporter}"
	printf "le repertoire \" "${node_exporter}" \" sera maintenant créé à partir de l'archive \" "${archive}" \" \n"
fi

tar -xvzf /usr/share/"${archive}" -C /usr/share

cp /usr/share/"${node_exporter}"/node_exporter /usr/local/bin/

#####Vérifie si un utilisateur pour node exporter existe déjà ou en crée un

getent passwd "${user_node}"
if [ "$?" -eq 0 ]
then
        user_existence="direct_success"
else
        user_existence="fail"
fi

while [ "${user_existence}" = "fail" ]
do
        printf "l'utilisateur nommé \" "${user_node}" \" qui sera attribué à Node Exporter n'existe pas encore et sera créé\n"
        useradd -rs /bin/false "${user_node}"
        fonction_verif_user_creation
done

fonction_user_install_status

chown node_exporter:node_exporter /usr/local/bin/node_exporter
printf "l'utilisateur \""${user_node}"\"est devenu propriétaire du fichier bin \" node_exporter \"\n"

#####Vérifie si le service Node exporter est déjà existant dans /etc/systemd/system, sinon en crée un , si oui compare à un fichier test

if [ ! -e "${chemin_service}" ]
then
        printf "le service "${service}" n'existe pas encore\n"
        touch "${chemin_service}"
        printf "${contenu_service}" > "${chemin_service}"
else
        printf "le service existe déjà\n"
        fonction_testcompar_nodexp_serv
fi
printf "le service est pret chemin : "${chemin_service}"\n"

#####Charge Node exporter et fait redémarrer les services nécessaires

systemctl daemon-reload
systemctl enable node_exporter
sudo systemctl start node_exporter

if [ $( systemctl show -p ActiveState --value node_exporter ) = "active" ]
then
        printf "le service node exporter est actif\n"
        printf "l'installation est terminé\n"
        printf "la page web de node exporter devrait être accessible depuis le port 9100\n"
        printf "Node exporter fonctionne en général avec prometheus aussi n'oubliez pas de compléter le fichier .yml de prmetheus \n"
        printf "FLAWLESS VICTORY INDEEEEEEED\n"
else
        printf "il y a eu un probleme, node exporter n'est pas actif\n"
        printf "etrange que ça échoue à ce stade tout de même...\n"
        printf "................................................\n"
        printf "ce script ne peut plus rien pour vous, il va falloir trouver à la main pourquoi ça marche pas, GOOD LUCK\n"
fi
