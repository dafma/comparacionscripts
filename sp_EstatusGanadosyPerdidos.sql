/****** Object:  StoredProcedure [dbo].[sp_EstatusGanadosyPerdidos]    Script Date: 05/05/2017 15:42:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER    Procedure [dbo].[sp_EstatusGanadosyPerdidos]
@Usuario Char(10),
-- modify 05/05/17 @Familia Varchar(50),
@Grupo varchar(50),
@AgenteD char(10),
@AgenteA char(10),     
@FechaD Datetime,
@FechaA Datetime,
@Empresa char(5),
@Sucursal int,
@Zona           Varchar(30) --cambiado/agregado para nuevo filtro Diciembre 2014
As
Begin

--select @Usuario='GVT'
Declare
@Categoria VarChar(50),
@Familia Varchar(50)

--Select @Sucursal=NullIF(@Sucursal, '')

exec spValidaAgentesGABC
@Usuario,
@Empresa,
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
     
Create Table #Movs(
ID Int Null,
Agente char(10) Null,
AgenteNombre char(100) Null,
Movimiento varchar(40) Null,
Cliente char(10) Null,
CteNombre varchar(100) Null,
Empresa char(5) null,
Estatus char(15) Null,
FechaEmision datetime Null,
FechaInicioO datetime Null,
FechaInicioC datetime Null,
Importe Money Null,
MovimientoD varchar(40) Null,
EstatusD char(15) Null,
FechaEmisionD datetime Null,
Porcentaje int Null,
GanadosenTiempo int Null,
TotalGanados Int Null,
TotalPerdidos Int Null,
ImporteGanados Money Null,
ImportePerdidos Money Null,
TotalOrdenes int Null)


Insert Into #Movs
Select v.ID, v.Agente, AgenteNombre=a.Nombre, Movimiento=(Ltrim(Rtrim(v.Mov))+' '+Ltrim(Rtrim(v.MovID))), v.Cliente, 
CteNombre=c.Nombre,v.Empresa, 
v.Estatus,
 v.FechaEmision, 
FechaInicioO=v.FechaInicioC,
FechaInicioC=DateAdd(day, 10, v.FechaInicioC), v.Importe,
MovimientoD=(Ltrim(Rtrim(v1.Mov))+' '+Ltrim(Rtrim(v1.MovID))), EstatusD=v1.Estatus, FechaEmisionD=v1.FechaEmision, 
Porcentaje=Case 
When v1.Mov='Cotizacion Concluida' And v1.FechaEmision <=DateAdd(day, 10, v.FechaInicioC) And v1.Estatus='CONCLUIDO'
Then 100 Else 0 End,
GanadosenTiempo=Case 
When v1.Mov='Cotizacion Concluida' And v1.FechaEmision <=DateAdd(day, 10, v.FechaInicioC) And v1.Estatus='CONCLUIDO' And v1.Estatus='CONCLUIDO'
Then 1 Else 0 End,
TotalGanados=Case 
When v1.Mov='Cotizacion Concluida' And v1.Estatus='CONCLUIDO'
Then 1 Else 0 End,
TotalPerdidos=Case 
When v1.Mov='Venta Perdida' And v1.Estatus='CONCLUIDO'
Then 1 Else 0 End,
ImporteGanados=Case 
When v1.Mov='Cotizacion Concluida' --And v1.FechaEmision <=DateAdd(day, 10, v.FechaInicioC) And v1.Estatus='CONCLUIDO'
Then v.Importe Else 0 End,
ImportePerdidos=Case 
When v1.Mov='Venta Perdida'  And v1.Estatus='CONCLUIDO'
Then v.Importe Else 0 End,
TotalOrdenes=1
From Venta v
Join Venta v1 On v1.Origen=v.Mov And v1.OrigenID=v.MovID And v1.Empresa=Isnull(@Empresa,v1.Empresa) And v1.Mov in ('Cotizacion Concluida', 'Venta Perdida') And v1.Estatus ='CONCLUIDO'
And IsNull(v1.Sucursal, '') = IsNull(IsNull(@Sucursal, v1.Sucursal), '')
Left Outer Join Agente a On a.Agente=v.Agente
Join Cte c On c.Cliente=v.Cliente
Where v.Mov='Cotización Cliente' And v.Estatus In ('CONCLUIDO', 'PENDIENTE', 'SINAFECTAR') And v.MovID Not Like '%-%'
--And v1.Estatus In('CONCLUIDO', Null)
--And IsNull(a.Categoria, '') = IsNull(IsNull(@Categoria, a.Categoria), '')
-- modify 05/05/17 And IsNull(a.Familia, '') = IsNull(IsNull(@Familia, a.Familia), '')
And IsNull(a.Grupo, '') = IsNull(IsNull(@Grupo, a.Grupo), '')
And a.Agente Between @AgenteD And @AgenteA
And a.Zona=Isnull(@Zona,a.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
And v.Empresa=Isnull(@Empresa,v.Empresa) And v.FechaInicioC Between @FechaD And @FechaA
And IsNull(v.Sucursal, '') = IsNull(IsNull(@Sucursal, v.Sucursal), '')
Order By v.Agente, v.FechaInicioC

--sp_EstatusGanadosyPerdidos 'GVT', '(Todos)', '(Todos)', 'MAC', 'MAC', '01-05-2008', '31-05-2008', 'LABC', 1

IF @Zona='METRO'
   Begin
     Select * From #Movs Order By AgenteNombre, FechaInicioC -- Where MovimientoD Is Not Null
   End
Else 
   IF @Zona<>'METRO' or @Zona IS NULL
      Begin
         Select * From #Movs-- Where MovimientoD Is Not Null
	  End
End










