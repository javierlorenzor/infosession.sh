#!/bin/bash

# Estilos de texto
TEXT_BOLD=$(tput bold)
TEXT_ULINE=$(tput sgr 0 1)
TEXT_GREEN=$(tput setaf 2)
TEXT_RESET=$(tput sgr0)
TEXT_RED=$(tput setaf 1)
TEXT_BLUE=$(tput setaf 4)
TEXT_MAGENTA=$(tput setaf 5)

# Variables de mensajes y cabecera 
ERROR="${TEXT_RED}${TEXT_BOLD}Deberás consultar -h o --help para más información.${TEXT_RESET}"
HELP="${TEXT_GREEN}${TEXT_BOLD}Este programa muestra una tabla con información sobre los procesos.${TEXT_RESET}"
PROGNAME=$(basename $0)
CABECERA="${TEXT_GREEN}${TEXT_BOLD}SID  PGID    PID      USER    TTY   %MEM  CMD${TEXT_RESET}"

# Tabla basica 
tabla_b=$(ps -eo sid,pgid,pid,user,tty,%mem,cmd --no-headers --sort=user | awk '{print $1, $2, $3, $4, $5, $6, $7, $8}') 
if [[ $? -ne 0 ]]; then
    salida_error "Error al ejecutar el comando ps."
fi


# Función para manejar errores
salida_error() 
{
    echo "${PROGNAME}: en la línea $LINENO" 1>&2
    echo "$1"
    echo $ERROR
    exit 1
}

# Función de ayuda
ayuda() 
{
    echo 
    echo $HELP
    echo
    echo "${TEXT_BOLD}Uso: ./infosesion.sh [opciones]${TEXT_RESET}"
    echo
    echo "${TEXT_MAGENTA}${TEXT_BOLD}Las opciones son:${TEXT_RESET}"
    echo "-z: La tabla muestra también los procesos cuyo identificador sea 0."
    echo "-u [usuario]: Muestra los procesos cuyo usuario efectivo sea el especificado."
    echo "-d [ruta]: Muestra solo los procesos que tengan archivos abiertos en el directorio especificado."
    echo "-h|--help: Muestra esta ayuda."
    echo 
}


# Función para mostrar procesos sin PID 0 y del usuario bash
no_option() {
    echo -e "$CABECERA"
    echo "$tabla_b" | awk '$3 != "0" && $7 ~/bash/' | column -t
    if [[ $? -ne 0 ]]; then
        salida_error "Error al mostrar los procesos sin PID 0 y del usuario bash."
    fi
}

# Función para mostrar procesos con PID 0 (-z)
pid0() {
    echo -e "$CABECERA"
    echo "$tabla_b" | column -t
    if [[ $? -ne 0 ]]; then
        salida_error "Error al mostrar todos los procesos, incluyendo PID 0."
    fi
    exit 0
}

# Función para procesar la opción -u (usuario)
filtrar_por_usuario() {
    echo -e "$CABECERA"
    echo "$tabla_b" | awk -v usuario="$1" '$4 == usuario' | column -t
    if [[ $? -ne 0 ]]; then
        salida_error "Error al filtrar por usuario."
    fi
}

# Función para procesar la opción -d (directorio)
filtrar_por_directorio() {
    echo -e "$CABECERA"
    lsof_output=$(lsof +d "$1" 2>/dev/null | awk '{print $2}') || salida_error "Fallo al ejecutar lsof en el directorio $1."
    if [[ $? -ne 0 ]]; then
        salida_error "Error al obtener procesos con archivos abiertos en $1."
    fi
    filtrado=$(echo "$tabla_b" | awk 'NR==FNR {pids[$1]; next} $3 in pids' <(echo "$lsof_output"))
    if [[ $? -ne 0 ]]; then
        salida_error "Error al filtrar procesos con archivos abiertos en $1."
    fi
    [[ -z "$filtrado" ]] && salida_error "No se encontraron procesos con archivos abiertos en $1."
    echo "$filtrado" | column -t
    exit 0
}

# Variables para las opciones
usuario=""
directorio=""

# Si no hay opciones, se usa no_option
if [[ $# -eq 0 ]]; then
    no_option
    if [[ $? -ne 0 ]]; then
        salida_error "Error en la función no_option."
    fi
else
    # Procesar opciones
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -z) # Mostrar todos los procesos, incluyendo PID 0
                pid0
                shift
                ;;
            -u) # Filtro por usuario
                if [[ -n $2 ]]; then
                    usuario="$2"
                    filtrar_por_usuario "$usuario"
                    shift 2
                else
                    salida_error "Debes proporcionar un nombre de usuario con la opción -u."
                fi
                ;;
            -d) # Filtro por directorio
                if [[ -n $2 ]]; then
                    directorio="$2"
                    filtrar_por_directorio "$directorio"
                    shift 2
                else
                    salida_error "Debes proporcionar una ruta de directorio con la opción -d."
                fi
                ;;
            -h|--help) # Mostrar la ayuda
                ayuda
                exit 0
                ;;
            *) # Opción no válida
                salida_error "Opción no reconocida: $1."
                ;;
        esac
    done
fi



