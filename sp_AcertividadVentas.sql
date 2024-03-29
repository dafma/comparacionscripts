/****** Object:  StoredProcedure [dbo].[sp_AcertividadVentas]    Script Date: 04/24/2017 16:19:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER           Procedure [dbo].[sp_AcertividadVentas]
@Usuario Char(10),
@Familia Varchar(50),
@Grupo varchar(50),
@AgenteD char(10),
@AgenteA char(10),     
@FechaD Datetime,
@FechaA Datetime,
@Empresa char(5),
@Sucursal int,
@Zona Varchar(30) --cambiado/agregado para nuevo filtro Diciembre 2014
As
Begin

--select @Usuario='GVT'

Declare
@Categoria VarChar(50),
@ID int,
@Cumplimiento int,
@Importe money

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
--Select @Sucursal=NullIF(@Sucursal, '')

Select v.ID, v.Agente, AgenteNombre=a.Nombre, Movimiento=(Ltrim(Rtrim(v.Mov))+' '+Ltrim(Rtrim(v.MovID))), v.Cliente, CteNombre=c.Nombre, v.Estatus, v.FechaEmision, 
FechaInicioO=v.FechaInicioC,v.Empresa,
FechaInicioC=DateAdd(day, 10, v.FechaInicioC), v.Importe, ImporteP=Cast(0 As Money),
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
When v1.Mov='Cotizacion Concluida' And v1.FechaEmision <=DateAdd(day, 10, v.FechaInicioC) And v1.Estatus='CONCLUIDO'
Then v.Importe Else 0 End,
TotalOrdenes=1
Into #Acertividad
From Venta v
Left Outer Join Venta v1 On v1.Origen=v.Mov And v1.OrigenID=v.MovID And v1.Empresa=Isnull(@Empresa,v1.Empresa)
And IsNull(v1.Sucursal, '') = IsNull(IsNull(@Sucursal, v1.Sucursal), '')
Left Outer Join Agente a On a.Agente=v.Agente
Join Cte c On c.Cliente=v.Cliente
Where v.Mov='Cotización Cliente' And v.Estatus In ('CONCLUIDO', 'PENDIENTE', 'SINAFECTAR') And v.MovID Not Like '%-%'
--And v1.Estatus In('CONCLUIDO', Null)
--And IsNull(a.Categoria, '') = IsNull(IsNull(@Categoria, a.Categoria), '')
And IsNull(a.Familia, '') = IsNull(IsNull(@Familia, a.Familia), '')
And IsNull(a.Grupo, '') = IsNull(IsNull(@Grupo, a.Grupo), '')
And a.Zona=Isnull(@Zona,a.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
And a.Agente Between @AgenteD And @AgenteA
And v.Empresa=Isnull(@Empresa,v.Empresa)
And IsNull(v.Sucursal, '') = IsNull(IsNull(@Sucursal, v.Sucursal), '') --And v.FechaInicioC Between @FechaD And @FechaA
Order By v.Agente, v.FechaInicioC

Declare CrProb Cursor For
Select ID, Importe From #Acertividad
Open CrProb
Fetch Next From CrProb Into @ID, @Importe
While @@Fetch_Status <> - 1 And @@Error=0
Begin
	IF @@Fetch_Status <> - 2
	Begin
	IF Exists (Select * From CrmVentas Where IDVentas=@ID)
	Begin
	  Select @Cumplimiento = (Select Top 1 Cumplimiento From CrmVentas Where IDVentas=@ID And Cumplimiento Is Not Null Order by Fechaemision Desc)
	  IF @Cumplimiento <> 0
	  Begin
	    Update #Acertividad Set ImporteP=((@Importe*@Cumplimiento)/100) Where ID=@ID
	  End
	End
	End
Fetch Next From CrProb Into @ID, @Importe
End
Close CrProb
Deallocate CrProb

IF @Zona='METRO'
   Begin
     Select * From #Acertividad Where FechaInicioC Between @FechaD And @FechaA Order by AgenteNombre, Movimiento
   End
Else 
   IF @Zona<>'METRO'
      Begin
         Select * From #Acertividad Where FechaInicioC Between @FechaD And @FechaA Order by Agente, FechaInicioC
	  End


--sp_AcertividadVentas 'GVT', '(Todos)', '(Todos)', 'AMO', 'RJM', '01-03-2008', '31-03-2008', 'LABC', 0

	    
End




