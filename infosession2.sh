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
HELP="${TEXT_GREEN}${TEXT_BOLD}Este programa muestra una tabla con información sobre los procesos del usuario: $USER .${TEXT_RESET}"
PROGNAME=$(basename $0)


#CABECERAS
CABECERA="$(printf "${TEXT_GREEN}${TEXT_BOLD}%-6s %-6s %-6s %-15s %-8s %-6s %s${TEXT_RESET}\n" "SID" "PGID" "PID" "USER" "TTY" "%MEM" "CMD")"
#CABECERA="${TEXT_GREEN}${TEXT_BOLD}SID  PGID    PID    USER    TTY   %MEM  CMD${TEXT_RESET}"
CABECERA2="$(printf "${TEXT_MAGENTA}${TEXT_BOLD}%-5s %-10s %-10s %-10s %-15s %-10s %-10s %s${TEXT_RESET}\n" "SID" "TOT_PGID" "%MEM_TOT" "PID_LEAD" "US_LEAD" "CON_TTY" "CMD_LEAD")"


#TABLA BASICA (comando ps basico (unica llamada a ps))
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
    echo "-u [usuarios]:     Muestra los procesos cuyo usuario efectivo sea el especificado.(se pued introducir uno o avrios)"
    echo "-d [ruta]:        Muestra solo los procesos que tengan archivos abiertos en el directorio especificado."
    echo "-t:               Muestra solo los procesos que tengan una terminal controladora asociada."
    echo "-e:               Muestra una tabla de sesiones."
    echo "-sm:              Ordena la tabla por % de memoria.(opcion valida con -e o sin -e)"
    echo "-sg:              Ordena la tabla por número de procesos.(esta opcion no es valida con -sm o sin el uso de -e)"
    echo "-r:               Muestra la tabla en orden inverso."
    echo "-h|--help:        Muestra esta ayuda."
    echo 
}


#FUNCION PARA CUANDO NO PONES NINGUNA OPCION EN EL SCRIPT
no_option() {
    echo -e "$CABECERA"
    # comprobamos que la PID (col1) no sea 0 y que el usuario (col4) sea bash
    echo "$tabla_b" | awk '$1 != "0" && $4 == "bash"' 

    if [[ $? -ne 0 ]]; then
        salida_error "Se ha producido un error al mostrar los procesos del usuario Bash con PID distinto de 0" 
    fi
}



#VARIABLES PARA LAS OPCIONES DEL SCRIPT 
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
            -t) # Filtro por terminal controladora asociada.
                OPCION_T=true
                shift
                ;;
            -e) # FIltro para Tabla de sesiones
                OPCION_E=true
                shift
                ;;
            -sm) #Filtro para ordenar por memoria
                OPCION_SM=true
                shift
                ;;
            -sg) #Filtro para ordenar por num de procesos
                OPCION_SG=true
                shift
                ;;
            -r) # Filtro para ordenar en orden inverso
                OPCION_R=true
                shift
                ;;
            -h|--help) # Mostrar la ayuda 
                ayuda
                if [[ $? -ne 0 ]]; then
                    salida_error "Se ha producido un error al mostrar la ayuda."
                fi
                exit 0
                ;;
            *) # Opción no válida
                salida_error "Se ha producido un error has introducido una opcion que no se reconoce: $1."
                ;;
        esac
    done
fi



tabla_f="$tabla_b"  # tabla que recogera los filtros que se le apliquen

# Filtrar por sesiones (OPCION -e)
if [[ "$OPCION_E" == true ]]; then

    SID=$(echo "$tabla_f" | awk '{print $1}' | sort -n | uniq) # sesiones diferenntes 


    for i in $SID; do
        # Número de grupos de procesos diferentes por sesión
        PGID=$(echo "$tabla_f" | awk '$1 == '"$i"' {print $2}' | sort -u | wc -l)
    
        # Total del % de memoria por sesión
        MEM=$(echo "$tabla_f" | awk '$1 == '"$i"' {sum+=$6} END {print sum "%"}')
    
        # PID líder de la sesión
        PID=$(echo "$tabla_f" | awk '$1 == '"$i"' && $3 == '"$i"' {print $3}')

        #Usuario efectivo de la sesión
        USER=$(echo "$tabla_f" | awk '$1 == '"$i"' && $3 == '"$i"' {print $4}')

        #Terminal del proceso lider de la sesión
        TERMINAL=$(echo "$tabla_f" | awk '$1 == '"$i"' && $3 == '"$i"' {print $5}')

        #Comando del proceso lider de la sesión
        PROCESO=$(echo "$tabla_f" | awk '$1 == '"$i"' && $3 == '"$i"' {print $7}')

       #Guardamos la información recogida en una variable para despues imprimirla 
        tabla_sesion+=$(printf "%-5s %-10s %-10s %-10s %-15s %-10s %-10s %s" "$i" "$PGID" "$MEM" "$PID" "$USER" "$TERMINAL" "$PROCESO" "\n")

    done

    # ordenar tabla por usuario (columna 5)
    tabla_sesion=$(echo -e "$tabla_sesion" | sort  -k 5) 

fi 

#Ordenar por memoria (OPCION -sm)
if [[ "$OPCION_SM" == true ]]; then

    if [[ "$OPCION_E" == true ]]; then
        tabla_sesion=$(echo -e "$tabla_sesion"| sort -n -k 3)
    else
        tabla_f=$(echo "$tabla_f" | sort -n -k 6)
    fi
fi

#Ordenar por numero de procesos (OPCION -sg)
if [[ "$OPCION_SG" == true ]]; then
    if [[ "$OPCION_SM" == true  ]]; then
        salida_error "Se ha producido un error no se puede ordenar por memoria (-sm) y por numero de procesos(-sg) a la vez."
    elif [[ "$OPCION_E" == false ]]; then
        salida_error "Se ha producido un error no se puede usar la opcion (-sg) y sin la opcion (-e) "
    else
        tabla_f=$(echo "$tabla_f" | sort -n -k 2)
    fi
fi

# Filtrar por usuario (OPCION -u)
if [[ -n "$OPCION_U" ]]; then  # comprobamos que la variable no esté vacía
    tabla_f=$(echo "$tabla_f" | awk '$4 == "'$OPCION_U'"')  # filtramos la tabla por el usuario especificado
    #Comprobamos que la tabla no esté vacía (para ello usamos -z que comprueba si la cadena está vacía)
    if [[ -z "$tabla_f" ]]; then
        salida_error "Se ha producido un error no hay procesos con el usuario $OPCION_U"
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
    # Recorremos los PID de los procesos que tienen archivos abiertos en el directorio especificado en OPCION_D
    for i in $pid_lsof_local; do
        #Comprobamos que en la columna 3 (pid) sea igual al pid que hemos sacado con lsof
        tabla_local=$(echo "$tabla_f" | awk '$3 == '$i'')
        # Solo imprimir si tabla_local tiene contenido (para que no imprima líneas vacías)
        if [[ -n "$tabla_local" ]]; then
             tabla_f="$tabla_local"
        fi
    done 

fi

# Mostrar todos los procesos, incluyendo PID 0 (OPCION -z)
if [[ "$OPCION_Z" == true ]]; then
    tabla_f=$(echo "$tabla_f" )
fi

#Mostrar procesos que tengan una terminal controladora asociada 
if [[ "$OPCION_T" == true ]]; then 
    tabla_f=$(echo "$tabla_f" | awk '$5 != "?"')
fi

#Ordenar en orden inverso (OPCION -r)


#MOSTRAR LA TABLA 
if [[ "$OPCION_E" == true ]]; then
 
    if [[ -z "$tabla_sesion" ]]; then
        echo 
        echo "${TEXT_YELLOW}${TEXT_BOLD}NO SE HAN ENCONTRADO RESULTADOS A TU BUESQUEDA PRUEBA OTRA COMBINACION DE OPCIONES.${TEXT_RESET}"
        ayuda

    else
        echo -e "$CABECERA2"
        echo "$tabla_sesion"
        if [[ $? -ne 0 ]]; then
            salida_error "Se ha producido un error al mostrar la tabla de sesiones."
        fi
    fi
    exit 0
else 

    if [[ -z "$tabla_f" ]]; then
        echo
        echo "${TEXT_YELLOW}${TEXT_BOLD}NO SE HAN ENCONTRADO RESULTADOS A TU BUESQUEDA PRUEBA OTRA COMBINACION DE OPCIONES.${TEXT_RESET}"
        ayuda
    else
        echo -e "$CABECERA"
        echo "$tabla_f"
        if [[ $? -ne 0 ]]; then
            salida_error "Se ha producido un error al mostrar la tabla de procesos."
        fi
    fi
    exit 0
fi

#salimos del script
exit 0