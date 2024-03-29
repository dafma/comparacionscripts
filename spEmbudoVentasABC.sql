
/****** Object:  StoredProcedure [dbo].[spEmbudoVentasABC]    Script Date: 04/25/2017 18:05:18 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec spEmbudoVentasABC 'LMAGVT','(Todos)','(Todos)','AGP','ZZZZZZ',	'07/01/2014','07/31/2014','LMA',0,null

ALTER       PROCEDURE [dbo].[spEmbudoVentasABC]
    @Usuario        Char(10),
   -- @Familia        Varchar(50),
	@Grupo			varchar(50),
	@AgenteD		char(10),
	@AgenteA		char(10),     
	@FechaD			Datetime,
	@FechaA			Datetime,
	@Empresa		char(5),
	@Sucursal		int,
	@Zona           Varchar(30) --cambiado/agregado para nuevo filtro Diciembre 2014


AS BEGIN


Declare
    @Categoria VarChar(50),
    @Agente Char(10),
    @ID int,
    @IDRelacion Int,
    @Moneda Char(10),
    @TipoCambio Float,
    @Familia   Varchar(50)





exec spValidaAgentesGABC  --cambiado/agregado para nuevo filtro Diciembre 2014
@Usuario,
@Empresa ,
@Categoria OUTPUT,
@Familia OUTPUT,
@Grupo OUTPUT,
@AgenteD OUTPUT,
@AgenteA OUTPUT,
@Zona  OUTPUT --cambiado/agregado para nuevo filtro Diciembre 2014

  IF @Empresa not in(Select Empresa From Empresa) or @Empresa in('','null','NULL')
     Begin
       Select @Empresa=null
     End
  IF @Zona not in(Select Distinct Zona From Agente) or @Zona in('','null','NULL')
     Begin
       Select @Zona=null
     End
--exec spEmbudoVentasABC 'GVT','(Todos)','(Todos)','AGP','ZZZZZZ',	'01/07/2014','31/07/2014','LMA',0,''

--Set dateFormat dmy
--  IF @Grupo IN ('NULL', '', '0', '(Todos)') SELECT @Grupo = NULL

--Select @Sucursal=NullIF(@Sucursal, '')

CREATE TABLE #EmbudoVenta(
Orden			int		  NULL,
ID                  Int       NULL,
Mov			        Char(20)  NULL,
MovID			    varchar(20)	NULL,
Cliente			char(10)	NULL,
Empresa		char(5) null,
Grupo			varchar(50)	NULL,
--Familia         varchar(50) NULL,
Agente			char(10)	NULL,
NomAgente  varchar(100) NULL, 
FechaOriginal		Datetime	NULL,
Situacion		varchar(50)	NULL,
Seguimiento		varchar(100)	NULL,
Moneda          Char(10) null,
TipoCambio      Float null,
Importe			money		NULL,
ImporteP		money		NULL,
Contacto		varchar(50)	NULL,
Puesto			varchar(50)	NULL,
MovCrm          Char(20) Null,
MovIdCrm        VarChar(20) Null,
FechaSituacion		Datetime	NULL,
FechaActividad      DateTime  Null,
CantidadSituacion	int		NULL,
ImporteSituacion	money		NULL,
FechaSeguimiento    Datetime  null,
Objetivo            Text  null,
Compromiso          Text  null,
Porcentaje	    float null,
ImporteSituacionP   money null)

  INSERT #EmbudoVenta
        (Orden, ID,Mov,Moneda,Empresa,TipoCambio, MovID, Cliente, Grupo, Agente,NomAgente, FechaOriginal, Situacion, Seguimiento, Importe, ImporteP, Contacto, Puesto, FechaSituacion)
  SELECT Distinct 1,v.ID, v.Mov,v.Moneda,v.Empresa,v.Tipocambio, v.MovID, v.Cliente, ag.Grupo, v.Agente, ag.Nombre, v.FechaEmision, v.Situacion, v.SituacionNota, v.Importe, 0, v.Atencion, ct.Cargo,v.FechaInicioC-- LEFT(CONVERT(varchar, v.FechaInicioC, 110),10)   
    FROM Venta v, CteCto ct, Cte c, Agente ag
   WHERE v.Cliente = c.Cliente
     AND c.Cliente = ct.Cliente
     AND v.Atencion = ct.Nombre
     AND v.Agente = ag.Agente
     AND ISNULL(ag.Grupo, '') = ISNULL(ISNULL(@Grupo, ag.Grupo), '')
     AND v.Agente BETWEEN @AgenteD AND @AgenteA
--     AND ((v.FechaInicioC is not Null And v.FechaInicioC BETWEEN @FechaD AND @FechaA) or (Isnull(v.FechaInicioC,'')=Isnull(v.FechaInicioC,'')))
--		Por Indicaciones de RGC y JSU se deshabilito el filtro de Fecha para que salgan todas las pendientes 18/10/2013.
     AND v.Mov ='Cotización Cliente'
     AND v.Estatus='PENDIENTE'
     AND v.Empresa = Isnull(@Empresa,v.Empresa)
     And IsNull(v.Sucursal, '') = IsNull(IsNull(@Sucursal, v.Sucursal), '')
--     AND ag.Categoria = IsNull(@Categoria,ag.Categoria) --cambiado/agregado para nuevo filtro Diciembre 2014
     --And ag.Familia=Isnull(@Familia,ag.Familia)
     And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
     And Substring(v.Mov,5,1)<>'-'   ---esto es para que no incluya las subctoizaciones
     And v.Situacion in('PARA EVALUACION','NEGOCIACIÓN CLIENTE')
--exec spEmbudoVentasABC 'ALOPEZ2','(Todos)','(Todos)','AGP','ZZZZZZ',	'01/01/2014','01/31/2014','LMA',0
---
  DECLARE crAuxiliar CURSOR FOR
   SELECT ID From #EmbudoVenta
  
  OPEN crAuxiliar
  FETCH NEXT FROM crAuxiliar INTO @ID
  WHILE @@FETCH_STATUS <> -1 And @@Error=0
  BEGIN
    IF @@FETCH_STATUS <> -2 
       Begin
         Select @IDRelacion=(Select Max(ID) From crmventas Where idventas=@ID)
         Update #EmbudoVenta
         Set FechaSeguimiento=c.FechaSeguimiento,
             MovCrm          =c.Mov,
             MovIdCrm        =c.Movid,
             FechaActividad  =c.FechaActividad,
             Objetivo        =c.Objetivo,
             Compromiso      =c.Compromisos,
	     ImporteP	     =IsNull(((a.Importe*IsNull(c.Cumplimiento,0))/100),0),
	     Porcentaje	     =IsNull(c.Cumplimiento,0)
         From #EmbudoVenta a,crmVentas c 
         Where c.ID=@IdRelacion
               And a.ID=@ID
         --Where Current of crAuxiliar
       End
    FETCH NEXT FROM crAuxiliar INTO @ID
  END
  CLOSE crAuxiliar
  DEALLOCATE crAuxiliar
--- 
  SELECT * Into #EmbudoVenta2 FROM #EmbudoVenta --WHERE ORDEN=1
  Where ((FechaSeguimiento is not Null And FechaSeguimiento BETWEEN @FechaD AND @FechaA) or (FechaSeguimiento is Null))
/****Se quita el Filtro por FechaSituacion y Se cambia por FechaSeguimiento, solicitado por JS 12-02-2008 USB
  Where ((FechaSituacion is not Null And FechaSituacion BETWEEN @FechaD AND @FechaA) or (Fechasituacion is Null))
*****/

  DECLARE crAuxiliar CURSOR FOR
   SELECT Distinct Agente,Moneda From #EmbudoVenta2
  
  OPEN crAuxiliar
  FETCH NEXT FROM crAuxiliar INTO @Agente,@Moneda
  WHILE @@FETCH_STATUS <> -1 And @@Error=0
  BEGIN
    IF @@FETCH_STATUS <> -2 
       Begin
		  SELECT DISTINCT Situacion, Mov,Moneda
			INTO #ResumenSit
			FROM #EmbudoVenta2
            Where Agente=@Agente
		   ORDER BY Situacion

		  SELECT Situacion, Mov, CantidadSituacion = COUNT(Situacion)
			INTO #ResumenSitCant
			FROM #EmbudoVenta2
            Where Agente=@Agente
		   GROUP BY Situacion, Mov
		   ORDER BY Situacion

		  SELECT Situacion, Mov, ImporteSituacion = SUM(Importe)
			INTO #ResumenSitImp
			FROM #EmbudoVenta2
            Where Agente=@Agente
		   GROUP BY Situacion, Mov
		   ORDER BY Situacion

		  SELECT Situacion, Mov, ImporteSituacionP = SUM(ImporteP)
			INTO #ResumenSitImpP
			FROM #EmbudoVenta2
            Where Agente=@Agente
		   GROUP BY Situacion, Mov
		   ORDER BY Situacion

          Select @Grupo=(Select Grupo FRom Agente Where Agente=@Agente)
          Select @Familia=(Select Familia FRom Agente Where Agente=@Agente)
		  INSERT #EmbudoVenta2
				(Orden,Agente, Grupo,Moneda,Situacion, Mov, CantidadSituacion, ImporteSituacion, ImporteSituacionP)
		  SELECT 2, @Agente,@Grupo,a.Moneda,a.Situacion, a.Mov, b.CantidadSituacion, c.ImporteSituacion, d.ImporteSituacionP
			FROM #ResumenSit a, #ResumenSitCant b, #ResumenSitImp c, #ResumenSitImpP d
		   WHERE a.Situacion = b.Situacion AND a.Mov = b.Mov
			 AND a.Situacion = c.Situacion AND a.Mov = c.Mov
			 AND a.Situacion = d.Situacion AND a.Mov = d.Mov
		   ORDER BY a.Situacion, a.Mov
          Drop Table #ResumenSit
          Drop Table #ResumenSitCant
          Drop Table #ResumenSitImp 
	  Drop Table #ResumenSitImpP 
       End
    FETCH NEXT FROM crAuxiliar INTO @Agente,@Moneda
  END
  CLOSE crAuxiliar
  DEALLOCATE crAuxiliar

Update #EmbudoVenta2 Set ImporteP=0 Where ImporteP Is Null
  IF @Zona='METRO'
   Begin
     SELECT * FROM #EmbudoVenta2 ORDER BY Grupo, NomAgente, Orden, FechaActividad, Situacion dESC
   End
Else 
   IF @Zona<>'METRO'
      Begin
         SELECT * FROM #EmbudoVenta2 ORDER BY Grupo, Agente, Orden, FechaActividad, Situacion dESC
	  End
  

END

