var itemAsModal = function() {
  if (Bridge.item != '') {
    var modal = $('.modal');
    openModal(modal);

    var span = modal.find('.close');
    span.click(function() {
      closeModal(modal);
    });
    window.onclick = function(e) {
      e.preventDefault();
        if (e.target.classList == 'modal') {
           closeModal(modal);
        }
    }
  }
};


var openModal = function(modal) {
  $(modal).show().appendTo('body');
  $('body').addClass('modal-active');
}

var closeModal = function(modal) {
  $(modal).hide();
  $('body').removeClass('modal-active');
}


$(document).ready(itemAsModal);
