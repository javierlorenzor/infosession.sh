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
CABECERA="${TEXT_GREEN}${TEXT_BOLD}SID  PGID    PID    USER    TTY   %MEM  CMD${TEXT_RESET}"

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

no_option() {
    echo -e "$CABECERA"
    echo "$tabla_b" | awk '$3 != "0" && $7 ~/bash/' | column -t
    if [[ $? -ne 0 ]]; then
        salida_error "Error al mostrar los procesos sin PID 0 y del usuario bash."
    fi
}

# Variables para las opciones
OPCION_Z=false
OPCION_D=""
OPCION_U=""

# Si no hay opciones, se usa no_option
if [[ $# -eq 0 ]]; then
    no_option
    if [[ $? -ne 0 ]]; then
        salida_error "Error en la función no_option."
    fi
    exit 0
else
    # Procesar opciones
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -z) # Mostrar todos los procesos, incluyendo PID 0
                OPCION_Z=true
                shift
                ;;
            -u) # Filtro por usuario
                shift
                if [[ -z "$1" || "$1" == "-"* ]]; then
                    salida_error "Se requiere un nombre de usuario después de la opción -u."
                fi
                while [[ "$1" && "$1" != "-"* ]]; do
                    OPCION_U+="$1 "
                done
                shift
                ;;
            -d) # Filtro por directorio
                OPCION_D="$2"
                shift 2
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

# Aplicar filtros

# Filtrar por usuario
if [[ -n "$OPCION_U" ]]; then  # comprobamos que la variable no esté vacía
  tabla_b=$(echo "$tabla_b" | grep -E "$(echo $OPCION_U | sed 's/ /|/g')")
fi

# Filtrar por directorio
if [[ -n "$OPCION_D" ]]; then
    # Comprobar si el directorio existe
    if [[ ! -d "$OPCION_D" ]]; then
        salida_error "El directorio especificado no existe."
    fi

    #sacamos los pid de los procesos que tienen archivos abiertos en el directorio especificado 
    pid_lsof_local=$(lsof +d $OPCION_D | awk '{print $2}' | tail -n +2 | uniq | tr '\n' ' ')

    if [[ -z "$pid_lsof_local" ]]; then
        error_exit "No hay procesos con archivos abiertos en el directorio especificado."
    fi
    
    # Filtrar los procesos que tengan archivos abiertos en el directorio especificado
    #tabla_local=$(echo "$tabla_b" | grep -wFf <(echo "$pid_lsof_local"))
    echo -e "$CABECERA"

    for pid in $pid_lsof_local; do
        tabla_local=$(echo "$tabla_b" | awk -v pid="$pid" '$3 == pid')
        echo "$tabla_local"
    done | column -t

fi


if [[ "$OPCION_Z" == true ]]; then
    echo -e "$CABECERA"
    echo "$tabla_b" | column -t
fi
