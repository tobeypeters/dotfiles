//in theory, a mobile data provider (Sprint in this case) will often move these seperate script files inline.
//When doing so, they'll remove the script tag that we place in the markup, with a style of display=none.
//So, if that occurs, our scripts are probably being corrupted...
var cookieNAM = 'shownProviderWarning';
function validateScriptIncludes() {
    if (typeof($) == "undefined")
        return;

    return; // disable this checking for now

    var testJS = $('script[style*="display"]');
    if (testJS.length>0 && document.cookie.indexOf(cookieNAM) == -1) {

        //looks like we have some provider 'optimizing' done, or inlining at the least...
        //we need to let the user know that this is happening, and that there are possibly going to be errors as a result...
        var html = '<div id="divProviderWarning" style="display:none;"> ';
        html += '<p style="font-weight:bold;" >';
        html += '<span class="ui-icon ui-icon-alert" style="float:left; margin:0;"></span> ';
        html += 'We have determined that your internet provider is using an "optimization" feature that is modifying our page content before it reaches your browser, ';
        html += 'in particular, the script rendering.  </p>';
        html += 'Functionality will be compromised if you continue.  ';
        html += 'We recommend that you connect to an alternate internet provider or contact your current provider ';
        html += 'and request that they disable this "optimization" for your account.';
        html += '</div>';
        
        $('body').append(html);
        var $uiDlg = $('#divProviderWarning').dialog(
        {
            modal: true,
            width: 500,
            //height: 300,
            draggable: false,
            resizable: false,
            title: 'Warning!',
            dialogClass: "alert",
            buttons: {
                Ok: function () {
                    $(this).dialog('close');
                },
                "Hide": {
                    text: "Don't show this again",
                    priority: 'secondary',
                    style: 'width:200px;',
                    click: function () {
                        $(this).dialog('close');
                        //save a cookie so we know to hide it for the session...
                        document.cookie = cookieNAM+"=1;max-age=7200";//set a 2 hour cookie...
                    }
                }
            }
        });
    }
}