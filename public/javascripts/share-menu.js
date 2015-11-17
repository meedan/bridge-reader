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
      $(this).next('.embed-code-holder').toggleClass('embed-code-holder-expanded');
      return false;
    });

    var clipboard = new Clipboard('.btn');

    clipboard.on('success', function(e) {
        console.log(e);
    });

    clipboard.on('error', function(e) {
        console.log(e);
    });


  });

}(jQuery));
