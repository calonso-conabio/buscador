/*********************************************************************************************************************************/
// Modal
$(document).ready(function(){

    // Acción a ejecutar al reproducir una modal
    $('#modal-media-content').on('show.bs.modal', function (event) {
        var button = $(event.relatedTarget); // Botón que dispara el modal, contiene la información a pegar en el modal
        var media;
        var contenType = button.data('type');

        $('#modal_title').text(button.data('title'));

        switch(contenType) {
            case 'imagen':
                //media = $(document.createElement("img")).addClass('img-responsive').attr('src', button.data('url'));
                /* OPCIÓN 2: Imágen como fondo de un div del tamaño del contenedor */
                media = $(document.createElement("div"));
                media.css({
                    'width' : '100%',
                    'height' : '100%',
                    'background' : 'url(' + button.data('url') +')',
                    'background-size': 'contain',
                    'background-position': 'center center',
                    'background-repeat':'no-repeat'
                });
                // Opcoón 2.2: en base al tamaño de la imágen determinar la altura del modal
                resizeImgContainer(button.data('url'));
                break;

            case 'youtube':
                $("#modal-media-content_body").removeAttr("style")
                var vidContainer = $(document.createElement("div")).addClass('embed-responsive embed-responsive-16by9')
                media = vidContainer.append(button.data('url'));
                break;

            case 'video':
                $("#modal-media-content_body").removeAttr("style")
                var vidContainer = $(document.createElement("div")).addClass('embed-responsive embed-responsive-16by9');
                var video = $(document.createElement("video")).attr('controls','').attr('controlsList', 'nodownload').attr('autoplay','');
                var source = $(document.createElement("source")).attr('src', button.data('url'));
                video.append(source);
                media = vidContainer.append(video);
                break;
        }

        $('#modal-media-content_body').append(media);

    });

    //Eliminar contenido del modal-body (necesario para q deje de reproducirse el video/audio cuando se cierra modal)
    $('#modal-media-content').on('hide.bs.modal', function(){$('#modal-media-content_body').empty()});

    $('.img-responsive').addClass('img-fluid');
});

function resizeImgContainer(url_img) {
    var height = 0;
    var width = 0;
    var img = new Image();
    var windowSpace = $(window).height() * 0.75; // Obtener el 75% de la pantalla

    img.src = url_img;
    img.onload = function() {
        height = img.height;
        width = img.width;

        // Verificar el tamaño en alto de la imagen:
        if(height >= windowSpace) {
            // Si es más grande que el alto del navegador, usar el alto de el tamaño el navegador para el contenedor
            $("#modal-media-content_body").css("height", windowSpace);
            // Si la imágen es alta
            if(height > width) {
                // Usar el ancho "autómatico"
                $("#modalTamanio").css("width",  "");
            } else {
                // Si es ancha, ocupar el 80% de la pantalla para mostrarla
                $("#modalTamanio").css("width",  "80%");
            }

        } else {
            // Si es menor al tamaño del navegador, usar el alto de la imagen para el contenedor
            $("#modal-media-content_body").css("height", height);
            // Si la imágen es alta
            if(height > width) {
                // Usar el ancho "autómatico"
                $("#modalTamanio").css("width",  "");
            } else {
                // Si es ancha, ocupar el 80% de la pantalla para mostrarla
                $("#modalTamanio").css("width",  width);
            }
        }
    };
}


/*********************************************************************************************************************************/
// When the user scrolls down 20px from the top of the document, show the button
window.onscroll = function() {scrollFunction()};

function scrollFunction() {
    if (document.body.scrollTop > 20 || document.documentElement.scrollTop > 20) {
        document.getElementById("upBtn").style.display = "block";
    } else {
        document.getElementById("upBtn").style.display = "none";
    }
}

// When the user clicks on the button, scroll to the top of the document
function topFunction() {
    document.body.scrollTop = 0; // For Safari
    document.documentElement.scrollTop = 0; // For Chrome, Firefox, IE and Opera
};


/*********************************************************************************************************************************/
/* Fuente typekit (Adobe) */
try{
    Typekit.load({async: true});
}catch(e) {
}
