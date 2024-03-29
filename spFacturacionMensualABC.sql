
/****** Object:  StoredProcedure [dbo].[spFacturacionMensualABC]    Script Date: 04/26/2017 13:46:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER        PROCEDURE [dbo].[spFacturacionMensualABC]
		@Grupo		varchar(50),
		@AgenteD	char(10),
		@AgenteA	char(10),
		@Ejercicio	int,
		@Empresa	char(5),
		@Sucursal	int,
		@Zona       Varchar(30) --cambiado/agregado para nuevo filtro Diciembre 2014
		
		

AS BEGIN

  DECLARE
	@EjercicioAnt1		int,
	@EjercicioAnt2		int,
	@GruX			varchar(50),
	@AgeX			char(10),
	@ImpX			money,
	@CuotaX			money,
	@FechaX			Datetime,
	@Eje2			int,
	@EjeX			int,
	@GruY			varchar(50),
	@AgeY			char(10),
	@ImpY			money,
	@EjeY			int,
	@PerY			int,
	@GruZ			varchar(50),
	@AgeZ			char(10),
	@EjeZ			int,
	@Mov			char(20)


IF Exists (Select * From SysObjects Where ID = object_id('dbo.FactCuotaM') and type = 'U') 
Drop Table dbo.FactCuotaM

  CREATE TABLE FactCuotaM (
	Grupo		varchar(50)	NULL,
	Agente		char(10)	NULL,
	NomAgente   varchar(100) NULL, 
	Empresa	char(5) null,
	Ejercicio	int		NULL,
	Cuota1		money		NULL,
	Importe1	money		NULL,
	Cuota2		money		NULL,
	Importe2	money		NULL,
	Cuota3		money		NULL,
	Importe3	money		NULL,
	Cuota4		money		NULL,
	Importe4	money		NULL,
	Cuota5		money		NULL,
	Importe5	money		NULL,
	Cuota6		money		NULL,
	Importe6	money		NULL,
	Cuota7		money		NULL,
	Importe7	money		NULL,
	Cuota8		money		NULL,
	Importe8	money		NULL,
	Cuota9		money		NULL,
	Importe9	money		NULL,
	Cuota10		money		NULL,
	Importe10	money		NULL,
	Cuota11		money		NULL,
	Importe11	money		NULL,
	Cuota12		money		NULL,
	Importe12	money		NULL,
	Prom		money		NULL,
	DesvEst		money		NULL,
	CV		float		NULL,
	VMin		money		NULL,
	VMax		money		NULL)




  IF @Grupo IN ('NULL', '', '0', '(Todos)') SELECT @Grupo = NULL
  IF @Ejercicio = 0 SELECT @Ejercicio = YEAR(GETDATE())
  IF @Zona not in(Select Distinct Zona From Agente) or @Zona in('','null','NULL')
     Begin
       Select @Zona=null
     End

  SELECT @EjercicioAnt1 = @Ejercicio - 1
  SELECT @EjercicioAnt2 = @Ejercicio - 2

  SELECT ag.Grupo, a.Agente, Importe= Sum(((a.Importe*a.TipoCambio)-((IsNull(a.AnticiposFacturados,0)-IsNull(AnticiposImpuestos,0))*a.TipoCambio))),
    a.Ejercicio, a.Periodo,a.Empresa
    INTO #FactMensual
    FROM Venta a, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     AND mt.Modulo = 'VTAS'
     AND mt.Clave = 'VTAS.F'
     AND a.Agente = ag.Agente
     --And ag.SucursalEmpresa=IsNull(@Sucursal, ag.SucursalEmpresa)
     AND a.Cliente = c.Cliente
     AND a.Estatus = 'CONCLUIDO'
     AND ISNULL(ag.Grupo, '') = ISNULL(ISNULL(@Grupo, ag.Grupo), '')
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     AND a.Ejercicio BETWEEN @EjercicioAnt2 AND @Ejercicio
     AND a.Empresa = isnull(@Empresa,a.Empresa)
     And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
     GROUP BY a.Mov, ag.Grupo, a.Agente, a.Ejercicio, a.Periodo,a.Empresa
--   ORDER BY ag.Grupo, a.Agente, a.Ejercicio, a.Periodo
Union
SELECT ag.Grupo, a.Agente, Importe = SUM(-a.Importe*a.TipoCambio), a.Ejercicio, a.Periodo,a.Empresa
    FROM Venta a, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     AND mt.Modulo = 'VTAS'
     AND mt.Clave = 'VTAS.D'
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     --And ag.SucursalEmpresa=IsNull(@Sucursal, ag.SucursalEmpresa)
     AND a.Estatus = 'CONCLUIDO'
     AND ISNULL(ag.Grupo, '') = ISNULL(ISNULL(@Grupo, ag.Grupo), '')
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     AND a.Ejercicio BETWEEN @EjercicioAnt2 AND @Ejercicio
     AND a.Empresa = @Empresa
     And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
     GROUP BY ag.Grupo, a.Agente, a.Ejercicio, a.Periodo,a.Empresa
Union
SELECT ag.Grupo, a.Agente, Sum(-a.Importe*a.TipoCambio), a.Ejercicio, a.Periodo,a.Empresa
    FROM Cxc a, CxcD, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     AND a.ID=CxcD.ID
     AND mt.Modulo = 'CXC'
     AND mt.Clave In ('CXC.NC')
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     --And ag.SucursalEmpresa=IsNull(@Sucursal, ag.SucursalEmpresa)
     AND a.Estatus In ('CONCLUIDO', 'PENDIENTE')
     AND ISNULL(ag.Grupo, '') = ISNULL(ISNULL(@Grupo, ag.Grupo), '')
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     AND a.Ejercicio BETWEEN @EjercicioAnt2 AND @Ejercicio
     AND a.Empresa = @Empresa
     And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
     AND CxcD.Aplica In ('Factura Anticipo','Factura Anticipo CFD')
     GROUP BY ag.Grupo, a.Agente, a.Ejercicio, a.Periodo,a.Empresa
Union
    SELECT ag.Grupo, a.Agente, Importe = SUM(a.Importe*a.TipoCambio), a.Ejercicio, a.Periodo,a.Empresa
    FROM Cxc a, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     AND mt.Modulo = 'CXC'
     AND mt.Clave = 'CXC.FA'
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     --And ag.SucursalEmpresa=IsNull(@Sucursal, ag.SucursalEmpresa)
     AND a.Estatus In ('CONCLUIDO', 'PENDIENTE')

     AND ISNULL(ag.Grupo, '') = ISNULL(ISNULL(@Grupo, ag.Grupo), '')
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     AND a.Ejercicio BETWEEN @EjercicioAnt2 AND @Ejercicio
     AND a.Empresa = @Empresa
     And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
     GROUP BY ag.Grupo, a.Agente, a.Ejercicio, a.Periodo,a.Empresa
Union
    SELECT ag.Grupo, a.Agente, Importe = SUM(a.Importe*a.TipoCambio), a.Ejercicio, a.Periodo,a.Empresa
    FROM Cxc a, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     AND mt.Modulo = 'CXC'
     AND mt.Clave = 'CXC.CA'
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     --And ag.SucursalEmpresa=IsNull(@Sucursal, ag.SucursalEmpresa)
     AND a.Estatus In ('CONCLUIDO', 'PENDIENTE')

     AND ISNULL(ag.Grupo, '') = ISNULL(ISNULL(@Grupo, ag.Grupo), '')
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     AND a.Ejercicio BETWEEN @EjercicioAnt2 AND @Ejercicio
     AND a.Empresa = @Empresa
     And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
     GROUP BY ag.Grupo, a.Agente, a.Ejercicio, a.Periodo,a.Empresa


--SELECT * FROM #FactMensual



 DECLARE CrFac CURSOR FOR 
  SELECT DISTINCT Grupo, Agente, @EjercicioAnt2
    FROM #FactMensual
    OPEN CrFac
   FETCH NEXT FROM CrFac INTO @GruX, @AgeX, @Eje2
   WHILE @@FETCH_STATUS <> -1
   BEGIN
     IF @@FETCH_STATUS <> -2 
     BEGIN
       SELECT @EjeX = @Eje2
       WHILE @EjeX <= @Ejercicio
       BEGIN
         INSERT FactCuotaM(Grupo, Agente, Ejercicio)
         VALUES(@GruX, @AgeX, @EjeX)
         SELECT @EjeX = @EjeX + 1
       END
     END
     FETCH NEXT FROM CrFac INTO @GruX, @AgeX, @Eje2
   END
   CLOSE CrFac
   DEALLOCATE CrFac


 DECLARE CrFac1 CURSOR FOR 
  SELECT Grupo, Agente, Sum(IsNull(Importe,0)), Ejercicio, Periodo
    FROM #FactMensual Group By Grupo, Agente, Ejercicio, Periodo
    OPEN CrFac1
   FETCH NEXT FROM CrFac1 INTO @GruY, @AgeY, @ImpY, @EjeY, @PerY
   WHILE @@FETCH_STATUS <> -1
   BEGIN
     IF @@FETCH_STATUS <> -2 
     BEGIN
       UPDATE FactCuotaM SET Importe1  = @ImpY WHERE Grupo = @GruY AND Agente = @AgeY AND Ejercicio = @EjeY AND @PerY = 1
       UPDATE FactCuotaM SET Importe2  = @ImpY WHERE Grupo = @GruY AND Agente = @AgeY AND Ejercicio = @EjeY AND @PerY = 2
       UPDATE FactCuotaM SET Importe3  = @ImpY WHERE Grupo = @GruY AND Agente = @AgeY AND Ejercicio = @EjeY AND @PerY = 3
       UPDATE FactCuotaM SET Importe4  = @ImpY WHERE Grupo = @GruY AND Agente = @AgeY AND Ejercicio = @EjeY AND @PerY = 4
       UPDATE FactCuotaM SET Importe5  = @ImpY WHERE Grupo = @GruY AND Agente = @AgeY AND Ejercicio = @EjeY AND @PerY = 5
       UPDATE FactCuotaM SET Importe6  = @ImpY WHERE Grupo = @GruY AND Agente = @AgeY AND Ejercicio = @EjeY AND @PerY = 6
       UPDATE FactCuotaM SET Importe7  = @ImpY WHERE Grupo = @GruY AND Agente = @AgeY AND Ejercicio = @EjeY AND @PerY = 7
       UPDATE FactCuotaM SET Importe8  = @ImpY WHERE Grupo = @GruY AND Agente = @AgeY AND Ejercicio = @EjeY AND @PerY = 8
       UPDATE FactCuotaM SET Importe9  = @ImpY WHERE Grupo = @GruY AND Agente = @AgeY AND Ejercicio = @EjeY AND @PerY = 9
       UPDATE FactCuotaM SET Importe10 = @ImpY WHERE Grupo = @GruY AND Agente = @AgeY AND Ejercicio = @EjeY AND @PerY = 10
       UPDATE FactCuotaM SET Importe11 = @ImpY WHERE Grupo = @GruY AND Agente = @AgeY AND Ejercicio = @EjeY AND @PerY = 11
       UPDATE FactCuotaM SET Importe12 = @ImpY WHERE Grupo = @GruY AND Agente = @AgeY AND Ejercicio = @EjeY AND @PerY = 12
     END
     FETCH NEXT FROM CrFac1 INTO @GruY, @AgeY, @ImpY, @EjeY, @PerY
   END
   CLOSE CrFac1
   DEALLOCATE CrFac1

 DECLARE CrFac2 CURSOR FOR 
  SELECT Grupo, Agente, Ejercicio
    FROM FactCuotaM
   WHERE Ejercicio = @Ejercicio
    OPEN CrFac2
   FETCH NEXT FROM CrFac2 INTO @GruZ, @AgeZ, @EjeZ
   WHILE @@FETCH_STATUS <> -1
   BEGIN
     IF @@FETCH_STATUS <> -2 
     BEGIN
       UPDATE FactCuotaM SET Cuota1  = (SELECT Importe FROM TablaAnualD WHERE TablaAnual = @AgeZ AND Ejercicio = @EjeZ AND Periodo = 1)  WHERE Grupo = @GruZ AND Agente = @AgeZ AND Ejercicio = @EjeZ
       UPDATE FactCuotaM SET Cuota2  = (SELECT Importe FROM TablaAnualD WHERE TablaAnual = @AgeZ AND Ejercicio = @EjeZ AND Periodo = 2)  WHERE Grupo = @GruZ AND Agente = @AgeZ AND Ejercicio = @EjeZ
       UPDATE FactCuotaM SET Cuota3  = (SELECT Importe FROM TablaAnualD WHERE TablaAnual = @AgeZ AND Ejercicio = @EjeZ AND Periodo = 3)  WHERE Grupo = @GruZ AND Agente = @AgeZ AND Ejercicio = @EjeZ
       UPDATE FactCuotaM SET Cuota4  = (SELECT Importe FROM TablaAnualD WHERE TablaAnual = @AgeZ AND Ejercicio = @EjeZ AND Periodo = 4)  WHERE Grupo = @GruZ AND Agente = @AgeZ AND Ejercicio = @EjeZ
       UPDATE FactCuotaM SET Cuota5  = (SELECT Importe FROM TablaAnualD WHERE TablaAnual = @AgeZ AND Ejercicio = @EjeZ AND Periodo = 5)  WHERE Grupo = @GruZ AND Agente = @AgeZ AND Ejercicio = @EjeZ
       UPDATE FactCuotaM SET Cuota6  = (SELECT Importe FROM TablaAnualD WHERE TablaAnual = @AgeZ AND Ejercicio = @EjeZ AND Periodo = 6)  WHERE Grupo = @GruZ AND Agente = @AgeZ AND Ejercicio = @EjeZ
       UPDATE FactCuotaM SET Cuota7  = (SELECT Importe FROM TablaAnualD WHERE TablaAnual = @AgeZ AND Ejercicio = @EjeZ AND Periodo = 7)  WHERE Grupo = @GruZ AND Agente = @AgeZ AND Ejercicio = @EjeZ
       UPDATE FactCuotaM SET Cuota8  = (SELECT Importe FROM TablaAnualD WHERE TablaAnual = @AgeZ AND Ejercicio = @EjeZ AND Periodo = 8)  WHERE Grupo = @GruZ AND Agente = @AgeZ AND Ejercicio = @EjeZ
       UPDATE FactCuotaM SET Cuota9  = (SELECT Importe FROM TablaAnualD WHERE TablaAnual = @AgeZ AND Ejercicio = @EjeZ AND Periodo = 9)  WHERE Grupo = @GruZ AND Agente = @AgeZ AND Ejercicio = @EjeZ
       UPDATE FactCuotaM SET Cuota10 = (SELECT Importe FROM TablaAnualD WHERE TablaAnual = @AgeZ AND Ejercicio = @EjeZ AND Periodo = 10) WHERE Grupo = @GruZ AND Agente = @AgeZ AND Ejercicio = @EjeZ
       UPDATE FactCuotaM SET Cuota11 = (SELECT Importe FROM TablaAnualD WHERE TablaAnual = @AgeZ AND Ejercicio = @EjeZ AND Periodo = 11) WHERE Grupo = @GruZ AND Agente = @AgeZ AND Ejercicio = @EjeZ
       UPDATE FactCuotaM SET Cuota12 = (SELECT Importe FROM TablaAnualD WHERE TablaAnual = @AgeZ AND Ejercicio = @EjeZ AND Periodo = 12) WHERE Grupo = @GruZ AND Agente = @AgeZ AND Ejercicio = @EjeZ
     END
     FETCH NEXT FROM CrFac2 INTO @GruZ, @AgeZ, @EjeZ
   END
   CLOSE CrFac2
   DEALLOCATE CrFac2

  SELECT Grupo, Agente, Prom=Sum(Importe), Valor=1
    INTO #Prom1
    FROM #FactMensual --Where Importe >0
   GROUP BY Grupo, Agente, Ejercicio, Periodo
   ORDER BY Grupo, Agente

SELECT Grupo, Agente, Prom=Sum(Prom)/Sum(Valor)
    INTO #Prom
    FROM #Prom1 Where Prom >0
   GROUP BY Grupo, Agente
   ORDER BY Grupo, Agente

  SELECT Grupo, Agente, DesvEst = STDEV(Prom)
    INTO #DesvEst
    FROM #Prom1 Where Prom >0
   GROUP BY Grupo, Agente
   ORDER BY Grupo, Agente

--spFacturacionMensualABC '(Todos)', 'EPC', 'EPC', 2008, 'LABC'

  SELECT Grupo, Agente, VMin = MIN(Prom)
    INTO #VMin
    FROM #Prom1 Where Prom >0
   GROUP BY Grupo, Agente
   ORDER BY Grupo, Agente

  SELECT Grupo, Agente, VMax = MAX(Prom)
    INTO #VMax
    FROM #Prom1 Where Prom >0
   GROUP BY Grupo, Agente
   ORDER BY Grupo, Agente

  UPDATE FactCuotaM SET Prom = b.Prom FROM FactCuotaM a, #Prom b WHERE a.Grupo = b.Grupo AND a.Agente = b.Agente --AND a.Ejercicio = b.Ejercicio
  UPDATE FactCuotaM SET DesvEst = b.DesvEst FROM FactCuotaM a, #DesvEst b WHERE a.Grupo = b.Grupo AND a.Agente = b.Agente --AND a.Ejercicio = b.Ejercicio
  UPDATE FactCuotaM SET CV = (ISNULL(DesvEst, 0)/Prom) * 100
  UPDATE FactCuotaM SET VMin = b.VMin FROM FactCuotaM a, #VMin b WHERE a.Grupo = b.Grupo AND a.Agente = b.Agente --AND a.Ejercicio = b.Ejercicio
  UPDATE FactCuotaM SET VMax = b.VMax FROM FactCuotaM a, #VMax b WHERE a.Grupo = b.Grupo AND a.Agente = b.Agente --AND a.Ejercicio = b.Ejercicio

/*
  Update FactCuotaM Set Cuota1=0 Where Importe1 Is Null
  Update FactCuotaM Set Cuota2=0 Where Importe2 Is Null
  Update FactCuotaM Set Cuota3=0 Where Importe3 Is Null
  Update FactCuotaM Set Cuota4=0 Where Importe4 Is Null
  Update FactCuotaM Set Cuota5=0 Where Importe5 Is Null
*/

UPDATE FactCuotaM set NomAgente = (Select Nombre FROM Agente WHERE Agente=FactCuotaM.Agente)

IF @Zona='METRO'
   Begin
     SELECT * FROM FactCuotaM Where Agente <> 'MOS' ORDER BY Grupo,NomAgente 		
   End
IF @Zona<>'METRO' or @Zona IS NULL
   Begin
	SELECT * FROM FactCuotaM Where Agente <> 'MOS' ORDER BY Grupo, Agente 
   End
END








