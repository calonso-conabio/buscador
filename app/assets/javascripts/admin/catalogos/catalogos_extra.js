$('form').on('focus', '.ncient-soulmate', function () {
    var events = $._data( $(this)[0], "events" );

    if (events === undefined)
        soulmateAsigna('admin/catalogos', $(this).attr('id'));
});
