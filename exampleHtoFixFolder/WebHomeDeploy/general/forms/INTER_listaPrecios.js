function INTER_listaPrecioForm () {}


INTER_listaPrecioForm.prototype = new  BSListaPrecioForm();





INTER_listaPrecioForm.prototype.SUPER_onAfterDataLoaded = INTER_listaPrecioForm.prototype._onAfterDataLoaded;

INTER_listaPrecioForm.prototype._onAfterDataLoaded = function (){
    this.SUPER_onAfterDataLoaded();

    var listaForm  = this;


    LISTAPRECIOS_ActualizarCallback = function (obj){
        if(ajaxRequestComplete(document.objRequest)) {
           // self._refresh(self.getWidget("ListaPrecioWebRep"));
        }

    };

    LISTAPRECIOS_ActualizarItem = function (grid, row, modifiedCellIndex) {
        try {

            var idItem = row.getFieldValue('ListaPrecioItemID');
            var LPI_productoID = row.getFieldValue('ProductoID');
            var LPI_porcentajeReferencia = row.getFieldValue('PorcentajeReferencia');
            var LPI_ListaPrecioID = parametrosListaPreciosObj.getListaPrecioID();
            var LPI_ListaPrecioIDRef = parametrosListaPreciosObj.getListaPrecioIDRef();
            var LPI_FechaVigencia = parametrosListaPreciosObj.getFechaVigencia();
            var LPI_precio = 0;
            //Si tiene lista de referencia no tengo que grabar el precio
            if (LPI_ListaPrecioIDRef === null || LPI_ListaPrecioIDRef === 0 || LPI_ListaPrecioIDRef === -1) {
                LPI_precio = row.getFieldValue('Precio');
            }

            var formName = parametrosListaPreciosObj.getFormName();

            if (!LPI_porcentajeReferencia)
                LPI_porcentajeReferencia = 0;


            var param;
            if (LPI_FechaVigencia !== "" && LPI_FechaVigencia !== null) {

                var tipoLista = listaForm.getWidgetValue("TipoProducto");
                param = idItem + '|' + LPI_porcentajeReferencia + '|' + LPI_precio + '|' + LPI_ListaPrecioID + '|' + LPI_productoID + '|' + LPI_FechaVigencia + '|' + tipoLista + '|[SessionID]';
                executeServerMethod('app.interelec.configuracion.ventas.INTERListaPrecioImportadorHLP', 'updateListaItemVigencia', param, LISTAPRECIOS_ActualizarCallback, formName);
            } else {
                param = idItem + '|' + LPI_porcentajeReferencia + '|' + LPI_precio + '|' + LPI_ListaPrecioID + '|' + LPI_productoID + '|[SessionID]';
                executeServerMethod('app.bsuite.configuracion.ventas.ListaPrecioItemHLP', 'updateListaItem', param, LISTAPRECIOS_ActualizarCallback, formName);
            }

        } catch (ex) {
            jsExceptionAlert(ex);
            throw ex;
        }

    }


};



INTER_listaPrecioForm.prototype._superImportarLista =  INTER_listaPrecioForm.prototype._importarLista;


INTER_listaPrecioForm.prototype._importarLista = function (){

    if (this.getWidgetValue("TipoProducto") !== "0") {


        var obj = this.getCompatibilityForm();
        try {
            var form = getFormFromObject(obj);
            var listaID = getWidgetValue(form, "primaryKey");
            var fechaVigencia = getWidgetValue(form, "FechaVigencia");

            var button_importar = WIDGETUTILSWidgetButton(TEXT_IMPORTAR, 'openFile_click_OK', '', "INTERIMLIPREImportarListaReadFile(" + listaID + ",'" + fechaVigencia + "');", '', '80px', '');
            var button_exportar = WIDGETUTILSWidgetButton(TEXT_EXPORTAR, 'exportar_File', '', 'IMLIPREExportarXLS();', '', '80px', '');
            var button_salir = WIDGETUTILSWidgetButton(TEXTSALIR, '', '', 'WEBREPORTUTILSShowIframeFullScreen(\'ifrFullScreen\',document.forms[\'IMLIPREImportarListaFile\'],false);cClick(document.getElementById(\'overDiv\'));', '', '80px', '');
            var div = document.createElement('div');

            var innerHTML = '<br><br><form name="IMLIPREImportarListaFile" style="margin:0;">';
            if (fechaVigencia != '') {
                innerHTML += 'Se importarán registros para la vigencia: ' + fechaVigencia.substring(6, 8) + '-' + fechaVigencia.substring(4, 6) + '-' + fechaVigencia.substring(0, 4) + '<br><br>';
            }
            innerHTML += 'Seleccione el archivo a abrir:&nbsp;' +
                '<input style="width:300px;" id="IMLIPRElista_pedirArchivo_input" type="file" name="file"/></form>' + '<br>' +
                '<div style="float:right;padding-top:4px;">' + button_importar + button_exportar + button_salir + '</div>';
            div.innerHTML = innerHTML;

            popup(div.innerHTML, 'Abrir Archivo', 360, true, '');
            WEBREPORTUTILSShowIframeFullScreenBehindOverDiv('ifrFullScreen', document.forms['IMLIPREImportarListaFile']);
        } catch (ex) {
            jsExceptionAlert(ex);
            throw ex;
        }
    }else
        this._superImportarLista()


};

INTERIMLIPREImportarListaReadFile = function(listaID,fechaVigencia){
    try{
        if (listaID == null) listaID = "0";
        var uploadForm = document.forms['IMLIPREImportarListaFile'];
        var fileName = document.getElementById('IMLIPRElista_pedirArchivo_input').value;

        fileName = fileName.substring(fileName.lastIndexOf("\\") + 1, fileName.length);
        RM = new RemoteMethod('app.interelec.configuracion.ventas.INTERListaPrecioImportadorHLP', 'getAjaxResponseForImportListaPrecio');
        RM.setFileUploadForm(uploadForm);

        RM.invoke(IMLIPREImportarListaPrecioCallBack, parseInt(listaID), fechaVigencia);
    }catch (ex){
        jsExceptionAlert(ex);
        throw ex;
    }
}