/****** Object:  StoredProcedure [dbo].[sp_Retrasos_Ordenes]    Script Date: 05/08/2017 11:37:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


--sp_Retrasos_Ordenes 'LABC', 'GVT', '01-08-2007', '31-08-2007', 'AMO', 'RJM', '(Todos)', '(Todos)', ''

ALTER      Procedure [dbo].[sp_Retrasos_Ordenes]
@Empresa char(5),
@Usuario char(10),
@FechaD DateTime,
@FechaA DateTime,
@AgenteD char(10),
@AgenteA char(10),
-- modify 05/05/17 @Familia Varchar(50),
@Grupo varchar(50),
@Sucursal int,
@Zona           Varchar(30) --cambiado/agregado para nuevo filtro Diciembre 2014
As
Begin


Create Table #Ordenes_Conc(
Agente char(10) Null,
AgenteNombre varchar(100) Null,
Empresa char(5) null,
Mov char(20) Null,
MovID varchar(20) Null,
Estatus char(15) Null,
FechaEmision DateTime Null,
FechaComenzo DateTime Null,
Nombre varchar(100) Null,
EnTiempo Money Null,
D5A7Dias Money Null,
D8A10Dias Money Null,
D11A15Dias Money Null,
D16A30Dias Money Null,
D31A60Dias Money Null,
Mas60Dias Money Null,
TotalXAgente Int Null,
TotalEnTiempo Int Null,
Situacion Varchar(50) null)

Declare
@Hoy DateTime,
@ID Int,
@FechaI DateTime,
@FechaF DateTime,
@FechaComenzo DateTime,
@Situacion varchar(50),
@Mov char(20),
@MovID varchar(20),
@FechaEmision DateTime,
@Nombre varchar(100),
@Dias Int,
@ImporteTotal Money,
@Agente char(10),
@AgenteNombre varchar(100),
@Estatus char(15),
@Categoria VarChar(50),
@Familia Varchar(50)


-- modify 05/05/17 Execute spValidaAgentesGABC @Usuario, @Empresa, @Categoria OUTPUT, @Familia OUTPUT, @Grupo OUTPUT, @AgenteD OUTPUT, @AgenteA OUTPUT,@Zona  OUTPUT --cambiado/agregado para nuevo filtro Diciembre 2014

Execute spValidaAgentesGABC 
@Usuario, 
@Empresa,
@Categoria OUTPUT,
@Grupo OUTPUT, 
@AgenteD OUTPUT, 
@AgenteA OUTPUT,
@Zona  OUTPUT, --cambiado/agregado para nuevo filtro Diciembre 2014
@Familia OUTPUT

  IF @Empresa not in(Select Empresa From Empresa) or @Empresa in('','null','NULL')
     Begin
       Select @Empresa=null
     End
  IF @Zona not in(Select Distinct Zona From Agente) or @Zona in('','null','NULL')
     Begin
       Select @Zona=null
     End
--Select @Sucursal=NullIF(@Sucursal, '')

Select @Hoy=GetDate()

Select v.ID, v.Empresa, v.Mov, v.MovID, v.Cliente, Cte.Nombre, v.Agente, AgenteNom=Agente.Nombre, v.Situacion, v.Estatus, 
v.FechaEmision,FechaComenzo=@Hoy, Dias=0, Hoy=@Hoy, ImporteTotal=(v.Importe + v.Impuestos)*v.TipoCambio
Into #Orden
From Venta v
Join Cte On Cte.Cliente=v.Cliente
Left Outer Join Agente On Agente.Agente=v.Agente
Where v.Mov='Orden Facturacion' And v.Estatus In ('SINAFECTAR', 'PENDIENTE')
--And FechaEmision Between @FechaD And @FechaA 
And v.Empresa=Isnull(@Empresa,v.Empresa) 
And IsNull(v.Sucursal, '') = IsNull(IsNull(@Sucursal, v.Sucursal), '')
--And IsNull(Agente.Categoria, '') = IsNull(IsNull(@Categoria, Agente.Categoria), '')
-- modify 05/05/17 And IsNull(Agente.Familia, '') = IsNull(IsNull(@Familia, Agente.Familia), '')
And IsNull(Agente.Grupo, '') = IsNull(IsNull(@Grupo, Agente.Grupo), '')
AND v.Agente Between @AgenteD AND @AgenteA
And Agente.Zona=Isnull(@Zona,Agente.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
And (v.Situacion Not In ('ACEPTADO POR  RyF','BAJA DE ORDEN', 'FACTURACION DIFERENTE','NO COBRADAS','MAQUILA','MAQUILA FERMI','MAQUILA ABC') Or v.Situacion IS Null)
Order by v.Situacion

Declare CrOrden Cursor For
Select ID, FechaEmision, FechaComenzo, Situacion From #Orden
Open CrOrden
Fetch Next From CrOrden Into
@ID, @FechaI, @FechaF, @Situacion
While @@Fetch_Status <> - 1 And @@Error=0
Begin
  IF @@Fetch_Status <> - 2
  Begin
--    IF @Situacion Is Not Null
--    Begin
--	Select @FechaComenzo=(Select Top 1 FechaComenzo From MovTiempo Where Modulo='VTAS' And ID=@ID Order By IDOrden Desc)
--	Update #Orden Set FechaComenzo=@FechaComenzo Where ID=@ID
--	Update #Orden Set Dias=DateDiff(day, @FechaI, @FechaComenzo) Where ID=@ID
--    End
--    IF @Situacion Is Null
--    Begin
	Update #Orden Set Dias=DateDiff(day, @FechaI, @FechaF) Where ID=@ID
--    End

  End
Fetch Next From CrOrden Into
@ID, @FechaI, @FechaF, @Situacion
End
Close CrOrden
Deallocate CrOrden


/*
Select v.ID, v.Empresa, v.Mov, v.MovID, v.Cliente, Cte.Nombre, v.Agente, AgenteNom=Agente.Nombre, v.Situacion, v.Estatus, 
v.FechaEmision,FechaComenzo=@Hoy, Dias=0, Hoy=@Hoy, ImporteTotal=(v.Importe + v.Impuestos)*v.TipoCambio, Valor=1
Into #OrdenConcluido
From Venta v
Join Cte On Cte.Cliente=v.Cliente
Left Outer Join Agente On Agente.Agente=v.Agente
Where v.Mov='Orden Facturacion' And v.Estatus <> 'CANCELADO'
And FechaEmision Between @FechaD And @FechaA And Empresa=@Empresa
And IsNull(Agente.Categoria, '') = IsNull(IsNull(@Categoria, Agente.Categoria), '')
And IsNull(Agente.Familia, '') = IsNull(IsNull(@Familia, Agente.Familia), '')
And IsNull(Agente.Grupo, '') = IsNull(IsNull(@Grupo, Agente.Grupo), '')
AND v.Agente Between @AgenteD AND @AgenteA
Order by v.Situacion

Declare CrOrden2 Cursor For
Select ID, FechaEmision, FechaComenzo, Agente From #OrdenConcluido
Open CrOrden2
Fetch Next From CrOrden2 Into
@ID, @FechaI, @FechaF, @Agente
While @@Fetch_Status <> - 1 And @@Error=0
Begin
  IF @@Fetch_Status <> - 2
  Begin
	Select @FechaComenzo=(Select Top 1 FechaComenzo From MovTiempo Where Modulo='VTAS' 
	And ID=@ID And Situacion In('PENDIENTE CONFIRMACIÓN CLIENTE', 'CLIENTE FRECUENTE CON DESC. FIJO', 'CONFIRMO CLIENTE',
	'RECHAZA RF', 'ACEPTADO POR  RyF', 'ALCANCE OK', 'CAMBIO ALCANCE')
	Order By IDOrden Desc)
	IF @FechaComenzo Is Null
	Begin
	  Select @FechaComenzo = @Hoy
	End
	Update #OrdenConcluido Set FechaComenzo=@FechaComenzo Where ID=@ID
	Update #OrdenConcluido Set Dias=DateDiff(day, @FechaI, @FechaComenzo) Where ID=@ID
  End
Fetch Next From CrOrden2 Into
@ID, @FechaI, @FechaF, @Agente
End
Close CrOrden2
Deallocate CrOrden2
*/


Declare CrConc Cursor For
Select Mov, MovID, Estatus, FechaEmision, FechaComenzo, Nombre, Agente, AgenteNom, Dias, ImporteTotal,Situacion From #Orden
Open CrConc
Fetch Next From CrConc Into
@Mov, @MovID, @Estatus, @FechaEmision, @FechaComenzo, @Nombre, @Agente, @AgenteNombre, @Dias, @ImporteTotal,@Situacion
While @@Fetch_Status <> - 1 And @@Error=0
Begin
  IF @@Fetch_Status <> - 2
  Begin
	IF @Dias between 0 And 4
	Begin
	Insert Into #Ordenes_Conc (Agente, AgenteNombre, Mov, MovID, Estatus, FechaEmision, FechaComenzo, Nombre, EnTiempo,Situacion)
	Values (@Agente, @AgenteNombre, @Mov, @MovID, @Estatus, @FechaEmision, @FechaComenzo, @Nombre, @ImporteTotal,@Situacion)
	End

	IF @Dias between 5 And 7
	Begin
	Insert Into #Ordenes_Conc (Agente, AgenteNombre, Mov, MovID, Estatus, FechaEmision, FechaComenzo, Nombre, D5A7Dias,Situacion)
	Values (@Agente, @AgenteNombre, @Mov, @MovID, @Estatus, @FechaEmision, @FechaComenzo, @Nombre, @ImporteTotal,@Situacion)
	End

	IF @Dias between 8 And 10
	Begin
	Insert Into #Ordenes_Conc (Agente, AgenteNombre, Mov, MovID, Estatus, FechaEmision, FechaComenzo, Nombre, D8A10Dias,Situacion)
	Values (@Agente, @AgenteNombre, @Mov, @MovID, @Estatus, @FechaEmision, @FechaComenzo, @Nombre, @ImporteTotal,@Situacion)
	End

	IF @Dias between 11 And 15
	Begin
	Insert Into #Ordenes_Conc (Agente, AgenteNombre, Mov, MovID, Estatus, FechaEmision, FechaComenzo, Nombre, D11A15Dias,Situacion)
	Values (@Agente, @AgenteNombre, @Mov, @MovID, @Estatus, @FechaEmision, @FechaComenzo, @Nombre, @ImporteTotal,@Situacion)
	End

	IF @Dias between 16 And 30
	Begin
	Insert Into #Ordenes_Conc (Agente, AgenteNombre, Mov, MovID, Estatus, FechaEmision, FechaComenzo, Nombre, D16A30Dias,Situacion)
	Values (@Agente, @AgenteNombre, @Mov, @MovID, @Estatus, @FechaEmision, @FechaComenzo, @Nombre, @ImporteTotal,@Situacion)
	End

	IF @Dias between 31 And 60
	Begin
	Insert Into #Ordenes_Conc (Agente, AgenteNombre, Mov, MovID, Estatus, FechaEmision, FechaComenzo, Nombre, D31A60Dias,Situacion)
	Values (@Agente, @AgenteNombre, @Mov, @MovID, @Estatus, @FechaEmision, @FechaComenzo, @Nombre, @ImporteTotal,@Situacion)
	End

	IF @Dias > 60
	Begin
	Insert Into #Ordenes_Conc (Agente, AgenteNombre, Mov, MovID, Estatus, FechaEmision, FechaComenzo, Nombre, Mas60Dias,Situacion)
	Values (@Agente, @AgenteNombre, @Mov, @MovID, @Estatus, @FechaEmision, @FechaComenzo, @Nombre, @ImporteTotal,@Situacion)
	End
End
Fetch Next From CrConc Into
@Mov, @MovID, @Estatus, @FechaEmision, @FechaComenzo, @Nombre, @Agente, @AgenteNombre, @Dias, @ImporteTotal,@Situacion
End
Close CrConc
Deallocate CrConc

--Update #Ordenes_Conc Set TotalXAgente=(Select Sum(Valor) From #OrdenConcluido)

--Update #Ordenes_Conc Set TotalEnTiempo=(Select Sum(Valor) From #OrdenConcluido Where Dias <=4)


IF @Zona='METRO'
   Begin
     Select * From #Ordenes_Conc Order By AgenteNombre, Nombre
   End
Else 
   IF @Zona<>'METRO' or @Zona IS NULL
      Begin
         Select * From #Ordenes_Conc Order By Agente, Nombre
	  End


End


	




