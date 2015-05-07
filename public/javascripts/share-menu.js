/*jslint nomen: true, plusplus: true, todo: true, white: true, browser: true, indent: 2 */

(function($) {
  'use strict';

  $(document).ready(function() {
    // Expand share menu

    $('.bridgeEmbed__share-menu').hide();
    $('.bridgeEmbed__share').on('click', function() {
      $(this).toggleClass('expanded');
      $(this).next('.bridgeEmbed__share-menu').slideToggle();
      return false;
    });

    // Expand embed code

    $('.bridgeEmbed__embed-code').hide();
    $('.bridgeEmbed__link-embed-code').on('click', function() {
      $(this).next('textarea').slideToggle();
      return false;
    });
  });

}(jQuery));
