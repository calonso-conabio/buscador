$('form').on('focus', '.ncient-soulmate', function () {
    var events = $._data( $(this)[0], "events" );

    if (events === undefined)
        soulmateAsigna('admin/catalogos', $(this).attr('id'));
});

$('form').on('focus', '.biblio-autocomplete', function () {
    var instancia = $(this).autocomplete( "instance" );
    if (instancia !== undefined) return;

    var biblio_id = '#' + $(this).attr('id');
    var bibliografia_id = biblio_id.replace(/_biblio$/, '_bibliografia_id');

    $(this).autocomplete({
        minLength: 2,
        source: function( request, response ) {
            $.getJSON( "/admin/bibliografias/autocompleta", request, function( data, status, xhr ) {
                response( data );
            });
        },
        select: function( event, ui ) {
            $(bibliografia_id).val(ui.item.value);
            $(biblio_id).val(ui.item.label);
            return false;
        }
    });
});

$('form').on('focus', '.reg-autocomplete', function () {
    var instancia = $(this).autocomplete( "instance" );
    if (instancia !== undefined) return;

    var reg_id = '#' + $(this).attr('id');
    var region_id = reg_id.replace(/_reg$/, '_region_id');

    $(this).autocomplete({
        minLength: 2,
        source: function( request, response ) {
            $.getJSON( "/admin/regiones/autocompleta", request, function( data, status, xhr ) {
                response( data );
            });
        },
        select: function( event, ui ) {
            $(region_id).val(ui.item.value);
            $(reg_id).val(ui.item.label);
            return false;
        }
    });
});

$('form').on('change', '.select-nivel', function () {
    var nivel_id = '#' + $(this).attr('id');
    var nivel = parseInt(nivel_id.slice(-1));

    // Pone vacios los select de niveles inferiores al escogido
    for(var i=nivel+1; i < 6; i++)
    {
        var nivel_siguiente_id = nivel_id.replace(nivel, i);
        $(nivel_siguiente_id).find('option').not(':first').remove();
    }

    // Obtiene los valores de los select superiores al escogido
    var params = {};
    params.nivel = nivel;

    for(var n=nivel; n > 0; n--)
    {
        var nivel_anterior_id = nivel_id.replace(nivel, n);
        var nivel_anterior = parseInt(nivel_anterior_id.slice(-1));
        params["nivel"+nivel_anterior] = $(nivel_anterior_id).val();
    }

    // Llena las opciones del siguiente nivel
    $.ajax({
        url: "/admin/catalogos/dame_nivel",
        method: "GET",
        data: params,
        dataType: "json"

    }).done(function(json) {
        if (json.estatus && json.resultados != undefined && json.resultados.length > 0 && nivel > 0 && nivel <= 4)
        {
            var nivel_siguiente_id = nivel_id.replace(nivel, nivel+1);

            for(var cat of json.resultados)
                $(nivel_siguiente_id).append($("<option>", { value: cat[1], text: cat[0] }));
        }
    }).fail(function () {
        console.log("ERROR");
    });

});