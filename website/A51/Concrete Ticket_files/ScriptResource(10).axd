﻿AjaxControlToolkit.FloatingBehavior = function(element) {
AjaxControlToolkit.FloatingBehavior.initializeBase(this,[element]);var _handle;var _location;var _dragStartLocation;var _profileProperty;var _profileComponent;var _mouseDownHandler = Function.createDelegate(this, mouseDownHandler);this.add_move = function(handler) {
this.get_events().addHandler('move', handler);}
this.remove_move = function(handler) {
this.get_events().removeHandler('move', handler);}
this.get_handle = function() {
return _handle;}
this.set_handle = function(value) {
if (_handle != null) {
$removeHandler(_handle, "mousedown", _mouseDownHandler);}
_handle = value;$addHandler(_handle, "mousedown", _mouseDownHandler);}
this.get_profileProperty = function() {
return _profileProperty;}
this.set_profileProperty = function(value) {
_profileProperty = value;}
this.get_profileComponent = function() {
return _profileComponent;}
this.set_profileComponent = function(value) {
_profileComponent = value;}
this.get_location = function() {
return _location;}
this.set_location = function(value) {
if (_location != value) {
_location = value;if (this.get_isInitialized()) { 
$common.setLocation(this.get_element(), _location);}
this.raisePropertyChanged('location');}
}
this.initialize = function() {
AjaxControlToolkit.FloatingBehavior.callBaseMethod(this, 'initialize');AjaxControlToolkit.DragDropManager.registerDropTarget(this);var el = this.get_element();if (!_location) { 
_location = $common.getLocation(el);}
el.style.position = "fixed";$common.setLocation(el, _location);}
this.dispose = function() {
AjaxControlToolkit.DragDropManager.unregisterDropTarget(this);if (_handle && _mouseDownHandler) {
$removeHandler(_handle, "mousedown", _mouseDownHandler);}
_mouseDownHandler = null;AjaxControlToolkit.FloatingBehavior.callBaseMethod(this, 'dispose');}
this.checkCanDrag = function(element) {
var undraggableTagNames = ["input", "button", "select", "textarea", "label"];var tagName = element.tagName;if ((tagName.toLowerCase() == "a") && (element.href != null) && (element.href.length > 0)) {
return false;}
if (Array.indexOf(undraggableTagNames, tagName.toLowerCase()) > -1) {
return false;}
return true;}
function mouseDownHandler(ev) {
window._event = ev;var el = this.get_element();if (this.checkCanDrag(ev.target)) {
_dragStartLocation = $common.getLocation(el);ev.preventDefault();this.startDragDrop(el);}
}
this.get_dragDataType = function() {
return "_floatingObject";}
this.getDragData = function(context) {
return null;}
this.get_dragMode = function() {
return AjaxControlToolkit.DragMode.Move;}
this.onDragStart = function() { }
this.onDrag = function() { }
this.onDragEnd = function(canceled) {
if (!canceled) {
var handler = this.get_events().getHandler('move');if(handler) {
var cancelArgs = new Sys.CancelEventArgs();handler(this, cancelArgs);canceled = cancelArgs.get_cancel();} 
}
var el = this.get_element();if (canceled) {
$common.setLocation(el, _dragStartLocation);} else {
_location = $common.getLocation(el);this.raisePropertyChanged('location');}
}
this.startDragDrop = function(dragVisual) {
AjaxControlToolkit.DragDropManager.startDragDrop(this, dragVisual, null);}
this.get_dropTargetElement = function() {
return document.body;}
this.canDrop = function(dragMode, dataType, data) {
return (dataType == "_floatingObject");}
this.drop = function(dragMode, dataType, data) {}
this.onDragEnterTarget = function(dragMode, dataType, data) {}
this.onDragLeaveTarget = function(dragMode, dataType, data) {}
this.onDragInTarget = function(dragMode, dataType, data) {}
}
AjaxControlToolkit.FloatingBehavior.registerClass('AjaxControlToolkit.FloatingBehavior', AjaxControlToolkit.BehaviorBase, AjaxControlToolkit.IDragSource, AjaxControlToolkit.IDropTarget, Sys.IDisposable);