/*jslint nomen: true, plusplus: true, todo: true, white: true, browser: true, indent: 2 */

// This happens on the child window
var Bridge = {};

(function($) {
  'use strict';

  // Add custom CSS
  var css = document.location.hash.replace('#css=', '');
  if (css !== '') {
    $('head').append('<link rel="stylesheet" href="' + css + '" type="text/css" class="bridgembed-custom-css" />');
    $('meta[name="twitter:image"]').attr('content', function(index, attr) {
      return attr + '?css=' + css;
    });
  }

  // Alert parent window when the height changes
  var htmlHeight = 0;
  if (!Bridge.path) {
    Bridge.path = document.location.pathname.replace('/medias/embed/', '').replace('/', '-');
  }
  var checkHTMLHeight = function() {
    var height = document.getElementsByTagName('BODY')[0].offsetHeight;
    if (height !== htmlHeight) {
      htmlHeight = height;
      window.parent.postMessage(['setHeight', Bridge.path, htmlHeight].join(';'), '*');
    }
    setTimeout(checkHTMLHeight, 100);
  };
  
  var isElementOnViewPort = function(el, data) {
    var rect = el.getBoundingClientRect(),
        h = data[0], w = data[1], tp = data[2], left = data[3];

    var offset = 500;

    return (
      rect.top + tp >= 0 &&
      rect.left + left >= 0 &&
      rect.bottom + tp <= (h + offset) &&
      rect.right + left <= w
    );
  };
  
  var lazyLoad = function(data) {
    $('.bridgeEmbed__item-pender-card').each(function() {
      var $that = $(this);
      if (!$that.hasClass('rendered') && isElementOnViewPort($that[0], data)) {
        $that.addClass('rendered');
        var script = document.createElement('script');
        script.type = 'text/javascript'; 
        script.src = $that.attr('data-src');
        script.async = true;
        $that[0].parentNode.insertBefore(script, $that[0]);
      }
    });
  };
  
  var messageCallback = function(e) {
    var data = e.data.toString().split(';'),
        type = data.shift();
  
    for (var i = 0; i < data.length; i++) {
      data[i] = parseInt(data[i], 10);
    }
  
    switch (type) {
      // Lazy load
      case 'lazyLoad':
        lazyLoad(data);
        break;
    }
  };
  
  var resizeOrScrollCallback = function() {
    var h = window.innerHeight || document.documentElement.clientHeight,
        w = window.innerWidth || document.documentElement.clientWidth,
        data = [h, w, 0, 0, 0, 0];
    lazyLoad(data);
  };
  
  if (!window.addEventListener) {
    window.attachEvent('onmessage', messageCallback);
    if (window === window.parent) {
      window.attachEvent('onscroll', resizeOrScrollCallback);
      window.attachEvent('onresize', resizeOrScrollCallback);
      window.attachEvent('onload', resizeOrScrollCallback);
    }
    window.attachEvent('onload', checkHTMLHeight);
  }
  else {
    window.addEventListener('message', messageCallback, false);
    if (window === window.parent) {
      window.addEventListener('scroll', resizeOrScrollCallback, false);
      window.addEventListener('resize', resizeOrScrollCallback, false);
      window.addEventListener('load', resizeOrScrollCallback, false);
    }
    window.addEventListener('load', checkHTMLHeight, false);
  }
}(jQuery));
