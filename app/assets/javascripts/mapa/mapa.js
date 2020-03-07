/**
 * Inicializa el mapa
 * @param id
 */
var cargaMapa = function (id)
{
    // El default de leaflet
    var OSM_layer = L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png',{
        zIndex: 1,
        noWrap: true
    });

    // Google terrain map layer
    var GTM_layer = L.tileLayer('http://{s}.google.com/vt/lyrs=p&x={x}&y={y}&z={z}',{
        subdomains:['mt0','mt1','mt2','mt3'],
        zIndex: 1,
        noWrap: true
    });
    // Google Hybrid
    var GHM_layer = L.tileLayer('http://{s}.google.com/vt/lyrs=y&x={x}&y={y}&z={z}',{
        subdomains:['mt0','mt1','mt2','mt3'],
        zIndex: 1,
        noWrap: true
    });

    var place = [23.79162789, -102.04376221];

    map = L.map(id, {
        zoomControl: false,
        doubleClickZoom: false,
        layers: [     // Existe un bug poniendo primero los layes de google
            //OSM_layer,
            GHM_layer,
            //GTM_layer,
        ]
    });

    var zoom = L.control.zoom({
        zoomInTitle: 'Acercarse',
        zoomOutTitle: 'Alejarse'
    });

    // https://github.com/brunob/leaflet.fullscreen
    var fullscreen = L.control.fullscreen({
        position: 'topleft',
        title: 'Pantalla completa',
        titleCancel: 'Salir de pantalla completa'
    });

    map.addControl(zoom);
    map.addControl(fullscreen);

    map.setView(place, 4);  // Default place and zoom

    // Para poner las capas iniciales de los mapas
    var baseMaps = {
        "Vista Híbrida": GHM_layer,
        //"Open Street Maps": OSM_layer,
        //"Vista de terreno": GTM_layer,
    };

    L.control.layers(baseMaps).addTo(map);

};