//index.js
import React, {
  NativeModules
} from 'react-native';

var RNNavigator = NativeModules.RNNavigator;
var NativeAppEventEmitter = React.NativeAppEventEmitter;

function _setListener(callbackId, func) {
  return NativeAppEventEmitter.addListener(callbackId, (...args) => func(...args));
}

function _genCallbackId() {
  return (Math.random()*1e20).toString(36);
}

function _processButtons(buttons) {
  if (!buttons) return;
  var unsubscribes = [];
  for (var i = 0 ; i < buttons.length ; i++) {
    buttons[i] = Object.assign({}, buttons[i]);
    var button = buttons[i];
    _processProperties(button);
    if (typeof button.onPress === "function") {
      var onPressId = _genCallbackId();
      var onPressFunc = button.onPress;
      button.onPress = onPressId;
      var unsubscribe = _setListener(onPressId, onPressFunc);
      unsubscribes.push(unsubscribe);
    }
  }
  return function () {
    for (var i = 0 ; i < unsubscribes.length ; i++) {
      if (unsubscribes[i]) { unsubscribes[i](); }
    }
  };
}

var NativeBridge = {
   Controller: function(id) {
     return {
       id: id,
       contextWithId: function(context) {
          var c = Object.assign({}, context);
          c.controller_id = this.id;
          return c;
       },
       naviAction: async function(action, context, animated) {
         action(this.contextWithId(context), animated, function(controllerId) {
           console.log(controllerId);
         });
       },
       push: function(context, animated) {
         this.naviAction(RNNavigator.push, context, animated);
       },
       pop: function(animated) {
         this.naviAction(RNNavigator.pop, {}, animated);
       },
       popToRoot: function(animated) {
         this.naviAction(RNNavigator.popToRoot, {}, animated);
       },
       setNaviRoot: function(context, animated) {
         this.naviAction(RNNavigator.setRoot, context, animated);
       },
       setNaviTop: function(context, animated) {
         this.naviAction(RNNavigator.setTop, context, animated);
       },
       present: function(context, animated) {
         this.naviAction(RNNavigator.present, context, animated);
       },
       dismiss: function(animated) {
         this.naviAction(RNNavigator.dismiss, {}, animated);
       },

      setLeftButtons: function (buttons, animated = false) {
        var unsubscribe = _processButtons(buttons);
        RNNavigator.setButtons(this.id, {buttons: buttons, side: "left", animated: animated});
        return unsubscribe;
      },

      setRightButtons: function (buttons, animated = false) {
        var unsubscribe = _processButtons(buttons);
        RNNavigator.setButtons(this.id, {buttons: buttons, side: "right", animated: animated});
        return unsubscribe;
      },

       invoke: function(parameters, callback) {
         RNNavigator.invoke(this.contextWithId({}), parameters, callback);
       },

       listen: function(event, callback) {
          return _setListener(event, callback); 
       },
     };
   }
}

module.exports = NativeBridge;

