
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[P_INT_ST_0035]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
  drop procedure [dbo].[P_INT_ST_0035]
GO


CREATE PROCEDURE [dbo].[P_INT_ST_0035](
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

AS
  BEGIN

    CREATE TABLE #temporal (
      ProductoID Int,
      Producto varchar(255),
      ProductoCodigo varchar(100),
      DepositoID Int,
      Deposito varchar(255),
      Superficie Numeric(14,4),
      Cantidad1 numeric(20,6),
      Unidad1 varchar(255),
      Cantidad2 numeric(20,6),
      Unidad2 varchar(255),
      PuntoReposicion numeric(20,6),
      CantidadStockaReponer numeric(20,6),
      LugarID int,
      Lugar varchar(255),
      RelacionCantidades numeric(30,6),
      Carga numeric(30,6),
      Moneda varchar(100),
      Cotizacion money,
      PrecioUnidadStock1 numeric(30,6),
      PrecioUnidadStock2 numeric(30,6),
      Importe numeric(30,6),
      ProductoRama1 varchar(255),
      ProductoRama2 varchar(255),
      ProductoRama3 varchar(255),
      ProductoRamaN varchar(255),
      DepositoRama1 varchar(255),
      DepositoRama2 varchar(255),
      DepositoRama3 varchar(255),
      DepositoRamaN varchar(255),
      Partida varchar(50),
      CargaCantidad1porSuperficie numeric(30,6),
      Partida_Alta Datetime,
      Partida_Vto Datetime,
      OrganizacionID int,
      Organizacion varchar(255),
      Cuenta varchar(255),
      Tenencia money,
      Partidaid int
    )

    insert into #temporal
    EXEC P_BS_ST_0030_Congelado @@FECHA,@@ProductoReportCode,@@LugarReportCode,@@DepositoReportCode,@@SubDepositoReportCode,@@OrganizacionReportCode,@@PartidaReportCode,@@TipoStock,@@CircuitoContableReportCode,@@SoloConStock,@@SoloStockMenorReposicion,@@VerSoloDepositos,@@ProductoTipo,@@EmpresaReportCode,@@TipoPrecio,@@Turno,@@AgruparPor,@@MonedaID

    select #temporal.*,
         Marca = isnull(BSMarca.Nombre,'') ,

        'Volumen' =  convert(DECIMAL(16,4), isnull(BSProducto.Volumen,0) * isnull(#temporal.Cantidad1,0)),
        'Peso' = isnull(BSProducto.Peso,0) * isnull(#temporal.Cantidad1,0),
        'Linea ' =  isnull(USR_LineaProducto.Nombre,'') ,
        'Familia' = isnull(USR_FamiliaProducto.Nombre,''),
        'SubFamilia' = isnull(USR_SubFamiliaProducto.Nombre,''),
        'Modelo' = isnull(USR_ModeloProducto.Nombre,''),
        'CodigoProveedor' = isnull(BSProducto.USR_CodigoProveedor,'')
    from #Temporal
      left join BSProducto on (BSProducto.ProductoID = #temporal.ProductoID)
      left join BSMarca on (BSMarca.MarcaID = BSProducto.MarcaID)
      left join USR_FamiliaProducto on BSProducto.USR_Familia = USR_FamiliaProducto.FamiliaID
      left join USR_LineaProducto on BSProducto.USR_Linea =  USR_LineaProducto.LineaID
      left join USR_SubFamiliaProducto on BSProducto.USR_SubFamilia = USR_SubFamiliaProducto.SubFamiliaID
      left join USR_ModeloProducto on BSProducto.USR_Modelo = USR_ModeloProducto.ModeloID

    Drop table #temporal

  END






