# Aqui iran las funciones que se cargaran al script para añadir modularidad


function comprobar() {
    lsblk $1 &> /dev/null
    
    if [ $(echo $?) != 0 ]; then
        echo -e "\e[1;91mEl disco no existe, abortando...\e[0m"
        exit 1
    fi
    
}

function crear_backup(){
    if [ -f "Tabla_particiones_$2.img" ]; then
        echo -e "\e[1;33mYa existe la tabla de particiones del disco $1\e[0m"
    else
        if [ "$3" == "gpt" ]; then
            dd if=$1 of="Tabla_particiones_$2.img" bs=512 count=34 &> /dev/null
        elif [ "$3" == "dos" ]; then
            dd if=$1 of="Tabla_particiones_$2.img" bs=512 count=1 &> /dev/null
        fi
    	echo -e "\e[1;92mCreada copia de la tabla de particiones del disco\e[0m \e[1;93m$1\e[0m"
    fi
}

