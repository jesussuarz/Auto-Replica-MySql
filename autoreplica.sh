#!/bin/sh
#=======================================#
#           ENCABEZADO INICIAL          #
#=======================================#
echo "
#================================================================#
  _____  _____  __      __     _                      _     
  \_   \/ __\ \/ /   /\ \ \___| |___      _____  _ __| | __ 
   / /\/ _\  \  /   /  \/ / _ \ __\ \ /\ / / _ \| '__| |/ / 
/\/ /_/ /    /  \  / /\  /  __/ |_ \ V  V / (_) | |  |   <  
\____/\/    /_/\_\ \_\ \/ \___|\__| \_/\_/ \___/|_|  |_|\_\

       IFX CORP | IFX NETWORKS | DATACENTER | HOSTING
#================================================================#
#   Nombre                      :   Auto Replica
#   Autor                       :   Jesus D. Suarez H.
#   Correo                      :   jdsuarez@ifxcorp.com
#   Nombre del Archivo          :   autoreplica.sh
#================================================================#
#   Licencia                    :   El codigo se distribuye bajo licencia GPLv3
#   Descripción                 :   Script para montar replicas MySql
#   Descargo de responsabilidad :   Este código se ejecuta bajo su total responsabilidad
#   Ayuda                       :   Solo coloque la contraseña de SSH del maestro hasta que deje de solicitarla
#   NOTAS                       :   Proporcione permisos de ejecución al script: chmod +x autoreplica.sh
#                               :   Si se desconecta ssh y debe iniciar de nuevo borre el .sql/.gz en el master/slave
#   Recomendaciones             :   Este script solo debe ejecutarse en su servidor replica/esclavo, nunca en el servidor master 
#                               :   Podría causar el borrado de todas sus bases de datos si intenta ejecutarlo en el server master
#================================================================#"
#=======================================#
#            FUTURAS MEJORAS            #
#=======================================#
#================================================================#
#   Mejoras que se pueden realizar de este código a futuro
#   * Implementar un reintentar si hay un error en la contraseña de ssh maestro 
#   * Barra de progreso en cada uno de los procesos con el paquete PV ej: [===>            ] 20%
#   * Detectar si existe la contraseña agregada en el archivo my.cnf de ser asi inicie sin pedir contraseña
#   * Detectar si no existe configuración de usuario en /root/.my.cnf y en ese caso solicitar la contraseña
#   * Obtener bases de datos a realizar DROP desde my.cnf si esta definido, si no obtener todas
#   * Detectar si se encuentra instalado mysql, de lo contrario instalarlo
#   * Crear usuario de replica automaticamente con permisos 
#   * Configurar bases de datos en el proceso de ejecucion 
#   * Conectarse a SSH con sshkey para luego usar ssh-agent para no solicitar multiples veces la contraseñas 
#================================================================#
#=======================================#
#           VARIABLES GLOBALES          #
#=======================================#
master_host='IP_master' #IP servidor maestro 
master_user='root' #Usuario mysql Maestro
master_pass='password' #Contraseña Maestro mysql
master_port='3306' #Puerto mysql
slave_user='user_slave' #Usuario mysql/mariadb
slave_pass='password' #Contraseña esclavo mysql
#Debe configurar mysql para que no pida contraseña para que esto funcione, Doc. ayuda: https://stackoverflow.com/a/39079470
#Tambien puede usar: export MYSQL_PWD=tu_contraseña_mysql, Doc. ayuda: https://stackoverflow.com/a/34670902
#=======================================#
#       NOMBRE DE LAS BASES DE DATOS    #
#=======================================#
#RECOMENDACION: No se recomienda copiar todas las bases de datos por seguridad, esto podria generar un error en sus datos replica
#Si desea agregar bases de datos adicionales debe modificar la linea de: #Crear bases de datos y agregar las nuevas
database1='DB_1'
database2='DB_2'
#Si todas las bases de datos comienzan por algún prefijo similar, de lo contrario modifique el script
prefix='DB_'
#=======================================#
#         DIRECTORIO DE COPIAS          #
#=======================================#
#Directorio donde se guardan las copias de la DB
#NOTA: Tanto en el master/slave será la misma carpeta de acuerdo a la configuración de este script 
dirsave='/root' 
#=======================================#
#           FECHA DE RESPALDO           #
#=======================================#
date=$(date +"%Y%m%d%H%M%S") 
echo"
#=======================================#
#           INICIO DE EJECUCION         #
#=======================================#
"
echo "  - 1/14) Coloque la contraseña del servidor $master_host"
ssh -o StrictHostKeyChecking=no $master_user@$master_host mysql "-u$master_user" "-p$master_pass" <<-EOSQL & 
    GRANT REPLICATION SLAVE ON *.* TO '$slave_user'@'%' IDENTIFIED BY '$slave_pass'; 
    FLUSH PRIVILEGES; 
    RESET MASTER;
    MASTER_AUTO_POSITION=0;
    FLUSH TABLES WITH READ LOCK; 
    DO SLEEP(3600); 
EOSQL
echo "  - Obteniendo LOG_FILE y LOG_POS de la base de datos del maestro"

#Espera 2 segundos y continua ..
sleep 2  

#Posiciones de LOGs en la DB actual 
MASTER_STATUS=$(ssh -o StrictHostKeyChecking=no $master_user@$master_host mysql "-u$master_user" "-p$master_pass" -ANe "SHOW MASTER STATUS;" | awk '{print $1 " " $2}')
LOG_FILE=$(echo $MASTER_STATUS | cut -f1 -d ' ')
LOG_POS=$(echo $MASTER_STATUS | cut -f2 -d ' ')
echo "  - El archivo de registro actual es $LOG_FILE y la posición del registro es $LOG_POS"

#Crear backup de las bases de datos
echo "  - 2/14) Vuelva a colocar la contraseña del servidor $master_host para crear respaldo"
ssh -o StrictHostKeyChecking=no $master_user@$master_host "mysqldump -u $master_user --password=$master_pass --max_allowed_packet=512M --master-data --single-transaction --hex-blob --routines --triggers --events --quick --add-drop-database --extended-insert --delete-master-logs --databases $database1 $database2 | gzip > $dirsave/dbs_$date.sql.gz"
echo "  - La copia de la base de datos fue creada en el servidor: $master_host:$dirsave"

# Cuando termine, desbloquee las bases de datos
echo "  - 3/14) Vuelva a colocar la contraseña del servidor $master_host para desbloquear base de datos maestra"
ssh -o StrictHostKeyChecking=no $master_user@$master_host mysql -u $master_user -p $master_pass -e "UNLOCK TABLES;";
echo "  - Esperando a que se bloquee la base de datos.."
echo "  - Base de datos maestra desbloqueada"

#Copiando DB backup a local
echo "  - 4/14) Vuelva a escribir la contraseña del servidor maestro $master_host para copiar el respaldo a local"
scp -o StrictHostKeyChecking=no $master_user@$master_host:$dirsave/dbs_$date.sql.gz $dirsave
echo "  - La copia se ha guardado en su servidor replica en el directorio $dirsave"

#Eliminar db remoto .gz
echo "  - 5/14) Por ultima vez vuelva a escribir la contraseña del servidor maestro $master_host"
ssh -o StrictHostKeyChecking=no $master_user@$master_host "rm -rf $dirsave/dbs_$date.sql.gz"
echo "  - Se borro la copia en $master_host:$dirsave"

#Colocando variables en esclavo
echo "  - De aqui en adelante el proceso es automatico (no debes colocar de nuevo la contraseña)"
echo "  - 6/14) Colocando variables MYSQL Esclavo"
mysql -u $slave_user -p $slave_pass -e "stop slave; reset slave; CHANGE MASTER TO MASTER_HOST='$master_host', MASTER_USER='$slave_user', MASTER_PASSWORD='$slave_pass', MASTER_PORT=3306, MASTER_LOG_FILE='$LOG_FILE', MASTER_LOG_POS=$LOG_POS;"

#bucle para leer y borrar las bases de datos según el prefix
echo "  - 7/14) Borrando las bases de datos" 
for db_name in $(mysql -u $slave_user -p $slave_pass -e "show databases like '$prefix%'" -ss)
do
    mysql -u $slave_user -p $slave_pass -e "drop database ${db_name}";
done
echo "  - Bases de datos borradas"

#Crear bases de datos
echo "  - 8/14) Creando bases de datos nuevas en esclavo"
mysql -u $slave_user -p $slave_pass -e "CREATE DATABASE $database1; CREATE DATABASE $database2;"
echo "  - Bases de datos nuevas creadas"

#Convertir de .gz a .sql
echo "  - 9/14) bases de datos en $dirsave local"
gunzip $dirsave/dbs_$date.sql.gz
echo "  - Bases de datos descomprimidas"

#Restaurar bases de datos
echo "  - 10/14) Restaurando bases de datos restauradas"
mysql -u $slave_user -p $slave_pass < $dirsave/dbs_$date.sql
echo "  - Bases de datos restauradas"

#Eliminar db local .sql
echo "  - 11/14) Borrando base de datos local"
rm -rf $dirsave/dbs_$date.sql
echo "  - Base de datos local borrada"

#iniciar esclavo
echo "  - 12/14) Iniciar MySql Esclavo"
mysql -u $slave_user -p $slave_pass -e "START SLAVE;"
echo "  - Bases de datos iniciada"

#Mostrar estado del slave
echo "  - 13/14) Mostrar estado del esclavo? [Y/n]"
read SHOW_STATUS
if [ "$SHOW_STATUS" = "y" ] || [ "$SHOW_STATUS" = "" ]; then
    mysql -u $slave_user -p$slave_pass -e "show slave status\G;"
fi
echo "  - 14/14) Esperando el resultado del estado de la replica .."

#Espera 3 segundos y continua.. 
sleep 3

#Mostrar estado final de la replica si funciona o no
SLAVE_OK=$(ssh -o StrictHostKeyChecking=no $master_user@$master_host mysql "-u$slave_user" "-p$slave_pass" -e "SHOW SLAVE STATUS\G;" | grep 'Waiting for master')
if [ -z "$SLAVE_OK" ]; then
        echo "  - Error ! Estado de E/S del esclavo incorrecto."
else
        echo "  - Estado de E/S del esclavo correcto (OK)"
fi
echo"

#=======================================#
#       FIN DE EJECUCION DEL SCRIPT     #
#    Disfrute de su replica :) ¡Adios!  #
#=======================================#