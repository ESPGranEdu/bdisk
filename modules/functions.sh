function comprobar() {
    lsblk $1 &> /dev/null
    
    if [ $(echo $?) != 0 ]; then
        echo -e "\e[1;91mEl disco no existe, abortando...\e[0m"
        exit 1
    fi
    
}
