/****** Object:  StoredProcedure [dbo].[sp_VentasxCliente]    Script Date: 05/05/2017 15:35:21 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER          Procedure [dbo].[sp_VentasxCliente]
@Empresa char(5),
@Ejercicio Int,
@Periodo1 Int, 
@Periodo2 Int,
@Periodo3 Int,
@Usuario Char(10),
-- modify 05/05/17 @Familia Varchar(50),
@Grupo varchar(50),
@AgenteD char(10),
@AgenteA char(10),
@Sucursal int,
@Zona           Varchar(30) --cambiado/agregado para nuevo filtro Diciembre 2014
As
Begin

--sp_VentasxCliente 'LABC', 2008, 01, 01, 01, 'GVT', '(Todos)', '(Todos)', 'AMO', 'RJM', 0

Create Table #Ventas(
Agente char(10) Null,
NomAgente varchar(100) Null,
Empresa char(5) null,
Cliente char(10) Null,
Nombre varchar(100) Null,
EnviarA int Null,
SucursalNom varchar(100) Null,
Ejercicio Int Null,
Periodo1 Money Null,
Periodo2 Money Null,
Periodo3 Money Null,
Presupuesto1 Money Null,
Presupuesto2 Money Null,
Presupuesto3 Money Null,
Periodo4 Money Null,
Periodo5 Money Null,
Periodo6 Money Null)

Declare
@Ejercicio2 Int,
@Categoria VarChar(50),
@Cliente char(10),
@EnviarA Int, 
@Ejer Int,
@Presupuesto Money,
@Familia Varchar(50)

--Select @Sucursal=NullIF(@Sucursal, '')

Select @Ejercicio2 = @Ejercicio-1

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
     
Insert Into #Ventas(Empresa,Agente, NomAgente, Cliente, Nombre, EnviarA, SucursalNom, Ejercicio, Periodo1)
SELECT a.Empresa,a.Agente,ag.Nombre,a.Cliente,c.Nombre,a.EnviarA,null,a.Ejercicio,Sum((a.Importe*a.TipoCambio)-((IsNull(a.AnticiposFacturados,0)-IsNull(AnticiposImpuestos,0))*a.TipoCambio)) 
    FROM Venta a, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     AND mt.Modulo = 'VTAS'
     AND mt.Clave = 'VTAS.F'
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     AND a.Estatus = 'CONCLUIDO'
--     And IsNull(Ag.Categoria, '') = IsNull(IsNull(@Categoria, Ag.Categoria), '')
-- modify 05/05/17     And IsNull(Ag.Familia, '') = IsNull(IsNull(@Familia, Ag.Familia), '')
     And IsNull(Ag.Grupo, '') = IsNull(IsNull(@Grupo, Ag.Grupo), '')
     And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     AND a.Ejercicio = @Ejercicio
     AND a.Periodo = @Periodo1
     AND a.Empresa = Isnull(@Empresa,a.Empresa)
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
Group By a.Agente, ag.Nombre, a.Empresa,a.Cliente, c.Nombre, a.EnviarA, a.Ejercicio
----Agregado para las Notas de Cargo
Insert Into #Ventas(Empresa,Agente, NomAgente, Cliente, Nombre, EnviarA, SucursalNom, Ejercicio, Periodo1)
SELECT a.Empresa,a.Agente,ag.Nombre,a.Cliente,c.Nombre,a.ClienteEnviarA,null,a.Ejercicio,Sum((a.Importe*a.TipoCambio))
    FROM Cxc a,  MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     --AND a.ID=CxcD.ID
     AND mt.Modulo = 'CXC'
     AND mt.Clave In ('CXC.CA')
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     AND a.Estatus In ('CONCLUIDO', 'PENDIENTE')
--     And IsNull(Ag.Categoria, '') = IsNull(IsNull(@Categoria, Ag.Categoria), '')
-- modify 05/05/17     And IsNull(Ag.Familia, '') = IsNull(IsNull(@Familia, Ag.Familia), '')
     And IsNull(Ag.Grupo, '') = IsNull(IsNull(@Grupo, Ag.Grupo), '')
     And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     AND a.Ejercicio = @Ejercicio
     AND a.Periodo = @Periodo1
     AND a.Empresa = Isnull(@Empresa,a.Empresa)
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
Group By a.Agente, ag.Nombre,a.Empresa, a.Cliente, c.Nombre, a.ClienteEnviarA, a.Ejercicio
---- fin del agregado para notas de Cargo
Insert Into #Ventas(Empresa,Agente, NomAgente, Cliente, Nombre, EnviarA, SucursalNom, Ejercicio, Periodo1)
SELECT a.Empresa,a.Agente,ag.Nombre,a.Cliente,c.Nombre,a.EnviarA,null,a.Ejercicio,Sum(-(a.Importe*a.TipoCambio))
    FROM Venta a, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     AND mt.Modulo = 'VTAS'
     AND mt.Clave = 'VTAS.D'
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     AND a.Estatus = 'CONCLUIDO'
--     And IsNull(Ag.Categoria, '') = IsNull(IsNull(@Categoria, Ag.Categoria), '')
-- modify 05/05/17     And IsNull(Ag.Familia, '') = IsNull(IsNull(@Familia, Ag.Familia), '')
     And IsNull(Ag.Grupo, '') = IsNull(IsNull(@Grupo, Ag.Grupo), '')
     And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     AND a.Ejercicio = @Ejercicio
     AND a.Periodo = @Periodo1
     AND a.Empresa = Isnull(@Empresa,a.Empresa)
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
Group By a.Agente, ag.Nombre,a.Empresa, a.Cliente, c.Nombre, a.EnviarA, a.Ejercicio

Insert Into #Ventas(Empresa,Agente, NomAgente, Cliente, Nombre, EnviarA, SucursalNom, Ejercicio, Periodo1)
SELECT a.Empresa,a.Agente,ag.Nombre,a.Cliente,c.Nombre,a.ClienteEnviarA,null,a.Ejercicio,Sum(-(a.Importe*a.TipoCambio))
    FROM Cxc a, CxcD, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     AND a.ID=CxcD.ID
     AND mt.Modulo = 'CXC'
     AND mt.Clave In ('CXC.NC')
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     AND a.Estatus In ('CONCLUIDO', 'PENDIENTE')
--     And IsNull(Ag.Categoria, '') = IsNull(IsNull(@Categoria, Ag.Categoria), '')
-- modify 05/05/17     And IsNull(Ag.Familia, '') = IsNull(IsNull(@Familia, Ag.Familia), '')
     And IsNull(Ag.Grupo, '') = IsNull(IsNull(@Grupo, Ag.Grupo), '')
     And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     AND a.Ejercicio = @Ejercicio
     AND a.Periodo = @Periodo1
     AND a.Empresa = Isnull(@Empresa,a.Empresa)
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
     AND CxcD.Aplica In  ('Factura Anticipo','Factura Anticipo CFD')
Group By a.Agente, ag.Nombre, a.Empresa,a.Cliente, c.Nombre, a.ClienteEnviarA, a.Ejercicio

Insert Into #Ventas(Empresa,Agente, NomAgente, Cliente, Nombre, EnviarA, SucursalNom, Ejercicio, Periodo1)
SELECT a.Empresa,a.Agente,ag.Nombre,a.Cliente,c.Nombre,a.ClienteEnviarA,null,a.Ejercicio,Sum(a.Importe*a.TipoCambio)
    FROM Cxc a, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     AND mt.Modulo = 'CXC'
     AND mt.Clave In ('CXC.FA')--, 'CXC.NC')
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     AND a.Estatus In ('CONCLUIDO', 'PENDIENTE')
--     And IsNull(Ag.Categoria, '') = IsNull(IsNull(@Categoria, Ag.Categoria), '')
-- modify 05/05/17     And IsNull(Ag.Familia, '') = IsNull(IsNull(@Familia, Ag.Familia), '')
     And IsNull(Ag.Grupo, '') = IsNull(IsNull(@Grupo, Ag.Grupo), '')
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
     AND a.Ejercicio = @Ejercicio
     AND a.Periodo = @Periodo1
     AND a.Empresa = Isnull(@Empresa,a.Empresa)
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
Group By a.Agente, ag.Nombre, a.Empresa,a.Cliente, c.Nombre, a.ClienteEnviarA, a.Ejercicio
----fin del periodo 1
Insert Into #Ventas(Empresa,Agente, NomAgente, Cliente, Nombre, EnviarA, SucursalNom, Ejercicio, Periodo2)
SELECT a.Empresa,a.Agente,ag.Nombre,a.Cliente,c.Nombre,a.EnviarA,null,a.Ejercicio,Sum((a.Importe*a.TipoCambio)-((IsNull(a.AnticiposFacturados,0)-IsNull(AnticiposImpuestos,0))*a.TipoCambio)) 
    FROM Venta a, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     AND mt.Modulo = 'VTAS'
     AND mt.Clave = 'VTAS.F'
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     AND a.Estatus = 'CONCLUIDO'
--     And IsNull(Ag.Categoria, '') = IsNull(IsNull(@Categoria, Ag.Categoria), '')
-- modify 05/05/17     And IsNull(Ag.Familia, '') = IsNull(IsNull(@Familia, Ag.Familia), '')
     And IsNull(Ag.Grupo, '') = IsNull(IsNull(@Grupo, Ag.Grupo), '')
     And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     AND a.Ejercicio = @Ejercicio
     AND a.Periodo = @Periodo2
     AND a.Empresa = Isnull(@Empresa,a.Empresa)
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
Group By a.Agente, ag.Nombre,a.Empresa, a.Cliente, c.Nombre, a.EnviarA, a.Ejercicio
----Agregado para las Notas de Cargo
Insert Into #Ventas(Empresa,Agente, NomAgente, Cliente, Nombre, EnviarA, SucursalNom, Ejercicio, Periodo1)
SELECT a.Empresa,a.Agente,ag.Nombre,a.Cliente,c.Nombre,a.ClienteEnviarA,null,a.Ejercicio,Sum((a.Importe*a.TipoCambio))
    FROM Cxc a, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     --AND a.ID=CxcD.ID
     AND mt.Modulo = 'CXC'
     AND mt.Clave In ('CXC.CA')
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     AND a.Estatus In ('CONCLUIDO', 'PENDIENTE')
--     And IsNull(Ag.Categoria, '') = IsNull(IsNull(@Categoria, Ag.Categoria), '')
-- modify 05/05/17     And IsNull(Ag.Familia, '') = IsNull(IsNull(@Familia, Ag.Familia), '')
     And IsNull(Ag.Grupo, '') = IsNull(IsNull(@Grupo, Ag.Grupo), '')
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
     AND a.Ejercicio = @Ejercicio
     AND a.Periodo = @Periodo2
     AND a.Empresa = Isnull(@Empresa,a.Empresa)
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
Group By a.Agente, ag.Nombre,a.Empresa, a.Cliente, c.Nombre, a.ClienteEnviarA, a.Ejercicio
---- fin del agregado para notas de Cargo

Insert Into #Ventas(Empresa,Agente, NomAgente, Cliente, Nombre, EnviarA, SucursalNom, Ejercicio, Periodo2)
SELECT a.Empresa,a.Agente,ag.Nombre,a.Cliente,c.Nombre,a.EnviarA,null,a.Ejercicio,Sum(-(a.Importe*a.TipoCambio))
    FROM Venta a, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     AND mt.Modulo = 'VTAS'
     AND mt.Clave = 'VTAS.D'
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     AND a.Estatus = 'CONCLUIDO'
--     And IsNull(Ag.Categoria, '') = IsNull(IsNull(@Categoria, Ag.Categoria), '')
-- modify 05/05/17     And IsNull(Ag.Familia, '') = IsNull(IsNull(@Familia, Ag.Familia), '')
     And IsNull(Ag.Grupo, '') = IsNull(IsNull(@Grupo, Ag.Grupo), '')
     And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     AND a.Ejercicio = @Ejercicio
     AND a.Periodo = @Periodo2
     AND a.Empresa = Isnull(@Empresa,a.Empresa)
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
Group By a.Agente, ag.Nombre,a.Empresa, a.Cliente, c.Nombre, a.EnviarA, a.Ejercicio

Insert Into #Ventas(Empresa,Agente, NomAgente, Cliente, Nombre, EnviarA, SucursalNom, Ejercicio, Periodo2)
SELECT a.Empresa,a.Agente,ag.Nombre,a.Cliente,c.Nombre,a.ClienteEnviarA,null,a.Ejercicio,Sum(-(a.Importe*a.TipoCambio))
    FROM Cxc a, CxcD, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     AND a.ID=CxcD.ID
     AND mt.Modulo = 'CXC'
     AND mt.Clave In ('CXC.NC')
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     AND a.Estatus In ('CONCLUIDO', 'PENDIENTE')
--     And IsNull(Ag.Categoria, '') = IsNull(IsNull(@Categoria, Ag.Categoria), '')
-- modify 05/05/17     And IsNull(Ag.Familia, '') = IsNull(IsNull(@Familia, Ag.Familia), '')
     And IsNull(Ag.Grupo, '') = IsNull(IsNull(@Grupo, Ag.Grupo), '')
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
     AND a.Ejercicio = @Ejercicio
     AND a.Periodo = @Periodo2
     AND a.Empresa = Isnull(@Empresa,a.Empresa)
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
     AND CxcD.Aplica In ('Factura Anticipo','Factura Anticipo CFD')
Group By a.Agente, ag.Nombre,a.Empresa,a.Cliente, c.Nombre, a.ClienteEnviarA, a.Ejercicio

Insert Into #Ventas(Empresa,Agente, NomAgente, Cliente, Nombre, EnviarA, SucursalNom, Ejercicio, Periodo2)
SELECT a.Empresa,a.Agente,ag.Nombre,a.Cliente,c.Nombre,a.ClienteEnviarA,null,a.Ejercicio,Sum(a.Importe*a.TipoCambio)
    FROM Cxc a, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     AND mt.Modulo = 'CXC'
     AND mt.Clave In ('CXC.FA')--, 'CXC.NC')
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     AND a.Estatus In ('CONCLUIDO', 'PENDIENTE')
--     And IsNull(Ag.Categoria, '') = IsNull(IsNull(@Categoria, Ag.Categoria), '')
-- modify 05/05/17     And IsNull(Ag.Familia, '') = IsNull(IsNull(@Familia, Ag.Familia), '')
     And IsNull(Ag.Grupo, '') = IsNull(IsNull(@Grupo, Ag.Grupo), '')
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
     AND a.Ejercicio = @Ejercicio
     AND a.Periodo = @Periodo2
     AND a.Empresa = Isnull(@Empresa,a.Empresa)
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
Group By a.Agente, ag.Nombre,a.Empresa, a.Cliente, c.Nombre, a.ClienteEnviarA, a.Ejercicio

----fin del periodo 2
----
Insert Into #Ventas(Empresa,Agente, NomAgente, Cliente, Nombre, EnviarA, SucursalNom, Ejercicio, Periodo3)
SELECT a.Empresa,a.Agente,ag.Nombre,a.Cliente,c.Nombre,a.EnviarA,null,a.Ejercicio,Sum((a.Importe*a.TipoCambio)-((IsNull(a.AnticiposFacturados,0)-IsNull(AnticiposImpuestos,0))*a.TipoCambio)) 
    FROM Venta a, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     AND mt.Modulo = 'VTAS'
     AND mt.Clave = 'VTAS.F'
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     AND a.Estatus = 'CONCLUIDO'
--     And IsNull(Ag.Categoria, '') = IsNull(IsNull(@Categoria, Ag.Categoria), '')
-- modify 05/05/17     And IsNull(Ag.Familia, '') = IsNull(IsNull(@Familia, Ag.Familia), '')
     And IsNull(Ag.Grupo, '') = IsNull(IsNull(@Grupo, Ag.Grupo), '')
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
     AND a.Ejercicio = @Ejercicio
     AND a.Periodo = @Periodo3
     AND a.Empresa = Isnull(@Empresa,a.Empresa)
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
Group By a.Agente, ag.Nombre,a.Empresa, a.Cliente, c.Nombre, a.EnviarA, a.Ejercicio
----Agregado para las Notas de Cargo
Insert Into #Ventas(Empresa,Agente, NomAgente, Cliente, Nombre, EnviarA, SucursalNom, Ejercicio, Periodo1)
SELECT a.Empresa,a.Agente,ag.Nombre,a.Cliente,c.Nombre,a.ClienteEnviarA,null,a.Ejercicio,Sum((a.Importe*a.TipoCambio))
    FROM Cxc a, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     --AND a.ID=CxcD.ID
     AND mt.Modulo = 'CXC'
     AND mt.Clave In ('CXC.CA')
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     AND a.Estatus In ('CONCLUIDO', 'PENDIENTE')
--     And IsNull(Ag.Categoria, '') = IsNull(IsNull(@Categoria, Ag.Categoria), '')
-- modify 05/05/17     And IsNull(Ag.Familia, '') = IsNull(IsNull(@Familia, Ag.Familia), '')
     And IsNull(Ag.Grupo, '') = IsNull(IsNull(@Grupo, Ag.Grupo), '')
     And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     AND a.Ejercicio = @Ejercicio
     AND a.Periodo = @Periodo3
     AND a.Empresa = Isnull(@Empresa,a.Empresa)
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
Group By a.Agente, ag.Nombre,a.Empresa, a.Cliente, c.Nombre, a.ClienteEnviarA, a.Ejercicio
---- fin del agregado para notas de Cargo

Insert Into #Ventas(Empresa,Agente, NomAgente, Cliente, Nombre, EnviarA, SucursalNom, Ejercicio, Periodo3)
SELECT a.Empresa,a.Agente,ag.Nombre,a.Cliente,c.Nombre,a.EnviarA,null,a.Ejercicio,Sum(-(a.Importe*a.TipoCambio))
    FROM Venta a, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     AND mt.Modulo = 'VTAS'
     AND mt.Clave = 'VTAS.D'
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     AND a.Estatus = 'CONCLUIDO'
--     And IsNull(Ag.Categoria, '') = IsNull(IsNull(@Categoria, Ag.Categoria), '')
-- modify 05/05/17     And IsNull(Ag.Familia, '') = IsNull(IsNull(@Familia, Ag.Familia), '')
     And IsNull(Ag.Grupo, '') = IsNull(IsNull(@Grupo, Ag.Grupo), '')
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
     AND a.Ejercicio = @Ejercicio
     AND a.Periodo = @Periodo3
     AND a.Empresa = Isnull(@Empresa,a.Empresa)
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
Group By a.Agente, ag.Nombre,a.Empresa, a.Cliente, c.Nombre, a.EnviarA, a.Ejercicio

Insert Into #Ventas(Empresa,Agente, NomAgente, Cliente, Nombre, EnviarA, SucursalNom, Ejercicio, Periodo3)
SELECT a.Empresa,a.Agente,ag.Nombre,a.Cliente,c.Nombre,a.ClienteEnviarA,null,a.Ejercicio,Sum(-(a.Importe*a.TipoCambio))
    FROM Cxc a, CxcD, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     AND a.ID=CxcD.ID
     AND mt.Modulo = 'CXC'
     AND mt.Clave In ('CXC.NC')
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     AND a.Estatus In ('CONCLUIDO', 'PENDIENTE')
--     And IsNull(Ag.Categoria, '') = IsNull(IsNull(@Categoria, Ag.Categoria), '')
-- modify 05/05/17     And IsNull(Ag.Familia, '') = IsNull(IsNull(@Familia, Ag.Familia), '')
     And IsNull(Ag.Grupo, '') = IsNull(IsNull(@Grupo, Ag.Grupo), '')
     And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     AND a.Ejercicio = @Ejercicio
     AND a.Periodo = @Periodo3
     AND a.Empresa = Isnull(@Empresa,a.Empresa)
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
     AND CxcD.Aplica In ('Factura Anticipo','Factura Anticipo CFD')
Group By a.Agente, ag.Nombre,a.Empresa, a.Cliente, c.Nombre, a.ClienteEnviarA, a.Ejercicio

Insert Into #Ventas(Empresa,Agente, NomAgente, Cliente, Nombre, EnviarA, SucursalNom, Ejercicio, Periodo3)
SELECT a.Empresa,a.Agente,ag.Nombre,a.Cliente,c.Nombre,a.ClienteEnviarA,null,a.Ejercicio,Sum(a.Importe*a.TipoCambio)
    FROM Cxc a, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     AND mt.Modulo = 'CXC'
     AND mt.Clave In ('CXC.FA')--, 'CXC.NC')
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     AND a.Estatus In ('CONCLUIDO', 'PENDIENTE')
--     And IsNull(Ag.Categoria, '') = IsNull(IsNull(@Categoria, Ag.Categoria), '')
-- modify 05/05/17     And IsNull(Ag.Familia, '') = IsNull(IsNull(@Familia, Ag.Familia), '')
     And IsNull(Ag.Grupo, '') = IsNull(IsNull(@Grupo, Ag.Grupo), '')
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
     AND a.Ejercicio = @Ejercicio
     AND a.Periodo = @Periodo3
     AND a.Empresa = Isnull(@Empresa,a.Empresa)
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
Group By a.Agente, ag.Nombre,a.Empresa, a.Cliente, c.Nombre, a.ClienteEnviarA, a.Ejercicio
----fin del periodo 3

/***** Se Calcula el Ejercicio Anterior *****/
-----------------
-----------------
Insert Into #Ventas(Empresa,Agente, NomAgente, Cliente, Nombre, EnviarA, SucursalNom, Ejercicio, Periodo4)
SELECT a.Empresa,a.Agente,ag.Nombre,a.Cliente,c.Nombre,a.EnviarA,null,a.Ejercicio,Sum((a.Importe*a.TipoCambio)-((IsNull(a.AnticiposFacturados,0)-IsNull(AnticiposImpuestos,0))*a.TipoCambio)) 
    FROM Venta a, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     AND mt.Modulo = 'VTAS'
     AND mt.Clave = 'VTAS.F'
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     AND a.Estatus = 'CONCLUIDO'
--     And IsNull(Ag.Categoria, '') = IsNull(IsNull(@Categoria, Ag.Categoria), '')
-- modify 05/05/17     And IsNull(Ag.Familia, '') = IsNull(IsNull(@Familia, Ag.Familia), '')
     And IsNull(Ag.Grupo, '') = IsNull(IsNull(@Grupo, Ag.Grupo), '')
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
     AND a.Ejercicio = @Ejercicio2
     AND a.Periodo = @Periodo1
     AND a.Empresa = Isnull(@Empresa,a.Empresa)
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
Group By a.Agente, ag.Nombre,a.Empresa, a.Cliente, c.Nombre, a.EnviarA, a.Ejercicio
----Agregado para las Notas de Cargo
Insert Into #Ventas(Empresa,Agente, NomAgente, Cliente, Nombre, EnviarA, SucursalNom, Ejercicio, Periodo1)
SELECT a.Empresa,a.Agente,ag.Nombre,a.Cliente,c.Nombre,a.ClienteEnviarA,null,a.Ejercicio,Sum((a.Importe*a.TipoCambio))
    FROM Cxc a, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     --AND a.ID=CxcD.ID
     AND mt.Modulo = 'CXC'
     AND mt.Clave In ('CXC.CA')
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     AND a.Estatus In ('CONCLUIDO', 'PENDIENTE')
--     And IsNull(Ag.Categoria, '') = IsNull(IsNull(@Categoria, Ag.Categoria), '')
-- modify 05/05/17     And IsNull(Ag.Familia, '') = IsNull(IsNull(@Familia, Ag.Familia), '')
     And IsNull(Ag.Grupo, '') = IsNull(IsNull(@Grupo, Ag.Grupo), '')
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
     AND a.Ejercicio = @Ejercicio2
     AND a.Periodo = @Periodo1
     AND a.Empresa = Isnull(@Empresa,a.Empresa)
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
Group By a.Agente, ag.Nombre, a.Empresa,a.Cliente, c.Nombre, a.ClienteEnviarA, a.Ejercicio
---- fin del agregado para notas de Cargo

Insert Into #Ventas(Empresa,Agente, NomAgente, Cliente, Nombre, EnviarA, SucursalNom, Ejercicio, Periodo4)
SELECT a.Empresa,a.Agente,ag.Nombre,a.Cliente,c.Nombre,a.EnviarA,null,a.Ejercicio,Sum(-(a.Importe*a.TipoCambio))
    FROM Venta a, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     AND mt.Modulo = 'VTAS'
     AND mt.Clave = 'VTAS.D'
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     AND a.Estatus = 'CONCLUIDO'
--     And IsNull(Ag.Categoria, '') = IsNull(IsNull(@Categoria, Ag.Categoria), '')
-- modify 05/05/17     And IsNull(Ag.Familia, '') = IsNull(IsNull(@Familia, Ag.Familia), '')
     And IsNull(Ag.Grupo, '') = IsNull(IsNull(@Grupo, Ag.Grupo), '')
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
     AND a.Ejercicio = @Ejercicio2
     AND a.Periodo = @Periodo1
     AND a.Empresa = ISnull(@Empresa,a.Empresa)
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
Group By a.Agente, ag.Nombre,a.Empresa, a.Cliente, c.Nombre, a.EnviarA, a.Ejercicio

Insert Into #Ventas(Empresa,Agente, NomAgente, Cliente, Nombre, EnviarA, SucursalNom, Ejercicio, Periodo4)
SELECT a.Empresa,a.Agente,ag.Nombre,a.Cliente,c.Nombre,a.ClienteEnviarA,null,a.Ejercicio,Sum(-(a.Importe*a.TipoCambio))
    FROM Cxc a, CxcD, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     AND a.ID=CxcD.ID
     AND mt.Modulo = 'CXC'
     AND mt.Clave In ('CXC.NC')
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     AND a.Estatus In ('CONCLUIDO', 'PENDIENTE')
--     And IsNull(Ag.Categoria, '') = IsNull(IsNull(@Categoria, Ag.Categoria), '')
-- modify 05/05/17     And IsNull(Ag.Familia, '') = IsNull(IsNull(@Familia, Ag.Familia), '')
     And IsNull(Ag.Grupo, '') = IsNull(IsNull(@Grupo, Ag.Grupo), '')
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
     AND a.Ejercicio = @Ejercicio2
     AND a.Periodo = @Periodo1
     AND a.Empresa = Isnull(@Empresa,a.Empresa)
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
     AND CxcD.Aplica In ('Factura Anticipo','Factura Anticipo CFD')
Group By a.Agente, ag.Nombre, a.Empresa,a.Cliente, c.Nombre, a.ClienteEnviarA, a.Ejercicio

Insert Into #Ventas(Empresa,Agente, NomAgente, Cliente, Nombre, EnviarA, SucursalNom, Ejercicio, Periodo4)
SELECT a.Empresa,a.Agente,ag.Nombre,a.Cliente,c.Nombre,a.ClienteEnviarA,null,a.Ejercicio,Sum(a.Importe*a.TipoCambio)
    FROM Cxc a, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     AND mt.Modulo = 'CXC'
     AND mt.Clave In ('CXC.FA')--, 'CXC.NC')
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     AND a.Estatus In ('CONCLUIDO', 'PENDIENTE')
--     And IsNull(Ag.Categoria, '') = IsNull(IsNull(@Categoria, Ag.Categoria), '')
-- modify 05/05/17     And IsNull(Ag.Familia, '') = IsNull(IsNull(@Familia, Ag.Familia), '')
     And IsNull(Ag.Grupo, '') = IsNull(IsNull(@Grupo, Ag.Grupo), '')
     And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     AND a.Ejercicio = @Ejercicio2
     AND a.Periodo = @Periodo1
     AND a.Empresa = Isnull(@Empresa,a.Empresa)
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
Group By a.Agente, ag.Nombre,a.Empresa, a.Cliente, c.Nombre, a.ClienteEnviarA, a.Ejercicio
----fin del periodo 1
Insert Into #Ventas(Empresa,Agente, NomAgente, Cliente, Nombre, EnviarA, SucursalNom, Ejercicio, Periodo5)
SELECT a.Empresa,a.Agente,ag.Nombre,a.Cliente,c.Nombre,a.EnviarA,null,a.Ejercicio,Sum((a.Importe*a.TipoCambio)-((IsNull(a.AnticiposFacturados,0)-IsNull(AnticiposImpuestos,0))*a.TipoCambio)) 
    FROM Venta a, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     AND mt.Modulo = 'VTAS'
     AND mt.Clave = 'VTAS.F'
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     AND a.Estatus = 'CONCLUIDO'
--     And IsNull(Ag.Categoria, '') = IsNull(IsNull(@Categoria, Ag.Categoria), '')
-- modify 05/05/17     And IsNull(Ag.Familia, '') = IsNull(IsNull(@Familia, Ag.Familia), '')
     And IsNull(Ag.Grupo, '') = IsNull(IsNull(@Grupo, Ag.Grupo), '')
     And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     AND a.Ejercicio = @Ejercicio2
     AND a.Periodo = @Periodo2
     AND a.Empresa = Isnull(@Empresa,a.Empresa)
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
Group By a.Agente, ag.Nombre,a.Empresa, a.Cliente, c.Nombre, a.EnviarA, a.Ejercicio
----Agregado para las Notas de Cargo
Insert Into #Ventas(Empresa,Agente, NomAgente, Cliente, Nombre, EnviarA, SucursalNom, Ejercicio, Periodo1)
SELECT a.Empresa,a.Agente,ag.Nombre,a.Cliente,c.Nombre,a.ClienteEnviarA,null,a.Ejercicio,Sum((a.Importe*a.TipoCambio))
    FROM Cxc a, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     --AND a.ID=CxcD.ID
     AND mt.Modulo = 'CXC'
     AND mt.Clave In ('CXC.CA')
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     AND a.Estatus In ('CONCLUIDO', 'PENDIENTE')
--     And IsNull(Ag.Categoria, '') = IsNull(IsNull(@Categoria, Ag.Categoria), '')
-- modify 05/05/17     And IsNull(Ag.Familia, '') = IsNull(IsNull(@Familia, Ag.Familia), '')
     And IsNull(Ag.Grupo, '') = IsNull(IsNull(@Grupo, Ag.Grupo), '')
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
     AND a.Ejercicio = @Ejercicio2
     AND a.Periodo = @Periodo2
     AND a.Empresa = Isnull(@Empresa,a.Empresa)
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
Group By a.Agente, ag.Nombre,a.Empresa, a.Cliente, c.Nombre, a.ClienteEnviarA, a.Ejercicio
---- fin del agregado para notas de Cargo

Insert Into #Ventas(Empresa,Agente, NomAgente, Cliente, Nombre, EnviarA, SucursalNom, Ejercicio, Periodo5)
SELECT a.Empresa,a.Agente,ag.Nombre,a.Cliente,c.Nombre,a.EnviarA,null,a.Ejercicio,Sum(-(a.Importe*a.TipoCambio))
    FROM Venta a, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     AND mt.Modulo = 'VTAS'
     AND mt.Clave = 'VTAS.D'
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     AND a.Estatus = 'CONCLUIDO'
--     And IsNull(Ag.Categoria, '') = IsNull(IsNull(@Categoria, Ag.Categoria), '')
-- modify 05/05/17     And IsNull(Ag.Familia, '') = IsNull(IsNull(@Familia, Ag.Familia), '')
     And IsNull(Ag.Grupo, '') = IsNull(IsNull(@Grupo, Ag.Grupo), '')
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
     AND a.Ejercicio = @Ejercicio2
     AND a.Periodo = @Periodo2
     AND a.Empresa = ISnull(@Empresa,a.Empresa)
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
Group By a.Agente, ag.Nombre, a.Empresa,a.Cliente, c.Nombre, a.EnviarA, a.Ejercicio

Insert Into #Ventas(Empresa,Agente, NomAgente, Cliente, Nombre, EnviarA, SucursalNom, Ejercicio, Periodo5)
SELECT a.Empresa,a.Agente,ag.Nombre,a.Cliente,c.Nombre,a.ClienteEnviarA,null,a.Ejercicio,Sum(-(a.Importe*a.TipoCambio))
    FROM Cxc a, CxcD, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     AND a.ID=CxcD.ID
     AND mt.Modulo = 'CXC'
     AND mt.Clave In ('CXC.NC')
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     AND a.Estatus In ('CONCLUIDO', 'PENDIENTE')
--     And IsNull(Ag.Categoria, '') = IsNull(IsNull(@Categoria, Ag.Categoria), '')
-- modify 05/05/17     And IsNull(Ag.Familia, '') = IsNull(IsNull(@Familia, Ag.Familia), '')
     And IsNull(Ag.Grupo, '') = IsNull(IsNull(@Grupo, Ag.Grupo), '')
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
     AND a.Ejercicio = @Ejercicio2
     AND a.Periodo = @Periodo2
     AND a.Empresa = Isnull(@Empresa,a.Empresa)
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
     AND CxcD.Aplica In ('Factura Anticipo','Factura Anticipo CFD')
Group By a.Agente, ag.Nombre,a.Empresa, a.Cliente, c.Nombre, a.ClienteEnviarA, a.Ejercicio

Insert Into #Ventas(Empresa,Agente, NomAgente, Cliente, Nombre, EnviarA, SucursalNom, Ejercicio, Periodo5)
SELECT a.Empresa,a.Agente,ag.Nombre,a.Cliente,c.Nombre,a.ClienteEnviarA,null,a.Ejercicio,Sum(a.Importe*a.TipoCambio)
    FROM Cxc a, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     AND mt.Modulo = 'CXC'
     AND mt.Clave In ('CXC.FA')--, 'CXC.NC')
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     AND a.Estatus In ('CONCLUIDO', 'PENDIENTE')
--     And IsNull(Ag.Categoria, '') = IsNull(IsNull(@Categoria, Ag.Categoria), '')
-- modify 05/05/17     And IsNull(Ag.Familia, '') = IsNull(IsNull(@Familia, Ag.Familia), '')
     And IsNull(Ag.Grupo, '') = IsNull(IsNull(@Grupo, Ag.Grupo), '')
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
     AND a.Ejercicio = @Ejercicio2
     AND a.Periodo = @Periodo2
     AND a.Empresa = Isnull(@Empresa,a.Empresa)
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
Group By a.Agente, ag.Nombre,a.Empresa, a.Cliente, c.Nombre, a.ClienteEnviarA, a.Ejercicio

----fin del periodo 2
----
Insert Into #Ventas(Empresa,Agente, NomAgente, Cliente, Nombre, EnviarA, SucursalNom, Ejercicio, Periodo6)
SELECT a.Empresa,a.Agente,ag.Nombre,a.Cliente,c.Nombre,a.EnviarA,null,a.Ejercicio,Sum((a.Importe*a.TipoCambio)-((IsNull(a.AnticiposFacturados,0)-IsNull(AnticiposImpuestos,0))*a.TipoCambio)) 
    FROM Venta a, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     AND mt.Modulo = 'VTAS'
     AND mt.Clave = 'VTAS.F'
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     AND a.Estatus = 'CONCLUIDO'
--     And IsNull(Ag.Categoria, '') = IsNull(IsNull(@Categoria, Ag.Categoria), '')
-- modify 05/05/17     And IsNull(Ag.Familia, '') = IsNull(IsNull(@Familia, Ag.Familia), '')
     And IsNull(Ag.Grupo, '') = IsNull(IsNull(@Grupo, Ag.Grupo), '')
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
     AND a.Ejercicio = @Ejercicio2
     AND a.Periodo = @Periodo3
     AND a.Empresa = Isnull(@Empresa,a.Empresa)
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
Group By a.Agente, ag.Nombre, a.Empresa,a.Cliente, c.Nombre, a.EnviarA, a.Ejercicio
----Agregado para las Notas de Cargo
Insert Into #Ventas(Empresa,Agente, NomAgente, Cliente, Nombre, EnviarA, SucursalNom, Ejercicio, Periodo1)
SELECT a.Empresa,a.Agente,ag.Nombre,a.Cliente,c.Nombre,a.ClienteEnviarA,null,a.Ejercicio,Sum((a.Importe*a.TipoCambio))
    FROM Cxc a, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     --AND a.ID=CxcD.ID
     AND mt.Modulo = 'CXC'
     AND mt.Clave In ('CXC.CA')
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     AND a.Estatus In ('CONCLUIDO', 'PENDIENTE')
--     And IsNull(Ag.Categoria, '') = IsNull(IsNull(@Categoria, Ag.Categoria), '')
-- modify 05/05/17     And IsNull(Ag.Familia, '') = IsNull(IsNull(@Familia, Ag.Familia), '')
     And IsNull(Ag.Grupo, '') = IsNull(IsNull(@Grupo, Ag.Grupo), '')
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
     AND a.Ejercicio = @Ejercicio2
     AND a.Periodo = @Periodo3
     AND a.Empresa = Isnull(@Empresa,a.Empresa)
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
Group By a.Agente, ag.Nombre,a.Empresa, a.Cliente, c.Nombre, a.ClienteEnviarA, a.Ejercicio
---- fin del agregado para notas de Cargo

Insert Into #Ventas(Empresa,Agente, NomAgente, Cliente, Nombre, EnviarA, SucursalNom, Ejercicio, Periodo6)
SELECT a.Empresa,a.Agente,ag.Nombre,a.Cliente,c.Nombre,a.EnviarA,null,a.Ejercicio,Sum(-(a.Importe*a.TipoCambio))
    FROM Venta a, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     AND mt.Modulo = 'VTAS'
     AND mt.Clave = 'VTAS.D'
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     AND a.Estatus = 'CONCLUIDO'
--     And IsNull(Ag.Categoria, '') = IsNull(IsNull(@Categoria, Ag.Categoria), '')
-- modify 05/05/17     And IsNull(Ag.Familia, '') = IsNull(IsNull(@Familia, Ag.Familia), '')
     And IsNull(Ag.Grupo, '') = IsNull(IsNull(@Grupo, Ag.Grupo), '')
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
     AND a.Ejercicio = @Ejercicio2
     AND a.Periodo = @Periodo3
     AND a.Empresa = ISnull(@Empresa,a.Empresa)
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
Group By a.Agente, ag.Nombre,a.Empresa, a.Cliente, c.Nombre, a.EnviarA, a.Ejercicio

Insert Into #Ventas(Empresa,Agente, NomAgente, Cliente, Nombre, EnviarA, SucursalNom, Ejercicio, Periodo6)
SELECT a.Empresa,a.Agente,ag.Nombre,a.Cliente,c.Nombre,a.ClienteEnviarA,null,a.Ejercicio,Sum(-(a.Importe*a.TipoCambio))
    FROM Cxc a, CxcD, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     AND a.ID=CxcD.ID
     AND mt.Modulo = 'CXC'
     AND mt.Clave In ('CXC.NC')
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     AND a.Estatus In ('CONCLUIDO', 'PENDIENTE')
--     And IsNull(Ag.Categoria, '') = IsNull(IsNull(@Categoria, Ag.Categoria), '')
-- modify 05/05/17     And IsNull(Ag.Familia, '') = IsNull(IsNull(@Familia, Ag.Familia), '')
     And IsNull(Ag.Grupo, '') = IsNull(IsNull(@Grupo, Ag.Grupo), '')
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
     AND a.Ejercicio = @Ejercicio2
     AND a.Periodo = @Periodo3
     AND a.Empresa = Isnull(@Empresa,a.Empresa)
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
     AND CxcD.Aplica In ('Factura Anticipo','Factura Anticipo CFD')
Group By a.Agente, ag.Nombre,a.Empresa, a.Cliente, c.Nombre, a.ClienteEnviarA, a.Ejercicio

Insert Into #Ventas(Empresa,Agente, NomAgente, Cliente, Nombre, EnviarA, SucursalNom, Ejercicio, Periodo6)
SELECT a.Empresa,a.Agente,ag.Nombre,a.Cliente,c.Nombre,a.ClienteEnviarA,null,a.Ejercicio,Sum(a.Importe*a.TipoCambio)
    FROM Cxc a, MovTipo mt, Cte c, Agente ag
   WHERE a.Mov = mt.Mov
     AND mt.Modulo = 'CXC'
     AND mt.Clave In ('CXC.FA')--, 'CXC.NC')
     AND a.Cliente = c.Cliente
     AND a.Agente = ag.Agente
     AND a.Estatus In ('CONCLUIDO', 'PENDIENTE')
--     And IsNull(Ag.Categoria, '') = IsNull(IsNull(@Categoria, Ag.Categoria), '')
-- modify 05/05/17     And IsNull(Ag.Familia, '') = IsNull(IsNull(@Familia, Ag.Familia), '')
     And IsNull(Ag.Grupo, '') = IsNull(IsNull(@Grupo, Ag.Grupo), '')
     AND a.Agente BETWEEN @AgenteD AND @AgenteA
     And ag.Zona=Isnull(@Zona,ag.Zona)--cambiado/agregado para nuevo filtro Diciembre 2014
     AND a.Ejercicio = @Ejercicio2
     AND a.Periodo = @Periodo3
     AND a.Empresa = Isnull(@Empresa,a.Empresa)
     And IsNull(a.Sucursal, '') = IsNull(IsNull(@Sucursal, a.Sucursal), '')
Group By a.Agente, ag.Nombre,a.Empresa, a.Cliente, c.Nombre, a.ClienteEnviarA, a.Ejercicio
----fin del periodo 3

Declare CrPres Cursor For
Select Cliente, EnviarA From #Ventas
Open CrPres
Fetch Next From CrPres into
@Cliente, @EnviarA
While @@Fetch_Status <> - 1 And @@Error = 0
Begin
	IF @@Fetch_Status <> - 2
	Begin

/***** Validacion para Clientes q no tienen Sucursal*****/
	  IF @EnviarA Is Null
	  Begin
	    IF Exists (Select Importe From PresupuestoCtesABC Where Ejercicio=@Ejercicio And Periodo=@Periodo1
	    And Cte=@Cliente And CteEnviarA Is Null)
	    Begin
	      Select @Presupuesto=Importe From PresupuestoCtesABC Where Ejercicio=@Ejercicio And Periodo=@Periodo1
	      And Cte=@Cliente And CteEnviarA Is Null
	      Update #Ventas Set Presupuesto1=@Presupuesto Where Cliente=@Cliente And EnviarA Is Null
	    End

	  IF Exists (Select Importe From PresupuestoCtesABC Where Ejercicio=@Ejercicio And Periodo=@Periodo2
	    And Cte=@Cliente And CteEnviarA Is Null)
	    Begin
	      Select @Presupuesto=Importe From PresupuestoCtesABC Where Ejercicio=@Ejercicio And Periodo=@Periodo2
	      And Cte=@Cliente And CteEnviarA Is Null
	      Update #Ventas Set Presupuesto2=@Presupuesto Where Cliente=@Cliente And EnviarA Is Null
	    End

	  IF Exists (Select Importe From PresupuestoCtesABC Where Ejercicio=@Ejercicio And Periodo=@Periodo3
	    And Cte=@Cliente And CteEnviarA Is Null)
	    Begin
	      Select @Presupuesto=Importe From PresupuestoCtesABC Where Ejercicio=@Ejercicio And Periodo=@Periodo3
	      And Cte=@Cliente And CteEnviarA Is Null
	      Update #Ventas Set Presupuesto3=@Presupuesto Where Cliente=@Cliente And EnviarA Is Null
	    End

	   End

/***** Validacion para Clientes q si tienen Sucursal*****/
	  IF @EnviarA Is Not Null
	  Begin
	    IF Exists (Select Importe From PresupuestoCtesABC Where Ejercicio=@Ejercicio And Periodo=@Periodo1
	    And Cte=@Cliente And CteEnviarA=@EnviarA)
	    Begin
	      Select @Presupuesto=Importe From PresupuestoCtesABC Where Ejercicio=@Ejercicio And Periodo=@Periodo1
	      And Cte=@Cliente And CteEnviarA=@EnviarA
	      Update #Ventas Set Presupuesto1=@Presupuesto Where Cliente=@Cliente And EnviarA=@EnviarA
	    End

	    IF Exists (Select Importe From PresupuestoCtesABC Where Ejercicio=@Ejercicio And Periodo=@Periodo2
	    And Cte=@Cliente And CteEnviarA=@EnviarA)
	    Begin
	      Select @Presupuesto=Importe From PresupuestoCtesABC Where Ejercicio=@Ejercicio And Periodo=@Periodo2
	      And Cte=@Cliente And CteEnviarA=@EnviarA
	      Update #Ventas Set Presupuesto2=@Presupuesto Where Cliente=@Cliente And EnviarA=@EnviarA
	    End

	    IF Exists (Select Importe From PresupuestoCtesABC Where Ejercicio=@Ejercicio And Periodo=@Periodo3
	    And Cte=@Cliente And CteEnviarA=@EnviarA)
	    Begin
	      Select @Presupuesto=Importe From PresupuestoCtesABC Where Ejercicio=@Ejercicio And Periodo=@Periodo3
	      And Cte=@Cliente And CteEnviarA=@EnviarA
	      Update #Ventas Set Presupuesto3=@Presupuesto Where Cliente=@Cliente And EnviarA=@EnviarA
	    End
	    
	  End

	    
	End
Fetch Next From CrPres into
@Cliente, @EnviarA
End
Close CrPres
Deallocate CrPres



IF @Zona='METRO'
   Begin
	 Select Agente, NomAgente,Empresa, Cliente, Nombre, EnviarA, SucursalNom, --Ejercicio, 
		Periodo1=Sum(Periodo1), 
		Periodo4=Sum(Periodo4),
		Presupuesto1, 
		Periodo2=Sum(Periodo2), 
		Periodo5=Sum(Periodo5), 
		Presupuesto2, 
		Periodo3=Sum(Periodo3), 
		Periodo6=Sum(Periodo6),
		Presupuesto3
		From #Ventas
		Group By  Agente,NomAgente, Empresa,Cliente, Nombre, EnviarA, SucursalNom, /*Ejercicio,*/ Presupuesto1, Presupuesto2, Presupuesto3
		Order By  Nombre, EnviarA
		
   
   End
Else 
   IF @Zona<>'METRO' or @Zona IS NULL
      Begin
		 Select Agente, NomAgente, Cliente, Nombre, EnviarA, SucursalNom, --Ejercicio, 
			Periodo1=Sum(Periodo1), 
			Periodo4=Sum(Periodo4),
			Presupuesto1, 
			Periodo2=Sum(Periodo2), 
			Periodo5=Sum(Periodo5), 
			Presupuesto2, 
			Periodo3=Sum(Periodo3), 
			Periodo6=Sum(Periodo6),
			Presupuesto3
			From #Ventas
			Group By Agente, NomAgente, Cliente, Nombre, EnviarA, SucursalNom, /*Ejercicio,*/ Presupuesto1, Presupuesto2, Presupuesto3
			Order By Agente, Nombre, EnviarA
	  End
End










