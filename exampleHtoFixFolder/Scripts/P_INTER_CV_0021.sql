--UTF-8 ñ
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[P_inter_CV_0021]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
  drop procedure [dbo].[P_inter_CV_0021]
GO

/*
COMPOSICION DE SALDOS

Fecha : 25/02/2008
Autor : Eduardo Paoletta

Insert Into FAFArbolSeleccion(ID, ReportCode) Values(0, 561841516) -- OrganizacionReportCode
Insert Into FAFArbolSeleccion(ID, ReportCode) Values(0, 123298456) -- CircuitoContableReportCode
Insert Into FAFArbolSeleccion(Id, ReportCode) Values(0, 485663973) -- Cuenta
Insert Into FAFArbolSeleccion(ID, ReportCode) Values(0, 151651991) -- MonedaReportCode
Insert Into FAFArbolSeleccion(ID, ReportCode) Values(0, 151651651) -- EmpresaReportCode
Exec P_BS_CV_0020 '20190101', 561841516, 123298456, 485663973, 999999, 0, 1, 1, 1, 151651651,0,0
Delete From FAFArbolSeleccion
*/

CREATE PROCEDURE P_inter_CV_0021(
  @@Fecha DateTime,
  @@OrganizacionReportCode Int,
  @@CircuitoContableReportCode Int,
  @@CuentaReportCode Int,
  @@DimensionID Int,
  @@DimensionValor Int,
  @@IncluirClientes Int,
  @@IncluirProveedores Int,
  @@MonedaTransaccion Int,
  @@EmpresaReportCode Int,
  @@SoloCtaCte Int = 0,
  @@DocumentoReportCode Int,
  @@IncluirChequesTercero bit,
  @@IncluirChequesPropios bit

--  @@VendedorID int
     )


AS
  BEGIN
    SET NOCOUNT ON

    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    DECLARE @Debe int
    DECLARE @Haber int
    DECLARE @DimensionID INT
    Declare @RegistroID Int
    Declare @TIPO_OPERACION int
    Declare @TIPO_OPERACION_TESORERIA int
    Declare @MonedaPPal int
    Declare @MonedaTran int
    Declare @MonedaSec int

    DECLARE  @ESTADO_ENCARTERA  INT = -2
    DECLARE  @ESTADO_ENCUSTODIA INT  = 6


    Set @TIPO_OPERACION = 1
    Set @TIPO_OPERACION_TESORERIA = 9
    SET @Debe = 1
    SET @Haber = -1
    SET @DimensionID = ISNULL(@@DimensionID, 0)
    Set @RegistroID = IsNull(@@DimensionValor, 0)
    Set @MonedaPPal = 1
    Set @MonedaTran = 0
    Set @MonedaSec = dbo.getMonedaSecundaria();

    -- creo la tabla final que la da origen al informe
    CREATE TABLE #FINALTMP (
      FINALTMPID int,
      AsientoItemID int,
      Fecha DateTime,
      FechaComprobante DateTime,
      FechaVto DateTime,
      DocumentoID Int,
      OrganizacionID Int,
      OrganizacionCodigo VarChar(100),
      CUIT varchar (50),
      CuentaID Int,
      Empresa varchar(255),
      Descripcion VarChar(8000),
      MonedaIDTransaccion Int,
      ImporteMonedaPpal Money,
      ImporteMonedaTransaccion Money,
      --ImporteMonedaSecundaria Money,
      Dimension varchar(255),
      DimensionValor varchar(255),
      TransaccionID int,
      Vencimiento VarChar(50),
      Documento VarChar(255),
      Comprobante VarChar(255),
      Organizacion VarChar(255),
      Cuenta VarChar(255),
      DiasMora int,
      DebeHaber int,
      CotizacionMonTransaccion Money,
      CotizacionMonSecundaria Money,
      VendedorID int


    )

    DECLARE @DECIMALES_IMPORTE int;
    SET @DECIMALES_IMPORTE = dbo.getDecimalesImporte();

    DECLARE @CodIdioma VarChar(2)
    SELECT 	@CodIdioma = dbo.getIdioma()

    DECLARE @TEXTO_A_VENCER VarChar(50)
    DECLARE @TEXTO_A_VENCER_0_1_MES VarChar(50)
    DECLARE @TEXTO_A_VENCER_1_2_MESES VarChar(50)
    DECLARE @TEXTO_A_VENCER_2_3_MESES VarChar(50)
    DECLARE @TEXTO_A_VENCER_3_6_MESES VarChar(50)
    DECLARE @TEXTO_A_VENCER_MAS_6_MESES VarChar(50)

    DECLARE @TEXTO_VENCIDO_0_1_MES VarChar(50)
    DECLARE @TEXTO_VENCIDO_1_2_MESES VarChar(50)
    DECLARE @TEXTO_VENCIDO_2_3_MESES VarChar(50)
    DECLARE @TEXTO_VENCIDO_3_6_MESES VarChar(50)
    DECLARE @TEXTO_VENCIDO_MAS_6_MESES VarChar(50)

    SELECT @TEXTO_A_VENCER = dbo.getTexto('A vencer', @CodIdioma)

    SELECT @TEXTO_A_VENCER_0_1_MES = dbo.getTexto('A vencer 0 a 1 mes', @CodIdioma)
    SELECT @TEXTO_A_VENCER_1_2_MESES = dbo.getTexto('A vencer 1 a 2 meses', @CodIdioma)
    SELECT @TEXTO_A_VENCER_2_3_MESES = dbo.getTexto('A vencer 2 a 3 meses', @CodIdioma)
    SELECT @TEXTO_A_VENCER_3_6_MESES = dbo.getTexto('A vencer 3 a 6 meses', @CodIdioma)
    SELECT @TEXTO_A_VENCER_MAS_6_MESES = dbo.getTexto('A vencer más de 6 meses', @CodIdioma)


    SELECT @TEXTO_VENCIDO_0_1_MES = dbo.getTexto('Vencido 0 a 1 mes', @CodIdioma)
    SELECT @TEXTO_VENCIDO_1_2_MESES = dbo.getTexto('Vencido 1 a 2 meses', @CodIdioma)
    SELECT @TEXTO_VENCIDO_2_3_MESES = dbo.getTexto('Vencido 2 a 3 meses', @CodIdioma)
    SELECT @TEXTO_VENCIDO_3_6_MESES = dbo.getTexto('Vencido 3 a 6 meses', @CodIdioma)
    SELECT @TEXTO_VENCIDO_MAS_6_MESES = dbo.getTexto('Vencido más de 6 meses', @CodIdioma)


    /*
    *******************************
    ***     LOS MOVIMIENTOS     ***
    *******************************
    */




/*

    if (isnull(@@VendedorID,0) <> 0 )
    BEGIN
      Select
        OrganizacionID

      into #OrganizacionForVendedorID from BSOrganizacion where VendedorID = @@VendedorID


      delete from FAFArbolSeleccion where reportcode = @@OrganizacionReportCode


      INSERT into FAFArbolSeleccion (reportcode,ID)
        Select @@OrganizacionReportCode ,OrganizacionID from #OrganizacionForVendedorID



    END

*/




    IF @@Fecha >= convert(Date,GETDATE())
      BEGIN
        print 'hoy'
        Insert
        Into #FINALTMP
          Select
            0,
            BSAsientoItem.AsientoItemID,
            BSAsientoItem.Fecha,
            ISNULL(BSTransaccion.FechaComprobante, BSAsientoItem.Fecha),
            BSAsientoItem.FechaVto,
            BSTransaccion.TransaccionID,
            BSOrganizacion.OrganizacionID,
            BSOrganizacion.Codigo,
            BSOrganizacion.CUIT,
            BSCuenta.CuentaID,
            Empresa.Nombre as Empresa,
            IsNull(BSTransaccion.Descripcion, ''),
            BSAsientoItem.MonedaIDTransaccion,
            --Moneda Principal
            ROUND(Case When @DimensionID = 0 Then
              --(IsNull(BSAsientoItem.ImporteMonPrincipal, 0) * BSAsientoItem.DebeHaber) - (IsNull(dbo.getCanceladoAsientoItemFecha(BSAsientoItem.AsientoItemID, BSAsientoItem.DebeHaber, @@Fecha, @MonedaPPal, @@MonedaTransaccion), 0) * BSAsientoItem.DebeHaber)
              (IsNull(BSAsientoItem.ImporteMonPrincipal, 0) * BSAsientoItem.DebeHaber) - (IsNull(BSAsientoItem.ImporteCanceladoMonPrincipal , 0) * BSAsientoItem.DebeHaber)
                  Else
                    case when IsNull(BSTransaccionDimension.ImporteMonPrincipal, 0) = 0  then
                      (IsNull(BSAsientoItem.ImporteMonPrincipal, 0) * BSAsientoItem.DebeHaber) -(IsNull(dbo.getCanceladoAsientoItemFecha(BSAsientoItem.AsientoItemID, BSAsientoItem.DebeHaber, @@Fecha, @MonedaPPal, @@MonedaTransaccion), 0) * BSAsientoItem.DebeHaber)
                    else
                      (IsNull(BSTransaccionDimension.ImporteMonPrincipal, 0) * BSAsientoItem.DebeHaber) - ((IsNull(dbo.getCanceladoAsientoItemFecha(BSAsientoItem.AsientoItemID, BSAsientoItem.DebeHaber, @@Fecha, @MonedaTran, @@MonedaTransaccion), 0) * BSAsientoItem.DebeHaber) * BSTransaccionDimension.Porcentaje)/100
                    end
                  End,@DECIMALES_IMPORTE),
            --Moneda Transaccion
            ROUND(Case When @DimensionID = 0 Then
              (IsNull(BSAsientoItem.ImporteMonTransaccion, 0) * BSAsientoItem.DebeHaber) - (IsNull(BSAsientoItem.ImporteCanceladoMonTransaccion , 0) * BSAsientoItem.DebeHaber)
                  Else
                    case when IsNull(BSTransaccionDimension.ImporteMonTransaccion, 0) = 0 then
                      (IsNull(BSAsientoItem.ImporteMonTransaccion, 0) * BSAsientoItem.DebeHaber) - (IsNull(dbo.getCanceladoAsientoItemFecha(BSAsientoItem.AsientoItemID, BSAsientoItem.DebeHaber, @@Fecha, @MonedaTran, @@MonedaTransaccion), 0) * BSAsientoItem.DebeHaber)
                    else
                      (IsNull(BSTransaccionDimension.ImporteMonTransaccion, 0) * BSAsientoItem.DebeHaber) - ((IsNull(dbo.getCanceladoAsientoItemFecha(BSAsientoItem.AsientoItemID, BSAsientoItem.DebeHaber, @@Fecha, @MonedaTran, @@MonedaTransaccion), 0) * BSAsientoItem.DebeHaber) * BSTransaccionDimension.Porcentaje)/100
                    end
                  End,@DECIMALES_IMPORTE),




            IsNull(BSDimension.Nombre, ''),
            IsNull(BSDimensionSeleccion.Nombre, ''),
            BSTransaccion.TransaccionID,
            '',
            BSTransaccion.Nombre,
            BSTransaccion.NumeroDocumento,
            BSOrganizacion.Nombre,
            BSCuenta.Nombre ,
            DiasMora = 0,
            DebeHaber = BSAsientoItem.DebeHaber,
            CotizacionMonTransaccion = BSTransaccionCotizacion.Cotizacion,
            CotizacionMonSecundaria = ISNULL(CotMonSec.Cotizacion,0),
            0
          /*   OrganizacionRama1 = SeleccionOrganizacion.NodoNivel1,
             OrganizacionRama2 = SeleccionOrganizacion.NodoNivel2,
             OrganizacionRama3 = SeleccionOrganizacion.NodoNivel3

             */

          From
            BSAsientoItem
            Inner Join BSOrganizacion On BSAsientoItem.OrganizacionID = BSOrganizacion.OrganizacionID
            Inner Join BSCuenta On BSAsientoItem.CuentaID = BSCuenta.CuentaID
            Inner Join BsTransaccion On BsAsientoItem.TransaccionID = BsTransaccion.TransaccionID
            Inner Join FAFTransaccionSubtipo On BsTransaccion.TransaccionSubtipoID = FAFTransaccionSubtipo.TransaccionSubtipoID
            Inner Join BSTransaccionCotizacion On (BSTransaccionCotizacion.TransaccionID = BSTransaccion.TransaccionID
                                                   AND BSTransaccionCotizacion.MonedaID = BSAsientoItem.MonedaIDTransaccion)




            Inner Join FAFArbolSeleccion AS SeleccionCuenta ON
                                                              (SeleccionCuenta.ReportCode = @@CuentaReportCode AND
                                                               (SeleccionCuenta.ID = 0 Or BsCuenta.CuentaID = SeleccionCuenta.ID))

            Inner Join FAFArbolSeleccion AS SeleccionCircuitoContable ON
                                                                        (SeleccionCircuitoContable.ReportCode = @@CircuitoContableReportCode AND
                                                                         (SeleccionCircuitoContable.ID = 0 Or FAFTransaccionSubtipo.CircuitoContableID = SeleccionCircuitoContable.ID))

            Inner Join FAFArbolSeleccion As SeleccionOrganizacion On
                                                                    (SeleccionOrganizacion.ReportCode = @@OrganizacionReportCode And
                                                                     (SeleccionOrganizacion.ID = 0 Or BSOrganizacion.OrganizacionID = SeleccionOrganizacion.ID))

            Inner join FAFArbolSeleccion As SeleccionEmpresa On
                                                               (SeleccionEmpresa.ReportCode = @@EmpresaReportCode And
                                                                (SeleccionEmpresa.ID = 0 Or BSTransaccion.EmpresaID = SeleccionEmpresa.ID))

            Inner join FAFEmpresa As Empresa On
                                               (BSTransaccion.EmpresaID = Empresa.EmpresaID)



            Inner join FAFArbolSeleccion As SeleccionDocumento On
                                                                 (SeleccionDocumento.ReportCode = @@DocumentoReportCode And
                                                                  (SeleccionDocumento.ID = 0 Or FAFTransaccionSubtipo.TransaccionSubtipoID = SeleccionDocumento.ID))





            Left Join BSProducto On BSAsientoItem.ProductoID = BSProducto.ProductoID
            Left Join BSTransaccionDimension On BSAsientoItem.AsientoItemID = BSTransaccionDimension.AsientoItemID And @DimensionID = BSTransaccionDimension.DimensionID
            Left Join BSDimension On BSTransaccionDimension.DimensionID = BSDimension.DimensionID
            Left Join BSDimensionSeleccion On BSTransaccionDimension.RegistroID = BSDimensionSeleccion.RegistroID And BSTransaccionDimension.DimensionID = BSDimensionSeleccion.DimensionID
            Left Join BSMoneda On BSAsientoItem.MonedaIDTransaccion = BSMoneda.MonedaID
            Left Join BSTransaccionCotizacion CotMonSec On (CotMonSec.TransaccionID = BSTransaccion.TransaccionID
                                                            AND CotMonSec.MonedaID = @MonedaSec)


          Where
            (BSAsientoItem.Fecha <= @@Fecha)
            --And (round(BSAsientoItem.ImporteMonPrincipal,@DECIMALES_IMPORTE) <> round(IsNull(dbo.getCanceladoAsientoItemFecha(BSAsientoItem.AsientoItemID, BSAsientoItem.DebeHaber, @@Fecha, @MonedaPPal, @@MonedaTransaccion), 0),@DECIMALES_IMPORTE))
            And (round(BSAsientoItem.ImporteMonPrincipal,@DECIMALES_IMPORTE) <> round(IsNull(BSAsientoItem.ImporteCanceladoMonPrincipal,0),@DECIMALES_IMPORTE) )
            And (@@DimensionID = 0 Or round(BSTransaccionDimension.ImporteMonPrincipal,@DECIMALES_IMPORTE) <> 0 Or round(BSAsientoItem.ImporteMonPrincipal,@DECIMALES_IMPORTE) <> 0)
            And ((@@IncluirClientes = 1 And BSOrganizacion.EsCliente = 1) Or
                 (@@IncluirProveedores = 1 And BSOrganizacion.EsProveedor = 1))
            And (@RegistroID = 0 Or IsNull(BSTransaccionDimension.RegistroID, 0) = @RegistroID)
            AND ((@@SoloCtaCte = 0  OR (@@SoloCtaCte = 1 AND BSCuenta.ImpactaCtasCtes = 1)))
            AND (@@MonedaTransaccion = 0 OR BSAsientoItem.MonedaIDTransaccion = @@MonedaTransaccion)
      END
    ELSE
      BEGIN
        print 'Ayer'
        Insert
        Into #FINALTMP
          Select
            0,
            BSAsientoItem.AsientoItemID,
            BSAsientoItem.Fecha,
            ISNULL(BSTransaccion.FechaComprobante, BSAsientoItem.Fecha),
            BSAsientoItem.FechaVto,
            BSTransaccion.TransaccionID,
            BSOrganizacion.OrganizacionID,
              'OrganizacionCodigo' = BSOrganizacion.Codigo,
            BSOrganizacion.CUIT,
            BSCuenta.CuentaID,
              Empresa.Nombre as Empresa,
            IsNull(BSTransaccion.Descripcion, ''),
            BSAsientoItem.MonedaIDTransaccion,
            --Moneda Principal
            ROUND(Case When @DimensionID = 0 Then
              (IsNull(BSAsientoItem.ImporteMonPrincipal, 0) * BSAsientoItem.DebeHaber) - (IsNull(dbo.getCanceladoAsientoItemFecha(BSAsientoItem.AsientoItemID, BSAsientoItem.DebeHaber, @@Fecha, @MonedaPPal, @@MonedaTransaccion), 0) * BSAsientoItem.DebeHaber)
                  --(IsNull(BSAsientoItem.ImporteMonPrincipal, 0) * BSAsientoItem.DebeHaber) - (IsNull(BSAsientoItem.ImporteCanceladoMonPrincipal , 0) * BSAsientoItem.DebeHaber)
                  Else
                    case when IsNull(BSTransaccionDimension.ImporteMonPrincipal, 0) = 0  then
                      (IsNull(BSAsientoItem.ImporteMonPrincipal, 0) * BSAsientoItem.DebeHaber) -(IsNull(dbo.getCanceladoAsientoItemFecha(BSAsientoItem.AsientoItemID, BSAsientoItem.DebeHaber, @@Fecha, @MonedaPPal, @@MonedaTransaccion), 0) * BSAsientoItem.DebeHaber)
                    else
                      (IsNull(BSTransaccionDimension.ImporteMonPrincipal, 0) * BSAsientoItem.DebeHaber) - ((IsNull(dbo.getCanceladoAsientoItemFecha(BSAsientoItem.AsientoItemID, BSAsientoItem.DebeHaber, @@Fecha, @MonedaTran, @@MonedaTransaccion), 0) * BSAsientoItem.DebeHaber) * BSTransaccionDimension.Porcentaje)/100
                    end
                  End,@DECIMALES_IMPORTE),
            --Moneda Transaccion
            ROUND(Case When @DimensionID = 0 Then
              --(IsNull(BSAsientoItem.ImporteMonTransaccion, 0) * BSAsientoItem.DebeHaber) - (IsNull(BSAsientoItem.ImporteCanceladoMonTransaccion , 0) * BSAsientoItem.DebeHaber)
              (IsNull(BSAsientoItem.ImporteMonTransaccion, 0) * BSAsientoItem.DebeHaber) - (IsNull(dbo.getCanceladoAsientoItemFecha(BSAsientoItem.AsientoItemID, BSAsientoItem.DebeHaber, @@Fecha, @MonedaTran, @@MonedaTransaccion), 0) * BSAsientoItem.DebeHaber)
                  Else
                    case when IsNull(BSTransaccionDimension.ImporteMonTransaccion, 0) = 0 then
                      (IsNull(BSAsientoItem.ImporteMonTransaccion, 0) * BSAsientoItem.DebeHaber) - (IsNull(dbo.getCanceladoAsientoItemFecha(BSAsientoItem.AsientoItemID, BSAsientoItem.DebeHaber, @@Fecha, @MonedaTran, @@MonedaTransaccion), 0) * BSAsientoItem.DebeHaber)
                    else
                      (IsNull(BSTransaccionDimension.ImporteMonTransaccion, 0) * BSAsientoItem.DebeHaber) - ((IsNull(dbo.getCanceladoAsientoItemFecha(BSAsientoItem.AsientoItemID, BSAsientoItem.DebeHaber, @@Fecha, @MonedaTran, @@MonedaTransaccion), 0) * BSAsientoItem.DebeHaber) * BSTransaccionDimension.Porcentaje)/100
                    end
                  End,@DECIMALES_IMPORTE),




            IsNull(BSDimension.Nombre, ''),
            IsNull(BSDimensionSeleccion.Nombre, ''),
            BSTransaccion.TransaccionID,
            '',
            BSTransaccion.Nombre,
            BSTransaccion.NumeroDocumento,
            BSOrganizacion.Nombre,
            BSCuenta.Nombre ,
              DiasMora = 0,
              DebeHaber = BSAsientoItem.DebeHaber,
              CotizacionMonTransaccion = BSTransaccionCotizacion.Cotizacion,
              CotizacionMonSecundaria = ISNULL(CotMonSec.Cotizacion,0),
              0

          From
            BSAsientoItem
            Inner Join BSOrganizacion On BSAsientoItem.OrganizacionID = BSOrganizacion.OrganizacionID
            Inner Join BSCuenta On BSAsientoItem.CuentaID = BSCuenta.CuentaID
            Inner Join BsTransaccion On BsAsientoItem.TransaccionID = BsTransaccion.TransaccionID
            Inner Join FAFTransaccionSubtipo On BsTransaccion.TransaccionSubtipoID = FAFTransaccionSubtipo.TransaccionSubtipoID
            Inner Join BSTransaccionCotizacion On (BSTransaccionCotizacion.TransaccionID = BSTransaccion.TransaccionID
                                                   AND BSTransaccionCotizacion.MonedaID = BSAsientoItem.MonedaIDTransaccion)





            Inner Join FAFArbolSeleccion AS SeleccionCuenta ON
                                                              (SeleccionCuenta.ReportCode = @@CuentaReportCode AND
                                                               (SeleccionCuenta.ID = 0 Or BsCuenta.CuentaID = SeleccionCuenta.ID))

            Inner Join FAFArbolSeleccion AS SeleccionCircuitoContable ON
                                                                        (SeleccionCircuitoContable.ReportCode = @@CircuitoContableReportCode AND
                                                                         (SeleccionCircuitoContable.ID = 0 Or FAFTransaccionSubtipo.CircuitoContableID = SeleccionCircuitoContable.ID))

            Inner Join FAFArbolSeleccion As SeleccionOrganizacion On
                                                                    (SeleccionOrganizacion.ReportCode = @@OrganizacionReportCode And
                                                                     (SeleccionOrganizacion.ID = 0 Or BSOrganizacion.OrganizacionID = SeleccionOrganizacion.ID))

            Inner join FAFArbolSeleccion As SeleccionEmpresa On
                                                               (SeleccionEmpresa.ReportCode = @@EmpresaReportCode And
                                                                (SeleccionEmpresa.ID = 0 Or BSTransaccion.EmpresaID = SeleccionEmpresa.ID))

            Inner join FAFEmpresa As Empresa On
                                               (BSTransaccion.EmpresaID = Empresa.EmpresaID)



            Inner join FAFArbolSeleccion As SeleccionDocumento On
                                                                 (SeleccionDocumento.ReportCode = @@DocumentoReportCode And
                                                                  (SeleccionDocumento.ID = 0 Or FAFTransaccionSubtipo.TransaccionSubtipoID = SeleccionDocumento.ID))







            Left Join BSProducto On BSAsientoItem.ProductoID = BSProducto.ProductoID
            Left Join BSTransaccionDimension On BSAsientoItem.AsientoItemID = BSTransaccionDimension.AsientoItemID And @DimensionID = BSTransaccionDimension.DimensionID
            Left Join BSDimension On BSTransaccionDimension.DimensionID = BSDimension.DimensionID
            Left Join BSDimensionSeleccion On BSTransaccionDimension.RegistroID = BSDimensionSeleccion.RegistroID And BSTransaccionDimension.DimensionID = BSDimensionSeleccion.DimensionID
            Left Join BSMoneda On BSAsientoItem.MonedaIDTransaccion = BSMoneda.MonedaID
            Left Join BSTransaccionCotizacion CotMonSec On (CotMonSec.TransaccionID = BSTransaccion.TransaccionID
                                                            AND CotMonSec.MonedaID = @MonedaSec)


          Where
            (BSAsientoItem.Fecha <= @@Fecha)
            And (round(BSAsientoItem.ImporteMonPrincipal,@DECIMALES_IMPORTE) <> round(IsNull(dbo.getCanceladoAsientoItemFecha(BSAsientoItem.AsientoItemID, BSAsientoItem.DebeHaber, @@Fecha, @MonedaPPal, @@MonedaTransaccion), 0),@DECIMALES_IMPORTE))
            --And (round(BSAsientoItem.ImporteMonPrincipal,@DECIMALES_IMPORTE) <> round(IsNull(BSAsientoItem.ImporteCanceladoMonPrincipal,0),@DECIMALES_IMPORTE) )
            And (@@DimensionID = 0 Or round(BSTransaccionDimension.ImporteMonPrincipal,@DECIMALES_IMPORTE) <> 0 Or round(BSAsientoItem.ImporteMonPrincipal,@DECIMALES_IMPORTE) <> 0)
            And ((@@IncluirClientes = 1 And BSOrganizacion.EsCliente = 1) Or
                 (@@IncluirProveedores = 1 And BSOrganizacion.EsProveedor = 1))
            And (@RegistroID = 0 Or IsNull(BSTransaccionDimension.RegistroID, 0) = @RegistroID)
            AND ((@@SoloCtaCte = 0  OR (@@SoloCtaCte = 1 AND BSCuenta.ImpactaCtasCtes = 1)))
            AND (@@MonedaTransaccion = 0 OR BSAsientoItem.MonedaIDTransaccion = @@MonedaTransaccion)


      END




    /*
    *********************************
    ***     CALCULO DE SALDOS     ***
    *********************************
    */

    Declare @Dif Int


    Update 	#FINALTMP
    Set @Dif = DateDiff(Day, @@Fecha, IsNull(#FINALTMP.FechaVto, #FINALTMP.Fecha)),
      #FINALTMP.Vencimiento = Case 	When @Dif < -180 Then @TEXTO_VENCIDO_MAS_6_MESES
                              When @Dif >= -180 And @Dif < -90 Then @TEXTO_VENCIDO_3_6_MESES
                              When @Dif >= -90 And @Dif < -60 Then @TEXTO_VENCIDO_2_3_MESES
                              When @Dif >= -60 And @Dif < -30 Then @TEXTO_VENCIDO_1_2_MESES
                              When @Dif >= -30 And @Dif < 0 Then @TEXTO_VENCIDO_0_1_MES
                              When @Dif >= 0 AND @Dif <= 30 Then @TEXTO_A_VENCER_0_1_MES
                              When @Dif > 30 AND @Dif <= 60 Then @TEXTO_A_VENCER_1_2_MESES
                              When @Dif > 60 AND @Dif <= 90 Then @TEXTO_A_VENCER_2_3_MESES
                              When @Dif > 90 AND @Dif <= 180 Then @TEXTO_A_VENCER_3_6_MESES
                              When @Dif > 180 Then @TEXTO_A_VENCER_MAS_6_MESES
                              End,
      #FINALTMP.DiasMora = case when @Dif < 0 Then @Dif * -1 else 0 End
    /*
    ***************************************
    ***     DEVOLUCION DE LOS DATOS     ***
    ***************************************
    */
    /* No modificar el orden de los campos del select, en caso de ser necesario o
    de agregar/sacar algun campo, revisar el SPBSIndicadorImporteFacturasPendientes */



    create  table #chequesTMP  (
      TransaccionID int,
      Cuenta varchar(150) ,
      Banco varchar(150) ,
      Numero varchar(100),
      Tercero varchar(100),
      IdTributaria varchar(100),
      Documento varchar(150),
      FechaEmision date,
      FechaVencimiento date,
      ImporteMonTransaccion money,
      Moneda varchar(100) ,
      Empresa varchar(100) ,
      ClaseVO  varchar(150) ,
      Conciliado  VARCHAR(10),
      Ano varchar(10) ,
      AnoMes  varchar(50),
      Beneficiario varchar(250),
      DocumentoFisicoID int ,
      AsientoItemID int ,
      NumeroLote int ,
      Descripcion varchar(250),
      Estado varchar(50) ,
      CUITLibrador varchar(20)

    )


    DECLARE  @TipoCheque int = 1
    DECLARE  @EstadoChequeReportCode int = 481127893


    Insert Into FAFArbolSeleccion(ID, ReportCode)
      select BSEstado.EstadoID, @EstadoChequeReportCode from BSEstado

 --   Insert Into FAFArbolSeleccion(ID, ReportCode) Values(-2, @EstadoChequeReportCode)
  --  Insert Into FAFArbolSeleccion(ID, ReportCode) Values(6, @EstadoChequeReportCode)





    

    insert into #chequesTMP
    Exec P_BS_TE_0030 @@Fecha,@TipoCheque,@EstadoChequeReportCode,@@OrganizacionReportCode,@@CircuitoContableReportCode,
                      @@CuentaReportCode,@@EmpresaReportCode,'',null,@@Fecha,0





    Select
        '@@ClaseVO' = 	CASE when isnull(FAFTransaccionSubtipo.ClaseVO, '')<>''
        THEN FAFTransaccionSubtipo.ClaseVO
                       ELSE isnull(FAFTransaccionTipo.ClaseVOTransaccion, '')
                       END,
      #FINALTMP.FINALTMPID,
      #FINALTMP.TransaccionID,
      #FINALTMP.DocumentoID,
      #FINALTMP.AsientoItemID,
      #FINALTMP.OrganizacionID,
      #FINALTMP.OrganizacionCodigo,
      #FINALTMP.CuentaID,
      #FINALTMP.MonedaIDTransaccion,
      #FINALTMP.FechaVto,
      #FINALTMP.Fecha,
      #FINALTMP.FechaComprobante,
      #FINALTMP.Documento,
      #FINALTMP.Comprobante,
      'ComprobanteAdicional' =	CASE BSTransaccion.TransaccionTipoID
                                  WHEN @TIPO_OPERACION THEN IsNull (BSOperacion.NumeroDocumentoAdicional,'')
                                  WHEN @TIPO_OPERACION_TESORERIA THEN IsNull (BSOperacionTesoreria.NumeroDocumentoExterno,'')
                                  ELSE ''
                                  END,
      #FINALTMP.Organizacion,
      #FINALTMP.CUIT,
      #FINALTMP.Descripcion,
      #FINALTMP.Cuenta,
      #FINALTMP.Empresa,
      #FINALTMP.Dimension,
      #FINALTMP.DimensionValor,
        'ImporteMonPpal' = #FINALTMP.ImporteMonedaPpal,
        'ImporteMonSecundaria' = dbo.getCambioMonedaExtranjera(#FINALTMP.ImporteMonedaPpal,#FINALTMP.CotizacionMonSecundaria),
        'Moneda' = BSMoneda.Nombre,
      'ImporteMonTran' = #FINALTMP.ImporteMonedaTransaccion,
      #FINALTMP.Vencimiento,
      FAFTransaccionSubtipo.Codigo,
      BSTransaccion.NumeroInterno,
        'Sucursal' = CASE BSTransaccion.TransaccionTipoID
                     WHEN @TIPO_OPERACION THEN SucOperacion.Nombre
                     WHEN @TIPO_OPERACION_TESORERIA THEN SucOperacionTesoreria.Nombre
                     ELSE NULL
                     END,
        'ImporteCotfecha' = convert(money ,dbo.getImporteMonedaLocal (#FINALTMP.MonedaIDTransaccion,#FINALTMP.ImporteMonedaTransaccion,@@Fecha)),
        'DiasMora' = DiasMora ,
        Tipo = Case #FINALTMP.DebeHaber When 1 Then 'Crédito' Else 'Débito' End,
      #FINALTMP.DebeHaber,
      #FINALTMP.CotizacionMonTransaccion,




        CreditoDisponible =  USR_CREDITODIARIO.Monto,
        CreditoAsignado =  cliente.CreditoMaximo,
        NUMEROCHEQUE = '',
        FECHAVTOCHEQUE = null,
        FECHAEMISION = null,
        TIPOCHEQUE = '',
       -- Vendedor = isnull(vendedorFromClienteTesoreria.Nombre,vendedorFromClienteAsientoItem.Nombre)
       Vendedor = BSPersona.Nombre



    From
      #FINALTMP

      left join BSAsientoItem on #FINALTMP.AsientoItemID = BSAsientoItem.AsientoItemID
      Left Join BSMoneda On(#FINALTMP.MonedaIDTransaccion = BSMoneda.MonedaID)
      Left Join BSTransaccion On(#FINALTMP.TransaccionID = BSTransaccion.TransaccionID)
      Left Join FAFTransaccionSubTipo On(BSTransaccion.TransaccionSubTipoID = FAFTransaccionSubTipo.TransaccionSubTipoID)
      Left Join FAFTransaccionTipo On(FAFTransaccionSubTipo.TransaccionTipoID = FAFTransaccionTipo.TransaccionTipoID)
      Left Join BSOperacion On (#FINALTMP.TransaccionID = BSOperacion.TransaccionID)
      Left Join BSOperacionTesoreria On (#FINALTMP.TransaccionID = BSOperacionTesoreria.TransaccionID)
      Left Join BSSucursal SucOperacion On (BSOperacion.SucursalID = SucOperacion.SucursalID)
      Left Join BSSucursal SucOperacionTesoreria On (BSOperacionTesoreria.SucursalID = SucOperacionTesoreria.SucursalID)



      inner JOIN BSOrganizacion cliente on cliente.OrganizacionID = #FINALTMP.OrganizacionID

      left join BSPersona on cliente.VendedorID = BSPersona.PersonaID




    LEFT JOIN USR_CreditoDiario ON  cliente.OrganizacionID = USR_CREDITODIARIO.OrganizacionID
                                      and USR_CREDITODIARIO.fecha = convert(Date, getdate())
                                      AND  USR_CREDITODIARIO.EmpresaID = BSTransaccion.EmpresaID




    Union all

    Select
        '@@ClaseVO' = 	CASE when isnull(FAFTransaccionSubtipo.ClaseVO, '')<>''
        THEN FAFTransaccionSubtipo.ClaseVO
                       ELSE isnull(FAFTransaccionTipo.ClaseVOTransaccion, '')
                       END,
      0,
      #chequesTMP.TransaccionID,
      #chequesTMP.TransaccionID,
      #chequesTMP.AsientoItemID,
      BSOperacionTesoreria.organizacionID,
      isnull(clienteTesoreria.Codigo,clienteAsientoItem.Codigo),
      0,--#chequesTMP.Cuentaid
      BSTransaccion.MonedaID,--#FINALTMP.MonedaIDTransaccion,
      BSAsientoItem.FechaVto,
      BSTransaccion.Fecha,
      BSTransaccion.Fecha,
      #chequesTMP.Documento,
      '',
      '', -- comprobasnteadicional
      isnull(clienteTesoreria.Nombre,#chequesTMP.Tercero),--#FINALTMP.Organizacion,
      #chequesTMP.CUITLibrador, -- #FINALTMP.CUIT,
      #chequesTMP.Descripcion, -- #FINALTMP.Descripcion,
      #chequesTMP.Cuenta, -- #FINALTMP.Cuenta,
      #chequesTMP.Empresa, -- #FINALTMP.Empresa,
      '',--#chequesTMP.dime,
      '',-- #FINALTMP.DimensionValor,
        'ImporteMonPpal' = BSAsientoItem.ImporteMonPrincipal,
        'ImporteMonSecundaria' = BSAsientoItem.ImporteMonSecundaria, -- dbo.getCambioMonedaExtranjera(#FINALTMP.ImporteMonedaPpal,#FINALTMP.CotizacionMonSecundaria),
        'Moneda' = #chequesTMP.Moneda,
        'ImporteMonTran' = #chequesTMP.ImporteMonTransaccion,
      '',--#chequesTMP.FechaVencimiento,
      FAFTransaccionSubtipo.Codigo,
      BSTransaccion.NumeroInterno,
        'Sucursal' =  BSSucursal.Nombre,
        'ImporteCotfecha' =  convert(money ,dbo.getImporteMonedaLocal (BSTransaccion.MonedaID,#chequesTMP.ImporteMonTransaccion,@@Fecha)),
        'DiasMora' =  '',-- DiasMora ,
        Tipo =  Case BSAsientoItem.DebeHaber When 1 Then 'Crédito' Else 'Débito' End,
      0,--#FINALTMP.DebeHaber,
      0,--#FINALTMP.CotizacionMonTransaccion,






        CreditoDisponible =  isnull(USR_CreditoDiarioOpTesoreria.Monto,USR_CreditoDiarioAsientoGenrico.Monto),
        CreditoAsignado =  isnull(clienteTesoreria.CreditoMaximo,clienteAsientoItem.CreditoMaximo),

        NUMEROCHEQUE = #chequesTMP.Numero,
        FECHAVTOCHEQUE = #chequesTMP.FechaVencimiento,
        FECHAEMISION = #chequesTMP.FechaEmision,

      /*RECEPCHTER')
= 'RECEPCHTEROTRO'*/
        TIPOCHEQUE = case when BSOperacionBancaria.codigo = 'RECEPCHTER' then  'Propio' else 'Tercero' end,
        Vendedor = isnull(vendedorFromClienteTesoreria.Nombre, vendedorFromClienteOperacion.Nombre)






    from #chequesTMP


      INNER join BSTransaccion on #chequesTMP.TransaccionID = BSTransaccion.TransaccionID
      INNER join FAFTransaccionSubtipo on BSTransaccion.TransaccionSubtipoID = FAFTransaccionSubtipo.TransaccionSubtipoID
      INNER JOIN FAFTransaccionTipo ON BSTransaccion.TransaccionTipoID = FAFTransaccionTipo.TransaccionTipoID
      INNER join BSAsientoItem on BSAsientoItem.AsientoItemID = #chequesTMP.AsientoItemID

      INNER join BSDocumentoFisico on BSAsientoItem.DocumentoFisicoID = BSDocumentoFisico.DocumentoFisicoID
      Inner Join BSAsientoItem AsientoItemOrigenCheque on BSDocumentoFisico.TransaccionID = AsientoItemOrigenCheque.TransaccionID
                                                              And  BSDocumentoFisico.DocumentoFisicoID = AsientoItemOrigenCheque.DocumentoFisicoID


      INNER join BSOperacionBancaria on AsientoItemOrigenCheque.OperacionBancariaID = BSOperacionBancaria.OperacionBancariaID

      Left Join BSOperacionTesoreria On (BSTransaccion.TransaccionID = BSOperacionTesoreria.TransaccionID)
      Left Join BSAsiento on BSTransaccion.TransaccionID = BSAsiento.TransaccionID




      LEFT Join BSOrganizacion clienteTesoreria on BSOperacionTesoreria.OrganizacionID = clienteTesoreria.OrganizacionID
        Left Join BSPersona vendedorFromClienteTesoreria on vendedorFromClienteTesoreria.PersonaID = clienteTesoreria.VendedorID

      Left Join BSOrganizacion clienteAsientoItem on BSDocumentoFisico.OrganizacionID = clienteAsientoItem.OrganizacionID
        Left Join BSPersona vendedorFromClienteOperacion on vendedorFromClienteOperacion.PersonaID = clienteAsientoItem.VendedorID




      LEFT Join FAFArbolSeleccion As SeleccionOrganizacionTesoreria On
                                                                      (SeleccionOrganizacionTesoreria.ReportCode = @@OrganizacionReportCode And
                                                                       (SeleccionOrganizacionTesoreria.ID = 0 Or clienteTesoreria.OrganizacionID = SeleccionOrganizacionTesoreria.ID))


      LEFT Join FAFArbolSeleccion As SeleccionOrganizacionAsientoGen On
                                                                       (SeleccionOrganizacionAsientoGen.ReportCode = @@OrganizacionReportCode And
                                                                        (SeleccionOrganizacionAsientoGen.ID = 0 Or clienteAsientoItem.OrganizacionID = SeleccionOrganizacionAsientoGen.ID))


      left join BSSucursal on BSOperacionTesoreria.SucursalID = BSSucursal.SucursalID

      LEFT JOIN USR_CreditoDiario USR_CreditoDiarioOpTesoreria ON  clienteTesoreria.OrganizacionID = USR_CreditoDiarioOpTesoreria.OrganizacionID
                                                                   and USR_CreditoDiarioOpTesoreria.fecha = convert(Date, getdate())
                                                                   AND  USR_CreditoDiarioOpTesoreria.EmpresaID = BSTransaccion.EmpresaID

      LEFT JOIN USR_CreditoDiario USR_CreditoDiarioAsientoGenrico ON  clienteTesoreria.OrganizacionID = USR_CreditoDiarioAsientoGenrico.OrganizacionID
                                                                      and USR_CreditoDiarioAsientoGenrico.fecha = convert(Date, getdate())
                                                                      AND  USR_CreditoDiarioAsientoGenrico.EmpresaID = BSTransaccion.EmpresaID

    WHERE   (((@@IncluirChequesTercero = 1 and BSOperacionBancaria.Codigo = 'RECEPCHTER')
              or (@@IncluirChequesPropios = 1 And BSOperacionBancaria.Codigo = 'RECEPCHTEROTRO')) )



    Order By
      #FINALTMP.Organizacion,
      #FINALTMP.Fecha




    delete from FAFArbolSeleccion where reportcode = @EstadoChequeReportCode

  End
GO
