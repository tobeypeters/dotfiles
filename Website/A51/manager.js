"use strict";

function debugInfo() {
  var pt = window.performance.timing;

  var lt = pt.loadEventEnd - pt.navigationStart; //Load Time
  var lt = (lt < 0) ? 0: lt;

  var ct = pt.responseEnd - pt.responseStart; //Connect / Response time
  var rt = pt.domComplete - pt.domLoading; //Page Render Time
  var la = pt.responseStart - pt.fetchStart; //Latency
  var dns = pt.domainLookupEnd - pt.domainLookupStart; //DNS lookup time
  var sc = pt.connectEnd - pt.connectStart; //Server Connect Time
  var srt = pt.responseStart - pt.requestStart; //Server Response Time
  var fb = pt.responseStart - pt.navigationStart; //Total First Byte Time

  var ol = pt.loadEventEnd - pt.loadEventStart; //Onload Time
  var ol = (ol < 0) ? 0: ol;

  var di = pt.domInteractive - pt.navigationStart; //DOM Interactive Time
  var dc = pt.domContentLoadedEventEnd - pt.navigationStart; //DOM Content Load Time
  var dpi = pt.domInteractive - pt.domLoading; //DOM Processing to Interactive
  var dic = pt.domComplete - pt.domInteractive; //DOM Interactive to Complete
  var rdt = pt.redirectEnd - pt.redirectStart; //Redirect time

  var DEBUG_INFO = {
    'Server Connect Time': sc,
    'Server Response Time': srt,
    'DNS Lookup Time': dns,
    'Latency': la,
    'Load Time': lt,
    'Onload Time': ol,
    'Render Time': rt,
    'Redirect time': rdt,
    'First Byte Time': fb,
    'Connect Time': ct,
    'DOM Interactive Time': di,
    'DOM Content Load Time': dc,  
    'DOM Processing to Interactive': dpi,
    'DOM Interactive to Complete': dic
  }

  return DEBUG_INFO;
}

function changeVisibilty(pID, pKind, pHeight) {
  //Changes the display type or height of elements
  pID = document.getElementById(pID);
  var es = pID.style;

  pKind ? ('none' == getComputedStyle(pID).display) ? es.display = pKind : es.display = 'none' : es.height = pHeight + 'px';
}

function gup(name, url) {
  //Get URL Parameter
  //gup('q', 'hxxp://example.com/?q=abc');

  if (!name || !url) {
    return null;
  }

  name = name.replace(/[\[]/, '\\[').replace(/[\]]/, '\\]');
  var c = (new RegExp('[\\?&]' + name + '=([^&#]*)')).exec(url);
  return ((null == c) ? null : c[1]);
}

function decode(a) {
  // ROT13 : a Caesar cipher 
  // letter -> letter' such that code(letter') = (code(letter) + 13) modulo 26
  return a.replace(/[a-zA-Z]/g, function(c){
      return String.fromCharCode((c <= "Z" ? 90 : 122) >= (c = c.charCodeAt(0) + 13) ? c : c - 26);
  })
} 

function isMobileDevice(giveOS) {
  //Mobile device detection
  return giveOS ? DetectOS() : !typeof['Windows', 'macOS', 'Linux'].find(function(a) {
      return (a == DetectOS());
  });
}

function DetectOS () {
  //Detects the OS this script is running on
  //No full proof way. I chose to approach it, this way
var Detect = {init:function() {
    Detect.OS = Detect.searchString(Detect.dataOS);
  }, searchString:function(b) {
    for (var a = 0; a < b.length; a++) {
      var c = b[a].string;//, d = b[a].prop;
      if (c) {
        if (-1 != c.indexOf(b[a].subString)) {
          //userSgent lookup
          return b[a].identity;
        }
      } /*else {
        if (d) {
            //platform lookup
            console.log('here 2');
          return b[a].identity;
        }
      }*/
    }
  }, dataOS:[
      //{string:navigator.platform, subString:"Win", identity:"Windows"},
      //{string:navigator.platform, subString:"Mac", identity:"macOS"},
      {string:navigator.userAgent, subString:'Win', identity:'Windows'},
      {string:navigator.userAgent, subString:'Mac', identity:'macOS'},

      {string:navigator.userAgent, subString:'Android', identity:'Android'},
      {string:navigator.userAgent, subString:'iPhone', identity:'iOS'},
      {string:navigator.userAgent, subString:'iPad', identity:'iOS'},
      {string:navigator.userAgent, subString:'iPod', identity:'iOS'},

      //{string:navigator.platform, subString:"Linux", identity:"Linux"}
      {string:navigator.userAgent, subString:'Linux', identity:'Linux'},
      {string:navigator.userAgent, subString:'OS\\2', identity:'OS\\2'},
      {string:navigator.userAgent, subString:'BeOS', identity:'BeOS'},
      {string:navigator.userAgent, subString:'Haiku', identity:'Haiku'},
      {string:navigator.userAgent, subString:'SunOS', identity:'SunOS'},
      {string:navigator.userAgent, subString:'OpenBSD', identity:'OpenBSD'}      
    ]
  };

  Detect.init();
  return Detect.OS;
}