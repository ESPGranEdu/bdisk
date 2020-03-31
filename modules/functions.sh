#!/usr/bin/env bash
# Aqui iran las funciones que se cargaran al script para añadir modularidad

function crear_backup() {
    disk="$1"
    partition="$2"
    partition_table_type="$3"

    if [ -f "partition_table_$partition.img" ]; then
        return
    else
        if [ "$partition_table_type" == "gpt" ]; then
            dd if="$disk" of="partition_table_$partition.img" bs=512 count=34 &>/dev/null
        elif [ "$partition_table_type" == "dos" ]; then
            dd if="$disk" of="partition_table_$partition.img" bs=512 count=1 &>/dev/null
        fi
        echo -e "\e[1;92mCreada copia de la tabla de particiones del disco\e[0m \e[1;93m$disk\e[0m"
    fi
}
