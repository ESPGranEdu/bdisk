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

disco_f=$(echo $disco | cut -f3 -d/)
num_part=$(lsblk -f $disco | tr -d "├─" | egrep "$disco_f[1-128]" | wc -l)
mapfile -t part < <(lsblk -f $disco | tr -d "├─" | egrep "$disco_f[1-128]" | awk '{print $1}' )
mapfile -t tipo_part < <(lsblk -f $disco | tr -d "├─" | egrep "$disco_f[1-128]" | awk '{print $2}')

# Funciones para detectar si el disco proporcinado existe
# Y crear la tabla de particiones del disco escogido

function buscar_disco(){
    lsblk $1 &> /dev/null

    if [ $(echo $?) != 0 ]; then
        echo "El disco no existe, abortando..."
        exit 1
    else
        echo "El disco $1 esta en el sistema"
    fi
}

function backup_tabla_particiones(){
    gdisk $1 << EOF
    b
    Tabla_particiones.img
    w
EOF

}

# Miramos si el disco que ha proporcionado el usuario existe en el equipo

buscar_disco $disco

# Si se encuentra el disco, se realizara la copia de seguridad
# de la tabla de particiones y de las particiones del disco

# Backup de la tabla de particiones

backup_tabla_particiones $disco &> /dev/null

# Backup de las particiones

for X in $(seq 0 $(($num_part-1)));
do 
    echo "partclone.${tipo_part[$X]} -Ncs /dev/${part[$X]} | gzip -c > ${part[$X]}.pc.gz"
done

exit 0
