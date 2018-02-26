-- ESA_Logistica '400996' SELECT * FROM BSPRODUCTO



if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ESA_Logistica]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop procedure [dbo].[ESA_Logistica]
GO

CREATE PROCEDURE ESA_Logistica(
	@@productoCode  varchar(100)
)
AS
Begin

SET NOCOUNT  OFF


DECLARE @EsaLogisticaID int
DECLARE @productoID int
DECLARE @Cantidad int
DECLARE @CantidadCaja int







	Select @productoID = productoID from BSProducto where codigo = @@productoCode

	SELECT
			@Cantidad = sum(isnull(Cantidad1,0))

	FROM 	BSMovimientoStock
		inner join FAFTablaTag on BSMovimientoStock.DepositoID = FAFTablaTag.RegistroID

	WHERE  BSMovimientoStock.ProductoID = @productoID
					AND FAFTablaTag.Tabla = 'BSDeposito' and FAFTablaTag.TagID = 'VENTA'


  /*      SELECT  @CantidadCaja = ISNULL(BSProductoCodigoBarra.Multiplicador,1)
        FROM 	BSProductoCodigoBarra
        WHERE	BSProductoCodigoBarra.ProductoID = @productoID
          AND 	UnidadIDPresentacion = 103
    */
	Select @Cantidad



END

GO
