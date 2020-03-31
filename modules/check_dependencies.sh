#!/usr/bin/env bash

# Este script comprueba si las dependencias necesarias estan instaladas,
# en el caso de que no lo esten se instalaran. Depende de las distribución
# se ejecutara la funcion respectivamente

(($(id -u) != 0)) && { echo "Debes tener permisos de administrador" && exit 1; }

function suseCheck() {
    local _packages="$*"
    local _package

    for _package in ${_packages[*]}; do
        if ! rpm -q "$_package" &>/dev/null; then
            echo -e "\e[1;93mFalta la dependencia \"$_package\", en breves se instalara...\e[0m"
            zypper install -y "$_package" &>/dev/null
        fi
    done

}

function fedoCheck() {
    local _packages="$*"
    local _package

    for _package in ${_packages[*]}; do
        if ! rpm -q "$_package" &>/dev/null; then
            echo -e "\e[1;93mFalta la dependencia \"$_package\", en breves se instalara...\e[0m"
            dnf install -y "$_package" &>/dev/null
        fi
    done

}

function archCheck() {
    local _packages="$*"
    local _package

    for _package in ${_packages[*]}; do
        if ! pacman -Qq "$_package" &>/dev/null; then
            echo -e "\e[1;93mFalta la dependencia \"$_package\", en breves se instalara...\e[0m"
            pacman -Sy "$_package" --noconfirm &>/dev/null
        fi
    done
}

function debianCheck() {
    local _packages="$*"
    local _package

    for _package in ${_packages[*]}; do
        if ! dpkg -l | grep -q "$_package" &>/dev/null; then
            echo -e "\e[1;93mFalta la dependencia \"$_package\", en breves se instalara...\e[0m"
            apt-get install -y "$_package" &>/dev/null
        fi
    done

}

# Dependencies
deps=("fzf" "partclone" "zstd")

# Check Distro
if command -v pacman &>/dev/null; then
    archCheck "${deps[@]}"
elif command -v zypper &>/dev/null; then
    suseCheck "${deps[@]}"
elif command -v dnf &>/dev/null; then
    fedoCheck "${deps[@]}"
else
    debianCheck "${deps[@]}"
fi
