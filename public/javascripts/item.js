var showAndHideAnnotations = function() {
  $('.bridgeEmbed__item-comments .title').on("click", function() {
    $(this).siblings().toggle();
    $(this).toggleClass('open');
  });
};

var closeAnnotations = function(annotations) {
  $(annotations).siblings().hide();
  $(annotations).removeClass('open');
};

var changeLanguageSelected = function() {
  $('.bridgeEmbed__item-translation-languages span').on("click", function() {
    var translationAndComment = $(this).parent().siblings('.bridgeEmbed__item-translation-and-comment');
    var cardContainer = $(this).parent().siblings('.bridgeEmbed__item-embedly-card-container');

    if ($(this).hasClass('source-lang')) {
      $(cardContainer).insertBefore($(translationAndComment));
    } else {
      $(translationAndComment).insertBefore($(cardContainer));
    }
    $(this).toggleClass('active');
    $(this).siblings().toggleClass('active');
    var annotations = $(translationAndComment).find('.bridgeEmbed__item-comments .title');
    closeAnnotations(annotations);
  });
};

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
  $('body').attr('id', 'bridge__project')
}

$(document).ready(function() {
  itemAsModal();
  showAndHideAnnotations();
  changeLanguageSelected();
});
