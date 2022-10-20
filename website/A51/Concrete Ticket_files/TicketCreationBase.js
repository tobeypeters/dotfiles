var popupDigsiteUrl="";
var popupMapUrl="";

var winDigsite=null;
var winMap=null;

var popup=null;

window.onunload = UnloadPage;

function AttachImage(controlID, msg)
{
    $("#" + controlID).before('<img style="padding-right:5px" alt="' + msg + '" src="' + GetBaseUrl() + '/Images/error.png"/>');
}

function ShouldShowPopup()
{
    if (popup)
        popup.Show();
    
}
function ShowPopup(content_id,closer_elements,modal)
{
    popup = new PopUp(content_id, closer_elements, modal);
    popup.Show();
}

function ProcessEndRequest()
{
    RetrieveTicketCreationHiddenData();        

    if(popupDigsiteUrl != "")
    {
        winDigsite=DisplayWindow(winDigsite,"DigsiteSearch",popupDigsiteUrl,"800px","500px");
        popupDigsiteUrl="";
    }
    else
    {
        UnloadWinDigsite();
    }
   
    if(popupMapUrl != "")
    {
        winMap=DisplayWindow(winMap,"DigsiteMap",popupMapUrl,"800px","600px");
        popupMapUrl="";
    }
    else
    {
        UnloadWinMap();
    } 
}

function RetrieveTicketCreationHiddenData()
{
	var frm=document.forms[0]; 

	var count=0;
	for (var i=1;i<frm.elements.length;i++) 
	{ 
		var e = frm.elements[i]; 
		if (e.type !="hidden") 
			continue;
	
		if(e.className=="popupDigsiteUrl")
		{
			popupDigsiteUrl=e.value;
			e.value="";
			count++;
		}
		else if(e.className=="popupMapUrl")
		{
		    popupMapUrl=e.value;
		    e.value="";
		    count++;
		}
		
		if(count>=2)
		    return;
	}		
}

function DisplayWindow(win,name,url,width,height)
{
    var x=window.screenLeft+50;
    var y=window.screenTop+10;
    y=100;
    
    var param="width="+width;
    param=param+", height="+height;
    param=param+", scrollbars=1, status=1, menubar=0, toolbar=0, resizable=1";
    
    //var param="width=100px, height=20px, scrollbars=1, status=1, menubar=0, toolbar=0, resizable=1";
    param = param+", top="+y+", left="+x;

    if (IsWindowClosed(win))
        win = null;
    
    if(win==null)
    {
        //  Pop-up blocker can cause this to fail and return null...
        win=window.open(url,name,param);
    }
    else
    {
        if(win.location==url)   
            win.focus();
        else
            win.location=url;
    }
    if (win)
        win.focus();

    return win;
}

//  Returns true if we fired the event to cause a post back.  False if not
function ApplyResult(postbackTriggerId,applyType,hiddenResutlId,applyIdValue, fromID, toID, toValue, fromValue)
{
    if (fromID != "" && toID != "")
    {
        var to = $get(toID);
        var from = $get(fromID);
        to.value = toValue;
        from.value = fromValue;
    }
       
    var e=$get(postbackTriggerId);
    if(e==null && applyIdValue != null)
        return ApplyResultWithOutTrigger(applyIdValue);
    else if (e == null)
        return false;
    
    var eHiddenResult=$get(hiddenResutlId);
    if(eHiddenResult != null)
        eHiddenResult.value=applyIdValue;
    
    for(i=0; i<e.options.length; i++)
    {
        if(e.options[i].value==applyType)
        {
            e.options[i].selected = true;
            if (e.dispatchEvent) {
                var event = document.createEvent("HTMLEvents");
                event.initEvent("change", true, false);
                e.dispatchEvent(event);
            }
            else {
                e.fireEvent("onchange");
            }
            return true;
        }
    }
    
    return false;
}

//  Returns true if we fired the event to cause a post back.  False if not
function ApplyResultWithOutTrigger(applyIdValue)
{
    var frm=document.forms[0]; 

	var count=0;
	for (var i=1;i<frm.elements.length;i++) 
	{ 
		var e = frm.elements[i]; 
		if (e.className !="hiddenItem") 
			continue;
	    
	    if (e.id.indexOf("lookupTypeUsed") > 0)
		{
			e.value=applyIdValue;
		}
	    if (e.id.indexOf("ddPostBackTrigger") > 0)
		{
		    if (e.dispatchEvent) {
		        var event = document.createEvent("HTMLEvents");
		        event.initEvent("change", true, false);
		        e.dispatchEvent(event);
		    }
		    else {
		        e.fireEvent("onchange");
		    }
			return true;
		}
    }
	
	return false;
}

function UnloadPage()
{
    UnloadWinDigsite();
    UnloadWinMap();
}
function UnloadWinDigsite()
{
    CloseWin(winDigsite);
}
function UnloadWinMap()
{
    CloseWin(winMap);

}
function UnloadPopupWindow(win) {
    CloseWin(win);
}
function ViewMap()
{
    popupMapUrl=GetBaseUrl()+"/Ticket/DigsiteSearch/Map.aspx?DigsiteSearchType=Map";
    winMap=DisplayWindow(winMap,"DigsiteMap",popupMapUrl,"800px","600px");
    popupMapUrl="";
}

//  This function is used when viewing a map from a read-only ticket.  It uses the Read Only ticket
//  object from session instead of the ticket creation object.
function ViewMapOfReadOnlyTicket() {
    popupMapUrl = GetBaseUrl() + "/Ticket/DigsiteSearch/Map.aspx?DigsiteSearchType=Map&TicketSource=ReadOnly";
    winMap = DisplayWindow(winMap, "DigsiteMap", popupMapUrl, "800px", "600px");
    popupMapUrl = "";
}

function ViewLandLord(isTicketCreation)
{
    popupMapUrl = GetBaseUrl() + "/Reports/LandlordReport.aspx";
    if (isTicketCreation)
        popupMapUrl = popupMapUrl + "?TicketCreation=1";
    winMap = DisplayWindow(winMap, "LandlordReport", popupMapUrl, "800px", "600px");
    popupMapUrl = "";
}
//Read the value to revert back to if they have a confirmation question and the cancel out of it
//Control - the control that is changing.
var cancelValue;
function ReadValueForCancel(control)
{
    var cancelValue = control.value;
    
    //if it's a drop down then we want to get the text not the value.
    if (control.tagName == "SELECT")
        cancelValue = control.selectedIndex;
}
//Popup a confirmation message as a confirm box.  If they select cancel and they have a non confirmation value
//  then revert back to the previous selection, else leave the selection.
//Control - Control that is changing
//Value - Value that if selected should pop the dialog
//Message - The message to show in the Dialog
//NonConfirmationValue - do we have a non confirmed value...
//If the nonConfirmedValue == 0 then we didn't have a nonConfirmed value, if it's 1 
//  we had one so selecting cancel should revert back to the previous value.
function ConfirmationPopup(control, value, message, nonConfirmValue)
{
    var controlValue = control.value;
    
    //if it's a drop down then we want to get the text not the value.
    if (control.tagName == "SELECT")
        controlValue = control.options[control.selectedIndex].text;
        
    if (controlValue.toUpperCase() == value.toUpperCase())
    {
        var onNo = '';
        if (nonConfirmValue!=0)
            onNo = "var ctl=$getControl('" + control.id + "');ctl.tagName=='SELECT'?ctl.selectedIndex=" + cancelValue + ":ctl.value='" + cancelValue + "';ctl.focus();"
        
        var md=new ModalDialogue();
        md.Title='Confirmation';
        md.Text=message;
        md.AddButton('Yes', "var ctl=$getControl('" + control.id + "');ctl.focus();");
        md.AddButton('No', onNo);
        md.EnableClose = false;
        md.Show();
    }
    else
    {
        if (control.tagName == "SELECT")
            cancelValue = control.selectedIndex;
        else
            cancelValue = controlValue;
    }
}


//The affected fields functions can be more combined to reduce code duplication
//control = control fireing event
//value = if 'control' has this value then use 'required' and 'enable' variables
//contorlID = client id of the affected control
//irthnameControlID = client id of the control to put the required star on
//required = should the affected control be required
//enable = should the affected control be enabled or disabled
//originalEnabled = if the affected control should be enabled if the 'control' doesn't have the 'value'
//originalRequired = if the affected control should be required if the 'control' doesn't have the 'value'
//defaultValue = value to set the affected control to if the 'control' doesn't have the 'value'. If null, won't do anything
function AffectedField(control, value, controlID, irthnameControlID, required, enable, originalEnabled, originalRequired, defaultValue)
{
    if ((control == null) || (typeof control === "undefined") || (control === "undefined"))
        return;

    var affectedControl = $get(controlID);
    var requireControl = null;
    
    if (irthnameControlID != null && irthnameControlID != 'undefined')
    {
        requireControl = $get(irthnameControlID);
    }
    
    var controlValue = control.value;
    
    //if it's a drop down then we want to get the text not the value.
    if (control.tagName == "SELECT")
        controlValue = control.options[control.selectedIndex].text;
    else if (control.tagName == "TABLE") {
        //it's a radio button list
        return;
    }


    if (controlValue.toUpperCase() == value.toUpperCase())
    {         
        if (enable == 'True')
            affectedControl.disabled = null;
        else
            SetupAffectedFieldToNotBeRequired(affectedControl, defaultValue);

        //FormatControl(requireControl, required == 'True');
    }
    else
    {
        if (originalEnabled == 'True')
            affectedControl.disabled = null;
        else
            SetupAffectedFieldToNotBeRequired(affectedControl, defaultValue);

        FormatControl(requireControl, originalRequired == 'True');
    }
}

//  Sets up an affected control to not be required.  Also removes any error indicates/colors
//  that may have been added by the server controls.
function SetupAffectedFieldToNotBeRequired(affectedControl, defaultValue)
{
    affectedControl.disabled = "disabled";

    //Set the default value since the control is being disabled.
    affectedControl.value = defaultValue;

    //  Remove/disable server added indicators:
    $(affectedControl).removeClass("invalidBg");                    //  red background
    $(affectedControl).parent().find("img").css("display", "none");    //  red * icon
}

//control = control fireing event
//values = if 'control' has one of these values then use 'required' and 'enable' variables (Comma seperated list.)
//contorlID = client id of the affected control
//irthnameControlID = client id of the control to put the required star on
//required = should the affected control be required
//enable = should the affected control be enabled or disabled
//originalEnabled = if the affected control should be enabled if the 'control' doesn't have the 'value'
//originalRequired = if the affected control should be required if the 'control' doesn't have the 'value'
//defaultValue = value to set the affected control to if the 'control' doesn't have the 'value'. If null, won't do anything
function CustomAffectedFields(ctrl, values, controlID, irthnameControlID, required, enable, originalEnabled, originalRequired, defaultValue) {

try{
    var control = (ctrl.value != undefined) ? ctrl : $('input:checked', ctrl)[0];

    var affectedControl = $get(controlID);
       if (affectedControl == null)
        return; 
    
    var requireControl = null;
    
    if (irthnameControlID != null && irthnameControlID != 'undefined')
    {
        requireControl = $get(irthnameControlID);
    }
    
    var arrValues = new Array();
    arrValues = values.split(',');
    
    for (var i = 0; i < arrValues.length; i++)
    {
        var value = arrValues[i].replace(/^\s*/, "").replace(/\s*$/, "");
    	if (control.value.toUpperCase() == value.toUpperCase())
        {         
            if (enable == 'True')
                affectedControl.disabled = null;
            else
            {
                affectedControl.disabled = "disabled";
            
                //Set the default value since the control is being disabled.
                if (defaultValue != null)
                    affectedControl.value = defaultValue;   
            }

            FormatControl(requireControl, required == 'True');
            return true;
        }
    }

    if (originalEnabled == 'True')
        affectedControl.disabled = null;
    else
    {
        affectedControl.disabled = "disabled";
    
        //Set the default value since the control is being disabled.
        if (defaultValue != null)
            affectedControl.value = defaultValue;  
    }

    FormatControl(requireControl, originalRequired == 'True');
    }
    catch (e)
    {
        alert(e.message);
    }
}

