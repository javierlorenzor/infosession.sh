#!/bin/bash

#ESTILOS DE TEXTO
TEXT_BOLD=$(tput bold)
TEXT_ULINE=$(tput sgr 0 1)
TEXT_GREEN=$(tput setaf 2)
TEXT_RESET=$(tput sgr0)
TEXT_RED=$(tput setaf 1)
TEXT_BLUE=$(tput setaf 4)
TEXT_YELLOW=$(tput setaf 3)
TEXT_MAGENTA=$(tput setaf 5)


# MENSAJES DE ERROR Y AYUDA
ERROR="${TEXT_GREEN}${TEXT_BOLD}Deberás consultar -h o --help para más información.${TEXT_RESET}"
HELP="${TEXT_GREEN}${TEXT_BOLD}Este programa muestra una tabla con información sobre los procesos.${TEXT_RESET}"
PROGNAME=$(basename $0)
AYUDA_M="${TEXT_RED}${TEXT_BOLD}La tabla es muy pequeña, por favor, consulta la ayuda para más información.${TEXT_RESET}"

#CABECERAS
CABECERA="$(printf "${TEXT_GREEN}${TEXT_BOLD}%-6s %-6s %-6s %-15s %-8s %-6s %s${TEXT_RESET}\n" "SID" "PGID" "PID" "USER" "TTY" "%MEM" "CMD")"
#CABECERA="${TEXT_GREEN}${TEXT_BOLD}SID  PGID    PID    USER    TTY   %MEM  CMD${TEXT_RESET}"


#TABLA BAASICA (comando ps basico (unica llamada a ps))
tabla_b=$(ps -eo sid,pgid,pid,user:15,tty,%mem,cmd --no-headers --sort=user | awk '{printf "%-6s %-6s %-6s %-15s %-8s %-6s %s\n", $1, $2, $3, $4, $5, $6, $7}')
#tabla_b=$(ps -eo sid,pgid,pid,user:20,tty,%mem,cmd --no-headers --sort=user | awk '{print $1, $2, $3, $4, $5, $6, $7, $8}') 
if [[ $? -ne 0 ]]; then
    salida_error "Se ha producido un error al ejecutar el comando ps."
fi


#COMPROBAR FUNCIONAMIENTO DE LOS COMANDOS LSO Y AWK
for i in awk lsof ; do 
    which $i > /dev/null
    if [[ $? -ne 0 ]]; then
        salida_error "Se a producido un error el comando $i no está disponible."
    fi 
done


#FUNCIÓN PARA MANEJAR ERRORES 
salida_error() 
{
    echo "${TEXT_RED}${TEXT_BOLD}------------------------------------------------------------------------------------${TEXT_RESET}"
    echo "${TEXT_RED}${TEXT_BOLD}               Error en la ejecución del archivo ${PROGNAME} ${TEXT_RESET}" 
    echo "${TEXT_RED}${TEXT_BOLD}------------------------------------------------------------------------------------${TEXT_RESET}"
    echo "El error esta en la línea $LINENO" 1>&2
    echo 
    echo "${TEXT_YELLOW}${TEXT_BOLD}$1 ${TEXT_RESET}"
    echo 
    echo $ERROR
    echo 
    exit 1
}


#FUNCIÓN PARA MOSTRAR LA AYUDA
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


#FUNCION PARA CUANDO NO PONES NINGUNA OPCION EN EL SCRIPT
no_option() {
    echo -e "$CABECERA"
    # comprobamos que la PID (col1) no sea 0 y que el usuario (col4) sea el usuario actual
    actual_user=$(echo "$USER") # usaurio actual de bash usuario que está ejecutando el script vamos $USER , tambien se podría hacer con whoami
    echo "$tabla_b" | awk '$1 != "0" && $4 == "'"$actual_user"'"' | sort -k 4 -b 
    if [[ $? -ne 0 ]]; then
        salida_error "Se ha producido un error al mostrar los procesos del usuario Bash con PID distinto de 0" 
    fi
}



#VARIABLES PARA LAS OPCIONES DEL SCRIPT 
OPCION_Z=false
OPCION_D=""
OPCION_U=""
OPCION_M=false


# Si no hay opciones, se usa no_option
if [[ $# -eq 0 ]]; then
    no_option  # llamamos a la función no_option
    # Comprobamos que no haya errores con la función llamada 
    if [[ $? -ne 0 ]]; then
        salida_error "Se ha producido un error en la función no_option."
    fi
    exit 0  # salimos del script porque no hay opciones
else
    # Procesamos las  opciones
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -z) # Mostrar todos los procesos, incluyendo PID 0
                OPCION_Z=true
                shift
                ;;
            -u ) # Filtro por usuario
                shift
                OPCION_U="$1"
                #comprobamos que la opción no este vacía o que se haya introducido despues otra opcion sin poner un usuario
                if [[ -z "$1" || "$1" == "-"* ]]; then
                    salida_error "Se ha producido un error se debe especificar un usuario después de la opción -u."
                fi
                shift
                ;;
            -d) # Filtro por ruta de directorio
                OPCION_D="$2"
                if [[ -z "$OPCION_D" || "$OPCION_D" == "-"* ]]; then
                    salida_error "Se ha producido un error se debe inttroducir una ruta a un directprio después de la opción -d."
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
            -max) # Modificación
                OPCION_M=true
                shift
                ;;
            *) # Opción no válida
                salida_error "Se ha producido un error has introducido una opcion que no se reconoce: $1."
                ;;
        esac
    done
fi

if [[ "$OPCION_M" == true ]]; then
    #usuario con mas porcentaje de memoria
    linea_local=$(echo "$tabla_b" | sort -nr -k 6 | head -n 1)

    #pid del usuario con mas porcentaje de memoria
    pid_local=$(echo "$linea_local" | awk '{print $4}')

    uer_local=$(echo "$linea_local" | awk '{print $1}')

    
    porcent_local=$(echo "$linea_local" | awk '{print $6}')

    # Mostrar todos los procesos, incluyendo PID 0
    echo "El usaurio $user_local con pid $pid_local tiene un porcentaje de memoria de $porcent_local"
    exit 0 
fi

tabla_f="$tabla_b"  # tabla que recogera los filtros que se le apliquen


# Filtrar por usuario (OPCION -u)
if [[ -n "$OPCION_U" ]]; then  # comprobamos que la variable no esté vacía
    tabla_f=$(echo "$tabla_f" | awk '$4 == "'$OPCION_U'"')  # filtramos la tabla por el usuario especificado
    #Comprobamos que la tabla no esté vacía (para ello usamos -z que comprueba si la cadena está vacía)
    if [[ -z "$tabla_f" ]]; then
        salida_error "Se ha producido un error no hay procesos con el usuario $OPCION_U"
    else 
        #imprimimos la tabla con el usuario especificado
        echo -e "$CABECERA"
        echo "$tabla_f" 
    fi 
fi


# Filtrar por directorio (OPCION -d)
if [[ -n "$OPCION_D" ]]; then
    # Comprobar si el directorio existe (para ello usamos -d que comprueba si el directorio existe)
    if [[ ! -d "$OPCION_D" ]]; then
        salida_error "Se ha producido un error el directorio $OPCION_D no existe."
    fi 

    #sacamos los pid de los procesos que tienen archivos abiertos en el directorio especificado (tr para que esten todos en una línea )
    pid_lsof_local=$(lsof +d $OPCION_D | awk '{print $2}' | tail -n +2 | uniq | tr '\n' ' ')

    #Comprobamos que la variable no esté vacía (para ello usamos -z que comprueba si la cadena está vacía)
    if [[ -z "$pid_lsof_local" ]]; then
        error_exit "Se ha producido un error no hay procesos con archivos abiertos en el directorio $OPCION_D"
    fi
    
    # Filtrar los procesos que tengan archivos abiertos en el directorio especificado
    #echo -e "$CABECERA" # imprimimos la cabecera

    # Recorremos los PID de los procesos que tienen archivos abiertos en el directorio especificado en OPCION_D
    for i in $pid_lsof_local; do
        #Comprobamos que en la columna 3 (pid) sea igual al pid que hemos sacado con lsof
        tabla_local=$(echo "$tabla_f" | awk '$3 == '$i'')
        # Solo imprimir si tabla_local tiene contenido (para que no imprima líneas vacías)
        #if [[ -n "$tabla_local" ]]; then
            #echo "$tabla_local"
        #fi
        #echo "$tabla_local"
    done 
    #echo "$tabla_local"
    tabla_f="$tabla_local"  # Actualizar `tabla_f` con los resultados (para poder seguir aplicando filtros)
fi

# Mostrar todos los procesos, incluyendo PID 0 (OPCION -z)
if [[ "$OPCION_Z" == true ]]; then
    echo -e "$CABECERA"
    # Mostrar todos los procesos, incluyendo PID 0
    echo "$tabla_f" 
fi

tamano=$(echo "$tabla_f" | wc -l)  # Contar el número de líneas de la tabla
if [[ $tamano -lt 5 ]]; then
    echo "$AYUDA_M"
fi

#salimos del script
exit 0