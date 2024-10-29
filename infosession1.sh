#!/bin/bash

# Estilos de texto
TEXT_BOLD=$(tput bold)
TEXT_ULINE=$(tput sgr 0 1)
TEXT_GREEN=$(tput setaf 2)
TEXT_RESET=$(tput sgr0)
TEXT_RED=$(tput setaf 1)
TEXT_BLUE=$(tput setaf 4)
TEXT_YELLOW=$(tput setaf 3)
TEXT_MAGENTA=$(tput setaf 5)

# Variables de mensajes y cabecera 
ERROR="${TEXT_YELLOW}${TEXT_BOLD}Deberás consultar -h o --help para más información.${TEXT_RESET}"
HELP="${TEXT_GREEN}${TEXT_BOLD}Este programa muestra una tabla con información sobre los procesos.${TEXT_RESET}"
PROGNAME=$(basename $0)
CABECERA="${TEXT_GREEN}${TEXT_BOLD}SID  PGID    PID    USER    TTY   %MEM  CMD${TEXT_RESET}"
#CABECERA2="${TEXT_BLUE}${TEXT_BOLD}SID    GID     %MEM    PID     UID  TTY CMD ${TEXT_RESET}" 

# Tabla basica 
tabla_b=$(ps -eo sid,pgid,pid,user,tty,%mem,cmd --no-headers --sort=user | awk '{print $1, $2, $3, $4, $5, $6, $7, $8}') 
if [[ $? -ne 0 ]]; then
    salida_error "Error al ejecutar el comando ps."
fi

# Función para manejar errores
salida_error() 
{
    echo "${PROGNAME}: en la línea $LINENO" 1>&2
    echo 
    echo "${TEXT_RED}${TEXT_BOLD}$1 ${TEXT_RESET}"
    echo 
    echo $ERROR
    echo 
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
    echo "-z:               La tabla muestra también los procesos cuyo identificador sea 0."
    echo "-u [usuario]:     Muestra los procesos cuyo usuario efectivo sea el especificado."
    echo "-d [ruta]:        Muestra solo los procesos que tengan archivos abiertos en el directorio especificado."
    echo "-h|--help:        Muestra esta ayuda."
    echo 
}

no_option() {
    echo -e "$CABECERA"
    # comprobamos que la PID (col1) no sea 0 y que el usuario (col4) sea bash
    echo "$tabla_b" | awk '$1 != "0" && $4 = "bash"' | column -t

    if [[ $? -ne 0 ]]; then
        salida_error "Se ha producido un error al mostrar los procesos del usuario Bash con PID distinto de 0" 
    fi
}

# Variables para las opciones
OPCION_Z=false
OPCION_D=""
OPCION_U=""



# Si no hay opciones, se usa no_option
if [[ $# -eq 0 ]]; then
    no_option  # llamamos a la función no_option
    # Comprobamos que no haya errores con la función llamada 
    if [[ $? -ne 0 ]]; then
        salida_error "Se ha producido un error en la función no_option."
    fi
    exit 0  # salimos del script porque no hay opciones
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
                OPCION_U="$1"
                #comprobamos que la opción no este vacía o que se haya introducido despues otra opcion sin poner un usuario
                if [[ -z "$1" || "$1" == "-"* ]]; then
                    salida_error "Se debe especificar un usuario después de la opción -u."
                fi
                shift
                ;;
            -d) # Filtro por directorio
                OPCION_D="$2"
                if [[ -z "$OPCION_D" || "$OPCION_D" == "-"* ]]; then
                    salida_error "Se debe inttroducir una ruta a un directprio después de la opción -d."
                fi
                shift 2
                ;;
            -h|--help) # Mostrar la ayuda
                ayuda
                if [[ $? -ne 0 ]]; then
                    salida_error "Se ha producido un error al mostrar la ayuda."
                fi
                exit 0
                ;;
            *) # Opción no válida
                salida_error "Se ha introducido una opcion que no se reconoce: $1."
                ;;
        esac
    done
fi

# Una vez recogidos los filtros que se quiere hacer a la tabla los aplicamos 

# Mostrar los procesos de un directorio en especifico opción -d y un usuario especifico opción -u (o al reves -u y -d) 
if [[ -n "$OPCION_U" && -n "$OPCION_D" ]]; then
    # Comprobar si el directorio existe
    if [[ ! -d "$OPCION_D" ]]; then
        salida_error "Se ha introducido un directorio especificado no existe."
    fi

    # Sacar los PID de los procesos que tienen archivos abiertos en el directorio especificado 
    pid_lsof_local=$(lsof +d "$OPCION_D" | awk '{print $2}' | tail -n +2 | uniq | tr '\n' ' ')

    if [[ -z "$pid_lsof_local" ]]; then
        salida_error "Se ha introducido un directorio donde no hay procesos con archivos abiertos"
    fi

    echo -e "$CABECERA"
    # Filtrar los procesos de un usuario específico que también estén en el directorio especificado
    for i in $pid_lsof_local; do
        tabla_local=$(echo "$tabla_b" | awk '$3 == '$i' && $4 == '$OPCION_U'')
        echo "$tabla_local"
    done | column -t
    exit 0
fi


# Filtrar por usuario (OPCION -u)
if [[ -n "$OPCION_U" ]]; then  # comprobamos que la variable no esté vacía
    tabla_u=$(echo "$tabla_b" | grep "$OPCION_U" ) 
    #Comprobamos que la tabla no esté vacía
    if [[ -z "$tabla_u" ]]; then
        salida_error "No hay procesos con el usuario especificado."
    else 
        echo -e "$CABECERA"
        echo "$tabla_u" | column -t
        exit 0
    fi 
fi

# Filtrar por directorio (OPCION -d)
if [[ -n "$OPCION_D" ]]; then
    # Comprobar si el directorio existe
    if [[ ! -d "$OPCION_D" ]]; then
        salida_error "El directorio especificado no existe."
    fi 

    #sacamos los pid de los procesos que tienen archivos abiertos en el directorio especificado (tr para que esten todos en una línea )
    pid_lsof_local=$(lsof +d $OPCION_D | awk '{print $2}' | tail -n +2 | uniq | tr '\n' ' ')

    if [[ -z "$pid_lsof_local" ]]; then
        error_exit "No hay procesos con archivos abiertos en el directorio que se ha especificado"
    fi
    
    # Filtrar los procesos que tengan archivos abiertos en el directorio especificado
    echo -e "$CABECERA"

    for pid in $pid_lsof_local; do
        tabla_local=$(echo "$tabla_b" | awk -v pid="$pid" '$3 == pid')
        echo "$tabla_local"
    done | column -t

    exit 0 

fi

# Mostrar todos los procesos, incluyendo PID 0 (OPCION -z)
if [[ "$OPCION_Z" == true ]]; then
    echo -e "$CABECERA"
    echo "$tabla_b" | column -t
    exit 0
fi




exit 0