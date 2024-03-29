
/****** Object:  StoredProcedure [dbo].[sp_Cumplimiento_OT]    Script Date: 04/24/2017 18:23:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER         Procedure [dbo].[sp_Cumplimiento_OT]
@Usuario Char(10),
@Familia Varchar(50),
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


/***Consulta para el Reporte***/
--sp_Cumplimiento_OT '{Usuario}', '{Info.Gerencias}', '{Info.CoordinacionABC}', '{Info.AgenteD}', '{Info.AgenteA}','{Info.FechaD}', '{Info.FechaA}', '{Empresa}'

/***Forma Previa***/
--EspecificarAgentesFiltro


--sp_Cumplimiento_OT 'GVT', '(Todos)', '(Todos)', 'AGP', 'AGP', '01-01-2008', '01-02-2008', 'LABC', 0

Declare
@Categoria VarChar(50)

Execute spValidaAgentesGABC
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
IF @Zona<>'METRO'
    Begin
		Select v.ID, v.Empresa, v.Mov, v.MovID, v.Cliente, Cte.Nombre, v.Agente, AgenteNom=Agente.Nombre, v.Situacion, 
		Estatus=Substring(v.Estatus,1,1), v.FechaEmision, 
		S1Situacion=(Select Top 1 Situacion From MovTiempo Where Modulo='VTAS' And ID=v.ID And Situacion In ('CLIENTE FRECUENTE CON DESC. FIJO', 'CONFIRMO CLIENTE','FACTURACION ESPECIAL') Order By IDOrden Desc),
		S1FechaComenzo=
		Case When (v.Situacion In ('CLIENTE FRECUENTE CON DESC. FIJO', 'CONFIRMO CLIENTE', 'ACEPTADO POR  RyF','FACTURACION ESPECIAL') Or (v.Estatus='CONCLUIDO'))
		Then (Select Top 1 FechaComenzo From MovTiempo Where Modulo='VTAS' And ID=v.ID And Situacion In ('CLIENTE FRECUENTE CON DESC. FIJO', 'CONFIRMO CLIENTE','FACTURACION ESPECIAL') Order By IDOrden Desc) Else Null End,
		SSituacion=(Select Top 1 Situacion From MovTiempo Where Modulo='VTAS' And ID=v.ID And Situacion='ACEPTADO POR  RyF' Order By IDOrden Desc),
		SFechaComenzo=(Select Top 1 FechaComenzo From MovTiempo Where Modulo='VTAS' And ID=v.ID And Situacion ='ACEPTADO POR  RyF' Order By IDOrden Desc),
		Dias=DateDiff(day, FechaEmision, (Select Top 1 FechaComenzo From MovTiempo Where Modulo='VTAS' And ID=v.ID And Situacion ='ACEPTADO POR  RyF' Order By IDOrden Desc)),
		S1Cumplimiento = Case When DateDiff(day, FechaEmision, (Select Top 1 FechaComenzo From MovTiempo Where Modulo='VTAS' And ID=v.ID And Situacion In ('CLIENTE FRECUENTE CON DESC. FIJO', 'CONFIRMO CLIENTE','FACTURACION ESPECIAL') Order By IDOrden Desc)) <=8 Then 100 Else 0 End,
		S1ImporteEnTiempo = Case When DateDiff(day, FechaEmision, (Select Top 1 FechaComenzo From MovTiempo Where Modulo='VTAS' And ID=v.ID And Situacion In ('CLIENTE FRECUENTE CON DESC. FIJO', 'CONFIRMO CLIENTE','FACTURACION ESPECIAL') Order By IDOrden Desc)) <=8 Then (v.Importe + v.Impuestos)*v.TipoCambio Else 0 End,
		Cumplimiento=Case When DateDiff(day, FechaEmision, (Select Top 1 FechaComenzo From MovTiempo Where Modulo='VTAS' And ID=v.ID And Situacion ='ACEPTADO POR  RyF' Order By IDOrden Desc)) <=9 Then 100 Else 0 End,
		ImporteTotal=(v.Importe + v.Impuestos)*v.TipoCambio,
		ImporteEnTiempo=Case When DateDiff(day, FechaEmision, (Select Top 1 FechaComenzo From MovTiempo Where Modulo='VTAS' And ID=v.ID And Situacion ='ACEPTADO POR  RyF' Order By IDOrden Desc)) <=9 Then (v.Importe + v.Impuestos)*v.TipoCambio Else 0 End,
		fespecial=Case When v.Situacion='FACTURACION ESPECIAL' Then 'F.E.' Else '' End
		--Into #Orden
		From Venta v
		Join Cte On Cte.Cliente=v.Cliente
		Left Outer Join Agente On Agente.Agente=v.Agente
		Where v.Mov='Orden Facturacion' And v.Estatus Not In ('CANCELADO')
		And FechaEmision Between @FechaD And @FechaA
		And Empresa=Isnull(@Empresa,Empresa)
		And IsNull(v.Sucursal, '') = IsNull(IsNull(@Sucursal, v.Sucursal), '')
		--And IsNull(Agente.Categoria, '') = IsNull(IsNull(@Categoria, Agente.Categoria), '')
		And IsNull(Agente.Familia, '') = IsNull(IsNull(@Familia, Agente.Familia), '')
		And IsNull(Agente.Grupo, '') = IsNull(IsNull(@Grupo, Agente.Grupo), '')
		And Agente.Zona=Isnull(@Zona,Agente.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
		And Agente.Agente Between @AgenteD AND @AgenteA
		Order by Agente.Agente, Cte.Nombre
	End
IF @Zona='METRO'
    Begin
		Select v.ID, v.Empresa, v.Mov, v.MovID, v.Cliente, Cte.Nombre, v.Agente, AgenteNom=Agente.Nombre, v.Situacion, 
		Estatus=Substring(v.Estatus,1,1), v.FechaEmision, 
		S1Situacion=(Select Top 1 Situacion From MovTiempo Where Modulo='VTAS' And ID=v.ID And Situacion In ('CLIENTE FRECUENTE CON DESC. FIJO', 'CONFIRMO CLIENTE','FACTURACION ESPECIAL') Order By IDOrden Desc),
		S1FechaComenzo=
		Case When (v.Situacion In ('CLIENTE FRECUENTE CON DESC. FIJO', 'CONFIRMO CLIENTE', 'ACEPTADO POR  RyF','FACTURACION ESPECIAL') Or (v.Estatus='CONCLUIDO'))
		Then (Select Top 1 FechaComenzo From MovTiempo Where Modulo='VTAS' And ID=v.ID And Situacion In ('CLIENTE FRECUENTE CON DESC. FIJO', 'CONFIRMO CLIENTE','FACTURACION ESPECIAL') Order By IDOrden Desc) Else Null End,
		SSituacion=(Select Top 1 Situacion From MovTiempo Where Modulo='VTAS' And ID=v.ID And Situacion='ACEPTADO POR  RyF' Order By IDOrden Desc),
		SFechaComenzo=(Select Top 1 FechaComenzo From MovTiempo Where Modulo='VTAS' And ID=v.ID And Situacion ='ACEPTADO POR  RyF' Order By IDOrden Desc),
		Dias=DateDiff(day, FechaEmision, (Select Top 1 FechaComenzo From MovTiempo Where Modulo='VTAS' And ID=v.ID And Situacion ='ACEPTADO POR  RyF' Order By IDOrden Desc)),
		S1Cumplimiento = Case When DateDiff(day, FechaEmision, (Select Top 1 FechaComenzo From MovTiempo Where Modulo='VTAS' And ID=v.ID And Situacion In ('CLIENTE FRECUENTE CON DESC. FIJO', 'CONFIRMO CLIENTE','FACTURACION ESPECIAL') Order By IDOrden Desc)) <=8 Then 100 Else 0 End,
		S1ImporteEnTiempo = Case When DateDiff(day, FechaEmision, (Select Top 1 FechaComenzo From MovTiempo Where Modulo='VTAS' And ID=v.ID And Situacion In ('CLIENTE FRECUENTE CON DESC. FIJO', 'CONFIRMO CLIENTE','FACTURACION ESPECIAL') Order By IDOrden Desc)) <=8 Then (v.Importe + v.Impuestos)*v.TipoCambio Else 0 End,
		Cumplimiento=Case When DateDiff(day, FechaEmision, (Select Top 1 FechaComenzo From MovTiempo Where Modulo='VTAS' And ID=v.ID And Situacion ='ACEPTADO POR  RyF' Order By IDOrden Desc)) <=9 Then 100 Else 0 End,
		ImporteTotal=(v.Importe + v.Impuestos)*v.TipoCambio,
		ImporteEnTiempo=Case When DateDiff(day, FechaEmision, (Select Top 1 FechaComenzo From MovTiempo Where Modulo='VTAS' And ID=v.ID And Situacion ='ACEPTADO POR  RyF' Order By IDOrden Desc)) <=9 Then (v.Importe + v.Impuestos)*v.TipoCambio Else 0 End,
		fespecial=Case When v.Situacion='FACTURACION ESPECIAL' Then 'F.E.' Else '' End
		--Into #Orden
		From Venta v
		Join Cte On Cte.Cliente=v.Cliente
		Left Outer Join Agente On Agente.Agente=v.Agente
		Where v.Mov='Orden Facturacion' And v.Estatus Not In ('CANCELADO')
		And FechaEmision Between @FechaD And @FechaA
		And Empresa=Isnull(@Empresa,Empresa)
		And IsNull(v.Sucursal, '') = IsNull(IsNull(@Sucursal, v.Sucursal), '')
		--And IsNull(Agente.Categoria, '') = IsNull(IsNull(@Categoria, Agente.Categoria), '')
		And IsNull(Agente.Familia, '') = IsNull(IsNull(@Familia, Agente.Familia), '')
		And IsNull(Agente.Grupo, '') = IsNull(IsNull(@Grupo, Agente.Grupo), '')
		And Agente.Zona=Isnull(@Zona,Agente.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
		And Agente.Agente Between @AgenteD AND @AgenteA
		Order by Agente.Nombre, v.Mov
	End
End





