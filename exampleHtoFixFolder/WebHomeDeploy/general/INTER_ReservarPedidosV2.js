


/**
 * Created by nico vidal on 27/12/17.
 */

var INDEX_OPERACIONITEMID = 'OPERACIONITEMID';
var INDEX_CANTIDADASIGNADA = 'CANTIDADASIGNADA';
var INDEX_CANTIDADASIGNADAOLD = 'CANTIDADASIGNADAOLD';
var INDEX_CANTIDADPENDIENTE = 'CANTIDADPENDIENTE';
var INDEX_PRODUCTO = 'PRODUCTOID';
var INDEX_PRODUCTOCODIGO = 'CODIGOPRODUCTO';
var INDEX_SOTCK = 'STOCK';

var INDEX_IMPORTEASIGNADO = 'IMPORTEASIGNADO';
var INDEX_PRECIO = 'PRECIO';
var INDEX_SUCURSAL = 'SUCURSALID';
var INDEX_TRANSACCIONID = 'TRANSACCIONID';
var INDEX_CLIENTE = 'CLIENTEID';
var INDEX_AGRUPA = 'REMITO POR OC';
var INDEX_ITEMASIGNADO = 'ITEMASIGNADO';
var INDEX_TOPE_ENTREGA = 'TOPE DE ENTREGA';
var INDEX_CODIGO_CLIENTE ='CODIGO CLIENTE';
var INDEX_CLIENTE_NOMBRE ='CLIENTE';
var INDEX_VER_INFO ='VERINFO';
var INDEX_PRECIOSINIMPUESTOS = 'PRECIOSINIMPUESTOS';
var INDEX_PRECIODOLAR = 'PRECIODOLAR';
var INDEX_DESCUENTO1 = 'DESCUENTO1';
var INDEX_DESCUENTO2 = 'DESCUENTO2';



//var semaphore = false;
/** ojo ya hay semaforo del lado del server, esto es solo por un tema cosmetico, porque la progress bar se  muestra en el aquire tapando la anterior,
 * y prestando a la confusion sideral emblemática cosmica

 */
function HideToolTip(wr){

    wr._webreport._snapViewPopup.close();


}





function ReservaPedidosInterelec_onLoadJs(webReport){
    try{


        var gridLayout =  webReport.getLayout('WebReportGridLayout');

        gridLayout.setCellChangeEvent(ReservaPedidosInterelec_onCellChange);





        gridLayout.SUPER_afterShow = gridLayout._afterShow;


        gridLayout._grid.SUPER_moveColumn = gridLayout._grid.moveColumn;


        // cuando se mueven las columnas, hay que re cachear los indices
        gridLayout._grid.moveColumn = function (src,dst){
            this.SUPER_moveColumn(src,dst);

            this.data.cacheListManager.createColumnsCache();

        };





        /*    webReport.showLayoutByIndex = function(layoutIndex){
                if (this._layouts[layoutIndex] instanceof  WebReportGridLayout){
                    gridLayout._shouldAutomatizar = false;
                }
                this.SUPER_showLayoutByIndex(layoutIndex);
            };*/

        var webReportID = webReport._webReportDiv.id;


        gridLayout._afterShow = function () {


            this.SUPER_afterShow();



            var self  =  this;


            var fafdata = this._grid.data;


            fafdata.cacheListManager = {


                _gridFafData : self._grid.data,
                _grid : self._grid,
                _curretRow : null,

                _itemCache :  [],
                _listNameCol :  [],
                _blackList : [],
                columnsIndexCache :[],



                start : function(){

                    this.createColumnsCache();

                    var it = this.getGridIterator();


                    var selfManager = this;





                    var indexInfo = this.getIndexFromColumn(INDEX_VER_INFO);

                    while((row = it.next()) !== null) {

                        row[indexInfo] = '<a class="quickView" ' +
                            'onmouseover="javascript:ShowToolTip(' +  webReportID + ',' + row.originalIndex + ',' + indexInfo  +  ')" ' +
                            'onmouseout="javascript:HideToolTip(' + webReportID + ')">' + this.getValueFromRow(row,INDEX_VER_INFO) +
                            '</a>';


                        row.getFieldValue = function (colName){

                            return  selfManager.getValueFromRow(this,colName);


                        };
                        this._listNameCol.forEach(function (item) {

                                selfManager.addItemCache(item,row);
                            }
                        )

                    }

                },

                /* genera un hash de las columnas para obtener directamente la columna
                    a updatear y no recorrer el array de columnas por cada getFieldValue */
                createColumnsCache : function (){

                    var fafDataFields  = this._gridFafData.getColumns().fields;
                    this.columnsIndexCache = [];

                    for(var i = 0; i < fafDataFields.length; i++) {
                        this.columnsIndexCache[fafDataFields[i].name] = [];
                        this.columnsIndexCache[fafDataFields[i].name].index = i;

                        this.columnsIndexCache[fafDataFields[i].name].isToolTip =  fafDataFields[i].name === INDEX_VER_INFO   ;

                    }

                    this.getIndexFromColumn = function (colName){

                        return this.columnsIndexCache[colName].index;



                    };

                    this.isTooltip = function (colName){
                        return this.columnsIndexCache[colName].isToolTip;
                    }

                } ,

                // devuelve un valor del un row determinado, la idea es no usar el getFieldValue del row

                getValueFromRow : function(row,colName){
                    var index = this.getIndexFromColumn(colName);
                    var retValue;
                    if (this.isTooltip(colName)) {
                        var div  = document.createElement('div');
                        div.innerHTML =  this._gridFafData.data[row.originalIndex][index];
                        retValue = div.outerText
                    }else
                        retValue =  this._gridFafData.data[row.originalIndex][index];

                    return retValue

                },



                addItemCache : function (itemName, row){

                    var keyMap  = row.getFieldValue(itemName);
                    var colCache = this._itemCache[itemName];


                    var codeKey = colCache._internalCode + keyMap;
                    if (!colCache._existsKey(codeKey)) {
                        colCache[codeKey] = [];
                        colCache[codeKey]._totalAReservar = 0;
                        colCache[codeKey].cantidadRestante = parseFloat(row.getFieldValue(colCache._reservationColName));
                        colCache[codeKey].clientName = row.getFieldValue(INDEX_CODIGO_CLIENTE)
                    }
                    return colCache[codeKey];




                },

                createCache : function(itemNameCode, columnNameIden, reservationColumn){

                    this._itemCache[columnNameIden] = [];
                    var cacheList = this._itemCache[columnNameIden];
                    cacheList._columnIdentification = columnNameIden;
                    cacheList._internalCode = itemNameCode +  "_";


                    cacheList._reservationColName = reservationColumn;

                    this._listNameCol.push(columnNameIden);


                    cacheList._existsKey = function(key){
                        var value = this[key];
                        return value && value  !== undefined && value !== '' && value !== null

                    };



                },

                getGridIterator : function(){
                    var it = this._gridFafData.getIterator(null);
                    it.setCopyRow(false);
                    return it

                },

                getItemCache : function (cacheItemKey){

                    var itemCaches = this._itemCache[cacheItemKey];
                    var idRow  = this._curretRow.getFieldValue(cacheItemKey);

                    return itemCaches[itemCaches._internalCode+ idRow];




                },

                getItemCacheFromRow : function (cacheItemKey,row){
                    if (row) {
                        var itemCaches = this._itemCache[cacheItemKey];
                        if (!row.getFieldValue)
                            row.getFieldValue = function (name) {
                                return row.getValue(name);
                            };

                        var idRow = row.getFieldValue(cacheItemKey);

                        return itemCaches[itemCaches._internalCode + idRow];
                    }



                }






            };





            fafdata.cacheListManager.createCache("Prod_code",INDEX_PRODUCTO,INDEX_SOTCK);
            fafdata.cacheListManager.createCache("Clie_code",INDEX_CLIENTE,INDEX_TOPE_ENTREGA);

            fafdata.cacheListManager.start();
            var selfCache = fafdata.cacheListManager;
            if (!this._grid.super_reload)
                this._grid.super_reload =  this._grid.reload;

            this._grid.reload = function (){
                this.super_reload();
                selfCache.start();
                ReservaPedidosInterelec_refreshGrid(this)

            };



            ReservaPedidosInterelec_refreshGrid(this._grid)








        };








    } catch (ex) {
        jsExceptionAlert(ex);
        throw ex;
    }
}


function ShowToolTip(webReport,rowIndex,columnIndexTip){


    var wr = webReport._webreport;




    var row = wr._fafData.data[rowIndex];
    var grid = wr.getLayout('WebReportGridLayout');

    function DrawSnapView() {
        var html = document.createElement('div');
        html.className = 'snapViewPopup';
        var fields = wr._fafData.getColumns().fields;
        for(var i = 0; i < fields.length; i++) {

            if(fields[i].index === columnIndexTip ) {
                var div = document.createElement('div');
                div.className = 'column';

                var divCaption = document.createElement('div');
                // divCaption.className = 'caption';
                // es muy negro todo esto pero hay que hacerlo rapidito :(
                //  var captionTip = fields[i].name === INDEX_CANTIDADPENDIENTE ? 'Stock' : 'tope ';

                divCaption.innerHTML =  '';

                var divValue = document.createElement('div');
                divValue.className = 'value';
                var sysCol = null;
                for(var n = 0; n < grid._systemColumns.length; n++) {

                    if(grid._systemColumns[n].columnField == fields[i]) {
                        sysCol = grid._systemColumns[n];
                        break;
                    }
                }


                var hashCiente = wr._fafData.cacheListManager.getItemCacheFromRow(INDEX_CLIENTE,row);
                var hashProducto =  wr._fafData.cacheListManager.getItemCacheFromRow(INDEX_PRODUCTO,row);


                //divValue.innerHTML = 'tope = <b style="color:#84bae6">'  +  hashCiente.cantidadRestante.toFixed(2)  +  '</b > ;  stock =  <b style="color:#84bae6">'  + hashProducto.cantidadRestante  + '</b>';  // (cacheItem.cantidadRestante).toFixed(2);
                divValue.innerHTML = ' <p> tope = '   + hashCiente.cantidadRestante.toFixed(2)  + ' </p>  <p>stock =  '  + hashProducto.cantidadRestante  + '<p>' ;  // (cacheItem.cantidadRestante).toFixed(2);

                div.appendChild(divCaption);
                div.appendChild(divValue);
                html.appendChild(div);
            }
        }
        var popup = new FAFSimplePopup(html, true);
        popup.botonera = false;
        //popup.show(htmlRef);
        popup.showOnPointerRef(10, 10);

        popup.main.classList.add('snapViewPopupContainer');
        wr._snapViewPopup = popup;

    }

    DrawSnapView();



}


function ReservaPedidosInterelec_asignacionAutomatica(gridLayout){

    gridLayout._grid.selectAllRecords();


    gridLayout._grid.productoIDBlackList = [];
    gridLayout._grid.clientBlackList = [];
    gridLayout._grid.firstLoad = true;
    gridLayout._grid._onMainCheckboxCallback();

    gridLayout._grid.refresh();




}

var onSelection = false;
function ReservaPedidosInterelec_onCellChange(grid, row, modifiedCellIndex, newValue){
    try{
        //var form = getFormFromObject(grid._div);
        if(!onSelection)
            ReservaPedidosInterelec_reservarParcial(grid, row, modifiedCellIndex, newValue);

    } catch (ex) {
        jsExceptionAlert(ex);
        throw ex;
    }
}


function ReservaPedidosInterelec_createXmlForLog(errorMsj) {

    var xml = '<root>';

    for (var i = 0; i < errorMsj.length; i++  )
        xml += '<entry><type>3</type><text>'+ errorMsj[i] + '</text></entry>'

    xml += '</root>';



    return parseXml(xml);


}
function ReservaPedidosInterelec_Asignar(webReport){
    ReservaPedidosInterelec_AsignarDesasignar(webReport,true)
}

function ReservaPedidosInterelec_DesAsignar(webReport){
    ReservaPedidosInterelec_AsignarDesasignar(webReport,false)
}

function ReservaPedidosInterelec_AsignarDesasignar(webReport,assigned){


    var wr = webReport._webreport;

    var gridLayout =  wr.getLayout('WebReportGridLayout');
    var selectedRecords = gridLayout._grid.getSelectedRecords();
    selectedRecords.itemCount = selectedRecords.length - 1;



    ReservaPedidosInterelec_onGroupSelection(assigned,selectedRecords,gridLayout);
    // gridLayout._grid.clearSelectedRecords();
    ReservaPedidosInterelec_refreshGrid(gridLayout._grid);



}

function ReservaPedidosInterelec_onGroupSelection(asignar,itemSelection,gridLayout){

    try {




        var grid = gridLayout._webreport._currentLayout._grid;

        var fafdata = gridLayout._webreport._currentLayout._grid.data;




        for (var i = 0; i <= itemSelection.itemCount; i++) {
            var r = itemSelection[i];


            if (!r.getFieldValue) {
                r.getFieldValue = function (fieldName) {
                    return this.getValue(fieldName)
                };
            }


            if (asignar) {
                if (r.getFieldValue(INDEX_ITEMASIGNADO) !== 'Asignado') {
                    ReservaPedidosInterelec_setGridValue(grid, fafdata, r.originalIndex, INDEX_CANTIDADASIGNADA, r.getFieldValue(INDEX_CANTIDADPENDIENTE));
                    ReservaPedidosInterelec_reservar(grid, fafdata, r, true,0);
                }
            }else {
                if (r.getFieldValue(INDEX_ITEMASIGNADO) === 'Asignado') {
                    var cantidadRollBack = ReservaPedidosInterelec_setGridValue(grid, fafdata, r.originalIndex, INDEX_CANTIDADASIGNADA, 0);
                    ReservaPedidosInterelec_reservar(grid, fafdata, r, true,cantidadRollBack);
                }
            }



        }







    } catch (ex) {
        jsExceptionAlert(ex);
        throw ex;
    }
}


function ReservaPedidosInterelec_itemSelection(wrObj, grid, row,rowIndex){
    try{
        if (row) {

            row.getFieldValue = function (fieldName) {

                return grid._grid.data.cacheListManager.getValueFromRow(this, fieldName);


            };

            row.originalIndex = rowIndex;

            ReservaPedidosInterelec_proponerCantidad(grid._grid, grid._grid.data, row);
        }else
            FAFshowError("No es posible asignar/desasignar cuando se esta recargando la grilla, por favor espero un momento ")
    } catch (ex) {
        jsExceptionAlert(ex);
        throw ex;
    }
}
//@Deprecated
function ReservaPedidosInterelec_onRowSelection(form, gridLayout, row){
    try{

        var fafData = gridLayout._fafData;

        if (row) {

            row.getFieldValue = function (fieldName) {

                return fafData.cacheListManager.getValueFromRow(this, fieldName);


            };


        }



    } catch (ex) {
        jsExceptionAlert(ex);
        throw ex;
    }
}

function ReservaPedidosInterelec_reservarParcial(grid, row, modifiedCellIndex, newValue){
    try{

        var fafdata = grid._fafdata;

        row.getFieldValue = function (fieldName) {

            return fafdata.cacheListManager.getValueFromRow(this,fieldName);


        };


        var cantidadOld = Number(row.getFieldValue(INDEX_CANTIDADASIGNADAOLD));
        var cantidadRollBack = ReservaPedidosInterelec_setGridValue(grid._grid,fafdata,row.originalIndex,INDEX_CANTIDADASIGNADA,newValue);
        ReservaPedidosInterelec_reservar(grid._grid, fafdata, row,false,cantidadRollBack,cantidadOld);




        ReservaPedidosInterelec_refreshGrid(grid._grid);




    }catch(ex){
        jsExceptionAlert(ex);
        throw ex;
    }
}

function ReservaPedidosInterelec_proponerCantidad(grid, fafdata, row){
    try{


        var seleccionado  = !(row.getFieldValue(INDEX_ITEMASIGNADO) === 'Asignado'); //grid.getSelectedRecords().isSelected(row);
        var cantidadOld = Number(row.getFieldValue(INDEX_CANTIDADASIGNADAOLD));

        onSelection = true;
        if (seleccionado) {
            ReservaPedidosInterelec_setGridValue(grid, fafdata, row.originalIndex, INDEX_CANTIDADASIGNADA, row.getFieldValue(INDEX_CANTIDADPENDIENTE));

        }else
            var cantidadRollBack = ReservaPedidosInterelec_setGridValue(grid, fafdata, row.originalIndex, INDEX_CANTIDADASIGNADA, 0);


        onSelection = false;


        if (ReservaPedidosInterelec_reservar(grid, fafdata, row,false,cantidadRollBack,cantidadOld)) // devuelve algo si  hubo un problema
            grid.selectedRecords.remove(row);





        ReservaPedidosInterelec_refreshGrid(grid);


    }catch(ex){
        onSelection = false;
        jsExceptionAlert(ex);
        throw ex;
    }
}


/**
 * @return {string}
 */
function ReservaPedidosInterelec_reservar(grid, fafdata, row,isMultiselect,cantidadRollBack,cantidadOld){
    try{


        if (cantidadOld === undefined || cantidadOld === '' )
            cantidadOld = 0;
        //var wr = grid._webreport;
        fafdata.cacheListManager._curretRow = row;

        var cacheHandler =  fafdata.cacheListManager;



        var cacheProducto =  cacheHandler.getItemCache(INDEX_PRODUCTO);

        var cantidadPedida = Number(row.getFieldValue(INDEX_CANTIDADPENDIENTE));
        var cantidadAReservar = Number(row.getFieldValue(INDEX_CANTIDADASIGNADA));

        var clientCache = cacheHandler.getItemCache(INDEX_CLIENTE);


        var itemPrecio =  Number(row.getFieldValue(INDEX_PRECIO)).toFixed(3);

        var ImporteTotal =  parseFloat((cantidadAReservar * itemPrecio));
        var ImporteTotalOld =  parseFloat((cantidadOld * itemPrecio));


        cacheProducto._totalAReservar  = cantidadAReservar;
        cacheProducto._cantidadRollBack = cantidadRollBack;


        clientCache._totalAReservar = ImporteTotal;



        var cantidadStockRestante = parseFloat( cacheProducto.cantidadRestante);

        var cantidadTopeRestante = parseFloat( clientCache.cantidadRestante.toFixed(2));

        var cantidadFinalDeposito = cantidadStockRestante - cantidadAReservar;
        var cantidadFinalTope  = cantidadTopeRestante - clientCache._totalAReservar;


        // TODO hay que arreglar esto, no esta nada lindo

        if (cantidadOld > cacheProducto._totalAReservar ){
            cacheProducto._cantidadRollBack = Math.abs(cacheProducto._totalAReservar - cantidadOld);
        }else if (cantidadOld < cacheProducto._totalAReservar ){
            cacheProducto._totalAReservar = Math.abs(cacheProducto._totalAReservar - cantidadOld);
        }


        if (ImporteTotalOld > clientCache._totalAReservar ){
            cantidadFinalTope += ImporteTotalOld;
            clientCache._cantidadRollBack = Math.abs(clientCache._totalAReservar - ImporteTotalOld);
        }else if (ImporteTotalOld < clientCache._totalAReservar ){
            cantidadFinalTope +=  ImporteTotalOld;
            clientCache._totalAReservar = Math.abs(clientCache._totalAReservar - ImporteTotalOld);
        }




        var prefijoError ='Producto: '  + row.getFieldValue(INDEX_PRODUCTOCODIGO);








        if(cantidadAReservar < 0 || cantidadAReservar > cantidadPedida) {


            ReservaPedidosInterelec_setGridValue(grid, fafdata, row.originalIndex, INDEX_CANTIDADASIGNADA, cantidadOld);


            var error = 'La cantidad a reservar debe ser mayor a 0 y menor o igual que la cantidad pedida \n';

            if (!isMultiselect) {
                alert(error);
                //else
                return prefijoError + ' - ' + error
            }

        } else if(cantidadFinalDeposito < 0) {

            error = 'No hay suficiente cantidad en el deposito \n';





            ReservaPedidosInterelec_setGridValue(grid, fafdata, row.originalIndex, INDEX_CANTIDADASIGNADA, cantidadOld);



            if (!isMultiselect)
                alert(error);

            return prefijoError + ' - ' + error



        } else if (isNaN(cantidadAReservar)) {


            ReservaPedidosInterelec_setGridValue(grid, fafdata, row.originalIndex, INDEX_CANTIDADASIGNADA, cantidadOld);

        }else if ((parseFloat(cantidadFinalTope.toFixed(2)) ) < 0){
            error = 'tope del cliente excedido  \n';

            ReservaPedidosInterelec_setGridValue(grid, fafdata, row.originalIndex, INDEX_CANTIDADASIGNADA, cantidadOld);

            clientCache._cantidadRollBack = 0;


            if (!isMultiselect)
                alert(error);

            return prefijoError + ' - ' + error




        }else {
            ReservaPedidosInterelec_actualizarCantidadRestante(cacheProducto,clientCache,row);


        }
        //   if (!isMultiselect)
        //      ReservaPedidosInterelec_refreshGrid(grid);


    }catch(ex){
        jsExceptionAlert(ex);
        throw ex;
    }
}


function ReservaPedidosInterelec_actualizarCantidadRestante(cacheProducto,clientCache,row){
    try{

        //var wr = grid._webreport;
        if (cacheProducto._cantidadRollBack > 0 ) {
            cacheProducto.cantidadRestante += cacheProducto._cantidadRollBack;
            clientCache.cantidadRestante += parseFloat((cacheProducto._cantidadRollBack * row.getFieldValue(INDEX_PRECIO)).toFixed(3));


        }else {
            cacheProducto.cantidadRestante -= cacheProducto._totalAReservar;
            clientCache.cantidadRestante -=  parseFloat((cacheProducto._totalAReservar * parseFloat(row.getFieldValue(INDEX_PRECIO)).toFixed(3)))


        }





    }catch(ex){
        onSelection = false;
        jsExceptionAlert(ex);
        throw ex;
    }
}


function ReservaPedidosInterelec_setGridValue(grid, fafdata, rowIndex, columnName, valor){
    try{




        if (columnName === INDEX_CANTIDADASIGNADA) {
            if (parseFloat(valor) === 0){


                var cantidadRollBack = parseInt(fafdata.getFieldValue(rowIndex,fafdata.columns.find(INDEX_CANTIDADASIGNADA)));
                if (cantidadRollBack === 0)
                    cantidadRollBack = parseInt(fafdata.getFieldValue(rowIndex,fafdata.columns.find(INDEX_CANTIDADASIGNADAOLD)));

            }

            var asignado = parseFloat(valor) > 0 ? 'Asignado' : 'No Asignado';
            fafdata.setFieldValue(rowIndex, fafdata.columns.find(INDEX_ITEMASIGNADO), asignado);
        }

        /* Precio X cantidad asignada  */

        fafdata.setFieldValue(rowIndex, fafdata.columns.find(columnName),parseFloat(valor));
        fafdata.setFieldValue(rowIndex, fafdata.columns.find(INDEX_CANTIDADASIGNADAOLD),fafdata.getFieldValue(rowIndex,fafdata.columns.find(INDEX_CANTIDADASIGNADA)));

        // Tope de Entrega - Facturas de venta generadas del día - Importe Asignado.




        var precioItem = parseFloat(fafdata.getFieldValue(rowIndex,fafdata.columns.find(INDEX_PRECIO)));

        var ImporteItemAsignado =  (precioItem * fafdata.getFieldValue(rowIndex,fafdata.columns.find(INDEX_CANTIDADASIGNADA)));

        fafdata.setFieldValue(rowIndex, fafdata.columns.find(INDEX_IMPORTEASIGNADO),parseFloat(ImporteItemAsignado));


        return cantidadRollBack
    }catch(ex){
        jsExceptionAlert(ex);
        throw ex;
    }
}

function ReservaPedidosInterelec_refreshGrid(grid){
    var retorna;
    try{


        grid.enableSort = false;
        grid.data.enableSort = false;

        grid.fastReload();
        grid._refreshGroupData();

        grid.enableSort = true;
        grid.data.enableSort = true;


    } catch(ex){
        try {
            var scroll = grid.grid.objBox.scrollTop;
            grid.reload(true, 50);
            grid.grid.objBox.scrollTop = scroll;
        } catch(ex2) {
            jsExceptionAlert(ex);
            throw ex;
        }
    }
    return retorna;
}

function ReservaPedidosInterelec_sendData(webReport){






    function GenerarLoteTrasacciones () {

        var grid = webReport._webreport._currentLayout._grid;

        var genericToString = function (obj) {
            var propertiesString = Object.keys(obj);

            var ret = [];
            for (var i = 0; i < propertiesString.length; i++) {

                if (propertiesString[i] !== 'add' && propertiesString[i] !== 'get' && propertiesString[i] !== 'toString' && propertiesString[i] !== 'addTransaction') {

                    ret.push(propertiesString[i]);
                }

            }

            return ret

        };

        function objetClient() {}

        objetClient.prototype = {};

        objetClient.prototype.init = function () {


            this.toString = function () {

                var sucursales = Object.keys(this.sucursales);

                var ret = '';
                for (var i = 0; i < sucursales.length; i++) {

                    if (sucursales[i] !== 'add' && sucursales[i] !== 'get') {

                        ret += '_SUC_' + sucursales[i] + this.sucursales.get(sucursales[i])._transactions.toString()
                    }

                }

                return ret.replace(/,/g, '');

            },

                this.addTransaction = function (rowObjData) {
                    var sucObj = this.sucursales.get(rowObjData.sucursalName);
                    if (!sucObj)
                        this.sucursales.add(rowObjData);
                    else {
                        var transaction = sucObj._transactions.get(rowObjData.transactionID);
                        if (!transaction)
                            sucObj._transactions.add(rowObjData);
                        else
                            transaction._operacionItems.add(rowObjData);

                    }

                };


            this.sucursales = {
                add: function (objTransaction) {
                    var sucursalObject = this;
                    var suc = objTransaction.sucursalName;
                    sucursalObject[suc] = [];
                    sucursalObject[suc]._transactions = [];


                    sucursalObject[suc]._transactions.add = function (objTransaction) {

                        this[' ' + objTransaction.transactionID] = [];
                        this[' ' + objTransaction.transactionID]._operacionItems = [];
                        this[' ' + objTransaction.transactionID]._operacionItems.add = function (objOperacion) {
                            this[' ' + objOperacion.operacionItemID] = objOperacion.productoID + '@' + objOperacion.cantidad + '@' + objOperacion.precio + '@' + objOperacion.precioDolar + '@'  + objOperacion.descuento  + '@' + objOperacion.descuento2 ;
                            this.get = function (operID) {
                                return this[operID];

                            }
                        };



                        this[' ' + objTransaction.transactionID]._operacionItems.add(objTransaction);

                    };
                    sucursalObject[suc]._transactions.get = function (tranID) {
                        var ret = this[' ' + tranID];
                        if (ret === undefined)
                            return false;
                        else
                            return ret;


                    };

                    sucursalObject[suc]._transactions.toString = function () {
                        var ret = [];
                        var transactionList = genericToString(this);
                        var codeString = '';
                        for (var i = 0; i < transactionList.length; i++) {
                            codeString += '_tranID_' + transactionList[i];
                            var operItemsList = genericToString(this[transactionList[i]]._operacionItems);
                            for (var j = 0; j < operItemsList.length; j++) {
                                codeString += '_operID_' + operItemsList[j] + '->' + this[transactionList[i]]._operacionItems.get(operItemsList[j]);

                            }
                            ret.push(codeString);
                            codeString = '';

                        }
                        return ret;


                    };

                    sucursalObject[suc]._transactions.add(objTransaction)
                },

                get: function (sucursalName) {
                    return this[sucursalName]
                }

            }

        };


        var dataSenderClient = [];


        var rowData = null;


        var it = grid.data.cacheListManager.getGridIterator();

        while ((row = it.next()) !== null) {
            if (row.getFieldValue(INDEX_ITEMASIGNADO) === 'Asignado') {

                if (row.getFieldValue(INDEX_CANTIDADASIGNADA) > 0) {
                    rowData = {
                        sucursalName: row.getFieldValue(INDEX_SUCURSAL),
                        transactionID: row.getFieldValue(INDEX_TRANSACCIONID),
                        operacionItemID: row.getFieldValue(INDEX_OPERACIONITEMID),
                        productoID: row.getFieldValue(INDEX_PRODUCTO),
                        precio: row.getFieldValue(INDEX_PRECIOSINIMPUESTOS),
                        precioDolar: row.getFieldValue(INDEX_PRECIODOLAR),
                        cantidad: row.getFieldValue(INDEX_CANTIDADASIGNADA),
                        descuento: parseFloat(row.getFieldValue(INDEX_DESCUENTO1)),
                        descuento2: parseFloat(row.getFieldValue(INDEX_DESCUENTO2))

                    };


                    var cliente = row.getFieldValue(INDEX_CLIENTE);
                    if (row.getValue(INDEX_AGRUPA) === 'SI')
                        cliente += 'AG';

                    if (!dataSenderClient[cliente]) {
                        dataSenderClient[cliente] = new objetClient();
                        dataSenderClient[cliente].init();
                    }

                    dataSenderClient[cliente].addTransaction(rowData);


                }

            }

        }

        var arraySender = genericToString(dataSenderClient,dataSenderClient);


        sendDataServer(arraySender,dataSenderClient);



    }

    function sendDataServer(arraySender,dataSenderClient) {

        var wr = webReport._webreport;



        var senderDataString = '';
        for (var i = 0; i < arraySender.length; i++)
            senderDataString += (  '|' + arraySender[i] + dataSenderClient[arraySender[i]].toString());


        var depID = parseInt(wr.getFilterParameter("WEBREPROTPARAM_Deposito"));
        var transaccionSubTipoIDFactura = parseInt(wr.getFilterParameter("WEBREPROTPARAM_facturaSubTipoID"));
        var transaccionSubTipoIDRemito = parseInt(wr.getFilterParameter("WEBREPROTPARAM_RemitoID"));


        if (transaccionSubTipoIDRemito !== 0 && transaccionSubTipoIDFactura !== 0) {
            if (senderDataString.length > 0) {

                var progress = new FAFProgressBar();
                progress.aquire(
                    function (serverProgress) {
                        var progressID = serverProgress.getID();

                        var RM = new RemoteMethod("app.interelec.transacciones.generador.INTER_ESATransactionGenerator", "GenerarTransacciones");

                        RM.invoke(function (responseData) {
                            if (responseData) {



                                setTimeout(function () {

                                    LogScreenShowPopUp(responseData);

                                }, 1000); // le damos un delay para que se muestre sin problemas

                                var FAFgrid = wr._currentLayout._grid;
                                FAFgrid._grid.clearAll();
                                wr.needsRefresh();
                                wr.forceLayoutsRefresh();


                            }

                        }, senderDataString, transaccionSubTipoIDRemito, transaccionSubTipoIDFactura, depID, progressID) //);



                    })
            } else
                alert("No se puede generar Remitos sin cantidades")

        } else
            alert("Debe configurar los documentos de destino (Remito, factura)")






    }


    showAskPopup(GenerarLoteTrasacciones, null, "Desea generar las transacciones ?");


}









