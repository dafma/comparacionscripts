/****** Object:  StoredProcedure [dbo].[sp_Ctes_Arranque]    Script Date: 05/05/2017 15:54:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER       Procedure [dbo].[sp_Ctes_Arranque]
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

Create Table #Venta(
Agente char(10) Null,
AgenteNom varchar(100) Null,
Empresa  Char(5) Null,
Cliente char(10) Null,
Nombre varchar(100) Null,
FechaArranque DateTime Null,
FechaResultados DateTime Null,
CMov char(20) Null,
CMovID varchar(20) Null,
CFechaEmision DateTime Null,
CImporte Money Null,
FMov char(20) Null,
FMovID varchar(20) Null,
FFechaEmision DateTime Null,
FImporte Money Null
)

/***Consulta para el Reporte***/
--sp_Ctes_Arranque '{Usuario}', '{Info.Gerencias}', '{Info.CoordinacionABC}', '{Info.AgenteD}', '{Info.AgenteA}','{Info.FechaD}', '{Info.FechaA}', '{Empresa}'

/***Forma Previa***/
--EspecificarAgentesFiltro

--sp_Ctes_Arranque 'GVT', '(Todos)', '(Todos)', 'AMO', 'RJM', '01-12-2007', '31-12-2007', 'LABC'

Declare 
@Cliente char(10),
@Nombre varchar(100),
@FechaArranque DateTime,
@FechaResultados DateTime,
@Mov char(20),
@MovID varchar(20),
@FechaEmision Datetime,
@Importe Money,
@ID Int,
@Agente char(10),
@AgenteNom varchar(100),
@Categoria VarChar(50),
@Familia Varchar(50)

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
     
Set @ID=0

Select c.Agente, AgenteNom=ag.Nombre, c.Cliente, c.Nombre, FechaArranque, FechaResultados
Into #Ctes
From Cte c
Left Outer Join Agente ag On ag.Agente=c.Agente
Where c.FechaArranque Between @FechaD And @FechaA--c.FechaArranque >=@FechaD And c.FechaResultados <=@FechaA
And ag.Agente between @AgenteD And @AgenteA
--And IsNull(Ag.Categoria, '') = IsNull(IsNull(@Categoria, Ag.Categoria), '')
-- modify 05/05/17 And IsNull(Ag.Familia, '') = IsNull(IsNull(@Familia, Ag.Familia), '')
And IsNull(Ag.Grupo, '') = IsNull(IsNull(@Grupo, Ag.Grupo), '')
And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014


Declare CrCtes Cursor For
Select Agente, AgenteNom, Cliente, Nombre, FechaArranque, FechaResultados From #Ctes
Open CrCtes
Fetch Next From CrCtes Into
@Agente, @AgenteNom, @Cliente, @Nombre, @FechaArranque, @FechaResultados
While @@Fetch_Status <> -1 And @@Error =0
Begin
	IF @@Fetch_Status <> -2
	Begin
		Insert Into #Venta(Agente, AgenteNom, Cliente, Nombre, CMovID, FechaArranque, FechaResultados, CFechaEmision, CImporte, FMov, FMovID, FFechaEmision, FImporte, CMov)
		Values (@Agente, @AgenteNom, @Cliente, @Nombre, Null, @FechaArranque, @FechaResultados, Null, 0, 'Factura', '0', 0, 0, 'Cotización Cliente')

		Declare CrVentas Cursor For
		Select Empresa,Mov, MovID, FechaEmision, ((Importe+Impuestos)*TipoCambio) From Venta 
		Where FechaEmision Between @FechaArranque And @FechaResultados And Cliente=@Cliente
        And IsNull(Sucursal, '') = IsNull(IsNull(@Sucursal, Sucursal), '')
		And Mov='Cotización Cliente' And Estatus In ('PENDIENTE', 'CONCLUIDO') And MovID Not Like'%-%'
		Open CrVentas
		Fetch Next From CrVentas Into
		@Empresa,@Mov, @MovID, @FechaEmision, @Importe
		While @@Fetch_Status <> -1 And @@Error =0
		Begin
			IF @@Fetch_Status <> -2
			Begin
				IF @Mov Is Not Null
				Begin
				Insert Into #Venta(Empresa,Agente, AgenteNom, Cliente, Nombre, CMov, CMovID, FechaArranque, FechaResultados, CFechaEmision, CImporte, FMov, FMovID, FFechaEmision, FImporte)
				Values
				(@Empresa,@Agente, @AgenteNom, @Cliente, @Nombre, @Mov, @MovID, @FechaArranque, @FechaResultados, @FechaEmision, @Importe, 'Factura', '0', 0, 0)
				End
			End
		Fetch Next From CrVentas Into
		@Empresa,@Mov, @MovID, @FechaEmision, @Importe
		End
		Close CrVentas
		Deallocate CrVentas
	End
Fetch Next From CrCtes Into
@Agente, @AgenteNom, @Cliente, @Nombre, @FechaArranque, @FechaResultados
End
Close CrCtes
Deallocate CrCtes



Declare CrCtes Cursor For
Select Agente, AgenteNom, Cliente, Nombre, FechaArranque, FechaResultados From #Ctes
Open CrCtes
Fetch Next From CrCtes Into
@Agente, @AgenteNom, @Cliente, @Nombre, @FechaArranque, @FechaResultados
While @@Fetch_Status <> -1 And @@Error =0
Begin
	IF @@Fetch_Status <> -2
	Begin
		Declare CrVentas Cursor For
		Select Empresa,Mov, MovID, FechaEmision, ((Importe+Impuestos)*TipoCambio) From Venta 
		Where FechaEmision Between @FechaArranque And @FechaResultados And Cliente=@Cliente
		And IsNull(Sucursal, '') = IsNull(IsNull(@Sucursal, Sucursal), '')
		And Mov='Factura' And Estatus='CONCLUIDO'
		Open CrVentas
		Fetch Next From CrVentas Into
		@Empresa,@Mov, @MovID, @FechaEmision, @Importe
		While @@Fetch_Status <> -1 And @@Error =0
		Begin
			IF @@Fetch_Status <> -2
			Begin
				IF @Mov Is Not Null
				Begin
				Insert Into #Venta(Empresa,Agente, AgenteNom, CMov, CMovID, CFechaEmision, CImporte, Cliente, Nombre, FMov, FMovID, FechaArranque, FechaResultados, FFechaEmision, FImporte)
				Values
				(@Empresa,@Agente, @AgenteNom, 'Cotización Cliente', '0', 0, 0, @Cliente, @Nombre, @Mov, @MovID, @FechaArranque, @FechaResultados, @FechaEmision, @Importe)
				End
			End
		Fetch Next From CrVentas Into
		@Empresa,@Mov, @MovID, @FechaEmision, @Importe
		End
		Close CrVentas
		Deallocate CrVentas
	End
Fetch Next From CrCtes Into
@Agente, @AgenteNom, @Cliente, @Nombre, @FechaArranque, @FechaResultados
End
Close CrCtes
Deallocate CrCtes

IF @Zona='METRO'
   Begin
     Select  Empresa,AgenteNom, Cliente, Nombre, FechaArranque, FechaResultados, CMov, CImporte=Sum(CImporte), FMov, FImporte=Sum(FImporte) From #Venta 
   	 Group By  AgenteNom, Cliente, Nombre, FechaArranque, FechaResultados, CMov, FMov
	 Order By FImporte Desc
   End
Else 
   IF @Zona<>'METRO' or @Zona IS NULL
      Begin
         Select Agente, AgenteNom, Cliente, Nombre, FechaArranque, FechaResultados, CMov, CImporte=Sum(CImporte), FMov, FImporte=Sum(FImporte) From #Venta 
		 Group By Agente, AgenteNom, Cliente, Nombre, FechaArranque, FechaResultados, CMov, FMov
		 Order By FImporte Desc
	  End



End
--select * from cte where fechaarranque is not null



/* 
Verion anterior 02/05/2017
--select * from #Venta

Select Agente, AgenteNom, Cliente, Nombre, FechaArranque, FechaResultados, CMov, CImporte=Sum(CImporte), FMov, FImporte=Sum(FImporte) From #Venta 
Group By Agente, AgenteNom, Cliente, Nombre, FechaArranque, FechaResultados, CMov, FMov
Order By FImporte Desc

 */





