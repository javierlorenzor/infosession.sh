#Estilos 
TEXT_BOLD=$(tput bold)
TEXT_ULINE=$(tput sgr 0 1)
TEXT_GREEN=$(tput setaf 2)
TEXT_RESET=$(tput sgr0)
TEXT_RED=$(tput setaf 1)
TEXT_BLUE=$(tput setaf 4)
TEXT_MAGENTA=$(tput setaf 5)

#Variables 
ERROR="${TEXT_RED}${TEXT_BOLD}Deberas de consutar -h o --help para mas infromacion${TEXT_RESET}${TEXT_RESET}" #mensaje salida error
HELP="${TEXT_GREEN}${TEXT_BOLD}Este programa muestra una tabla con información sobre los procesos ${TEXT_RESET}${TEXT_RESET}" # mensaje del help 
PROGNAME=$(basename $0)
CABECERA="${TEXT_GREEN}${TEXT_BOLD}SID  PGID    PID      USER    TTY   %MEM  CMD ${TEXT_RESET}${TEXT_RESET}" #cabecera de la tabla

#Tabla Base 
tabla_b="$(ps -eo sid,pgid,pid,user,tty,%mem,cmd --no-headers --sort=user | awk '{print $1," ",$2," ",$3," ",$4," ",$5," ",$6," ",$7," ",$8}')"  #tabla de procesos
 

#funciones
salida_error() #funcion salida error // manejo de errores
{
    echo "${PROGNAME}:en la línea $LINENO" 1>&2
    echo $ERROR
    exit 1
}

ayuda() #Funcion que muestra funcionamiento del sysinfo
{
    echo 
    echo $HELP
    echo
    echo "${TEXT_BOLD}Uso: ./infosession.sh [opciones] ${TEXT_RESET} "
    echo
    echo "${TEXT_MAGENTA}${TEXT_BOLD}Las opciones son:${TEXT_RESET}${TEXT_RESET}" 
    echo "-z: la tabla muestra los procesos cuyo identificador sea 0"
    echo "-u [usuario]: se muestran los procesos cuyo usuario efectivo sea el usuario especificado"
    echo "-d [ruta]: se muestran solo los procesos que tengan abiertos archivos en el directorio especificado"
    echo "-h|--help: opcion de opcion de ayuda "
    echo 
}

no_option() #mostar tabla con usuario bash y sin procesos con identificador 0 
{
    echo -e "$CABECERA"
    echo "$TABLA" | awk ' $3 != "0" && $4 ~ /bash/* ' | column -t 
    exit 0
} 


pid0() # mostrar la tabla con los procesos con identificador 0 opción -z
{
    echo -e "$CABECERA"
    echo "$TABLA" | column -t 
    exit 0
}


opt=0
usuario=""
directorio=""

if [[ $# -eq 0 ]]; then
    no_option
    if [[ $? -ne 0 ]]; then
        salida_error "Ha ocurrido un error inesperado."
    fi
    exit 0
else
    # Procesar opciones
    while [[ $# -gt 0 ]]; do
        key="$1"
        case $key in
            -z) # Opción Z
                pid0 
                if [[ $?-ne 0 ]]; then
                    salida_error "Ha ocurrido un error inesperado."
                fi
                 exit 0
                shift # Avanzar al siguiente argumento
                ;;
            -u) # Opción -u
                if [[ -n $2 ]]; then
                    usuario="$2"
                    shift 2 # Avanzamos dos argumentos
                else
                    salida_error "Tienes que proporcionar un nombre de usuario junto con la opción -u."
                fi
                ;;
            -d) # Opción -d
                if [[ -n $2 ]]; then
                    directory="$2"
                    shift 2 # Avanzamos dos argumentos
                else
                    salida_error "Debes proporcionar una ruta a un directoio junto con la opción -d."
                fi
                ;;
            -h|--help) # Opción de ayuda
                ayuda
                exit 0
                ;;
            *) # Cualquier otra opción no válida
                salida_error "Debes proporcionar una opción válida: $1"
                exit 1
                ;;
        esac
        shift # Avanzar al siguiente argumento
    done
fi










