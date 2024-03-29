
/****** Object:  StoredProcedure [dbo].[sp_Comisiones]    Script Date: 05/08/2017 16:22:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





--sp_Comisiones 'GVT', '(Todos)', '(Todos)', 2016, 5, 2016, 5, 'LMB', 'LMB', 'FERMI',0,'METRO'
ALTER                   Procedure [dbo].[sp_Comisiones]
@Usuario char(10),
-- modyfy m 08/05/17 @Familia varchar(50),
@Grupo varchar(50),
@EF		int,
@PF		int,
@EC		int,
@PC		int,
@AgenteD	char(10),
@AgenteA	char(10),
@Empresa	char(5),
@Sucursal int,
@Zona           Varchar(30) --cambiado/agregado para nuevo filtro Diciembre 2014
As
Begin

Create Table #ConVtasCobro(
ID int Null,
REmpresa Char(5) Null,
Mov char(20) Null,
MovID varchar(20) Null,
FechaEmision SmallDateTime Null,
Cliente char(10) Null,
Nombre varchar(100) Null,
Importe Money Null,
Impuestos Money,
Agente char(10) Null,
NombreAg varchar(100),
Estatus char(15) Null,
EstatusCxc char(15) Null,
Condicion varchar(50) Null,
DiasVencimiento Int Null, 
Cuota Float Null,
ImporteTotal Money Null,
PorcenTotal Float Null,
PorcenComision Float Null,
DescFact Money Null,
DescAuto Money Null,
DescDife Money Null,
PorcenAplica Float Null,
FechaCobro Datetime null,
Cobro Money Null,
FechaAnticipoFac datetime null,
Saldo Money Null,  ---agregado
AnticipoFact Money Null,
FechaAnticipo datetime null,
Anticipo Money Null,
NotaCredito Money Null,
TotalCobrado Money Null,
Vencimiento DateTime Null,
FechaMaxCobro DateTime Null,
CobroEnTiempo char(2) Null,
ComisionPagar Float Null,
RecibioCte Datetime null,
CubiertaPorAnticipos bit null
)

Declare
@Mov char(20),
@MovID varchar(20),
@ImporteC Money,
@ImporteAF Money,
@ImporteA Money,
@ImporteNC Money,
@IDVtas Int,
@ID Int,
@Vencimiento DateTime,
@VencimientoMax DateTime,
@Cliente char(10),
@Condicion varchar(50),
@FechaEmision DateTime,
@EjercicioF Int,
@EjercicioC Int,
@PeriodoF Int,
@PeriodoC int,
@DiasVencimiento Int,
@CobroEnTipo char(2),
@PorcenAplica float,
@ImporteTotal Money,
@Agente char(10),
@PorcenComision Float,
@DescDif Money,
@PorComision Float,
@PorTotal Float,
@ImpTotal Money,
@FechaCobro datetime,
@FechaAnticipoFac datetime,
@FechaAnticipo datetime,
@EnTiempo char(2),
@EnTiempo2 char(2),
@Categoria VarChar(50),
@FEchaCobroFA DateTime,
@Importe Money,
@Impuestos Money,
@ImporteFactura Money,
@ImporteFacturasA Money,
@DescFact Money,
@DescAuto Money,
@DescDife Money,
@RecibioCte DateTime,
@ImpuestoFA Money,
@NombreAg varchar(100),
@Familia varchar(50)

Exec sp_MesPasado @EF, @PF, @EC, @PC, @EjercicioF OUTPUT, @PeriodoF OUTPUT, @EjercicioC OUTPUT, @PeriodoC OUTPUT

--Select @Usuario='GVT'

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

Insert #ConVtasCobro
Select v.ID, v.Empresa,v.Mov, v.MovID, v.FechaEmision, v.Cliente, c.Nombre, Importe=Case When (v.Mov in('Factura','Factura CFD') And v.estatus='CONCLUIDO') OR (v.Mov in('Factura','Factura CFD') And v.estatus='CANCELADO' AND v.Ejercicio=@EjercicioF AND v.Periodo=@PeriodoF And MONTH(v.FechaCancelacion)>Month(v.FechaEmision))
Then ((v.Importe-(Isnull(v.AnticiposFacturados,0)-Isnull(v.anticiposimpuestos,0)))*v.TipoCambio)
Else ((v.Importe-(Isnull(v.AnticiposFacturados,0)-Isnull(v.anticiposimpuestos,0)))*v.TipoCambio)*-1 End,v.Impuestos,
v.Agente, ag.Nombre, v.Estatus, Substring(cxc.Estatus,1,1), cc.Condicion, DiasVencimiento=Case When IsNull(cc.DiasVencimiento,0) = 0 Then 8 Else IsNull(cc.DiasVencimiento,0) End,
Cuota = (Select Importe From TablaAnualD Where TablaAnual = v.Agente AND Ejercicio = v.Ejercicio AND Periodo = v.Periodo),
Null, Null, Null,
--Calcula el Descuento de la Factura
DescFact=IsNull((Select (Sum((IsNull(Cantidad,0)*IsNull(Precio,0))/100*DescuentoLinea)/(Sum(IsNull(Cantidad,0)*IsNull(Precio,0))/2)/2)*100 From VentaD Where ID=v.ID And DescuentoLinea>0 And DescuentoLinea Is Not Null And IsNull(Precio,0)>0),0),
--Descuento Autorizado
DescAuto=10.0,
--Calcula la Diferencia entre el Descuento de la Factura y el Autorizado
DescDife=Case When IsNull((Select (Sum((IsNull(Cantidad,0)*IsNull(Precio,0))/100*DescuentoLinea)/(Sum(IsNull(Cantidad,0)*IsNull(Precio,0))/2)/2)*100 From VentaD Where ID=v.ID And DescuentoLinea>0 And DescuentoLinea Is Not Null And IsNull(Precio,0)>0),0)-10.0 < 0 
Then 0 Else IsNull((Select (Sum((IsNull(Cantidad,0)*IsNull(Precio,0))/100*DescuentoLinea)/(Sum(IsNull(Cantidad,0)*IsNull(Precio,0))/2)/2)*100 From VentaD Where ID=v.ID And DescuentoLinea>0 And DescuentoLinea Is Not Null And IsNull(Precio,0)>0),0) -10.0 End,
Null, Null, 0, Null,v.SAldo, 0, Null, 0, 0, 0, Null, Null, Null, Null, ve.ReciboFecha,0
From Venta v
Join VentaD vd On v.ID=vd.ID
Join Cxc On v.Mov=cxc.Origen And v.MovID=cxc.OrigenID And cxc.OrigenTipo='VTAS' And Cxc.Estatus In ('PENDIENTE', 'CONCLUIDO','CANCELADO')  And IsNull(cxc.Sucursal, '') = IsNull(IsNull(@Sucursal, cxc.Sucursal), '') And v.cliente=cxc.Cliente
Join Cte c On c.Cliente=v.Cliente
Left Outer Join Condicion cc On cc.Condicion=v.Condicion
Left Outer Join Agente ag On ag.Agente=v.Agente
Left Outer Join VentaEntrega ve On ve.ID=v.ID
Where v.Empresa=Isnull(@Empresa,v.Empresa) And (v.Estatus='CONCLUIDO' or (v.Estatus='CANCELADO' AND MONTH(v.FechaCancelacion)>Month(v.FechaEmision))) 
AND v.Ejercicio=@EjercicioF AND (v.Periodo=@PeriodoF Or (v.Estatus='CANCELADO' AND MONTH(v.FechaCancelacion)=@PeriodoF))
And IsNull(v.Sucursal, '') = IsNull(IsNull(@Sucursal, v.Sucursal), '')
--And IsNull(Ag.Categoria, '') = IsNull(IsNull(@Categoria, Ag.Categoria), '')
-- m modify 08/05/17 And IsNull(Ag.Familia, '') = IsNull(IsNull(@Familia, Ag.Familia), '')
And IsNull(Ag.Grupo, '') = IsNull(IsNull(@Grupo, Ag.Grupo), '')
AND ag.Agente Between @AgenteD And @AgenteA 
And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
And v.Mov In ('Factura', 'Devolucion Venta','Factura CFD','Devolucion CFD','Cancelacion Factura')
Group By v.ID, vd.ID, v.Empresa,v.Mov, v.MovID, v.FechaEmision,v.FechaCancelacion, v.Cliente, c.Nombre, v.TipoCambio, v.Agente, ag.Nombre, v.Estatus, Cxc.Estatus,
cc.Condicion, cc.DiasVencimiento, v.Ejercicio, v.Periodo, ve.ReciboFecha,v.Saldo,v.Importe,v.Impuestos,v.AnticiposFacturados,v.anticiposimpuestos
--Inserta las Notas de Credito aplicadas a Facturas Anticipo
----------
Insert #ConVtasCobro(Id,REmpresa,Mov,Movid,FechaEmision,cliente,Importe,NotaCredito,Impuestos,Agente,NombreAg,Estatus,EstatusCXC,DiasVencimiento,Cuota,Saldo)
Select a.ID, a.Empresa,a.Mov, a.MovID, a.FechaEmision, a.Cliente,  Case When a.Estatus in('CONCLUIDO','PENDIENTE') then -(a.Importe*a.TipoCambio) Else (a.Importe*a.TipoCambio) end, Case When a.Estatus in('CONCLUIDO','PENDIENTE') then -(a.Importe*a.TipoCambio) Else (a.Importe*a.TipoCambio) end, a.Impuestos,
a.Agente, ag.Nombre, a.Estatus, Substring(a.Estatus,1,1), 8,
Cuota = (Select Importe From TablaAnualD Where TablaAnual = a.Agente AND Ejercicio = a.Ejercicio AND Periodo = a.Periodo),a.SAldo
    FROM Cxc a, CxcD, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     AND a.ID=CxcD.ID
     AND mt.Modulo = 'CXC'
     AND mt.Clave In ('CXC.NC')
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     AND a.Estatus In ('CONCLUIDO', 'PENDIENTE', 'CANCELADO')
/***** Lineas Para el Filtro de Agentes *****/
--     And IsNull(Ag.Categoria, '') = IsNull(IsNull(@Categoria, Ag.Categoria), '')
 -- m modify 08/05/17    And IsNull(Ag.Familia, '') = IsNull(IsNull(@Familia, Ag.Familia), '')
     And IsNull(Ag.Grupo, '') = IsNull(IsNull(@Grupo, Ag.Grupo), '')
     And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
/***** Lineas Para el Filtro de Agentes *****/
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     AND a.Ejercicio = @EjercicioF
     AND a.Periodo = @PeriodoF
     AND a.Empresa = Isnull(@Empresa,a.Empresa)
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
     AND CxcD.Aplica In ('Factura Anticipo','Factura Anticipo CFD')
   ORDER BY ag.Grupo, a.Agente


--
   Insert #ConVtasCobro
   select c.ID,c.Empresa,c.Mov,c.MovID,c.FechaEmision,c.Cliente,t.Nombre,(c.Importe*c.tipocambio),(c.Impuestos*c.tipocambio),c.Agente,ag.Nombre,c.Estatus,
                      Substring(c.Estatus,1,1), n.Condicion, DiasVencimiento=Case When IsNull(n.DiasVencimiento,0) = 0 Then 8 Else IsNull(n.DiasVencimiento,0) End,
                      Cuota = (Select Importe From TablaAnualD Where TablaAnual = c.Agente AND Ejercicio = c.Ejercicio AND Periodo = c.Periodo),
                      Null, Null, Null,Null,Null,Null,
                      Null, Null, 0, Null,C.SAldo, 0, Null, 0, 0, 0, Null, Null, Null, Null, Null,0
   From cxc c,Cte t,Condicion n,Agente ag
   Where c.Cliente=t.Cliente
   And c.Condicion=n.Condicion
   AND c.Ejercicio=@EjercicioF AND c.Periodo=@PeriodoF 
   And c.Agente=ag.Agente
   AND c.Estatus in('CONCLUIDO','PENDIENTE')
   And c.Empresa=Isnull(@Empresa,c.Empresa) 
   And IsNull(c.Sucursal, '') = IsNull(IsNull(@Sucursal, c.Sucursal), '')
--   And IsNull(Ag.Categoria, '') = IsNull(IsNull(@Categoria, Ag.Categoria), '')
  -- m modify 08/05/17 And IsNull(Ag.Familia, '') = IsNull(IsNull(@Familia, Ag.Familia), '')
   And IsNull(Ag.Grupo, '') = IsNull(IsNull(@Grupo, Ag.Grupo), '')
   And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
   AND ag.Agente Between @AgenteD And @AgenteA  
   And c.Mov In ('Factura Anticipo','Factura Anticipo CFD')

---Actualiza los  datos de las Facturas Anticipo desde los datos de la factura
Declare CrTotal Cursor For 
  Select ID From #ConVtasCobro Where Mov In ('Factura Anticipo','Factura Anticipo CFD')
Open CrTotal
Fetch Next From CrTotal into @ID
While @@Fetch_Status <> - 1 And @@Error = 0
Begin
	IF @@Fetch_Status <> - 2
	Begin
         Select @IdVtas=(Select Max(ID) From VentaFacturaAnticipo v Where v.CXCid=@ID)
         IF not exists(Select id From #ConVtasCobro Where id=@IdVtas and Mov in('Factura','Factura CFD'))
            Begin
              Select @DescFact=IsNull((Select (Sum((IsNull(Cantidad,0)*IsNull(Precio,0))/100*DescuentoLinea)/(Sum(IsNull(Cantidad,0)*IsNull(Precio,0))/2)/2)*100 From VentaD Where ID=@IdVtas And DescuentoLinea>0 And DescuentoLinea Is Not Null And IsNull(Precio,0)>0),0),
              @DescAuto=10.0,
              @DescDife=Case When IsNull((Select (Sum((IsNull(Cantidad,0)*IsNull(Precio,0))/100*DescuentoLinea)/(Sum(IsNull(Cantidad,0)*IsNull(Precio,0))/2)/2)*100 From VentaD Where ID=@IdVtas And DescuentoLinea>0 And DescuentoLinea Is Not Null And IsNull(Precio,0)>0),0)-10.0 < 0 
                       Then 0 Else IsNull((Select (Sum((IsNull(Cantidad,0)*IsNull(Precio,0))/100*DescuentoLinea)/(Sum(IsNull(Cantidad,0)*IsNull(Precio,0))/2)/2)*100 From VentaD Where ID=@IdVtas And DescuentoLinea>0 And DescuentoLinea Is Not Null And IsNull(Precio,0)>0),0) -10.0 End
              Select @RecibioCte=(Select ReciboFecha From VentaEntrega Where Id=@IdVtas)
            End
         Else
            Begin
              Select @DescFact=(Select c.DescFact From #ConVtasCobro c Where c.id=(Select Max(v.Id) From VentaFacturaAnticipo v Where v.CXCid=@ID) and c.Mov in ('Factura','Factura CFD')) 
              Select @DescAuto=(Select c.DescAuto From #ConVtasCobro c Where c.id=(Select Max(v.Id) From VentaFacturaAnticipo v Where v.CXCid=@ID) and c.Mov in ('Factura','Factura CFD')) 
              Select @DescDife=(Select c.DescDife From #ConVtasCobro c Where c.id=(Select Max(v.Id) From VentaFacturaAnticipo v Where v.CXCid=@ID) and c.Mov in ('Factura','Factura CFD')) 
              Select @RecibioCte=(Select c.RecibioCte From #ConVtasCobro c Where c.id=(Select Max(v.Id) From VentaFacturaAnticipo v Where v.CXCid=@ID) and c.Mov in ('Factura','Factura CFD')) 
            End
         UPdate #ConVtasCobro 
         Set DescFact=@DescFact,DescAuto=@DescAuto,DescDife=@DescDife,RecibioCte=@RecibioCte
         Where Current of CrTotal
	End	
Fetch Next From CrTotal into @ID
End
Close CrTotal
Deallocate CrTotal


Declare CrTotal Cursor For
Select Mov, Agente, DescDife, ID,NombreAg  From #ConVtasCobro
Open CrTotal
Fetch Next From CrTotal into
@Mov, @Agente, @DescDif, @ID,@NombreAg
While @@Fetch_Status <> - 1 And @@Error = 0
Begin
	IF @@Fetch_Status <> - 2
	Begin
	
--sp_Comisiones 'GVT', '(Todos)', '(Todos)', 2016, 5, 2016, 5, 'LMB', 'LMB', 'FERMI',0,'METRO'

	IF @Zona<>'METRO'
	   Begin
	     Select @ImpTotal=(Select Sum(Importe) From #ConVtasCobro Where Agente=@Agente)-- And Mov=@Mov)
       End
	IF @Zona='METRO'
	   Begin
	     Select @ImpTotal=(Select Sum(Importe) From #ConVtasCobro Where NombreAG=@NombreAG)-- And Mov=@Mov)
       End
	Select @PorTotal=(Select (@ImpTotal*100)/(Select Importe From TablaAnualD Where TablaAnual = @Agente AND Ejercicio = @EjercicioF AND Periodo = @PeriodoF))
	--Select @PorComision=(Select Valor From TablaRangoD Where TablaRango='Comision Agentes' And
	--	((Select @ImpTotal*100)/(Select Importe From TablaAnualD Where TablaAnual = @Agente AND Ejercicio = @EjercicioF AND Periodo = @PeriodoF))
	--	Between NumeroD And NumeroA)
    IF @Zona<>'METRO'
	   Begin
	     Select @PorComision=(Select Valor From TablaRangoD Where TablaRango='Comision Agentes' And
		        round(@PorTotal,2) Between NumeroD And NumeroA)		
       End
    IF @Zona='METRO'
	   Begin
	     Select @PorComision=(Select Valor From TablaRangoD Where TablaRango='Comision Ag Metro' And
		        round(@PorTotal,2) Between NumeroD And NumeroA)		
       End
	Update #ConVtasCobro Set PorcenTotal = @PorTotal Where Agente=@Agente
	Update #ConVtasCobro Set PorcenComision = @PorComision Where Agente=@Agente
	Update #ConVtasCobro Set ImporteTotal = @ImpTotal Where Agente=@Agente-- And Mov=@Mov
		IF @DescDif <> 0
		Begin
			Update #ConVtasCobro Set PorcenAplica=((1-((@DescDif/100)*5)) * @PorComision) Where ID=@ID 	
		End
		IF @DescDif = 0 
		Begin
			Update #ConVtasCobro Set PorcenAplica=@PorComision Where ID=@ID
		End
	End	
Fetch Next From CrTotal into
@Mov, @Agente, @DescDif, @ID,@NombreAg
End
Close CrTotal
Deallocate CrTotal

Update #ConVtasCobro Set NotaCredito=Importe /*,TotalCobrado=Importe*/ From #ConVtasCobro Where Mov In ('Devolucion Venta','Devolucion CFD')
--agregado el 28 de feb
--Update #ConVtasCobro Set AnticipoFAct = 0 Where AnticipoFAct<>0 And Mov in('Factura','Factura CFD')
---termina el agregado
Declare CrCobro Cursor For
Select ID, Mov, MovID, FechaEmision, Cliente, Condicion, DiasVencimiento, PorcenAplica, Agente
From #ConVtasCobro Where Mov in('Factura','Factura Anticipo','Factura CFD','Factura Anticipo CFD')
Open CrCobro
Fetch Next From CrCobro Into
@IDVtas, @Mov, @MovID, @FechaEmision, @Cliente, @Condicion, @DiasVencimiento, @PorcenAplica, @Agente
While @@Fetch_Status <> - 1 And @@Error = 0
Begin
	IF @@Fetch_Status <> - 2
	Begin
--Se inserta la Fecha de Vencimiento
	  Exec spCalcularVencimiento 'VTAS', @Empresa, @Cliente, @Condicion, @FechaEmision, @Vencimiento OUTPUT, Null, Null
	  IF @FechaEmision=@Vencimiento Begin Select @Vencimiento=@Vencimiento+8 End
	  Update #ConVtasCobro Set Vencimiento = @Vencimiento Where Current of CrCobro
--Se inserta la Fecha Maxima de Vencimiento	  
	  --Exec spCalcularVencimiento 'VTAS', @Empresa, @Cliente, @Condicion, @Vencimiento, @VencimientoMax OUTPUT, Null, Null
	  --IF @Vencimiento=@VencimientoMax Begin Select @VencimientoMax=@VencimientoMax+8 End
	  Select @VencimientoMax=DateAdd(Day, @DiasVencimiento, @Vencimiento)
	  Update #ConVtasCobro Set FechaMaxCobro = @VencimientoMax Where Current of CrCobro

--Se inicializan variables

	  Select @ImporteC=0, @ImporteAF=0, @ImporteA=0, @ImporteNC=0

--Calculo de Cobros
	  IF Exists (Select * From CxcD, Cxc Where CxcD.ID=Cxc.ID And Cxc.Mov='Cobro' And Cxc.Estatus='CONCLUIDO' 
	  And Aplica=@Mov And AplicaID=@MovID And Cxc.Ejercicio=@EjercicioC And Cxc.Periodo=@PeriodoC) --And Cxc.FechaEmision <= @VencimientoMax)
	  Begin
	    Select @FechaCobro=(Select Distinct(Max(Cxc.FechaEmision)) From CxcD, Cxc Where CxcD.ID=Cxc.ID And Cxc.Mov='Cobro' 
	    And Cxc.Estatus='CONCLUIDO' And Aplica=@Mov And AplicaID=@MovID And Cxc.Ejercicio=@EjercicioC And Cxc.Periodo=@PeriodoC)    
	    Update #ConVtasCobro Set FechaCobro=@FechaCobro Where Current of CrCobro     
	
	    Select @ImporteC=(Select Sum(((IsNull(CxcD.Importe,0))-(IsNull(CxcD.Importe,0) * IsNull(Cxc.IVAFiscal,0)))*Cxc.TipoCambio) From CxcD, Cxc Where CxcD.ID=Cxc.ID And Cxc.Mov='Cobro' 
	    And Cxc.Estatus='CONCLUIDO' And Aplica=@Mov And AplicaID=@MovID And Cxc.Ejercicio=@EjercicioC And Cxc.Periodo=@PeriodoC)-- And Cxc.FechaEmision <= @VencimientoMax)

	    Select @ImporteAF=(Select Sum(((IsNull(CxcD.Importe,0))-(IsNull(CxcD.Importe,0) * Cxc.IVAFiscal))*Cxc.TipoCambio)
	    From CxcD, Cxc Where CxcD.ID=Cxc.ID And Cxc.Mov='Cobro' 
	    And Cxc.Estatus='CONCLUIDO' 
	    And Aplica In (Select Mov From Cxc Where ID In (Select CxcID From VentaFacturaAnticipo Where ID=@IDVtas))
	    And AplicaID In (Select MovID From Cxc Where ID In (Select CxcID From VentaFacturaAnticipo Where ID=@IDVtas))
	    And Cxc.Ejercicio=@EjercicioC And Cxc.Periodo=@PeriodoC)

	    Update #ConVtasCobro Set Cobro=@ImporteC Where Current of CrCobro

	    Update #ConVtasCobro Set AnticipoFact=@ImporteAF Where Current of CrCobro
	  End
--Calculo de Anticipos
	  IF Exists (Select * From CxcD, Cxc Where CxcD.ID=Cxc.ID And Cxc.Mov='Aplicacion' And Cxc.Estatus='CONCLUIDO' 
	  And Aplica=@Mov And AplicaID=@MovID /*And Cxc.Ejercicio=@EjercicioC And Cxc.Periodo=@PeriodoC*/ And Cxc.Origen='Anticipo')-- And Cxc.FechaEmision <= @VencimientoMax)
	  Begin
	    Select @FechaAnticipo=(Select Distinct(Max(Cxc.FechaEmision)) From CxcD, Cxc Where CxcD.ID=Cxc.ID And Cxc.Mov='Aplicacion' 
	    And Cxc.Estatus='CONCLUIDO' And Aplica=@Mov And AplicaID=@MovID /*And Cxc.Ejercicio=@EjercicioC And Cxc.Periodo=@PeriodoC */And Cxc.Origen='Anticipo')-- And Cxc.FechaEmision <= @VencimientoMax)
	    Update #ConVtasCobro Set FechaAnticipo=@FechaAnticipo Where Current of CrCobro    
	
	    Select @ImporteA=(Select Sum(((IsNull(CxcD.Importe,0))-(IsNull(CxcD.Importe,0) * IsNull(Cxc.IVAFiscal,0)))*Cxc.TipoCambio) From CxcD, Cxc Where CxcD.ID=Cxc.ID And Cxc.Mov='Aplicacion' 
	    And Cxc.Estatus='CONCLUIDO' And Aplica=@Mov And AplicaID=@MovID And Cxc.Ejercicio=@EjercicioC And Cxc.Periodo=@PeriodoC And Cxc.Origen='Anticipo')-- And Cxc.FechaEmision <= @VencimientoMax)	
	    Update #ConVtasCobro Set Anticipo=@ImporteA Where Current of CrCobro
	  End

--sp_Comisiones 'GVT', '(Todos)', '(Todos)', 2008, 9, 2008, 10, 'JCV', 'JCV', 'LABC',0

	    Select @ImporteTotal = IsNull(@ImporteC,0) + /*IsNull(@ImporteAF,0) +*/ IsNull(@ImporteA,0) + IsNull(@ImporteNC,0)

	    Select @EnTiempo=Case When @FechaCobro<=@VencimientoMax And @ImporteC > 0 Then 'Si' Else 'No' End
	    Select @EnTiempo2=Case When @FechaAnticipo<=@VencimientoMax And @ImporteA > 0 Then 'Si' Else 'No' End

	    Update #ConVtasCobro Set TotalCobrado=@ImporteTotal Where Current of CrCobro	    
	    Update #ConVtasCobro Set CobroEnTiempo = @EnTiempo Where Current of CrCobro

--para comprobar: comenta las lineas que dicen agregado e imprimelo, despues descomentalas e imprime de nuevo el reporte solo deben cambiar las facturas del problema

        IF @Mov not in('Factura','Factura CFD')  --agreagdo agregado
           Begin  --agreagdo agregado
	          Update #ConVtasCobro Set ComisionPagar = Case When (@ImporteAF * (@PorcenAplica/100)) < 0 Then 0 
              Else (@ImporteAF * (@PorcenAplica/100)) End Where Current of CrCobro
           End  --agreagdo agregado
	    IF @EnTiempo='Si' Begin
	    Update #ConVtasCobro Set ComisionPagar = IsNull(ComisionPagar,0) + Case When (@ImporteC * (@PorcenAplica/100)) < 0 Then 0 
            Else (@ImporteC * (@PorcenAplica/100)) End Where Current of CrCobro End

	    IF @EnTiempo2='Si' And (@ImporteA Is Not Null Or @ImporteA <> 0)Begin
	    Update #ConVtasCobro Set ComisionPagar = IsNull(ComisionPagar,0) +  Case When (@ImporteA * (@PorcenAplica/100)) < 0 Then 0 
            Else (@ImporteA * (@PorcenAplica/100)) End Where Current of CrCobro End

	End
Fetch Next From CrCobro Into
@IDVtas, @Mov, @MovID, @FechaEmision, @Cliente, @Condicion, @DiasVencimiento, @PorcenAplica, @Agente
End
Close CrCobro
Deallocate CrCobro


Update #ConVtasCobro Set ComisionPagar = 0 Where ComisionPagar Is Null
Update #ConVtasCobro Set Cobro = 0 Where Cobro Is Null
Update #ConVtasCobro Set TotalCobrado = 0 Where TotalCobrado Is Null


IF @Zona='METRO'
   Begin
     Select * From #ConVtasCobro Order by NombreAg
   End
Else 
   IF @Zona<>'METRO'
      Begin
         Select * From #ConVtasCobro Order by Agente
	  End
End





