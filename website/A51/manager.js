"use strict";

function changeStyle(pID, pKind, pHeight) {
  // Changes the display type or height of elements
  // changeStyle('navBottom', 'inline') changeStyle('profDiv', 'block')
  // changeStyle('profDiv', null, 100)
  if (!(pID && (pKind || pHeight))) {
    return;
  }

  pID = document.getElementById(pID);
  var es = pID.style;

  if (pKind) {
    ('none' == getComputedStyle(pID).display) ? es.display = pKind : es.display = 'none';
  }

  if (pHeight) {
    es.height = pHeight + 'px';
  }
}

function gup(name, url) {
  //Get URL Parameter
  //gup('q', 'hxxp://example.com/?q=abc');

  if (!name || !url) {
    return null;
  }

  name = name.replace(/[\[]/, '\\[').replace(/[\]]/, '\\]');
  var c = (new RegExp('[\\?&]' + name + '=([^&#]*)')).exec(url);

  return c ? c[1] : null;
}

function decode(a) {
  // ROT13 : a Caesar cipher
  // letter -> letter' such that code(letter') = (code(letter) + 13) modulo 26
  return a.replace(/[a-zA-Z]/g, function(c){
      return String.fromCharCode((c <= "Z" ? 90 : 122) >= (c = c.charCodeAt(0) + 13) ? c : c - 26);
  })
}

function isMobileDevice() {
  //Mobile device detection
  return (-1 == ['Windows', 'macOS', 'Linux'].indexOf(DetectOS()));
}

function DetectOS () {
  // Try and determine what OS the browser is running on.
  // Only accurate, if the useragent is.  Plus, I don't take account,
  // for new Linux based phones.  There useragent, might only say Linux???
  var osMap = new Map([
    ['Win', 'Windows'],
    ['Mac', 'macOS'],
    ['Android', 'Android'],
    ['iPhone', 'iOS'],
    ['iPad', 'iOS'],
    ['iPod', 'iOS'],
    ['Linux', 'Linux'],
    ['OS\\2', 'OS\\2'],
    ['BeOS', 'BeOS'],
    ['Haiku', 'Haiku'],
    ['SunOS', 'SunOS'],
    ['OpenBSD', 'OpenBSD']
    ]);

  var result = 'Unknown';

  osMap.forEach((value, key) => {
    if (-1 != navigator.userAgent.indexOf(key)) {
      result = value;
    }
  });

  return result;
}

function initNavs() {
  var sep =  "&nbsp;|&nbsp;"
  var md = "<a href='?d=main.html'>Home</a>" + sep +
            "<a href='?d=blank.html'>Link 2</a>" + sep +
            "<a href='?d=blank.html'>Link 3</a>" + sep +
            "<a href='?d=blank.html'>Link 4</a>" + sep +
            "<a href='?d=doids.html'>Doids</a>" + sep +
            "<a href='?d=filetest.html'>Files</a>" + sep +
            "<a href='?d=contact.html'>Contact</a>" + "&nbsp;";

  //Fill the navbars with anchor elements
  document.getElementById('navTop').innerHTML = md;
  document.getElementById('navBottom').innerHTML = '&nbsp;' + md;
}

function resizeIframe () {
  // I do it this way, because this function is used by iframe.onload and window.resize
  // Otherwise, you can just say this.style.height
  var el = document.getElementById('doc');

  el.style.height = el.contentWindow.document.body.scrollHeight + 40 + 'px';
}

window.onload = function () {
  // Evem though the code worked & the site worked,
  // I'd get random typeerrors & null errors in the console.
  var el = document.getElementById('doc');

  if (el)
  {
    el.addEventListener('load', resizeIframe);
    window.addEventListener('resize', resizeIframe);

    var pDoc = gup('d', location.href);

    el.src = 'content/' + (pDoc ? pDoc : 'main.html');
  }

  el = document.getElementById('alertLink');

  if (el)
  {
    el.onclick = function () {
      changeStyle('alertBox', 'none');

      sessionStorage && sessionStorage.setItem('alertClosed', 'true');
    }
  }

  el = document.getElementById('profSpan');

  if (el)
  {
    // Suppose to move towards PerformanceNavigationTiming.  But, it's not
    // fully supported by all browsers.  Espicially, Safari ...
    //var pt = window.performance.timing;
    const [pt] = performance.getEntriesByType("navigation");

    var dblEnter = '<br><br>';
    var dbgInfo = 'URL: ' + location.href + dblEnter +
                  'Generated: ' + Date() + dblEnter;

    var dS = ' : <strong>';
    var dE = 'ms</strong> : ';

    var m = Math.max;

    // No I don't like wrapping all of these calculations in a max().
    // But, I was getting some negative values.
    const permInfo = [
                'Server Connect Time' + dS + m(0, pt.connectEnd - pt.connectStart) + dE + 'The average amount of time spent in establishing a TCP connection.',
               'Server Response Time' + dS + m(0, pt.responseStart - pt.requestStart) + dE + 'The amount of time it takes for a web server to respond to a request from a browser.',
                    'DNS Lookup Time' + dS + m(0, pt.domainLookupEnd - pt.domainLookupStart) + dE + 'The process by which a DNS record is returned from a DNS server.',
                            'Latency' + dS + m(0, pt.responseStart - pt.fetchStart) + dE + 'The amount of time it takes for the host server to receive and process a request for a page object.',
                          'Load Time' + dS + m(0, pt.loadEventEnd - pt.navigationStart) + dE + 'Page load time is the time it takes to download and display the entire content of a web page in the browser.',
                        'Onload Time' + dS + m(0, pt.loadEventEnd - pt.loadEventStart) + dE + 'The time elapsed since the start of the first request until the page triggered the load event.',
                        'Render Time' + dS + m(0, pt.domComplete - pt.domLoading) + dE + 'The time it takes to actually have the web page ready for the visitor to use and interact with.',
                      'Redirect time' + dS + m(0, pt.redirectEnd - pt.redirectStart) + dE + 'The time it takes a request to follow a redirect.',
                    'First Byte Time' + dS + m(0, pt.responseStart - pt.navigationStart) + dE + 'The duration from the user or client making an HTTP request to the first byte of the page being received by the clients browser.',
                       'Connect Time' + dS + m(0, pt.responseEnd - pt.responseStart) + dE + 'For an uptime check (http check) the connect / response time is calculated as the time it takes to perform a HTTP GET to the specified URL. It is calculated in three parts: Time to First Byte, Time to recieve headers, and time to load HTML of the site.',
               'DOM Interactive Time' + dS + m(0, pt.domInteractive - pt.navigationStart) + dE + 'The time immediately before the user agent sets the current document readiness to interactive.',
              'DOM Content Load Time' + dS + m(0, pt.domContentLoadedEventEnd - pt.navigationStart) + dE + 'The time it takes for all of the processing to complete and all of the resources on the page (images, etc.) to finish downloading.',
      'DOM Processing to Interactive' + dS + m(0, pt.domInteractive - pt.domLoading) + dE + 'The amount of load time which passes before the user can start to interact with it.',
        'DOM Interactive to Complete' + dS + m(0, pt.domComplete - pt.domInteractive) + dE + 'The time it takes for the browser to load images/videos and execute any JavaScript code waiting for the domContentLoaded event.'
    ]

    permInfo.forEach((item) => {
      dbgInfo += item + dblEnter;
    });

    el.innerHTML = dbgInfo;

    console.table(pt);
  }

  initNavs();

  if (sessionStorage) {
    !(sessionStorage.getItem('alertClosed')) && changeStyle('alertBox', 'block');
  }

//  let message = { height: document.body.scrollHeight };

	// window.top refers to parent window
//	window.top.postMessage(message, "*");
}