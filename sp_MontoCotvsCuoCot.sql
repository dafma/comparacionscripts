/****** Object:  StoredProcedure [dbo].[sp_MontoCotvsCuoCot]    Script Date: 05/07/2017 21:57:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER              Procedure [dbo].[sp_MontoCotvsCuoCot]
@Grupo		varchar(50),
@AgenteD	char(10),
@AgenteA	char(10),
@Ejercicio	int,
@Periodo	int,
@Empresa	char(5),
@Usuario 	Char(10),
-- modify 05/'5/17 @Familia 	Varchar(50),
@Sucursal int,
@Zona           Varchar(30) --cambiado/agregado para nuevo filtro Diciembre 2014

As
Begin
  IF @Empresa not in(Select Empresa From Empresa) or @Empresa in('','null','NULL')
     Begin
       Select @Empresa=null
     End
 IF @Grupo IN ('NULL', '', '0', '(Todos)') SELECT @Grupo = NULL
-- modify 05/'5/17 IF @Familia IN ('NULL', '', '0', '(Todos)') SELECT @Familia = NULL
  IF @Ejercicio = 0 SELECT @Ejercicio = YEAR(GETDATE())
  IF @Zona not in(Select Distinct Zona From Agente) or @Zona in('','null','NULL')
     Begin
       Select @Zona=null
     End
--sp_MontoCotvsCuoCot '(Todos)', 'AAM', 'ZZZZZZ', 2015, 1, 'LABC', 'GDA010', '(Todos)',1,'OCCIDENTE'

Declare
@Categoria VarChar(50),
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
@Cuota		money,
@FechaX			Datetime,
@CuotaDia		money,
@Familia 	Varchar(50)

IF Exists (Select * From SysObjects Where ID =Object_ID('dbo.FactCuotaC') And Type ='U')
Drop Table dbo.FactCuotaC

CREATE TABLE FactCuotaC (
Valor		Int		Null,
Empresa	char(5) null,
Grupo		varchar(50)	NULL,
Agente		char(10)	NULL,
AgenteNombre 	varchar(100)	NULL,
Mov 		char(30)	Null,
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

exec spValidaAgentesGABC
@Usuario,
@Empresa,
@Categoria OUTPUT,
@Familia OUTPUT,
@Grupo OUTPUT,
@AgenteD OUTPUT,
@AgenteA OUTPUT,
@Zona  OUTPUT --cambiado/agregado para nuevo filtro Diciembre 2014

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


Select v.ID, v.Agente, AgenteNombre=a.Nombre, a.Grupo, MovO=v.Mov, MovIDO=v.MovID, v.Cliente, CteNombre=c.Nombre, 
v.Estatus, v.FechaEmision, v.FechaInicioC, v.Importe,v.Empresa, 
Cuota = (SELECT Importe FROM TablaAnualD WHERE TablaAnual = a.Agente AND Ejercicio = @Ejercicio AND Periodo = @Periodo),
MovD=v1.Mov, MovIDD=v1.MovID, EstatusD=v1.Estatus, FechaEmisionD=v1.FechaEmision, ImporteD=v1.Importe,
Porcentaje=Case 
When v1.Mov='Cotizacion Concluida' And v1.FechaEmision Between @IniSemana1 And @UltimoDiaMes And v1.Estatus='CONCLUIDO'
Then 100 Else 0 End,
GanadosenTiempo=Case 
When v1.Mov='Cotizacion Concluida' And v1.FechaEmision Between @IniSemana1 And @UltimoDiaMes And v1.Estatus='CONCLUIDO'
Then 1 Else 0 End,
TotalGanados=Case 
When v1.Mov='Cotizacion Concluida' And v1.Estatus='CONCLUIDO'
Then 1 Else 0 End,
TotalPerdidos=Case 
When v1.Mov='Venta Perdida' And v1.Estatus='CONCLUIDO'
Then 1 Else 0 End,
ImporteGanados=Case 
When v1.Mov='Cotizacion Concluida' And v1.FechaEmision Between @IniSemana1 And @UltimoDiaMes And v1.Estatus='CONCLUIDO'
Then v.Importe Else 0 End,
TotalOrdenes=1
Into #Concentrado
From Venta v
Left Outer Join Venta v1 On v1.Origen=v.Mov And v1.OrigenID=v.MovID
Left Outer Join Agente a On a.Agente=v.Agente
Join Cte c On c.Cliente=v.Cliente
Where v.Mov='Cotización Cliente' And v.Estatus In ('CONCLUIDO', 'PENDIENTE', 'SINAFECTAR') And v.MovID Not Like '%-%'
--And v1.Estatus In('CONCLUIDO', Null)
And IsNull(a.Categoria, '') = IsNull(IsNull(@Categoria, a.Categoria), '')
-- modify 05/'5/17 And IsNull(a.Familia, '') = IsNull(IsNull(@Familia, a.Familia), '')
And IsNull(a.Grupo, '') = IsNull(IsNull(@Grupo, a.Grupo), '')
And a.Agente Between @AgenteD And @AgenteA
And a.Zona=Isnull(@Zona,a.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
And v.Empresa=Isnull(@Empresa,v.Empresa) And v.Periodo=@Periodo
And IsNull(v.Sucursal, '') = IsNull(IsNull(@Sucursal, v.Sucursal), '')
Order By v.Agente, v.MovID
--SELECT * FROM #Concentrado---QUITAR QUITAR QUITAR
--sp_MontoCotvsCuoCot '(Todos)', 'AAM', 'ZZZZZZ', 2015, 1, 'LABC', 'GDA010', '(Todos)',1,'OCCIDENTE'

INSERT FactCuotaC (Valor,Empresa, Agente, AgenteNombre, Grupo, Mov, Importe1, FechaD1, FechaA1, Importe2, FechaD2, FechaA2, Importe3, FechaD3, FechaA3, Importe4, FechaD4, FechaA4, Importe5, FechaD5, FechaA5)

-- SE INSERTA LA CUOTA TRIPLEPLICADA
Select 10, Empresa,Agente, AgenteNombre, Grupo, 'CUOTA TRIPLE POR COTIZAR', Cuota*3 / Day(@UltimoDiaMes)* @Dias1, @IniSemana1, @FinSemana1, Null, @IniSemana2, @FinSemana2, Null, @IniSemana3, @FinSemana3, Null, @IniSemana4, @FinSemana4, Null, @IniSemana5, @FinSemana5 From #Concentrado
Union
Select 10, Empresa,Agente, AgenteNombre, Grupo, 'CUOTA TRIPLE POR COTIZAR', Null, @IniSemana1, @FinSemana1, Cuota*3 / Day(@UltimoDiaMes)* @Dias2, @IniSemana2, @FinSemana2, Null, @IniSemana3, @FinSemana3, Null, @IniSemana4, @FinSemana4, Null, @IniSemana5, @FinSemana5 From #Concentrado
Union
Select 10, Empresa,Agente, AgenteNombre, Grupo, 'CUOTA TRIPLE POR COTIZAR', Null, @IniSemana1, @FinSemana1, Null, @IniSemana2, @FinSemana2, Cuota*3 / Day(@UltimoDiaMes)* @Dias3, @IniSemana3, @FinSemana3, Null, @IniSemana4, @FinSemana4, Null, @IniSemana5, @FinSemana5 From #Concentrado
Union
Select 10, Empresa,Agente, AgenteNombre, Grupo, 'CUOTA TRIPLE POR COTIZAR', Null, @IniSemana1, @FinSemana1, Null, @IniSemana2, @FinSemana2, Null, @IniSemana3, @FinSemana3, Cuota*3 / Day(@UltimoDiaMes)* @Dias4, @IniSemana4, @FinSemana4, Null, @IniSemana5, @FinSemana5 From #Concentrado
Union
Select 10, Empresa,Agente, AgenteNombre, Grupo, 'CUOTA TRIPLE POR COTIZAR', Null, @IniSemana1, @FinSemana1, Null, @IniSemana2, @FinSemana2, Null, @IniSemana3, @FinSemana3, Null, @IniSemana4, @FinSemana4, Cuota*3 / Day(@UltimoDiaMes)* @Dias5, @IniSemana5, @FinSemana5 From #Concentrado
Union
-- SE INSERTA LA CUOTA DE COTIZACIONES
Select 20, Agente, AgenteNombre,Empresas, Grupo, MovO, Sum(Importe), @IniSemana1, @FinSemana1, Null, @IniSemana2, @FinSemana2, Null, @IniSemana3, @FinSemana3, Null, @IniSemana4, @FinSemana4, Null, @IniSemana5, @FinSemana5 From #Concentrado Where FechaEmision Between @IniSemana1 AND @FinSemana1 And MovO='Cotización Cliente'
Group By Agente, AgenteNombre,Empresa, Grupo, MovO
Union
Select 20, Agente, AgenteNombre, Empresa,Grupo, MovO, Null, @IniSemana1, @FinSemana1, Sum(Importe), @IniSemana2, @FinSemana2, Null, @IniSemana3, @FinSemana3, Null, @IniSemana4, @FinSemana4, Null, @IniSemana5, @FinSemana5 From #Concentrado Where FechaEmision Between @IniSemana2 AND @FinSemana2 And MovO='Cotización Cliente'
Group By Agente, AgenteNombre, Empresa,Grupo, MovO
Union
Select 20, Agente, AgenteNombre, Empresa,Grupo, MovO, Null, @IniSemana1, @FinSemana1, Null, @IniSemana2, @FinSemana2, Sum(Importe), @IniSemana3, @FinSemana3, Null, @IniSemana4, @FinSemana4, Null, @IniSemana5, @FinSemana5 From #Concentrado Where FechaEmision Between @IniSemana3 AND @FinSemana3 And MovO='Cotización Cliente'
Group By Agente, AgenteNombre, Empresa,Grupo, MovO
Union
Select 20, Agente, AgenteNombre, Empresa,Grupo, MovO, Null, @IniSemana1, @FinSemana1, Null, @IniSemana2, @FinSemana2, Null, @IniSemana3, @FinSemana3, Sum(Importe), @IniSemana4, @FinSemana4, Null, @IniSemana5, @FinSemana5 From #Concentrado Where FechaEmision Between @IniSemana4 AND @FinSemana4 And MovO='Cotización Cliente'
Group By Agente, AgenteNombre, Empresa,Grupo, MovO
Union
Select 20, Agente, AgenteNombre, Empresa,Grupo, MovO, Null, @IniSemana1, @FinSemana1, Null, @IniSemana2, @FinSemana2, Null, @IniSemana3, @FinSemana3, Null, @IniSemana4, @FinSemana4, Sum(Importe), @IniSemana5, @FinSemana5 From #Concentrado Where FechaEmision Between @IniSemana5 AND @FinSemana5 And MovO='Cotización Cliente'
Group By Agente, AgenteNombre, Empresa,Grupo, MovO
Union

-- SE INSERTA LOS PORCENTAJES ALCANZADOS

Select 25, Agente, AgenteNombre,Empresa, Grupo, '% ALCANZADO TRIPLE', (Sum(Importe) * 100) / (Cuota * 3 / Day(@UltimoDiaMes)* @Dias1), @IniSemana1, @FinSemana1, Null, @IniSemana2, @FinSemana2, Null, @IniSemana3, @FinSemana3, Null, @IniSemana4, @FinSemana4, Null, @IniSemana5, @FinSemana5 From #Concentrado Where FechaEmision Between @IniSemana1 AND @FinSemana1 And MovO='Cotización Cliente'
Group By Agente, AgenteNombre, Empresa,Grupo, Cuota
Union
Select 25, Agente, AgenteNombre, Empresa,Grupo, '% ALCANZADO TRIPLE', Null, @IniSemana1, @FinSemana1, (Sum(Importe) * 100) / (Cuota * 3 / Day(@UltimoDiaMes)* @Dias2), @IniSemana2, @FinSemana2, Null, @IniSemana3, @FinSemana3, Null, @IniSemana4, @FinSemana4, Null, @IniSemana5, @FinSemana5 From #Concentrado Where FechaEmision Between @IniSemana2 AND @FinSemana2 And MovO='Cotización Cliente'
Group By Agente, AgenteNombre, Empresa,Grupo, Cuota
Union
Select 25, Agente, AgenteNombre, Empresa,Grupo, '% ALCANZADO TRIPLE', Null, @IniSemana1, @FinSemana1, Null, @IniSemana2, @FinSemana2, (Sum(Importe) * 100) / (Cuota * 3 / Day(@UltimoDiaMes)* @Dias3), @IniSemana3, @FinSemana3, Null, @IniSemana4, @FinSemana4, Null, @IniSemana5, @FinSemana5 From #Concentrado Where FechaEmision Between @IniSemana3 AND @FinSemana3 And MovO='Cotización Cliente'
Group By Agente, AgenteNombre, Empresa,Grupo, Cuota
Union
Select 25, Agente, AgenteNombre, Empresa,Grupo, '% ALCANZADO TRIPLE', Null, @IniSemana1, @FinSemana1, Null, @IniSemana2, @FinSemana2, Null, @IniSemana3, @FinSemana3, (Sum(Importe) * 100) / (Cuota * 3 / Day(@UltimoDiaMes)* @Dias4), @IniSemana4, @FinSemana4, Null, @IniSemana5, @FinSemana5 From #Concentrado Where FechaEmision Between @IniSemana4 AND @FinSemana4 And MovO='Cotización Cliente'
Group By Agente, AgenteNombre, Empresa,Grupo, Cuota
Union
Select 25, Agente, AgenteNombre, Empresa,Grupo, '% ALCANZADO TRIPLE', Null, @IniSemana1, @FinSemana1, Null, @IniSemana2, @FinSemana2, Null, @IniSemana3, @FinSemana3, Null, @IniSemana4, @FinSemana4, (Sum(Importe) * 100) / (Cuota * 3 / Day(@UltimoDiaMes)* @Dias5), @IniSemana5, @FinSemana5 From #Concentrado Where FechaEmision Between @IniSemana5 AND @FinSemana5 And MovO='Cotización Cliente'
Group By Agente, AgenteNombre, Empresa,Grupo, Cuota
Union
-- SE INSERTA LA CUOTA SENCILLA
Select 30, Agente, AgenteNombre, Empresa,Grupo, 'CUOTA SENCILLA POR COTIZAR', Cuota / Day(@UltimoDiaMes)* @Dias1, @IniSemana1, @FinSemana1, Null, @IniSemana2, @FinSemana2, Null, @IniSemana3, @FinSemana3, Null, @IniSemana4, @FinSemana4, Null, @IniSemana5, @FinSemana5 From #Concentrado
Union
Select 30, Agente, AgenteNombre, Empresa,Grupo, 'CUOTA SENCILLA POR COTIZAR', Null, @IniSemana1, @FinSemana1, Cuota / Day(@UltimoDiaMes)* @Dias2, @IniSemana2, @FinSemana2, Null, @IniSemana3, @FinSemana3, Null, @IniSemana4, @FinSemana4, Null, @IniSemana5, @FinSemana5 From #Concentrado
Union
Select 30, Agente, AgenteNombre, Empresa,Grupo, 'CUOTA SENCILLA POR COTIZAR', Null, @IniSemana1, @FinSemana1, Null, @IniSemana2, @FinSemana2, Cuota / Day(@UltimoDiaMes)* @Dias3, @IniSemana3, @FinSemana3, Null, @IniSemana4, @FinSemana4, Null, @IniSemana5, @FinSemana5 From #Concentrado
Union
Select 30, Agente, AgenteNombre, Empresa,Grupo, 'CUOTA SENCILLA POR COTIZAR', Null, @IniSemana1, @FinSemana1, Null, @IniSemana2, @FinSemana2, Null, @IniSemana3, @FinSemana3, Cuota / Day(@UltimoDiaMes)* @Dias4, @IniSemana4, @FinSemana4, Null, @IniSemana5, @FinSemana5 From #Concentrado
Union
Select 30, Agente, AgenteNombre, Empresa,Grupo, 'CUOTA SENCILLA POR COTIZAR', Null, @IniSemana1, @FinSemana1, Null, @IniSemana2, @FinSemana2, Null, @IniSemana3, @FinSemana3, Null, @IniSemana4, @FinSemana4, Cuota / Day(@UltimoDiaMes)* @Dias5, @IniSemana5, @FinSemana5 From #Concentrado

-- SE INSERTA LA CUOTA COTIZACIONES CONCLUIDAS
Union
Select 40, Agente, AgenteNombre, Empresa,Grupo, MovD, Sum(ImporteD), @IniSemana1, @FinSemana1, Null, @IniSemana2, @FinSemana2, Null, @IniSemana3, @FinSemana3, Null, @IniSemana4, @FinSemana4, Null, @IniSemana5, @FinSemana5 From #Concentrado Where FechaEmisionD Between @IniSemana1 AND @FinSemana1 And MovD='Cotizacion Concluida' And EstatusD='CONCLUIDO'
Group By Agente, AgenteNombre, Empresa,Grupo, MovD
Union
Select 40, Agente, AgenteNombre, Empresa,Grupo, MovD, Null, @IniSemana1, @FinSemana1, Sum(ImporteD), @IniSemana2, @FinSemana2, Null, @IniSemana3, @FinSemana3, Null, @IniSemana4, @FinSemana4, Null, @IniSemana5, @FinSemana5 From #Concentrado Where FechaEmisionD Between @IniSemana2 AND @FinSemana2 And MovD='Cotizacion Concluida' And EstatusD='CONCLUIDO'
Group By Agente, AgenteNombre, Empresa,Grupo, MovD
Union
Select 40, Agente, AgenteNombre, Empresa,Grupo, MovD, Null, @IniSemana1, @FinSemana1, Null, @IniSemana2, @FinSemana2, Sum(ImporteD), @IniSemana3, @FinSemana3, Null, @IniSemana4, @FinSemana4, Null, @IniSemana5, @FinSemana5 From #Concentrado Where FechaEmisionD Between @IniSemana3 AND @FinSemana3 And MovD='Cotizacion Concluida' And EstatusD='CONCLUIDO'
Group By Agente, AgenteNombre, Empresa,Grupo, MovD
Union
Select 40, Agente, AgenteNombre, Empresa,Grupo, MovD, Null, @IniSemana1, @FinSemana1, Null, @IniSemana2, @FinSemana2, Null, @IniSemana3, @FinSemana3, Sum(ImporteD), @IniSemana4, @FinSemana4, Null, @IniSemana5, @FinSemana5 From #Concentrado Where FechaEmisionD Between @IniSemana4 AND @FinSemana4 And MovD='Cotizacion Concluida' And EstatusD='CONCLUIDO'
Group By Agente, AgenteNombre, Empresa,Grupo, MovD
Union
Select 40, Agente, AgenteNombre, Empresa,Grupo, MovD, Null, @IniSemana1, @FinSemana1, Null, @IniSemana2, @FinSemana2, Null, @IniSemana3, @FinSemana3, Null, @IniSemana4, @FinSemana4, Sum(ImporteD), @IniSemana5, @FinSemana5 From #Concentrado Where FechaEmisionD Between @IniSemana5 AND @FinSemana5 And MovD='Cotizacion Concluida' And EstatusD='CONCLUIDO'
Group By Agente, AgenteNombre, Empresa,Grupo, MovD
-- SE INSERTA EL PORCENTAJE ALCANZADO ENTRE COTIZACIONES CONCLUIDAS Y CUOTA SENCILLA
Union
Select 45, Agente, AgenteNombre, Empresa,Grupo, '% ALCANZADO SENCILLO', (Sum(ImporteD) * 100) / (Cuota / Day(@UltimoDiaMes)* @Dias1), @IniSemana1, @FinSemana1, Null, @IniSemana2, @FinSemana2, Null, @IniSemana3, @FinSemana3, Null, @IniSemana4, @FinSemana4, Null, @IniSemana5, @FinSemana5 From #Concentrado Where FechaEmisionD Between @IniSemana1 AND @FinSemana1 And MovD='Cotizacion Concluida' And EstatusD='CONCLUIDO'
Group By Agente, AgenteNombre, Empresa,Grupo, Cuota
Union
Select 45, Agente, AgenteNombre, Empresa,Grupo, '% ALCANZADO SENCILLO', Null, @IniSemana1, @FinSemana1, (Sum(ImporteD) * 100) / (Cuota / Day(@UltimoDiaMes)* @Dias2), @IniSemana2, @FinSemana2, Null, @IniSemana3, @FinSemana3, Null, @IniSemana4, @FinSemana4, Null, @IniSemana5, @FinSemana5 From #Concentrado Where FechaEmisionD Between @IniSemana2 AND @FinSemana2 And MovD='Cotizacion Concluida' And EstatusD='CONCLUIDO'
Group By Agente, AgenteNombre, Empresa,Grupo, Cuota
Union
Select 45, Agente, AgenteNombre, Empresa,Grupo, '% ALCANZADO SENCILLO', Null, @IniSemana1, @FinSemana1, Null, @IniSemana2, @FinSemana2, (Sum(ImporteD) * 100) / (Cuota / Day(@UltimoDiaMes)* @Dias3), @IniSemana3, @FinSemana3, Null, @IniSemana4, @FinSemana4, Null, @IniSemana5, @FinSemana5 From #Concentrado Where FechaEmisionD Between @IniSemana3 AND @FinSemana3 And MovD='Cotizacion Concluida' And EstatusD='CONCLUIDO'
Group By Agente, AgenteNombre, Empresa,Grupo, Cuota
Union
Select 45, Agente, AgenteNombre, Empresa,Grupo, '% ALCANZADO SENCILLO', Null, @IniSemana1, @FinSemana1, Null, @IniSemana2, @FinSemana2, Null, @IniSemana3, @FinSemana3, (Sum(ImporteD) * 100) / (Cuota / Day(@UltimoDiaMes)* @Dias4), @IniSemana4, @FinSemana4, Null, @IniSemana5, @FinSemana5 From #Concentrado Where FechaEmisionD Between @IniSemana4 AND @FinSemana4 And MovD='Cotizacion Concluida' And EstatusD='CONCLUIDO'
Group By Agente, AgenteNombre, Empresa,Grupo, Cuota
Union
Select 45, Agente, AgenteNombre, Empresa,Grupo, '% ALCANZADO SENCILLO', Null, @IniSemana1, @FinSemana1, Null, @IniSemana2, @FinSemana2, Null, @IniSemana3, @FinSemana3, Null, @IniSemana4, @FinSemana4, (Sum(ImporteD) * 100) / (Cuota / Day(@UltimoDiaMes)* @Dias5), @IniSemana5, @FinSemana5 From #Concentrado Where FechaEmisionD Between @IniSemana5 AND @FinSemana5 And MovD='Cotizacion Concluida' And EstatusD='CONCLUIDO'
Group By Agente, AgenteNombre, Empresa,Grupo, Cuota
Union

-- SE INSERTA LA CUOTA DE VENTAS PERDIDAS
Select 50, Agente, AgenteNombre, Empresa,Grupo, MovD, Sum(ImporteD), @IniSemana1, @FinSemana1, Null, @IniSemana2, @FinSemana2, Null, @IniSemana3, @FinSemana3, Null, @IniSemana4, @FinSemana4, Null, @IniSemana5, @FinSemana5 From #Concentrado Where FechaEmisionD Between @IniSemana1 AND @FinSemana1 And MovD='Venta Perdida' And EstatusD='CONCLUIDO'
Group By Agente, AgenteNombre, Empresa,Grupo, MovD
Union
Select 50, Agente, AgenteNombre, Empresa,Grupo, MovD, Null, @IniSemana1, @FinSemana1, Sum(ImporteD), @IniSemana2, @FinSemana2, Null, @IniSemana3, @FinSemana3, Null, @IniSemana4, @FinSemana4, Null, @IniSemana5, @FinSemana5 From #Concentrado Where FechaEmisionD Between @IniSemana2 AND @FinSemana2 And MovD='Venta Perdida' And EstatusD='CONCLUIDO'
Group By Agente, AgenteNombre, Empresa,Grupo, MovD
Union
Select 50, Agente, AgenteNombre, Empresa,Grupo, MovD, Null, @IniSemana1, @FinSemana1, Null, @IniSemana2, @FinSemana2, Sum(ImporteD), @IniSemana3, @FinSemana3, Null, @IniSemana4, @FinSemana4, Null, @IniSemana5, @FinSemana5 From #Concentrado Where FechaEmisionD Between @IniSemana3 AND @FinSemana3 And MovD='Venta Perdida' And EstatusD='CONCLUIDO'
Group By Agente, AgenteNombre, Empresa,Grupo, MovD
Union
Select 50, Agente, AgenteNombre, Empresa,Grupo, MovD, Null, @IniSemana1, @FinSemana1, Null, @IniSemana2, @FinSemana2, Null, @IniSemana3, @FinSemana3, Sum(ImporteD), @IniSemana4, @FinSemana4, Null, @IniSemana5, @FinSemana5 From #Concentrado Where FechaEmisionD Between @IniSemana4 AND @FinSemana4 And MovD='Venta Perdida' And EstatusD='CONCLUIDO'
Group By Agente, AgenteNombre, Empresa,Grupo, MovD
Union
Select 50, Agente, AgenteNombre, Empresa,Grupo, MovD, Null, @IniSemana1, @FinSemana1, Null, @IniSemana2, @FinSemana2, Null, @IniSemana3, @FinSemana3, Null, @IniSemana4, @FinSemana4, Sum(ImporteD), @IniSemana5, @FinSemana5 From #Concentrado Where FechaEmisionD Between @IniSemana5 AND @FinSemana5 And MovD='Venta Perdida' And EstatusD='CONCLUIDO'
Group By Agente, AgenteNombre, Empresa,Grupo, MovD

Update FactCuotaC Set Mov='MONTO REAL COTIZADO' Where Mov='Cotización Cliente'
Update FactCuotaC Set Mov='CUOTA SENC. POR CERRAR' Where Mov='CUOTA SENCILLA POR COTIZAR'
Update FactCuotaC Set Mov='COTIZACIONES CERRADAS' Where Mov='Cotizacion Concluida'
Update FactCuotaC Set Mov='% ALCANZADO' Where Mov='% ALCANZADO SENCILLO'
Update FactCuotaC Set Mov='MONTO VENTA PERDIDA' Where Mov='Venta Perdida'

IF @Zona='METRO'
   Begin
     Select Valor, Grupo, AgenteNombre, Empresa,Mov, 
		Importe1=Sum(Importe1), FechaD1, FechaA1,
		Importe2=Sum(Importe2), FechaD2, FechaA2,
		Importe3=Sum(Importe3), FechaD3, FechaA3,
		Importe4=Sum(Importe4), FechaD4, FechaA4,
		Importe5=Sum(Importe5), FechaD5, FechaA5
		From FactCuotaC
		Group By Valor, Grupo, AgenteNombre, Empresa,Mov, 
		FechaD1, FechaA1, 
		FechaD2, FechaA2, 
		FechaD3, FechaA3, 
		FechaD4, FechaA4, 
		FechaD5, FechaA5 
		Order By Grupo, AgenteNombre, Empresa,Valor		
   End
Else 
   IF @Zona<>'METRO' or @Zona IS NULL
      Begin
		Select Valor, Grupo, Agente, AgenteNombre, Mov, 
		Importe1=Sum(Importe1), FechaD1, FechaA1,
		Importe2=Sum(Importe2), FechaD2, FechaA2,
		Importe3=Sum(Importe3), FechaD3, FechaA3,
		Importe4=Sum(Importe4), FechaD4, FechaA4,
		Importe5=Sum(Importe5), FechaD5, FechaA5
		From FactCuotaC
		Group By Valor, Grupo, Agente, AgenteNombre, Mov, 
		FechaD1, FechaA1, 
		FechaD2, FechaA2, 
		FechaD3, FechaA3, 
		FechaD4, FechaA4, 
		FechaD5, FechaA5 
		Order By Grupo, Agente, Valor
	  End
End









