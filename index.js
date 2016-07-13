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
       naviAction: function(action, context, animated) {
          try {
            const pushedControllerId = action(this.contextWithId(context), animated);
            console.log(controllerId);
          } catch(e) {
            console.error(e);
          }
       },
       push: function(context, animated) {
         this.naviAction(RNNavigator.push, context, animated);
       },
       pop: function(aimated) {
         this.naviAction(RNNavigator.pop, {}, animated);
       },
       popToRoot: function(animated) {
         this.naviAction(RNNavigator.popToRoot, {}, animated);
       },
       resetRoot: function(context, animated) {
         this.naviAction(RNNavigator.resetRoot, {}, animated);
       },
       resetTop: function(context, animated) {
         this.naviAction(RNNavigator.resetTop, {}, animated);
       }
       present: function(context, animated) {
         this.naviAction(RNNavigator.present, context, animated);
       },
       dismiss: function(animated) {
         this.naviAction(RNNavigator.dismiss, context, animated);
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

module.exports = Controllers;

