


var ACCION_FOR_IMPORTE = 0;
var ACCION_FOR_PORCENTAJE = 1;
var ACCION_FOR_LISTAPRECIO = 2;
var ACCION_FOR_DIFCAMBIO = 3;
var ACCION_FOR_DEVOLUCION = 4;

var label = ["Importe","Porcentaje","Lista de Precio","TC"];




function INTER_DynamicPopup(){}



INTER_DynamicPopup.prototype = new FAFDynamicForm();

INTER_DynamicPopup.prototype._onChangeLista = function(wdg){

    var isListaVigencia = wdg.getSelectedValue("VIGENCIA") === 'SI';
    var form = wdg.getForm();
    form.getWidget("dynamicWidgetDate").setVisible(isListaVigencia);
    form._exigeFecha = isListaVigencia;






};

INTER_DynamicPopup.prototype.closePopup = function(wdg){

    wdg.getForm()._container._showedInPopup.close();

};

INTER_DynamicPopup.prototype.refreshWrid = function(wr){

    wr.getLayout('WebReportGridLayout').getFafGrid().clearSelectedRecords();
    wr.needsRefresh();
    wr.forceLayoutsRefresh();


};


INTER_DynamicPopup.prototype._sendData = function(wdg) {

    var form = wdg.getForm();
    var wr = form._colledWebRep;


    function internalCallBack(responseData) { // popup con los errores que se pudieron haber dado
        try {

            LogScreenShowPopUp(responseData);

        } catch (ex) {
            jsExceptionAlert(ex);
            throw ex;
        }
    }


    form.refreshWrid(wr);

    var fecha = '';

    var inputMotivo = form.getWidgetValue("Motivo");
    var inputDescripcion = form.getWidgetValue("Descripcion");
    var inputGeneric = 0;
    if (wr._accion === ACCION_FOR_LISTAPRECIO) {
        inputGeneric = parseInt(form.getWidgetValue("dynamicWidgetSelector"));
        if (form.getWidgetValue("dynamicWidgetDate") !== null) {
            fecha = FafDataFormatDate(form.getWidgetValue("dynamicWidgetDate"), true);

        }
    } else if (wr._accion === ACCION_FOR_PORCENTAJE){

        form._validateData = function () {
            inputGeneric = parseInt(form.getWidgetValue("dynamicWidget"));
            var retVal = true;
            if (inputGeneric > 100) {

                FAFshowError("No es posible indicar un porcentaje mayor a 100");
                retVal = false;


            }
            return retVal;


        }

    }else
        inputGeneric = form.getWidgetValue("dynamicWidget");

    if (!fecha && form._exigeFecha) {
        FAFshowMessage("debe indicar una fecha para listas con vigencia");
        return false;
    } else if (!form.checkRequiredWidgetValues())
        return false;


    var TranSubTipoNotCredito = parseInt(wr.getFilterParameter("PARAMWEBREPORT_TipoDocGenerarNotaCredito"));
    var TranSubTipoNotaDebito = parseInt(wr.getFilterParameter("PARAMWEBREPORT_TipoDocGenerarNotaDebito"));


    if (!TranSubTipoNotaDebito || isNaN(TranSubTipoNotaDebito) || isNaN(TranSubTipoNotCredito)) {
        FAFshowMessage("debe indicar los tipo de transacciones a generar, en los parametros de la vista");
        return false;
    }

    var shouldSendData = true;

    if (form._validateData)
        shouldSendData = form._validateData();


    if (shouldSendData) {
        var progress = new FAFProgressBar();
        progress.aquire(
            function (serverProgress) {
                var progressID = serverProgress.getID();

                var RM = new RemoteMethod('app.interelec.transacciones.generador.INTER_NotaCreditoGenerator', 'generateTransaction');


                RM.invoke(internalCallBack, wr._gridInfo, wr._accion, inputGeneric, TranSubTipoNotCredito, TranSubTipoNotaDebito, inputDescripcion + "|" + inputMotivo, fecha.toString(), progressID);

            });
        form._container._showedInPopup.close();
    }



};



function CreateNC(buttonDiv,Wr){

    var webRep = Wr._webreport;

    var gridInfoAjax = getInfromation(webRep);

    try{
        if (gridInfoAjax !== null ){
            var popup = new FAFPopUpList();

            popup.addItem("Generar a partir de un importe", function() {
                ExecuteAccionNC(Wr,ACCION_FOR_IMPORTE,gridInfoAjax);
                return true;
            });
            popup.addItem("Generar a partir de un porcentaje", function() {
                ExecuteAccionNC(Wr,ACCION_FOR_PORCENTAJE,gridInfoAjax);
                return true;
            });
            popup.addItem("Gererar por Lista de precio", function() {
                ExecuteAccionNC(Wr,ACCION_FOR_LISTAPRECIO,gridInfoAjax);
                return true;
            });
            popup.addItem("Generar por dif de cambio", function() {
                ExecuteAccionNC(Wr,ACCION_FOR_DIFCAMBIO,gridInfoAjax);
                return true;
            });

            popup.addItem("Generar Nota de Crédito por rechazo de mercadería ", function() {
                ExecuteAccionNC(Wr,ACCION_FOR_DEVOLUCION,gridInfoAjax);
                return true;
            });



            popup.show(buttonDiv);
        }

    }catch(ex){
        jsExceptionAlert(ex);
        throw ex;
    }




}



function ExecuteAccionNC(obj,accion,gridInfoAjax){

    var wr = obj._webreport;
    if (accion !== ACCION_FOR_DEVOLUCION) {
        function callback(xml) {
            FAFDynamicForm.loadServerForm(xml, function (df) {
                df._colledWebRep = wr;
                df._colledWebRep._accion = accion;
                df._colledWebRep._gridInfo = gridInfoAjax;


                df.getWidget("dynamicWidget").setCaption(label[accion]);
                if (accion === ACCION_FOR_LISTAPRECIO) {
                    df.getWidget("dynamicWidget").setVisible(false);
                    df.getWidget("dynamicWidgetSelector").setVisible(true);
                    df.getWidget("dynamicWidgetSelector").setCaption(label[accion]);

                }

                df.showInPopup(575);


                //ActiveForm = df;

            });

        }

        var RM = new RemoteMethod('faf.dynamicform.form.server.entidad.desktop.EntidadDesktopForm', 'getPopUpForm');
        RM.invoke(callback, 'INTERELEC_PopupGenerarNotaCredito', '');

    }else {
        FAFWEBREPORT_lastRecordLoaded = 'DF2'; // esta mierda la hago porque para generar la entidad vacio el codigo pregunta por esta variable, y ahi determina si lo hace con df1 o df2

        var Selected = wr.getSelectedRows();

        var clienteID = Selected[0].getValue("CLIENTEID");
        var workFlowID = Selected[0].getValue("WORKFLOWID");
        var operacionItemsIDList = '';
        for (var i =0 ; i < Selected.length ; i++  ){

            var row  = Selected[i];

            if (row){

                if (row.getValue("CLIENTEID") !== clienteID){
                    FAFshowError("No es posible generar una devolución de mas de un cliente ! ");
                    return;
                }
                operacionItemsIDList +=  row.getValue("OPERACIONITEMID") +  ',';

            }


        }

        var loadingDOM  = getLoading('loadFormData');
        loadingDOM.style.display = 'block';

        var TranSubTipoNotCredito = parseInt(wr.getFilterParameter("PARAMWEBREPORT_TipoDocGenerarNotaCreditoDev"));
        FAFDynamicFormVO.loadRemoteDynamicForm('OperacionVO', 0, TranSubTipoNotCredito, null, function (df) {
            getLoading('loadFormData');
            var form = df.getMainForm();

            form.setUserValue("TRANSACCIONID", -1);
            form.setUserValue("OperacionItemsIDFacturas", operacionItemsIDList);
            form.setUserValue("clienteID", clienteID);
            form.setUserValue("workFlowID", workFlowID);
            form.setUserValue("action", "loadGridItems");

            form._onBeforeClose = function(){
                wr.needsRefresh();
                wr.forceLayoutsRefresh();
                var FAFgrid = wr._currentLayout._grid;
                FAFgrid._grid.clearAll();
            };

            form.submitForm(function(){

                getLoading('loadFormData').style.display = 'none';
            });
        }, 1000);

    }
}




function getInfromation(webReport){

    //var webRep =  webReport._webreport

    var selectedRow  = webReport.getSelectedRows();




    if (typeof selectedRow[0] !== 'undefined'){
        var fafDataColumns = webReport._fafData.getColumns();
        var OperacionItemID = "";

        selectedRow.sort(function(a,b){

            return 	a[fafDataColumns.find("TransaccionID").index] < b[fafDataColumns.find("TransaccionID").index] ;
        });


        var TransaccionOldID = selectedRow[0][fafDataColumns.find("TransaccionID").index];
        var TransaccionID = selectedRow[0][fafDataColumns.find("TransaccionID").index];
        var CodeAjax = "";

        for (rowIndex = 0; rowIndex < selectedRow.length;) {


            while (TransaccionOldID === TransaccionID && rowIndex < selectedRow.length){
                OperacionItemID =   OperacionItemID + selectedRow[rowIndex][fafDataColumns.find("OperacionItemID").index] + ",";
                rowIndex++;
                if (rowIndex < selectedRow.length)
                    TransaccionID =  selectedRow[rowIndex][fafDataColumns.find("TransaccionID").index]
            }
            //TransaccionOldID = selectedRow[rowIndex][fafDataColumns.find("TransaccionID").index]

            CodeAjax += "_AJAX_SEP_"  + TransaccionOldID + ";" +  OperacionItemID;
            if (rowIndex < selectedRow.length)
                TransaccionOldID = selectedRow[rowIndex][fafDataColumns.find("TransaccionID").index];
            OperacionItemID = "";
        }

        return	CodeAjax
    }else{
        FAFshowWarning('Seleccione al menos un item');
    }


}