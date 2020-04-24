#!/usr/bin/env bash

# Limpiamos el contenido de la terminal actual para mayor visualizacion
clear
set -e # Bash estricto
export FZF_DEFAULT_OPTS='--height 50% --reverse --border' # Flags para fzf

# Cargar el contenido de la carpeta modules
for module in modules/*; do
    source "$module"
    clear
done

# Comprobamos si el usuario tiene permisos de super usuarios
(($(id -u) != 0)) && { echo "Debes tener permisos de administrador" && exit 1; }

# Variables y arrays para sacar correctamente la informacion del disco
disk=$(
    fdisk -l | grep -E "\/dev\/(mmcblk[0-9]+|nvme[0-9]n[0-9]+|hd[a-z]|sd[a-z]):" | awk '{print $2,$3,$4}' |
        sed 's/,$//g;s/:/\t/g' | fzf --prompt="Selecciona el disco al que quieres hacerle un backup --> " | awk '{print $1}'
)
mounted=0
partition_table_type=$(fdisk -l "$disk" | grep -oP "dos|gpt")
diskf=$(echo "$disk" | cut -f3 -d/)
part_num=$(lsblk -lf "$disk" | grep -cE "${diskf}p?[0-9]+")
mapfile -t part < <(lsblk -lf "$disk" | grep -E "${diskf}p?[0-9]+" | awk '{print $1}')
mapfile -t tipo_part < <(lsblk -lf "$disk" | grep -E "${diskf}p?[0-9]+" | awk '{print $2}')

# Antes de realizar el backup de las particiones, le mostramos al usuario las particiones
# a las que se le va a hacer una copia de seguridad
echo -e "\e[1;92mSe van a realizar las siguientes copias: \e[0m"
echo

# Le mostramos las particiones a las que se le va a hacer una copia de seguridad
# y el tipo de la particion, si no se conoce el formato, se muestra "desconocido"

for d in $(seq 0 $((part_num - 1))); do
    [ "${tipo_part[$d]}" == "" ] && tipo_part[$d]="desconocido"

    # Aqui se comprueba si la particion esta montada o no, debido a que si esta montada, partclone no podra
    # realizar correctamente la copia de seguridad del disco duro por este motivo
    if grep -q "${part[$d]}" /proc/mounts; then
        echo -e "\e[1;93m/dev/${part[$d]}\e[0m \e[1mde tipo\e[0m \e[1;96m${tipo_part[$d]}\e[0m \e[1;91mMONTADO\e[0m"
        mounted=1
    else
        echo -e "\e[1;93m/dev/${part[$d]}\e[0m \e[1mde tipo\e[0m \e[1;96m${tipo_part[$d]}\e[0m"
    fi

done

# Despues de mostrarle las particiones al usuario, le preguntamos al usuario si
# desea realizar la copia de estas particiones, pero si se ha detectado alguna
# particion montada, se le pregunta al usuario si desea desmontarla para hacer
# copia, si no, se hacen las copias pero no de las particiones que estan montadas
echo

if ((mounted != 0)); then
    echo -ne "\e[1;95mSe han detectado particiones montadas, si se desea realizar la copia de seguridad
se van a desmontar las particiones. ¿desea proseguir?[S/n]: \e[0m"
    read -r user
else
    echo -ne "\e[1m¿Desea realizar la copia de las siguientes particiones? [S/n]: \e[0m"
    read -r user
fi

if [[ "$user" == @([sS]|[yY]|) ]]; then
    read -rep "Introduce el directorio donde quieras guardar la copia: " dir_user
    dir_user="${dir_user}_$(date -I)"

    if [ -d "$dir_user" ]; then
        cd "$dir_user"

        # Copia de seguridad de la table de particiones
        crear_backup "$disk" "$diskf" "$partition_table_type"
    else
        mkdir -p "$dir_user"
        cd "$dir_user"
        crear_backup "$disk" "$diskf" "$partition_table_type" i

        # Desmontamos las particiones que esten montadas
        for disk in $(seq 0 $((part_num - 1))); do
            if grep -q "${part[$disk]}" /proc/mounts; then
                umount "/dev/${part[$disk]}"
            fi
        done
    fi

    # Hacemos la copia de seguridad
    for X in $(seq 0 $((part_num - 1))); do
        if [ "${tipo_part[$X]}" == "desconocido" ]; then
            partclone.dd -Ns "/dev/${part[$X]}" | zstd -15 -z >"${part[$X]}.pc.zst"
        else
            partclone.${tipo_part[$X]} -Ncs "/dev/${part[$X]}" | zstd -15 -z >"${part[$X]}.pc.zst"
        fi
    done
else
    echo -e "\e[1;91mAbortando...\e[0m"
    exit 0
fi
