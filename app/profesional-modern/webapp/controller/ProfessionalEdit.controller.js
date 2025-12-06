sap.ui.define(["sap/ui/core/mvc/Controller"],function(C){
  return C.extend("app.profesional-modern.controller.ProfessionalEdit",{
    onInit:function(){ var r=this.getOwnerComponent().getRouter(); r.getRoute("Route_Edit").attachPatternMatched(this._onRouteMatched,this); },
    _onRouteMatched:function(o){ var id=o.getParameter("arguments").professionalId; var p="/Professional('"+id+"')"; this.getView().bindElement({ path:p }); },
    onSave:function(){ var m=this.getView().getModel(); var ctx=this.getView().getBindingContext(); var key=ctx.getPath(); var avail=this.getView().getModel().getProperty(key+"/availability"); var sel=this.getView().getModel().getProperty(key+"/__availability_sel__"); if(sel!==undefined){ m.setProperty(key+"/availability", sel==="yes"); }
      m.submitBatch().then(function(){ sap.m.MessageToast.show("Guardado"); this.getOwnerComponent().getRouter().navTo("Route_Detail", { professionalId: ctx.getProperty("ID") }); }.bind(this)); },
    onCancel:function(){ var id=this.getView().getBindingContext().getProperty("ID"); this.getOwnerComponent().getRouter().navTo("Route_Detail", { professionalId:id }); }
  });
});
