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
HELP="${TEXT_GREEN}${TEXT_BOLD}Este programa muestra una tabla con información sobre los procesos y sesiones del usuario: $USER .${TEXT_RESET}"
PROGNAME=$(basename $0)


#CABECERAS
CABECERA="$(printf "${TEXT_GREEN}${TEXT_BOLD}%-8s %-8s %-8s %-15s %-8s %-8s %s${TEXT_RESET}\n" "SID" "PGID" "PID" "USER" "TTY" "%MEM" "CMD")"
#CABECERA="${TEXT_GREEN}${TEXT_BOLD}SID  PGID    PID    USER    TTY   %MEM  CMD${TEXT_RESET}"
CABECERA2="$(printf "${TEXT_MAGENTA}${TEXT_BOLD}%-5s %-10s %-10s %-10s %-15s %-10s %-10s %s${TEXT_RESET}\n" "SID" "TOT_PGID" "%MEM_TOT" "PID_LEAD" "US_LEAD" "CON_TTY" "CMD_LEAD")"
#si queremos alinear la tabla a la derecha simplemente quitamos el - antes de la s en el printf

#TABLA BASICA (comando ps basico (unica llamada a ps))
tabla_b=$(ps -eo sid,pgid,pid,user:15,tty,%mem,cmd --no-headers --sort=user | awk '{printf "%-8s %-8s %-8s %-15s %-8s %-8s %s\n", $1, $2, $3, $4, $5, $6, $7}')
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
    echo "${TEXT_BOLD}${TEXT_BLUE}Uso: $PROGNAME [opciones]${TEXT_RESET}"
    echo
    echo "${TEXT_MAGENTA}${TEXT_BOLD}Las opciones posibles son con cualquier orden son:${TEXT_RESET}"
    echo "${TEXT_BOLD}-z:${TEXT_RESET}               La tabla muestra también los procesos cuyo identificador sea 0."
    echo "${TEXT_BOLD}-u [usuarios]:${TEXT_RESET}    Muestra los procesos cuyo usuario efectivo sea el especificado.(se pued introducir uno o avrios)"
    echo "${TEXT_BOLD}-d [ruta]:${TEXT_RESET}        Muestra solo los procesos que tengan archivos abiertos en el directorio especificado."
    echo "${TEXT_BOLD}-t:${TEXT_RESET}               Muestra solo los procesos que tengan una terminal controladora asociada."
    echo "${TEXT_BOLD}-e:${TEXT_RESET}               Muestra una tabla de sesiones."
    echo "${TEXT_BOLD}-sm:${TEXT_RESET}              Ordena la tabla por % de memoria.(opcion valida con -e o sin -e)"
    echo "${TEXT_BOLD}-sg:${TEXT_RESET}              Ordena la tabla por número de procesos.(esta opcion no es valida con -sm o sin el uso de -e)"
    echo "${TEXT_BOLD}-r:${TEXT_RESET}               Muestra la tabla en orden inverso."
    echo "${TEXT_BOLD}-h|--help:${TEXT_RESET}        Muestra esta ayuda."
    echo 

    exit 0
}


#FUNCION PARA CUANDO NO PONES NINGUNA OPCION EN EL SCRIPT
no_option() {
    echo -e "$CABECERA"
    # comprobamos que la PID (col1) no sea 0 y que el usuario (col4) sea el usuario actual
    actual_user=$(echo "$USER") # usaurio actual de bash usuario que está ejecutando el script vamos $USER , tambien se podría hacer con whoami
    echo "$tabla_b" | awk '$1 != "0" && $4 == "'"$actual_user"'"' | sort -k 4 -b $REVERSE
    if [[ $? -ne 0 ]]; then
        salida_error "Se ha producido un error al mostrar los procesos del usuario actual con PID distinto de 0" 
    fi
}

#VARIABLES PARA LAS OPCIONES DEL SCRIPT 
OPCION_Z=false
OPCION_D=false
DIR=""
OPCION_U=false 
USUARIOS=""
#OP_VALIDAS="-z -d -t -e -sm -sg -r"
OPCION_T=false
OPCION_E=false
OPCION_SM=false
OPCION_SG=false
OPCION_R=false
REVERSE=""


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
                OPCION_U=true
                shift

                #IMPLEMENTACION PARA UN SOLO USUARIO
                #USUARIOS="$1"
                #comprobamos que la opción no este vacía o que se haya introducido despues otra opcion sin poner un usuario
                #if [[ -z "$1" || "$1" == "-"* ]]; then
                    #salida_error "Se ha producido un error se debe especificar un usuario después de la opción -u."
                #fi

                #IMPLEMENTACION PARA VARIOS USUARIOS
                while [[ -n "$1" && "$1" != "-"* ]]; do
                    USUARIOS+="$1 " # añadimos un espacio para que se separen los usuarios
                    #$USUARIOS contendra una cadena con los usuarios separados por un espacio  
                    shift
                done
                ;;
            -d) # Filtro por ruta de directorio
                OPCION_D=true
                DIR="$2"
                if [[ -z "$DIR" || "$DIR" == "-"* ]]; then
                    salida_error "Se ha producido un error se debe introducir una ruta a un directprio después de la opción -d."
                fi
                shift 2
                ;;
            -t) # Filtro por terminal
                OPCION_T=true
                shift
                ;;
            -e) # Muestra una tabla de sesiones
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
                #Ordenar de forma inversa (OPCION -r)
                if [[ "$OPCION_R" == true ]]; then
                    REVERSE="-r"  
                else
                    REVERSE=""
                fi
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


#Filtrar por usuario (OPCION -u)(para un solo usuario)
#if [[ "$OPCION_U" == true ]]; then  
    #tabla_f=$(echo "$tabla_f" | awk '$4 == "'$USUARIOS'"'| sort -k4 -b)  # filtramos la tabla por el usuario especificado
    #Comprobamos que la tabla no esté vacía (para ello usamos -z que comprueba si la cadena está vacía)
    #if [[ -z "$tabla_f" ]]; then
        #salida_error "Se ha producido un error no hay procesos con el usuario $USUARIOS"
    #fi 
#fi


#Filtrar por usuario (OPCION -u)(para varios usuarios)
if [[ "$OPCION_U" == true ]]; then 
    #echo "$USUARIOS"
    # Recorremos los usuarios contnidos en $USUARIOS que habíamos obtenido antes en el case
    for i in $USUARIOS; do
        #echo "$i"
        #guardamos en la variable tabla_u los procesos que tengan el usuario especificado
        tabla_u=$(echo "$tabla_f" | awk '$4 == "'$i'"')
        if [[ $? -ne 0 ]]; then
            salida_error "Se ha producido un error en el bucle for de la opción -u."
        fi

        #introducimos en la tabla local la infromación de los usuarios que se han indicado
        tabla_loc+="$tabla_u"

        if [[ -z "$tabla_loc" ]]; then
            salida_error "Se ha producido un error no hay procesos con los usuarios especificados $USUARIOS"
        fi
    done

    if [[ $? -ne 0 ]]; then
        salida_error "Se ha producido un error en el bucle for de la opción -u."
    fi

    
    #ordenamos la tabla por el usuario (columna 4)
    tabla_f=$(echo "$tabla_loc" | sort -k4 -b $REVERSE)


    if [[ -z "$tabla_f" ]]; then
        salida_error "Se ha producido un error no hay procesos con los usuarios especificados $USUARIOS"
    fi
fi 


# Mostrar todos los procesos, incluyendo PID 0 (OPCION -z)
if [[ "$OPCION_Z" == true ]]; then
    #echo "$REVERSE"
    #simplemente es mostrar la tabla ya que esta recoge por defecto todos los procesos se ordena por el usuario (columna 4)
    tabla_f=$(echo "$tabla_f" | sort -k 4 -b $REVERSE)
    if [[ $? -ne 0 ]]; then
        salida_error "Se ha producido un error al realizar la opcion -z"
    fi
fi


# Filtrar por directorio (OPCION -d)
if [[ "$OPCION_D" == true ]]; then
    # Comprobar si el directorio existe (para ello usamos -d que comprueba si el directorio existe)
    if [[ ! -d "$DIR" ]]; then
        salida_error "Se ha producido un error el directorio $DIR no existe."
    fi 

    #sacamos los pid de los procesos que tienen archivos abiertos en el directorio especificado (tr para que esten todos en una línea )
    pid_lsof_local=$(lsof +d $DIR | awk '{print $2}' | tail -n +2 | uniq | tr '\n' ' ')

    #Comprobamos que la variable no esté vacía (para ello usamos -z que comprueba si la cadena está vacía)
    if [[ -z "$pid_lsof_local" ]]; then
        error_exit "Se ha producido un error no hay procesos con archivos abiertos en el directorio $DIR"
    fi
    
    # Recorremos los PID de los procesos que tienen archivos abiertos en el directorio especificado en DIR
    for i in $pid_lsof_local; do
        #Comprobamos que en la columna 3 (pid) sea igual al pid que hemos sacado con lsof
        tabla_local=$(echo "$tabla_f" | awk '$3 == "'$i'"')
        # Solo guardar filas con  contenido (para que no imprima líneas vacías)
        if [[ -n "$tabla_local" ]]; then
            tabla_d+=$(echo -e "\n $tabla_local  \n" )
        fi
    done 
    #echo "$tabla_d"
    #echo "$tabla_local"
    tabla_f=$(echo "$tabla_d" | sort -k4 -b $REVERSE)  
    if [[ $? -ne 0 ]]; then
        salida_error "Se ha producido un error no hay procesos con archivos abiertos en el directorio $DIR"
    fi
fi


#Filtrar por terminal (OPCION -t)
if [[ "$OPCION_T" == true ]]; then
    tabla_f=$(echo "$tabla_f" | awk '$5 != "?"' ) 
    if [[ $? -ne 0 ]]; then
        salida_error "Se ha producido un error al filtrar por terminal."
    fi
fi


#Funcion para la tabla de sesiones
if [[ "$OPCION_E" == false  ]]; then

    SID=$(echo "$tabla_f" | awk '{print $1}' | sort -n | uniq) # sesiones diferenntes 
    #echo $SID
    if [[ $? -ne 0 ]]; then
        salida_error "Se ha producido un error al buscar los SID."
    fi


    for i in $SID; do
        # Número de grupos de procesos diferentes por sesión
        PGID=$(echo "$tabla_f" | awk '$1 == '"$i"' {print $2}' | sort -u | wc -l)
        #echo $PGID

        # Total del % de memoria por sesión
        MEM=$(echo "$tabla_f" | awk '$1 == '"$i"' {sum+=$6} END {print sum " %"}')
        #echo $MEM

        # PID del proceso líder de la sesión
        PID=$(echo "$tabla_f" | awk '$1 == '"$i"' && $3 == '"$i"' {print $3}')
         #echo $PID
        if [ -z "$PID" ]; then
            PID="?"
            USER="?"
            TERMINAL="?"
            PROCESO="?"
        else
            #Usuario efectivo de la sesión
            USER=$(echo "$tabla_f" | awk '$1 == '"$i"' && $3 == '"$i"' {print $4}')
            #echo $USER

            #Terminal del proceso lider de la sesión
            TERMINAL=$(echo "$tabla_f" | awk '$1 == '"$i"' && $3 == '"$i"' {print $5}')
            #echo $TERMINAL

            #Comando del proceso lider de la sesión
            PROCESO=$(echo "$tabla_f" | awk '$1 == '"$i"' && $3 == '"$i"' {print $7}')
            #echo $PROCESO
        fi
    
        #comprobamos que ninguno de los campos esté vacío si esta vacío ponemos ?
        #for j in $PGID $MEM $PID $USER $TERMINAL $PROCESO; do
            #if [[ -z "$j" ]]; then
                #j="?"
            #fi
        #done

       #Guardamos la información recogida en una variable para despues imprimirla 
        tabla_sesion+=$(printf "%-5s %-10s %-10s %-10s %-15s %-10s %-10s %s" "$i" "$PGID" "$MEM" "$PID" "$USER" "$TERMINAL" "$PROCESO" "\n")

    done

    if [[ $? -ne 0 ]]; then
        salida_error "Se ha producido un error al crear la tabla de sesiones."
    fi

    # ordenar tabla por usuario (columna 5) (se usa -b para ignorar los espacios en blanco ya que dan problemas por el printf)
    #tabla_sesion=$(echo -e "$tabla_sesion" | sort -d -k 5 --debug -b | REVERSE) 
    tabla_sesion=$(echo -e "$tabla_sesion" | sed '/^ *$/d' | sort -d -k 5 -b $REVERSE)  # sed es para eliminar una línea vacía que se creaba

fi 


#Ordenar por memoria (OPCION -sm)
if [[ "$OPCION_SM" == true ]]; then

    if [[ "$OPCION_E" == true ]]; then
        tabla_f=$(echo "$tabla_f" | sort -g -k 6 -b $REVERSE)
        if [[ $? -ne 0 ]]; then
            salida_error "Se ha producido un error al ordenar la tabla de procesos por memoria."
        fi
    else
        tabla_sesion=$(echo -e "$tabla_sesion" | sort -g -k 3 -b  $REVERSE)
        if [[ $? -ne 0 ]]; then
            salida_error "Se ha producido un error al ordenar la tabla de sesiones por memoria."
        fi
        
    fi
fi


#Ordenar por numero de procesos (OPCION -sg)
if [[ "$OPCION_SG" == true ]]; then
    if [[ "$OPCION_SM" == true  ]]; then
        salida_error "Se ha producido un error no se puede ordenar por memoria (-sm) y por numero de procesos(-sg) a la vez."
    elif [[ "$OPCION_E" == true ]]; then
        salida_error "Se ha producido un error no se puede usar la opcion (-sg) y con la opcion (-e) "
    else
        tabla_f=$(echo "$tabla_f" | sort -n -k 2 $REVERSE)
        if [[ $? -ne 0 ]]; then
            salida_error "Se ha producido un error al ordenar la tabla de sesiones por numero de procesos."
        fi
    fi
fi


#MOSTRAR LAS TABLAS DE PROCESOS Y SESIONES
if [[ "$OPCION_E" == true ]]; then
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
else 
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
fi

