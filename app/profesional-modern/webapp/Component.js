sap.ui.define(["sap/ui/core/UIComponent"], function(UIComponent){
  return UIComponent.extend("app.profesional-modern.Component",{
    metadata:{ manifest:"json" },
    init:function(){ UIComponent.prototype.init.apply(this, arguments); this.getRouter().initialize(); }
  });
});
