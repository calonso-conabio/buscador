//=require especies/carrusel/sly

/**
 * Despliega las fotos de naturalista
 */
var fotosNaturalista = function()
{
    $.ajax(
        {
            url: opciones.naturalista_api,
            type: 'GET',
            dataType: 'json'
        }).done(function (json) {
        if (jQuery.isEmptyObject(json)) {
            fotosBDI();
        } else {

            if (json.total_results == 0) {
                fotosBDI();
            } else if (json.results[0].taxon_photos.length == 0) {
                fotosBDI();//TODO PONER CAJAS FIJAS, EN EL EVENTO DONE RELLENAR LOS BACKGROUND
            } else {
                $.ajax(
                    {
                        url: '/especies/' + opciones.taxon + '/fotos-referencia',
                        type: 'POST',
                        data: {
                            fotos: JSON.stringify(json.results[0].taxon_photos.slice(0, 5))
                        }
                    }).done(function (fotos) {
                    if (jQuery.isEmptyObject(opciones.geodatos)){}
                    //$('#contenedor_fotos').removeClass().addClass('col-xs-8 col-sm-8 col-md-8 col-lg-8 col-xs-offset-2 col-sm-offset-2 col-md-offset-2 col-lg-offset-2');
                    else {
                        //$('#contenedor_fotos').removeClass().addClass('col-xs-12 col-sm-10 col-md-5 col-lg-5 col-xs-offset-0 col-sm-offset-1 col-md-offset-0');
                        $('#contenedor_mapa').removeClass().addClass('row');
                    }

                    $('#contenedor_fotos').html(fotos);
                    //inicia_carrusel();

                    $('#especies-destacadas .col').hover(function(){$(this).toggleClass('col-7')});
                    $('#especies-destacadas').hover(function(){$('#especies-destacadas div.col:first-of-type').toggleClass('col-6')});
                }).fail(function (error) {
                    fotosBDI();
                });
            }
        }
    }).fail(function (error) {
        fotosBDI();
    });
};

/**
 * Despliega las fotos de BDI
 */
var fotosBDI = function()
{
    $.ajax(
        {
            url: opciones.bdi_api,
            type: 'GET',
            dataType: 'json'
        }).done(function (json) {
        if (jQuery.isEmptyObject(json)) {
            $('#contenedor_fotos').remove();
            if (jQuery.isEmptyObject(opciones.geodatos)) $('#sin_datos').html('Lo sentimos, pero no contamos con una imagen o geodato');
        } else {

            if (json.estatus == 'error') {
                $('#contenedor_fotos').remove();
                if (jQuery.isEmptyObject(opciones.geodatos)) $('#sin_datos').html('Lo sentimos, pero no contamos con una imagen o geodato');
            } else if (json.estatus == 'OK' && json.fotos.length == 0) {
                $('#contenedor_fotos').remove();
                if (jQuery.isEmptyObject(opciones.geodatos)) $('#sin_datos').html('Lo sentimos, pero no contamos con una imagen o geodato');
            } else {
                $.ajax(
                    {
                        url: '/especies/' + opciones.taxon + '/fotos-referencia',
                        type: 'POST',
                        data: {fotos: JSON.stringify(json.fotos.slice(0, 5))}
                    }).done(function (fotos) {
                    if (jQuery.isEmptyObject(opciones.geodatos)){}
                    //$('#contenedor_fotos').removeClass().addClass('col-xs-8 col-sm-8 col-md-8 col-lg-8 col-xs-offset-2 col-sm-offset-2 col-md-offset-2 col-lg-offset-2');
                    else {
                        //$('#contenedor_fotos').removeClass().addClass('col-xs-12 col-sm-10 col-md-5 col-lg-5 col-xs-offset-0 col-sm-offset-1 col-md-offset-0');
                        $('#contenedor_mapa').removeClass().addClass('col-xs-12');
                    }

                    $('#contenedor_fotos').html(fotos);
                    $('#especies-destacadas .col').hover(function(){$(this).toggleClass('col-5')});
                    $('#especies-destacadas').hover(function(){$('#especies-destacadas div.col:first-of-type').toggleClass('col-4')});
                    //inicia_carrusel();
                }).fail(function (error) {
                    $('#contenedor_fotos').remove();
                    if (jQuery.isEmptyObject(opciones.geodatos)) $('#sin_datos').html('Lo sentimos, pero aún no contamos con una imagen o geodato');
                });
            }
        }
    }).fail(function (error) {
        $('#contenedor_fotos').remove();
        if (jQuery.isEmptyObject(opciones.geodatos)) $('#sin_datos').html('Lo sentimos, pero hubo un error al cargar las fotos');
    });
};

/**
 * Inicializa el carrusel en las imagenes principales
 */
var inicia_carrusel = function()
{
    //Para que la imagen inicial no se desborde antes de que inicie el carrusel:
    $('#foto-carrusel-interna').css('max-height', $('#contenedor_fotos').height() - 100 - $('#foto-carrusel > p').height());

    var sly = new Sly('#carrusel', {
        horizontal: 1,
        // Item based navigation //
        itemNav: 'centered',
        smart: 1,
        activateOn: 'click',
        // Scrolling //
        scrollSource: '#carrusel',
        scrollBy: 1,
        // Dragging //
        mouseDragging: 1,
        touchDragging: 1,
        elasticBounds: 1,
        startAt: 0,
        // Scrollbar //
        // Pagesbar //
        // Navigation buttons //
        // Automated cycling //
        cycleBy: 'items',
        cycleInterval: 6000,
        pauseOnHover: 1,
        // Mixed options //
        // Classes //
        activeClass: 'seleccionada'
    }).init();

    //En el evento de que una foto se convierte en activa, se modifica la foto central
    sly.on('active', function (eventName) {
        //Para cambiar la foto interna y establecer el tamaño máximo
        $('#foto-carrusel-interna').attr('src', $('img.seleccionada').attr('data-large')).css('max-height', $('#contenedor_fotos').height() - 100 - $('#foto-carrusel > p').height());
        // Para cambiar la atribucion de la foto (créditos) tanto en texto, como en ligas
        $('#foto-atribucion').html($('img.seleccionada').attr('data-attribution'));
        $('.enlace-atribucion').attr('href', $('img.seleccionada').attr('data-native-page-url'));
    });

    $(window).resize(function (e) {
        $('#carrusel').sly('reload');
    });

    if(!jQuery.isEmptyObject(opciones.geodatos)){
        ponTamaño();
    }
};
