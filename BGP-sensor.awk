#/bin/gawk -f

function getHHMMSS(segundos){
        s = segundos
        h=int(s/3600);
        s=s-(h*3600);
        m=int(s/60);
        s=s-(m*60);
        return sprintf("%02s:%02s:%02s", h, m, s)
}

function esIPValida(n){
        split(n,octetos,".")
        return ((octetos[1] ~ /^([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])$/) &&
                (octetos[2] ~ /^([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])$/) &&
                (octetos[3] ~ /^([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])$/) &&
                (octetos[4] ~ /^([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])$/))
}

BEGIN{
        FS=":"

# BGP Neighbour 1
        S_IP="192.0.2.1"
        S_ultimaFechaUP=""
        S_ultimaFechaDOWN=""
        S_cantidadCortes=0
        S_totalCortes=0
        mostrar_neighbour_1=0

# BGP Neighbour 2
        C_IP="192.0.2.2"
        C_ultimaFechaUP=""
        C_ultimaFechaDOWN=""
        C_cantidadCortes=0
        C_totalCortes=0
        mostrar_neighbour_2=0
}
{
        ano=substr($1,0,4)
        mes=substr($1,6,2)
        dia=substr($1,9,2)
        hora=substr($1,12,2)
        minuto=$2
        segundo=substr($3,0,2)

        if (( $4 ~ /^ %ADJCHANGE/ ) && ( $5 ~ /^ neighbor /)){
                split($5,descripcion," ")
                if (descripcion[2] == S_IP){
                        mostrar_neighbour_1=1
                        if (descripcion[3] == "Down"){
                                S_timeDown=mktime(ano" "mes" "dia" "hora" "minuto" "segundo)
                                S_ultimaFechaDOWN=ano"/"mes"/"dia" "hora":"minuto":"segundo
                        }else if (descripcion[3] == "Up"){
                                S_timeUp=mktime(ano" "mes" "dia" "hora" "minuto" "segundo)
                                S_ultimaFechaUP=ano"/"mes"/"dia" "hora":"minuto":"segundo
                                S_cantidadCortes++
                                if (!S_ultimaFechaDOWN){
                                        S_ultimaFechaDOWN=ano"/"mes"/"dia" 00:00:00"
                                        S_timeDown=mktime(ano" "mes" "dia" 00 00 00")
                                }
                                S_corteInicio[S_cantidadCortes]=S_ultimaFechaDOWN
                                S_corteFin[S_cantidadCortes]=S_ultimaFechaUP
                                S_corte[S_cantidadCortes]= S_timeUp - S_timeDown
                                S_totalCortes+=S_corte[S_cantidadCortes]
                        }
                } else if (descripcion[2] == C_IP){
                        mostrar_neighbour_2=1
                        if (descripcion[3] == "Down"){
                                C_timeDown=mktime(ano" "mes" "dia" "hora" "minuto" "segundo)
                                C_ultimaFechaDOWN=ano"/"mes"/"dia" "hora":"minuto":"segundo
                        }else if (descripcion[3] == "Up"){
                                C_timeUp=mktime(ano" "mes" "dia" "hora" "minuto" "segundo)
                                C_ultimaFechaUP=ano"/"mes"/"dia" "hora":"minuto":"segundo
                                C_cantidadCortes++
                                if (!C_ultimaFechaDOWN){
                                        C_ultimaFechaDOWN=ano"/"mes"/"dia" 00:00:00"
                                        C_timeDown=mktime(ano" "mes" "dia" 00 00 00")
                                }
                                C_corteInicio[C_cantidadCortes]=C_ultimaFechaDOWN
                                C_corteFin[C_cantidadCortes]=C_ultimaFechaUP
                                C_corte[C_cantidadCortes]= C_timeUp - C_timeDown
                                C_totalCortes+=C_corte[C_cantidadCortes]
                        }
                }
        }
}
END {
        salida="From: BGP ALARM <sysop@bblanca.com.ar>\n"
        salida=salida"Subject: BGP ALARM - "fecha" \n"
        salida=salida"Content-type: text/html\n\n"

        salida=salida"<h3> Cortes en sesion BGP </h3>"
        if (mostrar_neighbour_1){
                salida=salida"<table border=1><caption>SILICA ("S_IP")</caption><thead><tr><th>Inicio</th><th>Fin</th><th>Duracion</th></tr></thead></tbody>"
                for (i=1; i <= S_cantidadCortes; i++){
                        salida=salida"<tr><td>"S_corteInicio[i]"</td><td>"S_corteFin[i]"</td><td>"getHHMMSS(S_corte[i])"</td></tr>"
                }
                if (S_timeDown > S_timeUp){
                        salida=salida"<tr><td>"S_ultimaFechaDOWN"</td><td><b style=\"color:red;\">Still DOWN</b></td><td>...</td></tr>"
                }
                salida=salida"</tbody></table><p>Total de <b>"S_cantidadCortes"</b> cortes, sumarizando "S_totalCortes" segundos ("getHHMMSS(S_totalCortes)")</p>"
                print "Neighbour 1: Cantidad de cortes = "S_cantidadCortes" sumarizando un total de "S_totalCortes" segundos ("getHHMMSS(S_totalCortes)")"
        }

        if (mostrar_neighbour_2){
                salida=salida"<table border=1><caption>CABASE ("C_IP")</caption><thead><tr><th>Inicio</th><th>Fin</th><th>Duracion</th></tr></thead></tbody>"
                for (i=1; i <= C_cantidadCortes; i++){
                        salida=salida"<tr><td>"C_corteInicio[i]"</td><td>"C_corteFin[i]"</td><td>"getHHMMSS(C_corte[i])"</td></tr>"
                }
                if (C_timeDown > C_timeUp){
                        salida=salida"<tr><td>"C_ultimaFechaDOWN"</td><td><b style=\"color:red;\">Still DOWN</b></td><td>...</td></tr>"
                }
                salida=salida"</tbody></table><p>Total de <b>"C_cantidadCortes"</b> cortes, sumarizando "C_totalCortes" segundos ("getHHMMSS(C_totalCortes)")</p>"
                print "Neighbour 2: Cantidad de cortes = "C_cantidadCortes" sumarizando un total de "C_totalCortes" segundos ("getHHMMSS(C_totalCortes)")"
        }

        if (mostrar_neighbour_1 || mostrar_neighbour_2){
                system("echo '"salida"' | sendmail fvictor@bblanca.com.ar")
        }
}
