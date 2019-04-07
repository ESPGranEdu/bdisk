# Comprobar si las depdendencias necesarias estan instaladas en el sistema,
# en caso de que no esten, se instalan
function comprobar(){
    dpkg -l | grep $1 > /dev/null 2>&1 ||{
        echo >&2 -e "\e[1;91mFalta la dependencia: \"$1\"\e[0m"
    }
}
## Debian
