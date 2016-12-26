$( document ).ready(function() {
     var modal = $('.modal');
     var span = modal.find('.close');
     span.click(function() {
       modal.hide();
     });
     window.onclick = function(e) {
       e.preventDefault();
         if (e.target.classList == 'modal') {
            modal.hide();
         }
     }

     $(modal).show().appendTo('body');
});
