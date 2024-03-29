/****** Object:  StoredProcedure [dbo].[spFacturacionSectorABC]    Script Date: 05/05/2017 16:37:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER      PROCEDURE [dbo].[spFacturacionSectorABC]
		@Grupo		varchar(50),
		@Categoria	varchar(50),
		@AgenteD	char(10),
		@AgenteA	char(10),
		@Ejercicio	int,
		@Empresa	char(5),
		@Sucursal	int,
		@Zona           varchar(30) --add 02/05/17

AS BEGIN

  DECLARE
	@GruX			varchar(50),
	@AgeX			char(10),
	@ImpX			money,
	@CuotaX			money,
	@FechaX			Datetime,
	@Eje2			int,
	@CatX			varchar(50),
	@GruY			varchar(50),
	@AgeY			char(10),
	@ImpY			money,
	@CatY			varchar(50),
	@NumY			int,
	@PerY			int,
	@GruZ			varchar(50),
	@AgeZ			char(10),
	@EjeZ			int,
        @Cliente		char(10)

--drop table #FactCuotaM
  CREATE TABLE #FactSector (
	Grupo		varchar(50)	NULL,
	Agente		char(10)	NULL,
	NomAgente  varchar(100) NULL,  --add 02/05/17
	Empresa	char(5) null,
	Categoria	varchar(50)	NULL,
	Cant1		money		NULL,
	Importe1	money		NULL,
	Cant2		money		NULL,
	Importe2	money		NULL,
	Cant3		money		NULL,
	Importe3	money		NULL,
	Cant4		money		NULL,
	Importe4	money		NULL,
	Cant5		money		NULL,
	Importe5	money		NULL,
	Cant6		money		NULL,
	Importe6	money		NULL,
	Cant7		money		NULL,
	Importe7	money		NULL,
	Cant8		money		NULL,
	Importe8	money		NULL,
	Cant9		money		NULL,
	Importe9	money		NULL,
	Cant10		money		NULL,
	Importe10	money		NULL,
	Cant11		money		NULL,
	Importe11	money		NULL,
	Cant12		money		NULL,
	Importe12	money		NULL,
        Cliente		bigint		NULL)

  IF @Grupo     IN ('NULL', '', '0', '(Todos)') SELECT @Grupo     = NULL
  IF @Categoria IN ('NULL', '', '0', '(Todos)') SELECT @Categoria = NULL
  
  IF @Zona not in(Select Distinct Zona From Agente) or @Zona in('','null','NULL') --add 02/05/17
     Begin
       Select @Zona=null
     End

Create Table #FactMensual(
Grupo varchar(50) Null,
Agente char(10) Null,
Importe money Null,
Cliente int Null,
Categoria varchar(50) Null,
Ejercicio int Null,
Periodo int Null)
  
Insert Into #FactMensual
  SELECT ag.Grupo, a.Agente, Importe=Sum(((a.Importe*a.TipoCambio)-((IsNull(a.AnticiposFacturados,0)-IsNull(AnticiposImpuestos,0))*a.TipoCambio))), 
         Cliente = COUNT(a.Cliente), c.Categoria, a.Ejercicio, a.Periodo,a.Empresa
    FROM Venta a, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     AND mt.Modulo = 'VTAS'
     AND mt.Clave = 'VTAS.F'
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     AND a.Estatus = 'CONCLUIDO'
     AND ISNULL(ag.Grupo,   '')  = ISNULL(ISNULL(@Grupo,     ag.Grupo), '')
     AND ISNULL(c.Categoria, '') = ISNULL(ISNULL(@Categoria, c.Categoria), '')
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     AND a.Ejercicio = @Ejercicio
     AND a.Empresa = @Empresa
     And ag.Zona=Isnull(@Zona,ag.Zona) --add 02/05/17
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
   Group BY ag.Grupo, a.Agente, c.Categoria, a.Ejercicio, a.Periodo,a.Empresa
Union All
SELECT ag.Grupo, a.Agente, Importe=Sum((a.Importe*a.TipoCambio)),
       Cliente = COUNT(a.Cliente), c.Categoria, a.Ejercicio, a.Periodo,a.Empresa
    FROM Cxc a, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     AND mt.Modulo = 'CXC'
     AND mt.Clave In ('CXC.FA')
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     AND a.Estatus In ('CONCLUIDO', 'PENDIENTE')
     AND ISNULL(ag.Grupo,   '')  = ISNULL(ISNULL(@Grupo,     ag.Grupo), '')
     AND ISNULL(c.Categoria, '') = ISNULL(ISNULL(@Categoria, c.Categoria), '')
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     AND a.Ejercicio = @Ejercicio
     AND a.Empresa = @Empresa
     And ag.Zona=Isnull(@Zona,ag.Zona) --add 02/05/17
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
     Group BY ag.Grupo, a.Agente, c.Categoria, a.Ejercicio, a.Periodo,a.Empresa
Union All
SELECT ag.Grupo, a.Agente, Importe=IsNull(Sum((-a.Importe*a.TipoCambio)),0),
         Cliente = COUNT(a.Cliente), c.Categoria, a.Ejercicio, a.Periodo,a.Empresa
    FROM Venta a, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     AND mt.Modulo = 'VTAS'
     AND mt.Clave = 'VTAS.D'
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     AND a.Estatus = 'CONCLUIDO'
     AND ISNULL(ag.Grupo,   '')  = ISNULL(ISNULL(@Grupo,     ag.Grupo), '')
     AND ISNULL(c.Categoria, '') = ISNULL(ISNULL(@Categoria, c.Categoria), '')
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     AND a.Ejercicio = @Ejercicio
     AND a.Empresa = @Empresa
     And ag.Zona=Isnull(@Zona,ag.Zona) --add 02/05/17
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
   Group BY ag.Grupo, a.Agente, c.Categoria, a.Ejercicio, a.Periodo,a.Empresa
Union All
SELECT ag.Grupo, a.Agente, Importe=IsNull(Sum((-a.Importe*a.TipoCambio)),0),
       Cliente = COUNT(a.Cliente), c.Categoria, a.Ejercicio, a.Periodo,a.Empresa
    FROM Cxc a, CxcD, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     AND a.ID=CxcD.ID
     AND mt.Modulo = 'CXC'
     AND mt.Clave In ('CXC.NC')
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     AND a.Estatus In ('CONCLUIDO', 'PENDIENTE')
     AND ISNULL(ag.Grupo,   '')  = ISNULL(ISNULL(@Grupo,     ag.Grupo), '')
     AND ISNULL(c.Categoria, '') = ISNULL(ISNULL(@Categoria, c.Categoria), '')
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     AND a.Ejercicio = @Ejercicio
     AND a.Empresa = @Empresa
     And ag.Zona=Isnull(@Zona,ag.Zona) --add 02/05/17
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
     AND CxcD.Aplica = 'Factura Anticipo'
     Group BY ag.Grupo, a.Agente, c.Categoria, a.Ejercicio, a.Periodo,a.Empresa
Union All
SELECT ag.Grupo, a.Agente, Importe=IsNull(Sum((a.Importe*a.TipoCambio)),0),
       Cliente = COUNT(a.Cliente), c.Categoria, a.Ejercicio, a.Periodo,a.Empresa
    FROM Cxc a, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     --AND a.ID=CxcD.ID
     AND mt.Modulo = 'CXC'
     AND mt.Clave In ('CXC.CA')
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     AND a.Estatus In ('CONCLUIDO', 'PENDIENTE')
     AND ISNULL(ag.Grupo,   '')  = ISNULL(ISNULL(@Grupo,     ag.Grupo), '')
     AND ISNULL(c.Categoria, '') = ISNULL(ISNULL(@Categoria, c.Categoria), '')
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     AND a.Ejercicio = @Ejercicio
     AND a.Empresa = @Empresa
     And ag.Zona=Isnull(@Zona,ag.Zona) --add 02/05/17
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
     --AND CxcD.Aplica = 'Factura Anticipo'
     Group BY ag.Grupo, a.Agente, c.Categoria, a.Ejercicio, a.Periodo,a.Empresa

Update #FactMensual Set Grupo='S/G' Where Grupo Is Null
Update #FactMensual Set Categoria='S/C' Where Categoria Is Null 

--Select * From #FactMensual

/*
  SELECT ag.Grupo, a.Agente, Importe = SUM(a.Importe), Cliente = COUNT(a.Cliente), c.Categoria, a.Ejercicio, a.Periodo
    INTO #FactMensual
    FROM Venta a, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     AND mt.Modulo = 'VTAS'
     AND mt.Clave = 'VTAS.F'
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     AND a.Estatus = 'CONCLUIDO'
     AND ISNULL(ag.Grupo,   '')  = ISNULL(ISNULL(@Grupo,     ag.Grupo), '')
     AND ISNULL(c.Categoria, '') = ISNULL(ISNULL(@Categoria, c.Categoria), '')
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     AND a.Ejercicio = @Ejercicio
     AND a.Empresa = @Empresa
   GROUP BY ag.Grupo, a.Agente, c.Categoria, a.Ejercicio, a.Periodo
   ORDER BY ag.Grupo, a.Agente, c.Categoria, a.Ejercicio, a.Periodo
*/

 DECLARE CrFac CURSOR FOR 
  SELECT Distinct Grupo, Agente, Categoria
    FROM #FactMensual
    OPEN CrFac
   FETCH NEXT FROM CrFac INTO @GruX, @AgeX, @CatX
   WHILE @@FETCH_STATUS <> -1
   BEGIN
     IF @@FETCH_STATUS <> -2 
     BEGIN
       INSERT #FactSector(Grupo, Agente, Categoria)
       VALUES(@GruX, @AgeX, @CatX)
     END
     FETCH NEXT FROM CrFac INTO @GruX, @AgeX, @CatX
   END
   CLOSE CrFac
   DEALLOCATE CrFac

--Select * From #FactSector

--spFacturacionSectorABC'(Todos)','(Todos)','AGP','VHG',2008,'LABC'

 DECLARE CrFac1 CURSOR FOR 
  SELECT Grupo, Agente, Categoria, Sum(IsNull(Importe,0)), Sum(IsNull(Cliente,0)), Periodo
    FROM #FactMensual
    Group By Grupo, Agente, Categoria, Periodo
    OPEN CrFac1
   FETCH NEXT FROM CrFac1 INTO @GruY, @AgeY, @CatY, @ImpY, @NumY, @PerY
   WHILE @@FETCH_STATUS <> -1
   BEGIN
     IF @@FETCH_STATUS <> -2 
     BEGIN
       IF @ImpY Is Null Select @ImpY=0
       UPDATE #FactSector SET Importe1  = @ImpY WHERE Grupo = @GruY AND Agente = @AgeY AND Categoria = @CatY AND @PerY = 1
       UPDATE #FactSector SET Cant1     = @NumY WHERE Grupo = @GruY AND Agente = @AgeY AND Categoria = @CatY AND @PerY = 1
       UPDATE #FactSector SET Importe2  = @ImpY WHERE Grupo = @GruY AND Agente = @AgeY AND Categoria = @CatY AND @PerY = 2
       UPDATE #FactSector SET Cant2     = @NumY WHERE Grupo = @GruY AND Agente = @AgeY AND Categoria = @CatY AND @PerY = 2
       UPDATE #FactSector SET Importe3  = @ImpY WHERE Grupo = @GruY AND Agente = @AgeY AND Categoria = @CatY AND @PerY = 3
       UPDATE #FactSector SET Cant3     = @NumY WHERE Grupo = @GruY AND Agente = @AgeY AND Categoria = @CatY AND @PerY = 3
       UPDATE #FactSector SET Importe4  = @ImpY WHERE Grupo = @GruY AND Agente = @AgeY AND Categoria = @CatY AND @PerY = 4
       UPDATE #FactSector SET Cant4     = @NumY WHERE Grupo = @GruY AND Agente = @AgeY AND Categoria = @CatY AND @PerY = 4
       UPDATE #FactSector SET Importe5  = @ImpY WHERE Grupo = @GruY AND Agente = @AgeY AND Categoria = @CatY AND @PerY = 5
       UPDATE #FactSector SET Cant5     = @NumY WHERE Grupo = @GruY AND Agente = @AgeY AND Categoria = @CatY AND @PerY = 5
       UPDATE #FactSector SET Importe6  = @ImpY WHERE Grupo = @GruY AND Agente = @AgeY AND Categoria = @CatY AND @PerY = 6
       UPDATE #FactSector SET Cant6     = @NumY WHERE Grupo = @GruY AND Agente = @AgeY AND Categoria = @CatY AND @PerY = 6
       UPDATE #FactSector SET Importe7  = @ImpY WHERE Grupo = @GruY AND Agente = @AgeY AND Categoria = @CatY AND @PerY = 7
       UPDATE #FactSector SET Cant7     = @NumY WHERE Grupo = @GruY AND Agente = @AgeY AND Categoria = @CatY AND @PerY = 7
       UPDATE #FactSector SET Importe8  = @ImpY WHERE Grupo = @GruY AND Agente = @AgeY AND Categoria = @CatY AND @PerY = 8
       UPDATE #FactSector SET Cant8     = @NumY WHERE Grupo = @GruY AND Agente = @AgeY AND Categoria = @CatY AND @PerY = 8
       UPDATE #FactSector SET Importe9  = @ImpY WHERE Grupo = @GruY AND Agente = @AgeY AND Categoria = @CatY AND @PerY = 9
       UPDATE #FactSector SET Cant9     = @NumY WHERE Grupo = @GruY AND Agente = @AgeY AND Categoria = @CatY AND @PerY = 9
       UPDATE #FactSector SET Importe10 = @ImpY WHERE Grupo = @GruY AND Agente = @AgeY AND Categoria = @CatY AND @PerY = 10
       UPDATE #FactSector SET Cant10    = @NumY WHERE Grupo = @GruY AND Agente = @AgeY AND Categoria = @CatY AND @PerY = 10
       UPDATE #FactSector SET Importe11 = @ImpY WHERE Grupo = @GruY AND Agente = @AgeY AND Categoria = @CatY AND @PerY = 11
       UPDATE #FactSector SET Cant11    = @NumY WHERE Grupo = @GruY AND Agente = @AgeY AND Categoria = @CatY AND @PerY = 11
       UPDATE #FactSector SET Importe12 = @ImpY WHERE Grupo = @GruY AND Agente = @AgeY AND Categoria = @CatY AND @PerY = 12
       UPDATE #FactSector SET Cant12    = @NumY WHERE Grupo = @GruY AND Agente = @AgeY AND Categoria = @CatY AND @PerY = 12
     END
     FETCH NEXT FROM CrFac1 INTO @GruY, @AgeY, @CatY, @ImpY, @NumY, @PerY
   END
   CLOSE CrFac1
   DEALLOCATE CrFac1

Update #FactSector Set NomAgente=(Select Nombre From Agente Where Agente=#FactSector.Agente)
IF @Zona='METRO'  --add 02/05/17
   Begin
     SELECT * FROM #FactSector ORDER BY Grupo, NomAgente, Categoria, Cliente
   End
Else 
   IF @Zona<>'METRO' or @Zona IS NULL
      Begin
         SELECT * FROM #FactSector ORDER BY Grupo, Agente, Categoria, Cliente
	  End

END





