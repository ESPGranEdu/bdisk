#!/bin/bash
# Cargar el contenido de la carpet modules

if [ ! -d modules  ]; then
    echo -e "\e[1;91mNo se encuentra la carpeta \"modules\"\e[0m"
    exit 1
elif [ ! -f modules/functions.sh ]; then
    echo -e "\e[1;91mError al cargar \"functions.sh\"\e[0m"
    exit 1
else
    source modules/*
fi

# Comprobamos si el usuario tiene permisos de super usuarios

if [ $(id -u) != 0 ]; then
    echo "Debes de tener permisos de administrador para ejecutar este script"
    exit 1
fi 

# Primero le pedimos al usuario que introduzca el disco
# al cual se le va a hacer la copia de segutidad

echo -en "\e[1mIntroduce el disco al que se le quiere hacer una copia --> \e[0m"; read -e disco

# Miramos si el disco que ha proporcionado el usuario existe en el equipo

comprobar $disco

# Variables y arrays para sacar correctamente la informacion del disco

tipo_tabla=$(fdisk -l $disco | grep -oP "dos|gpt")
disco_f=$(echo $disco | cut -f3 -d/)
num_part=$(lsblk -lf $disco | egrep "$disco_f([1-9]|[1-8][0-9]|9[0-9]|1[01][0-9]|12[0-8])" | wc -l)
mapfile -t part < <(lsblk -lf $disco | egrep "$disco_f([1-9]|[1-8][0-9]|9[0-9]|1[01][0-9]|12[0-8])" | awk '{print $1}' )
mapfile -t tipo_part < <(lsblk -lf $disco | egrep "$disco_f([1-9]|[1-8][0-9]|9[0-9]|1[01][0-9]|12[0-8])" | awk '{print $2}')

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

    echo -e "\e[1;93m/dev/${part[$disk]}\e[0m \e[1mde tipo\e[0m \e[1;96m${tipo_part[$disk]}\e[0m"
done

# Despues de mostrarle las particiones al usuario, le preguntamos al usuario si
# desea realizar la copia de estas particiones

echo ""
echo -en "\e[1mDesea realizar la copia de las siguientes particiones[S/n]: \e[0m"; read user

if [[ "$user" == "S" || "$user" == "s" || "$user" == "" ]]; then
    # Backup de las particiones
    
    for X in $(seq 0 $(($num_part-1)));
    do
        partclone.${tipo_part[$X]} -Ncs /dev/${part[$X]} | gzip -c > ${part[$X]}.pc.gz
    done
    
    exit 0
elif [[ "$user" == "N" || "$user" == "n" ]]; then
    echo -e "\e[1;91mAbortando...\e[0m"
    exit 1
fi
