#! /bin/bash

cd /home/enciclovida/buscador/
redis-server &
sleep 10
export RAILS_ENV=production
rails runner "eval(File.read '/home/enciclovida/buscador/tools/levantaServicios/levantaBlurrily.rb')" &
nohup ruby /home/enciclovida/buscador/bin/delayed_job -i validaciones --queue=validaciones run &
nohup ruby /home/enciclovida/buscador/bin/delayed_job -i descargar_taxa --queue=descargar_taxa run &
nohup ruby /home/enciclovida/buscador/bin/delayed_job -i ejemplares_snib--queue=ejemplares_snib run &
nohup ruby /home/enciclovida/buscador/bin/delayed_job -i estadisticas --queue=estadisticas run &
nohup ruby /home/enciclovida/buscador/bin/delayed_job -i observaciones_naturalista --queue=observaciones_naturalista run &
nohup ruby /home/enciclovida/buscador/bin/delayed_job -i redis --queue=redis run &
nohup ruby /home/enciclovida/buscador/bin/delayed_job -i peces --queue=peces run &
nohup ruby /home/enciclovida/buscador/bin/delayed_job -i estadisticas_naturalista --queue=estadisticas_naturalista run &
nohup ruby /home/enciclovida/buscador/bin/delayed_job -i estadisticas_conabio --queue=estadisticas_conabio run &
nohup ruby /home/enciclovida/buscador/bin/delayed_job -i estadisticas_wikipedia --queue=estadisticas_wikipedia run &
nohup ruby /home/enciclovida/buscador/bin/delayed_job -i estadisticas_eol --queue=estadisticas_eol run &
nohup ruby /home/enciclovida/buscador/bin/delayed_job -i estadisticas_tropicos_service --queue=estadisticas_tropicos_service run &
nohup ruby /home/enciclovida/buscador/bin/delayed_job -i estadisticas_maccaulay --queue=estadisticas_maccaulay run &
nohup ruby /home/enciclovida/buscador/bin/delayed_job -i estadisticas_SNIB --queue=estadisticas_SNIB run &
nohup ruby /home/enciclovida/buscador/bin/delayed_job -i estadisticas_mapas_distribucion --queue=estadisticas_mapas_distribucion run &
