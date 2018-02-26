
DECLARE  @DiccionarioTipoDocInter  int

if not exists(select 1 from FAFDiccionario  where Codigo ='TIPODOCASIGNADOR')
    BEGIN




      INSERT INTO FAFDiccionario
        (Nombre, Codigo, Activo, Descripcion, Tipo, DiccionarioIDPadre, NombreFisicoEntidad, NombreClase,
         OrigenDatos, SelectHelp, AliasGenerationClass, SelectGrid, Protegido, PermitirPrivados, SelectReport, TipoAlta,
         MostrarSoloRamaSeleccionada, DefinePermisos, NucleoFuncionalID, DisponibleMobile, SelectMobile,
         FechaUltimaNovedad, SelectExport, NombreEntidadMobile, EsSegment, SegmentType, GeneratesCube,
         AppItemID, ConsumerCount, SegmentConditions, SegmentConditionsContactos, CamposVisibles, DefineSeguridad,
         defaultmobilesync, TimeStampUltimaModif) VALUES ('Tipos de Documento interelec', 'TIPODOCASIGNADOR', 1, 'Tipos de Documento', 2,
                                                              null, 'FafTransaccionSubtipo', '', 'INTERELEC',
                                                              'SELECT FAFTransaccionSubtipo.TransaccionSubtipoID, FAFTransaccionSubtipo.Nombre	FROM FAFTransaccionSubtipo	WHERE (IsNull(FAFTransaccionSubtipo.Activo,0)<>0 or FAFTransaccionSubtipo.Codigo = ''RV13'' or FAFTransaccionSubtipo.codigo = ''RV04'' )	order by FAFTransaccionSubtipo.nombre',
                                                              '', 'SELECT FAFTransaccionSubtipo.TransaccionSubtipoID, FAFTransaccionSubtipo.Nombre FROM FAFTransaccionSubtipo WHERE (IsNull(FAFTransaccionSubtipo.Activo,0)<>0 or FAFTransaccionSubtipo.Codigo = ''RV13'' or FAFTransaccionSubtipo.codigo = ''RV04'' )   order by FAFTransaccionSubtipo.nombre',
                                                                  0, 0, 'SELECT FAFTransaccionSubtipo.TransaccionSubtipoID, FAFTransaccionSubtipo.Nombre FROM FAFTransaccionSubtipo WHERE (IsNull(FAFTransaccionSubtipo.Activo,0)<>0 or FAFTransaccionSubtipo.Codigo = ''RV13'' or FAFTransaccionSubtipo.codigo = ''RV04'' )   order by FAFTransaccionSubtipo.nombre',

                                                                  0, 0, 0, -10, 0, '', null, null, '', null, null, null, null, null, null, null, null, 0, 0, null);

      Select @DiccionarioTipoDocInter =  DiccionarioID from FAFDiccionario where codigo = 'TIPODOCASIGNADOR'



      INSERT INTO FAFDiccionarioCondicion (DiccionarioID, Codigo, Condicion) VALUES (@DiccionarioTipoDocInter, 'TransaccionCategoria', 'TransaccionCategoriaID in (?)');





    END

go


Update FAFTransaccionSubtipo set Activo = 0 where Codigo = 'RV13' or codigo = 'RV04'

go

