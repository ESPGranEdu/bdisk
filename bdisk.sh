#!/bin/bash
# Limpiamos el contenido de la terminal actual para mayor visualizacion

clear

# Cargar el contenido de la carpeta modules

if [ ! -d modules  ]; then
    echo -e "\e[1;91mNo se encuentra la carpeta \"modules\"\e[0m"
    exit 1
elif [ ! -f modules/functions.sh ]; then
    echo -e "\e[1;91mError al cargar \"functions.sh\"\e[0m"
    exit 1
elif [ ! -f modules/check_dependencies.sh ]; then
    echo -e "\e[1;91mError al cargar \"check_dependencies.sh\"\e[0m"
    exit 1
else
    for modules in $(ls modules/);
    do
        source modules/$modules
    done
fi

# Comprobamos si el usuario tiene permisos de super usuarios

if [ "$(id -u)" != 0 ]; then
    echo "Debes de tener permisos de administrador para ejecutar este script"
    exit 1
fi 

# Primero le pedimos al usuario que introduzca el disco
# al cual se le va a hacer la copia de seguridad

disco=$(du -a /dev | grep -E "sd[a-z]\b" | awk '{print $2}' | fzf --reverse \
--prompt="Selecciona el disco al que quieres hacerle un backup --> ")

# Miramos si el disco que ha proporcionado el usuario existe en el equipo

comprobar $disco

# Variables y arrays para sacar correctamente la informacion del disco

aviso_montura=0
tipo_tabla=$(fdisk -l $disco | grep -oP "dos|gpt")
disco_f=$(echo $disco | cut -f3 -d/)
num_part=$(lsblk -lf $disco | grep -E "$disco_f([1-9]|[1-8][0-9]|9[0-9]|1[01][0-9]|12[0-8])" | wc -l)
mapfile -t part < <(lsblk -lf $disco | grep -E "$disco_f([1-9]|[1-8][0-9]|9[0-9]|1[01][0-9]|12[0-8])" | awk '{print $1}' )
mapfile -t tipo_part < <(lsblk -lf $disco | grep -E "$disco_f([1-9]|[1-8][0-9]|9[0-9]|1[01][0-9]|12[0-8])" | awk '{print $2}')

# Comprobamos si ya existe una copia de la tabla de particiones
# para evitar operaciones de escritura y lectura si a lo que
# se le va a hacer una copia de seguridad es un disco SSD

 crear_backup $disco $disco_f $tipo_tabla

# Antes de realizar el backup de las particiones, le mostramos al usuario las particiones
# a las que se le va a hacer una copia de seguridad

echo -e "\e[1;92mSe van a realizar las siguientes copias: \e[0m"
echo ""

# Le mostramos las particiones a las que se le va a hacer una copia de seguridad
# y el tipo de la particion, si no se conoce el formato, se muestra "desconocido"

for disk in $(seq 0 $(($num_part-1)));
do
    if [ "${tipo_part[$disk]}" == "" ]; then
        tipo_part[$disk]="desconocido"
    fi
    
    # Aqui se comprueba si la particion esta montada o no, debido a que si esta montada, partclone no podra 
    # realizar correctamente la copia de seguridad del disco duro por este motivo

    if grep -q ${part[$disk]} /proc/mounts; then
    	echo -e "\e[1;93m/dev/${part[$disk]}\e[0m \e[1mde tipo\e[0m \e[1;96m${tipo_part[$disk]}\e[0m \e[1;91mMONTADO\e[0m"
        aviso_montura=1
	else
    	echo -e "\e[1;93m/dev/${part[$disk]}\e[0m \e[1mde tipo\e[0m \e[1;96m${tipo_part[$disk]}\e[0m"
    fi

done

# Despues de mostrarle las particiones al usuario, le preguntamos al usuario si
# desea realizar la copia de estas particiones, pero si se ha detectado alguna
# particion montada, se le pregunta al usuario si desea desmontarla para hacer 
# copia, si no, se hacen las copias pero no de las particiones que estan montadas

echo ""

if [ $aviso_montura != 0 ]; then
    echo -en "\e[1;95mSe han detectado particiones montadas, si se desea realizar la copia de seguridad
se van a desmontar las particiones. ¿desea proseguir?[S/n]: \e[0m"; read user
    if [[ "$user" == "S" || "$user" == "s" || "$user" == "" ]]; then
        # Desmontamos las particiones que esten montadas

        for disk in $(seq 0 $((num_part-1)));
        do
            umount "/dev/${part[$disk]}"
        done
        
        # Hacemos la copia de seguridad

        for X in $(seq 0 $((num_part-1)));
        do
            if [ "${tipo_part[$X]}" == "desconocido" ]; then
                partclone.dd -Ncs /dev/${part[$X]} | gzip -c > ${part[$X]}.pc.gz
            else
                partclone.${tipo_part[$X]} -Ncs /dev/${part[$X]} | gzip -c > ${part[$X]}.pc.gz
            fi
        done
    
        exit 0
    else  
        echo -e "\e[1;91mAbortando...\e[0m"
        exit 1        
    fi
fi

echo -en "\e[1m¿Desea realizar la copia de las siguientes particiones? [S/n]: \e[0m"; read user

if [[ "$user" == "S" || "$user" == "s" || "$user" == "" ]]; then
    # Backup de las particiones

    for X in $(seq 0 $((num_part-1)));
    do
        if [ "${tipo_part[$X]}" == "desconocido" ]; then
            partclone.dd -Ncs /dev/${part[$X]} | gzip -c > ${part[$X]}.pc.gz
        else
            partclone.${tipo_part[$X]} -Ncs /dev/${part[$X]} | gzip -c > ${part[$X]}.pc.gz
        fi
    done
    
    exit 0

elif [[ "$user" == "N" || "$user" == "n" ]]; then

    echo -e "\e[1;91mAbortando...\e[0m"
    exit 1
fi