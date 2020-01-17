/**
 * Funcion para atachar que una caja de texto tenga funcionamiento con soulmate y redis
 * @param tipo_busqueda
 */
var soulmateAsigna = function(tipo_busqueda, elem)
{
    if (elem == undefined)
        var elemento = 'nombre';
    else
        var elemento = elem;

    var render = function(term, data, type, index, id)
    {
        if (I18n.locale == 'es-cientifico')
        {
            var nombres = '<h5> ' + data.nombre_comun + '</h5>' + '<h5><a href="" class="not-active">' + data.nombre_cientifico + ' </a><i>' + data.autoridad + '</i></h5><h5>&nbsp;</h5>';
            return nombres;
        }else{
            data.nombre_cientifico = limpiar(data.nombre_cientifico);
            
            if(data.nombre_comun == null) {
                var nombres = '<a href="" class="not-active">' + data.nombre_cientifico + '</a>';
            }else {
                var nombres = '<b>' + primeraEnMayuscula(data.nombre_comun) + ' </b><sub>' + data.lengua + '</sub><a href="" class="not-active">' + data.nombre_cientifico + '</a>';
            }

            if(data.foto == null) {
                var foto = '<i class="soulmate-img ev1-ev-icon pull-left"></i>';
            }else{
                var foto_url = data.foto;
                var foto = "<i class='soulmate-img pull-left' style='background-image: url(\"" + foto_url + "\")';></i>";
            }

            var iconos = "";
            var ev = '-ev-icon';

            $.each(data.cons_amb_dist, function(i, val){
                if (i == 'no-endemica' || i =='actual') return true;
                iconos = iconos + "<span class='btn-title' tooltip-title='" + val + "'><i class='" + i + ev +"'></i></span>"
            });

            if(data.geodatos != undefined && data.geodatos.length > 0){
                iconos = iconos + "<span class='btn-title' tooltip-title='Tiene datos geográficos'><i class='glyphicon glyphicon-globe'></i></span>";
            }

            if(data.fotos > 0) {
                iconos = iconos + "<span class='btn-title' tooltip-title='Tiene imágenes'><i class='picture-ev-icon'></i><sub>" + data.fotos + "</sub></span>";
            }

            return foto + " " + nombres + "<h5 class='soulmate-icons'>" + iconos + "</h5>";
        }
    };

    var select = function(term, data, type)
    {
        $('#' + elemento).val(term);
        $('ul#soulmate').hide();    // esconde el autocomplete cuando escoge uno

        switch (tipo_busqueda){
            case 'avanzada':
                cat_tax_asociadas(data.id);  // despliega las categorias taxonomicas asociadas al taxon
                $('#id').attr('value', data.id); //TODO arreglar el ID id ¬.¬ !>.> pffff
                break;
            case 'peces':
                $('#id').attr('value', data.id);
                bloqueaBusqueda();
                break;
            case 'pmc_new':
                $('#pmc_pez_especie_id').attr('value', data.id);
                break;
            case 'soloAsigna':
                $('#id').attr('value', data.id); //TODO arreglar el ID id ¬.¬ !>.> pffff
                break;
            case 'metamares':
                $('#proy_b_especie_id').attr('value', data.id); // feliz?
                break;
            case 'metamares_proy_esp':
                $('#'+elemento.replace('nombre_cientifico','especie_id')).attr('value', data.id);
                break;
            case 'admin/catalogos':
                $('#'+elemento.replace('nombre_cientifico','especie_id')).attr('value', data.id);
                break;
            default:
                // Para no pasar por el controlador de busquedas, ir directo a la especie, solo busqueda basica
                var nom_cientifico = data.nombre_cientifico.trim().toLowerCase().replace(/[^a-z0-9]+/g,'-').replace(/(^-|-$)/g,'').replace(/[\(\)]/g, '');
                window.location.replace('/especies/'  + data.id + '-' + nom_cientifico);
                $('#id').attr('value', data.id); //TODO arreglar el ID id ¬.¬ !>.> pffff
        }
    };

    $('#' + elemento).soulmate({
        url:            "http://"+ IP + ":" + PORT + "sm/search",
        types:          TYPES,
        renderCallback: render,
        selectCallback: select,
        minQueryLength: 2,
        maxResults:     5,
        timeout:        3500
    });
};