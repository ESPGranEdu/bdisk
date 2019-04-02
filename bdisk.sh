#!/bin/bash
# Comprobamos si el usuario tiene permisos de super usuarios

if [ $(id -u) != 0 ]; then
    echo "Debes de tener permisos de administrador para ejecutar este script"
    exit 1
fi

# Primero le pedimos al usuario que introduzca el disco
# al cual se le va a hacer la copia de segutidad

echo -n "Introduce el disco al que se le quiere hacer una copia --> "; read disco

# Variables y arrays para sacar correctamente la informacion del disco

tipo_tabla=$(fdisk -l $disco | grep -oP "dos|gpt")
disco_f=$(echo $disco | cut -f3 -d/)
num_part=$(lsblk -lf $disco | egrep "$disco_f([1-9]|[1-8][0-9]|9[0-9]|1[01][0-9]|12[0-8])" | wc -l)
mapfile -t part < <(lsblk -lf $disco | egrep "$disco_f([1-9]|[1-8][0-9]|9[0-9]|1[01][0-9]|12[0-8])" | awk '{print $1}' )
mapfile -t tipo_part < <(lsblk -lf $disco | egrep "$disco_f([1-9]|[1-8][0-9]|9[0-9]|1[01][0-9]|12[0-8])" | awk '{print $2}')

# Miramos si el disco que ha proporcionado el usuario existe en el equipo

lsblk $1 &> /dev/null

if [ $(echo $?) != 0 ]; then
    echo "El disco no existe, abortando..."
    exit 1
fi

# Si se encuentra el disco, se realizara la copia de seguridad
# de la tabla de particiones y de las particiones del disco

# Backup de la tabla de particiones

echo "Creando tabla de particiones..."

if [[ "$tabla_particiones" == "gpt" ]]; then
    dd if=$disco of=Tabla$disco_f.img bs=512 count=34
elif [[ "$tabla_particiones" == "mbr" ]]; then
    dd if=$disco of=Tabla$disco_f.img bs=512 count=1
fi

echo "Creada copia de la tabla de particiones del disco $disco"

# Antes de realizar el backup de las particiones, le mostramos al usuario las particiones
# a las que se le va a hacer una copia de seguridad

echo "Se van a realizar las siguientes copias: "
echo ""
for disk in $(seq 0 $(($num_part-1)));
do  
    echo "/dev/${part[$disk]} de tipo ${tipo_part[$disk]}"
done
# Despues de mostrarle las particiones al usuario, le preguntamos al usuario si
# desea realizar la copia de estas particiones

echo ""
echo -n "Desea realizar la copia de las siguientes particiones[S/n]: "; read user

if [[ "$user" == "S" || "$user" == "s" || "$user" == "" ]]; then
    # Backup de las particiones

    for X in $(seq 0 $(($num_part-1)));
    do 
        partclone.${tipo_part[$X]} -Ncs /dev/${part[$X]} | gzip -c > ${part[$X]}.pc.gz
    done

    exit 0
elif [[ "$user" == "N" || "$user" == "n"]]; then
    echo "Abortando..."
    exit 1
fi