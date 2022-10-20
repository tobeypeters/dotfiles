__dragAndDrop_version=1;

document.onmousemove=mouseMove;
document.onmouseup=mouseUp;

var __dragAndDrop_dragObject = null;
var __dragAndDrop_mouseOffset = 0;
var __dragAndDrop_marginOffset = 0;

function getMouseOffset(target, ev)
{
	ev=ev||window.event;

	var docPos = getPositionDragAndDrop(target);
	var mousePos=mouseCoords(ev);
	return {x:mousePos.x-docPos.x, y:mousePos.y-docPos.y};
}

function getPositionDragAndDrop(e)
{
	var left=0,
	    top=0;

	while (e.offsetParent)
	{
		left+=e.offsetLeft;
		top+=e.offsetTop;
		e=e.offsetParent;
	}

	left+=e.offsetLeft;
	top+=e.offsetTop;

	return {x:left, y:top};
}

function mouseCoords(ev)
{
	if(ev.pageX || ev.pageY)
	    return { x: ev.pageX, y: ev.pageY };

	if (document.body == null)
	    return { x: ev.clientX, y: ev.clientY };

	return {x:ev.clientX+document.body.scrollLeft-document.body.clientLeft,
		    y:ev.clientY+document.body.scrollTop-document.body.clientTop};
}

function mouseMove(ev)
{
	ev= ev || window.event;
	var mousePos = mouseCoords(ev);

	if(__dragAndDrop_dragObject) {
	    __dragAndDrop_dragObject.style.position = 'absolute';
		__dragAndDrop_dragObject.style.top=mousePos.y-__dragAndDrop_mouseOffset.y;
		__dragAndDrop_dragObject.style.left = mousePos.x - __dragAndDrop_mouseOffset.x + __dragAndDrop_marginOffset;
		$(__dragAndDrop_dragObject).css({ 'position': 'absolute', 'top': mousePos.y - __dragAndDrop_mouseOffset.y, 'left': mousePos.x - __dragAndDrop_mouseOffset.x + __dragAndDrop_marginOffset });
		return false;
	}
}

function mouseUp()
{
	__dragAndDrop_dragObject = null;
}

function makeDraggable(item,offset)
{
	if(!item) return;
	if(offset)
	    __dragAndDrop_marginOffset=offset;
	else
	    __dragAndDrop_marginOffset = 0;

	item.onmousedown=function(ev)
	{
		__dragAndDrop_dragObject=this;
		__dragAndDrop_mouseOffset=getMouseOffset(this, ev);
		return false;
	}
}

;function NumericKeyDown(event,e)
{
    if (IsControlKey(event))
        return true;

    if (IsFuncKey(event))
        return true;


    if(IsNumbericKey(event))
        return true;

    return false;
}

;var __base_version=1,
    __show_errors=false;


function GetKeyCode(event) 
{
    // cross-browser technique for getting an event reference
    var e = (!event) ? window.event : event;

    // cross browser technique for getting the key that was pressed
    var code = (e.which)?e.which : e.keyCode;
    return code;
}

function IsControlKey(event) 
{
    // cross-browser technique for getting an event reference
    var e = (!event) ? window.event : event;

    if (e.altKey == true)
        return true;
    if (e.ctrlKey == true)
        return true;
    
    return false;
}
function IsTabKey(event) 
{
    return (GetKeyCode(event) == 9);
}
function IsShiftKey(event)
{
    return (GetKeyCode(event) == 16);
}
function IsFuncKey(event) 
{
    var code = GetKeyCode(event);
    if (code == 8) //Backspace
        return true;

    if (code == 46) //Delete
        return true;

    if (code == 9) //Tab
        return true;

    if (code == 37) //Left arrow
        return true;

    if (code == 39) //Right arrow
        return true;

    if (code == 38) //Up arrow
        return true;

    if (code == 40) //Down arrow
        return true;

    if (code == 36) //Home
        return true;

    if (code == 35) //End
        return true;

    if (code == 39) //Page Up
        return true;

    if (code == 39) //Page Down
        return true;
        
    return false;
}
function IsUpArrowKey(event) {
    return (GetKeyCode(event) == 38);  //Up arrow
}
function IsDownArrowKey(event)
{
    return (GetKeyCode(event) == 40);  //Down arrow
}
function IsLeftBracketKey(event) 
{
    // cross-browser technique for getting an event reference
    var e = (!event) ? window.event : event;

    if ((e.shiftKey == true) && (GetKeyCode(event) == 9))
        return true;
        
    return false;
}
function IsRightBracketKey(event) 
{
    var e = (!event) ? window.event : event;

    if((e.shiftKey==true) && (GetKeyCode(event)==0))
        return true;
        
    return false;
}
function IsNumbericKey(event) 
{
    var code = GetKeyCode(event);
    var e = (!event) ? window.event : event;


    if(e.shiftKey==true)
        return false;
        
 
    // 0 ---- 48
    // 9 ---- 57           
    if((code>47) &&(code<58))
        return true;

    // 0 ---- 96
    // 9 ---- 105
    if ((code > 95) && (code < 106))
        return true;
        
    return false;
}
function EnableControlOnCheckBoxClick(checkBoxId,controlId,onclick)
{
	var eCheckBox=$get(checkBoxId);
	if(eCheckBox==null)
		return;

	var eControl=$get(controlId);
	if(eControl==null)
		return;

    eControl.disabled = eCheckBox.checked ? false : true;
    eControl.className = "button";
	
	//At this point, I deliberately built this into the function even though it creates
	//a nongeneric bahavior in a seemingly generic function. I did this to minimize the 
	//number of changes that would occur if I added a paramater ("onclick") and changed
	//it everywhere it's called. Currently, the only time that this function is used
	//is to associate the Verify checkbox with the Finish button. This will have to change
	//if we decide to start using it generically.
    if(eControl.onclick==null)
    {
        eControl.onclick="$get('"+controlId+"').style.visibility='hidden'";

        if (eControl.addEventListener)  
            eControl.addEventListener('click',new Function(eControl.onclick),false); 
        else if (eControl.attachEvent)  
            eControl.attachEvent('onclick',new Function(eControl.onclick)); 
    }
}

function CopySelectedItemToTextArea(listId,txtId,option,maxLen,resetSelection)
{
    //Option==0: Override txtId content w/selected VALUE
    //Option==1: Append selected VALUE to the beginning
    //Option==2: Append selected VALUE to the end
    //Option==3: Override txtId content w/selected TEXT
    //Option==4: Append selected TEXT to the beginning
    //Option==5: Append selected TEXT to the end
    
    if(option<0)
        return;
    if(option>5)
        return;
    var eList=$get(listId);
    if((eList==null) || (eList.selectedIndex < 0))
        return;
    var eTextArea=$get(txtId);
    if(eTextArea==null)
        return;

    var selectedText = "";
    if (option < 3)
        selectedText = eList.options[eList.selectedIndex].value;
    else
        selectedText = eList.options[eList.selectedIndex].text;

    if (eList.selectedIndex == 0 || selectedText.length == 0 || selectedText == "< N/A >" || selectedText == "< Select ... >" || selectedText == "< Blank >")
        return;
    
    if((option == 0 || option == 3) && CheckMaxLengthAndShowMessage(selectedText, maxLen))
        eTextArea.value=selectedText;
    else if (option == 1 || option == 4)
    {
        var newValue=selectedText;
        if(eTextArea.value.length>0)
            newValue=newValue+"; " + eTextArea.value;
        
        if (CheckMaxLengthAndShowMessage(newValue, maxLen))
            eTextArea.value=newValue;
    }
    else if (option == 2 || option == 5)
    {
        var newValue=eTextArea.value;
        if(newValue.length>0)
            newValue=newValue+"; ";
        
        newValue=newValue+selectedText;
        
        if (CheckMaxLengthAndShowMessage(newValue, maxLen))
            eTextArea.value=newValue;
    }
    
    if (resetSelection == "True")
        eList.selectedIndex=0;
}
function CheckMaxLengthAndShowMessage(text,maxLen)
{
    if (maxLen == 0)
        return true;
        
    if (text.length >= maxLen)
    {
        msg = 'Cannot add data because the maximum number '; 
        msg += 'of allowable characters (' + maxLen + ') '; 
        msg += 'will be exceeded.  Your data was not added.  Please check your data.'; 

        alert(msg);
        
        return false;
    }
    
    return true;
}
function CopySelectedItemToTextAreaWithoutSemicolon(listId, txtId, option, maxLen, resetSelection)
{
    //Option==0: Override txtId content w/selected VALUE
    //Option==1: Append selected VALUE to the beginning
    //Option==2: Append selected VALUE to the end
    //Option==3: Override txtId content w/selected TEXT
    //Option==4: Append selected TEXT to the beginning
    //Option==5: Append selected TEXT to the end
    
    if(option<0)
        return;
    if(option>5)
        return;
    var eList=$get(listId);
    if ((eList == null) || (eList.selectedIndex < 0))
        return;
    var eTextArea=$get(txtId);
    if(eTextArea==null)
        return;

    var selectedText = "";
    if (option < 3)
        selectedText = eList.options[eList.selectedIndex].value;
    else
        selectedText = eList.options[eList.selectedIndex].text;

    if (eList.selectedIndex == 0 || selectedText.length == 0 || selectedText == "< N/A >" || selectedText == "< Select ... >" || selectedText == "< Blank >")
        return;

    if ((option == 0 || option == 3) && CheckMaxLengthAndShowMessage(selectedText, maxLen))
        eTextArea.value=selectedText;
    else if (option == 1 || option == 4)
    {
        var newValue=selectedText;
        if(eTextArea.value.length>0)
            newValue=newValue+" " + eTextArea.value;
        
        if (CheckMaxLengthAndShowMessage(newValue, maxLen))
            eTextArea.value=newValue;
    }
    else if (option == 2 || option == 5)
    {
        var newValue=eTextArea.value;
        if(newValue.length>0)
            newValue=newValue+" ";
        
        newValue=newValue+selectedText;
        
        if (CheckMaxLengthAndShowMessage(newValue, maxLen))
            eTextArea.value=newValue;
    }

    if (resetSelection == "True")
        eList.selectedIndex = 0;
}

function getScreenCenterY() 
{   
    return getScrollOffset()+(getInnerHeight()/2);   
}   
  
function getScreenCenterX() 
{   
    return(document.body.clientWidth/2);   
}   
  
function getInnerHeight() 
{   
    var y;   
    if (self.innerHeight)   
        y = self.innerHeight;   
    else if (document.documentElement && document.documentElement.clientHeight)  
        y = document.documentElement.clientHeight;   
    else if (document.body) 
        y = document.body.clientHeight;   
    return y;   
}   
  
function getScrollOffset() 
{   
    var y;   
    if (self.pageYOffset)  
        y = self.pageYOffset;   
    else if (document.documentElement && document.documentElement.scrollTop)   
        y = document.documentElement.scrollTop;   
    else if (document.body)  
        y = document.body.scrollTop;   
    return y;   
}

//  ** NOTHING ** should use this function in the future.  The proper way to do this
//  is with the $get function.  However, there are alot of places calling it and it handles
//  errors (invalid parameters) differently than $get().  Specifically, if 'arguments' are
//  undefined, this function just silently returns null while $get blows up.  This was originally
//  named "$" which conflicted with jQuery so to avoid breaking anything and to fix this conflict,
//  renamed this method to $getControl.  When possible, any callers of this function should be
//  changed to call $get.
$getControl=function()
{
  var elements = new Array();

  for (var i=0;i<arguments.length;i++) 
  {
    var element=arguments[i];
    if (typeof(element)=='string')element=document.getElementById(element);
    if (arguments.length==1)return element;

    elements.push(element);
  }
  return elements;
}

document.FindElements=function(element,tag)
{
    var elementsFound=new Array();
    
    if(tag==undefined || tag==null)
        tag='*';
        
    var elements=document.getElementsByTagName(tag);
    for(var i=0;i<elements.length;i++)
    {
        if(elements[i].id.search(element)>-1)
            elementsFound.push(elements[i]);
    }
    return elementsFound;
}

__getGUID=function()
{
    var hex=function(){return (((1+Math.random())*0x10000)|0).toString(16).substring(1)}
    return (hex()+hex()+hex()+hex()+hex()+hex()+hex()+hex()).toUpperCase();
}

__handle_error=function(err)
{
    if(__show_errors)throw err;
    return err.description;
}


function StyleSheet (style_sheet)
{
    this.Sheet=(style_sheet==null)?null:this.Get(style_sheet);
}

//************************StyleSheet
StyleSheet.prototype.Get=function(style_sheet)
{
    if(style_sheet==null)
    {
        return document.styleSheets[0];
    }
    else
    {
        for (i=0;i<document.styleSheets.length;i++)
        {
            if(document.styleSheets[i].href.search(style_sheet+'.css')>-1)
            {
                return document.styleSheets[i];
            }
        }
    }
}

StyleSheet.prototype.GetAttribute=function(className, attribute)
{
    if(this.Sheet==null)
        return '';
        
    var sheet=this.Sheet;

    try
    {
        for (i=0;i<sheet.rules.length;i++)
        {
            if(sheet.rules[i].selectorText.toLowerCase().indexOf(className.toLowerCase())>-1)
                return eval('sheet.rules[i].style.'+attribute);
        }
    }
    catch(e){}

    return '';
}
//*************************************************************

function FormatControl(control, required)
{
    if (control != null && control != 'undefined') {
        $(control).find('font').remove();

        if (required)
            control.innerHTML = "<font color=red>*</font>" + control.innerHTML;
    }
}

function findPosX(obj)
{
    return getPosition(obj).x;
}

function findPosY(obj)
{
    return getPosition(obj).y;
}

function getPosition(element)
{
    var left = 0;
    var top = 0;

    if (element != null)
    {
        // Try because sometimes errors on offsetParent after DOM changes.
        try
        {
            while (element.offsetParent)
            {
                // While we haven't got the top element in the DOM hierarchy
                // Add the offsetLeft
                left += element.offsetLeft;
                // If my parent scrolls, then subtract the left scroll position
                if (element.offsetParent.scrollLeft) { left -= element.offsetParent.scrollLeft; }

                // Add the offsetTop
                top += element.offsetTop;
                // If my parent scrolls, then subtract the top scroll position
                if (element.offsetParent.scrollTop) { top -= element.offsetParent.scrollTop; }

                // Grab
                element = element.offsetParent;
            }
        }
        catch (e)
        {
            // Do nothing
        }

        // Add the top element left offset and the windows left scroll and subtract the body's client left position.
        left += element.offsetLeft + document.body.scrollLeft - document.body.clientLeft;

        // Add the top element topoffset and the windows topscroll and subtract the body's client top position.
        top += element.offsetTop + document.body.scrollTop - document.body.clientTop;
    }

    return { x: left, y: top };
}

//  Show or Hide a div element if the caps lock key is currently pressed.
//  Use this like this: onkeypress="CheckCapsLock(event, 'divChangePassCapsOn')
//  on a Password input control to warn the user if Caps Lock is currently on.
function CheckCapsLock(e, divName)
{
    kc = e.keyCode ? e.keyCode : e.which;
    sk = e.shiftKey ? e.shiftKey : ((kc == 16) ? true : false);
    if (((kc >= 65 && kc <= 90) && !sk) || ((kc >= 97 && kc <= 122) && sk))
        document.getElementById(divName).style.visibility = 'visible';
    else
        document.getElementById(divName).style.visibility = 'hidden';
}

function GetParameterFromQueryString(key) {
    hu = window.location.search.substring(1);
    gy = hu.split("&");

    for (i = 0; i < gy.length; i++) {
        ft = gy[i].split("=");
        if (ft[0] == key)
            return ft[1];
    }
}
;
    function PhoneKeyDown(event,e) {
    
	    if(IsControlKey(event))
	        return true;
	        
        if(IsFuncKey(event))
            return true;

        if(IsLeftBracketKey(event))
            return true;
            
        if(IsRightBracketKey(event))
            return true;
        
        if(IsNumbericKey(event))
            return true;
                
        if(IsOtherValidPhoneKey(event))
            return true;

        return false;
    }
    
    function PhoneKeyDownOption(event,e,dropDownID)
    {
        var dropDown = $get(dropDownID);

        if (dropDown.value.toUpperCase() != "EMAIL")
            return PhoneKeyDown(event, e);

        return true;
    }
    
    function PhoneFocusOut(event,e, isFax)
    {
        var s=e.value,
            phone="",
            temp="";
        
        for(i=0; i<s.length; i++)
        {
            temp=s.substr(i,1);
            
            if(temp < "0")
              continue;
            if(temp > "9")
              continue;
            
            phone+=temp;
        }
        if(phone.length==0)
            return;
            
        if(isFax)
        {
            if(phone.length != 10)
            {
                alert("Please enter a 10 digit fax number");
                e.focus();
                return;
            }
        }
        else if(phone.length<10)
        {
            alert("Please enter a minimum of 10 digits for the phone number");
            e.focus();
            return;
        }
        var newPhone ="("+phone.substr(0,3)+") "+phone.substr(3,3)+" - "+phone.substr(6,4);
        if(phone.length>10)
            newPhone=newPhone+" x"+phone.substr(10,phone.length-10);
            
        e.value=newPhone;

    }
    
    function PhoneFocusOutOption(event,e, dropDownID)
    {
    
        var dropDown = $get(dropDownID);

        if (dropDown.value.toUpperCase() != "EMAIL")
            PhoneFocusOut(event,e,0);

    }
    
    function IsOtherValidPhoneKey(event) {

        var code = GetKeyCode(event);

        if(code==189) //"-" key
            return true;
        
        if(code==88) //"x" key
            return true;
    
        return false;
    }


    //on page load, we need to override a function in the ajax control tool kit to fix a webkit issue with backspacing in the 
    //text box when it's masked


    //_ExecuteNav
    var _ExecNavOverride = function (evt, scanCode) {
        if (evt.type == "keydown") {
            if (Sys.Browser.agent == Sys.Browser.InternetExplorer) {
                if ((scanCode == 86 || scanCode == 118) && !evt.shiftKey && evt.ctrlKey && !evt.altKey) {
                    this._SetCancelEvent(evt);
                    this._PasteFromClipBoard();
                    return;
                }
                if (evt.shiftKey && !evt.ctrlKey && !evt.altKey && evt.keyCode == 45) {
                    this._SetCancelEvent(evt);
                    this._PasteFromClipBoard();
                    return;
                }
            }
        }
        if (Sys.Browser.agent != Sys.Browser.InternetExplorer || evt.type == "keypress") {
            if (evt.rawEvent.shiftKey && !evt.rawEvent.ctrlKey && !evt.rawEvent.altKey && evt.rawEvent.keyCode == 45) {
                this._SetCancelEvent(evt);
                this._PasteFromClipBoard();
                return;
            }
            if (evt.type == "keypress" && (scanCode == 86 || scanCode == 118) && !evt.shiftKey && evt.ctrlKey && !evt.altKey) {
                this._SetCancelEvent(evt);
                this._PasteFromClipBoard();
                return;
            }
        }
        if (Sys.Browser.agent == Sys.Browser.InternetExplorer || evt.type == "keydown") {
            if (scanCode == 8) {
                this._SetCancelEvent(evt);
                curpos = this._deleteTextSelection();
                if (curpos != -1) {
                    this.setSelectionRange(curpos, curpos);
                } else {
                    curpos = this._getCurrentPosition();
                    this._backspace(curpos);
                    curpos = this._getPreviousPosition(curpos - 1);
                    this.setSelectionRange(curpos, curpos);
                }
                var wrapper = AjaxControlToolkit.TextBoxWrapper.get_Wrapper(this.get_element());
                if (this._MessageValidatorTip && wrapper.get_Value() == this._EmptyMask) {
                    this.ShowTooltipMessage(true);
                }
                if (Sys.Browser.agent == Sys.Browser.Opera) {
                    this._SaveText = wrapper.get_Value();
                    this._SavePosi = curpos;
                    this._timer.set_enabled(false);
                    this._timer.set_interval(1);
                    this._timer.set_enabled(true);
                }
            } else if (scanCode == 46 || scanCode == 127) {
                this._SetCancelEvent(evt);
                var wrapper = AjaxControlToolkit.TextBoxWrapper.get_Wrapper(this.get_element());
                curpos = this._deleteTextSelection();
                if (curpos == -1) {
                    curpos = this._getCurrentPosition();
                    if (!this._isValidMaskedEditPosition(curpos)) {
                        if (curpos != this._LogicLastInt && this._InputDirection != AjaxControlToolkit.MaskedEditInputDirections.RightToLeft) {
                            curpos = this._getNextPosition(curpos);
                        }
                    }
                    this._deleteAtPosition(curpos, false);
                } else {
                    if (this._InputDirection == AjaxControlToolkit.MaskedEditInputDirections.RightToLeft) {
                        ClearText = this._getClearMask(wrapper.get_Value());
                        if (ClearText != "") {
                            ClearText = ClearText.replace(new RegExp("(\\" + this.get_CultureThousandsPlaceholder() + ")", "g"), "") + '';
                            if (ClearText.substring(ClearText.length - 1, ClearText.length) == this.get_CultureDecimalPlaceholder()) {
                                ClearText = ClearText.substring(0, ClearText.length - 1);
                                this.loadValue(ClearText, this._LogicLastInt);
                            } else {
                                this.loadValue(ClearText, this._LogicLastPos);
                            }
                        }
                    }
                }
                this.setSelectionRange(curpos, curpos);
                if (this._MessageValidatorTip && wrapper.get_Value() == this._EmptyMask) {
                    this.ShowTooltipMessage(true);
                }
                if (Sys.Browser.agent == Sys.Browser.Opera) {
                    this._SaveText = wrapper.get_Value();
                    this._SavePosi = curpos;
                    this._timer.set_enabled(false);
                    this._timer.set_interval(1);
                    this._timer.set_enabled(true);
                }
            } else if (evt.ctrlKey) {
                if (scanCode == 39 || scanCode == 35 || scanCode == 34) {
                    this._DirectSelText = "R";
                    if (Sys.Browser.agent == Sys.Browser.Opera) {
                        return;
                    }
                    this._SetCancelEvent(evt);
                    curpos = this._getCurrentPosition();
                    this.setSelectionRange(curpos, this._LogicLastPos + 1);
                } else if (scanCode == 37 || scanCode == 36 || scanCode == 33) {
                    this._DirectSelText = "L";
                    if (Sys.Browser.agent == Sys.Browser.Opera) {
                        return;
                    }
                    this._SetCancelEvent(evt);
                    curpos = this._getCurrentPosition();
                    this.setSelectionRange(this._LogicFirstPos, curpos);
                }
            } else if (scanCode == 35 || scanCode == 34) {
                this._DirectSelText = "R";
                if (Sys.Browser.agent == Sys.Browser.Opera) {
                    return;
                }
                this._SetCancelEvent(evt);
                if (evt.shiftKey) {
                    curpos = this._getCurrentPosition();
                    this.setSelectionRange(curpos, this._LogicLastPos + 1);
                } else {
                    this.setSelectionRange(this._LogicLastPos + 1, this._LogicLastPos + 1);
                }
            } else if (scanCode == 36 || scanCode == 33) {
                this._DirectSelText = "L";
                if (Sys.Browser.agent == Sys.Browser.Opera) {
                    return;
                }
                this._SetCancelEvent(evt);
                if (evt.shiftKey) {
                    curpos = this._getCurrentPosition();
                    this.setSelectionRange(this._LogicFirstPos, curpos);
                } else {
                    this.setSelectionRange(this._LogicFirstPos, this._LogicFirstPos);
                }
            } else if (scanCode == 37) {
                this._DirectSelText = "L";
                if (Sys.Browser.agent == Sys.Browser.Opera) {
                    return;
                }
                this._SetCancelEvent(evt);
                if (evt.shiftKey) {
                    var BoundSel = this._GetBoundSelection();
                    if (BoundSel) {
                        if (BoundSel.left > this._LogicFirstPos) {
                            BoundSel.left--;
                        }
                        this.setSelectionRange(BoundSel.left, BoundSel.right);
                    } else {
                        var pos = this._getCurrentPosition();
                        if (pos > this._LogicFirstPos) {
                            this.setSelectionRange(pos - 1, pos);
                        }
                    }
                } else {
                    curpos = this._getCurrentPosition() - 1;
                    if (curpos < this._LogicFirstPos) {
                        curpos = this._LogicFirstPos;
                    }
                    this.setSelectionRange(curpos, curpos);
                }
                if (Sys.Browser.agent == Sys.Browser.Opera) {
                    var wrapper = AjaxControlToolkit.TextBoxWrapper.get_Wrapper(this.get_element());
                    this._SaveText = wrapper.get_Value();
                    this._SavePosi = curpos;
                    this._timer.set_enabled(false);
                    this._timer.set_interval(1);
                    this._timer.set_enabled(true);
                }
            } else if (scanCode == 39) {
                this._DirectSelText = "R";
                if (Sys.Browser.agent == Sys.Browser.Opera) {
                    return;
                }
                this._SetCancelEvent(evt);
                if (evt.shiftKey) {
                    var BoundSel = this._GetBoundSelection();
                    if (BoundSel) {
                        if (BoundSel.right < this._LogicLastPos + 1) {
                            BoundSel.right++;
                        }
                        this.setSelectionRange(BoundSel.left, BoundSel.right);
                    } else {
                        pos = this._getCurrentPosition();
                        if (pos < this._LogicLastPos + 1) {
                            this.setSelectionRange(pos, pos + 1);
                        }
                    }
                } else {
                    curpos = this._getCurrentPosition() + 1;
                    if (curpos > this._LogicLastPos + 1) {
                        curpos = this._LogicLastPos + 1;
                    }
                    this.setSelectionRange(curpos, curpos);
                }
                if (Sys.Browser.agent == Sys.Browser.Opera) {
                    var wrapper = AjaxControlToolkit.TextBoxWrapper.get_Wrapper(this.get_element());
                    this._SaveText = wrapper.get_Value();
                    this._SavePosi = curpos;
                    this._timer.set_enabled(false);
                    this._timer.set_interval(1);
                    this._timer.set_enabled(true);
                }
            } else if (scanCode == 27) {
                this._SetCancelEvent(evt);
                var wrapper = AjaxControlToolkit.TextBoxWrapper.get_Wrapper(this.get_element());
                if (this._EmptyMask == this._initialvalue) {
                    wrapper.set_Value("");
                } else {
                    wrapper.set_Value(this._initialvalue);
                }
                this._onFocus();
            }
        }
        this._SetCancelEvent(evt);
    }
//    $(function () {
//        overrideExec();

//    });
    function overrideExec() {
//        if (!window.HasOverriddenNav) {
        try { p = AjaxControlToolkit.MaskedEditBehavior.prototype; } catch (e) { p = null; }
            if (p != null) {
                p._ExecuteNav = _ExecNavOverride;
            }
//            window.HasOverriddenNav = true;
//        }
    }
;    function ZipcodeFocusOut(event,e)
    {
        var zip=e.value;

        if (zip == null || zip == "")
            return;
            
        if (zip.match(/^\d{5}(-\d{4})?$/)) 
        {
            e.value=zip;
            return;
        }

        zip=zip.toUpperCase();
        if (zip.match(/^[ABCEGHJKLMNPRSTVXY]\d[A-Z] \d[A-Z]\d$/)) 
        {
            e.value=zip;
            return;
        }

        alert('Zip code is Invalid.');
        
        e.focus();
        
    }

    

;function FreeTextKeyDown(event,e,maxLen)
{

    if (IsControlKey(event))
        return true;

    if (IsFuncKey(event))
        return true;

    if (e.value.length >= maxLen)
        return false;

    return true;
     
}
function FreeTextOnPaste(event,e,maxLen) 
{ 
    var Data = window.clipboardData.getData('Text'); 
    var SelText; 
    var Range; 
    var msg; 

    if (maxLen != null) 
    { 
        Range = window.document.selection.createRange(); 
        SelText = Range.text; 


        if (SelText != null && SelText != '' && SelText != undefined) 
        { 
            if ((e.value.length - SelText.length) + Data.length < maxLen) 
            { 
                return; 
            } 
        } 

        if (e.value.length + Data.length >= maxLen) 
        { 
            msg = 'Cannot paste complete data because the maximum number '; 
            msg += 'of allowable characters (' + maxLen + ') '; 
            msg += 'will be exceeded.  Your data has been cut off at the maximum number ';
            msg += 'of characters allowed.  Please check your data.'; 

            alert(msg); 
            e.value += Data;
            e.value = e.value.substr(0, maxLen);

            event.returnValue=false;; 
        } 
    } 
} 

;/*
	Utility functions for working with JS events.
	
	Based on code from http://blog.keithpatton.com/CommentView,guid,ea20813e-f68b-47ad-a2a9-8ef390adfe1d.aspx
	and http://simonwillison.net/2004/May/26/addLoadEvent/)
*/

// event worker object constructor
function EventUtils()
{
	this.addHandler = EventUtils.addHandler;
}
EventUtils.addHandler =
	function (objRefOrID, eventName, func) 
	{
		// Adds a new event handler to an event, maintaining any existing handlers already assigned.
		//	 objRefOrID: either an object reference or a DOM ID string
		//	 eventName: the event name to attach to (without the "on", e.g. for click event use "click")
		//	 func: a function pointer to the event handler to run
		
		var obj = null;
		var eventRef;
		var eventHandlers;

		try 
		{
			if (typeof objRefOrID == "object")
				obj = objRefOrID;
			else if (objRefOrID == "window")
				obj = window;
			else if (objRefOrID == "document")
				obj = document;
			else
				obj = document.getElementById(objRefOrID);
				
			if (obj == null)
				throw("Invalid object reference.");

			eventRef = "obj.on" + eventName;
			eventHandlers = eval(eventRef);
			
			if (typeof eventHandlers == "function") // not first handler
				eval(eventRef + " = function(event) {eventHandlers(event); func(event);}");  
			else // first handler
				eval(eventRef + " = func;");
		}
		catch (err)
		{
			/* Debug statements 
			var objID = "unknown";
			if (typeof objRefOrID == "string")
				objID = objRefOrID;
			else if ((typeof obj == "object") && (obj != null))
				objID = obj.id;

			alert("While adding handler to '" + objID + "." + eventName + "': " + err.description);
			*/
		}
	}
	
// Use EventUtils like:
// EventUtils.addHandler("window", "load", someEventHandler);
// function someEventHandler(e) { 
//	  if (!e) e = window.event; 	
// }

;var __IrthErrorVersion=1;

///<Documentation>
///<Class name="IrthError">
///<Constructor>
///<summary>Error constructor</summary>
///<param name="originator" type="string" required="false">
///     The name of the object throwing the error.
///</param>
///<param name="functionName" type="string" required="false">
///     The name of the function within the object that is throwing the error.
///</param>
///<param name="description" type="string" required="false">
///     A brief description of the error.
///</param>
function IrthError(originator,functionName,description)
{
    this.Originator=obj;
    this.Function=func;
    this.Description=desc;
}
///</Constructor>

///<Methods>
///<Method name="Throw">
///<summary>Throws a custom WebControl error</summary>
///<returns>HTML object</returns>
IrthError.prototype.Throw=function()
{
    throw new Error("Irth Error\nObject: "+this.Originator+"\nFunction: "+this.Function+"\nDescription: "+this.Description);
} 
///</Method>
///</Methods>
///</Class>
///</Documentation>
;__ModalDialogue_version = 1;

///<Documentation>
///<Class name="ModalDialogue">
///<Constructor>
///<summary>ModalDialogue constructor</summary>
///<param name="id" type="string" required="false">
///     The id to be assigned to the HTML control generated from the Render()
///     function. If this is not provided, than a GUID is automatically assigned.
///</param>
///<param name="caption" type="string" required="false">
///     The name to be displayed as a caption for the modal dialogue
///</param>
///<param name="text" type="string" required="false">
///     The message to be displayed in the dialogue.
///</param>
///<param name="type" type="integer" required="false">
///     The type of Modal dialogue box to be displayed. Currently supported:
///     0 - Informational (OK button only)
///     1 - Confirmation (Yes and No buttons)
///</param>
function ModalDialogue(caption, text) {

    if (__base_version == undefined && __IrthErrorVersion > 0)
        new IrthError("ModalDialogue", "Constructor", "Object requires the inclusion of the GeneralScript.js file.").Throw();
    if (__dragAndDrop_version == undefined && __IrthErrorVersion > 0)
        new IrthError("ModalDialogue", "Constructor", "Object requires the inclusion of the DragAndDrop.js file.").Throw();

    this.Title = (caption == undefined || caption == null) ? '' : caption;
    this.Text = (text == undefined || text == null) ? '' : text;
    this.ID = __getGUID();
    this.BackdropID = this.ID + 'modal';
    //this.EnableClose = true;
    this.Buttons = new Array();
    this.ImagesLocation = '../Images/';
    this.Draggable = true;
    this.NoButtons = false;
}
///</Constructor>

///<Method name="AddButton">
///<summary>Adds a button to the Modal Dialogue box</summary>
///<returns>void</returns>
ModalDialogue.prototype.AddButton = function (text, onclick) {
    this.Buttons.push(new Button(text, onclick));
}
///</Method>

///<Method name="ClearButtons">
///<summary>Clears all buttons from the Modal Dialogue box</summary>
///<returns>void</returns>
ModalDialogue.prototype.ClearButtons = function () {
    this.Buttons.clear();
}
///</Method>

///<Method name="ClearButtons">
///<summary>Clears all buttons from the Modal Dialogue box</summary>
///<returns>void</returns>
ModalDialogue.prototype.Dispose = function (backdropID) {
    document.body.removeChild($getControl(this.ID));
    document.body.removeChild($getControl(this.BackdropID));
}
///</Method>

///<Method name="Show">
///<summary>Shows the Modal Dialogue box</summary>
///<returns>HTML object</returns>
ModalDialogue.prototype.Show = function (container) {
    var dialogueContainer = document.createElement("DIV"),
        dialogue = document.createElement("TABLE"),
        title = dialogue.insertRow(-1),
        filler = title.insertCell(-1),
        titleText = title.insertCell(-1),
        close = title.insertCell(-1),
        text = dialogue.insertRow(-1).insertCell(-1),
        buttonContainer = dialogue.insertRow(-1).insertCell(-1),
        //closeImage = document.createElement("IMG"),
        backdropID = this.BackdropID,
        closeOnClick = "__ModalDialogue_toggle('" + this.ID + "', '" + this.BackdropID + "')",
        compFunc,
        button;

    if (this.Buttons.length == 0 && !this.NoButtons)
        this.Buttons.push(new Button('OK'));

    if (container === undefined || container === null) {
        var modalBackdrop = document.createElement("DIV");
        modalBackdrop.className = 'ModalDialogueBackground';
        modalBackdrop.id = backdropID;
        modalBackdrop.style.width = document.body.clientWidth;
        modalBackdrop.style.height = document.body.clientHeight;
        $(modalBackdrop).css({ "width": document.body.clientWidth, "height": document.body.clientHeight });
        document.body.appendChild(modalBackdrop);
    }
    else {
        container.className = 'ModalDialogueBackground';
        backdropID = container.id;
    }

    dialogueContainer.className = 'ModalDialogueContainer';
    dialogueContainer.id = this.ID;

    if (typeof container === 'undefined' || container === null)
        document.body.appendChild(dialogueContainer);
    else
        container.appendChild(dialogueContainer);

    dialogue.className = 'ModalDialogue';

    title.className = 'ModalDialogueTitle';

    titleText.className = 'ModalDialogueTitleText';
    titleText.innerHTML = this.Title;

//    if (this.EnableClose) {
        //close.className = 'ModalDialogueClose';
        //closeImage.src = this.ImagesLocation + 'close.PNG';
        //closeImage.onclick = new Function(closeOnClick);
        //closeImage.onmouseover = "this.src='" + this.ImagesLocation + "close_hover.PNG'";
        //closeImage.onmouseout = "this.src='" + this.ImagesLocation + "close.PNG'";
        //closeImage.alt = 'X';
        //close.appendChild(closeImage);
//    }

    text.className = 'ModalDialogueText';
    text.colSpan = 3;
    text.innerHTML = this.Text;

    buttonContainer.className = 'ModalDialogueButtonContainer';
    buttonContainer.colSpan = 3;

    for (var i = 0; i < this.Buttons.length; i++) {
        button = document.createElement("INPUT");
        button.type = 'button';
        this.Buttons[i].onClick = (this.Buttons[i].onClick == null) ? closeOnClick : closeOnClick + ';' + this.Buttons[i].onClick;
        compFunc = (function (i, buttons) { return new Function(buttons[i].onClick); } (i, this.Buttons));
        button.onclick = compFunc;
        button.id = this.ID + '_close_' + i;
        button.className = 'ModalDialogueButton';
        button.value = this.Buttons[i].Text;

        if (i > 0) {
            var space = document.createElement("span");
            space.innerHTML = "&nbsp;";
            buttonContainer.appendChild(space);
            //buttonContainer.innerHTML += '&nbsp;';
        }
        buttonContainer.appendChild(button);
    }

    //dialogueContainer.innerHTML = dialogue.outerHTML;
    dialogueContainer.appendChild(dialogue);

    if (this.Draggable)
        makeDraggable(dialogueContainer, 250);

    __ModalDialogue_toggle(this.ID, this.BackdropID);

    //This is to stop the positioning of the Dialogue on Mobile being placed off the screen when the user is zoomed in and presses the Cancel button
    // since the modal cannot access opener.IsTouchDevice() when it loads here we have to check it manually... dumb.
    if ((navigator.userAgent.indexOf('iPod') != -1)||(navigator.userAgent.indexOf('iPhone') != -1)||(navigator.userAgent.indexOf('iPad') != -1)
        ||(navigator.userAgent.indexOf('Android') != -1)||(navigator.userAgent.indexOf('Windows Phone') != -1)||(navigator.userAgent.indexOf('Touch') != -1)) {    
        if ($(window).scrollTop() > 0) {
            window.scrollTo(150, 150);
        }
    }
    else {
        //  The dialog gets positioned at top=25% by the css.  But if the page is currently scrolled, that
        //  can result in the dialog not being visible.  This makes sure it's in view.
        if ($(window).scrollTop() > 0) {
            var dialogOffset = $(dialogueContainer).offset();
            dialogOffset.top = dialogOffset.top + $(window).scrollTop();
            $(dialogueContainer).offset(dialogOffset);
        }
    }

    return dialogueContainer;
}
///</Method>

///<EventMethod name="Show">
///<summary>Shows the Modal Dialogue box</summary>
///<returns>HTML object</returns>
__ModalDialogue_toggle = function (id, backdropID) {
    var md = $getControl(id),
        background = $getControl(backdropID);

    if (!md) return;
    var mdVis = md.style.visibility;
    md.style.visibility = (mdVis == null || mdVis == '') ? 'visible' : (mdVis == 'visible') ? 'hidden' : 'visible';

    if (background) {
        backVis = background.style.visibility;
        background.style.visibility = (backVis == null || backVis == '') ? 'visible' : (backVis == 'visible') ? 'hidden' : 'visible';
    }
    else
        return;

    for (var i = 0; i < document.forms.length; i++)
        document.forms[i].disabled = !document.forms[i].disabled;
    return;
}
///</EventMethod>
///</Methods>
///</Class>

///<Class name="Button">
function Button(text, onclick) {
    this.Text = text;
    this.onClick = onclick;
}
///</Class>

///<UnitTests>
///<Test object="ModalDialogue" name="Show()" description="Tests to ensure that the modal dialogue displays properly." type="positive">
ModalDialogue_Show = function () {
    try {
        var md = new ModalDialogue('Pop-up blocker is enabled!', 'This site requires the use of pop ups. <br /><br />In order to use the site without a problem, you will need to disable the Pop-up blocker before entering. This can be done by: <br />1. Click on the bar directly above this box ("Pop-up blocked. To see this pop-up or additional options click here...") <br />2. Select "Always Allow Pop-ups from This Site..."');
        __actual = md.Show().innerHTML;
        __expected = '';
        return __actual == __expected;
    }
    catch (err) { __actual = __handle_error(err) }
    return false;
}
///</Test>
///</UnitTests>
///</Documentation>




;__ModalDialogue_version = 1;

///<Documentation>
///<Class name="Browser">
///<Constructor>
///<summary>Browser constructor</summary>
Browser = function(){}
///</Constructor>

///<Methods>
///<Method name="GetType">
///<summary>Gets the current type of browser (IE, FireFox, etc)</summary>
///<returns>void</returns>
Browser.prototype.GetType = function() 
{
    return navigator.appName;
}
///</Method>

///<Method name="GetVersion">
///<summary>Gets the current type of browser. This currently only works for IE</summary>
///<returns>void</returns>
Browser.prototype.GetVersion = function() 
{
    var rv = -1; 
    if (navigator.appName == 'Microsoft Internet Explorer') 
    {
        var ua = navigator.userAgent;
        var re = new RegExp("MSIE ([0-9]{1,}[\.0-9]{0,})");
        if (re.exec(ua) != null)
            rv = parseFloat(RegExp.$1);
    }
    return rv;
}
///</Method>

///<Method name="GetVersion">
///<summary>Gets the current type of browser. This currently only works for IE</summary>
///<returns>void</returns>
Browser.prototype.IsSupported = function() 
{
    if (navigator.appName != 'Microsoft Internet Explorer')
        return false;

    if (this.GetVersion < 7.0)
        return false;

    return true;
}

///</Method>
///</Methods>
///</Class>
Browser.prototype.IsIEBrowser = function () {
    if (navigator.appName == 'Microsoft Internet Explorer')
        return true;

    return false;
}


;__exception_version=1;

///<Documentation>
///<Class name="Exception">
///<Constructor>
///<summary>Error constructor</summary>
///<param name="obj" type="string" required="false">
///     The name of the object throwing the error.
///</param>
///<param name="func" type="string" required="false">
///     The name of the function within the object that is throwing the error.
///</param>
///<param name="desc" type="string" required="false">
///     A brief description of the error.
///</param>
function Exception(obj,func,desc)
{
    this.Object=obj;
    this.Function=func;
    this.Description=desc;
}
///</Constructor>

///<Methods>
///<Method name="Throw">
///<summary>Throws a custom WebControl error</summary>
///<returns>HTML object</returns>
Exception.prototype.Throw=function()
{
    throw new Error("WebControl Error\nObject: "+this.Object+"\nFunction: "+this.Function+"\nDescription: "+this.Description);
} 
///</Method>

///<Method name="Attach">
///<summary>Attaches an error description to a user control</summary>
///<returns>HTML object</returns>
Exception.prototype.Attach=function(control)
{
	if(control==null)
 		return;
 		
 	if(typeof control != 'object')
 	    control = $getControl(control);
 
   if (!control.parentNode)
      return;

	if(control.className.indexOf('exception_control')<0)
   	control.className+=' exception_control';

	if ($getControl(control.id + '_exc'))
		return;
		
	var err=document.createElement('IMG');
	err.alt=this.Description;
	err.src='images/error.png';
   err.id=control.id+'_exc';
   control.parentNode.insertBefore(err, control);
   
	var space = document.createElement("SPAN");
	space.id=control.id+'_excspace';
	space.innerHTML='&nbsp';
	control.parentNode.insertBefore(space, control);
} 
///</Method>

///<Method name="Attach">
///<summary>Attaches an error description to a user control</summary>
///<returns>HTML object</returns>
Exception.prototype.Detach=function(control)
{
	if(control==null)
 		return;
 		
 	if(typeof control != 'object')
 	    control = $getControl(control);
 
   if (!control.parentNode)
      return;

   var err = $getControl(control.id + '_exc');
	if(err)
	{
		control.parentNode.removeChild(err);
		control.parentNode.removeChild($getControl(control.id + '_excspace'));
	}
	
	if(control.className.indexOf('exception_control')>=0)
   	control.className=control.className.replace(' exception_control','');
} 
///</Method>

///<Method name="IsAttached">
///<summary>Checks to see if there is an exception attached to the control</summary>
///<returns>HTML object</returns>
Exception.prototype.IsAttached=function(controlID)
{
	if(controlID==null)
 		return;
 		
 	if(typeof control == 'object')
 	    controlID = $getControl(controlID).id;

 	var err = $getControl(controlID + '_exc');
	alert(controlID+'_exc'+'/'+err);
	if(err)
		return true;
	return false;
} 
///</Method>
///</Methods>
///</Class>
///</Documentation>


;__string_version=1;

String.prototype.Contains=function(value)
{
    if(this.search(value)>-1)return true;
    return false;
}

String.prototype.PadZeroes=function(required_string_size,leading) 
{
    leading=(leading==null)?true:leading;
    var zeroes='';
    for(var i=0;i<required_string_size;i++)zeroes+="0";
    if(leading)
        return (zeroes+this).substr(0,required_string_size);
    else
        return (this+zeroes).substr(0,required_string_size);
        
}

String.prototype.Trim=function()
{
	if(this.replace(/ /g,'')=='')
		return '';
		
	return this.replace(/^(\s*)([\W\w]*)(\b\s*$)/,'$2');
}

String.prototype.toCurrency=function()
{
    var val=parseInt(this)
    if(isNaN(val))return this;

    var return_val=this,
        dollars_cents=return_val.split(".");
    dollars_cents[0]=dollars_cents[0].toNumber();
    if(dollars_cents.length>1)
        return_val=dollars_cents[0]+"."+dollars_cents[1].PadZeroes(2,false).substr(0,2);
    else
        return_val=dollars_cents[0]+".00";
    return (val < 0) ? '$getControl(' + return_val.replace('-', '') + ')' : '$' + return_val;
}

String.prototype.toNumber=function()
{
    if(this.indexOf(',')<0)
    {
        var val=this.split('.')[0],
            iterations=parseInt(val.length/3),
            new_val='';
        for(var i=0;i<iterations;i++)
            new_val=','+val.substr(val.length-3*(i+1),3)+new_val;
        new_val=val.substr(0,val.length-iterations*3)+new_val;
        if(val.length%3==0)new_val=new_val.substr(1);
        return new_val;
    }
}

String.prototype.Escape=function()
{
    var re=new RegExp("\n", "gi"),
        new_string=this.replace(re,"\\n");
    re=new RegExp("\r", "gi");
    new_string=new_string.replace(re,"\\r");
    re=new RegExp("\"", "gi");
    new_string=new_string.replace(re,"\\\"");
    re=new RegExp("'", "gi");
    return new_string.replace(re,"\\'");
}

String.prototype.RemoveControlCharacters=function()
{
	return this.replace(/\s/g,'');
}

String.prototype.IsEmpty=function()
{
	if(this==undefined||this==null||this=='')
		return true;
	return false;
}

String.prototype.GetQueryParameterValue = function(key)
{
	return(this.match(new RegExp("[?|&]?" + key + "=([^&]*)"))[1]);
}

String.prototype.insert=function(value, startPosition)
{
	return this.substr(0,startPosition)+value+this.substr(startPosition);
}

String.prototype.count=function(value)
{
	if(!value || value.IsEmpty())
		return 0;
		
	var	occurrences = 0,
			i=0;
	
	while(true)
	{
		i=this.indexOf(value,i);
		if(i<0) break;
		i+=value.length;
		occurrences++;
	}
	
	return occurrences;
}

String.prototype.indexAfter=function(value,occurrences)
{
	if(!value || value.IsEmpty() || !occurrences || occurrences<=0)
		return 0;
		
	var	index=0;
	
	for(var i=0;i<occurrences;i++)
	{
		var idx=this.indexOf(value,index);
		
		if(idx<0) 
		{
			return -1;
			break;
		}
		
		index=idx+value.length;
	}
	
	return index;
}

;Event=function(name)
{
	this.Name=name;
}

Event.prototype.AppendToElement = function(element, script)
{
    if (this.Name == null || element == null)
        return;

    var changeHandler = new Function(script);
    if (element.addEventListener)
        element.addEventListener(this.Name.substr(2), changeHandler, false);
    else if (element.attachEvent)
        element.attachEvent(this.Name, changeHandler);
}
Event.prototype.AddToElement = function(element, script)
{
    if (this.Name == null || element == null)
        return;

    var changeHandler = new Function(script);
    switch (this.Name)
    {
        case 'onmouseover':
            element.onmouseover = script;
            break;
        case 'onmouseout':
            element.onmouseout = script;
            break;
        case 'onchange':
            element.onchange = script;
            break;
        case 'onclick':
            element.onclick = script;
            break;
        case 'onblur':
            element.onblur = script;
            break;
        case 'onfocus':
            element.onfocus = script;
            break;
        case 'onkeyup':
            element.onkeyup = script;
            break;
    }
    if (element.addEventListener)
        element.addEventListener(this.Name.substr(2), changeHandler, false);
    else if (element.attachEvent)
        element.attachEvent(this.Name, changeHandler);
}


Event.prototype.RemoveFromElement=function(element,script)
{
	if(this.Name==null)
		return;	

    var handler=new Function(script);
	if (element.detachEvent)
		element.detachEvent(this.Name,handler); 
	else 
		element.removeEventListener(this.Name.substr(2),handler,false); 

	eval('element.'+this.Name+'=null;'); 
}
 
Event.prototype.ClearAllFromElement=function(element)
{ 
	if(this.Name==null)
		return;
    var fnc=eval('element.'+this.Name);

 	if(fnc==null)
    	return
    	
    if(typeof(fnc)=='string')fnc=new Function(fnc);
   
   	if (element.detachEvent)
        element.detachEvent(this.Name,fnc); 
    else 
        element.removeEventListener(this.Name.substr(2),fnc,false); 
    eval('element.'+this.Name+'=null;'); 
}

Event.prototype.ReplaceOnElement=function(element,script) 
{
	if(this.Name==null)
		return;

    this.ClearFromElement(eventName);
    this.AddToElement(eventName,script);
}

Event.prototype.RefreshAll = function(control)
{
    var control = $getControl(control);
    if (!control) return;

    if (control.OnBlur && !control.OnBlur.IsEmpty())
        new Event('onblur').AddToElement(control, control.OnBlur);

    if (control.OnFocus && !control.OnFocus.IsEmpty())
        new Event('onfocus').AddToElement(control, control.OnFocus);

    if (control.OnKeyUp && !control.OnKeyUp.IsEmpty())
        new Event('onkeyup').AddToElement(control, control.OnKeyUp);

    if (control.OnKeyDown && !control.OnKeyDown.IsEmpty())
        new Event('onkeydown').AddToElement(control, control.OnKeyDown);

    if (control.OnChange && !control.OnChange.IsEmpty())
        new Event('onchange').AddToElement(control, control.OnChange);

    if (control.OnClick && !control.OnClick.IsEmpty())
        new Event('onclick').AddToElement(control, control.OnClick);

    if (control.OnMouseOut && !control.OnMouseOut.IsEmpty())
        new Event('onmouseout').AddToElement(control, control.OnMouseOut);

    if (control.OnMouseOver && !control.OnMouseOver.IsEmpty())
        new Event('onmouseover').AddToElement(control, control.OnMouseOver);

    if (control.OnMouseDown && !control.OnMouseDown.IsEmpty())
        new Event('onmousedown').AddToElement(control, control.OnMouseDown);

}
;Array.prototype.CurrentPosition=0;

Array.prototype.Contains=function(value)
{
	for(var i=0;i<this.length;i++)
		if(this[i]==value)
			return true;
	
	return false;
}

Array.prototype.GetNext=function()
{
	if(this.length==0)
		return;

	this.CurrentPosition++;
	if(this.CurrentPosition>=this.length)
		this.CurrentPosition=0;
	return this[this.CurrentPosition];
}

Array.prototype.GetPrevious=function()
{
	if(this.length==0)
		return;

	this.CurrentPosition--;
	if(this.CurrentPosition<0)
		this.CurrentPosition=this.length-1;
	return this[this.CurrentPosition];
}

Array.prototype.GetRandom=function()
{
	if(this.length==0)
		return;
	if(this.length==1)
		return this[0];

	var i;
	do 
	{
	  i = Math.floor(Math.random()*this.length);
	} while (i==this.CurrentPosition);

	this.CurrentPosition=i;
	return this[this.CurrentPosition];
}

Array.prototype.GetCurrent=function()
{
	if(this.length==0)
		return;
	return this[this.CurrentPosition];
}
;/*
JSONstring v 1.01
copyright 2006 Thomas Frank
(small sanitizer added to the toObject-method, May 2008)

This EULA grants you the following rights:

Installation and Use. You may install and use an unlimited number of copies of the SOFTWARE PRODUCT.

Reproduction and Distribution. You may reproduce and distribute an unlimited number of copies of the SOFTWARE PRODUCT either in whole or in part; each copy should include all copyright and trademark notices, and shall be accompanied by a copy of this EULA. Copies of the SOFTWARE PRODUCT may be distributed as a standalone product or included with your own product.

Commercial Use. You may sell for profit and freely distribute scripts and/or compiled scripts that were created with the SOFTWARE PRODUCT.

Based on Steve Yen's implementation:
http://trimpath.com/project/wiki/JsonLibrary

Sanitizer regExp:
Andrea Giammarchi 2007

*/

JSONstring={
	compactOutput:false, 		
	includeProtos:false, 	
	includeFunctions: false,
	detectCirculars:true,
	restoreCirculars:true,
	
	make:function(arg,restore) {
		this.restore=restore;
		this.mem=[];this.pathMem=[];
		return this.toJsonStringArray(arg).join('');
	},
	
	toObject:function(x){
		if(!this.cleaner){
			try{this.cleaner=new RegExp('^("(\\\\.|[^"\\\\\\n\\r])*?"|[,:{}\\[\\]0-9.\\-+Eaeflnr-u \\n\\r\\t])+?$')}
			catch(a){this.cleaner=/^(true|false|null|\[.*\]|\{.*\}|".*"|\d+|\d+\.\d+)$/}
		};
		if(!this.cleaner.test(x)){return {}};
		eval("this.myObj="+x);
		if(!this.restoreCirculars || !alert){return this.myObj};
		if(this.includeFunctions){
			var x=this.myObj;
			for(var i in x){if(typeof x[i]=="string" && !x[i].indexOf("JSONincludedFunc:")){
				x[i]=x[i].substring(17);
				eval("x[i]="+x[i])
			}}
		};
		this.restoreCode=[];
		this.make(this.myObj,true);
		var r=this.restoreCode.join(";")+";";
		eval('r=r.replace(/\\W([0-9]{1,})(\\W)/g,"[$1]$2").replace(/\\.\\;/g,";")');
		eval(r);
		return this.myObj
	},
	
	toJsonStringArray:function(arg, out) {
		if(!out){this.path=[]};
		out = out || [];
		var u; // undefined
		switch (typeof arg) {
		case 'object':
			this.lastObj=arg;
			if(this.detectCirculars){
				var m=this.mem; var n=this.pathMem;
				for(var i=0;i<m.length;i++){
					if(arg===m[i]){
						out.push('"JSONcircRef:'+n[i]+'"');return out
					}
				};
				m.push(arg); n.push(this.path.join("."));
			};
			if (arg) {
				if (arg.constructor == Array) {
					out.push('[');
					for (var i = 0; i < arg.length; ++i) {
						this.path.push(i);
						if (i > 0)
							out.push(',\n');
						this.toJsonStringArray(arg[i], out);
						this.path.pop();
					}
					out.push(']');
					return out;
				} else if (typeof arg.toString != 'undefined') {
					out.push('{');
					var first = true;
					for (var i in arg) {
						if(!this.includeProtos && arg[i]===arg.constructor.prototype[i]){continue};
						this.path.push(i);
						var curr = out.length; 
						if (!first)
							out.push(this.compactOutput?',':',\n');
						this.toJsonStringArray(i, out);
						out.push(':');                    
						this.toJsonStringArray(arg[i], out);
						if (out[out.length - 1] == u)
							out.splice(curr, out.length - curr);
						else
							first = false;
						this.path.pop();
					}
					out.push('}');
					return out;
				}
				return out;
			}
			out.push('null');
			return out;
		case 'unknown':
		case 'undefined':
		case 'function':
			if(!this.includeFunctions){out.push(u);return out};
			arg="JSONincludedFunc:"+arg;
			out.push('"');
			var a=['\n','\\n','\r','\\r','"','\\"'];
			arg+=""; for(var i=0;i<6;i+=2){arg=arg.split(a[i]).join(a[i+1])};
			out.push(arg);
			out.push('"');
			return out;
		case 'string':
			if(this.restore && arg.indexOf("JSONcircRef:")==0){
				this.restoreCode.push('this.myObj.'+this.path.join(".")+"="+arg.split("JSONcircRef:").join("this.myObj."));
			};
			out.push('"');
			var a=['\n','\\n','\r','\\r','"','\\"'];
			arg+=""; for(var i=0;i<6;i+=2){arg=arg.split(a[i]).join(a[i+1])};
			out.push(arg);
			out.push('"');
			return out;
		default:
			out.push(String(arg));
			return out;
		}
	}
};
///<Documentation>
///<Class name="Phone">
Phone=function(number,required) 
{
	this.Constructor(number,required);
}

///<Constructor>
///<summary>Phone constructor</summary>
///<param name="number" type="string" required="false">
///     The text representation of the phone number.
///</param>
Phone.prototype.Constructor=function(number,required) 
{
	
	this.Exception=null;
	this.AreaCode='';
	this.LocalCode='';
	this.UniqueCode='';
	this.Extension='';
	this.Value=number?number:null;
	this.FormattedNumber='';
	this.IsRequired=required?required:false;
	
	__validPhoneNonNumericsPattern=/[\(\)\.\-\x\X\ ]/g;
	
	if(number!=undefined)
		this.Parse(number);	
}
///</Constructor>

///<Methods>
///<Method name="IsValid">
///<summary>Determines whether the number represents a valid phone number</summary>
///<param name="number" type="string" required="false">
///     The text representation of the phone number.
///</param>
///<returns>Boolean</returns>
Phone.prototype.IsValid=function(number)
{
	if(number==null)
		if(this.Value==null)
			return this.Exception==null;
		else
			number=this.Value;
	
	this.Exception=null;
   if (number == "" || number == null) 
   {
   	if(this.IsRequired)
   	{
      	this.Exception = new Exception("Phone", "IsValid", "No number was entered.");
        	return false;
      }
      return true;
   }
   
	var phone = number.replace(__validPhoneNonNumericsPattern, '');     
   if (/[^0-9]/.test(phone)) 
        this.Exception = new Exception("Phone", "IsValid", "The phone number contains illegal characters.");
   else if (phone.length < 10) 
        this.Exception = new Exception("Phone", "IsValid", "The phone number is too short. Please be sure to include the area code.");

   return this.Exception==null;
}
///</Method>

///<Method name="Parse">
///<summary>
///	Parses the number into it's base parts. This also creates the Formatted text
///	version of the phone number.
///</summary>
///<param name="number" type="string" required="false">
///     The text representation of the phone number.
///</param>
///<returns>Boolean</returns>
Phone.prototype.Parse=function(number)
{
	if(this.IsValid(number))
	{
		var phone = number.replace(__validPhoneNonNumericsPattern, '');     
		this.AreaCode=phone.substr(0,3);
		this.LocalCode=phone.substr(3,3);
		this.UniqueCode=phone.substr(6,4);
		
		this.FormattedNumber = "("+this.AreaCode+") "+this.LocalCode+" - "+this.UniqueCode;
		
		if(phone.length>10)
		{
			this.Extension=phone.substr(10,phone.length-10);
			this.FormattedNumber+=' x '+this.Extension;
		}
		return true;
	}
	
	return false;
}
///</Method>
///</Methods>
///</Class>


///<Class name="Fax">
Fax = function(number)
{
	this.Constructor(number);
}

///<Inherits class="Phone">
Fax.prototype=new Phone();
///</Inherits>

///<Methods>
///<Method name="IsValid">
///<summary>Overrides the Phone validation. The fax can not have an Extension</summary>
///<param name="number" type="string" required="false">
///     The text representation of the phone number.
///</param>
///<returns>Boolean</returns>
Fax.prototype.IsValid=function(number)
{
	if(number==null)
		return this.Exception==null;
		
	this.Exception=null;

	var phone = new Phone(number);
	if (phone.IsValid())
	{
		if(phone.Extension=='')
			return true;
      this.Exception = new Exception("Fax", "IsValid", "Faxes can not have extensions.");
	}
	else
		this.Exception=phone.Exception;
			
	return false;
}
///</Method>
///</Methods>
///</Class>

///<UnitTests>
try
{
	if(__JSUnit_version>0)
	{
		
		var test=function()
		{
			var 	expected={"Exception":null,"AreaCode":"614","LocalCode":"459","UniqueCode":"9841","Extension":"323498","Value":"(614) 459-9841x323498","FormattedNumber":"(614) 459 - 9841 x 323498","IsRequired":false},
					actual=new Phone('(614) 459-9841x323498');
					
			return new JSUnitTestResult(actual,expected);
		}
		__jsUnit.AddTest('Phone','Constructor','Tests the constructor for creating a phone object','positive',test);

		test=function()
		{
			var 	expected=true,
					actual=new Phone('(614) 459-9841x234').IsValid();

			return new JSUnitTestResult(actual,expected);
		}
		__jsUnit.AddTest('Phone','IsValid','Tests valid phone number','positive',test);

		test=function()
		{
			var 	expected=false,
					actual=new Phone('(614) 4*&9-9841').IsValid();

			return new JSUnitTestResult(actual,expected);
		}
		__jsUnit.AddTest('Phone','IsValid','Tests phone with special characters','negative',test);

		test=function()
		{
			var 	expected=false,
					actual=new Phone('(614) 4zh9-9841').IsValid();

			return new JSUnitTestResult(actual,expected);
		}
		__jsUnit.AddTest('Phone','IsValid','Tests phone with alpha characters','negative',test);
		
		test=function()
		{
			var 	expected={"Exception":null,"AreaCode":"614","LocalCode":"459","UniqueCode":"9841","Extension":"","Value":"(614) 459-9841","FormattedNumber":"(614) 459 - 9841","IsRequired":false},
					actual=new Fax('(614) 459-9841');

			return new JSUnitTestResult(actual,expected);
		}
		__jsUnit.AddTest('Fax','Constructor','Tests the constructor for creating a Fax object','positive',test);

		test=function()
		{
			var 	expected=true,
					actual=new Fax('(614) 459-9841').IsValid();

			return new JSUnitTestResult(actual,expected);
		}
		__jsUnit.AddTest('Fax','IsValid','Tests valid fax number','positive',test);

		test=function()
		{
			var 	expected=false,
					actual=new Fax('(614) 459-9841x324').IsValid();

			return new JSUnitTestResult(actual,expected);
		}
		__jsUnit.AddTest('Fax','IsValid','Tests invalid fax number','negative',test);
	}
}
catch(err){}
///</UnitTests>
///</Documentation>
;///<Documentation>
///<Class name="Email">
Email = function(address) 
{
	this.Constructor(address);
}

///<Constructor>
///<summary>Email constructor</summary>
///<param name="address" type="string" required="false">
///     The text representation of the Internet Protocol address.
///</param>
Email.prototype.Constructor=function(address) 
{
	this.Exception=null;
	this.User=null;
	this.Domain=null;
	
	if(address!=null)
		this.IsValid(address);
}///</Constructor>

///<Methods>
///<Method name="IsValid">
///<summary>Determines whether the number represents a valid e-mail address</summary>
///<param name="address" type="string" required="false">
///     The text representation of the e-mail address.
///</param>
///<returns>Boolean</returns>
Email.prototype.IsValid=function(address)
{
	if(address==null)
		return this.Exception==null;
		
	this.Exception==null;

	var addressParts = address.split('@');
	
	if(addressParts.length==2)
	{
		this.User = addressParts[0],
		this.Domain = addressParts[1];

		var userParts = this.User.split('.');
		for(var i=0;i<userParts.length;i++)
		{
			if(userParts[i]=='')
			{
      		this.Exception = new Exception("Email", "IsValid", "User is invalid. It can not start with, end with, or contain multiple \".\"'s");
				return false;
			}
			
			if(/[<>()[\]\\,;:\s\"]/.test(userParts[i]))
			{
      		this.Exception = new Exception("Email", "IsValid", "User contains invalid characters.");
				return false;
			}
		}

		
		if(/(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,})$/.test(this.Domain))
			return true;
		
		var ip = new IPAddress(this.Domain);
		if(!ip.IsValid())
		{
      	this.Exception = new Exception("Email", "IsValid", 'Invalid e-mail domain: '+ip.Exception.Description);
			return false;
		}
		
		return true;
	}

	this.Exception = new Exception("Email", "IsValid", 'Invalid e-mail addess. No or too many "@"\'s present.');
	return false;
}
///</Method>


///</Methods>
///</Class>

///<Class name="IPAddress">
IPAddress=function(address)
{
	this.Constructor(address);
}

///<Constructor>
///<summary>IPAddress constructor</summary>
///<param name="address" type="string" required="false">
///     The text representation of the Internet Protocol address.
///</param>
IPAddress.prototype.Constructor=function(address) 
{
	this.Value=address;
	this.Octets=null;
	this.Reserved=false;
	this.Exception=null;
	
	if(address!=null)
		this.Parse(address);
}
///</Constructor>

///<Methods>
///<Method name="Parse">
///<summary>Parses the ip address into it's representative parts</summary>
///<param name="address" type="string" required="false">
///     The text representation of the ip address.
///</param>
///<returns>null</returns>
IPAddress.prototype.Parse=function(address)
{
	if(this.IsValid(address))
		this.Reserved=this.Octets[0]==10||(this.Octets[0]==172&&this.Octets[1]==16)||(this.Octets[0]==192&&this.Octets[1]==168)
}
///</Method>

///<Method name="IsValid">
///<summary>Determines whether the number represents a valid ip address</summary>
///<param name="address" type="string" required="false">
///     The text representation of the ip address.
///</param>
///<returns>Boolean</returns>
IPAddress.prototype.IsValid=function(address)
{
	if(address==null)
		return this.Exception==null;
		
	this.Exception==null;
	
	var octets=address.split('.');
	if (octets!=null && octets.length==4) 
	{
		for (var i=0;i<octets.length;i++) 
		{
			if (isNaN(octets[i]) || octets[i]>255) 
			{
				this.Exception = new Exception("IPAddress", "IsValid", "One of the octets is not in a valid range of numbers (must be 0 to 255).");
				return false;
   		}
		}
		
		this.Octets = octets;
		return true;
	}
	
	this.Exception = new Exception("IPAddress", "IsValid", "The address is not in a correct IP format.");
	return false;
}
///</Method>
///</Methods>
///</Class>

///<UnitTests>
try
{
	if(__JSUnit_version>0)
	{
		
		__jsUnit.AddTest('Email','IsValid','Tests for a syntactically valid e-mail address','positive',
			function()
			{
				var 	expected={"Exception":null,"User":"george","Domain":"irth.com"},
						actual=new Email('george@irth.com');
						
				return new JSUnitTestResult(actual,expected);
			});
			
		__jsUnit.AddTest('Email','IsValid','Tests for a syntactically invalid user in the e-mail address','negative',
			function()
			{
				var 	expected={"Exception":{"Object":"Email","Function":"IsValid","Description":"User contains invalid characters."},"User":"geo(rge","Domain":"irth.com"},
						actual=new Email('geo(rge@irth.com');

				return new JSUnitTestResult(actual,expected);
			});
			
		__jsUnit.AddTest('Email','IsValid','Tests for an e-mail address with an invalid ip','negative',
			function()
			{
				var 	expected={"Exception":{"Object":"Email","Function":"IsValid","Description":"Invalid e-mail domain: One of the octets is not in a valid range of numbers (must be 0 to 255)."},"User":"george","Domain":"22.18.266.86"},
						actual=new Email('george@22.18.266.86');

				return new JSUnitTestResult(actual,expected);
			});
			
		__jsUnit.AddTest('Email','IsValid','Tests for an e-mail address with a valid ip','positive',
			function()
			{
				var 	expected={"Exception":null,"User":"george","Domain":"22.18.56.86"},
						actual=new Email('george@22.18.56.86');

				return new JSUnitTestResult(actual,expected);
			});
	}
}
catch(err){}
///</UnitTests>
///</Documentation>
;var __textbox_version = 1;

///<Documentation>
///<Class name="TextBox">
function TextBox(id, caption, text, watermark, mask, required)
{
    this.Constructor(id, caption, text, watermark, mask, required);
}

///<Constructor>
///<summary>TextBox constructor</summary>
///<param name="id" type="string" required="false">
///     The id to be assigned to the HTML control generated from the Render()
///     function. If this is not provided, than a GUID is automatically assigned.
///</param>
///<param name="caption" type="string" required="false">
///     The name to be displayed as a caption for the textbox
///</param>
///<param name="text" type="string" required="false">
///     The value to be entered into the textbox
///</param>
///<param name="watermark" type="string" required="false">
///     Watermark text to be placed in the text field whenever it is blank
///</param>
TextBox.prototype.Constructor = function(id, caption, text, watermark, mask, required)
{
    if (!__base_version || __base_version < 1)
        new Exception("TextBox", "Constructor", "The TextBox object requires the inclusion of the base.js file.").Throw();
    if (!__string_version || __string_version < 1)
        new Exception("TextBox", "Constructor", "The TextBox object requires the inclusion of the string.js file.").Throw();

    var tb = $getControl(id + '_obj');
    if (tb)
        tb = eval(tb.value);

    this.Control = $getControl(id + '_input');
    this.ID = id ? id : __getGUID();
    this.Caption = caption ? caption : tb ? tb.Caption : '';
    this.Disabled = tb ? tb.Disabled : false;
    this.Watermark = watermark ? watermark : tb ? tb.Watermark : '';
    this.Mask = mask ? mask : tb ? tb.Mask : '';
    this.IsNumeric = tb ? tb.IsNumeric : false;
    this.IsRequired = required ? required : tb ? tb.IsRequired : false;
    this.Type = 'TextBox';

    this.Text = text ? text : tb ? this.Unmask($getControl(id + '_input').value) : '';

}
///</Constructor>

///<Methods>
///<Method name="AddEvents">
///<summary>
///     Adds the events to a text box. This is for adding events to the control
///     after it has been rendered on an HTML page. Some browsers do not adequately
///     support adding the events when a control is appended as a child. In
///     those cases, call this methods after appending the control.
///</summary>
///<returns>HTML object</returns>
TextBox.prototype.AddEvents = function()
{
    var tb = $getControl(this.ID + '_input');
    if (!tb) return;

    if (tb.OnBlur && !tb.OnBlur.IsEmpty())
        new Event('onblur').AddToElement(tb, tb.OnBlur);

    if (tb.OnFocus && !tb.OnFocus.IsEmpty())
        new Event('onfocus').AddToElement(tb, tb.OnFocus);

    if (tb.OnKeyUp && !tb.OnKeyUp.IsEmpty())
        new Event('onkeyup').AddToElement(tb, tb.OnKeyUp);

    if (tb.OnKeyDown && !tb.OnKeyDown.IsEmpty())
        new Event('onkeydown').AddToElement(tb, tb.OnKeyDown);
}
///</Method>

///<Method name="Render">
///<summary>Renders the textbox</summary>
///<returns>HTML object</returns>
TextBox.prototype.Render = function () {
    var textbox = document.createElement("table"),
			row = textbox.insertRow(),
			caption = row.insertCell(),
			text = row.insertCell(),
			inp = document.createElement("INPUT"),
			obj = document.createElement("INPUT");

    textbox.id = this.ID;

    obj.id = this.ID + '_obj';
    obj.type = 'hidden';
    obj.value = '(' + JSONstring.make(this) + ')';

    inp.id = this.ID + '_input';
    inp.type = 'text';
    inp.className = "textbox_text";
    inp.value = this.Text;

    if (this.IsValid)
        inp.OnBlur = 'new ' + this.Type + '(\'' + this.ID + '\').IsValid();';

    if (!this.Watermark.IsEmpty()) {
        if (this.Text.IsEmpty()) {
            inp.value = this.Watermark;
            inp.className = "textbox_watermark";
        }
        inp.OnFocus = 'textbox_RemoveWatermark(\'' + this.ID + '\');';
        inp.OnBlur += 'textbox_SetWatermark(\'' + this.ID + '\');';
    }

    if (!this.Mask.IsEmpty() && this.Mask.indexOf('#') > -1) {
        if (this.Text.IsEmpty() && this.Watermark.IsEmpty())
            inp.value = this.Mask.replace(/#/g, ' ');

        inp.OnKeyUp = 'textbox_Mask(\'' + this.ID + '\',event);';
        inp.OnKeyDown = 'return textbox_IsMasked(\'' + this.ID + '\',event);';

        if (inp.value != this.Watermark)
            inp.value = this.ApplyMask();
    }

    //XC: Need to look at this
    if (this.IsNumeric)
        inp.OnKeyDown = 'return textbox_KeyIsNumeric(event);';

    caption.className = 'textbox_caption';
    caption.innerHTML = this.Caption;

    text.appendChild(inp);
    text.appendChild(obj);
    textbox.disabled = this.Disabled;

    return textbox;
}
///</Method>

///<Method name="GetCursorPosition">
///<summary>Gets the current position of the cursor within the textbox</summary>
///<returns>Integer</returns>
///<param name="control" type="string/object" required="false">
///     Watermark text to be placed in the text field whenever it is blank
///</param>
TextBox.prototype.GetCursorPosition = function()
{
    if (!this.Control)
        return 0;

    var currentRange = document.selection.createRange(),
			workRange = currentRange.duplicate();
    this.Control.select();
    var entireRange = document.selection.createRange(),
			cursorPosition = 0;
    while (workRange.compareEndPoints('StartToStart', entireRange) > 0)
    {
        workRange.moveStart("character", -1);
        cursorPosition++;
    }
    currentRange.select();
    return cursorPosition;
}
///</Method>

///<Method name="GetCursorPosition">
///<summary>Gets the current position of the cursor within the textbox</summary>
///<returns>Integer</returns>
TextBox.prototype.SetCursorPosition = function(position)
{
    if (!this.Control)
        return;

    if (this.Control.createTextRange)
    {
        var range = this.Control.createTextRange();
        range.move('character', position);
        range.select();
    }
    else
    {
        if (this.Control.selectionStart)
        {
            this.Control.focus();
            this.Control.setSelectionRange(position, position);
        }
        else
            this.Control.focus();
    }
}
///</Method>

///<Method name="Unmask">
///<summary>Returns the displayed text of the currently selected option</summary>
///<returns>String</returns>
TextBox.prototype.Unmask = function(text)
{
    if (!text)
    {
        if (this.Text)
            text = this.Text
        else
            return '';
    }

    if (this.Watermark == text)
        return '';

    if (!this.Mask || this.Mask.IsEmpty())
        return text;

    var last = '',
			unmasked = text,
			maskChars = this.Mask.replace(/#/g, '');
    for (var i = 0; i < maskChars.length; i++)
    {
        if (last == unmasked)
            return text;
        last = unmasked;

        var maskChar = maskChars.substr(i, 1);

        if (/[\(\)\\\*\+\?\^\$\|]/.test(maskChar))
            maskChar = '\\' + maskChar;
        var re = new RegExp(maskChar);
        unmasked = unmasked.replace(re, '');
    }

    return unmasked.Trim().replace(/ /g, '');
}
///</Method>

///<Method name="ApplyMask">
///<summary>Returns the displayed text of the currently selected option</summary>
///<returns>String</returns>
TextBox.prototype.ApplyMask = function()
{
    if (!this.Mask || this.Mask.IsEmpty() || this.Mask.indexOf('#') < 0)
        return;

    var textPosition = 0
    masked = '';

    for (var i = 0; i < this.Mask.length; i++)
    {
        var maskChar = this.Mask.substr(i, 1),
				textChar = this.Text.substr(textPosition, 1);

        if (maskChar == '#')
        {
            if (this.Text.length > textPosition)
                masked += textChar;
            else
                masked += ' ';

            textPosition++;
        }
        else
            masked += maskChar;
    }

    if (this.Text.length > textPosition)
        masked += this.Text.substr(textPosition);

    return masked.Trim();
}
///</Method>

///<Method name="GetText">
///<summary>Returns the displayed text of the currently selected option</summary>
///<returns>String</returns>
TextBox.prototype.IsValid = function()
{
    if (this.Control)
        new Exception().Detach(this.Control);

    if (this.IsRequired)
        if (this.Text.IsEmpty())
    {
        if (this.Control)
            new Exception(this.Type, 'IsValid', 'This field is required.').Attach(this.Control);
        return false;
    }

    return true;
}
///</Method>

///<EventMethod name="textbox_IsMasked">
textbox_IsMasked = function (id, event) {

    var code = GetKeyCode(event);
    //if it's a backspace or delete, check mask before removing the character
    if (code == 8 || code == 46) {
        var tb = new TextBox(id);
        if (!tb.Control || tb.Mask.IsEmpty()) return false;

        var maskChars = new Array(),
				cursor = code == 8 ? tb.GetCursorPosition() - 1 : tb.GetCursorPosition();
        for (var i = 0; i < tb.Mask.length; i++)
            if (tb.Mask.substr(i, 1) != '#')
                maskChars.push(i);

        if (maskChars.Contains(cursor))
            return true;
    }
    return false;
}
///</EventMethod>

///<EventMethod name="textbox_checkNumeric">
textbox_KeyIsNumeric = function (event) 
{
    var code = GetKeyCode(event);
    if (code < 58 || (code > 95 && code < 106) || (code > 34 && code < 47) || code == 8)
        return true;
    return false;
}
///</EventMethod>

///<EventMethod name="textbox_RemoveWatermark">
textbox_RemoveWatermark = function(id)
{
    var tb = new TextBox(id);
    if (!tb.Control) return;

    if (tb.Control.value == tb.Watermark)
    {
        tb.Control.className = "textbox_text";
        tb.Control.value = "";

        if (!tb.Mask.IsEmpty())
        {
            tb.Control.value = tb.ApplyMask();
            tb.SetCursorPosition(tb.Mask.indexOf('#'));
        }
    }
}
///</EventMethod>

///<EventMethod name="textbox_SetWatermark">
textbox_SetWatermark = function(id)
{
    var tb = new TextBox(id);
    if (!tb.Control) return;

    if (tb.Control.value == tb.Watermark || tb.Control.value.length == 0 || tb.Control.value == tb.Mask.replace(/#/g, ' '))
    {
        tb.Control.className = "textbox_watermark";
        tb.Control.value = tb.Watermark;
    }
    else
        tb.Control.className = "textbox_text";
}
///</EventMethod>

///<EventMethod name="textbox_Mask">
textbox_Mask = function(id, e)
{
    var tb = new TextBox(id);
    if (!tb.Control) return;

    if (e)
    {
        var key = e.keyCode;
        //Skip all keys that don't produce output on the screen (function keys, escape, etc.)
        if ((key > 2 && key < 8) || (key > 12 && key < 28) || (key > 32 && key < 38) || key == 40 || key == 93 || (key > 111 && key < 146))
            return true;
    }

    if (!tb.Mask || tb.Mask.IsEmpty() || tb.Mask.indexOf('#') < 0)
        return;

    var cursor = tb.GetCursorPosition(),
			textPosition = 0,
			masked = tb.Text != tb.Control.value;
    tb.Control.value = tb.ApplyMask();

    if (masked)
        cursor = tb.Mask.indexOf('#', cursor);
    else
        cursor = tb.Mask.indexAfter('#', tb.Text.length);

    if (cursor > -1)
        tb.SetCursorPosition(cursor);
    else
        tb.SetCursorPosition(tb.Control.value.length);

}
///</EventMethod>
///</Methods>
///</Class>

///<Class name="PhoneBox">
PhoneBox = function(id, caption, text, watermark, mask, required)
{
    this.Constructor(id, caption, text, watermark, mask, required);
    this.Mask = '(###) ###-####x';
    this.IsNumeric = true;
    this.Type = 'PhoneBox';
}

///<Inherits class="TextBox">
PhoneBox.prototype = new TextBox();
///</Inherits>

///<Methods>
///<Method name="IsValid">
///<summary>Determines whether the number represents a valid phone number</summary>
///<param name="control" type="string" required="false">
///     The PhoneBox control to check.
///</param>
///<returns>Boolean</returns>
PhoneBox.prototype.IsValid = function()
{
    if (this.Control)
        new Exception().Detach(this.Control);

    var phone = null,
 			isValid = false;

    if (this.Text.IsEmpty())
        isValid = !this.IsRequired;
    else
    {
        phone = new Phone(this.Text);
        isValid = phone.IsValid();
    }

    if (!isValid)
    {
        if (this.Control)
            if (phone)
            phone.Exception.Attach(this.Control);
        else
            new Exception(this.Type, 'IsValid', 'This field is required').Attach(this.Control);
        return false;
    }

    return true;
}
///</Method>
///</Methods>
///</Class>

///<Class name="FaxBox">
FaxBox = function(id, caption, text, watermark, mask, required)
{
    this.Constructor(id, caption, text, watermark, mask, required);
    this.Mask = '(###) ###-####';
    this.IsNumeric = true;
    this.Type = 'FaxBox';
}

///<Inherits class="TextBox">
FaxBox.prototype = new TextBox();
///</Inherits>

///<Methods>
///<Method name="IsValid">
///<summary>Determines whether the number represents a valid phone number</summary>
///<param name="control" type="string" required="false">
///     The PhoneBox control to check.
///</param>
///<returns>Boolean</returns>
FaxBox.prototype.IsValid = function()
{
    if (this.Control)
        new Exception().Detach(this.Control);

    var fax = null,
 			isValid = false;

    if (this.Text.IsEmpty())
        isValid = !this.IsRequired;
    else
    {
        fax = new Fax(this.Text);
        isValid = fax.IsValid();
    }

    if (!isValid)
    {
        if (this.Control)
            if (fax)
            fax.Exception.Attach(this.Control);
        else
            new Exception(this.Type, 'IsValid', 'This field is required').Attach(this.Control);
        return false;
    }

    return true;
}
///</Method>
///</Methods>
///</Class>

///<Class name="EmailBox">
EmailBox = function(id, caption, text, watermark, mask, required)
{
    this.Constructor(id, caption, text, watermark, mask, required);
    this.Type = 'EmailBox';
}

///<Inherits class="TextBox">
EmailBox.prototype = new TextBox();
///</Inherits>

///<Methods>
///<Method name="IsValid">
///<summary>Determines whether the number represents a valid phone number</summary>
///<param name="control" type="string" required="false">
///     The PhoneBox control to check.
///</param>
///<returns>Boolean</returns>
EmailBox.prototype.IsValid = function()
{
    if (this.Control)
        new Exception().Detach(this.Control);

    var email = null;

    if (this.Text.IsEmpty())
        isValid = !this.IsRequired;
    else
    {
        email = new Email(this.Text);
        isValid = email.IsValid();
    }

    if (!isValid)
    {
        if (this.Control)
            if (email)
            email.Exception.Attach(this.Control);
        else
            new Exception(this.Type, 'IsValid', 'This field is required').Attach(this.Control);
        return false;
    }

    return true;
}
///</Method>
///</Methods>
///</Class>

///<UnitTests>
try
{
    if (__JSUnit_version > 0)
    {

        __jsUnit.AddTest('TextBox', 'Render', 'Tests the Render function of the textbox object.', 'positive',
			function()
			{
			    var tb = new TextBox(null, 'Test', 'Freakin junk', 'Enter a value'),
						actual = tb.Render().outerHTML.replace(/[\r\n]/g, ''),
						expected = '<TABLE id=mytest><TBODY><TR><TD class=textbox_caption>Test</TD><TD><INPUT id=mytest_input onblur="var validate=function()&#13;&#10;{&#9;&#13;&#10;&#9;if(this.IsRequired)&#13;&#10;&#9;&#9;if(this.Text.IsEmpty())&#13;&#10;&#9;&#9;{&#13;&#10;&#9;&#9;&#9;if(this.Control)&#13;&#10;&#9;&#9;&#9;&#9;new Exception(\'TextBox\',\'IsValid\',\'This field is required.\').Attach(this.ID+\'_input\');&#13;&#10;&#9;&#9;&#9;return false;&#13;&#10;&#9;&#9;}&#13;&#10;&#13;&#10;&#9;if(this.Control)&#13;&#10;&#9;&#9;new Exception().Detach(this.ID+\'_input\');&#13;&#10;&#9;return true;&#13;&#10;};validate(this,false);textbox_SetWatermark(\'mytest\');" onfocus="textbox_RemoveWatermark(\'mytest\');" value="Freakin junk"><INPUT id=mytest_obj type=hidden value=\'({"Control":null,&#13;&#10;"ID":"mytest",&#13;&#10;"Caption":"Test",&#13;&#10;"Disabled":false,&#13;&#10;"Watermark":"Enter a value",&#13;&#10;"Mask":"",&#13;&#10;"IsNumeric":false,&#13;&#10;"IsRequired":false,&#13;&#10;"Text":"Freakin junk"})\'></TD></TR></TBODY></TABLE>';

			    return new JSUnitTestResult(actual, expected, true, tb.ID);
			});
        __jsUnit.AddTest('PhoneBox', 'Render', 'Tests the Render function of the PhoneBox object.', 'positive',
			function()
			{
			    var tb = new PhoneBox(null, 'Test', '', 'Enter a value'),
						actual = tb.Render().outerHTML.replace(/[\r\n]/g, ''),
						expected = '<TABLE><TBODY><TR><TD class=textbox_caption>Test</TD><TD><INPUT class=textbox_text id=mytest_input onblur="textbox_SetWatermark(\'mytest_input\',\'Enter a value\');" onfocus="textbox_RemoveWatermark(\'mytest_input\',\'Enter a value\');" alt="Freakin junk" value="Freakin junk"></TD></TR></TBODY></TABLE>';

			    return new JSUnitTestResult(actual, expected, true, tb.ID);
			});
    }
}
catch (err) { }
///</UnitTests>
///</Documentation>
;var __dropdownbox_version=1;

///<Documentation>
///<Class name="DropDownBox">
function DropDownBox(id,caption,options,required)
{
	this.Constructor(id,caption,options,required);
}

///<Constructor>
///<summary>DropDownBox constructor</summary>
///<param name="id" type="string" required="false">
///     The id to be assigned to the HTML control generated from the Render()
///     function. If this is not provided, than a GUID is automatically assigned.
///</param>
///<param name="caption" type="string" required="false">
///     The name to be displayed as a caption for the DropDownBox
///</param>
///<param name="text" type="string" required="false">
///     The value to be entered into the DropDownBox
///</param>
DropDownBox.prototype.Constructor = function(id, caption, options, required)
{
    if (!__base_version || __base_version < 1)
        new Exception("DropDownBox", "Constructor", "The DropDownBox object requires the inclusion of the base.js file.").Throw();
    if (!__string_version || __string_version < 1)
        new Exception("DropDownBox", "Constructor", "The DropDownBox object requires the inclusion of the string.js file.").Throw();

    var ddb = $getControl(id + '_obj');
    if (ddb)
        ddb = eval(ddb.value);

    this.ID = id ? id : __getGUID();
    this.Control = this.ID + '_box';
    this.Caption = caption ? caption : ddb ? ddb.Caption : '';
    this.Disabled = ddb ? ddb.Disabled : false;
    this.IsRequired = required ? required : ddb ? ddb.IsRequired : false;
    this.Type = 'DropDownBox';
    this.Sort = ddb ? ddb.Sort : true;
    this.Options = options ? options : ddb ? ddb.Options : new Array();
    this.OnChange = ddb ? ddb.OnChange : null;
}
///</Constructor>

///<Methods>
///<Methods>
///<Method name="Clear">
///<summary>Removes all the options</summary>
///<returns>String</returns>
DropDownBox.prototype.Clear = function()
{
    var dd = $getControl(this.Control);
    if (!dd) return;

    $(dd).empty();
}
///</Method>

///<Method name="getSelectedValue">
///<summary>Returns the value of the currently selected option</summary>
///<returns>String</returns>
DropDownBox.prototype.GetSelectedValue = function()
{
    var dd = $getControl(this.Control);
    if (dd && dd.options && dd.options.length > 0)
        return dd.options[dd.selectedIndex].value;
    return '';
}
///</Method>

///<Method name="Render">
///<summary>Renders the textbox</summary>
///<returns>HTML object</returns>
DropDownBox.prototype.Render = function()
{
    var dd = document.createElement("table"),
		row = dd.insertRow(),
		caption = row.insertCell(),
		drop = row.insertCell(),
		box = document.createElement("select"),
		obj = document.createElement("INPUT");

    dd.id = this.ID;

    obj.id = this.ID + '_obj';
    obj.type = "hidden";
    obj.value = '(' + JSONstring.make(this) + ')';

    box.id = this.ID + '_box';
    box.className = "dropdownbox_box";

    if (this.IsValid)
        box.OnBlur = 'new ' + this.Type + '(\'' + this.ID + '\').IsValid();';
    if (this.OnChange)
        box.OnChange = this.OnChange;

    if (this.Sort)
        this.Options.sort(dropdownbox_sortText);

    var lastGroup = null
    optGroup = null;
    for (var i = 0; i < this.Options.length; i++)
    {
        var group = this.Options[i].group;
        if (group && group != lastGroup)
        {
            if (lastGroup && optGroup)
                box.appendChild(optGroup);

            optGroup = document.createElement("OPTGROUP");
            optGroup.label = group;
            lastGroup = group;
        }

        var opt = document.createElement("OPTION");
        opt.value = this.Options[i].value;
        opt.innerHTML = this.Options[i].text;
        opt.title = this.Options[i].text;
        opt.selected = this.Options[i].selected;

        if (optGroup)
            optGroup.appendChild(opt);
        else
            box.appendChild(opt);
    }

    caption.className = 'dropdownbox_caption';
    caption.innerHTML = this.Caption;

    drop.appendChild(box);
    drop.appendChild(obj);
    dd.disabled = this.Disabled;

    return dd;
} 
///</Method>

///<Method name="AddOption">
///<summary>Adds an option to the listbox</summary>
///<param name="value" type="string" required="false">
///     Used to fill in the value of the listbox. This will be submitted on
///     a form post if the option is selected.
///</param>
///<param name="text" type="string" required="false">
///     This value will be shown to the user in the dropdown box but not 
///     submitted on a form post.
///</param>
///<param name="selected" type="boolean" required="false">
///     This value determines if this option will be the default selected item.
///     If more that one has a value of "true" than the last value will be selected.
///</param>
///<param name="group" type="string" required="false">
///     This value allows the use of option groups. If assigned a value, the text will
///     be displayed under a given group.
///</param>
///<returns>Null</returns>
DropDownBox.prototype.AddOption = function(value, text, selected, group)
{
    this.Options.push({ "value": value, "text": text, "selected": (selected ? selected : false), "group": group });

    var dd = $getControl(this.Control)
    if (dd)
    {
        var opt = document.createElement("OPTION");
        opt.value = value;
        opt.innerHTML = text;
        opt.title = text;

        if (selected) opt.selected = true;
        dd.appendChild(opt);
    }
} 
///</Method>

///<EventMethod name="textbox_IsMasked">
dropdownbox_sortText=function(a,b)
{
	if(a.group!=b.group) return 0;
	if(!a.text && !b.text) return 0;
	if(!a.text) return -1;
	if(!b.text) return 1;
	
	var aText=a.text.toLowerCase(),
		bText=b.text.toLowerCase();
	if(aText<bText) return -1;
	if(aText>bText) return 1;
	return 0;
}
///</EventMethod>

///<EventMethod name="textbox_IsMasked">
dropdownbox_sortGroup=function(a,b)
{
	if(!a.group && !b.group) return 0;
	if(!a.group) return -1;
	if(!b.group) return 1;
	
	var aGroup=a.group.toLowerCase(),
		bGroup=b.group.toLowerCase();
	if(aGroup<bGroup) return -1;
	if(aGroup>bGroup) return 1;
	return 0;
}
///</EventMethod>
///</Methods>
///</Class>


///<UnitTests>
try
{
	if(__JSUnit_version>0)
	{
		
		__jsUnit.AddTest('DropDownBox','Render','Tests the Render function of the dropdown object.','positive',
			function()
			{
				var	dd= new DropDownBox();
				dd.Caption='Test Drop Down';
				dd.AddOption(1,'Yes',true);
				dd.AddOption(0,'No');
				
				return new JSUnitTestResult(dd.Render().outerHTML.replace(/[\r\n]/g,''),'',true,dd.ID);
			});
		__jsUnit.AddTest('DropDownBox','Render','Tests the Render function of the dropdown constructor.','positive',
			function()
			{
				var	dd= new DropDownBox('test','Test Drop Down',[{"value":"Yes","text":"Yes","selected":false,"group":null},{"value":"No","text":"No","selected":true,"group":null}]);
				
				return new JSUnitTestResult(dd.Render().outerHTML.replace(/[\r\n]/g,''),'',true,dd.ID);
			});
	}
}
catch(err){}
///</UnitTests>
///</Documentation>

;LocationsControl = function(locations, id)
{
    this.Constructor(locations, id);
}

LocationsControl.prototype.Constructor = function(locations, id)
{
    var obj = $getControl(id + '_obj');
    if (obj)
        obj = eval(obj.value);
        
    this.ID = id ? id : __getGUID();
    this.Locations = locations ? locations : obj ? obj.Locations:null;
    this.StateControl = new DropDownBox(this.ID + '_state', 'State');
    this.CountyControl = new DropDownBox(this.ID + '_county', 'County'); 
}

LocationsControl.prototype.Render = function() {
    if (!this.Locations)
        return null;

    var search = document.createElement('table');
    var row = search.insertRow();
    var button = document.createElement('input');
    var obj = document.createElement('input');
    var helpLink = document.createElement('a');
    var memberContactLink = document.createElement('a');


    search.id = this.ID;
    obj.id = this.ID + '_obj';
    obj.type = "hidden";
    obj.value = '(' + JSONstring.make(this) + ')';

    for (var i = 0; i < this.Locations.length; i++)
        this.StateControl.AddOption(this.Locations[i].abbr, this.Locations[i].name);
    this.StateControl.OnChange = '__locationsControl_setCounties("' + this.ID + '");';

    for (var i = 0; i < this.Locations[0].counties.length; i++)
        this.CountyControl.AddOption(this.Locations[0].counties[i].env, this.Locations[0].counties[i].name);
    this.CountyControl.OnChange = '__locationsControl_changeCounty("' + this.ID + '");';

    button.id = this.ID + '_button';
    button.type = 'button';
    button.value = 'Get Emergency Contacts';
    button.OnClick = "__setMap();";

    helpLink.href = GetBaseUrl() + "/Documents/EmergencyContactHelp.pdf";
    helpLink.appendChild(document.createTextNode("Help"));
    helpLink.target = "_blank";
    helpLink.className = "link";

    memberContactLink.href = GetBaseUrl() + "/Centers/USAN/MemberContacts.aspx";
    memberContactLink.appendChild(document.createTextNode("Click here if you have a ticket number"));
    memberContactLink.className = "link";

    row.insertCell(-1).appendChild(this.StateControl.Render());
    row.insertCell(-1).appendChild(this.CountyControl.Render());
    row.insertCell(-1).appendChild(button);
    row.insertCell(-1).appendChild(helpLink);
    row.insertCell(-1).appendChild(memberContactLink);
    search.insertRow(0).insertCell().appendChild(obj);

    return search;
}

__setMap = function () {
    PageMethods.GetServiceAreaContacts(GetMap().NewDigSiteGeometryAsJson(), __getServiceAreaContacts_onComplete);
}

__getServiceAreaContacts_onComplete = function(result, response, method)
{
    if (result.substring(2, 0) != "({")
    {
        //  If doesn't start with "({" then it's an error message
        alert(result);
        return;
    }

    var serviceAreas = eval(result).ServiceAreas,
        container = document.createElement('div'),
        contactTable = document.createElement('table'),
        header = contactTable.insertRow(-1);

    header.className = 'datagridHeader';
    container.id = 'emergencyContactTable';
    contactTable.className = 'datagrid';
    contactTable.style.width = '95%';
    contactTable.id = container.id + '_grid';

    header.insertCell(-1).innerHTML = 'Member Utility';
    header.insertCell(-1).innerHTML = 'Main Contact#';
    header.insertCell(-1).innerHTML = 'Vacuum Contact#';
    header.insertCell(-1).innerHTML = 'Emergency Contact#';
    header.insertCell(-1).innerHTML = 'After Hours Contact#';

    for (var i = 0; i < serviceAreas.length; i++)
    {
        var row = contactTable.insertRow(-1);
        row.className = 'datagridCell';
        row.insertCell(-1).innerHTML = serviceAreas[i].Name;
        row.insertCell(-1).innerHTML = serviceAreas[i].Main;
        row.insertCell(-1).innerHTML = serviceAreas[i].Vacuum;
        row.insertCell(-1).innerHTML = serviceAreas[i].Emergency;
        row.insertCell(-1).innerHTML = serviceAreas[i].AfterHours;
    }

    $getControl('MapFrame').style.visibility = 'hidden';
    $getControl('MapFrameInstructions').style.visibility = 'hidden';
    var search = $getControl('EmergencyContactSearch'),
		button = document.createElement('input'),
		printVersion = document.createElement('a'),
		spacer = document.createElement('div');

    spacer.innerHTML = '&nbsp;';
    button.type = "button";
    button.value = 'Another Search?';
    button.OnClick = "$getControl('EmergencyContactSearch').removeChild($getControl('emergencyContactTable'));$getControl('EmergencyContactLocations').style.display='block';$getControl('MapFrame').style.visibility = 'visible';$getControl('MapFrameInstructions').style.visibility = 'visible';";
    button.id = container.id + '_button';

    printVersion.innerHTML = 'Printer friendly version';
    printVersion.className = 'hyperlink';
    printVersion.OnClick = "__emergencyContacts_print();";
    printVersion.id = container.id + '_print';


    container.appendChild(contactTable);
    container.appendChild(button);
    container.appendChild(spacer);
    container.appendChild(printVersion);
    search.appendChild(container);
    new Event().RefreshAll(button.id);
    new Event().RefreshAll(printVersion.id);
    $getControl('EmergencyContactLocations').style.display = 'none';
}

__getStates_onComplete = function(result, response, method) {
    if (!result) return;

    var locations = new LocationsControl(eval(result).states, 'EmergencyContactLocations');
    $getControl('EmergencyContactSearch').appendChild(locations.Render());
    var e = new Event();
    e.RefreshAll(locations.StateControl.Control);
    e.RefreshAll(locations.CountyControl.Control);
    e.RefreshAll(locations.ID + '_button');

    var mapFrame = $getControl('MapFrame');
    mapFrame.style.visibility = 'visible';
    mapFrame.style.width = '800px';
    mapFrame.style.height = '500px';

    $getControl('MapFrameInstructions').style.visibility = 'visible';

    //Should only need to do this here to resize the map correctly.  This gets called when you choose the 
    //  "I Accept" from the disclaimer portion. And since we are changing the Map size we should resize it.
    ResizeMap();

    //  The map may still be loaded the map def, so use a timer to periodically check to see
    //  when it's finished.  Otherwise, we may try to position before the map is loaded which will
    //  cause it to not be positioned at all.
    setTimeout("CheckMapEvents()", 500);
}

function CheckMapEvents()
{
    var map = GetMap();
     
    if (map.IsMapLoaded())
    {
        var loc = new LocationsControl(null, 'EmergencyContactLocations');
        map.ZoomToEnvelopeFromJson(loc.CountyControl.GetSelectedValue());
    } else
    {
        //  Still not loaded, need to try again
        setTimeout("CheckMapEvents()", 500);
    }
}

__locationsControl_setCounties = function(locationsID)
{
    var loc = new LocationsControl(null, locationsID),
        currentState = loc.StateControl.GetSelectedValue();

    loc.CountyControl.Clear();

    for (var i = 0; i < loc.Locations.length; i++)
        if (loc.Locations[i].abbr == currentState)
        break;

    loc.Locations[i].counties.sort(function(a, b) {
        var aText = a.name.toLowerCase(),
		bText = b.name.toLowerCase();
        if (aText < bText) return -1;
        if (aText > bText) return 1;
        return 0;
    });
    for (var j = 0; j < loc.Locations[i].counties.length; j++)
        loc.CountyControl.AddOption(loc.Locations[i].counties[j].env, loc.Locations[i].counties[j].name);

    GetMap().ZoomToEnvelopeFromJson(loc.CountyControl.GetSelectedValue());
}

__locationsControl_changeCounty = function(locationsID)
{
    var loc = new LocationsControl(null, locationsID);
    GetMap().ZoomToEnvelopeFromJson(loc.CountyControl.GetSelectedValue());
}

GetMap = function()
{
    return document.getElementById('MapFrame').contentWindow;
}

__emergencyContacts_print = function()
{
    var win = window.open('', 'printwin', 'directories=0,location=0,menubar=0,scrollbars=0,titlebar=0,toolbar=0');
    win.document.write('<head><link id="stylesheet" href="' + GetBaseUrl() + '/Css/stylesheet.css" rel="stylesheet" type="text/css"/></head><body>' + $getControl('emergencyContactTable_grid').outerHTML + '</body>');
    win.document.close();
    win.document.location.reload(true);
    win.print();
    if (!$.browser.msie)
        win.close();
}


;PasswordRequest=function(){}

PasswordRequest.prototype.Render = function(container)
{
    var obj = 'passwordRequest',
		firstName = new TextBox(obj + 'Firstname', 'First Name', null, null, null, true),
		lastName = new TextBox(obj + 'Lastname', 'Last Name', null, null, null, true),
		phone = new PhoneBox(obj + 'Phone', 'Phone', null, null, null, true),
		company = new TextBox(obj + 'Company', 'Company Name', null, null, null, true),
		companyFax = new FaxBox(obj + 'Fax', 'Company Fax (optional)'),
		email = new EmailBox(obj + 'Email', 'E-mail', null, null, null, true),
		sendButton = document.createElement('input'),
		cancelButton = document.createElement('input'),
		modalBack = document.createElement('div'),
		request = document.createElement('table');

    request.id = 'passwordRequest';
    request.className = 'passwordRequest';
    request.style.width = '400px';

    modalBack.id = request.id + '_modalBack';
    modalBack.className = 'passwordRequest_background';

    sendButton.type = 'button';
    sendButton.value = 'Send';
    sendButton.OnClick = '__passwordRequest_Send();';

    cancelButton.type = 'button';
    cancelButton.value = 'Cancel';
    cancelButton.OnClick = '$getControl(\'' + modalBack.id + '\').style.visibility=\'hidden\';$getControl(\'' + request.id + '\').style.visibility=\'hidden\';'
    sendButton.className = cancelButton.className = 'passwordRequest_button';

    var title = request.insertRow().insertCell();
    title.className = 'passwordRequest_title';
    title.innerHTML = 'Request a New User Name and Password';
    request.insertRow().insertCell().appendChild(firstName.Render());
    request.insertRow().insertCell().appendChild(lastName.Render());
    request.insertRow().insertCell().appendChild(phone.Render());
    request.insertRow().insertCell().appendChild(company.Render());
    request.insertRow().insertCell().appendChild(companyFax.Render());
    request.insertRow().insertCell().appendChild(email.Render());

    var buttons = document.createElement("table")
    row = buttons.insertRow();
    row.insertCell().appendChild(sendButton);
    row.insertCell().appendChild(cancelButton);
    var buttonCell = request.insertRow().insertCell();
    buttonCell.colSpan = 2;
    buttonCell.appendChild(buttons);

    if (container)
    {
        if (typeof container != 'object')
            container = $getControl(container);
        container.appendChild(modalBack);
        container.appendChild(request);
        firstName.AddEvents();
        lastName.AddEvents();
        phone.AddEvents();
        company.AddEvents();
        companyFax.AddEvents();
        email.AddEvents();
        new Event('onclick').AddToElement(cancelButton, cancelButton.OnClick + 'document.body.removeChild($getControl(\'' + modalBack.id + '\'));document.body.removeChild($getControl(\'' + request.id + '\'));');
        new Event('onclick').AddToElement(sendButton, sendButton.OnClick);
    }
    return request;
}

__passwordRequest_Send = function()
{
    var obj = 'passwordRequest',
		first = new TextBox(obj + 'Firstname'),
		last = new TextBox(obj + 'Lastname'),
		phone = new PhoneBox(obj + 'Phone'),
		company = new TextBox(obj + 'Company'),
		fax = new FaxBox(obj + 'Fax'),
		email = new EmailBox(obj + 'Email');

    if (first.IsValid() && last.IsValid() && phone.IsValid() && company.IsValid() && fax.IsValid() && email.IsValid())
        PageMethods.SendPasswordRequest(first.Text, last.Text, phone.Text, company.Text, fax.Text, email.Text, "info@alberta1call.com", __passwordRequest_onComplete, __passwordRequest_onError);
    else
        alert('Some of the fields are invalid. Hover your mouse over the error marks (X) to see what\'s wrong.');
}

__passwordRequest_onComplete = function(result, response, method)
{
    alert('Your User Name and temporary password will be emailed to the address you provide within 3 business days');
    document.body.removeChild($getControl('passwordRequest'));
    document.body.removeChild($getControl('passwordRequest_modalBack'));
}

__passwordRequest_onError = function(error, response, method)
{
    if (error) alert(error.get_message());
}

///<UnitTests>
try
{
	if(__JSUnit_version>0)
	{
		
		__jsUnit.AddTest('PasswordRequest','Render','Display the password request box.','positive',
			function()
			{
				var 	actual=new PasswordRequest('Your User Name and temporary password will be emailed to the address you provide within 3 business days').Render().outerHTML.replace(/[\r\n]/g,''),
						expected='';
				
				return new JSUnitTestResult(actual,expected,true);
			});
	}
}
catch(err){}
///</UnitTests>
;