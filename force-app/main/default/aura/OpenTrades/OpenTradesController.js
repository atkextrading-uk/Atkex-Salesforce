({
  doInit: function(component, event, helper) {
    var action = component.get("c.getTrades");
    action.setCallback(this, function(data) {
      component.set("v.Trades", data.getReturnValue());
      console.log(data.getReturnValue());
    });
    $A.enqueueAction(action);
  }
})