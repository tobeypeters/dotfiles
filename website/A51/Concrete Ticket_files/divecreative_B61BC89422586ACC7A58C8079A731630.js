
/**
 * Wrapper for the Bing Maps 7.0 API
 * Reference: http://msdn.microsoft.com/en-us/library/gg427606.aspx
 * 
 *  - Looks for a div with id "map-display". If it exists, it dynamically places a Bing map
 *  - Looks for a Javascript object named "mapDisplayConfig" for location and places data 
 * 
 * Example:
 * var mapDisplayConfig = {
 *   center: [47.592, -122.332],
 *   pins: [{
 *     location: [47.592, -122.332],
 *   }, {
 *     location: [47.592, -122.332],
 *   }]
 * }
 */

var irth = irth || {};
var mapDisplayConfig = mapDisplayConfig || null;
irth.MapDisplay = function() {
  
  this.init = function() {
    // Please replace this with your own Bing Maps Key - this one expires after 90 days.
    this.bingMapsKey = "AnXnx5ERM-PhTT-kRGEMjmkQcWpuc1PWa5EtNyI3xTaJmM4hRgL0HM-M0RzLTru2";
      
    this.canvas = $('#map-display');
    
    if(this.canvas.length > 0 && mapDisplayConfig) {
      this.map = new Microsoft.Maps.Map(this.canvas[0], {credentials:this.bingMapsKey});
      
      if(mapDisplayConfig.center) {
        this.center(mapDisplayConfig.center[0], mapDisplayConfig.center[1]);
      }
      
      if(mapDisplayConfig.pins) {
        var i = 0, length=mapDisplayConfig.pins.length, pin;
        for(; i<length; i++) {
          pin = mapDisplayConfig.pins[i];
          this.addPin(pin.location[0], pin.location[1]);
        }
      }
    }
  };
  
  this.addPin = function(latitude, longitude) {
    // Define the pushpin location
    var location = new Microsoft.Maps.Location(latitude, longitude);
    
    // Add a pin to the map
    var pin = new Microsoft.Maps.Pushpin(location); 
    this.map.entities.push(pin);
  };
  
  this.center = function(latitude, longitude) {
    var location = new Microsoft.Maps.Location(latitude, longitude);
    this.map.setView({center: location, zoom: 10});
  };
  
  this.resize = function() {
    var win = $(window);
    this.canvas.css({
      width: win.width()+'px',
      height: (win.height()-90)+'px'
    });
    //*/
  };
  
};
/**
 * Popover components.
 * 
 * Searches the page for popovers and adds interaction as needed.
 * Initialized in utilisphere.js
 */

var irth = irth || {};
irth.PopOver = function() {
  
  this.init = function() {
    this.activeNav = null;
    this.activeMenus = [];
    
    $('.popover-toggle').click($.proxy(this.onClickToggleButton, this));
  };
  
  this.onClickToggleButton = function(event) {
    var button = $(event.currentTarget);
    var contentId = button.attr('data-toggle');
    var nav = $('#'+contentId);
    
    if(nav.length > 0) {
      event.preventDefault();
      event.stopPropagation();
      
      var isOpen = nav.hasClass('open');
      if(isOpen === true) {
        this.closePopover();
      } else {
        this.openPopover(button, nav);
      }
    }
  };
  
  this.openPopover = function(button, nav) {
    this.activeNav = nav;
    
    $('.popover-sub-nav-link', nav).click($.proxy(this.onClickSubNavLink, this));
    $('.popover-action-close', nav).click($.proxy(this.onClickClose, this));
    $('.popover-action-back', nav).click($.proxy(this.onClickBack, this));
    
    var menu = $($('.popover-menu', nav)[0]);
    this.activeMenus = [menu];
    
    $('.popover-sub-menu', nav).removeClass('open');
    
    this.updateNavPosition();
    
    if(this.activeNav)
        this.activeNav.addClass('opening');

    setTimeout(function () {
        if (nav) {
            nav.addClass('open');
            nav.removeClass('opening');
        }
    }, 50);
    
    setTimeout(function () {
        if ($('body')) {
            $('body').addClass('noscroll');
        }
    }, 500);
  };
  
  this.closePopover = function () {
      if (this.activeNav) {
          this.activeNav.addClass('closing');
          this.activeNav.removeClass('open');

          var nav = this.activeNav;
          setTimeout(function () {
              nav.removeClass('closing');
          }, 500);

          this.activeNav = null;

          $('body').removeClass('noscroll');
      }
  };
  
  this.onClickSubNavLink = function(event) {
    var button = $(event.currentTarget);
    var contentId = button.attr('data-toggle');
    var subMenu = $(".popover-sub-menu[data-id='"+contentId+"']", this.activeNav);
    
    if(subMenu.length > 0) {
      event.preventDefault();
      event.stopPropagation();
      
      this.activeMenus.push(subMenu);
      
      subMenu.addClass('open');
      
      this.updateNavPosition();
    }
  };
  
  this.onClickBack = function(event) {
    event.preventDefault();
    event.stopPropagation();
    
    this.activeMenus.pop();
    this.updateNavPosition();
  };
  
  this.onClickClose = function(event) {
    event.preventDefault();
    event.stopPropagation();
    
    this.closePopover();
  };
  
  this.updateNavPosition = function() {
    var offset = -(this.activeMenus.length - 1)*$(window).width();
    
    $('.popover-menus', this.activeNav).css({
      '-webkit-transform': 'translateX('+offset+'px)',
      '-moz-transform': 'translateX('+offset+'px)',
      'transform': 'translateX('+offset+'px)'
    });
  };
  
};
/**
 * Slide navigation component.
 * 
 * Handles interaction for the menu button in the header, and the slide-in system tray. 
 * Initialized in utilisphere.js
 */

var irth = irth || {};
irth.SlideNav = function() {
  
  this.init = function() {
    this.menuButtonWidth = 48;
    this.maxMenuWidth = 290;
    
    this.canvas = $('#slide-nav');
    this.menu = $('.slide-menu', this.canvas);
    
    $('.navbar-toggle', this.canvas).click($.proxy(this.onClickMenuButton, this));
    
    $(window).resize($.proxy(this.resize, this));
    this.resize();
    
    this.menu.show();
  };
  
  this.onClickMenuButton = function(event) {
    event.preventDefault();
    event.stopPropagation();
    
    $('html').toggleClass('show-slide-nav');
    
    var expanded = $('html').hasClass('show-slide-nav');
    
    var offset = 0;
    if(expanded === true) {
      offset = $(window).width() - this.menuButtonWidth;
      offset = Math.min(offset, this.maxMenuWidth);
    }
  
    var css = {
      '-webkit-transform': 'translateX('+offset+'px)',
      '-moz-transform': 'translateX('+offset+'px)',
      '-ms-transform': 'translateX('+offset+'px)',
      'transform': 'translateX('+offset+'px)'
    };
    
    this.canvas.css(css);
    $('#page-content').css(css);
  };
  
  this.resize = function() {
    var menuWidth = $(window).width() - this.menuButtonWidth;
    menuWidth = Math.min(menuWidth, this.maxMenuWidth);
    var menuHeight = $(window).height();
    var css = {
      width: menuWidth+'px',
      height: menuHeight+'px',
      '-webkit-transform': 'translateX(-'+menuWidth+'px)',
      '-moz-transform': 'translateX(-'+menuWidth+'px)',
      '-ms-transform': 'translateX(-'+menuWidth+'px)',
      'transform': 'translateX(-'+menuWidth+'px)'
    };
    this.menu.css(css);
  };
  
};
/**
 * @preserve FastClick: polyfill to remove click delays on browsers with touch UIs.
 *
 * @version 1.0.2
 * @codingstandard ftlabs-jsv2
 * @copyright The Financial Times Limited [All Rights Reserved]
 * @license MIT License (see LICENSE.txt)
 */

/*jslint browser:true, node:true*/
/*global define, Event, Node*/


/**
 * Instantiate fast-clicking listeners on the specified layer.
 *
 * @constructor
 * @param {Element} layer The layer to listen on
 * @param {Object} options The options to override the defaults
 */
function FastClick(layer, options) {
  'use strict';
  var oldOnClick;

  options = options || {};

  /**
   * Whether a click is currently being tracked.
   *
   * @type boolean
   */
  this.trackingClick = false;


  /**
   * Timestamp for when click tracking started.
   *
   * @type number
   */
  this.trackingClickStart = 0;


  /**
   * The element being tracked for a click.
   *
   * @type EventTarget
   */
  this.targetElement = null;


  /**
   * X-coordinate of touch start event.
   *
   * @type number
   */
  this.touchStartX = 0;


  /**
   * Y-coordinate of touch start event.
   *
   * @type number
   */
  this.touchStartY = 0;


  /**
   * ID of the last touch, retrieved from Touch.identifier.
   *
   * @type number
   */
  this.lastTouchIdentifier = 0;


  /**
   * Touchmove boundary, beyond which a click will be cancelled.
   *
   * @type number
   */
  this.touchBoundary = options.touchBoundary || 10;


  /**
   * The FastClick layer.
   *
   * @type Element
   */
  this.layer = layer;

  /**
   * The minimum time between tap(touchstart and touchend) events
   *
   * @type number
   */
  this.tapDelay = options.tapDelay || 200;

  if (FastClick.notNeeded(layer)) {
    return;
  }

  // Some old versions of Android don't have Function.prototype.bind
  function bind(method, context) {
    return function() { return method.apply(context, arguments); };
  }


  var methods = ['onMouse', 'onClick', 'onTouchStart', 'onTouchMove', 'onTouchEnd', 'onTouchCancel'];
  var context = this;
  for (var i = 0, l = methods.length; i < l; i++) {
    context[methods[i]] = bind(context[methods[i]], context);
  }

  // Set up event handlers as required
  if (deviceIsAndroid) {
    layer.addEventListener('mouseover', this.onMouse, true);
    layer.addEventListener('mousedown', this.onMouse, true);
    layer.addEventListener('mouseup', this.onMouse, true);
  }

  layer.addEventListener('click', this.onClick, true);
  layer.addEventListener('touchstart', this.onTouchStart, false);
  layer.addEventListener('touchmove', this.onTouchMove, false);
  layer.addEventListener('touchend', this.onTouchEnd, false);
  layer.addEventListener('touchcancel', this.onTouchCancel, false);

  // Hack is required for browsers that don't support Event#stopImmediatePropagation (e.g. Android 2)
  // which is how FastClick normally stops click events bubbling to callbacks registered on the FastClick
  // layer when they are cancelled.
  if (!Event.prototype.stopImmediatePropagation) {
    layer.removeEventListener = function(type, callback, capture) {
      var rmv = Node.prototype.removeEventListener;
      if (type === 'click') {
        rmv.call(layer, type, callback.hijacked || callback, capture);
      } else {
        rmv.call(layer, type, callback, capture);
      }
    };

    layer.addEventListener = function(type, callback, capture) {
      var adv = Node.prototype.addEventListener;
      if (type === 'click') {
        adv.call(layer, type, callback.hijacked || (callback.hijacked = function(event) {
          if (!event.propagationStopped) {
            callback(event);
          }
        }), capture);
      } else {
        adv.call(layer, type, callback, capture);
      }
    };
  }

  // If a handler is already declared in the element's onclick attribute, it will be fired before
  // FastClick's onClick handler. Fix this by pulling out the user-defined handler function and
  // adding it as listener.
  if (typeof layer.onclick === 'function') {

    // Android browser on at least 3.2 requires a new reference to the function in layer.onclick
    // - the old one won't work if passed to addEventListener directly.
    oldOnClick = layer.onclick;
    layer.addEventListener('click', function(event) {
      oldOnClick(event);
    }, false);
    layer.onclick = null;
  }
}


/**
 * Android requires exceptions.
 *
 * @type boolean
 */
var deviceIsAndroid = (navigator.userAgent.indexOf('Android') > 0);


/**
 * iOS requires exceptions.
 *
 * @type boolean
 */
var deviceIsIOS = /iP(ad|hone|od)/.test(navigator.userAgent);


/**
 * iOS 4 requires an exception for select elements.
 *
 * @type boolean
 */
var deviceIsIOS4 = deviceIsIOS && (/OS 4_\d(_\d)?/).test(navigator.userAgent);


/**
 * iOS 6.0(+?) requires the target element to be manually derived
 *
 * @type boolean
 */
var deviceIsIOSWithBadTarget = deviceIsIOS && (/OS ([6-9]|\d{2})_\d/).test(navigator.userAgent);

/**
 * BlackBerry requires exceptions.
 *
 * @type boolean
 */
var deviceIsBlackBerry10 = navigator.userAgent.indexOf('BB10') > 0;

/**
 * Determine whether a given element requires a native click.
 *
 * @param {EventTarget|Element} target Target DOM element
 * @returns {boolean} Returns true if the element needs a native click
 */
FastClick.prototype.needsClick = function(target) {
  'use strict';
  switch (target.nodeName.toLowerCase()) {

  // Don't send a synthetic click to disabled inputs (issue #62)
  case 'button':
  case 'select':
  case 'textarea':
    if (target.disabled) {
      return true;
    }

    break;
  case 'input':

    // File inputs need real clicks on iOS 6 due to a browser bug (issue #68)
    if ((deviceIsIOS && target.type === 'file') || target.disabled) {
      return true;
    }

    break;
  case 'label':
  case 'video':
    return true;
  }

  return (/\bneedsclick\b/).test(target.className);
};


/**
 * Determine whether a given element requires a call to focus to simulate click into element.
 *
 * @param {EventTarget|Element} target Target DOM element
 * @returns {boolean} Returns true if the element requires a call to focus to simulate native click.
 */
FastClick.prototype.needsFocus = function(target) {
  'use strict';
  switch (target.nodeName.toLowerCase()) {
  case 'textarea':
    return true;
  case 'select':
    return !deviceIsAndroid;
  case 'input':
    switch (target.type) {
    case 'button':
    case 'checkbox':
    case 'file':
    case 'image':
    case 'radio':
    case 'submit':
      return false;
    }

    // No point in attempting to focus disabled inputs
    return !target.disabled && !target.readOnly;
  default:
    return (/\bneedsfocus\b/).test(target.className);
  }
};


/**
 * Send a click event to the specified element.
 *
 * @param {EventTarget|Element} targetElement
 * @param {Event} event
 */
FastClick.prototype.sendClick = function(targetElement, event) {
  'use strict';
  var clickEvent, touch;

  // On some Android devices activeElement needs to be blurred otherwise the synthetic click will have no effect (#24)
  if (document.activeElement && document.activeElement !== targetElement) {
    document.activeElement.blur();
  }

  touch = event.changedTouches[0];

  // Synthesise a click event, with an extra attribute so it can be tracked
  clickEvent = document.createEvent('MouseEvents');
  clickEvent.initMouseEvent(this.determineEventType(targetElement), true, true, window, 1, touch.screenX, touch.screenY, touch.clientX, touch.clientY, false, false, false, false, 0, null);
  clickEvent.forwardedTouchEvent = true;
  targetElement.dispatchEvent(clickEvent);
};

FastClick.prototype.determineEventType = function(targetElement) {
  'use strict';

  //Issue #159: Android Chrome Select Box does not open with a synthetic click event
  if (deviceIsAndroid && targetElement.tagName.toLowerCase() === 'select') {
    return 'mousedown';
  }

  return 'click';
};


/**
 * @param {EventTarget|Element} targetElement
 */
FastClick.prototype.focus = function(targetElement) {
  'use strict';
  var length;

  // Issue #160: on iOS 7, some input elements (e.g. date datetime) throw a vague TypeError on setSelectionRange. These elements don't have an integer value for the selectionStart and selectionEnd properties, but unfortunately that can't be used for detection because accessing the properties also throws a TypeError. Just check the type instead. Filed as Apple bug #15122724.
  if (deviceIsIOS && targetElement.setSelectionRange && targetElement.type.indexOf('date') !== 0 && targetElement.type !== 'time') {
    length = targetElement.value.length;
    targetElement.setSelectionRange(length, length);
  } else {
    targetElement.focus();
  }
};


/**
 * Check whether the given target element is a child of a scrollable layer and if so, set a flag on it.
 *
 * @param {EventTarget|Element} targetElement
 */
FastClick.prototype.updateScrollParent = function(targetElement) {
  'use strict';
  var scrollParent, parentElement;

  scrollParent = targetElement.fastClickScrollParent;

  // Attempt to discover whether the target element is contained within a scrollable layer. Re-check if the
  // target element was moved to another parent.
  if (!scrollParent || !scrollParent.contains(targetElement)) {
    parentElement = targetElement;
    do {
      if (parentElement.scrollHeight > parentElement.offsetHeight) {
        scrollParent = parentElement;
        targetElement.fastClickScrollParent = parentElement;
        break;
      }

      parentElement = parentElement.parentElement;
    } while (parentElement);
  }

  // Always update the scroll top tracker if possible.
  if (scrollParent) {
    scrollParent.fastClickLastScrollTop = scrollParent.scrollTop;
  }
};


/**
 * @param {EventTarget} targetElement
 * @returns {Element|EventTarget}
 */
FastClick.prototype.getTargetElementFromEventTarget = function(eventTarget) {
  'use strict';

  // On some older browsers (notably Safari on iOS 4.1 - see issue #56) the event target may be a text node.
  if (eventTarget.nodeType === Node.TEXT_NODE) {
    return eventTarget.parentNode;
  }

  return eventTarget;
};


/**
 * On touch start, record the position and scroll offset.
 *
 * @param {Event} event
 * @returns {boolean}
 */
FastClick.prototype.onTouchStart = function(event) {
  'use strict';
  var targetElement, touch, selection;

  // Ignore multiple touches, otherwise pinch-to-zoom is prevented if both fingers are on the FastClick element (issue #111).
  if (event.targetTouches.length > 1) {
    return true;
  }

  targetElement = this.getTargetElementFromEventTarget(event.target);
  touch = event.targetTouches[0];

  if (deviceIsIOS) {

    // Only trusted events will deselect text on iOS (issue #49)
    selection = window.getSelection();
    if (selection.rangeCount && !selection.isCollapsed) {
      return true;
    }

    if (!deviceIsIOS4) {

      // Weird things happen on iOS when an alert or confirm dialog is opened from a click event callback (issue #23):
      // when the user next taps anywhere else on the page, new touchstart and touchend events are dispatched
      // with the same identifier as the touch event that previously triggered the click that triggered the alert.
      // Sadly, there is an issue on iOS 4 that causes some normal touch events to have the same identifier as an
      // immediately preceeding touch event (issue #52), so this fix is unavailable on that platform.
      if (touch.identifier === this.lastTouchIdentifier) {
        event.preventDefault();
        return false;
      }

      this.lastTouchIdentifier = touch.identifier;

      // If the target element is a child of a scrollable layer (using -webkit-overflow-scrolling: touch) and:
      // 1) the user does a fling scroll on the scrollable layer
      // 2) the user stops the fling scroll with another tap
      // then the event.target of the last 'touchend' event will be the element that was under the user's finger
      // when the fling scroll was started, causing FastClick to send a click event to that layer - unless a check
      // is made to ensure that a parent layer was not scrolled before sending a synthetic click (issue #42).
      this.updateScrollParent(targetElement);
    }
  }

  this.trackingClick = true;
  this.trackingClickStart = event.timeStamp;
  this.targetElement = targetElement;

  this.touchStartX = touch.pageX;
  this.touchStartY = touch.pageY;

  // Prevent phantom clicks on fast double-tap (issue #36)
  if ((event.timeStamp - this.lastClickTime) < this.tapDelay) {
    event.preventDefault();
  }

  return true;
};


/**
 * Based on a touchmove event object, check whether the touch has moved past a boundary since it started.
 *
 * @param {Event} event
 * @returns {boolean}
 */
FastClick.prototype.touchHasMoved = function(event) {
  'use strict';
  var touch = event.changedTouches[0], boundary = this.touchBoundary;

  if (Math.abs(touch.pageX - this.touchStartX) > boundary || Math.abs(touch.pageY - this.touchStartY) > boundary) {
    return true;
  }

  return false;
};


/**
 * Update the last position.
 *
 * @param {Event} event
 * @returns {boolean}
 */
FastClick.prototype.onTouchMove = function(event) {
  'use strict';
  if (!this.trackingClick) {
    return true;
  }

  // If the touch has moved, cancel the click tracking
  if (this.targetElement !== this.getTargetElementFromEventTarget(event.target) || this.touchHasMoved(event)) {
    this.trackingClick = false;
    this.targetElement = null;
  }

  return true;
};


/**
 * Attempt to find the labelled control for the given label element.
 *
 * @param {EventTarget|HTMLLabelElement} labelElement
 * @returns {Element|null}
 */
FastClick.prototype.findControl = function(labelElement) {
  'use strict';

  // Fast path for newer browsers supporting the HTML5 control attribute
  if (labelElement.control !== undefined) {
    return labelElement.control;
  }

  // All browsers under test that support touch events also support the HTML5 htmlFor attribute
  if (labelElement.htmlFor) {
    return document.getElementById(labelElement.htmlFor);
  }

  // If no for attribute exists, attempt to retrieve the first labellable descendant element
  // the list of which is defined here: http://www.w3.org/TR/html5/forms.html#category-label
  return labelElement.querySelector('button, input:not([type=hidden]), keygen, meter, output, progress, select, textarea');
};


/**
 * On touch end, determine whether to send a click event at once.
 *
 * @param {Event} event
 * @returns {boolean}
 */
FastClick.prototype.onTouchEnd = function(event) {
  'use strict';
  var forElement, trackingClickStart, targetTagName, scrollParent, touch, targetElement = this.targetElement;

  if (!this.trackingClick) {
    return true;
  }

  // Prevent phantom clicks on fast double-tap (issue #36)
  if ((event.timeStamp - this.lastClickTime) < this.tapDelay) {
    this.cancelNextClick = true;
    return true;
  }

  // Reset to prevent wrong click cancel on input (issue #156).
  this.cancelNextClick = false;

  this.lastClickTime = event.timeStamp;

  trackingClickStart = this.trackingClickStart;
  this.trackingClick = false;
  this.trackingClickStart = 0;

  // On some iOS devices, the targetElement supplied with the event is invalid if the layer
  // is performing a transition or scroll, and has to be re-detected manually. Note that
  // for this to function correctly, it must be called *after* the event target is checked!
  // See issue #57; also filed as rdar://13048589 .
  if (deviceIsIOSWithBadTarget) {
    touch = event.changedTouches[0];

    // In certain cases arguments of elementFromPoint can be negative, so prevent setting targetElement to null
    targetElement = document.elementFromPoint(touch.pageX - window.pageXOffset, touch.pageY - window.pageYOffset) || targetElement;
    targetElement.fastClickScrollParent = this.targetElement.fastClickScrollParent;
  }

  targetTagName = targetElement.tagName.toLowerCase();
  if (targetTagName === 'label') {
    forElement = this.findControl(targetElement);
    if (forElement) {
      this.focus(targetElement);
      if (deviceIsAndroid) {
        return false;
      }

      targetElement = forElement;
    }
  } else if (this.needsFocus(targetElement)) {

    // Case 1: If the touch started a while ago (best guess is 100ms based on tests for issue #36) then focus will be triggered anyway. Return early and unset the target element reference so that the subsequent click will be allowed through.
    // Case 2: Without this exception for input elements tapped when the document is contained in an iframe, then any inputted text won't be visible even though the value attribute is updated as the user types (issue #37).
    if ((event.timeStamp - trackingClickStart) > 100 || (deviceIsIOS && window.top !== window && targetTagName === 'input')) {
      this.targetElement = null;
      return false;
    }

    this.focus(targetElement);
    this.sendClick(targetElement, event);

    // Select elements need the event to go through on iOS 4, otherwise the selector menu won't open.
    // Also this breaks opening selects when VoiceOver is active on iOS6, iOS7 (and possibly others)
    if (!deviceIsIOS || targetTagName !== 'select') {
      this.targetElement = null;
      event.preventDefault();
    }

    return false;
  }

  if (deviceIsIOS && !deviceIsIOS4) {

    // Don't send a synthetic click event if the target element is contained within a parent layer that was scrolled
    // and this tap is being used to stop the scrolling (usually initiated by a fling - issue #42).
    scrollParent = targetElement.fastClickScrollParent;
    if (scrollParent && scrollParent.fastClickLastScrollTop !== scrollParent.scrollTop) {
      return true;
    }
  }

  // Prevent the actual click from going though - unless the target node is marked as requiring
  // real clicks or if it is in the whitelist in which case only non-programmatic clicks are permitted.
  if (!this.needsClick(targetElement)) {
    event.preventDefault();
    this.sendClick(targetElement, event);
  }

  return false;
};


/**
 * On touch cancel, stop tracking the click.
 *
 * @returns {void}
 */
FastClick.prototype.onTouchCancel = function() {
  'use strict';
  this.trackingClick = false;
  this.targetElement = null;
};


/**
 * Determine mouse events which should be permitted.
 *
 * @param {Event} event
 * @returns {boolean}
 */
FastClick.prototype.onMouse = function(event) {
  'use strict';

  // If a target element was never set (because a touch event was never fired) allow the event
  if (!this.targetElement) {
    return true;
  }

  if (event.forwardedTouchEvent) {
    return true;
  }

  // Programmatically generated events targeting a specific element should be permitted
  if (!event.cancelable) {
    return true;
  }

  // Derive and check the target element to see whether the mouse event needs to be permitted;
  // unless explicitly enabled, prevent non-touch click events from triggering actions,
  // to prevent ghost/doubleclicks.
  if (!this.needsClick(this.targetElement) || this.cancelNextClick) {

    // Prevent any user-added listeners declared on FastClick element from being fired.
    if (event.stopImmediatePropagation) {
      event.stopImmediatePropagation();
    } else {

      // Part of the hack for browsers that don't support Event#stopImmediatePropagation (e.g. Android 2)
      event.propagationStopped = true;
    }

    // Cancel the event
    event.stopPropagation();
    event.preventDefault();

    return false;
  }

  // If the mouse event is permitted, return true for the action to go through.
  return true;
};


/**
 * On actual clicks, determine whether this is a touch-generated click, a click action occurring
 * naturally after a delay after a touch (which needs to be cancelled to avoid duplication), or
 * an actual click which should be permitted.
 *
 * @param {Event} event
 * @returns {boolean}
 */
FastClick.prototype.onClick = function(event) {
  'use strict';
  var permitted;

  // It's possible for another FastClick-like library delivered with third-party code to fire a click event before FastClick does (issue #44). In that case, set the click-tracking flag back to false and return early. This will cause onTouchEnd to return early.
  if (this.trackingClick) {
    this.targetElement = null;
    this.trackingClick = false;
    return true;
  }

  // Very odd behaviour on iOS (issue #18): if a submit element is present inside a form and the user hits enter in the iOS simulator or clicks the Go button on the pop-up OS keyboard the a kind of 'fake' click event will be triggered with the submit-type input element as the target.
  if (event.target.type === 'submit' && event.detail === 0) {
    return true;
  }

  permitted = this.onMouse(event);

  // Only unset targetElement if the click is not permitted. This will ensure that the check for !targetElement in onMouse fails and the browser's click doesn't go through.
  if (!permitted) {
    this.targetElement = null;
  }

  // If clicks are permitted, return true for the action to go through.
  return permitted;
};


/**
 * Remove all FastClick's event listeners.
 *
 * @returns {void}
 */
FastClick.prototype.destroy = function() {
  'use strict';
  var layer = this.layer;

  if (deviceIsAndroid) {
    layer.removeEventListener('mouseover', this.onMouse, true);
    layer.removeEventListener('mousedown', this.onMouse, true);
    layer.removeEventListener('mouseup', this.onMouse, true);
  }

  layer.removeEventListener('click', this.onClick, true);
  layer.removeEventListener('touchstart', this.onTouchStart, false);
  layer.removeEventListener('touchmove', this.onTouchMove, false);
  layer.removeEventListener('touchend', this.onTouchEnd, false);
  layer.removeEventListener('touchcancel', this.onTouchCancel, false);
};


/**
 * Check whether FastClick is needed.
 *
 * @param {Element} layer The layer to listen on
 */
FastClick.notNeeded = function(layer) {
  'use strict';
  var metaViewport;
  var chromeVersion;
  var blackberryVersion;

  // Devices that don't support touch don't need FastClick
  if (typeof window.ontouchstart === 'undefined') {
    return true;
  }

  // Chrome version - zero for other browsers
  chromeVersion = +(/Chrome\/([0-9]+)/.exec(navigator.userAgent) || [,0])[1];

  if (chromeVersion) {

    if (deviceIsAndroid) {
      metaViewport = document.querySelector('meta[name=viewport]');

      if (metaViewport) {
        // Chrome on Android with user-scalable="no" doesn't need FastClick (issue #89)
        if (metaViewport.content.indexOf('user-scalable=no') !== -1) {
          return true;
        }
        // Chrome 32 and above with width=device-width or less don't need FastClick
        if (chromeVersion > 31 && document.documentElement.scrollWidth <= window.outerWidth) {
          return true;
        }
      }

    // Chrome desktop doesn't need FastClick (issue #15)
    } else {
      return true;
    }
  }

  if (deviceIsBlackBerry10) {
    blackberryVersion = navigator.userAgent.match(/Version\/([0-9]*)\.([0-9]*)/);
    
    // BlackBerry 10.3+ does not require Fastclick library.
    // https://github.com/ftlabs/fastclick/issues/251
    if (blackberryVersion[1] >= 10 && blackberryVersion[2] >= 3) {
      metaViewport = document.querySelector('meta[name=viewport]');

      if (metaViewport) {
        // user-scalable=no eliminates click delay.
        if (metaViewport.content.indexOf('user-scalable=no') !== -1) {
          return true;
        }
        // width=device-width (or less than device-width) eliminates click delay.
        if (document.documentElement.scrollWidth <= window.outerWidth) {
          return true;
        }
      }
    }
  }
  
  // IE10 with -ms-touch-action: none, which disables double-tap-to-zoom (issue #97)
  if (layer.style.msTouchAction === 'none') {
    return true;
  }

  return false;
};


/**
 * Factory method for creating a FastClick object
 *
 * @param {Element} layer The layer to listen on
 * @param {Object} options The options to override the defaults
 */
FastClick.attach = function(layer, options) {
  'use strict';
  return new FastClick(layer, options);
};


if (typeof define == 'function' && typeof define.amd == 'object' && define.amd) {

  // AMD. Register as an anonymous module.
  define(function() {
    'use strict';
    return FastClick;
  });
} else if (typeof module !== 'undefined' && module.exports) {
  module.exports = FastClick.attach;
  module.exports.FastClick = FastClick;
} else {
  window.FastClick = FastClick;
}
;
/**
 * This is the main class for the Utilisphere website.
 * It initializes all the other components that may be used across pages.
 * 
 * During compilation, these files should be prepended:
 * _map-display.js
 * _popover.js
 * _slide-nav.js
 */

var irth = irth || {};
irth.instance = null;
irth.Utilisphere = function() {
  
  this.init = function() {
      // Handles popovers on the site.
      this.popOver = new irth.PopOver();
      this.popOver.init();
      
      // Handles the main navigation at the top of the page, and the slide-in system tray.
      this.slideNav = new irth.SlideNav();
      this.slideNav.init();
      
      // Displays Bing maps.
      this.mapDisplay = new irth.MapDisplay();
      this.mapDisplay.init();
      
      // Removes 300ms click delay on touch-based devices.
      FastClick.attach(document.body);
  };
  
};

// Initialize the site once the document is loaded.
$(document).ready(function() {
  if(irth.instance === null) {
    irth.instance = new irth.Utilisphere();
    irth.instance.init();
  }
});

