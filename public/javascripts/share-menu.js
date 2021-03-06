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

    // Copy to clipboard

    var clipboard = new window.Clipboard('.btn');
    clipboard.on('error', function(e) {
      console.log(e);
      window.alert('Please manually select the link inside the text box to copy and paste. Your browser does not support Click To Copy.');
    });


  });

}(jQuery));
