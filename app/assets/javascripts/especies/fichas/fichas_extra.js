$(document).ready(function() {
    $('#taxon_description').on('change', '#from', function () {
        opciones.cual_ficha = $(this).val();

        $.ajax({
            url: "/especies/" + opciones.taxon + "/describe?from=" + opciones.cual_ficha,
            method: 'get',
            success: function (data, status) {
                $('.taxon_description').replaceWith(data);
            },
            error: function (request, status, error) {
                $('.taxon_description').loadingShades('close');
            }
        });
    });

    // Función para mostrar más detalles de una ficha en particular haciendo una llamada al servicio Bioteca
    $('#describe').off('click').on('click', "[id^='ficha_']", function () {
        var idFicha = $(this).attr('id').replace("ficha_", "");
        var detalleEstaVacio =  $('#detalle_' + idFicha).is(':empty');

        if (detalleEstaVacio) {
            jQuery.ajax({
                success: function(html){
                    $('#detalle_' + idFicha).html(html);
                },
                fail: function(){
                    $('#detalle_' + idFicha).html('Hubo un error al cargar los datos, por favor intentalo de nuevo.');
                },
                method: 'get',
                url: '/registro_bioteca/' + idFicha
            });

            // Si el detalle está vacío, asumimos que siempre aparecerá: Ver menos detalles
            $("#ficha_" + idFicha).html("<i class='glyphicon glyphicon-minus-sign'></i> Ver menos detalles");

        } else {

            if( $('#detalle_' + idFicha).hasClass( "detalle-oculto" ) ) {
                $("#ficha_" + idFicha).html("<i class='glyphicon glyphicon-minus-sign'></i> Ver menos detalles");
            } else {
                $("#ficha_" + idFicha).html("<i class='glyphicon glyphicon-plus-sign'></i> Ver mas detalles");
            }
            $('#detalle_' + idFicha).toggleClass("detalle-oculto");
        }

        return false;
    });
});

// Función para llamar a la siguiente página desde botón siguiénte / atrás
var biotecaCurrentPage = 1;
var biotecaLastPage = 99;

function changePage(taxon, tipo, action) {
    // Calcular página siguiente
    if (action === "siguiente") {
        if (biotecaCurrentPage < biotecaLastPage )
            biotecaCurrentPage += 1;
    } else {
        if (biotecaCurrentPage >= 2)
            biotecaCurrentPage -= 1;
        else
            biotecaCurrentPage = 1
    }
    biotecaLoadPage(taxon, tipo, biotecaCurrentPage)
}

// Función para cargar siguientes páginas de bioteca
function biotecaLoadPage(taxon, tipo, page) {
    // Primero, verificamos la página en la que se encuentra
    var paginaEstaVacia =  $('#janium_records-' + tipo + '-page-' + page).is(':empty');
    $('.page-item').removeClass("active");
    $("#button-janium_records-" + page).addClass("active");

    // Si está vacía, hayq ue invocar al servicio web para agregare la info
    if (paginaEstaVacia) {
        jQuery.ajax({
            success: function(html){
                $('#janium_records-' + tipo + '-page-' + page).html(html);
            },
            fail: function(){
                $('#janium_records-' + tipo + '-page-' + page).html('Hubo un error al cargar los datos, por favor intentalo de nuevo.');
            },
            method: 'get',
            url: '/registros_bioteca/' + taxon + '/find_by=' + tipo + '/page=' + page
        });

        $('.janium_records_' + tipo).addClass("janium_records-not-show");
        $('#janium_records-' + tipo + '-page-' + page).removeClass("janium_records-not-show");

    } else {
        $('.janium_records_' + tipo).addClass("janium_records-not-show");
        // Si no está vacia, sólo hay que mostrar el div
        $('#janium_records-' + tipo + '-page-' + page).removeClass("janium_records-not-show");
    }

    // Control de botón: "Anterior"
    if ( biotecaCurrentPage === 1)
        $('#button-janium-before').addClass("disabled");
    else
        $('#button-janium-before').removeClass("disabled");

    // Control de botón: "Siguiente"
    if ($('#button-janium_records-' + page ).hasClass('last')) {
        biotecaLastPage = parseInt(page);
        $('#button-janium-next').addClass("disabled");
    } else {
        $('#button-janium-next').removeClass("disabled");
    }

    biotecaCurrentPage = parseInt(page);
}

// Cambiar el tipo de búsqueda: por nombre científico o por nombre común
function changeTBusqueda(tipo, taxon) {
    //Verifica si se ha hecho ya la consulta
    var paginaEstaVacia =  $('#busqueda-' + tipo).is(':empty');

    // Si está vacía, hay que invocar al servicio web para agregare los resultados
    if (paginaEstaVacia) {
        jQuery.ajax({
            success: function(html){
                $('#busqueda-' + tipo).html(html);
            },
            fail: function(){
                $('#busqueda-' + page).html('Hubo un error al cargar los datos, por favor intentalo de nuevo.');
            },
            method: 'get',
            url: '/registros_bioteca/' + taxon + '/find_by=' + tipo
        });
    }

    // En cuenlquier caso, hay que marcar y mostrar sólo la pestaña seleccionada
    $('.busqueda-item').removeClass("active");
    $("#item-busqueda-" + tipo).addClass("active");
    $('.bioteca-records').css("display", "none");
    $('#busqueda-' + tipo).css("display", "table");
}
