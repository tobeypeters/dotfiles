window.onload=window_onresize;
window.onresize=window_onresize;

/*
function window_onresize()
{
	var bottomEdge;
	var tdMainContent=$get("tdBanner");
	var HeightToSubtract = tdMainContent.offsetHeight;

	
	if ((navigator.appName == "Microsoft Internet Explorer") && (parseInt(navigator.appVersion) >= 4 ))
	{
		bottomEdge = document.body.offsetHeight;
		var divHeight=bottomEdge - HeightToSubtract - 60;
		if (divHeight > 50)
		$get("mainDiv").style.height = (bottomEdge - HeightToSubtract - 50) + "px";
	} 
}
*/

function window_onresize()
{
    // Modified 4-10-2007 by SPJ: to use AJAX controls we have to put IE in standards-compliant mode. This mode
    // causes IE 6+ to use the CSS1 box model, rather than the non-compliant box model used previously. I updated
    // this script to provide the same results as before, but using the new box model.
    // See http://msdn2.microsoft.com/en-us/library/bb250395.aspx for more info.

    //Don't do any resizing on mobile so zooming what break the page
    if (IsTouchDevice()) {
        $get("mainDiv").style.height = 'auto';
        return;
    }
    // Get the height of the banner and controls above/below main content area
	var bottomEdge;
	var tdMainContent=$get("tdBanner");
	var HeightToSubtract = tdMainContent.offsetHeight;
	
	// Using object detection is far less brittle than using the user-agent for browser version detection
	var bottomEdge;
	
	if (typeof(window.innerHeight) == "number") 
	{
	    // not IE. window.innerHeight gives the window size
		bottomEdge = window.innerHeight;
		$get("mainDiv").style.height = (bottomEdge - HeightToSubtract - 50) + "px";

		bottomEdge = innerHeight;
		var mainTable = document.getElementById("mainTable");
		if (mainTable && mainTable.style)
    		mainTable.style.height = (bottomEdge - HeightToSubtract - 35) + "px";
	} else if( document.documentElement && document.documentElement.clientHeight ) 
	{
        //IE 6+ in 'standards compliant mode'. document.documentElement.clientHeight gives us the window size.
        bottomEdge = document.documentElement.clientHeight;
		$get("mainDiv").style.height = (bottomEdge - HeightToSubtract - 35) + "px";

        bottomEdge = document.documentElement.clientHeight;
        var mainTb=$get("masterTable");
        if(mainTb != null)
		    mainTb.style.height = (bottomEdge - HeightToSubtract - 35) + "px";
	} else if( document.body && ( document.body.clientWidth || document.body.clientHeight ) ) 
	{
        //IE 4 compatible. 
		bottomEdge = document.body.offsetHeight;
		if ((bottomEdge - HeightToSubtract - 50) > 50) 
		{
			$get("mainDiv").style.height = (bottomEdge - HeightToSubtract - 50) + "px";
		}
    }
}
function EndRequestHandler(sender, args)
{
    if (args.get_error() && args.get_response().get_timedOut()) 
    {
        if (typeof(HandleTimeout)!="undefined")
            HandleTimeout();
        else
            alert('The request has taken too long.');
            
        // remember to set errorHandled = true to keep from getting a popup from the AJAX library itself
        args.set_errorHandled(true);
    }

    if(typeof(ProcessEndRequest)!="undefined")
    {
         ProcessEndRequest();         
    }
    if(typeof(SetupTrainingWheels) != "undefined")
    {
        SetupTrainingWheels();
    }
    if(typeof(SetControlFocus) != "undefined")
    { 
        SetControlFocus();
    }
    if(typeof(ShouldShowPopup) != "undefined")
    {
        ShouldShowPopup();
    }
    window_onresize();
}

function SetFocusToControl(controlId)
{
    var e=$get(controlId);
    if(e==null)
        return;
        
   e.focus();
}
function CopyDropdownListSelection(dropListId,hiddenBoxId)
{
    var eDropList=$get(dropListId);
    var eHiddenBox=$get(hiddenBoxId);
    
    if(eDropList==null)
        return;
    if(eHiddenBox==null)
        return;
        
    eHiddenBox.value=eDropList.selectedIndex;
}

function IsTouchDevice() {
    if (navigator.userAgent.indexOf('iPod') != -1) { return true; }
    if (navigator.userAgent.indexOf('iPhone') != -1) { return true; }
    if (navigator.userAgent.indexOf('iPad') != -1) { return true; }
    if (navigator.userAgent.indexOf('Android') != -1) { return true; }
    if (navigator.userAgent.indexOf('Windows Phone') != -1) { return true; }
    if (navigator.userAgent.indexOf('Touch') != -1) { return true; }
    else { return false; }
}

function IsWindowClosed(win) {
    if (win === undefined || win == null || win.closed === undefined || win.closed)
        return true;
    return false;
}

function CloseWin(win) {
    if (!IsWindowClosed(win))
        win.close();
    win = null;
}

;