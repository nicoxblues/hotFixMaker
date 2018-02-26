/*
 * UTF-8 (ñ)
 */

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[P_INTER_OP_0013]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure [dbo].[P_INTER_OP_0013]
GO

 
CREATE PROCEDURE [dbo].[P_INTER_OP_0013](
	@@categoriaID                INT,
	@@fechaDesde                 DATETIME,
	@@fechaHasta                 DATETIME,
	@@DocumentoTipoReportCode    INT,
	@@ClienteReportCode          INT,
	@@CircuitoContableReportCode INT,
	@@DimensionID                INT,
	@@DimensionValor             INT,
	@@ProductoReportCode         INT,
	@@MonedaReportCode           INT,
	@@verPendientes              INT,
	@@EmpresaReportCode          INT,
	@@Tipo                       INT = -1, -- TIPO_VENTA = 0, TIPO_COMPRA = 1, TIPO_LOGISTICA = 2
	@@ListaCategorias            VARCHAR(255) = NULL,
	@@IncluirConceptosCalculados BIT = 1
)
	AS
BEGIN 
	SET NOCOUNT ON 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 


DECLARE @FiltroDocumentoTipo int
DECLARE @FiltroCliente int
DECLARE @FiltroEmpresa int
DECLARE @FiltroCircuitoContable int
DECLARE @FiltroMoneda int
DECLARE @FiltroProducto int


SELECT @FiltroDocumentoTipo = IsNULL(count(*),0)
FROM FAFArbolSeleccion
WHERE reportcode = @@DocumentoTipoReportCode
AND id = 0

SELECT @FiltroCliente = IsNULL(count(*),0)
FROM FAFArbolSeleccion
WHERE reportcode = @@ClienteReportCode
AND id = 0

SELECT @FiltroEmpresa = IsNULL(count(*),0)
FROM FAFArbolSeleccion
WHERE reportcode = @@EmpresaReportCode
AND id = 0

SELECT @FiltroCircuitoContable = IsNULL(count(*),0)
FROM FAFArbolSeleccion
WHERE reportcode = @@CircuitoContableReportCode
AND id = 0

SELECT @FiltroMoneda = IsNULL(count(*),0)
FROM FAFArbolSeleccion
WHERE reportcode = @@MonedaReportCode
AND id = 0

SELECT @FiltroProducto = IsNULL(count(*),0)
FROM FAFArbolSeleccion
WHERE reportcode = @@ProductoReportCode
AND id = 0

Declare @MON_ID_SECUNDARIA Int
Set @MON_ID_SECUNDARIA = dbo.getMonedaSecundaria()

 
CREATE TABLE #TMPCategorias ( 
	TransaccionCategoriaID INT) 
 
	--Si me pasaron una lista de categorias, las inserto en una tabla temporal 
	if (@@ListaCategorias<>'') 
		BEGIN 
			DECLARE @LISTATMP VarChar(255) 
			DECLARE @Posicion INT 
			SELECT @@ListaCategorias = replace(@@ListaCategorias, ' ','') 
			SELECT @LISTATMP = @@ListaCategorias 
			while (charindex(',', @LISTATMP) > 0) 
				begin 
					SELECT @Posicion = 1 
					INSERT INTO #TMPCategorias VALUES(substring(@LISTATMP, @Posicion, charindex(',',@LISTATMP)-1)) 
					SELECT @LISTATMP = substring(@LISTATMP, charindex(',',@LISTATMP) +1, len(@LISTATMP)) 
					SELECT @Posicion = charindex(',',@LISTATMP) 
				end 
			INSERT INTO #TMPCategorias VALUES (@LISTATMP) 
 
		END 
	else 
		INSERT INTO #TMPCategorias VALUES (@@categoriaID)	 
 
	declare @ITEM_TIPO_PRODUCTO int 
	declare @ITEM_TIPO_CONCEPTO int
	declare @verPendientesOrigen int 
	declare @verPendientesDestino int 
 
	Declare @DimensionID Int  
	Declare @RegistroID Int  
	Set @DimensionID = IsNull(@@DimensionID, 0)  
	Set @RegistroID = IsNull(@@DimensionValor, 0)  
 
	set @ITEM_TIPO_PRODUCTO = 0 
	set @ITEM_TIPO_CONCEPTO = 1
 
	-- no ver sólo pendientes 
	if (@@verPendientes=0)  
	begin 
		set @verPendientesOrigen = 0 
		set @verPendientesDestino = 0
	end 
 
	-- ver pendientes de origen 
	if (@@verPendientes=1)  
	begin 
		set @verPendientesOrigen = 1 
		set @verPendientesDestino = 0 
	end 
 
	-- ver pendientes de destino 
	if (@@verPendientes=2)  
	begin 
		set @verPendientesOrigen = 0 
		set @verPendientesDestino = 1 
	end 
 
	-- ver pendientes de origen y destino 
	if (@@verPendientes=3)  
	begin 
		set @verPendientesOrigen = 1 
		set @verPendientesDestino = 1 
	end 
	
	/* No modificar el orden de los campos del select, en caso de ser necesario 
	o al agregar/sacar algun campo revisar el SPBSIndicadorImportePedidoMesActual y el SPBSIndicadorProductoMasVendidoMesActual*/
	
	
	SELECT  
		'OperacionItemID' = BSOperacionItem.OperacionItemID, 
		'TransaccionSubtipoID' = bstransaccion.transaccionsubtipoid,
		'Fecha' = BSTransaccion.Fecha, 
		'FechaComprobante' = BSTransaccion.FechaComprobante, 
		'TransaccionTipoNombre' = FAFTransaccionTipo.nombre, 
		'TransacconSubtipoNombre' = FAFTransaccionSubTipo.nombre, 
		'TransaccionID' = BSTransaccion.TransaccionID, 
		'DocNroInt' = FAFTransaccionSubtipo.Codigo + ' - ' + convert(varchar(7), BSTransaccion.NumeroInterno), 
		'Comprobante' = BSTransaccion.NumeroDocumento, 
		'ComprobanteAdicional' = IsNull (BSOperacion.NumeroDocumentoAdicional,''),
		'NumeroContrato' = IsNull (BSOperacion.NumeroContratoIntermediario, ''), 
		'DimensionValor' = BSDimensionSeleccion.Nombre, 
		'TotalBruto' = (BSTransaccion.ImporteBruto * FAFTransaccionSubtipo.Control23), 
		'TotalConceptos' = (BSTransaccion.ImporteOtros * FAFTransaccionSubtipo.Control23), 
		'Total' = (BSTransaccion.ImporteTotal * FAFTransaccionSubtipo.Control23), 
		'Cliente' = IsNull(BSOrganizacion.Nombre,''), 
		'Descripcion' = BSTransaccion.Descripcion, 
		'CondicionPago' = BSCondicionPago.Nombre, 
		'Moneda' = BSMoneda.Nombre, 
		'Cotizacion' = BSTransaccionCotizacion.Cotizacion,  
		'ListaPrecio' = BSListaPrecio.nombre, 
		'Vendedor' = BSPersona.Nombre, 
		'Producto' = 	Case BSOperacionItem.Tipo 
					When @ITEM_TIPO_PRODUCTO Then BSProducto.Nombre
					When @ITEM_TIPO_CONCEPTO Then BSConcepto.Nombre
				End,
		'Marca'=isNull(BSMarca.Nombre,''),
		'DescItem' = BSOperacionItem.Descripcion,        
        'Cantidad' = case when (@DimensionID = 0) 
                         then (BSOperacionItem.CantidadWorkflow) 
                         else (dbo.getCantidadFromPorcentajeCantidad(BSOperacionItem.CantidadWorkflow, isNull(BSTransaccionDimension.Porcentaje, 100)))  
                     end * case when BSAsientoItem.debeHaber is null
                               then FAFTransaccionSubtipo.Control23
                               else BSAsientoItem.debeHaber * case when (isNull(FAFTransaccionSubtipo.control0, 0) = 0)
                                                                  then -1
                                                                  else 1
                                                              end
                           end,
                    
		'CantidadPendiente' = BSOperacionItem.CantidadDisponibleDestino, 
		'CantidadStock2' = BSOperacionItem.CantidadStock2, 
		'UnidadVenta' = UnidadVenta.Nombre, 
		'UnidadCompra' = UnidadCompra.Nombre, 
		'UnidadStock' = UnidadStock.Nombre, 
		'UnidadStock2' = UnidadStock2.Nombre, 
		'Precio' = BSOperacionItem.Precio, 
		'PrecioMonPrincipal' = BSOperacionItem.PrecioMonPrincipal,
		'PrecioMonSecundaria' = BSOperacionItem.USR_PrecioMonSecundaria,

		'ImporteMonPrincipal' = Case When (@DimensionID = 0 Or IsNull(BSTransaccionDimension.ImporteMonPrincipal,0) = 0) 
                                    Then (Case When IsNull(BSAsientoItem.AsientoItemId, 0) = 0
                                            Then
                                                (Case When BSOperacionItem.PrecioTipo = 1 
                                                    Then BSOperacionItem.CantidadStock1 * BSOperacionItem.PrecioMonPrincipal
                                                When BSOperacionItem.PrecioTipo = 2 
                                                    Then BSOperacionItem.CantidadStock2 * BSOperacionItem.PrecioMonPrincipal
                                                Else BSOperacionItem.CantidadWorkflow * BSOperacionItem.PrecioMonPrincipal
                                                End)
                                            Else BSAsientoItem.ImporteMonPrincipal 
                                            end)
                                    Else BSTransaccionDimension.ImporteMonPrincipal
								end * case when BSAsientoItem.debeHaber is null
                                          then FAFTransaccionSubtipo.Control23
                                          else BSAsientoItem.debeHaber * case when (isNull(FAFTransaccionSubtipo.control0, 0) = 0)
                                                                             then -1
                                                                             else 1
                                                                         end
                                      end,
                    
		'ImporteMonSecundaria' = BSOperacionItem.USR_ImporteMonSecundaria, /*Case When (@DimensionID = 0 Or IsNull(BSTransaccionDimension.ImporteMonSecundaria,0) = 0)
                                    Then (Case When IsNull(BSAsientoItem.AsientoItemId, 0) = 0
                                            Then 
                                                (Case When BSOperacionItem.PrecioTipo = 1 
                                                    Then BSOperacionItem.CantidadStock1 * BSOperacionItem.PrecioMonSecundaria
                                                When BSOperacionItem.PrecioTipo = 2 
                                                    Then BSOperacionItem.CantidadStock2 * BSOperacionItem.PrecioMonSecundaria
                                                Else BSOperacionItem.CantidadWorkflow * BSOperacionItem.PrecioMonSecundaria
                                                End)
                                            Else BSAsientoItem.ImporteMonSecundaria
                                            End)
                                    Else BSTransaccionDimension.ImporteMonSecundaria
					 			 end * case when BSAsientoItem.debeHaber is null
                                           then FAFTransaccionSubtipo.Control23
                                           else BSAsientoItem.debeHaber * case when (isNull(FAFTransaccionSubtipo.control0, 0) = 0)
                                                                              then -1
                                                                              else 1
                                                                          end
                                       end,*/

		'DepositoOrigen' = DepositoOrigen.Nombre, 
		'DepositoDestino' = DepositoDestino.Nombre, 
		'PrecioSobre' = Case 	When BSOperacionItem.PrecioTipo = 1 Then 'Cant. Stock 1'  
					When BSOperacionItem.PrecioTipo = 2 Then 'Cant. Stock 2'  
					Else 'Cantidad' End, 
		'Importe' =   CASE WHEN IsNull(BSOperacionItem.Importe,0) <> 0 THEN
					(Case When @DimensionID = 0 Then 		-- Mon Transaccion 
						(BSOperacionItem.Importe * FAFTransaccionSubtipo.Control23) 
					Else 
						(Case When (BSOperacionItem.Importe < 0) 
						Then  
							IsNull(BSTransaccionDimension.ImporteMonTransaccion * -1,BSOperacionItem.Importe) 
						Else 
							IsNull(BSTransaccionDimension.ImporteMonTransaccion,BSOperacionItem.Importe)  
						End) * FAFTransaccionSubtipo.Control23 
					End) - Isnull(BSOperacionItem.ImporteImpuestoIncluido,0) * FAFTransaccionSubtipo.Control23
				ELSE
					IsNull(BSOperacionItem.CantidadWorkflow,0) * IsNull(BSOperacionItem.Precio,0)
				END,

		'Gravado' = Case When BSOperacionItem.Tipo = @ITEM_TIPO_PRODUCTO
					Then Case When @DimensionID = 0 Then 		-- Mon Transaccion 
							IsNull(BSOperacionItem.ImporteGravado,0) * FAFTransaccionSubtipo.Control23
						Else 
							Abs(IsNull(BSTransaccionDimension.Porcentaje,100)*IsNull(BSOperacionItem.ImporteGravado,0)/100) * FAFTransaccionSubtipo.Control23
						End
					Else 0
					End,

		'No Gravado' = Case When BSOperacionItem.Tipo = @ITEM_TIPO_PRODUCTO
						Then CASE WHEN IsNull(BSOperacionItem.Importe,0) <> 0 THEN
								Case When @DimensionID = 0 Then 		-- Mon Transaccion 
									(IsNull(BSOperacionItem.Importe,0) - IsNull(BSOperacionItem.ImporteGravado,0)) * FAFTransaccionSubtipo.Control23
								Else 
									Abs(IsNull(BSTransaccionDimension.ImporteMonTransaccion,BSOperacionItem.Importe) - IsNull(BSTransaccionDimension.Porcentaje,100)*IsNull(BSOperacionItem.ImporteGravado,0)/100) * FAFTransaccionSubtipo.Control23
								End
							ELSE
								IsNull(BSOperacionItem.CantidadWorkflow,0) * IsNull(BSOperacionItem.Precio,0) - IsNull(BSOperacionItem.ImporteGravado,0)
							END
						Else 0
						End,
 
		'Proveedor' = BSOrganizacion.nombre, 
		'Partida' = isnull(BSPartida.numero, ''), 
		'Estado'= BSEstado.Nombre, 
    'CodigoProd' = BSProducto.Codigo,
		--GUARDA CON ESTO QUE ESTA PUESTO AL REVES A PROPOSITO 
		'PendienteOrigen' = BSOperacionItem.CantidadDisponibleDestino, 
		'PendienteDestino' = BSOperacionItem.CantidadDisponibleOrigen, 
 		'ImportePendienteOrigen' = dbo.getImporteFromCantidadPrecio(BSOperacionItem.CantidadDisponibleDestino, BSOperacionItem.Precio) * Case when IsNULL(aplicaanticipofinanciero,0) <> 0 then (100 - PorcentajeAnticipoFinanciero) /100 ELSE 1 END, 
		'ImportePendienteDestino' = dbo.getImporteFromCantidadPrecio(BSOperacionItem.CantidadDisponibleOrigen, BSOperacionItem.Precio)  * Case when IsNULL(aplicaanticipofinanciero,0) <> 0 then (100 - PorcentajeAnticipoFinanciero) /100 ELSE 1 END, 
		'Organizacion' = OrganizacionItem.Nombre, 
		'Cuenta' = BSCuenta.Nombre, 
		'Empresa' = FAFEmpresa.Nombre, 
		'Ano' = dbo.getFechaAno(BSTransaccion.Fecha), 
		'Ano-Mes' = dbo.getFechaAnoMes(BSTransaccion.Fecha), 
		ProductoRama1 = SeleccionProducto.NodoNivel1, 
		ProductoRama2 = SeleccionProducto.NodoNivel2, 
		ProductoRama3 = SeleccionProducto.NodoNivel3, 
		ProductoRamaN = SeleccionProducto.NodoNivelN,
		'PorcentajeImpositivo' = BSOperacionItem.PorcentajeTasaImpositiva,
		'ControlImpositivo3' = case BSproducto.ControlImpositivo3	/*replicar valores de OrganizacionBackend.java*/
									when 0 then ''
									when 1 then 'Bienes'
									when 2 then 'Bienes de uso'
									when 3 then 'Locaciones'
									when 4 then 'Otros'
									when 5 then 'Servicios'
								end,
		'GravadoPorTasaImpositiva' = CAST(round((Case When BSOperacionItem.Tipo = @ITEM_TIPO_PRODUCTO
					Then Case When @DimensionID = 0 Then 		-- Mon Transaccion 
							IsNull(BSOperacionItem.ImporteGravado,0) * FAFTransaccionSubtipo.Control23
						Else 
							Abs(IsNull(BSTransaccionDimension.Porcentaje,100)*IsNull(BSOperacionItem.ImporteGravado,0)/100) * FAFTransaccionSubtipo.Control23
						End
					Else 0
					End)*(BSOperacionItem.PorcentajeTasaImpositiva/100),2) as decimal(15,2)),
		'@@ClaseVO' = IsNull(FAFTransaccionSubTipo.ClaseVO, IsNull(FAFTransaccionTipo.ClaseVOTransaccion, '')),
		'FechaProximoPaso' = BSOperacionItem.FechaProximoPaso,
		'SemanaCargaDesde' = isNull(BSOperacion.SemanaCarga,0),
		'SemanaCargaHasta' = isNull(BSOperacion.SemanaCargaHasta,0),
		'ProvinciaDestino' = ISNULL(ProvinciaDestino.Nombre,''),
		'ProvinciaOrigen' = ISNULL(ProvinciaOrigen.Nombre,''),
 		'Coordenadas' = dbo.getCoordenadasForMapa(4,BSOrganizacion.OrganizacionID),
		'Corredor' = OrgCorredor.Nombre,
		'CodigoCliente' = BSOrganizacion.Codigo,
		'Sucursal' = BSSucursal.Nombre,
		'CAI/CAE' = BSOperacion.CAINumero,
		'Nivel1Dimension' = SeleccionDimension.NodoNivel1, 
		'Nivel2Dimension' = SeleccionDimension.NodoNivel2, 
		'Nivel1Cliente' = SeleccionOrganizacion.NodoNivel1, 
		'Nivel2Cliente' = SeleccionOrganizacion.NodoNivel2,
		'clienteID' = BSOrganizacion.OrganizacionID,
	  'workFlowID' = BSOperacion.WorkflowID,
		'RemitoEstado' = BSOperacion.USR_estado


	FROM  
		BSTransaccion 
		INNER JOIN FAFTransaccionTipo ON BSTransaccion.TransaccionTipoID=FAFTransaccionTipo.TransaccionTipoID 
		INNER JOIN FAFTransaccionSubtipo ON BSTransaccion.TransaccionSubtipoID = FAFTransaccionSubtipo.TransaccionSubtipoID 
		INNER JOIN BSOperacion ON BSTransaccion.TransaccionID = BSOperacion.TransaccionID 
		INNER JOIN BSEstado ON BSTransaccion.EstadoID=BSEstado.EstadoID 
		INNER JOIN BSOperacionItem ON BSOperacion.TransaccionID = BSOperacionItem.TransaccionID 
		INNER JOIN FAFEmpresa ON BSTransaccion.EmpresaID = FAFEmpresa.EmpresaID 
		LEFT Join FAFArbolSeleccion AS SeleccionProducto ON SeleccionProducto.ReportCode = @@ProductoReportCode AND  BSOperacionItem.ProductoID = SeleccionProducto.ID 
		LEFT Join FAFArbolSeleccion AS SeleccionOrganizacion ON 	SeleccionOrganizacion.ReportCode = @@ClienteReportCode AND  BSOperacion.OrganizacionID = SeleccionOrganizacion.ID


		
	/*	INNER Join FAFArbolSeleccion AS SeleccionCircuitoContable ON ( 
				SeleccionCircuitoContable.ReportCode = @@CircuitoContableReportCode AND (SeleccionCircuitoContable.ID = 0 OR BSCircuitoContable.CircuitoContableID = SeleccionCircuitoContable.ID)) 
		INNER Join FAFArbolSeleccion AS SeleccionCliente ON ( 
				SeleccionCliente.ReportCode = @@ClienteReportCode AND (SeleccionCliente.ID = 0 OR BSOperacion.OrganizacionID = SeleccionCliente.ID)) 
		INNER Join FAFArbolSeleccion AS SeleccionMoneda ON ( 
				SeleccionMoneda.ReportCode = @@MonedaReportCode AND (SeleccionMoneda.ID = 0 OR BStransaccion.MonedaID = SeleccionMoneda.ID)) 
		INNER Join FAFArbolSeleccion AS SeleccionDocumentoTipo ON ( 
				SeleccionDocumentoTipo.ReportCode = @@DocumentoTipoReportCode AND (SeleccionDocumentoTipo.ID = 0 OR faftransaccionsubtipo.TransaccionSubtipoID = SeleccionDocumentoTipo.ID)) 
		INNER Join FAFArbolSeleccion AS SeleccionEmpresa ON (SeleccionEmpresa.ReportCode = @@EmpresaReportCode AND (SeleccionEmpresa.ID = 0 OR BSTransaccion.EmpresaID = SeleccionEmpresa.ID)) 
 
	*/	 
		
		LEFT JOIN BSAsientoItem ON (BSOperacionItem.TransaccionID = BSAsientoItem.TransaccionID AND BSOperacionItem.OperacionItemID = BSAsientoItem.ItemID) 
		LEFT JOIN BSCuenta ON BSAsientoItem.CuentaID = BSCuenta.CuentaID	 
		LEFT JOIN BSProducto ON BSOperacionItem.ProductoID = BSProducto.ProductoID 
		LEFT JOIN BSMarca ON BSMarca.MarcaID=BSproducto.MarcaID
		LEFT JOIN BSCondicionPago ON BSOperacion.CondicionPagoID = BSCondicionPago.CondicionPagoID 
		LEFT JOIN BSListaPrecio ON BSOperacion.ListaPrecioID = BSListaPrecio.ListaPrecioID 
		LEFT JOIN BSPersona ON BSOperacion.PersonaIDVendedor = BSPersona.PersonaID 
		LEFT JOIN BSMoneda ON BSOperacion.MonedaID = BSMoneda.MonedaID 
		LEFT JOIN BSOrganizacion ON BSOperacion.OrganizacionID = BSOrganizacion.OrganizacionID
		LEFT JOIN BSOrganizacion OrgCorredor on BSoperacion.OrganizacionIDIntermediario  = OrgCorredor.OrganizacionID
		LEFT JOIN BSTransaccionCotizacion ON (BSTransaccionCotizacion.TransaccionID = BSOperacion.TransaccionID AND
											  BSTransaccionCotizacion.MonedaID = BSOperacion.MonedaID)
				
		LEFT JOIN BSOrganizacion OrganizacionItem ON BSOperacionItem.OrganizacionID = OrganizacionItem.OrganizacionID 
		LEFT JOIN BSDeposito DepositoOrigen ON BSOperacionItem.DepositoIDOrigen = DepositoOrigen.DepositoID 
		LEFT JOIN BSDeposito DepositoDestino ON BSOperacionItem.DepositoIDDestino = DepositoDestino.DepositoID 
		LEFT JOIN BSUnidad Unidad1 ON BSProducto.UnidadIDStock1 = Unidad1.UnidadID 
		LEFT JOIN BSUnidad Unidad2 ON BSProducto.UnidadIDStock2 = Unidad2.UnidadID 
		LEFT JOIN BSUnidad as UnidadVenta on UnidadVenta.UnidadID=BSProducto.UnidadIDVenta 
		LEFT JOIN BSUnidad as UnidadCompra on UnidadCompra.UnidadID=BSProducto.UnidadIDCompra 
		LEFT JOIN BSUnidad as UnidadStock on UnidadStock.UnidadID=BSProducto.UnidadIDStock1 
		LEFT JOIN BSUnidad as UnidadStock2 on UnidadStock2.UnidadID=BSProducto.UnidadIDStock2
		LEFT JOIN BSConcepto On (BSOperacionItem.ConceptoID = BSConcepto.ConceptoID)
		LEFT JOIN BSSucursal on BSSucursal.SucursalID=BSOperacion.SucursalID
		
		left join BSPartida on BSOperacionItem.PartidaID=BSPartida.PartidaID 
		Left Join BSTransaccionDimension On(BSOperacionItem.TransaccionID = BSTransaccionDimension.TransaccionID  
							AND BSOperacionItem.OperacionItemID = BSTransaccionDimension.ItemID  
							AND @DimensionID = BSTransaccionDimension.DimensionID) 
		Left Join BSDimension On(BSTransaccionDimension.DimensionID = BSDimension.DimensionID AND BSDimension.DimensionID = @DimensionID)  
		Left Join BSDimensionSeleccion On(BSTransaccionDimension.RegistroID = BSDimensionSeleccion.RegistroID And BSTransaccionDimension.DimensionID = BSDimensionSeleccion.DimensionID)  
		Left Join BSProvincia as ProvinciaDestino on (BSOperacion.ProvinciaIDDestino = ProvinciaDestino.ProvinciaID)
		Left Join BSProvincia as ProvinciaOrigen on (ProvinciaOrigen.ProvinciaID = BSOperacion.ProvinciaIDOrigen)
		
		Inner Join FAFArbolSeleccion As SeleccionDimension On  
				(SeleccionDimension.ReportCode = @@DimensionValor And  
				(SeleccionDimension.ID = 0 Or (BSDimensionSeleccion.RegistroID = SeleccionDimension.ID AND BSDimensionSeleccion.DimensionID = @DimensionID))) 
		
				
				
WHERE 
	  (@FiltroDocumentotipo = 1 OR  faftransaccionsubtipo.transaccionsubtipoid IN (SELECT id FROM FAFARbolSeleccion WHERE ReportCode = @@DocumentoTipoReportCode))
 AND  (@FiltroCircuitoContable = 1 OR  faftransaccionsubtipo.circuitocontableid IN (SELECT id FROM FAFARbolSeleccion WHERE ReportCode = @@CircuitoContableReportCode))
 AND  (@FiltroCliente = 1 OR  bsOperacion.organizacionid IN (SELECT id FROM FAFARbolSeleccion WHERE ReportCode = @@ClienteReportCode))
 AND  (@FiltroProducto = 1 OR  bsoperacionitem.productoid IN (SELECT id FROM FAFARbolSeleccion WHERE ReportCode = @@ProductoReportCode))
 AND  (@FiltroMoneda = 1 OR  bstransaccion.Monedaid IN (SELECT id FROM FAFARbolSeleccion WHERE ReportCode = @@MonedaReportCode))
 AND  (@FiltroEmpresa = 1 OR  bstransaccion.empresaid IN (SELECT id FROM FAFARbolSeleccion WHERE ReportCode = @@EmpresaReportCode))
 AND
	CASE WHEN (ISNULL(@@Tipo,-1) = -1)  
		THEN -1  
		ELSE FAFTransaccionSubtipo.Control0 END = ISNULL(@@Tipo,-1) 
	-- Todas las categorias de BSuite o una categoria específica 
	and ((@@categoriaID = 0 AND FAFTransaccionSubtipo.TransaccionCategoriaID < 0 AND FAFTransaccionSubtipo.TransaccionCategoriaID > -100) OR FAFTransaccionSubtipo.TransaccionCategoriaID IN (SELECT TransaccionCategoriaID FROM #TMPCategorias)) 

	and (BSOperacionItem.tipo = @ITEM_TIPO_PRODUCTO
		Or ((BSOperacionItem.tipo = @ITEM_TIPO_CONCEPTO) And (IsNull(BSOperacionItem.Importe,0) <> 0) and @@IncluirConceptosCalculados = 1))
	and (BSTransaccion.Fecha >= @@fechaDesde or @@fechaDesde=0 or @@fechaDesde is null) 
	and (BSTransaccion.Fecha < dateadd(d, 1, @@fechaHasta) or isnull(@@fechaHasta, 0)=0)
	and BSOperacion.USR_estado <> 'Recibido'
	
	 
	AND (@@verPendientes = 0 
		OR 
		(@verPendientesOrigen = 1 AND @verPendientesDestino = 1 AND (IsNull(BSOperacionItem.CantidadDisponibleOrigen, 0) > 0 OR	IsNull(BSOperacionItem.CantidadDisponibleDestino, 0) > 0)) 
		OR 
		((@verPendientesOrigen = 1 AND IsNull(BSOperacionItem.CantidadDisponibleDestino, 0) > 0))-- OR @verPendientesOrigen = 0) 
		OR 
		((@verPendientesDestino = 1 AND IsNull(BSOperacionItem.CantidadDisponibleOrigen, 0) > 0))-- OR @verPendientesDestino = 0) 
		
	) 
	 
	order by 
		BSTransaccion.Fecha, 
		BSTransaccion.Nombre, 
		FAFTransaccionSubTipo.nombre,
		BSOperacionItem.Tipo
 
END 

GO
