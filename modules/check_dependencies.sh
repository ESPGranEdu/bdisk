# Este script comprueba si las dependencias necesarias estan instaladas,
# en el caso de que no lo esten se instalaran. Depende de las distribución
# se ejecutara la funcion respectivamente


function suseCheck(){
    local _packages="$@"
    local _package


    for _package in ${_packages[*]};
    do
        hash $_package 2>&1 /dev/null
        if (( $? != 0 )); then
            echo -e "\e[1;93mFalta la dependencia \"$_package\", en breves se instalara...\e[0m"
            zypper install $_package  &> /dev/null
        fi
    done

}

function fedoCheck(){
    local _packages="$@"
    local _package


    for _package in ${_packages[*]};
    do
        hash $_package 2>&1 /dev/null
        if (( $? != 0 )); then
            echo -e "\e[1;93mFalta la dependencia \"$_package\", en breves se instalara...\e[0m"
            dnf install $_package  &> /dev/null
        fi
    done

}


function archCheck(){
    local _packages="$@"
    local _package


    for _package in ${_packages[*]};
    do
        hash $_package 2>&1 /dev/null
        if (( $? != 0 )); then
            echo -e "\e[1;93mFalta la dependencia \"$_package\", en breves se instalara...\e[0m"
            pacman -Sy $_package --noconfirm &> /dev/null
        fi
    done
}

function debianCheck(){
    dependencies=("fzy" "partclone")
    local _packages="${dependencies[$@]}"
    local _package


    for _package in ${_packages[*]};
    do
        hash $_package 2>&1 /dev/null
        if (( $? != 0 )); then
            echo -e "\e[1;93mFalta la dependencia \"$_package\", en breves se instalara...\e[0m"
            apt install -y $_package &> /dev/null
        fi
    done

}

