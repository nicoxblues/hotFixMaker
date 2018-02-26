function INTER_OperacionForm(){

    this.ItemsNoLicencia = [];
    this.isFirst_AfterDataLoad = true;



    /********************************          SE USA SOLO PARA PEDIDOS DE VENTA        *********************************************/

    this._productosIngresadosCache = [];

    this._productosIngresadosCache.codeCol = 'CODE_PROD';

    this._productosIngresadosCache._put = function(key,value){
        var internalKey = this.codeCol + key;
        this[internalKey] = value;

    };
    this._productosIngresadosCache._get = function(key){
        var internalKey = this.codeCol + key;
        var productoID = this[internalKey];
        if (productoID != '' && productoID != undefined)
            return this[internalKey];
        else
            return false;
    };

    this._productosIngresadosCache._removeItem = function(key){
        if (this._get(key))
            this._put(key,false); // por ahora lo hacemos asi, aunque no creo que borrar el atributo del objeto sea poco costoso

    };

    /********************************          PEDIDOS DE VENTA  FIN      *********************************************/



}



INTER_OperacionForm.prototype = new BSOperacionForm();


INTER_OperacionForm.prototype._GenerarBon = function(){

    this.setUserValue ('action',"BonficarItems");
    this.submitForm ();

};



INTER_OperacionForm.prototype.SUPER_super_onAfterDataLoaded  = INTER_OperacionForm.prototype._onAfterDataLoaded;

INTER_OperacionForm.prototype._onAfterDataLoaded = function() {
    var self = this;
    self.SUPER_super_onAfterDataLoaded();
    if (this._firstLoad){
        if (this.existsWidget("IncotermID")) {
            var wdg = this.getWidget("IncotermID");
            this._onChangeIncoterm(wdg);
        }
    };

    if(this.existsWidget("USR_porcentajeSeguro")){
        var widget = this.getWidget("USR_porcentajeSeguro");
        if (!widget.originalGetValue)
            widget.originalGetValue =  widget.getValue;
        widget.getValue = function(){
            var valueRet;
            if (self.isFirst_AfterDataLoad) { // yes, i am so negro !!
                self.isFirst_AfterDataLoad = false;
                valueRet = this.originalGetValue()
            }
            else
                valueRet = this.originalGetValue() / 100;
            return valueRet;
        }

    }
    var widgetItems = this.getWidget("OperacionItems");
    var pesoTotal = 0;
    var VolumenTotal = 0;
    var lineForm;
    if (this.getWidget("OperacionItems").findForm() instanceof INTER_PedidoVentaItemsForm && this.isFirstLoad()){
        var iter = widgetItems.getDataIterator();
        while  ( row = iter.next() ){
            widgetItems.findForm().putValCacheProducto(row.getValue("PRODUCTOID"),true);
            lineForm = this._loadFormFromRow(widgetItems.findForm(),row);

            pesoTotal =+ lineForm.getWidgetValue("USR_Peso");
            VolumenTotal =+ lineForm.getWidgetValue("USR_Volumen");



        }

    }else if (this.getWidget("OperacionItems").findForm() instanceof INTER_OperacionForm){
        var iterator = widgetItems.getDataIterator();
        while  ( row = iterator.next() ){
            lineForm =  this._loadFormFromRow(widgetItems.findForm(),row);

            pesoTotal =+ lineForm.getWidgetValue("USR_Peso");
            VolumenTotal =+ lineForm.getWidgetValue("USR_Volumen");



        }

    }



};








INTER_OperacionForm.prototype._SUPER_onSave = INTER_OperacionForm.prototype._onSave;

INTER_OperacionForm.prototype._onSave = function(){


    var titulo = this.getTitulo(); /* es una manera groncha de hacerlo pero, no quiero hacer llamadas ajax, por ahora*/
    if (titulo.includes("Pedido") && !titulo.includes("Proforma") ) {
        if (this.getWidget("CondicionPago").getText().includes("Anticipado")) {
            FAFshowError("Es cliente Pago Anticipado - Usar Proforma");
            return false
        }
    }




    if (this.existsWidget("USR_porcentajeSeguro") ) {
        var widgetPorcentaje = this.getWidget("USR_porcentajeSeguro");
        this._recalcularSeguroItems(widgetPorcentaje);
    }

    this._SUPER_onSave()


};

INTER_OperacionForm.prototype._loadFormFromRow = function(formLine,row){

    try {
        formLine._shouldShow = false;
        formLine.loadRecord(row.originalIndex);
    }
    finally {
        formLine._shouldShow = true;
    }
    return formLine;

};


INTER_OperacionForm.prototype._recalcularSeguroItems = function(wdg){

    var form = wdg.getForm();
    var widgetLine = form.getWidget("OperacionItems");
    var formLine = widgetLine.findForm();
    var iter = widgetLine.getDataIterator();
    var row;
    while(row = iter.next()) {


        var impactaEnProrrateo = row.getValue("USR_IMPACTAENPRORRATEO");
        var importe = row.getValue("IMPORTE"); //form.getWidgetValue("Precio");

        if(impactaEnProrrateo){
            //No se por que preguntaba por esto pero si lo dejo no anda. Si lo último que hacias era agregar un nuevo item entonces nunca cambiaba de form y el indice que ignoraba era siempre el del nuevo item
            //if (!formLine._isNew) { // otro parche horrible, hay que hacerlo, si no cuando se hace el calculo global se levanta el popup del form
            formLine = form._loadFormFromRow(formLine,row);
            //}


            // formLine.loadRecord( row.originalIndex)

            var valor = form.getBaseCalculo(importe,formLine,true);
            var map = formLine._getObjectItemMap( row.originalIndex);
            if (map.manualChange)
                valor = map._lastSeguroValue;



            widgetLine.setRowValue("USR_calculoSeguro", row.originalIndex, valor);
        }

    }

};

INTER_OperacionForm.prototype.getBrutoTotal = function(formChild){

    var impactaEnProrrateoActual = formChild.getWidgetValue("USR_ImpactaEnProrrateo");

    var indexToIgnore = formChild.getCurrentIndex();
    var widgetLine = this.getWidget("OperacionItems");
    var iter = widgetLine.getDataIterator();
    var bruto = 0.0;
    var row;
    while(row = iter.next()) {

        if (row.originalIndex != indexToIgnore ){
            var impactaEnProrrateo = widgetLine.getRowValue("USR_IMPACTAENPRORRATEO", row.originalIndex);
            if(impactaEnProrrateo)
                bruto += widgetLine.getRowValue("IMPORTE", row.originalIndex);
        }

    }// parche feísmo por cada get que sea hace se "pisa" el valor en el form actual, porque para recuperar el valor levanta el form index
    if (indexToIgnore != -1 )
        widgetLine.getRowValue("IMPORTE", indexToIgnore);

    formChild.setWidgetValue("USR_ImpactaEnProrrateo", impactaEnProrrateoActual);

    return bruto;

};

INTER_OperacionForm.prototype.getBaseCalculo = function(actualValue,formChild,loadForm){

    var porcentaje = this.getWidgetValue("USR_porcentajeSeguro");
    var flete = this.getWidgetValue("totalFlete");
    var brutoTotal = this.getBrutoTotal(formChild) + actualValue;


    var seguroTotal = ( brutoTotal + flete ) * porcentaje;

    var fleteCertificado = (actualValue / brutoTotal) * flete;


    var baseCalculo = (seguroTotal / flete) * fleteCertificado;




    return Math.abs(baseCalculo.toFixed(7));


};






function INTER_OperacionItemsForm (){

    var self = this;

    this._internalInit = function(){
        this._indexSeguroManual = [];
        var obj = {manualChange : false, _lastSeguroValue : 0.0};
        return obj

    };

    this._getObjectItemMap = function(index){ // me devuelve un objeto que me dice si el seguro fue editado a mano y cual es el valor de la edicion
// if (!self._rowCount)
        try {
            if (index)
                self._rowCount = index;
            else
                self._rowCount = this.getCurrentIndex();

            self.curret = self._rowCount == -1 ? 1 : self._rowCount;
            var obj = self._indexSeguroManual['index' + self.curret] == undefined ? (self._internalInit()) : self._indexSeguroManual['index' + self.curret];
            self._indexSeguroManual['index' + self.curret] = obj;
            return obj
        }catch(ex){
            return self._internalInit()
        }
    }


}

INTER_OperacionItemsForm.prototype = new BSOperacionItemsForm();


INTER_OperacionItemsForm.prototype._super_super_onDimensionesTabClick = INTER_OperacionItemsForm.prototype._onDimensionesTabClick;
INTER_OperacionItemsForm.prototype._onDimensionesTabClick = function (tabContainer, tabCallback) {
    this.ItemsDimension.formItem = this;
    this._super_super_onDimensionesTabClick(tabContainer, tabCallback);
};


INTER_OperacionItemsForm.prototype._onAfterFormRender = function(){
//this._SUPER_afterRowLoaded();


    if (this._isNew){
        this._getObjectItemMap()

    }


}


INTER_OperacionItemsForm.prototype.SUPER_setItemChangedRecalculaImporte= INTER_OperacionItemsForm.prototype._setItemChangedRecalculaImporte;

INTER_OperacionItemsForm.prototype._setItemChangedRecalculaImporte = function(wdg) {

    var form = wdg.getForm();
    var objecMap = form._getObjectItemMap();

    objecMap._lastSeguroValue = form.getWidget("USR_calculoSeguro")._originalValue;
    var isChangedItems = true;
// override
    form._onReturnedFromSubmit = function(){
        var widgetSeguro = form.getWidget("USR_calculoSeguro");
        if (isChangedItems) {
            if ((wdg._id == "Precio" || wdg._id == "CantidadWorkflow") && form.getWidgetValue("Precio") != 0 && form.getWidgetValue("USR_ImpactaEnProrrateo")) {
                var valor = form.getParentForm().getBaseCalculo(form.getWidgetValue("ItemImporte"),this);
                widgetSeguro.setValue(valor);

                objecMap.manualChange = false;
                objecMap._lastSeguroValue = valor;
                isChangedItems = false;

            } else
                form.setWidgetValue("USR_calculoSeguro", 0);
        }

    };

    wdg.getForm().SUPER_setItemChangedRecalculaImporte(wdg);


};

INTER_OperacionItemsForm.prototype._cacluloSeguroChange = function (wdg) {};


INTER_OperacionItemsForm.prototype.INTERSUPER_onRecordCommit = INTER_OperacionItemsForm.prototype._onRecordCommit;

INTER_OperacionItemsForm.prototype._onRecordCommit = function (){


    var retValue;
    if (this.existsWidget("USR_ImpactaEnProrrateo")) {
        var ImpactaEnProrrateo = this.getWidgetValue("USR_ImpactaEnProrrateo");
        var calculoSeguro = this.getWidget("USR_calculoSeguro");
        calculoSeguro._required = ImpactaEnProrrateo;
        retValue = (this.INTERSUPER_onRecordCommit());
        calculoSeguro._required = !ImpactaEnProrrateo;
    }else
        retValue = (this.INTERSUPER_onRecordCommit());


    return retValue;



};


INTER_OperacionItemsForm.prototype._SUPER_super_afterRecordCommit = INTER_OperacionItemsForm.prototype._super_afterRecordCommit;


INTER_OperacionItemsForm.prototype._super_afterRecordCommit = function(buttom) {

    this._SUPER_super_afterRecordCommit(buttom);
    if (this.existsWidget("USR_Licencia")) {
        if (this.getUserValue("USR_Licencia") !== '0') { // && !this.getParentForm().getWidgetValue("USR_Licencia")) {
            this.getParentForm().setWidgetValue("USR_Licencia", 1);
            this.getParentForm().ItemsNoLicencia.push(this.getWidgetValue("Producto"))
        }
    }
    var widgetSeguro = this.getWidget("USR_calculoSeguro");
    var curretMap = this._getObjectItemMap();
    // curretMap._itemNoLicencia = itemNoLicencia;
    if ((widgetSeguro.getValue() !== curretMap._lastSeguroValue) && curretMap._lastSeguroValue !== 0) {
        curretMap.manualChange = true;
        curretMap._lastSeguroValue = widgetSeguro.getValue();


    }

    return true;

};

INTER_OperacionItemsForm.prototype._afterRowDeleted = function() {
    var parentForm = this.getParentForm();
    var listNoLicencia =  parentForm.ItemsNoLicencia;
    var value = listNoLicencia[this.getCurrentIndex() - 1];
    if (listNoLicencia.length > 0 && value == this.getWidgetValue("Producto")) {

        parentForm.ItemsNoLicencia = listNoLicencia.filter(function (item) {
            return item !== value;
        });

        if (parentForm.ItemsNoLicencia.length === 0)
            parentForm.setWidgetValue("USR_Licencia", 0);

    }


    this._indexSeguroManual['index' + this.getCurrentIndex()] = null;


};


/*****************************    PEDIDOS DE VENTA *****************************************/





function INTER_PedidoVentaItemsForm(){


    self = this;

    this._getCacheProducto = function(){
        return self.getParentForm()._productosIngresadosCache
    };

    this.getCacheProductoVal = function(key){

        return this._getCacheProducto()._get(key)
    };

    this.putValCacheProducto = function(key,value){
        this._getCacheProducto()._put(key,value)

    };


}



INTER_PedidoVentaItemsForm.prototype = new BSOperacionItemsForm();


INTER_OperacionForm.prototype.INTER_SUPER_onCondicionPagoChanged = INTER_OperacionForm.prototype._onCondicionPagoChanged;

INTER_OperacionForm.prototype._onCondicionPagoChanged = function(wdg,callback) {
    var form = wdg.getForm();

    form.INTER_SUPER_onCondicionPagoChanged(wdg, callback);
    var titulo = form.getTitulo();
    if (titulo.includes("Pedido") && !titulo.includes("Proforma")) {
        if (wdg.getText().includes("Anticipado")) {
            FAFshowError("Es cliente Pago Anticipado - Usar Proforma");
        }


    }


};

INTER_PedidoVentaItemsForm.prototype.INTER_super_onRecordCommit = INTER_PedidoVentaItemsForm.prototype._onRecordCommit;

INTER_PedidoVentaItemsForm.prototype._onRecordCommit = function(){

    var retValue =  false;

    if (this.interelecSpecialValidate()){
        this.putValCacheProducto(this.getWidgetValue("Producto"),true);
        retValue = this.INTER_super_onRecordCommit();

    }

    return retValue;





};




INTER_PedidoVentaItemsForm.prototype.interelecSpecialValidate = function () {


    // porque la cantidad minima de venta la ponen en el widget de peso neto ? no se,lo que si se, es que lo hizo un consultor


    var coeficienteVenta = this.getWidgetValue("USR_PesoNeto");
    var cantidad =  this.getWidgetValue("CantidadPresentacion");


    if (cantidad % coeficienteVenta !== 0 && coeficienteVenta !== 0 ){
        FAFshowError("Cantidad incorrecta para el coeficiente "  + coeficienteVenta);
        return false;

    }

    var prodWidget = this.getWidget("Producto");
    if (this.prodChangValidate) { // si no tengo ni la funcion, no se cambio el producto asi que nada que hacer
        var producto = this.getCacheProductoVal(prodWidget.getValue()) && this.prodChangValidate();
        this.prodChangValidate = null;

        if (producto) {
            FAFshowError("Producto " + prodWidget.getText() + " repedido ");
            prodWidget.setValue(null);
            return false;

        }

    }

    var titulo = this.getParentForm().getTitulo();

    if (titulo.includes("Proforma")) {
        var prodStock  = this.getWidgetValue("USR_StockLogistica");
        var cantidadIndicada = this.getWidgetValue("CantidadWorkflow");

        if (cantidadIndicada  > prodStock   ) {
            FAFshowError("No tiene stock suficiente para cubrir esta proforma");
            return false
        }
    }

    //if (this.getWidgetValue("USR_ReglaCantidadAplicada") != 0 )
    //  FAFshowWarning ("Cantidad pendiente " + this.getWidgetValue("USR_ReglaCantidadAplicada") );

    return true

};

INTER_PedidoVentaItemsForm.prototype.INTER_SUPER_setFilterOperacionItem = INTER_PedidoVentaItemsForm.prototype._setFilterOperacionItem;




/*es medio raro pero es para sacar el valor actual de la cache si el tipo cambia el producto */
INTER_PedidoVentaItemsForm.prototype._setFilterOperacionItem = function(wdg){
    var form = wdg.getForm();
    form.INTER_SUPER_setFilterOperacionItem(wdg);
    var oldValue = wdg.getValue();

    form.prodChangValidate = function(){
        return oldValue !== wdg.getValue()

    };

    form._getCacheProducto()._removeItem(wdg.getValue());


};


INTER_PedidoVentaItemsForm.prototype._afterRowDeleted = function() {

    this._getCacheProducto()._removeItem(this.getWidgetValue("Producto"));

};


INTER_PedidoVentaItemsForm.prototype.INTER_SUPER_onProductoChanged = INTER_PedidoVentaItemsForm.prototype._onProductoChanged;

INTER_PedidoVentaItemsForm.prototype.INTER_SUPER_setItemChangedRecalculaImporte = INTER_PedidoVentaItemsForm.prototype._setItemChangedRecalculaImporte;



INTER_PedidoVentaItemsForm.prototype._setItemChangedRecalculaImporte = function (wdg){
    var form = wdg.getForm();
    form.validate(form.INTER_SUPER_setItemChangedRecalculaImporte,wdg,true);

};


INTER_PedidoVentaItemsForm.prototype.validate = function(callback,paramCallback,executeFirstCallBack){


    // sip ya seee es un asco, ya esta piden mierda.. mierda tendran....

    if (executeFirstCallBack) {
        callback(paramCallback);
        this.interelecSpecialValidate();
    }else
    if (this.interelecSpecialValidate()){
        callback(paramCallback)

    }

};


INTER_PedidoVentaItemsForm.prototype._onProductoChanged = function(wdg) {

    var form = wdg.getForm();
    var titulo = form.getParentForm().getTitulo();

    if (titulo.includes("Proforma")) {
        form.INTER_SUPER_onProductoChanged(wdg);
        form.waitForSubmitsToComplete(function(){
            if (form.getWidgetValue("USR_ReglaCantidadAplicada") > 0)
                FAFshowMessage("Cantidad pendiente : "  + form.getWidgetValue("USR_ReglaCantidadAplicada"), null);

        });


    }
    if (wdg.isDirty()) {
        form.validate(form.INTER_SUPER_onProductoChanged, wdg);
    }

};










