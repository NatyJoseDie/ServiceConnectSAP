sap.ui.define(["sap/ui/core/mvc/Controller","sap/ui/model/json/JSONModel","sap/ui/model/Filter","sap/ui/model/FilterOperator"],function(C,JSONModel,Filter,FO){
  return C.extend("app.profesional-modern.controller.Master",{
    onInit:function(){ var vm=new JSONModel({count:0,avg:0,avail:"all",ratingMin:0,query:""}); this.getView().setModel(vm,"vm"); this._bindTable(); this._refreshStats(); },
    _bindTable:function(){ var t=this.byId("tblProf"); t.bindItems({ path:"/Professional", parameters:{ $select:"fullName,professionType,location,rating,availability,ID" }, template:t.getItems()[0].clone() }); },
    _refreshStats:function(){ var that=this; jQuery.getJSON("/odata/v4/service-connect/Professional?$select=rating&$top=1000",function(d){ var vals=(d.value||[]).map(function(x){return Number(x.rating)||0}); var avg=vals.length? (vals.reduce(function(a,b){return a+b},0)/vals.length).toFixed(2):"0"; that.getView().getModel("vm").setProperty("/count", d['@odata.count']||vals.length); that.getView().getModel("vm").setProperty("/avg", avg); }); },
    onRefresh:function(){ this._bindTable(); this._refreshStats(); },
    onSortRating:function(){ var t=this.byId("tblProf"); var b=t.getBinding("items"); var cur=this._sortDesc!==false; this._sortDesc=!cur; b.sort([ new sap.ui.model.Sorter("rating", this._sortDesc) ]); },
    onFilterAvail:function(){ var vm=this.getView().getModel("vm"); var v=vm.getProperty("/avail"); vm.setProperty("/avail", v==="all"?"yes":"all"); this._applyFilters(); },
    onSearch:function(e){ this.getView().getModel("vm").setProperty("/query", e.getParameter("newValue")||""); this._applyFilters(); },
    onRatingMin:function(e){ this.getView().getModel("vm").setProperty("/ratingMin", Number(e.getSource().getSelectedKey())||0); this._applyFilters(); },
    onAvailChange:function(e){ this.getView().getModel("vm").setProperty("/avail", e.getSource().getSelectedKey()); this._applyFilters(); },
    _applyFilters:function(){ var vm=this.getView().getModel("vm"); var fs=[]; var q=vm.getProperty("/query"); if(q) fs.push(new Filter("fullName", FO.Contains, q)); var a=vm.getProperty("/avail"); if(a!=="all") fs.push(new Filter("availability", FO.EQ, a==="yes")); var r=vm.getProperty("/ratingMin"); if(r>0) fs.push(new Filter("rating", FO.GE, r)); this.byId("tblProf").getBinding("items").filter(fs); },
    onItemPress:function(e){ var ctx=e.getParameter("listItem").getBindingContext(); var id=ctx.getProperty("ID"); this.getOwnerComponent().getRouter().navTo("Route_Detail", { professionalId: id }); },
    onNew:function(){ },
    onOpenChat:function(){ this.getOwnerComponent().getRouter().navTo("Route_Chat", { threadId: "eeeeffff-0000-0000-0000-eeeeffff0001" }); }
  });
});
