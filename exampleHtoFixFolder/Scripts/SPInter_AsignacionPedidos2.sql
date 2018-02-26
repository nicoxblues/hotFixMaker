
/****** Object:  StoredProcedure [dbo].[SPInter_AsignacionPedidos2]    Script Date: 05/01/2018 09:16:01 p.m. ******/

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SPInter_AsignacionPedidos2]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
  drop procedure [dbo].[SPInter_AsignacionPedidos2]
GO


CREATE PROCEDURE [dbo].[SPInter_AsignacionPedidos2](
  @@TipoDoc INT = 0,
  @@Deposito INT  = 114,
  @@ClienteReportCode varchar(15)  ,
  @@FechaDesdePedido DateTime = '20000101',
  @@FechaHastaPedido DateTime = '20200101',
  @@RangoMinimo Money = 0,
  @@RangoMaximo Money = 0,
  @@EmpresaID INT = 16,
  @@FacturaSubTipoID INT = 0, -- dummy 
  @@RemitoSubTipoID INT = 0, -- dummy 
  @@isDevelop bit = 0
)

AS

  BEGIN

    SET NOCOUNT ON


    DECLARE @MonedaPrincipal INT = dbo.getMonedaPrincipal()
    DECLARE @CategoriaFacturaVenta INT = -8
    DECLARE @FechaCreditoCliente  DATETIME
    DECLARE @condicionPagoIDClienteProforma int
    set @FechaCreditoCliente = GETDATE();
    if @@isDevelop <> 0
      set  @FechaCreditoCliente = '20171204'


    -- es la condicion de pago anticipo la cual nos indica que el cliente es proforma
     select @condicionPagoIDClienteProforma = BSCondicionPago.CondicionPagoID from BSCondicionPago where codigo = 'CC00'



    SELECT MonedaID, ISNULL(dbo.getCotizacion(MonedaID, getDate()), 0) AS Cotizacion
    INTO #Cotizaciones
    FROM BSMOneda



    SELECT
        TransaccionID = BSOperacionItem.TransaccionID,
        OperacionItemID = BSOperacionItem.OperacionItemID,
        Fecha = BSTransaccion.Fecha,
        ProductoID = BSOperacionItem.ProductoID,
        Pedido = BSTransaccion.NumeroDocumento,
        Cliente = BSOrganizacion.Nombre,
        ClienteID = BSOrganizacion.OrganizacionID,
        'Codigo Cliente' = BSOrganizacion.Codigo,
        Producto = BSProducto.Nombre,
        CantidadPendiente = BSOperacionItem.CantidadDisponibleOrigen,
        CantidadAsignada = CAST(0.00 AS Numeric(16,4)),
        Sucursal = case When isnull(BSSucursal.Nombre,'') = '' then 'Sin sucursal' else BSSucursal.Nombre end ,
        SucursalID = case When isnull(BSSucursal.Nombre,'') = '' then '0' else BSSucursal.SucursalID end ,
        'Remito por OC' = isnull(BSOrganizacion.USR_RemitoOC,0),
        Stock = CAST(0.00 AS Numeric(16,4)),
        'Num interno' = BSTransaccion.NumeroInterno,
        ItemAsignado = convert(varchar(250),'No Asignado'),
        'Pedido/Sucursal' = case when isnull(BSOrganizacion.USR_RemitoOC,0) = 0
          then case When isnull(BSSucursal.Nombre,'') = '' then 'Sin sucursal' else BSSucursal.Nombre end
                            else convert(VARCHAR(120),BSTransaccion.NumeroInterno)
                            end,
        CodigoProducto = BSProducto.Codigo,
        BSTasaImpositiva.Porcentaje,

        PrecioSinImpuestos = CASE WHEN (BSProducto.MonedaID = @MonedaPrincipal or BSOrganizacionCondicionPago.CondicionPagoID = isnull(@condicionPagoIDClienteProforma,0))
          THEN BSOperacionItem.PrecioMonPrincipal -- ISNULL(BSOperacionItem.USR_PrecioBaseMonPrincipal, BSOperacionItem.PrecioMonPrincipal)
                             ELSE CASE WHEN BSTransaccion.monedaID = @MonedaPrincipal
                               THEN BSOperacionItem.PrecioMonPrincipal / BSTransaccionCotizacion.Cotizacion * CotizacionMonProducto.Cotizacion
                                  ELSE abs(BSOperacionItem.PrecioMonSecundaria * CotizacionMonTransaccion.Cotizacion)
                                  END
                             END,

        PrecioDolar = CASE WHEN BSProducto.MonedaID = @MonedaPrincipal THEN BSOperacionItem.PrecioMonPrincipal / CotizacionMonTransaccion.Cotizacion
                      Else BSOperacionItem.PrecioMonSecundaria End ,

        Precio = CAST(0.00 AS Money),
        ImporteBruto = CAST(0.00 AS Money),
        ImporteTotalPedido = CAST(0.00 AS Money),
        ImporteAsignado = CAST(0.00 AS Money),
        esClienteProforma = convert(bit, CASE WHEN BSOrganizacionCondicionPago.CondicionPagoID = isnull(@condicionPagoIDClienteProforma,0) THEN 1 else 0 end),
        'Tope de entrega' = isnull(creditoDiarioForOrganizacion.monto,0),
        Descuento1 = isnull(BSOperacionItem.Descuento1,0),
		    Descuento2 = isnull(BSOperacionItem.Descuento2,0)
		

    INTO #Pedidos
    FROM BSTransaccion
      INNER JOIN FAFTransaccionSubtipo ON FAFTransaccionSubtipo.TransaccionSubtipoID = BSTransaccion.TransaccionSubtipoID
      INNER JOIN BSOperacion ON BSTransaccion.TransaccionID = BSOperacion.TransaccionID
      INNER JOIN BSOrganizacion ON BSOrganizacion.OrganizacionID = BSOperacion.OrganizacionID
      INNER JOIN BSOperacionItem on BSOperacion.TransaccionID = BSOperacionItem.TransaccionID
      INNER JOIN BSProducto ON BSProducto.ProductoID = BSOperacionItem.ProductoID

      INNER JOIN FAFArbolSeleccion As SeleccionOrganizacion ON (SeleccionOrganizacion.ReportCode = @@ClienteReportCode And
                                                                (SeleccionOrganizacion.ID = 0 Or BSOrganizacion.OrganizacionID = SeleccionOrganizacion.ID))

      INNER JOIN FAFArbolSeleccion As SeleccionTipoDocumento ON (SeleccionTipoDocumento.ReportCode = @@TipoDoc And
                                                                 (SeleccionTipoDocumento.ID = 0 Or FAFTransaccionSubtipo.TransaccionSubtipoID  = SeleccionTipoDocumento.ID))

      LEFT JOIN #Cotizaciones CotizacionMonTransaccion ON BSTransaccion.monedaID = CotizacionMonTransaccion.MonedaID
      LEFT JOIN #Cotizaciones CotizacionMonProducto ON BSProducto.MonedaID = CotizacionMonProducto.MonedaID
      LEFT JOIN BSTransaccionCotizacion ON BSTransaccion.TransaccionID = BSTransaccionCotizacion.TransaccionID AND BSProducto.MonedaID = BSTransaccionCotizacion.MonedaID
      LEFT JOIN BSTasaImpositiva on BSProducto.TasaImpositivaIDVenta = BSTasaImpositiva.TasaImpositivaID
      LEFT JOIN BSSucursal ON BSOperacion.SucursalID = BSSucursal.SucursalID
      LEFT JOIN (Select USR_CREDITODIARIO.fecha as fecha, USR_CREDITODIARIO.monto, USR_CREDITODIARIO.OrganizacionID
                  From USR_CREDITODIARIO
                    Inner Join BSOrganizacion on BSOrganizacion.OrganizacionID = USR_CREDITODIARIO.OrganizacionID
                  where USR_CREDITODIARIO.EmpresaID = @@EmpresaID
                        and USR_CREDITODIARIO.fecha = convert(Date, @FechaCreditoCliente)
                        and ISNULL(USR_CREDITODIARIO.monto, 0) <> 0) AS creditoDiarioForOrganizacion on creditoDiarioForOrganizacion.OrganizacionID = BSOrganizacion.OrganizacionID

      left join BSOrganizacionCondicionPago on BSOrganizacion.OrganizacionID = BSOrganizacionCondicionPago.OrganizacionID and BSOrganizacionCondicionPago.EsDefault <> 0

    WHERE FAFTransaccionSubtipo.TransaccionCategoriaID = -6
          AND IsNull(BSOperacionItem.CantidadDisponibleOrigen, 0) > 0
          AND BSTransaccion.Fecha <= @@FechaHastaPedido
          AND BSTransaccion.Fecha >= @@FechaDesdePedido
          AND BSTransaccion.EmpresaID = @@EmpresaID
          AND FAFTransaccionSubtipo.Codigo <> 'PROFORMAVTA'
          And BSOrganizacion.USR_Bloqueado = 0
          And BSOrganizacion.USR_Suspendido = 0
	
	
	
     -- sacamos los items que son de clientes que no tienen tope y que no son de tipo proforma
    DELETE #Pedidos where #Pedidos.esClienteProforma = 0 and #Pedidos.[Tope de entrega] <= 0
	
	
	
    -- parche ! le metemos un tope gigante al los clientes que son de tipo proforma
    update #Pedidos set [Tope de entrega] = 9999999 where #Pedidos.esClienteProforma <> 0
	
	
    --se igualan los precios, tomando el ultimo precio por productop por cliente
    UPDATE #Pedidos SET PrecioSinImpuestos = UltimoPedidoItem.PrecioSinImpuestos,
    	Descuento1 = UltimoPedidoItem.Descuento1, 
    	Descuento2 = UltimoPedidoItem.Descuento2,
    	PrecioDolar = UltimoPedidoItem.PrecioDolar
    FROM #Pedidos
    CROSS APPLY (SELECT TOP 1 PrecioSinImpuestos, Descuento1, Descuento2, PrecioDolar
    			FROM #Pedidos P 
    			WHERE P.ClienteID = #Pedidos.ClienteID 
    			AND P.ProductoID = #Pedidos.ProductoID 
    			ORDER BY p.Fecha DESC, p.TransaccionID DESC) UltimoPedidoItem
	
	
    SELECT #Pedidos.ProductoID, SUM(CantidadPendiente) AS CantidadPendiente
    INTO #ResumenPedidos
    FROM #Pedidos
    GROUP BY #Pedidos.ProductoID


    --se calculan los importes y el precio con impuestos 
    UPDATE #Pedidos SET Precio = round(#Pedidos.PrecioSinImpuestos * (#Pedidos.Porcentaje / 100 + 1),3),
      ImporteBruto = #Pedidos.PrecioSinImpuestos * #Pedidos.CantidadPendiente,
      ImporteTotalPedido = #Pedidos.PrecioSinImpuestos * (#Pedidos.Porcentaje / 100 + 1) * #Pedidos.CantidadPendiente


    --Obtengo el stock de todos los productos involucrados en el proceso
    SELECT BSMovimientoStock.ProductoID, Cantidad = sum(Cantidad1)
    INTO #TMP_depositoStock
    FROM BSMovimientoStock
      INNER JOIN #ResumenPedidos ON BSMovimientoStock.ProductoID = #ResumenPedidos.ProductoID
    WHERE BSMovimientoStock.Fecha <= getdate()
          AND BSMovimientoStock.DepositoID = @@Deposito
          AND BSMovimientoStock.EmpresaID = @@EmpresaID
    GROUP BY BSMovimientoStock.ProductoID

    --Busco todas las proformas  proformas pendientes
    SELECT BSOperacionItem.ProductoID, SUM(BSOperacionItem.CantidadDisponibleOrigen) AS Cantidad
    INTO #ReservaStockProforma
    FROM BSTransaccion
      INNER JOIN FAFTransaccionSubtipo ON BSTransaccion.TransaccionSubtipoID = FAFTransaccionSubtipo.TransaccionSubtipoID
      INNER JOIN BSOperacionItem ON BSTransaccion.TransaccionID = BSOperacionItem.TransaccionID
      INNER JOIN #ResumenPedidos ON BSOperacionItem.ProductoID = #ResumenPedidos.ProductoID
    WHERE FAFTransaccionSubtipo.Codigo = 'PROFORMAVTA'
          AND DATEDIFF(DD, BSTransaccion.Fecha,getdate()) <  3
          AND BSTransaccion.EmpresaID = @@EmpresaID
          and BSOperacionItem.CantidadDisponibleOrigen > 0
    GROUP BY BSOperacionItem.ProductoID


    --Le saco al stock disponible las proformas pendientes del dia
    UPDATE #TMP_depositoStock SET Cantidad = #TMP_depositoStock.Cantidad - ISNULL(#ReservaStockProforma.Cantidad, 0)
    FROM #TMP_depositoStock
      INNER JOIN #ReservaStockProforma ON #TMP_depositoStock.ProductoID = #ReservaStockProforma.ProductoID

    DELETE #TMP_depositoStock WHERE Cantidad <= 0


    --Elimino todos los items de pedidos de los que no hay stock
    DELETE #Pedidos WHERE ProductoID NOT IN (SELECT ProductoID FROM #TMP_depositoStock)


    --Se eliminan de la seleccion los pedidos que esten fuera de rango 
    IF @@RangoMaximo <> 0
      DELETE FROM #Pedidos
      WHERE #Pedidos.ClienteID NOT IN (SELECT ClienteID FROM #Pedidos GROUP BY ClienteID HAVING SUM(ImporteTotalPedido) >= @@RangoMinimo and SUM(ImporteTotalPedido) <= @@RangoMaximo)



    --Asigno los items que tienen stock suficiente 
    UPDATE #Pedidos SET CantidadAsignada = CASE WHEN #ResumenPedidos.CantidadPendiente <= #TMP_depositoStock.Cantidad THEN #Pedidos.CantidadPendiente ELSE 0 END,
      ItemAsignado = CASE WHEN #ResumenPedidos.CantidadPendiente <= #TMP_depositoStock.Cantidad THEN 'Asignado' ELSE 'No Asignado' END,
      ImporteAsignado = CASE WHEN #ResumenPedidos.CantidadPendiente <= #TMP_depositoStock.Cantidad THEN #Pedidos.Precio * #Pedidos.CantidadPendiente ELSE 0 END
    FROM #Pedidos
      INNER JOIN #ResumenPedidos ON #Pedidos.ProductoID = #ResumenPedidos.ProductoID
      INNER JOIN #TMP_depositoStock ON #Pedidos.ProductoID = #TMP_depositoStock.ProductoID
    --WHERE #ResumenPedidos.CantidadPendiente <= #TMP_depositoStock.Cantidad 





    --se crea un resumen de los pedidos por cliente 
    SELECT #Pedidos.ClienteID, SUM(ImporteTotalPedido) AS ImporteTotal,
                               TotalVentaDia = ISNULL((SELECT SUM(BSTransaccion.ImporteTotal)
                                                       FROM BSTransaccion
                                                         INNER JOIN FAFTransaccionSubtipo ON BSTransaccion.TransaccionSubtipoID = FAFTransaccionSubtipo.TransaccionSubtipoID
                                                         INNER JOIN BSOperacion on BSTransaccion.TransaccionID = BSOperacion.TransaccionID
                                                       WHERE BSOperacion.OrganizacionID = #Pedidos.ClienteID
                                                             --AND BSOperacion.FechaBaseVencimiento = GETDATE() 
                                                             and BSTransaccion.Fecha = getDate()
                                                             AND FAFTransaccionSubtipo.TransaccionCategoriaID = @CategoriaFacturaVenta), 0)
    INTO #ResumenPedidosCliente
    FROM #Pedidos
    WHERE ItemAsignado <> 'No Asignado'
    GROUP BY #Pedidos.ClienteID



    UPDATE #Pedidos SET CantidadAsignada = 0,
      ItemAsignado = 'No Asignado',
      ImporteAsignado = 0
    FROM #Pedidos
      INNER JOIN #ResumenPedidosCliente ON #Pedidos.ClienteID = #ResumenPedidosCliente.ClienteID
    WHERE ItemAsignado <> 'No Asignado'
          AND isnull(#Pedidos.[Tope de entrega],0) < #ResumenPedidosCliente.ImporteTotal + #ResumenPedidosCliente.TotalVentaDia






    UPDATE #Pedidos SET Stock = #TMP_depositoStock.Cantidad - (SELECT SUM(P.CantidadAsignada) FROM #Pedidos P WHERE P.ProductoID = #Pedidos.ProductoID)
    FROM #Pedidos
      INNER JOIN #TMP_depositoStock ON #Pedidos.ProductoID = #TMP_depositoStock.ProductoID



    --bajamos el tope de entrega del cliente restando importe asignado 
    UPDATE #Pedidos SET #Pedidos.[Tope de entrega] = #Pedidos.[Tope de entrega] - (#ResumenPedidosCliente.ImporteTotal + #ResumenPedidosCliente.TotalVentaDia)
    FROM #Pedidos
      INNER JOIN #ResumenPedidosCliente ON #Pedidos.ClienteID = #ResumenPedidosCliente.ClienteID
    WHERE ItemAsignado <> 'No Asignado' and #Pedidos.[Tope de entrega] > 0





    SELECT #Pedidos.*, #ResumenPedidosCliente.TotalVentaDia, CANTIDADASIGNADAOLD = #Pedidos.CantidadAsignada,VERINFO = 'Ver info'
    FROM #Pedidos
      LEFT JOIN #ResumenPedidosCliente ON #Pedidos.ClienteID = #ResumenPedidosCliente.ClienteID
    ORDER BY Cliente

  End 

go


