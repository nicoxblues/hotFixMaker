if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[P_BS_ST_0030_Congelado]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
  drop procedure [dbo].[P_BS_ST_0030_Congelado]
GO




CREATE PROCEDURE [dbo].[P_BS_ST_0030_Congelado](
  @@FECHA DATETIME,
  @@ProductoReportCode int,
  @@LugarReportCode int,
  @@DepositoReportCode int,
  @@SubDepositoReportCode int,
  @@OrganizacionReportCode int,
  @@PartidaReportCode int,
  @@TipoStock int,  -- 0-propio / 1-de organizacion / 2 - Ambos
  @@CircuitoContableReportCode Int,
  @@SoloConStock SmallInt,
  @@SoloStockMenorReposicion SmallInt,
  @@VerSoloDepositos Int, --0-Solo Depositos / 1-Incluir subDepositos
  @@ProductoTipo Int = 0,  -- 0Todos / -1 Todos sin Hacienda / o ProductoTipoID para filtrar
  @@EmpresaReportCode Int,
  @@TipoPrecio INT,
  @@Turno	Int = 0, 	 -- 0 Indistinto / 1: Mañana / 2: Tarde
  @@AgruparPor Int = 0,
  @@MonedaID int = 0
)



  /* No modificar el orden de los campos de los select, en caso de ser necesario o
  de agregar/sacar algun campo revisar el SPBSIndicadorCantStockDebajoPtoReposicion*/


AS
  BEGIN

    SET NOCOUNT ON

    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    DECLARE @StockAmbos Int
    SELECT @StockAmbos = 2

    DECLARE @StockPropio Int
    SELECT @StockPropio = 0

    DECLARE @StockTerceros Int
    SELECT @StockTerceros = 1

    DECLARE @ProductoTipoHacienda INT
    SELECT @ProductoTipoHacienda = 5

    DECLARE @TODOS_SIN_HACIENDA INT
    SELECT @TODOS_SIN_HACIENDA = -1

    DECLARE @DEPOSITO_ANIMALES INT
    SELECT @DEPOSITO_ANIMALES = 2

    DECLARE @TURNO_MANANA INT
    DECLARE @TURNO_TARDE INT

    SELECT @TURNO_MANANA = 1
    SELECT @TURNO_TARDE = 2

    DECLARE @AgrupaDepositoPartida INT
    DECLARE @AgrupaDeposito INT

    SELECT @AgrupaDeposito = 1
    SELECT @AgrupaDepositoPartida = 0

    DECLARE @FiltroDeposito int
    DECLARE @FiltroOrganizacion int
    DECLARE @FiltroEmpresa int
    DECLARE @FiltroCircuitoContable int
    DECLARE @FiltroProducto int
    DECLARE @FiltroLugar int

    DECLARE @DECIMALES_IMPORTE int;
    SET @DECIMALES_IMPORTE = dbo.getDecimalesImporte();

    DECLARE @MonedaID_Principal INT
    SET @MonedaID_Principal = dbo.getMonedaPrincipal()

    IF (@@MonedaID IS NULL OR @@MonedaID = 0)
      SELECT @@MonedaID = @MonedaID_Principal

    SELECT @FiltroEmpresa = IsNULL(count(*),0)
    FROM FAFArbolSeleccion
    WHERE reportcode = @@EmpresaReportCode
          AND id = 0

    SELECT @FiltroCircuitoContable = IsNULL(count(*),0)
    FROM FAFArbolSeleccion
    WHERE reportcode = @@CircuitoContableReportCode
          AND id = 0

    SELECT @FiltroDeposito = IsNULL(count(*),0)
    FROM FAFArbolSeleccion
    WHERE reportcode = @@DepositoReportCode
          AND id = 0

    SELECT @FiltroProducto = IsNULL(count(*),0)
    FROM FAFArbolSeleccion
    WHERE reportcode = @@ProductoReportCode
          AND id = 0

    SELECT @FiltroOrganizacion = IsNULL(count(*),0)
    FROM FAFArbolSeleccion
    WHERE reportcode = @@OrganizacionReportCode
          AND id = 0

    SELECT @FiltroLugar = IsNULL(count(*),0)
    FROM FAFArbolSeleccion
    WHERE reportcode = @@LugarReportCode
          AND id = 0
    CREATE TABLE #TMPMoneda(
      MonedaID int,
      Cotizacion money)

    DECLARE @TIPO_MONEDA INT
    SELECT  @TIPO_MONEDA = 0

    Create Table #Stock (
      ProductoID int,
      DepositoID int,
      Cantidad1 numeric(20,6),
      Cantidad2 numeric(20,6),
      Moneda varchar(100),
      Cotizacion money,
      Importe money,
      PartidaId int,
      OrganizacionID int,
      CantidadTotalSinLote Numeric (20,6),
      CantidadRegistros int,
      Tenencia money
    )


    CREATE NONCLUSTERED INDEX [Indice_StockPD] ON [#Stock]
    (
      [ProductoID] ASC,
      [DepositoID] ASC
    )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

    CREATE NONCLUSTERED INDEX [Indice_StockP] ON [#Stock]
    (
      [ProductoID] ASC
    )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

    CREATE NONCLUSTERED INDEX [Indice_Stockd] ON [#Stock]
    (
      [DEpositoID] ASC
    )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

    CREATE NONCLUSTERED INDEX [Indice_StockPDPO] ON [#Stock]
    (
      [ProductoID] ASC,
      [DepositoID] ASC,
      [PartidaID] ASC,
      [OrganizacionID] ASC
    )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]


    CREATE NONCLUSTERED INDEX [Indice_StockPDO] ON [#Stock]
    (
      [ProductoID] ASC,
      [DepositoID] ASC,
      [OrganizacionID] ASC
    )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]


    INSERT INTO #TMPMoneda
    VALUES(@MonedaID_Principal, 1)

    INSERT INTO #TMPMoneda
      SELECT DISTINCT
        BSMonedaItem.MonedaID,
        BSMonedaItem.Cotizacion
      FROM
        BSMonedaItem
      WHERE
        BSMonedaItem.MonedaID <> @MonedaID_Principal AND
        BSMonedaItem.Fecha = (
          SELECT
            MAX(Item.Fecha)
          FROM
            BSMonedaItem AS Item
          WHERE
            Item.Fecha <= @@Fecha AND
            Item.MonedaID = BSMonedaItem.MonedaID)


    IF(@@AgruparPor =@AgrupaDeposito)
      begin
        Select
          BSMovimientoStock.ProductoID,
          BSMovimientoStock.DepositoID,
            Cantidad1 = SUM(BSMovimientoStock.Cantidad1),
            Cantidad2 = SUM(BSMovimientoStock.Cantidad2),
            Moneda = IsNull(MonedaHacienda.Nombre, MonedaProducto.Nombre),
            Cotizacion = #TMPMoneda.Cotizacion,--dbo.getCotizacion(IsNull(MonedaHacienda.MonedaID, MonedaProducto.MonedaID), @@FECHA),
            Importe =
                    CASE @@TipoPrecio WHEN 0 THEN	--Costo Standard
                      CASE @@ProductoTipo
                      WHEN @ProductoTipoHacienda THEN
                        CASE IsNull(BSAHaciendaCategoria.CotizacionTipo,0)
                        WHEN 0 THEN
                          CASE
                          WHEN @@MonedaID = @MonedaID_Principal THEN SUM(IsNull(BSMovimientoStock.Cantidad1,0)) * #TMPMoneda.Cotizacion
                          WHEN IsNull(MonedaProducto.MonedaID, BSProducto.MonedaID) = @@MonedaID THEN SUM(IsNull(BSMovimientoStock.Cantidad1,0))
                          ELSE SUM((IsNull(BSMovimientoStock.Cantidad1,0) * #TMPMoneda.Cotizacion) / #TMPMonedaDestino.cotizacion )
                          END
                        ELSE
                          CASE
                          WHEN @@MonedaID = @MonedaID_Principal THEN SUM(IsNull(BSMovimientoStock.Cantidad2,0)) * #TMPMoneda.Cotizacion
                          WHEN IsNull(MonedaProducto.MonedaID, BSProducto.MonedaID) = @@MonedaID THEN SUM(IsNull(BSMovimientoStock.Cantidad2,0))
                          ELSE SUM((IsNull(BSMovimientoStock.Cantidad2,0) * #TMPMoneda.Cotizacion) / #TMPMonedaDestino.cotizacion)
                          END
                        END

                      ELSE --Insumos
                        CASE WHEN @@MonedaID = -1 OR IsNull(MonedaProducto.MonedaID, BSProducto.MonedaID) = @@MonedaID THEN SUM(IsNull(BSMovimientoStock.Cantidad1,0) * IsNull(BSProducto.CostoStandard,0))
                        ELSE SUM((IsNull(BSMovimientoStock.Cantidad1,0) *  IsNull(BSProducto.CostoStandard,0)) * #TMPMonedaOrigen.cotizacion / #TMPMonedaDestino.cotizacion)
                        END
                      END

                    WHEN 1 THEN	--Valorizado
                      CASE @@ProductoTipo
                      WHEN @ProductoTipoHacienda
                        THEN
                          CASE IsNull(BSAHaciendaCategoria.CotizacionTipo,0) WHEN 0
                            THEN SUM(CASE WHEN IsNull(BSMovimientoStock.Cantidad1,0) > 0 THEN 1 ELSE -1 END * IsNull(BSMovimientoStockValorizado.Importe,0))
                          ELSE SUM(case WHEN IsNull(BSMovimientoStock.Cantidad2,0) > 0 THEN 1 ELSE -1 END * IsNull(BSMovimientoStockValorizado.Importe,0))
                          END

                      ELSE
                        CASE IsNull(BSProducto.UnidadValorizacion,0) WHEN 0
                          THEN SUM(CASE WHEN IsNull(BSMovimientoStock.Cantidad1,0) > 0 THEN 1 ELSE -1 END * IsNull(BSMovimientoStockValorizado.Importe,0))
                        ELSE SUM(case WHEN IsNull(BSMovimientoStock.Cantidad2,0) > 0 THEN 1 ELSE -1 END * IsNull(BSMovimientoStockValorizado.Importe,0))
                        END
                      END
                    END,
            PartidaID='',
          BSMovimientoStock.OrganizacionID,
            CantidadTotalSinLote = Convert (Numeric (20,6),0), tenencia = Convert (Numeric (20,6),0), CantidadRegistros = 0

        Into #StockPorDeposito
        From BSMovimientoStock

          --Joins para Nombres de campos
          INNER JOIN BSProducto ON BsMovimientoStock.ProductoID = BsProducto.ProductoID
          INNER JOIN BSDeposito ON BsMovimientoStock.DepositoID = BsDeposito.DepositoID
          INNER JOIN BsTransaccion ON BsMovimientoStock.TransaccionID = BsTransaccion.TransaccionID
          INNER JOIN FAFTransaccionSubTipo ON BsTransaccion.TransaccionSubTipoID = FAFTransaccionSubTipo.TransaccionSubTipoID
          INNER JOIN FAFEmpresa ON BsTransaccion.EmpresaID = FAFEmpresa.EmpresaID
          LEFT JOIN BSLugar ON BSDeposito.LugarID = BSLugar.LugarID
          LEFT JOIN BSMoneda MonedaProducto ON BSProducto.MonedaID = MonedaProducto.MonedaID
          LEFT JOIN BSAHaciendaCategoria ON BSProducto.ProductoID = BSAHaciendaCategoria.ProductoID
          LEFT JOIN BSAHaciendaCategoriaMoneda ON BSProducto.ProductoID = BSAHaciendaCategoriaMoneda.ProductoID AND BSLugar.LugarID = BSAHaciendaCategoriaMoneda.LugarID
          LEFT JOIN BSMoneda MonedaHacienda ON BSAHaciendaCategoriaMoneda.MonedaID = MonedaHacienda.MonedaID
          LEFT JOIN (BSMovimientoStockValorizado INNER JOIN BSTransaccion Valorizacion ON Valorizacion.TransaccionID = BSMovimientoStockValorizado.TransaccionID AND Valorizacion.MonedaID = CASE WHEN @@ProductoTipo = @ProductoTipoHacienda THEN @MonedaID_Principal ELSE @@MonedaID END) ON BSMovimientoStock.MovimientoStockID = BSMovimientoStockValorizado.MovimientoStockID
          LEFT JOIN #TMPMoneda ON  #TMPMoneda.MonedaID = IsNull(MonedaHacienda.MonedaID, MonedaProducto.MonedaID)
          LEFT JOIN #TMPMoneda  #TMPMonedaOrigen ON #TMPMonedaOrigen.MonedaID = IsNull(MonedaHacienda.MonedaID, MonedaProducto.MonedaID)
          LEFT JOIN #TMPMoneda  #TMPMonedaDestino ON #TMPMonedaDestino.MonedaID = @@MonedaID

        WHERE

          (BSMovimientoStock.Fecha < @@FECHA OR
           (BSMovimientoStock.Fecha = @@FECHA AND NOT (@@Turno = @TURNO_MANANA AND BSMovimientoStock.Turno = @TURNO_TARDE)))

          AND (@@PartidaReportCode = 0 OR BSMovimientoStock.PartidaID = @@PartidaReportCode)

          --Tipo de Stock
          AND (@@TipoStock = @StockAmbos
               OR (@@TipoStock = @StockPropio and BSMovimientoStock.OrganizacionID is Null)
               OR (@@TipoStock = @StockTerceros and BSMovimientoStock.OrganizacionID is not Null) )

          -- Un tipo de producto en particular		ó  Todos los prod     ó   Todos excepto los de hacienda
          AND (BSProducto.ProductoTipoID = @@ProductoTipo OR @@ProductoTipo = 0 OR BSProducto.ProductoTipoID is NULL OR (@@ProductoTipo = @TODOS_SIN_HACIENDA AND BSProducto.ProductoTipoID <> @ProductoTipoHacienda))

          AND  (@FiltroCircuitoContable = 1 OR  faftransaccionsubtipo.circuitocontableid IN (SELECT id FROM FAFARbolSeleccion WHERE ReportCode = @@CircuitoContableReportCode))
          AND  (@FiltroOrganizacion = 1 OR  bsMovimientoStock.organizacionid IN (SELECT id FROM FAFARbolSeleccion WHERE ReportCode = @@OrganizacionReportCode))
          AND  (@FiltroProducto = 1 OR  bsMovimientoStock.productoid IN (SELECT id FROM FAFARbolSeleccion WHERE ReportCode = @@ProductoReportCode))
          AND  (@FiltroDeposito = 1 OR  bsMovimientoStock.Depositoid IN (SELECT id FROM FAFARbolSeleccion WHERE ReportCode = @@DepositoReportCode))
          AND  (@FiltroLugar = 1 OR  bsLugar.Lugarid IN (SELECT id FROM FAFARbolSeleccion WHERE ReportCode = @@LugarReportCode))
          AND  (@FiltroEmpresa = 1 OR  bstransaccion.empresaid IN (SELECT id FROM FAFARbolSeleccion WHERE ReportCode = @@EmpresaReportCode))

        Group By
          BSMovimientoStock.ProductoID,
          BSMovimientoStock.DepositoID,
          BSLugar.LugarID,
          MonedaHacienda.MonedaID,
          MonedaHacienda.Nombre,
          MonedaProducto.MonedaID,
          MonedaProducto.Nombre,
          BSProducto.MonedaID,
          BSAHaciendaCategoria.CotizacionTipo,
          BSProducto.CostoStandard,
          --BSMovimientoStock.PartidaID,
          BSMovimientoStock.OrganizacionID,
          BSProducto.UnidadValorizacion,
          #TMPMoneda.Cotizacion,
          #TMPMonedaOrigen.Cotizacion,
          #TMPMonedaDestino.Cotizacion


        HAVING
          --Productos por debajo del punto de reposicion

          ((SUM(BsMovimientoStock.Cantidad1) < (SELECT PuntoReposicion FROM BsProductoDeposito WHERE BsProductoDeposito.ProductoID = BSMovimientoStock.ProductoID AND BsProductoDeposito.DepositoID = BSMovimientoStock.DepositoID) AND @@SoloStockMenorReposicion=1)
           OR (@@SoloStockMenorReposicion=0))

        IF @@TipoPrecio = 1
          BEGIN

            UPDATE #StockPorDeposito set CantidadTotalSinLote = (SELECT SUM(ABS(st2.Cantidad1)) FROM #StockPorDeposito st2 WHERE #StockPorDeposito.ProductoId = st2.productoid and #StockPorDeposito.depositoid = st2.depositoid)
            UPDATE #StockPorDeposito set CantidadRegistros = (SELECT Count(*) FROM #StockPorDeposito st2 WHERE #StockPorDeposito.ProductoId = st2.productoid and #StockPorDeposito.depositoid = st2.depositoid)

            UPDATE #StockPorDeposito set Importe = Importe +
                                                   ( IsNULL(
                                                       (SELECT SUM(IsNULL(ImporteFinal,0) - IsNULL(ImporteFinalSinTenencia,0))
                                                        FROM BSProcesoValorizacion
                                                          INNER JOIN BSProceso ON BSProcesoValorizacion.TransaccionID = BSProceso.TransaccionID
                                                          INNER JOIN BSTransaccion ON BSProceso.TransaccionID = BSTransaccion.TransaccionID
                                                          Inner Join FAFArbolSeleccion AS SeleccionEmpresa ON
                                                                                                             ( SeleccionEmpresa.ReportCode = @@EmpresaReportCode AND
                                                                                                               (SeleccionEmpresa.ID = 0 OR BSTransaccion.EmpresaID = SeleccionEmpresa.ID )
                                                                                                               )
                                                        WHERE ProductoID = #StockPorDeposito.ProductoID
                                                              AND DepositoID = #StockPorDeposito.DepositoID
                                                              AND BSTransaccion.MonedaID = CASE WHEN @@ProductoTipo = @ProductoTipoHacienda THEN @MonedaID_Principal ELSE @@MonedaID END
                                                              AND FechaHasta <= @@Fecha),0)) * CASE WHEN #StockPorDeposito.cantidadtotalsinlote <> 0 THEN (ABS(#StockPorDeposito.Cantidad1 / #StockPorDeposito.cantidadtotalsinlote)) ELSE (1.0/#StockPorDeposito.CantidadRegistros) END


            UPDATE #StockPorDeposito set Tenencia = 	 ( IsNULL(
                (SELECT SUM(IsNULL(ImporteFinal,0) - IsNULL(ImporteFinalSinTenencia,0))
                 FROM BSProcesoValorizacion
                   INNER JOIN BSProceso ON BSProcesoValorizacion.TransaccionID = BSProceso.TransaccionID
                   INNER JOIN BSTransaccion ON BSProceso.TransaccionID = BSTransaccion.TransaccionID
                   Inner Join FAFArbolSeleccion AS SeleccionEmpresa ON
                                                                      ( SeleccionEmpresa.ReportCode = @@EmpresaReportCode AND
                                                                        (SeleccionEmpresa.ID = 0 OR BSTransaccion.EmpresaID = SeleccionEmpresa.ID )
                                                                        )
                 WHERE ProductoID = #StockPorDeposito.ProductoID
                       AND DepositoID = #StockPorDeposito.DepositoID
                       AND BSTransaccion.MonedaID = CASE WHEN @@ProductoTipo = @ProductoTipoHacienda THEN @MonedaID_Principal ELSE @@MonedaID END
                       AND FechaHasta <= @@Fecha),0)) * CASE WHEN #StockPorDeposito.cantidadtotalsinlote <> 0 THEN (ABS(#StockPorDeposito.Cantidad1 / #StockPorDeposito.cantidadtotalsinlote)) ELSE (1.0/#StockPorDeposito.CantidadRegistros) END

          END

        Select 	ProductoID = #StockPorDeposito.ProductoID,
                Producto = BSProducto.Nombre,
                ProductoCodigo = BSProducto.Codigo,
                DepositoID = #StockPorDeposito.DepositoID,
                Deposito = BSDeposito.Nombre,
                Superficie = BSDeposito.Superficie,
                Cantidad1 = #StockPorDeposito.Cantidad1,
                Unidad1 = UnidadPrincipal.Nombre,
                Cantidad2 = #StockPorDeposito.Cantidad2,
                Unidad2 = UnidadSecundaria.Nombre,
                PuntoReposicion = isNull(BSProductoDeposito.PuntoReposicion, 0),
                CantidadStockaReponer = case when (isNull(BSProductoDeposito.StockMaximo, 0) > 0)
                  then
                    case when (BSProductoDeposito.StockMaximo < #StockPorDeposito.Cantidad1)  then 0
                    else (BSProductoDeposito.StockMaximo - #StockPorDeposito.Cantidad1) end
                                        else
                                          case when (isNull(BSProductoDeposito.PuntoReposicion, 0) < #StockPorDeposito.Cantidad1)  then 0
                                          else isNull(BSProductoDeposito.PuntoReposicion, 0) - #StockPorDeposito.Cantidad1 end
                                        end,
                LugarID = BSLugar.LugarID,
                Lugar = BSLugar.Nombre,
                RelacionCantidades =  CASE IsNull(#StockPorDeposito.Cantidad1,0) WHEN 0 THEN 0 ELSE #StockPorDeposito.Cantidad2 / #StockPorDeposito.Cantidad1 END,
                Carga = CASE IsNull(BSDeposito.Superficie,0) WHEN 0 THEN 0 ELSE #StockPorDeposito.Cantidad2 / BSDeposito.Superficie END,
                Moneda = #StockPorDeposito.Moneda,
                Cotizacion = #StockPorDeposito.Cotizacion,
                PrecioUnidadStock1 =  CASE WHEN IsNULL(#StockPorDeposito.Cantidad1,0) <> 0 THEN #StockPorDeposito.Importe / #StockPorDeposito.Cantidad1 ELSE 0 END,
                PrecioUnidadStock2 = CASE WHEN IsNULL(#StockPorDeposito.Cantidad2,0) <> 0 THEN #StockPorDeposito.Importe / #StockPorDeposito.Cantidad2 ELSE 0 END,

          /*le sumo el importe de tenencias*/
                Importe = Round(#StockPorDeposito.Importe,@DECIMALES_IMPORTE),

                ProductoRama1 = SeleccionProducto.NodoNivel1,
                ProductoRama2 = SeleccionProducto.NodoNivel2,
                ProductoRama3 = SeleccionProducto.NodoNivel3,
                ProductoRamaN = SeleccionProducto.NodoNivelN,
                DepositoRama1 = SeleccionDeposito.NodoNivel1,
                DepositoRama2 = SeleccionDeposito.NodoNivel2,
                DepositoRama3 = SeleccionDeposito.NodoNivel3,
                DepositoRamaN = SeleccionDeposito.NodoNivelN,
                Partida = '',
                CargaCantidad1porSuperficie = CASE IsNull(BSDeposito.Superficie,0) WHEN 0 THEN 0 ELSE #StockPorDeposito.Cantidad1 / BSDeposito.Superficie END,
                Partida_Alta = '',
                Partida_Vto = '',
          #StockPorDeposito.OrganizacionID,
                Organizacion = BSOrganizacion.Nombre,
                Cuenta = (SELECT MAX(BSCuenta.Nombre )
                          FROM BSCuenta
                            INNER JOIN BSConceptoValorizacion ON BSCuenta.CuentaID = BSConceptoValorizacion.CuentaIDDebe
                            INNER JOIN BSProductoConceptoValorizacion ON BSConceptoValorizacion.ConceptoValorizacionID = BSProductoConceptoValorizacion.ConceptoValorizacionID AND BSProductoConceptoValorizacion.ProductoID = 	 #StockPorDeposito.ProductoID
                            INNER JOIN FAFTransaccionSubTipo ON BSProductoConceptoValorizacion.ConceptoValorizacionTipoID = FAFTransaccionSubTipo.ConceptoValorizacionTipoID AND FAFTransaccionSubTipo.TransaccionTipoID IN (3, 103)
                ), Tenencia,Partidaid = 0


        From #StockPorDeposito
          INNER JOIN BSProducto ON #StockPorDeposito.ProductoID = BsProducto.ProductoID
          INNER JOIN BSDeposito ON #StockPorDeposito.DepositoID = BsDeposito.DepositoID
          LEFT JOIN BSProductoDeposito ON (BSProductoDeposito.ProductoID = BSProducto.ProductoID and BSProductoDeposito.DepositoID = BSDeposito.DepositoID)
          LEFT JOIN BSMoneda MonedaProducto ON BSProducto.MonedaID = MonedaProducto.MonedaID
          LEFT JOIN BsOrganizacion ON #StockPorDeposito.OrganizacionID = BsOrganizacion.OrganizacionID
          --LEFT JOIN BsPartida ON #StockPorDeposito.PartidaID = BsPartida.PartidaID
          --LEFT JOIN BsTransaccion BSPartidaTransaccion ON BSPartida.TransaccionID = BSPartidaTransaccion.TransaccionID
          LEFT JOIN BSUnidad UnidadPrincipal ON UnidadPrincipal.UnidadID = BSProducto.UnidadIDStock1
          LEFT JOIN BSUnidad UnidadSecundaria ON UnidadSecundaria.UnidadID = BSProducto.UnidadIDStock2
          LEFT JOIN BSLugar ON BSDeposito.LugarID = BSLugar.LugarID
          LEFT JOIN BSAHaciendaCategoria ON BSProducto.ProductoID = BSAHaciendaCategoria.ProductoID
          LEFT JOIN BSAHaciendaCategoriaMoneda ON BSProducto.ProductoID = BSAHaciendaCategoriaMoneda.ProductoID AND BSLugar.LugarID = BSAHaciendaCategoriaMoneda.LugarID
          LEFT JOIN BSMoneda MonedaHacienda ON BSAHaciendaCategoriaMoneda.MonedaID = MonedaHacienda.MonedaID
          LEFT JOIN FAFArbolSeleccion AS SeleccionProducto ON SeleccionProducto.ReportCode = @@ProductoReportCode AND #StockPorDeposito.ProductoID = SeleccionProducto.ID
          LEFT JOIN FAFArbolSeleccion AS SeleccionDeposito ON SeleccionDeposito.ReportCode = @@DepositoReportCode AND #StockPorDeposito.DepositoID = SeleccionDeposito.ID

        where ((#StockPorDeposito.Cantidad1 <> 0 or #StockPorDeposito.Cantidad2 <> 0 or
                (#StockPorDeposito.Importe <>0 and @@TipoPrecio = 1 and (#StockPorDeposito.Cantidad1 <> 0 or #StockPorDeposito.Cantidad2 <> 0)) and @@SoloConStock = 1)
               or @@SoloConStock = 0)

      end

    IF(	@@AgruparPor = @AgrupaDepositoPartida)
      begin
        Insert into #Stock
          Select
            BSMovimientoStock.ProductoID,
            BSMovimientoStock.DepositoID,
              Cantidad1 = SUM(BSMovimientoStock.Cantidad1),
              Cantidad2 = SUM(BSMovimientoStock.Cantidad2),
              Moneda = IsNull(MonedaHacienda.Nombre, MonedaProducto.Nombre),
              Cotizacion = #TMPMoneda.Cotizacion,
              Importe =
                      CASE @@TipoPrecio WHEN 0 THEN	--Costo Standard
                        CASE @@ProductoTipo
                        WHEN @ProductoTipoHacienda THEN	--Hacienda
                          CASE IsNull(BSAHaciendaCategoria.CotizacionTipo,0)
                          WHEN 0 THEN
                            CASE
                            WHEN @@MonedaID = @MonedaID_Principal THEN SUM(IsNull(BSMovimientoStock.Cantidad1,0)) * #TMPMoneda.Cotizacion
                            WHEN IsNull(MonedaProducto.MonedaID, BSProducto.MonedaID) = @@MonedaID THEN SUM(IsNull(BSMovimientoStock.Cantidad1,0))
                            ELSE SUM((IsNull(BSMovimientoStock.Cantidad1,0) * #TMPMoneda.Cotizacion) / #TMPMonedaDestino.cotizacion )
                            END
                          ELSE
                            CASE
                            WHEN @@MonedaID = @MonedaID_Principal THEN SUM(IsNull(BSMovimientoStock.Cantidad2,0)) * #TMPMoneda.Cotizacion
                            WHEN IsNull(MonedaProducto.MonedaID, BSProducto.MonedaID) = @@MonedaID THEN SUM(IsNull(BSMovimientoStock.Cantidad2,0))
                            ELSE SUM((IsNull(BSMovimientoStock.Cantidad2,0) * #TMPMoneda.Cotizacion) / #TMPMonedaDestino.cotizacion)
                            END
                          END

                        ELSE --Insumos
                          CASE WHEN @@MonedaID = -1 OR IsNull(MonedaProducto.MonedaID, BSProducto.MonedaID) = @@MonedaID THEN SUM(IsNull(BSMovimientoStock.Cantidad1,0) * IsNull(BSProducto.CostoStandard,0))
                          ELSE SUM((IsNull(BSMovimientoStock.Cantidad1,0) *  IsNull(BSProducto.CostoStandard,0)) * #TMPMonedaOrigen.cotizacion / #TMPMonedaDestino.cotizacion)

                          END

                        END

                      WHEN 1 THEN	--Valorizado
                        CASE @@ProductoTipo
                        WHEN @ProductoTipoHacienda
                          THEN
                            CASE IsNull(BSAHaciendaCategoria.CotizacionTipo,0) WHEN 0
                              THEN SUM(CASE WHEN IsNull(BSMovimientoStock.Cantidad1,0) > 0 THEN 1 ELSE -1 END * IsNull(BSMovimientoStockValorizado.Importe,0))
                            ELSE SUM(CASE WHEN IsNull(BSMovimientoStock.Cantidad2,0) > 0 THEN 1 ELSE -1 END * IsNull(BSMovimientoStockValorizado.Importe,0))
                            END

                        ELSE
                          CASE IsNull(BSProducto.UnidadValorizacion,0) WHEN 0
                            THEN SUM(CASE WHEN IsNull(BSMovimientoStock.Cantidad1,0) > 0 THEN 1 ELSE -1 END * IsNull(BSMovimientoStockValorizado.Importe,0))
                          ELSE SUM(case WHEN IsNull(BSMovimientoStock.Cantidad2,0) > 0 THEN 1 ELSE -1 END * IsNull(BSMovimientoStockValorizado.Importe,0))
                          END
                        END
                      END,


            BSMovimientoStock.PartidaID,
            BSMovimientoStock.OrganizacionID,
              CantidadTotalSinLote = Convert (Numeric (20,6),0), tenencia = Convert (Numeric (20,6),0), CantidadRegistros = 0


          From BSMovimientoStock

            --Joins para Nombres de campos
            INNER JOIN BSProducto ON BsMovimientoStock.ProductoID = BsProducto.ProductoID
            INNER JOIN BSDeposito ON BsMovimientoStock.DepositoID = BsDeposito.DepositoID
            INNER JOIN BsTransaccion ON BsMovimientoStock.TransaccionID = BsTransaccion.TransaccionID
            INNER JOIN FAFTransaccionSubTipo ON BsTransaccion.TransaccionSubTipoID = FAFTransaccionSubTipo.TransaccionSubTipoID
            INNER JOIN FAFEmpresa ON BsTransaccion.EmpresaID = FAFEmpresa.EmpresaID
            LEFT JOIN BSLugar ON BSDeposito.LugarID = BSLugar.LugarID
            LEFT JOIN BSMoneda MonedaProducto ON BSProducto.MonedaID = MonedaProducto.MonedaID
            LEFT JOIN BSAHaciendaCategoria ON BSProducto.ProductoID = BSAHaciendaCategoria.ProductoID
            LEFT JOIN BSAHaciendaCategoriaMoneda ON BSProducto.ProductoID = BSAHaciendaCategoriaMoneda.ProductoID AND BSLugar.LugarID = BSAHaciendaCategoriaMoneda.LugarID
            LEFT JOIN BSMoneda MonedaHacienda ON BSAHaciendaCategoriaMoneda.MonedaID = MonedaHacienda.MonedaID
            LEFT JOIN (BSMovimientoStockValorizado INNER JOIN BSTransaccion Valorizacion ON Valorizacion.TransaccionID = BSMovimientoStockValorizado.TransaccionID AND Valorizacion.MonedaID = CASE WHEN @@ProductoTipo = @ProductoTipoHacienda THEN @MonedaID_Principal ELSE @@MonedaID END) ON BSMovimientoStock.MovimientoStockID = BSMovimientoStockValorizado.MovimientoStockID
            LEFT JOIN #TMPMoneda ON  #TMPMoneda.MonedaID = IsNull(MonedaHacienda.MonedaID, MonedaProducto.MonedaID)
            LEFT JOIN #TMPMoneda  #TMPMonedaOrigen ON #TMPMonedaOrigen.MonedaID = IsNull(MonedaHacienda.MonedaID, MonedaProducto.MonedaID)
            LEFT JOIN #TMPMoneda  #TMPMonedaDestino ON #TMPMonedaDestino.MonedaID = @@MonedaID


          WHERE

            (BSMovimientoStock.Fecha < @@FECHA OR
             (BSMovimientoStock.Fecha = @@FECHA AND NOT (@@Turno = @TURNO_MANANA AND BSMovimientoStock.Turno = @TURNO_TARDE)))

            AND (@@PartidaReportCode = 0 OR BSMovimientoStock.PartidaID = @@PartidaReportCode)

            --Tipo de Stock
            AND (@@TipoStock = @StockAmbos
                 OR (@@TipoStock = @StockPropio and BSMovimientoStock.OrganizacionID is Null)
                 OR (@@TipoStock = @StockTerceros and BSMovimientoStock.OrganizacionID is not Null) )

            -- Un tipo de producto en particular		ó  Todos los prod     ó   Todos excepto los de hacienda
            AND (BSProducto.ProductoTipoID = @@ProductoTipo OR @@ProductoTipo = 0 OR BSProducto.ProductoTipoID is NULL OR (@@ProductoTipo = @TODOS_SIN_HACIENDA AND BSProducto.ProductoTipoID <> @ProductoTipoHacienda))

            AND  (@FiltroCircuitoContable = 1 OR  faftransaccionsubtipo.circuitocontableid IN (SELECT id FROM FAFARbolSeleccion WHERE ReportCode = @@CircuitoContableReportCode))
            AND  (@FiltroOrganizacion = 1 OR  bsMovimientoStock.organizacionid IN (SELECT id FROM FAFARbolSeleccion WHERE ReportCode = @@OrganizacionReportCode))
            AND  (@FiltroProducto = 1 OR  bsMovimientoStock.productoid IN (SELECT id FROM FAFARbolSeleccion WHERE ReportCode = @@ProductoReportCode))
            AND  (@FiltroDeposito = 1 OR  bsMovimientoStock.Depositoid IN (SELECT id FROM FAFARbolSeleccion WHERE ReportCode = @@DepositoReportCode))
            AND  (@FiltroLugar = 1 OR  bsLugar.Lugarid IN (SELECT id FROM FAFARbolSeleccion WHERE ReportCode = @@LugarReportCode))
            AND  (@FiltroEmpresa = 1 OR  bstransaccion.empresaid IN (SELECT id FROM FAFARbolSeleccion WHERE ReportCode = @@EmpresaReportCode))


          Group By
            BSMovimientoStock.ProductoID,
            BSMovimientoStock.DepositoID,
            BSLugar.LugarID,
            MonedaHacienda.MonedaID,
            MonedaHacienda.Nombre,
            MonedaProducto.MonedaID,
            MonedaProducto.Nombre,
            BSProducto.MonedaID,
            BSAHaciendaCategoria.CotizacionTipo,
            BSProducto.CostoStandard,
            BSMovimientoStock.PartidaID,
            BSMovimientoStock.OrganizacionID,
            BSProducto.UnidadValorizacion,
            #TMPMoneda.Cotizacion,
            #TMPMonedaOrigen.Cotizacion,
            #TMPMonedaDestino.Cotizacion

          HAVING
            --Productos por debajo del punto de reposicion

            ((SUM(BsMovimientoStock.Cantidad1) < (SELECT PuntoReposicion FROM BsProductoDeposito WHERE BsProductoDeposito.ProductoID = BSMovimientoStock.ProductoID AND BsProductoDeposito.DepositoID = BSMovimientoStock.DepositoID) AND @@SoloStockMenorReposicion=1)
             OR (@@SoloStockMenorReposicion=0))

        IF @@TipoPrecio = 1
          BEGIN

            UPDATE #Stock set CantidadTotalSinLote = (SELECT SUM(ABS(st2.Cantidad1)) FROM #Stock st2 WHERE #stock.ProductoId = st2.productoid and #stock.depositoid = st2.depositoid)
            UPDATE #Stock set CantidadRegistros = (SELECT Count(*) FROM #Stock st2 WHERE #stock.ProductoId = st2.productoid and #stock.depositoid = st2.depositoid)

            UPDATE #Stock set Importe = Importe +
                                        ( IsNULL(
                                            (SELECT SUM(IsNULL(ImporteFinal,0) - IsNULL(ImporteFinalSinTenencia,0))
                                             FROM BSProcesoValorizacion
                                               INNER JOIN BSProceso ON BSProcesoValorizacion.TransaccionID = BSProceso.TransaccionID
                                               INNER JOIN BSTransaccion ON BSProceso.TransaccionID = BSTransaccion.TransaccionID
                                               Inner Join FAFArbolSeleccion AS SeleccionEmpresa ON
                                                                                                  ( SeleccionEmpresa.ReportCode = @@EmpresaReportCode AND
                                                                                                    (SeleccionEmpresa.ID = 0 OR BSTransaccion.EmpresaID = SeleccionEmpresa.ID )
                                                                                                    )
                                             WHERE ProductoID = #Stock.ProductoID
                                                   AND DepositoID = #Stock.DepositoID
                                                   AND BSTransaccion.MonedaID = CASE WHEN @@ProductoTipo = @ProductoTipoHacienda THEN @MonedaID_Principal ELSE @@MonedaID END
                                                   AND FechaHasta <= @@Fecha),0)) * CASE WHEN #stock.cantidadtotalsinlote <> 0 THEN (ABS(#Stock.Cantidad1 / #stock.cantidadtotalsinlote)) ELSE (1.0/#stock.CantidadRegistros) END


            UPDATE #Stock set Tenencia = 	 ( IsNULL(
                (SELECT SUM(IsNULL(ImporteFinal,0) - IsNULL(ImporteFinalSinTenencia,0))
                 FROM BSProcesoValorizacion
                   INNER JOIN BSProceso ON BSProcesoValorizacion.TransaccionID = BSProceso.TransaccionID
                   INNER JOIN BSTransaccion ON BSProceso.TransaccionID = BSTransaccion.TransaccionID
                   Inner Join FAFArbolSeleccion AS SeleccionEmpresa ON
                                                                      ( SeleccionEmpresa.ReportCode = @@EmpresaReportCode AND
                                                                        (SeleccionEmpresa.ID = 0 OR BSTransaccion.EmpresaID = SeleccionEmpresa.ID )
                                                                        )
                 WHERE ProductoID = #Stock.ProductoID
                       AND DepositoID = #Stock.DepositoID
                       AND BSTransaccion.MonedaID = CASE WHEN @@ProductoTipo = @ProductoTipoHacienda THEN @MonedaID_Principal ELSE @@MonedaID END
                       AND FechaHasta <= @@Fecha),0)) * CASE WHEN #stock.cantidadtotalsinlote <> 0 THEN (ABS(#Stock.Cantidad1 / #stock.cantidadtotalsinlote)) ELSE (1.0/#stock.CantidadRegistros) END

          END

        Select 	ProductoID = #Stock.ProductoID,
                Producto = BSProducto.Nombre,
                ProductoCodigo = BSProducto.Codigo,
                DepositoID = #Stock.DepositoID,
                Deposito = BSDeposito.Nombre,
                Superficie = BSDeposito.Superficie,
                Cantidad1 = #Stock.Cantidad1,
                Unidad1 = UnidadPrincipal.Nombre,
                Cantidad2 = #Stock.Cantidad2,
                Unidad2 = UnidadSecundaria.Nombre,
                PuntoReposicion = isNull(BSProductoDeposito.PuntoReposicion, 0),
                CantidadStockaReponer = case when (isNull(BSProductoDeposito.StockMaximo, 0) > 0)
                  then
                    case when (BSProductoDeposito.StockMaximo < #Stock.Cantidad1)  then 0
                    else (BSProductoDeposito.StockMaximo - #Stock.Cantidad1) end
                                        else
                                          case when (isNull(BSProductoDeposito.PuntoReposicion, 0) < #Stock.Cantidad1)  then 0
                                          else isNull(BSProductoDeposito.PuntoReposicion, 0) - #Stock.Cantidad1 end
                                        end,
                LugarID = BSLugar.LugarID,
                Lugar = BSLugar.Nombre,
                RelacionCantidades =  CASE IsNull(#Stock.Cantidad1,0) WHEN 0 THEN 0 ELSE #Stock.Cantidad2 / #Stock.Cantidad1 END,
                Carga = CASE IsNull(BSDeposito.Superficie,0) WHEN 0 THEN 0 ELSE #Stock.Cantidad2 / BSDeposito.Superficie END,
                Moneda = #Stock.Moneda,
                Cotizacion = #Stock.Cotizacion,
                PrecioUnidadStock1 =  CASE WHEN IsNULL(#Stock.Cantidad1,0) <> 0 THEN #Stock.Importe / #Stock.Cantidad1 ELSE 0 END,
                PrecioUnidadStock2 = CASE WHEN IsNULL(#Stock.Cantidad2,0) <> 0 THEN #Stock.Importe / #Stock.Cantidad2 ELSE 0 END,

          /*le sumo el importe de tenencias*/
                Importe = Round(#Stock.Importe,@DECIMALES_IMPORTE),

                ProductoRama1 = SeleccionProducto.NodoNivel1,
                ProductoRama2 = SeleccionProducto.NodoNivel2,
                ProductoRama3 = SeleccionProducto.NodoNivel3,
                ProductoRamaN = SeleccionProducto.NodoNivelN,
                DepositoRama1 = SeleccionDeposito.NodoNivel1,
                DepositoRama2 = SeleccionDeposito.NodoNivel2,
                DepositoRama3 = SeleccionDeposito.NodoNivel3,
                DepositoRamaN = SeleccionDeposito.NodoNivelN,
                Partida = BSPartida.Numero,
                CargaCantidad1porSuperficie = CASE IsNull(BSDeposito.Superficie,0) WHEN 0 THEN 0 ELSE #Stock.Cantidad1 / BSDeposito.Superficie END,
                Partida_Alta = BsPartidaTransaccion.Fecha,
                Partida_Vto = BsPartida.FechaVto,
          #Stock.OrganizacionID,
                Organizacion = BSOrganizacion.Nombre,
                Cuenta = (SELECT MAX(BSCuenta.Nombre )
                          FROM BSCuenta
                            INNER JOIN BSConceptoValorizacion ON BSCuenta.CuentaID = BSConceptoValorizacion.CuentaIDDebe
                            INNER JOIN BSProductoConceptoValorizacion ON BSConceptoValorizacion.ConceptoValorizacionID = BSProductoConceptoValorizacion.ConceptoValorizacionID AND BSProductoConceptoValorizacion.ProductoID = 	 #Stock.ProductoID
                            INNER JOIN FAFTransaccionSubTipo ON BSProductoConceptoValorizacion.ConceptoValorizacionTipoID = FAFTransaccionSubTipo.ConceptoValorizacionTipoID AND FAFTransaccionSubTipo.TransaccionTipoID IN (3, 103)
                ), Tenencia,PartidaID = BSPartida.PartidaID


        From #stock
          INNER JOIN BSProducto ON #Stock.ProductoID = BsProducto.ProductoID
          INNER JOIN BSDeposito ON #Stock.DepositoID = BsDeposito.DepositoID
          LEFT JOIN BSProductoDeposito ON (BSProductoDeposito.ProductoID = BSProducto.ProductoID and BSProductoDeposito.DepositoID = BSDeposito.DepositoID)
          LEFT JOIN BSMoneda MonedaProducto ON BSProducto.MonedaID = MonedaProducto.MonedaID
          LEFT JOIN BsOrganizacion ON #Stock.OrganizacionID = BsOrganizacion.OrganizacionID
          LEFT JOIN BsPartida ON #Stock.PartidaID = BsPartida.PartidaID
          LEFT JOIN BsTransaccion BSPartidaTransaccion ON BSPartida.TransaccionID = BSPartidaTransaccion.TransaccionID
          LEFT JOIN BSUnidad UnidadPrincipal ON UnidadPrincipal.UnidadID = BSProducto.UnidadIDStock1
          LEFT JOIN BSUnidad UnidadSecundaria ON UnidadSecundaria.UnidadID = BSProducto.UnidadIDStock2
          LEFT JOIN BSLugar ON BSDeposito.LugarID = BSLugar.LugarID
          LEFT JOIN BSAHaciendaCategoria ON BSProducto.ProductoID = BSAHaciendaCategoria.ProductoID
          LEFT JOIN BSAHaciendaCategoriaMoneda ON BSProducto.ProductoID = BSAHaciendaCategoriaMoneda.ProductoID AND BSLugar.LugarID = BSAHaciendaCategoriaMoneda.LugarID
          LEFT JOIN BSMoneda MonedaHacienda ON BSAHaciendaCategoriaMoneda.MonedaID = MonedaHacienda.MonedaID
          LEFT JOIN FAFArbolSeleccion AS SeleccionProducto ON SeleccionProducto.ReportCode = @@ProductoReportCode AND #Stock.ProductoID = SeleccionProducto.ID
          LEFT JOIN FAFArbolSeleccion AS SeleccionDeposito ON SeleccionDeposito.ReportCode = @@DepositoReportCode AND #Stock.DepositoID = SeleccionDeposito.ID

        -- Tiene cantidades y me pidieron sólo con stock o me pideron todo
        where (((#Stock.Cantidad1 <> 0 or #Stock.Cantidad2 <> 0) and @@SoloConStock = 1) or @@SoloConStock = 0)

      End
    DROP TABLE #TMPMoneda
    Drop TAble #Stock
  End


GO
