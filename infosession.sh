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
CABECERA2="${TEXT_BLUE}${TEXT_BOLD}SID    GID     %MEM    PID     UID  TTY CMD ${TEXT_RESET}" 

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
    echo "-t: Muestra solo los procesos que tengan una terminal controladora asignada."
    echo "-e: Muestra información adicional sobre la sesión."
    echo "-sm: Ordena la tabla por el porcentaje de memoria consumida."
    echo "-sg: Ordena la tabla por el número de grupos de procesos."
    echo "-r: Invierte el orden de la tabla."
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
OPCION_T=false
OPCION_E=false
OPCION_SM=false
OPCION_SG=false
OPCION_R=false


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
            -t) #filtro por terminal 
                OPCION_T=true
                shift
                ;;
            -e) #Infromacion de sesion 
                OPCION_E=true
                shift
                ;;
            -sm) #Ordenar por memoria
                OPCION_SM=true
                shift
                ;;
            -sg) #Ordenar por grupos
                OPCION_SG=true
                shift
                ;;
            -r) #Invertir el orden
                OPCION_R=true
                shift
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

if [[ "$OPCION_T" == true ]]; then
    echo -e "$CABECERA"
    echo "$tabla_b" | awk '$5 != "?"' | column -t
fi

if [[ "$OPCION_E" == true ]]; then
    
    # 1. Identificador de sesión (SID)
    SID=$(echo "$tabla_b" | head -n 1 )
    
    # 2. Total de grupos de procesos diferentes de esa sesión
    gid_dif=$(echo "$tabla_b" | awk -v sid="$SID" '$1 == sid {print $2}' | sort -u | wc -l)
    
    # 3. Total del porcentaje de memoria consumida por todos los procesos de la sesión
    percent_t=$(echo "$tabla_b" | awk -v sid="$SID" '$1 == sid {sum+=$6} END {print sum "%"}')
   
    # 4. Identificador de proceso del proceso líder de la sesión
    pid=$(echo "$tabla_b" | awk -v sid="$SID" '$1 == sid && $1 == $3 {print $3}' | head -n 1)

    # 5. Usuario efectivo del proceso líder de la sesión
    user=$(echo "$tabla_b" | awk -v sid="$SID" '$1 == sid && $1 == $3 {print $4}' | head -n 1)

    # 6. Terminal controladora de la sesión (si la tuviera)
    tty=$(echo "$tabla_b" | awk -v sid="$SID" '$1 == sid && $1 == $3 {print $5}' | head -n 1)

    # 7. Comando del proceso líder de la sesión
    cmd=$(echo "$tabla_b" | awk -v sid="$SID" '$1 == sid && $1 == $3 {print $7}' | head -n 1)

    tabla_s=$(echo "$SID $gid_dif $percent_t $pid $user $tty $cmd")

    echo -e "$CABECERA2"
    echo "$tabla_s" | column -t
    

    
else 
    echo -e "$CABECERA"
    echo "$tabla_b" | column -t
    
fi

# Ordenar por memoria (opción -sm)
if [[ "$OPCION_SM" == true ]]; then
    echo -e "$CABECERA"
    echo "$tabla_b" | column -t | sort -k6 -g
fi

# Ordenar por número de grupos de procesos (opción -sg)
if [[ "$OPCION_SG" == true ]]; then
    echo -e "$CABECERA"
    echo "$tabla_b" | column -t | sort -k2 -n 
fi

# Invertir el orden (opción -r)
if [[ "$OPCION_R" == true ]]; then
    echo -e "$CABECERA"
    echo "$tabla_b" | column -t | sort1 -r
fi


exit 0