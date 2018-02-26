If Exists(Select * From sysobjects Where id = object_id('dbo.SPAsistenteInterelecServicios') and sysstat & 0xf = 4)
  drop procedure dbo.SPAsistenteInterelecServicios
Go


CREATE procedure [dbo].[SPAsistenteInterelecServicios] (
  @@WorkflowID int,
  @@TransaccionSubtipoID int,
  @@OrganizacionID int,
  @@ProductoID int,
  @@TipoRol smallint,
  @@FechaHasta datetime,
  @@ManejaImportes bit,
  @@FiltrarOrganizacion bit,
  @@VinculacionInterSucursal int,
  @@IncluirTeamplace bit,
  @@dummy varchar(255) = ''
)
AS
  BEGIN

    SET NOCOUNT ON

    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    DECLARE @EmpresaIDMultitenancy int
    SET @EmpresaIDMultitenancy = (SELECT ISNULL(EmpresaID,0) FROM FAFEmpresa WHERE CAST(EmpresaID AS varchar(128)) = (SELECT CAST(CONTEXT_INFO() AS varchar(128))))

    DECLARE @TIPO_ROL_ORIGEN smallint
    DECLARE @TIPO_ROL_DESTINO smallint
    SET @TIPO_ROL_ORIGEN = 0
    SET @TIPO_ROL_DESTINO = 1

    DECLARE @OPERACION_TIPO_VENTA smallint
    DECLARE @OPERACION_TIPO_COMPRA smallint
    DECLARE @OPERACION_TIPO_LOGISTICA smallint
    SET @OPERACION_TIPO_VENTA = 0
    SET @OPERACION_TIPO_COMPRA = 1
    SET @OPERACION_TIPO_LOGISTICA = 2

    DECLARE @ESTADO_ACTIVO smallint
    SET @ESTADO_ACTIVO = -19
    DECLARE @ESTADO_FINALIZADO smallint
    SET @ESTADO_FINALIZADO = -22


    IF @@TipoRol = @TIPO_ROL_DESTINO
    --Pendientes sin Ciclo
      SELECT
        BSOperacionItem.OperacionItemID AS OperacionItemID,
        BSOrganizacion.Nombre AS Organizacion,
        TransAVincular.Nombre AS Documento,
        TransAVincular.NumeroDocumento AS Comprobante,
        TransAVincular.Fecha AS Fecha,
        BSProducto.Nombre AS Producto,
        BSWorkflowItem.CicloItemID AS CicloItemID,
        BSWorkflowItem.BPMProcesoActividadID AS BPMProcesoActividadID,
        BSOperacionItem.CantidadDisponibleOrigen AS Pendiente,
        CASE
        WHEN BSWorkflow.Tipo = @OPERACION_TIPO_COMPRA THEN UnidadCompra.Nombre
        WHEN BSWorkflow.Tipo = @OPERACION_TIPO_VENTA THEN UnidadVenta.Nombre
        ELSE UnidadStock.Nombre
        END AS Unidad,
        CASE
        WHEN (isNull(TransSubtipoAVincular.Control8,0) = 0 AND BSOperacionItem.Precio = 0) THEN BSProducto.PrecioBaseVenta
        ELSE BSOperacionItem.Precio
        END AS Precio,
        BSMoneda.Nombre AS Moneda,
        BSPartida.Numero AS Partida,
        BSOperacionItem.Descripcion AS Descripcion,
        BSOperacionItem.FechaHasta AS FechaHasta,
        BSOperacionItem.FechaProximoPaso,
        isNull(TransSubtipoAVincular.ClaseVO,TransTipoAVincular.ClaseVOTransaccion) AS '@@ClaseVO',
        TransAVincular.TransaccionID AS TransaccionID,
        EmpresaAVincular.Nombre AS Sucursal,

        Legajo = (Select  top 1 Transa.Nombre
                  from BSTransaccionDimension
                    LEFT JOIN BSTransaccion Transa ON Transa.TransaccionID =  BSTransaccionDimension.RegistroID
                  WHERE  DimensionID = 999995 AND BSTransaccionDimension.TransaccionID = TransAVincular.TransaccionID),
        codigoProducto = BSProducto.Codigo,
        codigoCliente =  BSOrganizacion.Codigo

      FROM BSWorkflowItem
        INNER JOIN FAFTransaccionSubtipo AS TransSubtipoAVincular ON TransSubtipoAVincular.TransaccionSubtipoID=BSWorkflowItem.TransaccionSubtipoIDOrigen
        INNER JOIN FAFTransaccionTipo AS TransTipoAVincular ON TransSubtipoAVincular.TransaccionTipoID=TransTipoAVincular.TransaccionTipoID
        INNER JOIN BSTransaccion AS TransAVincular ON TransAVincular.TransaccionSubtipoID=TransSubtipoAVincular.TransaccionSubtipoID
        INNER JOIN FAFEmpresa AS EmpresaAVincular ON TransAVincular.EmpresaID=EmpresaAVincular.EmpresaID
        INNER JOIN FAFEmpresa AS EmpresaCorriente ON EmpresaCorriente.EmpresaID=@EmpresaIDMultitenancy
        INNER JOIN BSOperacion ON TransAVincular.TransaccionID=BSOperacion.TransaccionID
        INNER JOIN BSOperacionItem ON BSOperacion.TransaccionID=BSOperacionItem.TransaccionID
        INNER JOIN BSWorkflow ON BSWorkflowItem.WorkflowID=BSWorkflow.WorkflowID
        LEFT JOIN BSOrganizacion ON isNull(BSOperacionItem.OrganizacionIDOrigen,BSOperacion.OrganizacionID)=BSOrganizacion.OrganizacionID
        INNER JOIN BSMoneda ON BSOperacion.MonedaID=BSMoneda.MonedaID
        INNER JOIN BSProducto ON BSOperacionItem.ProductoID=BSProducto.ProductoID
        LEFT JOIN BSUnidad AS UnidadVenta ON BSProducto.UnidadIDVenta=UnidadVenta.UnidadID
        LEFT JOIN BSUnidad AS UnidadCompra ON BSProducto.UnidadIDCompra=UnidadCompra.UnidadID
        LEFT JOIN BSUnidad AS UnidadStock ON BSProducto.UnidadIDStock1=UnidadStock.UnidadID
        INNER JOIN FAFTransaccionSubtipo AS TransaccionSubtipo ON TransaccionSubtipo.TransaccionSubtipoID=BSWorkflowItem.TransaccionSubtipoIDDestino
        INNER JOIN BSTransaccionSubtipoConceptoProducto ON (BSTransaccionSubtipoConceptoProducto.TransaccionSubtipoID=TransaccionSubtipo.TransaccionSubtipoID
                                                            AND ((TransaccionSubtipo.Control0=@OPERACION_TIPO_VENTA AND BSProducto.ConceptoIDVenta=BSTransaccionSubtipoConceptoProducto.ConceptoID)
                                                                 OR (TransaccionSubtipo.Control0=@OPERACION_TIPO_COMPRA AND BSProducto.ConceptoIDCompra=BSTransaccionSubtipoConceptoProducto.ConceptoID)
                                                                 OR (TransaccionSubtipo.Control0=@OPERACION_TIPO_LOGISTICA AND BSProducto.ConceptoIDLogistica=BSTransaccionSubtipoConceptoProducto.ConceptoID)))
        LEFT JOIN FAFTransaccionSubtipo ON TransAVincular.TransaccionSubtipoID=FAFTransaccionSubtipo.TransaccionSubtipoID
        LEFT JOIN FAFTransaccionTipo ON TransaccionSubtipo.TransacciontipoID=FAFTransaccionTipo.TransacciontipoID
        LEFT JOIN BSPartida ON BSPartida.PartidaID=BSOperacionItem.PartidaID
      WHERE
        BSWorkflowItem.TransaccionSubtipoIDDestino = @@TransaccionSubtipoID
        AND (@@WorkflowID=0 OR (BSWorkflowItem.WorkflowID = @@WorkflowID AND
                                (ISNULL(BSWorkflow.VinculacionLibre,0)=1 OR
                                 (ISNULL(BSWorkflow.VinculacionLibre,0)=0 AND BSOperacion.WorkflowID=@@WorkflowID))))
        AND (@@FiltrarOrganizacion=0 OR (@@FiltrarOrganizacion=1 AND @@OrganizacionID<>0))
        AND (@@OrganizacionID=0 OR (BSOrganizacion.OrganizacionID = @@OrganizacionID OR
                                    (isNull(BSOperacionItem.OrganizacionIDOrigen,isNull(BSOperacion.OrganizacionID,0)) = 0)))
        AND (@@ProductoID=0 OR BSProducto.ProductoID=@@ProductoID)
        AND ((BSWorkflowItem.PermitePendienteNegativo = 1 AND BSOperacionItem.CantidadDisponibleOrigen <> 0) OR BSOperacionItem.CantidadDisponibleOrigen > 0)
        AND ((@@TipoRol=@TIPO_ROL_DESTINO AND isNull(BSOperacionItem.OrganizacionIDOrigen,isNull(BSOperacion.OrganizacionID,0)) = 0)
             OR (TransaccionSubtipo.Control0=@OPERACION_TIPO_LOGISTICA OR
                 (CASE TransaccionSubtipo.Control0
                  WHEN @OPERACION_TIPO_VENTA THEN BSOrganizacion.ConceptoIDCliente
                  WHEN @OPERACION_TIPO_COMPRA THEN BSOrganizacion.ConceptoIDProveedor
                  END) IN (SELECT BSTransaccionSubtipoConceptoOrganizacion.ConceptoID AS ConceptoID
                           FROM BSTransaccionSubtipoConceptoOrganizacion
                           WHERE BSTransaccionSubtipoConceptoOrganizacion.TransaccionSubtipoID = TransaccionSubtipo.TransaccionSubtipoID)))
        AND (@EmpresaIDMultitenancy=0 OR
             ((isNull(BSWorkflowItem.VinculacionInterSucursal,0) = 1 AND EmpresaAVincular.EmpresaIDPadre = EmpresaCorriente.EmpresaIDPadre)
              OR (isNull(BSWorkflowItem.VinculacionInterSucursal,0) <> 1 AND TransAVincular.EmpresaID = @EmpresaIDMultitenancy)))
        AND (isNull(@@FechaHasta,0)=0 OR (BSOperacionItem.FechaHasta<=@@FechaHasta OR isNull(BSOperacionItem.FechaHasta,0)<@@FechaHasta))
        AND TransAVincular.EstadoID = @ESTADO_ACTIVO
        AND isNull(BSWorkflowItem.CicloItemID,0) = 0
        AND isNull(BSWorkflowItem.BPMProcesoActividadID,0) = 0

      UNION ALL

      --Pendientes con Actividad BPM
      SELECT DISTINCT
        BSOperacionItem.OperacionItemID AS OperacionItemID,
        BSOrganizacion.Nombre AS Organizacion,
        TransAVincular.Nombre AS Documento,
        TransAVincular.NumeroDocumento AS Comprobante,
        TransAVincular.Fecha AS Fecha,
        BSProducto.Nombre AS Producto,
        BSWorkflowItem.CicloItemID AS CicloItemID,
        BSWorkflowItem.BPMProcesoActividadID AS BPMProcesoActividadID,
        BSOperacionItem.CantidadDisponibleOrigen AS Pendiente,
        CASE
        WHEN BSWorkflow.Tipo = @OPERACION_TIPO_COMPRA THEN UnidadCompra.Nombre
        WHEN BSWorkflow.Tipo = @OPERACION_TIPO_VENTA THEN UnidadVenta.Nombre
        ELSE UnidadStock.Nombre
        END AS Unidad,
        CASE
        WHEN (isNull(TransSubtipoAVincular.Control8,0) = 0 AND BSOperacionItem.Precio = 0) THEN BSProducto.PrecioBaseVenta
        ELSE BSOperacionItem.Precio
        END AS Precio,
        BSMoneda.Nombre AS Moneda,
        BSPartida.Numero AS Partida,
        BSOperacionItem.Descripcion AS Descripcion,
        BSOperacionItem.FechaHasta AS FechaHasta,
        BSOperacionItem.FechaProximoPaso,
        isNull(TransSubtipoAVincular.ClaseVO,TransTipoAVincular.ClaseVOTransaccion) AS '@@ClaseVO',
        TransAVincular.TransaccionID AS TransaccionID,
        EmpresaAVincular.Nombre AS Sucursal,
        Legajo = (Select  top 1 Transa.Nombre
                  from BSTransaccionDimension
                    LEFT JOIN BSTransaccion Transa ON Transa.TransaccionID =  BSTransaccionDimension.RegistroID
                  WHERE  DimensionID = 999995 AND BSTransaccionDimension.TransaccionID = TransAVincular.TransaccionID),
        codigoProducto = BSProducto.Codigo,
        codigoCliente =  BSOrganizacion.Codigo

      FROM BSWorkflowItem
        INNER JOIN FAFTransaccionSubtipo AS TransSubtipoAVincular ON TransSubtipoAVincular.TransaccionSubtipoID=BSWorkflowItem.TransaccionSubtipoIDOrigen
        INNER JOIN FAFTransaccionTipo AS TransTipoAVincular ON TransSubtipoAVincular.TransaccionTipoID=TransTipoAVincular.TransaccionTipoID
        INNER JOIN BSTransaccion AS TransAVincular ON TransAVincular.TransaccionSubtipoID=TransSubtipoAVincular.TransaccionSubtipoID
        INNER JOIN TPCasoTransaccionAsociada ON TransAVincular.TransaccionID=TPCasoTransaccionAsociada.TransaccionIDAsociada
        INNER JOIN BSTransaccion AS TransaccionCaso ON TPCasoTransaccionAsociada.TransaccionIDCaso=TransaccionCaso.TransaccionID
        INNER JOIN TPCasoActividad AS CasoActividad ON TransaccionCaso.TransaccionID=CasoActividad.TransaccionID
        INNER JOIN FAFEmpresa AS EmpresaAVincular ON TransAVincular.EmpresaID=EmpresaAVincular.EmpresaID
        INNER JOIN FAFEmpresa AS EmpresaCorriente ON EmpresaCorriente.EmpresaID=@EmpresaIDMultitenancy
        INNER JOIN BSOperacion ON TransAVincular.TransaccionID=BSOperacion.TransaccionID
        INNER JOIN BSOperacionItem ON BSOperacion.TransaccionID=BSOperacionItem.TransaccionID
        INNER JOIN BSWorkflow ON BSWorkflowItem.WorkflowID=BSWorkflow.WorkflowID
        LEFT JOIN BSOrganizacion ON isNull(BSOperacionItem.OrganizacionIDOrigen,BSOperacion.OrganizacionID)=BSOrganizacion.OrganizacionID
        INNER JOIN BSMoneda ON BSOperacion.MonedaID=BSMoneda.MonedaID
        INNER JOIN BSProducto ON BSOperacionItem.ProductoID=BSProducto.ProductoID
        LEFT JOIN BSUnidad AS UnidadVenta ON BSProducto.UnidadIDVenta=UnidadVenta.UnidadID
        LEFT JOIN BSUnidad AS UnidadCompra ON BSProducto.UnidadIDCompra=UnidadCompra.UnidadID
        LEFT JOIN BSUnidad AS UnidadStock ON BSProducto.UnidadIDStock1=UnidadStock.UnidadID
        INNER JOIN FAFTransaccionSubtipo AS TransaccionSubtipo ON TransaccionSubtipo.TransaccionSubtipoID=BSWorkflowItem.TransaccionSubtipoIDDestino
        INNER JOIN BSTransaccionSubtipoConceptoProducto ON (BSTransaccionSubtipoConceptoProducto.TransaccionSubtipoID=TransaccionSubtipo.TransaccionSubtipoID
                                                            AND ((TransaccionSubtipo.Control0=@OPERACION_TIPO_VENTA AND BSProducto.ConceptoIDVenta=BSTransaccionSubtipoConceptoProducto.ConceptoID)
                                                                 OR (TransaccionSubtipo.Control0=@OPERACION_TIPO_COMPRA AND BSProducto.ConceptoIDCompra=BSTransaccionSubtipoConceptoProducto.ConceptoID)
                                                                 OR (TransaccionSubtipo.Control0=@OPERACION_TIPO_LOGISTICA AND BSProducto.ConceptoIDLogistica=BSTransaccionSubtipoConceptoProducto.ConceptoID)))
        LEFT JOIN FAFTransaccionSubtipo ON TransAVincular.TransaccionSubtipoID=FAFTransaccionSubtipo.TransaccionSubtipoID
        LEFT JOIN FAFTransaccionTipo ON TransaccionSubtipo.TransacciontipoID=FAFTransaccionTipo.TransacciontipoID
        LEFT JOIN BSPartida ON BSPartida.PartidaID=BSOperacionItem.PartidaID
      WHERE
        @@IncluirTeamplace=1
        AND (@@TransaccionSubtipoID = 0 OR BSWorkflowItem.TransaccionSubtipoIDDestino = @@TransaccionSubtipoID)
        AND (@@WorkflowID=0 OR (BSWorkflowItem.WorkflowID = @@WorkflowID AND
                                (ISNULL(BSWorkflow.VinculacionLibre,0)=1 OR
                                 (ISNULL(BSWorkflow.VinculacionLibre,0)=0 AND BSOperacion.WorkflowID=@@WorkflowID))))
        AND (@@FiltrarOrganizacion=0 OR (@@FiltrarOrganizacion=1 AND @@OrganizacionID<>0))
        AND (@@OrganizacionID=0 OR (BSOrganizacion.OrganizacionID = @@OrganizacionID OR
                                    isNull(BSOperacionItem.OrganizacionIDOrigen,isNull(BSOperacion.OrganizacionID,0)) = 0))
        AND (@@ProductoID=0 OR BSProducto.ProductoID=@@ProductoID)
        AND ((BSWorkflowItem.PermitePendienteNegativo = 1 AND BSOperacionItem.CantidadDisponibleOrigen <> 0) OR BSOperacionItem.CantidadDisponibleOrigen > 0)
        AND (isNull(BSOperacionItem.OrganizacionIDOrigen,isNull(BSOperacion.OrganizacionID,0)) = 0
             OR (TransaccionSubtipo.Control0=@OPERACION_TIPO_LOGISTICA OR
                 (CASE TransaccionSubtipo.Control0
                  WHEN @OPERACION_TIPO_VENTA THEN BSOrganizacion.ConceptoIDCliente
                  WHEN @OPERACION_TIPO_COMPRA THEN BSOrganizacion.ConceptoIDProveedor
                  END) IN (SELECT BSTransaccionSubtipoConceptoOrganizacion.ConceptoID AS ConceptoID
                           FROM BSTransaccionSubtipoConceptoOrganizacion
                           WHERE BSTransaccionSubtipoConceptoOrganizacion.TransaccionSubtipoID = TransaccionSubtipo.TransaccionSubtipoID)))
        AND (@EmpresaIDMultitenancy=0 OR
             ((isNull(BSWorkflowItem.VinculacionInterSucursal,0) = 1 AND EmpresaAVincular.EmpresaIDPadre = EmpresaCorriente.EmpresaIDPadre)
              OR (isNull(BSWorkflowItem.VinculacionInterSucursal,0) <> 1 AND TransAVincular.EmpresaID = @EmpresaIDMultitenancy)))
        AND (isNull(@@FechaHasta,0)=0 OR (BSOperacionItem.FechaHasta<=@@FechaHasta OR isNull(BSOperacionItem.FechaHasta,0)<@@FechaHasta))
        AND isNull(BSWorkflowItem.BPMProcesoActividadID,0) <> 0
        AND CasoActividad.BPMProcesoActividadID = BSWorkflowItem.BPMProcesoActividadID
        AND isNull(CasoActividad.Finalizada,0) = 0

    ELSE

      --Pendientes sin Ciclo
      SELECT
        BSOperacionItem.OperacionItemID AS OperacionItemID,
        BSOrganizacion.Nombre AS Organizacion,
        TransAVincular.Nombre AS Documento,
        TransAVincular.NumeroDocumento AS Comprobante,
        TransAVincular.Fecha AS Fecha,
        BSProducto.Nombre AS Producto,
        BSWorkflowItem.CicloItemID AS CicloItemID,
        BSWorkflowItem.BPMProcesoActividadID AS BPMProcesoActividadID,
        BSOperacionItem.CantidadDisponibleDestino AS Pendiente,
        CASE
        WHEN BSWorkflow.Tipo = @OPERACION_TIPO_COMPRA THEN UnidadCompra.Nombre
        WHEN BSWorkflow.Tipo = @OPERACION_TIPO_VENTA THEN UnidadVenta.Nombre
        ELSE UnidadStock.Nombre
        END AS Unidad,
        CASE
        WHEN (isNull(TransSubtipoAVincular.Control8,0) = 0 AND BSOperacionItem.Precio = 0) THEN BSProducto.PrecioBaseVenta
        ELSE BSOperacionItem.Precio
        END AS Precio,
        BSMoneda.Nombre AS Moneda,
        BSPartida.Numero AS Partida,
        BSOperacionItem.Descripcion AS Descripcion,
        BSOperacionItem.FechaHasta AS FechaHasta,
        BSOperacionItem.FechaProximoPaso,
        isNull(TransSubtipoAVincular.ClaseVO,TransTipoAVincular.ClaseVOTransaccion) AS '@@ClaseVO',
        TransAVincular.TransaccionID AS TransaccionID,
        EmpresaAVincular.Nombre AS Sucursal,
        Legajo = (Select  top 1 Transa.Nombre
                  from BSTransaccionDimension
                    LEFT JOIN BSTransaccion Transa ON Transa.TransaccionID =  BSTransaccionDimension.RegistroID
                  WHERE  DimensionID = 999995 AND BSTransaccionDimension.TransaccionID = TransAVincular.TransaccionID),
        codigoProducto = BSProducto.Codigo,
        codigoCliente =  BSOrganizacion.Codigo
      FROM BSWorkflowItem
        INNER JOIN FAFTransaccionSubtipo AS TransSubtipoAVincular ON TransSubtipoAVincular.TransaccionSubtipoID=BSWorkflowItem.TransaccionSubtipoIDDestino
        INNER JOIN FAFTransaccionTipo AS TransTipoAVincular ON TransSubtipoAVincular.TransaccionTipoID=TransTipoAVincular.TransaccionTipoID
        INNER JOIN BSTransaccion AS TransAVincular ON TransAVincular.TransaccionSubtipoID=TransSubtipoAVincular.TransaccionSubtipoID
        INNER JOIN FAFEmpresa AS EmpresaAVincular ON TransAVincular.EmpresaID=EmpresaAVincular.EmpresaID
        INNER JOIN FAFEmpresa AS EmpresaCorriente ON EmpresaCorriente.EmpresaID=@EmpresaIDMultitenancy
        INNER JOIN BSOperacion ON TransAVincular.TransaccionID=BSOperacion.TransaccionID
        INNER JOIN BSOperacionItem ON BSOperacion.TransaccionID=BSOperacionItem.TransaccionID
        INNER JOIN BSWorkflow ON BSWorkflowItem.WorkflowID=BSWorkflow.WorkflowID
        LEFT JOIN BSOrganizacion ON isNull(BSOperacionItem.OrganizacionIDDestino,BSOperacion.OrganizacionID)=BSOrganizacion.OrganizacionID
        INNER JOIN BSMoneda ON BSOperacion.MonedaID=BSMoneda.MonedaID
        INNER JOIN BSProducto ON BSOperacionItem.ProductoID=BSProducto.ProductoID
        LEFT JOIN BSUnidad AS UnidadVenta ON BSProducto.UnidadIDVenta=UnidadVenta.UnidadID
        LEFT JOIN BSUnidad AS UnidadCompra ON BSProducto.UnidadIDCompra=UnidadCompra.UnidadID
        LEFT JOIN BSUnidad AS UnidadStock ON BSProducto.UnidadIDStock1=UnidadStock.UnidadID
        INNER JOIN FAFTransaccionSubtipo AS TransaccionSubtipo ON TransaccionSubtipo.TransaccionSubtipoID=BSWorkflowItem.TransaccionSubtipoIDOrigen
        INNER JOIN BSTransaccionSubtipoConceptoProducto ON (BSTransaccionSubtipoConceptoProducto.TransaccionSubtipoID=TransaccionSubtipo.TransaccionSubtipoID
                                                            AND ((TransaccionSubtipo.Control0=@OPERACION_TIPO_VENTA AND BSProducto.ConceptoIDVenta=BSTransaccionSubtipoConceptoProducto.ConceptoID)
                                                                 OR (TransaccionSubtipo.Control0=@OPERACION_TIPO_COMPRA AND BSProducto.ConceptoIDCompra=BSTransaccionSubtipoConceptoProducto.ConceptoID)
                                                                 OR (TransaccionSubtipo.Control0=@OPERACION_TIPO_LOGISTICA AND BSProducto.ConceptoIDLogistica=BSTransaccionSubtipoConceptoProducto.ConceptoID)))
        LEFT JOIN FAFTransaccionSubtipo ON TransAVincular.TransaccionSubtipoID=FAFTransaccionSubtipo.TransaccionSubtipoID
        LEFT JOIN FAFTransaccionTipo ON TransaccionSubtipo.TransacciontipoID=FAFTransaccionTipo.TransacciontipoID
        LEFT JOIN BSPartida ON BSPartida.PartidaID=BSOperacionItem.PartidaID
      WHERE
        BSWorkflowItem.TransaccionSubtipoIDOrigen = @@TransaccionSubtipoID
        AND (@@WorkflowID=0 OR (BSWorkflowItem.WorkflowID = @@WorkflowID AND
                                (ISNULL(BSWorkflow.VinculacionLibre,0)=1 OR
                                 (ISNULL(BSWorkflow.VinculacionLibre,0)=0 AND BSOperacion.WorkflowID=@@WorkflowID))))
        AND (@@FiltrarOrganizacion=0 OR (@@FiltrarOrganizacion=1 AND @@OrganizacionID<>0))
        AND (@@OrganizacionID=0 OR (BSOrganizacion.OrganizacionID = @@OrganizacionID OR
                                    isNull(BSOperacionItem.OrganizacionIDDestino,isNull(BSOperacion.OrganizacionID,0)) = 0))
        AND (@@ProductoID=0 OR BSProducto.ProductoID=@@ProductoID)
        AND BSOperacionItem.CantidadDisponibleDestino <> 0
        AND (isNull(BSOperacionItem.OrganizacionIDDestino,isNull(BSOperacion.OrganizacionID,0)) = 0
             OR (TransaccionSubtipo.Control0=@OPERACION_TIPO_LOGISTICA OR
                 (CASE TransaccionSubtipo.Control0
                  WHEN @OPERACION_TIPO_VENTA THEN BSOrganizacion.ConceptoIDCliente
                  WHEN @OPERACION_TIPO_COMPRA THEN BSOrganizacion.ConceptoIDProveedor
                  END) IN (SELECT BSTransaccionSubtipoConceptoOrganizacion.ConceptoID AS ConceptoID
                           FROM BSTransaccionSubtipoConceptoOrganizacion
                           WHERE BSTransaccionSubtipoConceptoOrganizacion.TransaccionSubtipoID = TransaccionSubtipo.TransaccionSubtipoID)))
        AND (@EmpresaIDMultitenancy=0 OR
             ((isNull(BSWorkflowItem.VinculacionInterSucursal,0) = 1 AND EmpresaAVincular.EmpresaIDPadre = EmpresaCorriente.EmpresaIDPadre)
              OR (isNull(BSWorkflowItem.VinculacionInterSucursal,0) <> 1 AND TransAVincular.EmpresaID = @EmpresaIDMultitenancy)))
        AND (isNull(@@FechaHasta,0)=0 OR (BSOperacionItem.FechaHasta<=@@FechaHasta OR isNull(BSOperacionItem.FechaHasta,0)<@@FechaHasta))
        AND (TransAVincular.EstadoID = @ESTADO_ACTIVO OR TransAVincular.EstadoID = @ESTADO_FINALIZADO)
        AND isNull(BSWorkflowItem.CicloItemID,0) = 0
        AND isNull(BSWorkflowItem.BPMProcesoActividadID,0) = 0

      UNION ALL

      --Pendientes con Actividad BPM
      SELECT DISTINCT
        BSOperacionItem.OperacionItemID AS OperacionItemID,
        BSOrganizacion.Nombre AS Organizacion,
        TransAVincular.Nombre AS Documento,
        TransAVincular.NumeroDocumento AS Comprobante,
        TransAVincular.Fecha AS Fecha,
        BSProducto.Nombre AS Producto,
        BSWorkflowItem.CicloItemID AS CicloItemID,
        BSWorkflowItem.BPMProcesoActividadID AS BPMProcesoActividadID,
        BSOperacionItem.CantidadDisponibleDestino AS Pendiente,
        CASE
        WHEN BSWorkflow.Tipo = @OPERACION_TIPO_COMPRA THEN UnidadCompra.Nombre
        WHEN BSWorkflow.Tipo = @OPERACION_TIPO_VENTA THEN UnidadVenta.Nombre
        ELSE UnidadStock.Nombre
        END AS Unidad,
        CASE
        WHEN (isNull(TransSubtipoAVincular.Control8,0) = 0 AND BSOperacionItem.Precio = 0) THEN BSProducto.PrecioBaseVenta
        ELSE BSOperacionItem.Precio
        END AS Precio,
        BSMoneda.Nombre AS Moneda,
        BSPartida.Numero AS Partida,
        BSOperacionItem.Descripcion AS Descripcion,
        BSOperacionItem.FechaHasta AS FechaHasta,
        BSOperacionItem.FechaProximoPaso,
        isNull(TransSubtipoAVincular.ClaseVO,TransTipoAVincular.ClaseVOTransaccion) AS '@@ClaseVO',
        TransAVincular.TransaccionID AS TransaccionID,
        EmpresaAVincular.Nombre AS Sucursal,
        Legajo = (Select  top 1 Transa.Nombre
                  from BSTransaccionDimension
                    LEFT JOIN BSTransaccion Transa ON Transa.TransaccionID =  BSTransaccionDimension.RegistroID
                  WHERE  DimensionID = 999995 AND BSTransaccionDimension.TransaccionID = TransAVincular.TransaccionID),
        codigoProducto = BSProducto.Codigo,
        codigoCliente =  BSOrganizacion.Codigo
      FROM BSWorkflowItem
        INNER JOIN FAFTransaccionSubtipo AS TransSubtipoAVincular ON TransSubtipoAVincular.TransaccionSubtipoID=BSWorkflowItem.TransaccionSubtipoIDDestino
        INNER JOIN FAFTransaccionTipo AS TransTipoAVincular ON TransSubtipoAVincular.TransaccionTipoID=TransTipoAVincular.TransaccionTipoID
        INNER JOIN BSTransaccion AS TransAVincular ON TransAVincular.TransaccionSubtipoID=TransSubtipoAVincular.TransaccionSubtipoID
        INNER JOIN TPCasoTransaccionAsociada ON TransAVincular.TransaccionID=TPCasoTransaccionAsociada.TransaccionIDAsociada
        INNER JOIN BSTransaccion AS TransaccionCaso ON TPCasoTransaccionAsociada.TransaccionIDCaso=TransaccionCaso.TransaccionID
        INNER JOIN TPCasoActividad AS CasoActividad ON TransaccionCaso.TransaccionID=CasoActividad.TransaccionID
        INNER JOIN FAFEmpresa AS EmpresaAVincular ON TransAVincular.EmpresaID=EmpresaAVincular.EmpresaID
        INNER JOIN FAFEmpresa AS EmpresaCorriente ON EmpresaCorriente.EmpresaID=@EmpresaIDMultitenancy
        INNER JOIN BSOperacion ON TransAVincular.TransaccionID=BSOperacion.TransaccionID
        INNER JOIN BSOperacionItem ON BSOperacion.TransaccionID=BSOperacionItem.TransaccionID
        INNER JOIN BSWorkflow ON BSWorkflowItem.WorkflowID=BSWorkflow.WorkflowID
        LEFT JOIN BSOrganizacion ON isNull(BSOperacionItem.OrganizacionIDDestino,BSOperacion.OrganizacionID)=BSOrganizacion.OrganizacionID
        INNER JOIN BSMoneda ON BSOperacion.MonedaID=BSMoneda.MonedaID
        INNER JOIN BSProducto ON BSOperacionItem.ProductoID=BSProducto.ProductoID
        LEFT JOIN BSUnidad AS UnidadVenta ON BSProducto.UnidadIDVenta=UnidadVenta.UnidadID
        LEFT JOIN BSUnidad AS UnidadCompra ON BSProducto.UnidadIDCompra=UnidadCompra.UnidadID
        LEFT JOIN BSUnidad AS UnidadStock ON BSProducto.UnidadIDStock1=UnidadStock.UnidadID
        INNER JOIN FAFTransaccionSubtipo AS TransaccionSubtipo ON TransaccionSubtipo.TransaccionSubtipoID=BSWorkflowItem.TransaccionSubtipoIDOrigen
        INNER JOIN BSTransaccionSubtipoConceptoProducto ON (BSTransaccionSubtipoConceptoProducto.TransaccionSubtipoID=TransaccionSubtipo.TransaccionSubtipoID
                                                            AND ((TransaccionSubtipo.Control0=@OPERACION_TIPO_VENTA AND BSProducto.ConceptoIDVenta=BSTransaccionSubtipoConceptoProducto.ConceptoID)
                                                                 OR (TransaccionSubtipo.Control0=@OPERACION_TIPO_COMPRA AND BSProducto.ConceptoIDCompra=BSTransaccionSubtipoConceptoProducto.ConceptoID)
                                                                 OR (TransaccionSubtipo.Control0=@OPERACION_TIPO_LOGISTICA AND BSProducto.ConceptoIDLogistica=BSTransaccionSubtipoConceptoProducto.ConceptoID)))
        LEFT JOIN FAFTransaccionSubtipo ON TransAVincular.TransaccionSubtipoID=FAFTransaccionSubtipo.TransaccionSubtipoID
        LEFT JOIN FAFTransaccionTipo ON TransaccionSubtipo.TransacciontipoID=FAFTransaccionTipo.TransacciontipoID
        LEFT JOIN BSPartida ON BSPartida.PartidaID=BSOperacionItem.PartidaID
      WHERE
        @@IncluirTeamplace=1
        AND (@@TransaccionSubtipoID = 0 OR BSWorkflowItem.TransaccionSubtipoIDOrigen = @@TransaccionSubtipoID)
        AND (@@WorkflowID=0 OR (BSWorkflowItem.WorkflowID = @@WorkflowID AND
                                (ISNULL(BSWorkflow.VinculacionLibre,0)=1 OR
                                 (ISNULL(BSWorkflow.VinculacionLibre,0)=0 AND BSOperacion.WorkflowID=@@WorkflowID))))
        AND (@@FiltrarOrganizacion=0 OR (@@FiltrarOrganizacion=1 AND @@OrganizacionID<>0))
        AND (@@OrganizacionID=0 OR (BSOrganizacion.OrganizacionID = @@OrganizacionID OR
                                    isNull(BSOperacionItem.OrganizacionIDDestino,isNull(BSOperacion.OrganizacionID,0)) = 0))
        AND (@@ProductoID=0 OR BSProducto.ProductoID=@@ProductoID)
        AND BSOperacionItem.CantidadDisponibleDestino <> 0
        AND (isNull(BSOperacionItem.OrganizacionIDDestino,isNull(BSOperacion.OrganizacionID,0)) = 0
             OR (TransaccionSubtipo.Control0=@OPERACION_TIPO_LOGISTICA OR
                 (CASE TransaccionSubtipo.Control0
                  WHEN @OPERACION_TIPO_VENTA THEN BSOrganizacion.ConceptoIDCliente
                  WHEN @OPERACION_TIPO_COMPRA THEN BSOrganizacion.ConceptoIDProveedor
                  END) IN (SELECT BSTransaccionSubtipoConceptoOrganizacion.ConceptoID AS ConceptoID
                           FROM BSTransaccionSubtipoConceptoOrganizacion
                           WHERE BSTransaccionSubtipoConceptoOrganizacion.TransaccionSubtipoID = TransaccionSubtipo.TransaccionSubtipoID)))
        AND (@EmpresaIDMultitenancy=0 OR
             ((isNull(BSWorkflowItem.VinculacionInterSucursal,0) = 1 AND EmpresaAVincular.EmpresaIDPadre = EmpresaCorriente.EmpresaIDPadre)
              OR (isNull(BSWorkflowItem.VinculacionInterSucursal,0) <> 1 AND TransAVincular.EmpresaID = @EmpresaIDMultitenancy)))
        AND (isNull(@@FechaHasta,0)=0 OR (BSOperacionItem.FechaHasta<=@@FechaHasta OR isNull(BSOperacionItem.FechaHasta,0)<@@FechaHasta))
        AND isNull(BSWorkflowItem.BPMProcesoActividadID,0) <> 0
        AND CasoActividad.BPMProcesoActividadID = BSWorkflowItem.BPMProcesoActividadID
        AND isNull(CasoActividad.Finalizada,0) = 0

  END
GO
