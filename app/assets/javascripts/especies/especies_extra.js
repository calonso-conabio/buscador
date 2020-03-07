// REVISADO: Para desplegar o contraer el arbol identado en ficha de la espcie
var despliegaOcontrae = function(elemento)
{
    var id = elemento.attr('taxon_id');
    var ul = $('#ul_' + id);
    var hijos = $('#ul_' + id).children().children('ul');

    if (hijos.size() > 0)  // Existe algun hijo
    {
        var minus = $('#span_' + id).hasClass("fa-minus");

        if (minus)
            $('#span_' + id).removeClass("fa-minus").addClass("fa-plus");

        hijos.remove();

    } else {
        $.ajax(
            {
                url: "/especies/" + id + "/arbol_identado_hojas"
            }).done(function(lista)
        {
            if (lista != '')
            {
                var plus = $('#span_' + id).hasClass("fa-plus");

                if (plus)
                    $('#span_' + id).removeClass("fa-plus").addClass("fa-minus");

                hijos.remove();
                $(elemento).parent().append(lista);
            }
        });
    }
};

$(document).ready(function(){
    tooltip();
    refreshMediaQueries();

    $('#pestañas > .nav a').one('click',function(){
        if (!Boolean($(this).hasClass('noLoad'))){
            var idPestaña = $(this).data('params') || this.getAttribute('href').replace('#','');
            var pestaña = '/especies/' + opciones.taxon + '/'+idPestaña;
            $(this.getAttribute('href')).load(pestaña, function () {
                if (idPestaña == 'descripcion_catalogos') $('.biblio-cat').popover({html: true});
            });
        }
    });

    if (opciones.naturalista_api != undefined) fotosNaturalista(); else fotosBDI();

    $('#nombres_comunes_todos').load("/especies/" + opciones.taxon + "/nombres-comunes-todos");

    $('#enlaces_externos').on('click', '#boton_pdf', function(){
        window.open("/especies/" + opciones.taxon + ".pdf?from=" + opciones.cual_ficha);
    });

    $(document).on('click', '.historial_ficha', function(){
        var comentario_id = $(this).attr('comentario_id');
        var especie_id = $(this).attr('especie_id');
        $("#historial_ficha_" + comentario_id).load("/especies/" + especie_id + "/comentarios/" + comentario_id + "/respuesta_externa?ficha=1");
        $("#historial_ficha_" + comentario_id).slideDown();
        return false;
    });
    $("html,body").animate({scrollTop: 127}, 500);

    $('#arbol').on('click', '.sub_link_taxon', function(){
        despliegaOcontrae($(this));
        return false;
    });
});