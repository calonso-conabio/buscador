/**
 * Borra observaciones anteriores y carga las nuevas
 * @param url
 */
var cargaObservacionesNaturalista = function(url)
{
    borraObservacionesAnterioresNaturalista();
    geojsonNaturalista(url);
};

/**
 * Borra observaciones anteriores
 */
var borraObservacionesAnterioresNaturalista = function()
{
    if (typeof naturalistaLayer !== 'undefined')
    {
        if (map.hasLayer(naturalistaLayer))
        {
            map.removeControl(naturalista_control);
            map.removeLayer(naturalistaLayer);
        }
    }

    naturalistaLayer = L.markerClusterGroup({
        chunkedLoading: true, spiderfyDistanceMultiplier: 2,
        spiderLegPolylineOptions: {weight: 1.5, color: 'white', opacity: 0.5},
        iconCreateFunction: function (cluster) {
            var markers = cluster.getAllChildMarkers();
            return L.divIcon({ html: '<div><span>' + markers.length + '</span></div>', className: 'div-cluster-naturalista',
                iconSize: L.point(40, 40) });
        }
    });
};

/**
 * La simbologia dentro del mapa
 */
var leyendaNaturalista = function()
{
    naturalista_control = L.control.layers({}, {}, {collapsed: true, position: 'bottomleft'}).addTo(map);

    naturalista_control.addOverlay(investigacionLayer,
        '<i class="fa fa-map-marker div-icon-naturalista"></i>Grado de investigación <sub>' + investigacion_conteo + '</sub>'
    );

    naturalista_control.addOverlay(casualLayer,
        '<i class="fa fa-flag div-icon-naturalista"></i>Grado casual <sub>' + casual_conteo + '</sub>'
    );
};

/**
 * Añade los puntos en forma de fuentes
 */
var aniadePuntosNaturaLista = function()
{
    var geojsonFeature =  { "type": "FeatureCollection", "features": allowedPoints.values() };

    var investigacion = L.geoJson(geojsonFeature, {
        pointToLayer: function (feature, latlng) {
            // Para distinguir si son solo las coordenadas
            if (opciones.solo_coordenadas)
            {
                if (feature.properties.d[1] == 1)  // Este campos quiere decir que es de grado de investigacion
                {
                    investigacion_conteo++;
                    return L.marker(latlng, {icon: L.divIcon({className: 'div-icon-naturalista', html: '<i class="fa fa-map-marker"></i>'})});
                }
            } else {
                if (feature.properties.d.quality_grade.toLowerCase() == 'investigación')
                {
                    investigacion_conteo++;
                    return L.marker(latlng, {icon: L.divIcon({className: 'div-icon-naturalista', html: '<i class="fa fa-flag"></i>'})});
                }
            }
        },
        onEachFeature: function (feature, layer) {
            // Para distinguir si son solo las coordenadas
            if (opciones.solo_coordenadas)
            {
                layer.on("click", function () {
                    observacionNaturalistaGeojson(layer, feature.properties.d[0]);
                });
            } else
                layer.bindPopup(observacionNaturalista(feature.properties.d));
        }
    });

    var casual = L.geoJson(geojsonFeature, {
        pointToLayer: function (feature, latlng) {
            // Para distinguir si son solo las coordenadas
            if (opciones.solo_coordenadas)
            {
                if (feature.properties.d[1] == 2)  // Este campos quiere decir que es de grado casual
                {
                    casual_conteo++;
                    return L.marker(latlng, {icon: L.divIcon({className: 'div-icon-naturalista', html: '<i class="fa fa-flag"></i>'})});
                }
            } else {
                if (feature.properties.d.quality_grade.toLowerCase() == 'casual')
                {
                    casual_conteo++;
                    return L.marker(latlng, {icon: L.divIcon({className: 'div-icon-naturalista', html: '<i class="fa fa-flag"></i>'})});
                }
            }
        },
        onEachFeature: function (feature, layer) {
            // Para distinguir si son solo las coordenadas
            if (opciones.solo_coordenadas)
            {
                layer.on("click", function () {
                    observacionNaturalistaGeojson(layer, feature.properties.d[0]);
                });
            } else
                layer.bindPopup(observacionNaturalista(feature.properties.d));
        }
    });

    investigacionLayer = L.featureGroup.subGroup(naturalistaLayer, investigacion);
    investigacionLayer.addLayer(investigacion);
    casualLayer = L.featureGroup.subGroup(naturalistaLayer, casual);
    casualLayer.addLayer(casual);

    map.addLayer(naturalistaLayer);
    map.addLayer(investigacionLayer);

    leyendaNaturalista();
    tituloControlLayerNaturalista();
};

/**
 * Hace una ajax request para la obtener la información de un taxon, esto es más rapido para muchas observaciones
 * */
var observacionNaturalistaGeojson = function(layer, id)
{
    $.ajax({
        url: "/especies/" + opciones.taxon + "/observacion-naturalista/" + id,
        dataType : "json",
        success : function (res){
            if (res.estatus)
            {
                var contenido = observacionNaturalista(res.observacion);
                layer.bindPopup(contenido);
                layer.openPopup();
            }
            else
                console.log("Hubo un error al retraer la observación: " + res.msg);
        },
        error: function( jqXHR ,  textStatus,  errorThrown ){
            console.log("error: " + textStatus);
            console.log(errorThrown);
            console.log(jqXHR.responseText);
        }
    });  // termina ajax
};

/**
 * Lanza el pop up con la inforamcion del taxon, ya esta cargado; este metodo es lento con muchas observaciones
 * */
var observacionNaturalista = function(prop)
{
    // Sustituye las etiquetas h5 por h4 y centra el texto
    var nombre_f = $('<textarea/>').html(opciones.nombre).text().replace(/<h5/g, "<h4 class='text-center'").replace(/<\/h5/g, "</h4");
    var contenido = "";

    contenido += "" + nombre_f + "";

    if (prop.thumb_url != undefined)
    {
        contenido += "<div><img class='img-responsive mx-auto d-block' src='" + prop.thumb_url + "'/></div>";
        contenido += "<strong>Atribución: </strong>" + prop.attribution + "<br />";
    }

    contenido += "<strong>Fecha: </strong>" + prop.observed_on + "<br />";
    contenido += "<strong>¿Silvestre / Naturalizado?: </strong>" + (prop.captive == true ? 'sí' : 'no') + "<br />";
    contenido += "<strong>Grado de calidad: </strong>" + prop.quality_grade + "<br />";
    contenido += "<strong>URL NaturaLista: </strong><a href='"+ prop.uri +"' target='_blank'>ver la observación</a><br />";

    // Para enviar un comentario acerca de un registro en particular
    contenido += "<strong>¿Tienes un comentario?: </strong><a href='/especies/" + opciones.taxon + "/comentarios/new?proveedor_id=" + prop.id + "&tipo_proveedor=7' target='_blank'>redactar</a><br />";

    return "<dl class='dl-horizontal'>" + contenido + "</dl>";
};

/**
 * Carga el geojson para iterarlo
 * @param url
 */
var geojsonNaturalista = function(url)
{
    $.ajax({
        url: url,
        dataType : "json",
        success : function (d){
            observaciones_conteo = d.length;
            investigacion_conteo = 0;
            casual_conteo = 0;

            allowedPoints = d3.map([]);

            for(var i=0;i<d.length;i++)
            {
                var item_id = 'geo-' + i.toString();

                if (opciones.solo_coordenadas)
                {
                    allowedPoints.set(item_id, {
                        "type"      : "Feature",
                        "properties": {d: [d[i][2], d[i][3]]},
                        "geometry"  : {coordinates: [d[i][0], d[i][1]], type: "Point"}
                    });
                } else {
                    allowedPoints.set(item_id, {
                        "type"      : "Feature",
                        "properties": {d: d[i]},
                        "geometry"  : JSON.parse(d[i].json_geom)
                    });
                }
            }

            aniadePuntosNaturaLista();
        },
        error: function( jqXHR ,  textStatus,  errorThrown ){
            console.log("error: " + textStatus);
            console.log(errorThrown);
            console.log(jqXHR.responseText);
        }
    });
};

/**
 * Pone el titulo en el control del layer, esto para darle formato y quede visible sin pasarle el mouse
 */
var tituloControlLayerNaturalista = function()
{
    $('.leaflet-control-layers:nth-child(1) a').remove();
    $('.leaflet-control-layers:nth-child(1)').prepend('<div class="text-center m-2"><span class=" font-weight-bold mr-2">Naturalista </span> <sub>' + observaciones_conteo + '</sub><br /> (ciencia ciudadana)<div>');
};