/**
 * Quita parametros de la URL actual
 * @param sParam
 * @returns {string}
 */
var quitaParametros = function(sParam)
{
    var url = window.location.href.split('?')[0]+'?';
    var sPageURL = decodeURIComponent(window.location.search.substring(1)),
        sURLVariables = sPageURL.split('&'),
        sParameterName,
        i;

    for (i = 0; i < sURLVariables.length; i++) {
        sParameterName = sURLVariables[i].split('=');
        if (sParameterName[0] != '')
            url = url + sParameterName[0] + '=' + sParameterName[1] + '&';
    }

    return url.substring(0,url.length-1);
};

/**
 * Para el pagiando con de metamares
 * @param paginas
 * @param pagina
 */
var paginadoMetamares = function(paginas, pagina)
{
    href = quitaParametros('pagina');
    var url = href.split('/').pop();

    if (url == 'proyectos')
        var param = '?';
    else
        var param = '&';

    $('.paginado-metamares').bootpag({
        total: paginas,          // total pages
        page: pagina,            // default page
        maxVisible: 5,     // visible pagination
        leaps: true,         // next/prev leaps through maxVisible
        firstLastUse: true,
        first: '←',
        last: '→'
    }).on("page", function(event, /* page number here */ num){
        window.location.replace(href + param + "pagina=" + num);
    });
};

/**
 * Autocompleta la institucion
 */
var dameInstitucion = function ()
{
    $("#metamares_proyecto_nom_institucion").autocomplete({
        source: function( request, response ) {
            $.ajax( {
                url: "/metamares/dame-institucion.json",
                dataType: "json",
                data: {
                    nombre_institucion: request.term
                },
                success: function( data ) {
                    response( data );
                }
            } );
        },
        minLength: 2,
        select: function( event, ui ) {
            $('#metamares_proyecto_institucion_id').val(ui.item.id);
            $("#institucion :input").attr("disabled", true);
        }
    });
};

/**
 * Desvincula el record en la interfaz
 */
var desvinculaInstitucion = function ()
{
    $('#desvincula_inst').on('click', function () {
        $('#metamares_proyecto_institucion_id').val('');
        $("#institucion :input").attr("disabled", true);
        $("#metamares_proyecto_nom_institucion").val('');
        return false;
    });
};

/**
 * Autocompleta el keyword
 */
var dameKeyword = function (keyword)
{
    keyword.autocomplete({
        source: function( request, response ) {
            $.ajax( {
                url: "/metamares/dame-keyword.json",
                dataType: "json",
                data: {
                    nombre_keyword: request.term
                },
                success: function( data ) {
                    response( data );
                }
            } );
        },
        minLength: 2,
        select: function( event, ui ) {
            keyword.val(ui.item.id);

        }
    });
};

$(document).on('focus', '[id^=metamares_proyecto_especies][id$=_nombre_cientifico]', function() {
    $('[id^=metamares_proyecto_especies][id$=_nombre_cientifico]').off();
    soulmateAsigna('metamares_proy_esp', this.id);
});