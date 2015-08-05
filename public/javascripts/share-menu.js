/*jslint nomen: true, plusplus: true, todo: true, white: true, browser: true, indent: 2 */

(function($) {
  'use strict';

  $(document).ready(function() {
    // Expand share menu

    $('.bridgeEmbed__share').on('click', function() {
      $(this).toggleClass('bridgeEmbed__share-expanded');
      $(this).next('.bridgeEmbed__share-menu').toggleClass('bridgeEmbed__share-menu-expanded');
      return false;
    });

    // Expand embed code

    $('.bridgeEmbed__link-embed-code').on('click', function() {
      $(this).next('textarea').toggleClass('bridgeEmbed__embed-code-expanded');
      return false;
    });
  });

}(jQuery));
