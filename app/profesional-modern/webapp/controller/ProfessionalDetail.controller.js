sap.ui.define(["sap/ui/core/mvc/Controller"],function(C){
  return C.extend("app.profesional-modern.controller.ProfessionalDetail",{
    onInit:function(){ var r=this.getOwnerComponent().getRouter(); r.getRoute("Route_Detail").attachPatternMatched(this._onRouteMatched,this); },
    _onRouteMatched:function(o){ var id=o.getParameter("arguments").professionalId; var p="/Professional('"+id+"')"; this.getView().bindElement({ path:p, parameters:{ $select:"fullName,professionType,location,rating,availability,email,phone,registrationNumber,ID" } }); var l=this.byId("listSO"); var b=l.getBinding("items"); if(b){ b.filter([ new sap.ui.model.Filter("professional_ID_ID", sap.ui.model.FilterOperator.EQ, id) ]); } },
    onEdit:function(){ var id=this.getView().getBindingContext().getProperty("ID"); this.getOwnerComponent().getRouter().navTo("Route_Edit", { professionalId:id }); },
    onSendMessage:function(){ var id=this.getView().getBindingContext().getProperty("ID"); var that=this; jQuery.getJSON("/odata/v4/service-connect/MessageThread?$top=1&$filter=professional_ID_ID eq '"+id+"'", function(d){ var tid=(d.value&&d.value[0]&&d.value[0].ID)||null; if(tid){ that.getOwnerComponent().getRouter().navTo("Route_Chat", { threadId: tid }); } else { sap.m.MessageToast.show("Sin conversación"); } }); }
  });
});
