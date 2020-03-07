/**
 * Borra capas anteriores y carga las nuevas
 * @param url
 */
var cargaCapasGeoserver = function(url)
{
    distribucionLayer = undefined;
    borraCapasAnterioresGeoserver();
    capaDistribucionGeoserver(url);
};

/**
 * Borra capas anteriores
 */
var borraCapasAnterioresGeoserver = function()
{
    if (distribucionLayer == undefined) return;
    if (map.hasLayer(distribucionLayer))
    {
        map.removeControl(geoserver_control);
        map.removeLayer(distribucionLayer);
    }
};

/**
 * La simbologia dentro del mapa
 */
var leyendaGeoserver = function()
{
    geoserver_control = L.control.layers({}, {}, {collapsed: true, position: 'bottomleft'}).addTo(map);

    geoserver_control.addOverlay(distribucionLayer,
        "<b>Distribución potencial<br /> (Geoserver CONABIO)</b>"
    );
};

/**
 * Crear y carga la capa de distribucion
 * @param url
 */
var capaDistribucionGeoserver = function (url) {
    var primer_layer = false;
    distribucionLayer = L.layerGroup([], { zIndex: 100 });
    geoserver_control = L.control.layers({}, {}, {collapsed: true, position: 'topright'}).addTo(map);

    $.each(opciones.geodatos.geoserver_descargas_url, function (index, datos) {
        console.log(datos);

        window[datos.id] = L.tileLayer.wms(url, {
            layers: datos.id,
            format: 'image/png',
            transparent: true,
            opacity: .7,
            zIndex: 4,
        });

        distribucionLayer.addLayer(window[datos.id]);

        if(!primer_layer)
        {
            map.addLayer(window[datos.id]);
            //window[datos.id].bringToFront();
            primer_layer = true;
        }

        geoserver_control.addOverlay(window[datos.id],
            "<b>Dist. potencial</b>: " + datos.anio + ' (' + datos.id + ')'
        );
    });
};