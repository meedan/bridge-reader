(function($) {
$(document).ready( function(){
    $('.btn-newsletter').click( function(event){
        event.stopPropagation();
        $('.newsletter-menu').toggle();
    });

    $('body').click(function(event) {
    if (!$(event.target).closest('.newsletter-menu').length) {
        $('.newsletter-menu').hide();
    }
    });

});

}(jQuery));
