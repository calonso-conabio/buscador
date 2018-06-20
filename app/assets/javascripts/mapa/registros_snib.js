/**
 * Borra registros anteriores y carga los nuevos
 * @param url
 */
var cargaRegistrosSnib = function(url)
{
    borraRegistrosAnterioresSnib();
    geojsonSnib(url);
};

/**
 * Borra registros anteriores
 */
var borraRegistrosAnterioresSnib = function()
{
    if (map.hasLayer(markersLayer))
    {
        map.removeControl(legend_control);
        map.removeLayer(markersLayer);
        markersLayer = L.markerClusterGroup({ chunkedLoading: true, spiderfyDistanceMultiplier: 2, spiderLegPolylineOptions: { weight: 1.5, color: 'white', opacity: 0.5 }, which_layer: 'geoportal'});
    }
};

/**
 * La simbologia dentro del mapa
 * @param con_conteo
 */
var leyendaSnib = function(con_conteo)
{
    legend_control = L.control.layers({}, {}, {collapsed: false, position: 'bottomleft'}).addTo(map);

    if (con_conteo == undefined)
        var conteo = "<b>Registros del SNIB</b>";
    else
        var conteo = "<b>Registros del SNIB <sub>" + registros_conteo + "</sub></b>";

    var marker_default = '&nbsp;&nbsp;<i class="circle-ev-icon div-icon-snib-default"></i>Especímenes en colecciones<br />';
    var marker_averaves = '<i class="feather-ev-icon div-icon-snib"></i>Observaciones<br />';
    var marker_fosil = '<i class="bone-ev-icon div-icon-snib"></i>Fósiles';

    legend_control.addOverlay(markersLayer,
        conteo + "<p>" + marker_default + marker_averaves + marker_fosil + "</p>"
    );
};

/**
 * Añade los puntos en forma de fuentes
 */
var aniadePuntosSnib = function()
{
    var geojsonFeature =  { "type": "FeatureCollection", "features": allowedPoints.values()};

    var species_layer = L.geoJson(geojsonFeature, {
        pointToLayer: function (feature, latlng) {

            if (feature.properties.d.ejemplarfosil == 'SI')  // Este campos quiere decir que es un fosil
                return L.marker(latlng, {icon: L.divIcon({className: 'div-icon-snib', html: '<i class="bone-ev-icon"></i>'})});
            else if (feature.properties.d.coleccion.toLowerCase().includes('averaves') || feature.properties.d.coleccion.toLowerCase().includes('ebird'))  // Este campos quiere decir que es de aves aves
                return L.marker(latlng, {icon: L.divIcon({className: 'div-icon-snib', html: '<i class="feather-ev-icon"></i>'})});
            else  // de lo contrario es un registro normal
                return L.marker(latlng, {icon: L.divIcon({className: 'div-icon-snib-default', html: '<i class="circle-ev-icon"></i>'})});
        },
        onEachFeature: function (prop, layer) {
            layer.bindPopup(ejemplarSnib(prop.properties.d));
            layer.on("click", function () {
            });
        }
    });

    markersLayer.addLayer(species_layer);
    map.addLayer(markersLayer);

    leyendaSnib(true);
};

/**
 * Hace una ajax request para la obtener la información de un taxon, esto es más rapido para muchos registros
 * */
var ejemplarSnibGeojson = function(layer, id)
{
    $.ajax({
        url: "/especies/" + TAXON.id + "/ejemplar-snib/" + id,
        dataType : "json",
        success : function (res){
            if (res.estatus == 'OK')
            {
                var ejemplar = res.ejemplar;
                var contenido = "";

                contenido += "<h4>" + nombre() + "</h4>";
                contenido += "<dt>Localidad: </dt><dd>" + ejemplar.localidad + "</dd>";
                contenido += "<dt>Municipio: </dt><dd>" + ejemplar.municipiomapa + "</dd>";
                contenido += "<dt>Estado: </dt><dd>" + ejemplar.estadomapa + "</dd>";
                contenido += "<dt>País: </dt><dd>" + ejemplar.paismapa + "</dd>";
                contenido += "<dt>Fecha: </dt><dd>" + ejemplar.fechacolecta + "</dd>";
                contenido += "<dt>Colector: </dt><dd>" + ejemplar.colector + "</dd>";
                contenido += "<dt>Colección: </dt><dd>" + ejemplar.coleccion + "</dd>";
                contenido += "<dt>Institución: </dt><dd>" + ejemplar.institucion + "</dd>";
                contenido += "<dt>País de la colección: </dt><dd>" + ejemplar.paiscoleccion + "</dd>";

                if (ejemplar.proyecto.length > 0 && ejemplar.urlproyecto.length > 0)
                    contenido += "<dt>Proyecto: </dt><dd><a href='" + ejemplar.urlproyecto + "' target='_blank'>" + ejemplar.proyecto + "</a></dd>";

                contenido += "<dt>Más información: </dt><dd><a href='http://" + ejemplar.urlejemplar + "' target='_blank'>consultar</a></dd>";

                // Para enviar un comentario acerca de un registro en particular
                contenido += "<dt>¿Tienes un comentario?: </dt><dd><a href='/especies/" + TAXON.id + "/comentarios/new?proveedor_id=" + ejemplar.idejemplar + "&tipo_proveedor=6' target='_blank'>redactar</a></dd>";

                contenido = "<dl class='dl-horizontal'>" + contenido + "</dl>" + "<strong>ID: </strong>" + ejemplar.idejemplar;
            } else {
                var contenido = "Hubo un error al retraer el ejemplar: " + res.msg;
            }

            // Pone el popup arriba del punto
            var popup = new L.Popup();
            var bounds = layer.getBounds();

            popup.setLatLng(bounds.getCenter());
            popup.setContent(contenido);
            map.openPopup(popup);
        },
        error: function( jqXHR ,  textStatus,  errorThrown ){
            console.log("error: " + textStatus);
            console.log(errorThrown);
            console.log(jqXHR.responseText);
        }
    });  // termina ajax
};

/**
 * Lanza el pop up con la inforamcion del taxon, ya esta cargado; este metodo es lento con muchos registros
 * */
var ejemplarSnib = function(prop)
{
    var contenido = "";

    contenido += "<h4 class='text-center'>" + nombre() + "</h4>";
    contenido += "<dt>Localidad: </dt><dd>" + prop.localidad + "</dd>";
    contenido += "<dt>Municipio: </dt><dd>" + prop.municipiomapa + "</dd>";
    contenido += "<dt>Estado: </dt><dd>" + prop.estadomapa + "</dd>";
    contenido += "<dt>País: </dt><dd>" + prop.paismapa + "</dd>";
    contenido += "<dt>Fecha: </dt><dd>" + prop.fechacolecta + "</dd>";
    contenido += "<dt>Colector: </dt><dd>" + prop.colector + "</dd>";
    contenido += "<dt>Colección: </dt><dd>" + prop.coleccion + "</dd>";
    contenido += "<dt>Institución: </dt><dd>" + prop.institucion + "</dd>";
    contenido += "<dt>País de la colección: </dt><dd>" + prop.paiscoleccion + "</dd>";

    if (prop.proyecto.length > 0 && prop.urlproyecto.length > 0)
        contenido += "<dt>Proyecto: </dt><dd><a href='" + prop.urlproyecto + "' target='_blank'>" + prop.proyecto + "</a></dd>";

    contenido += "<dt>Más información: </dt><dd><a href='" + prop.urlejemplar + "' target='_blank'>consultar</a></dd>";

    //Para enviar un comentario acerca de un registro en particular
    contenido += "<dt>¿Tienes un comentario?: </dt><dd><a href='/especies/" + opciones.taxon_seleccionado.id + "/comentarios/new?proveedor_id=" + prop.idejemplar + "&tipo_proveedor=6' target='_blank'>redactar</a></dd>";

    return "<dl class='dl-horizontal'>" + contenido + "</dl>" + "<strong>ID SNIB: </strong>" + prop.idejemplar;
};

/**
 * Para desplegar el nombre cientifico, idealmente deberia de venir del helper de especies
 * @returns {string}
 */
var nombre = function()
{
    if (I18n.locale == 'es')
    {
        if (opciones.taxon_seleccionado.nombre_comun.length > 0)
            return opciones.taxon_seleccionado.nombre_comun + "<br /><a href='/especies/" + opciones.taxon_seleccionado.id + "'><i>" + opciones.taxon_seleccionado.nombre_cientifico + "</i></a>";
        else
            return "<a href='/especies/" + opciones.taxon_seleccionado.id + "' target='_blank'><i>" + opciones.taxon_seleccionado.nombre_cientifico + "</i></a>";
    } else
        return "<a href='/especies/" + opciones.taxon_seleccionado.id + "' target='_blank'><i>" + opciones.taxon_seleccionado.nombre_cientifico + "</i></a>";
};

/**
 * Carga el geojson para iterarlo
 * @param url
 */
var geojsonSnib = function(url)
{
    $.ajax({
        url: url,
        dataType : "json",
        success : function (d){
            registros_conteo = d.length;
            allowedPoints = d3.map([]);

            for(var i=0;i<d.length;i++)
            {
                var item_id = 'geo-' + i.toString();

                allowedPoints.set(item_id, {
                    "type"      : "Feature",
                    "properties": {d: d[i]}, // El ID y si es de aver aves
                    "geometry"  : JSON.parse(d[i].json_geom)
                });
            }

            aniadePuntosSnib();
        },
        error: function( jqXHR ,  textStatus,  errorThrown ){
            console.log("error: " + textStatus);
            console.log(errorThrown);
            console.log(jqXHR.responseText);
        }
    });
};