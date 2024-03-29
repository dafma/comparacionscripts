/****** Object:  StoredProcedure [dbo].[spFacturacionSemanalABC]    Script Date: 05/05/2017 16:57:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER              PROCEDURE [dbo].[spFacturacionSemanalABC]
		@Grupo		varchar(50),
		@AgenteD	char(10),
		@AgenteA	char(10),
		@Ejercicio	int,
		@Periodo	int,
		@Empresa	VArchar(10),
		@Usuario 	Char(10),
--modify 05/05/17		@Familia 	Varchar(50),
		@Sucursal	int,
		@Zona           Varchar(30) --cambiado/agregado para nuevo filtro Diciembre 2014
AS BEGIN

  DECLARE
	@PrimerDiaMes		Datetime,
	@UltimoDiaMes		Datetime,
	@IniSemana1		Datetime,
	@FinSemana1		Datetime,
	@IniSemana2		Datetime,
	@FinSemana2		Datetime,
	@IniSemana3		Datetime,
	@FinSemana3		Datetime,
	@IniSemana4		Datetime,
	@FinSemana4		Datetime,
	@IniSemana5		Datetime,
	@FinSemana5		Datetime,
	@Dias1			int,
	@Dias2			int,
	@Dias3			int,
	@Dias4			int,
	@Dias5			int,
	@GruX			varchar(50),
	@AgeX			char(10),
	@ImpX			money,
	@CuotaX			money,
	@FechaX			Datetime,
	@CuotaDia		money,
	@Categoria 		VarChar(50),
	@Mov 			char(20),
	@TFacturacion		money,
	@TDevolucion		money,
	@TAnticipo		money,
	@EmpresaT	char(10),
	@Familia 	Varchar(50)

Exec spValidaAgentesGABC
@Usuario,
@Empresa,
@Categoria OUTPUT,
@Familia OUTPUT,
@Grupo OUTPUT,
@AgenteD OUTPUT,
@AgenteA OUTPUT,
@Zona  OUTPUT --cambiado/agregado para nuevo filtro Diciembre 2014

--drop table FactCuota
----Validacion Agentes para que no puedan ver movimientos de otros agentes
   IF @Categoria='EJECUTIVO DE VENTAS'
      Begin
        Select @Empresa=Nivelacceso,@Sucursal=SucursalEmpresa From Agente Where Agente=@AgenteD
        Select @Empresa=Case @Empresa When '(LABC)'  Then 'LABC'
                                      When '(FASIQ)' Then 'FASIQ'
                                      When '(LMA)'   Then 'LMA'
                                      When '(GMTK)'  Then 'GMTK'
                                      When '(FERMI)' Then 'FERMI'
                        End
      End
----
IF Exists (Select * From SysObjects Where ID=object_ID('dbo.FactCuota') And Type='U')
Drop Table dbo.FactCuota
  
  CREATE TABLE FactCuota (
	Orden 		Int		NULL,
	Grupo		varchar(50)	NULL,
	Empresa	VArchar(10) null,
	Mov		char(20) NULL,
	Agente		char(10) NULL,
	NomAgente   varchar(100) NULL, 
	Cuota1		money		NULL,
	Importe1	money		NULL,
	FechaD1		Datetime	NULL,
	FechaA1		Datetime	NULL,
	Cuota2		money		NULL,
	Importe2	money		NULL,
	FechaD2		Datetime	NULL,
	FechaA2		Datetime	NULL,
	Cuota3		money		NULL,
	Importe3	money		NULL,
	FechaD3		Datetime	NULL,
	FechaA3		Datetime	NULL,
	Cuota4		money		NULL,
	Importe4	money		NULL,
	FechaD4		Datetime	NULL,
	FechaA4		Datetime	NULL,
	Cuota5		money		NULL,
	Importe5	money		NULL,
	FechaD5		Datetime	NULL,
	FechaA5		Datetime	NULL)

Create Table #FactSem(
Orden int Null,
Grupo varchar(50)  Null,
Mov char(20)  Null,
MovId Varchar(20) null,
Agente char(10) Collate Modern_Spanish_CI_AS Null,
Importe Money Null,
Cuota Money Null,
FechaEmision DateTime Null)

  IF @Grupo IN ('NULL', '', '0', '(Todos)') SELECT @Grupo = NULL
  IF @Ejercicio = 0 SELECT @Ejercicio = YEAR(GETDATE())
  IF @Periodo = 0 SELECT @Periodo = MONTH(GETDATE())

  IF @Empresa not in(Select Empresa From Empresa) or @Empresa in('','null','NULL')
     Begin
       Select @Empresa=null
     End
  IF @Zona not in(Select Distinct Zona From Agente) or @Zona in('','null','NULL')
     Begin
       Select @Zona=null
     End
--exec spFacturacionSemanalABC '(Todos)','ACC','ZZZZZZ',2014,11,'NULL','GVT','(Todos)',NULL,'NULL'


Insert Into #FactSem(Orden, Grupo,empresa, Mov,MovId, Agente, Importe, Cuota, FechaEmision)
  SELECT 1, ag.Grupo, a.empresa,a.Mov,a.movid, a.Agente, ((a.Importe*a.TipoCambio)-((IsNull(a.AnticiposFacturados,0)-IsNull(AnticiposImpuestos,0))*a.TipoCambio)), 
         Cuota = (SELECT Importe FROM TablaAnualD WHERE TablaAnual = a.Agente AND Ejercicio = @Ejercicio AND Periodo = @Periodo), a.FechaEmision
--    INTO #FactSem
    FROM Venta a, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     AND mt.Modulo = 'VTAS'
     AND mt.Clave = 'VTAS.F'
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     --And ag.SucursalEmpresa=IsNull(@Sucursal,ag.SucursalEmpresa)
     AND a.Estatus = 'CONCLUIDO'
/***** Lineas Para el Filtro de Agentes *****/
--     And IsNull(Ag.Categoria, '') = IsNull(IsNull(@Categoria, Ag.Categoria), '')
--modify 05/05/17     And IsNull(Ag.Familia, '') = IsNull(IsNull(@Familia, Ag.Familia), '')
     And IsNull(Ag.Grupo, '') = IsNull(IsNull(@Grupo, Ag.Grupo), '')
     And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
/***** Lineas Para el Filtro de Agentes *****/
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     AND a.Ejercicio = @Ejercicio
     AND a.Periodo = @Periodo
     AND a.Empresa = Isnull(@Empresa,a.Empresa)
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
   ORDER BY ag.Grupo, a.Agente,a.empresa
-----

-----------
-----------Inserta Las facturas canceladas en meses posteriores al de emision
Insert Into #FactSem(Orden, Grupo,empresa, Mov,MovId, Agente, Importe, Cuota, FechaEmision)
  SELECT 1, ag.Grupo,a.empresa, a.Mov,a.movid, a.Agente, 
   Importe=Case When (a.Mov in('Factura','Factura CFD') And a.estatus='CANCELADO' AND a.Ejercicio=@Ejercicio AND a.Periodo=@Periodo And MONTH(a.FechaCancelacion)>Month(a.FechaEmision) And MONTH(a.FechaCancelacion)<>@Periodo)  
           Then ((a.Importe*a.TipoCambio)-((IsNull(a.AnticiposFacturados,0)-IsNull(AnticiposImpuestos,0))*a.TipoCambio))
           Else ((a.Importe*a.TipoCambio)-((IsNull(a.AnticiposFacturados,0)-IsNull(AnticiposImpuestos,0))*a.TipoCambio))*-1 End, 
         Cuota = (SELECT Importe FROM TablaAnualD WHERE TablaAnual = a.Agente AND Ejercicio = @Ejercicio AND Periodo = @Periodo),Case When Month(a.FechaCancelacion)<>@Periodo Then a.FechaEmision Else a.FechaCancelacion End --Cast(a.FechaCancelacion as Date) End
--    INTO #FactSem
    FROM Venta a, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     AND mt.Modulo = 'VTAS'
     AND mt.Clave = 'VTAS.F'
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     And (a.Estatus='CANCELADO' AND MONTH(a.FechaCancelacion)>Month(a.FechaEmision))
/***** Lineas Para el Filtro de Agentes *****/
--     And IsNull(Ag.Categoria, '') = IsNull(IsNull(@Categoria, Ag.Categoria), '')
--modify 05/05/17     And IsNull(Ag.Familia, '') = IsNull(IsNull(@Familia, Ag.Familia), '')
     And IsNull(Ag.Grupo, '') = IsNull(IsNull(@Grupo, Ag.Grupo), '')
     And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
/***** Lineas Para el Filtro de Agentes *****/
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     AND a.Ejercicio = @Ejercicio
     AND (a.Periodo=@Periodo Or MONTH(a.FechaCancelacion)=@Periodo)
     AND a.Empresa = Isnull(@Empresa,a.Empresa)
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
   ORDER BY ag.Grupo, a.Agente,a.empresa


-----------

/*
---notas de cargo
Insert Into #FactSem(Orden, Grupo, Mov,movid, Agente, Importe, Cuota, FechaEmision)
SELECT 1, ag.Grupo, 'Factura',a.movid, a.Agente, (a.Importe*a.TipoCambio), 
(SELECT Importe FROM TablaAnualD WHERE TablaAnual = a.Agente AND Ejercicio = @Ejercicio AND Periodo = @Periodo), a.FechaEmision
    FROM Cxc a,  MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     --AND a.ID=CxcD.ID
     AND mt.Modulo = 'CXC'
     AND mt.Clave In ('CXC.CA')
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     --And ag.SucursalEmpresa=IsNull(@Sucursal,ag.SucursalEmpresa)
     AND a.Estatus In ('CONCLUIDO', 'PENDIENTE')
/***** Lineas Para el Filtro de Agentes *****/
     And IsNull(Ag.Categoria, '') = IsNull(IsNull(@Categoria, Ag.Categoria), '')
     And IsNull(Ag.Familia, '') = IsNull(IsNull(@Familia, Ag.Familia), '')
     And IsNull(Ag.Grupo, '') = IsNull(IsNull(@Grupo, Ag.Grupo), '')
/***** Lineas Para el Filtro de Agentes *****/
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     AND a.Ejercicio = @Ejercicio
     AND a.Periodo = @Periodo
     AND a.Empresa = @Empresa
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
     --AND CxcD.Aplica = 'Factura Anticipo'
   ORDER BY ag.Grupo, a.Agente

--fin notas de cargo
*/
-----insertado para que salgan los agentes aunque no tengan movimientos 23-Abril-2010
--IF @Sucursal is not null And @Sucursal<>0 and @Categoria is null  --los gerentes son los unicos que lo pdoran ver y su categoria es null
--   Begin
   IF @Categoria<>'EJECUTIVO DE VENTAS'
    Begin  
      Select @EmpresaT=Case  @Empresa When 'LABC'  Then '(LABC)'  --agregado para impedir que agregue aegentes de otra empresaa si trae filtro de empresa
                                      When 'FASIQ' Then '(FASIQ)'
                                      When 'LMA'   Then '(LMA)'
                                      When 'GMTK'  Then '(GMTK)'
                                      When 'FERMI' Then '(FERMI)'
                        End
      Insert Into #FactSem(Orden, Grupo, Mov, Agente, Importe, Cuota, FechaEmision)
      Select 1,Grupo,'Factura',Agente,0,
      Cuota = (SELECT Importe FROM TablaAnualD WHERE TablaAnual = Agente.Agente AND Ejercicio = @Ejercicio AND Periodo = @Periodo), GetDate()
      From Agente
      Where Estatus='ALTA' And Categoria='EJECUTIVO DE VENTAS' And Zona=Isnull(@Zona,Zona)
      And Not Exists(Select f.* From #FactSem f Where f.Agente=Agente.Agente)
      AND NivelAcceso=Isnull(@EmpresaT,NivelAcceso)
      And SucursalEmpresa=IsNull(@Sucursal,SucursalEmpresa)
    End  
--   End
/*
IF @Sucursal is null and @Categoria is null
   Begin
      Insert Into #FactSem(Orden, Grupo, Mov, Agente, Importe, Cuota, FechaEmision)
      Select 1,Grupo,'Factura',Agente,0,
      Cuota = (SELECT Importe FROM TablaAnualD WHERE TablaAnual = Agente.Agente AND Ejercicio = @Ejercicio AND Periodo = @Periodo), GetDate()
      From Agente
      Where Estatus='ALTA' And Categoria='EJECUTIVO DE VENTAS' 
      And Not Exists(Select f.* From #FactSem f Where f.Agente=Agente.Agente)
   End
IF @Sucursal=0 And @Empresa='FERMI' and @Categoria is null
   Begin
      Insert Into #FactSem(Orden, Grupo, Mov, Agente, Importe, Cuota, FechaEmision)
      Select 1,Grupo,'Factura',Agente,0,
      Cuota = (SELECT Importe FROM TablaAnualD WHERE TablaAnual = Agente.Agente AND Ejercicio = @Ejercicio AND Periodo = @Periodo), GetDate()
      From Agente
      Where Estatus='ALTA' And Categoria='EJECUTIVO DE VENTAS' And SucursalEmpresa=0 And Familia='Gerencia de Ventas Fermi Mexico' 
      And Not Exists(Select f.* From #FactSem f Where f.Agente=Agente.Agente)
   End
IF @Sucursal=0 And @Empresa='LABC' and @Categoria is null
   Begin
      Insert Into #FactSem(Orden, Grupo, Mov, Agente, Importe, Cuota, FechaEmision)
      Select 1,Grupo,'Factura',Agente,0,
      Cuota = (SELECT Importe FROM TablaAnualD WHERE TablaAnual = Agente.Agente AND Ejercicio = @Ejercicio AND Periodo = @Periodo), GetDate()
      From Agente
      Where Estatus='ALTA' And Categoria='EJECUTIVO DE VENTAS' And SucursalEmpresa=0 And Familia<>'Gerencia de Ventas Fermi Mexico' 
      And Not Exists(Select f.* From #FactSem f Where f.Agente=Agente.Agente)
   End
*/
---
---


Insert Into #FactSem(Orden, Grupo, empresa,Mov,movid, Agente, Importe, Cuota, FechaEmision)
SELECT 2, ag.Grupo,a.empresa, a.Mov,a.movid, a.Agente, -(a.Importe*a.TipoCambio), (SELECT Importe FROM TablaAnualD WHERE TablaAnual = a.Agente AND Ejercicio = @Ejercicio AND Periodo = @Periodo), a.FechaEmision
    FROM Venta a, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     AND mt.Modulo = 'VTAS'
     AND mt.Clave = 'VTAS.D'
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     --And ag.SucursalEmpresa=IsNull(@Sucursal,ag.SucursalEmpresa)
     AND a.Estatus = 'CONCLUIDO'
/***** Lineas Para el Filtro de Agentes *****/
--     And IsNull(Ag.Categoria, '') = IsNull(IsNull(@Categoria, Ag.Categoria), '')
--modify 05/05/17     And IsNull(Ag.Familia, '') = IsNull(IsNull(@Familia, Ag.Familia), '')
     And IsNull(Ag.Grupo, '') = IsNull(IsNull(@Grupo, Ag.Grupo), '')
     And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
/***** Lineas Para el Filtro de Agentes *****/
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     AND a.Ejercicio = @Ejercicio
     AND a.Periodo = @Periodo
     AND a.Empresa = Isnull(@Empresa,a.Empresa)
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
   ORDER BY ag.Grupo, a.Agente

Insert Into #FactSem(Orden, Grupo,empresa, Mov,movid, Agente, Importe, Cuota, FechaEmision)
SELECT 2, ag.Grupo, a.empresa,'Devolucion Venta',a.movid, a.Agente, -(a.Importe*a.TipoCambio), 
(SELECT Importe FROM TablaAnualD WHERE TablaAnual = a.Agente AND Ejercicio = @Ejercicio AND Periodo = @Periodo), a.FechaEmision
    FROM Cxc a, CxcD, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     AND a.ID=CxcD.ID
     AND mt.Modulo = 'CXC'
     AND mt.Clave In ('CXC.NC')
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     --And ag.SucursalEmpresa=IsNull(@Sucursal,ag.SucursalEmpresa)
     AND a.Estatus In ('CONCLUIDO', 'PENDIENTE')
/***** Lineas Para el Filtro de Agentes *****/
--     And IsNull(Ag.Categoria, '') = IsNull(IsNull(@Categoria, Ag.Categoria), '')
--modify 05/05/17     And IsNull(Ag.Familia, '') = IsNull(IsNull(@Familia, Ag.Familia), '')
     And IsNull(Ag.Grupo, '') = IsNull(IsNull(@Grupo, Ag.Grupo), '')
     And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
/***** Lineas Para el Filtro de Agentes *****/
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     AND a.Ejercicio = @Ejercicio
     AND a.Periodo = @Periodo
     AND a.Empresa = Isnull(@Empresa,a.Empresa)
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
     AND CxcD.Aplica in('Factura Anticipo','Factura Anticipo CFD') ----Modificado para nueva revision 18-agodto 2011
   ORDER BY ag.Grupo, a.Agente

Insert Into #FactSem(Orden, Grupo, empresa,Mov,movid, Agente, Importe, Cuota, FechaEmision)
SELECT 3, ag.Grupo, a.empresa,a.Mov,a.movid, a.Agente, (a.Importe*a.TipoCambio), 
(SELECT Importe FROM TablaAnualD WHERE TablaAnual = a.Agente AND Ejercicio = @Ejercicio AND Periodo = @Periodo), a.FechaEmision
    FROM Cxc a, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     AND mt.Modulo = 'CXC'
     AND mt.Clave In ('CXC.FA')--, 'CXC.NC')
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     --And ag.SucursalEmpresa=IsNull(@Sucursal,ag.SucursalEmpresa)
     AND a.Estatus In ('CONCLUIDO', 'PENDIENTE')
/***** Lineas Para el Filtro de Agentes *****/
--     And IsNull(Ag.Categoria, '') = IsNull(IsNull(@Categoria, Ag.Categoria), '')
--modify 05/05/17     And IsNull(Ag.Familia, '') = IsNull(IsNull(@Familia, Ag.Familia), '')
     And IsNull(Ag.Grupo, '') = IsNull(IsNull(@Grupo, Ag.Grupo), '')
     And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
/***** Lineas Para el Filtro de Agentes *****/
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     AND a.Ejercicio = @Ejercicio
     AND a.Periodo = @Periodo
     AND a.Empresa = Isnull(@Empresa,a.Empresa)
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
   ORDER BY ag.Grupo, a.Agente

--Select * From #FactSem order by agente,mov,movid
--spFacturacionSemanalABC '(Todos)', 'AGP', 'WWW', 2011, 4, 'LABC', 'GVT', '(Todos)',0



  SELECT @PrimerDiaMes = CONVERT(Datetime, '01/'+CONVERT(char(2), @Periodo)+'/'+CONVERT(char(4), @Ejercicio), 103)
  SELECT @UltimoDiaMes = DATEADD(m, 1, @PrimerDiaMes) - 1
  SELECT @IniSemana1 = @PrimerDiaMes
  SELECT @FinSemana1 = @IniSemana1 + 6
  SELECT @Dias1 = DATEDIFF(d, @IniSemana1, @FinSemana1) + 1
  SELECT @IniSemana2 = @FinSemana1 + 1
  SELECT @FinSemana2 = @IniSemana2 + 6
  SELECT @Dias2 = DATEDIFF(d, @IniSemana2, @FinSemana2) + 1
  SELECT @IniSemana3 = @FinSemana2 + 1
  SELECT @FinSemana3 = @IniSemana3 + 6
  SELECT @Dias3 = DATEDIFF(d, @IniSemana3, @FinSemana3) + 1
  SELECT @IniSemana4 = @FinSemana3 + 1
  SELECT @FinSemana4 = @IniSemana4 + 6
  SELECT @Dias4 = DATEDIFF(d, @IniSemana4, @FinSemana4) + 1
  IF @FinSemana4 < @UltimoDiaMes
  BEGIN
    SELECT @IniSemana5 = @FinSemana4 + 1
    SELECT @FinSemana5 = @UltimoDiaMes
    SELECT @Dias5 = DATEDIFF(d, @IniSemana5, @FinSemana5) + 1
  END

  INSERT FactCuota (Orden, Grupo,empresa, Mov, Agente, Cuota1, Importe1, FechaD1,     FechaA1,     Cuota2, Importe2, FechaD2,     FechaA2,     Cuota3, Importe3, FechaD3,     FechaA3,     Cuota4, Importe4, FechaD4,     FechaA4,     Cuota5, Importe5, FechaD5,     FechaA5)
  SELECT DISTINCT    Orden, Grupo, empresa,Mov, Agente, 0.0,     0.0,     @IniSemana1, @FinSemana1, 0.0,     0.0,     @IniSemana2, @FinSemana2, 0.0,    0.0,      @IniSemana3, @FinSemana3, 0.0,    0.0,      @IniSemana4, @FinSemana4, 0.0,    0.0,      @IniSemana5, @FinSemana5
    FROM #FactSem

 DECLARE CrFac CURSOR FOR 
  SELECT Grupo, Mov, Agente, Importe, Cuota, FechaEmision
    FROM #FactSem
    OPEN CrFac
   FETCH NEXT FROM CrFac INTO @GruX, @Mov, @AgeX, @ImpX, @CuotaX, @FechaX
   WHILE @@FETCH_STATUS <> -1
   BEGIN
     IF @@FETCH_STATUS <> -2 
     BEGIN
       SELECT @CuotaDia = @CuotaX / DAY(@UltimoDiaMes)
       UPDATE FactCuota SET Cuota1 = @CuotaDia * @Dias1, Cuota2 = @CuotaDia * @Dias2, Cuota3 = @CuotaDia * @Dias3, Cuota4 = @CuotaDia * @Dias4, Cuota5 = @CuotaDia * @Dias5 WHERE Agente = @AgeX AND Grupo = @GruX
       IF @FechaX BETWEEN @IniSemana1 AND @FinSemana1 UPDATE FactCuota SET Importe1 = Importe1 + @ImpX WHERE Agente = @AgeX AND Grupo = @GruX And Mov=@Mov ELSE
       IF @FechaX BETWEEN @IniSemana2 AND @FinSemana2 UPDATE FactCuota SET Importe2 = Importe2 + @ImpX WHERE Agente = @AgeX AND Grupo = @GruX And Mov=@Mov ELSE
       IF @FechaX BETWEEN @IniSemana3 AND @FinSemana3 UPDATE FactCuota SET Importe3 = Importe3 + @ImpX WHERE Agente = @AgeX AND Grupo = @GruX And Mov=@Mov ELSE
       IF @FechaX BETWEEN @IniSemana4 AND @FinSemana4 UPDATE FactCuota SET Importe4 = Importe4 + @ImpX WHERE Agente = @AgeX AND Grupo = @GruX And Mov=@Mov ELSE
       IF @FechaX BETWEEN @IniSemana5 AND @FinSemana5 UPDATE FactCuota SET Importe5 = Importe5 + @ImpX WHERE Agente = @AgeX AND Grupo = @GruX And Mov=@Mov
     END
     FETCH NEXT FROM CrFac INTO @GruX, @Mov, @AgeX, @ImpX, @CuotaX, @FechaX
   END
   CLOSE CrFac
   DEALLOCATE CrFac

--Update FactCuota Set Cuota1=0, Cuota2=0, Cuota3=0, Cuota4=0, Cuota5=0 Where Mov<>'Factura'

--spFacturacionSemanalABC '(Todos)', 'AGP', 'VCL', 2009, 4, 'LABC', 'GVT', '(Todos)',1
UPDATE FactCuota set NomAgente = (Select Nombre FROM Agente WHERE Agente=FactCuota.Agente)

IF @Zona='METRO'
   Begin
     SELECT * FROM FactCuota Where Agente <> 'MOS' ORDER BY Grupo,NomAgente , Orden		
   End
Else 
   IF @Zona<>'METRO' or @Zona IS NULL
      Begin
		SELECT * FROM FactCuota Where Agente <> 'MOS' ORDER BY Grupo, Agente ,Orden
	  End
END

