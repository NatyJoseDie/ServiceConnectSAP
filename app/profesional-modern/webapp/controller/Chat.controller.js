sap.ui.define(["sap/ui/core/mvc/Controller"],function(C){
  return C.extend("app.profesional-modern.controller.Chat",{
    onInit:function(){ var r=this.getOwnerComponent().getRouter(); r.getRoute("Route_Chat").attachPatternMatched(this._onRouteMatched,this); },
    _onRouteMatched:function(o){ var id=o.getParameter("arguments").threadId; this._threadId=id; this._bindMessages(); },
    _bindMessages:function(){ var l=this.byId("lstMessages"); var f=this._messageFactory.bind(this); l.bindAggregation("items",{ path:"/Message", parameters:{ $select:"senderRole,content,createdAt,isRead,thread_ID_ID" }, factory:f }); l.getBinding("items").filter([ new sap.ui.model.Filter("thread_ID_ID", sap.ui.model.FilterOperator.EQ, this._threadId) ]); },
    _messageFactory:function(sId,ctx){ var role=ctx.getProperty("senderRole"); var right=role==="professional"; var bubble=new sap.m.VBox({ items:[ new sap.m.Text({ text: ctx.getProperty("content") }), new sap.m.Label({ text: ctx.getProperty("createdAt") }) ] }).addStyleClass(right?"bubble-right":"bubble-left"); var box=new sap.m.HBox({ justifyContent: right?"End":"Start", items:[ bubble ] }); return new sap.m.CustomListItem({ content:[ box ] }); },
    onSend:function(){ var txt=this.byId("inpMsg").getValue().trim(); if(!txt||!this._threadId) return; var m=this.getView().getModel(); var lb=m.bindList("/Message"); lb.create({ thread_ID_ID:this._threadId, senderRole:"professional", content:txt, createdAt:new Date().toISOString(), isRead:false }); m.submitBatch().then(function(){ this.byId("inpMsg").setValue(""); this.byId("lstMessages").getBinding("items").refresh(); }.bind(this)); },
    onBack:function(){ window.history.back(); }
  });
});
