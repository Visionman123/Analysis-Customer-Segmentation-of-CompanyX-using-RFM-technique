Use Customer_CompanyX;
----------------------------------------------------------------------------
--The following code are create 4 dimension: Date, Customer, Product and Sale Territory

Drop Table Dimdate;

CREATE TABLE DimDate(
    DateKey int IDENTITY(1,1) PRIMARY KEY,
	OrderDate datetime,
	DateID int,
	FullDateAlterKey date,
    DayNumberOfWeek int,
    DayNumberOfMonth int,
    DayNumberOfYear int,
	MonthNumberOfYear int,
	CalendarYear int,
	FiscalYear int
);

select * from DimDate

SET IDENTITY_INSERT DimDate ON;

insert into DimDate (OrderDate, DateID, FullDateAlterKey, DayNumberOfWeek, DayNumberOfMonth, DayNumberOfYear, MonthNumberOfYear, CalendarYear, FiscalYear)
select distinct CompanyX.Sales.SalesOrderHeader.OrderDate,
CONVERT(int,CONVERT(varchar,orderdate,112)) as DateID,
CONVERT(date,orderdate) as FullDateAlterKey,
DATEPART(dw,orderdate) as DayNumberOfWeek,
DATEPART(d,orderdate) as DayNumberOfMonth,
DATEPART(dy,orderdate) as DayNumberOfYear,
Month(orderdate) as MonthNumberOfYear,
year(orderdate) as CalendarYear,
year(orderdate) as FiscalYear
from CompanyX.Sales.SalesOrderHeader;


----------------------------------------------------------------------------
--DimCustomer: Using STD Type 2
Drop table DimCustomer;

CREATE TABLE DimCustomer(
    CustomerKey int IDENTITY(1,1) PRIMARY KEY,
	CustomerID int,
	PersonID int,
	StoreID int,
    FirstName nvarchar(255),
	LastName nvarchar(255),
	MiddleName nvarchar(255),
	BirthDate date,
	Gender varchar(1),
	YearlyIncome nvarchar(255),
	ModifiedDate datetime,
	ValueUntil datetime
);

WITH XMLNAMESPACES (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey')
insert into DimCustomer (CustomerID, PersonID, StoreID, FirstName, LastName, MiddleName, BirthDate, Gender, YearlyIncome, ModifiedDate)
select distinct sc.CustomerID, sc.PersonID, sc.StoreID, pp.FirstName, pp.LastName, pp.MiddleName, pp.PersonType , 
pp.Demographics.value('(/IndividualSurvey/BirthDate)[1]', 'date'),
pp.Demographics.value('(/IndividualSurvey/Gender)[1]', 'varchar(1)'),
pp.Demographics.value('(/IndividualSurvey/YearlyIncome)[1]', 'nvarchar(255)'),
pp.ModifiedDate
from CompanyX.Sales.Customer sc
join CompanyX.Person.Person pp on sc.PersonID = pp.BusinessEntityID
join CompanyX.Sales.SalesOrderHeader soh on sc.CustomerID = soh.CustomerID
where sc.PersonID is not null;
----------------------------------------------------------------------------
Drop table DimProduct;

CREATE TABLE DimProduct(
    ProductKey int IDENTITY(1,1) PRIMARY KEY,
    ProductID int,
    ProductName nvarchar(255),
    ProductSubCategoryID int,
	ModifiedDate datetime,
	ValueUntil datetime
);

--DimProduct: Using STD Type 2
Insert into DimProduct (ProductID, ProductName, ProductSubCategoryID, ModifiedDate)
SELECT P.ProductID, P.Name as ProductName, P.ProductSubCategoryID, P.ModifiedDate
FROM CompanyX.Production.Product P 
LEFT JOIN CompanyX.Production.ProductSubcategory PS ON P.ProductSubcategoryID = PS.ProductSubcategoryID
LEFT JOIN CompanyX.Production.ProductCategory PC ON PC.ProductCategoryID = PS.ProductCategoryID;

select * from DimProduct;

----------------------------------------------------------------------------
Drop table DimSalesTerritory;

CREATE TABLE DimSalesTerritory(
    SalesTerritoryKey int IDENTITY(1,1) PRIMARY KEY,
    TerritoryID int,
    Region nvarchar(255),
    Country nvarchar(255),
	ModifiedDate datetime,
	ValueUntil datetime
);

--DimTerritory
Insert into DimSalesTerritory (TerritoryID, Region, Country, ModifiedDate)
SELECT S.TerritoryID as TerritoryID, S.Name as Region, R.Name as Country, S.ModifiedDate as ModifiedDate
FROM CompanyX.Sales.SalesTerritory S, CompanyX.Person.CountryRegion R	
WHERE S.CountryRegionCode = R.CountryRegionCode;

----------------------------------------------------------------------------
Drop Table FactSalesOrder;

CREATE TABLE FactSalesOrder (
    FactSalesKey int IDENTITY(1,1) PRIMARY KEY,
    CustomerKey int,
    DateKey int,
    ProductKey int,
    SalesTerritoryKey int,
	SalesOrderDetailID int,
    OrderNumber nvarchar(50),
    LineNumber int,
    OrderQuantity int,
	UnitPrice MONEY,
    LineTotal MONEY,
    OnlineOrderFlag bit
);

insert into FactSalesOrder (SalesOrderDetailID, CustomerKey, DateKey, ProductKey, SalesTerritoryKey, OrderNumber, LineNumber, OrderQuantity, UnitPrice, LineTotal, OnlineOrderFlag)
select distinct sod.SalesOrderDetailID, dc.CustomerKey, dd.DateKey, dp.ProductKey, dst.SalesTerritoryKey, soh.SalesOrderNumber,ROW_NUMBER() OVER (PARTITION BY sod.SalesOrderID ORDER BY sod.SalesOrderDetailID) AS LineNumber, sod.OrderQty, sod.UnitPrice, sod.LineTotal, soh.OnlineOrderFlag from CompanyX.Sales.SalesOrderDetail sod
left join CompanyX.Sales.SalesOrderHeader soh on soh.SalesOrderID = sod.SalesOrderID
left join DimCustomer dc on dc.CustomerID = soh.CustomerID
left join DimDate dd on dd.OrderDate = soh.OrderDate
left join DimProduct dp on dp.ProductID = sod.ProductID 
left join DimSalesTerritory dst on dst.TerritoryID = soh.TerritoryID
order by SalesOrderDetailID;

select count(*) from FactSalesOrder;

Drop Table FactSalesOrder2;

CREATE TABLE FactSalesOrder2 (
    FactSalesKey int IDENTITY(1,1) PRIMARY KEY,
    CustomerKey int,
    DateKey int,
    ProductKey int,
    SalesTerritoryKey int,
	SalesOrderDetailID int,
    OrderNumber nvarchar(50),
    LineNumber int,
    OrderQuantity int,
	UnitPrice MONEY,
    LineTotal MONEY,
    OnlineOrderFlag bit
);

insert into FactSalesOrder2 (CustomerKey, DateKey, ProductKey, SalesTerritoryKey, SalesOrderDetailID, OrderNumber, LineNumber, OrderQuantity, UnitPrice, LineTotal, OnlineOrderFlag)
select dc.CustomerKey, dd.DateKey, dp.ProductKey, dst.SalesTerritoryKey, sod.SalesOrderDetailID, soh.SalesOrderNumber, ROW_NUMBER() OVER (PARTITION BY sod.SalesOrderID ORDER BY sod.SalesOrderDetailID) AS LineNumber, sod.OrderQty, sod.UnitPrice, sod.LineTotal, soh.OnlineOrderFlag from CompanyX.Sales.SalesOrderDetail sod
join CompanyX.Sales.SalesOrderHeader soh on soh.SalesOrderID = sod.SalesOrderID
join DimCustomer dc on dc.CustomerID = soh.CustomerID
join DimDate dd on dd.OrderDate = soh.OrderDate
join DimProduct dp on dp.ProductID = sod.ProductID
join DimSalesTerritory dst on dst.TerritoryID = soh.TerritoryID;

select count(*) from FactSalesOrder2;


Select*from dbo.FactSalesOrder;

--SELECT FACT TABLE BARU
--SELECT D.DateKey,
--	Cs.CustomerKey as IDCustomer,
--	P.ProductKey as IDProduct,
--	T.SalesTerritoryKey as SalesTerritoryKey,
--	SD.OrderQty as SalesQty,
--	SD.UnitPrice as UnitPrice,
--	SH.OnlineOrderFlag
--FROM CompanyX.Sales.SalesOrderHeader SH 
--	LEFT JOIN CompanyX.Sales.SalesOrderDetail SD
--	ON SH.SalesOrderID = SD.SalesOrderID
--	LEFT JOIN Customer_CompanyX.dbo.DimCustomer Cs ON Cs.CustomerID = SH.CustomerID
--	LEFT JOIN Customer_CompanyX.dbo.DimProduct P ON P.ProductID = SD.ProductID
--	LEFT JOIN Customer_CompanyX.dbo.DimSalesTerritory T ON T.TerritoryID = SH.TerritoryID
--	LEFT JOIN Customer_CompanyX.dbo.DimDate D ON D.DateKey = CONVERT(INT,CONVERT(VARCHAR,SH.OrderDate,112))

--select * from dbo.FactSalesOrder;

----------------------------------------------------------------------------
--Create Clone table for DW
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
-- Clone table CompanyX.Person.Person
drop table dbo.Person;

CREATE TABLE [dbo].[Person](
	[BusinessEntityID] [int] NOT NULL,
	BirthDate date,
	Gender varchar(1),
	YearlyIncome nvarchar(255),
	TotalPurchaseYTD MONEY,
 CONSTRAINT [PK_Person_BusinessEntityID] PRIMARY KEY CLUSTERED 
(
	[BusinessEntityID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

-- Clone table Production.Product
CREATE TABLE [dbo].[Product](
	[ProductID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
	[ProductNumber] [nvarchar](25) NOT NULL,
	[MakeFlag] bit NOT NULL,
	[FinishedGoodsFlag] bit NOT NULL,
	[Color] [nvarchar](15) NULL,
	[SafetyStockLevel] [smallint] NOT NULL,
	[ReorderPoint] [smallint] NOT NULL,
	[StandardCost] [money] NOT NULL,
	[ListPrice] [money] NOT NULL,
	[Size] [nvarchar](5) NULL,
	[SizeUnitMeasureCode] [nchar](3) NULL,
	[WeightUnitMeasureCode] [nchar](3) NULL,
	[Weight] [decimal](8, 2) NULL,
	[DaysToManufacture] [int] NOT NULL,
	[ProductLine] [nchar](2) NULL,
	[Class] [nchar](2) NULL,
	[Style] [nchar](2) NULL,
	[ProductSubcategoryID] [int] NULL,
	[ProductModelID] [int] NULL,
	[SellStartDate] [datetime] NOT NULL,
	[SellEndDate] [datetime] NULL,
	[DiscontinuedDate] [datetime] NULL,
	[rowguid] [uniqueidentifier] ROWGUIDCOL  NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_Product_ProductID] PRIMARY KEY CLUSTERED 
(
	[ProductID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

-- clone table [Production].[ProductCategory]
CREATE TABLE [dbo].[ProductCategory](
	[ProductCategoryID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
	[rowguid] [uniqueidentifier] ROWGUIDCOL  NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_ProductCategory_ProductCategoryID] PRIMARY KEY CLUSTERED 
(
	[ProductCategoryID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

-- clone table [Production].[ProductSubcategory]
CREATE TABLE [dbo].[ProductSubcategory](
	[ProductSubcategoryID] [int] IDENTITY(1,1) NOT NULL,
	[ProductCategoryID] [int] NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
	[rowguid] [uniqueidentifier] ROWGUIDCOL  NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_ProductSubcategory_ProductSubcategoryID] PRIMARY KEY CLUSTERED 
(
	[ProductSubcategoryID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

-- clone table sales.customer
CREATE TABLE [dbo].[Customer](
	[CustomerID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[PersonID] [int] NULL,
	[StoreID] [int] NULL,
	[TerritoryID] [int] NULL,
	[AccountNumber]  [nvarchar](20),
	[rowguid] [uniqueidentifier] ROWGUIDCOL  NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_Customer_CustomerID] PRIMARY KEY CLUSTERED 
(
	[CustomerID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

--create table sales.[SalesOrderHeader]
Use Customer_CompanyX;
Drop table dbo.SalesOrderHeader;

CREATE TABLE [dbo].[SalesOrderHeader](
	[SalesOrderID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[RevisionNumber] [tinyint] NOT NULL,
	[OrderDate] [datetime] NOT NULL,
	[DueDate] [datetime] NOT NULL,
	[ShipDate] [datetime] NULL,
	[Status] [tinyint] NOT NULL,
	[OnlineOrderFlag] bit NOT NULL,
	[SalesOrderNumber] [nvarchar](50),
	[PurchaseOrderNumber] [nvarchar](25) NULL,
	[AccountNumber] [nvarchar](15) NULL,
	[CustomerID] [int] NOT NULL,
	[SalesPersonID] [int] NULL,
	[TerritoryID] [int] NULL,
	[BillToAddressID] [int] NOT NULL,
	[ShipToAddressID] [int] NOT NULL,
	[ShipMethodID] [int] NOT NULL,
	[CreditCardID] [int] NULL,
	[CreditCardApprovalCode] [varchar](15) NULL,
	[CurrencyRateID] [int] NULL,
	[SubTotal] [money] NOT NULL,
	[TaxAmt] [money] NOT NULL,
	[Freight] [money] NOT NULL,
	[TotalDue] float,
	[Comment] [nvarchar](128) NULL,
	[rowguid] [uniqueidentifier] ROWGUIDCOL  NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[DateID] varchar not null 
 CONSTRAINT [PK_SalesOrderHeader_SalesOrderID] PRIMARY KEY CLUSTERED 
(
	[SalesOrderID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

--create table sales.[SalesOrderDetail]
CREATE TABLE [dbo].[SalesOrderDetail](
	[SalesOrderID] [int] NOT NULL,
	[SalesOrderDetailID] [int] IDENTITY(1,1) NOT NULL,
	[CarrierTrackingNumber] [nvarchar](25) NULL,
	[OrderQty] [smallint] NULL,
	[ProductID] [int] NOT NULL,
	[SpecialOfferID] [int] NOT NULL,
	[UnitPrice] [money] NULL,
	[UnitPriceDiscount] [money] NOT NULL,
	[LineTotal] float,
	[rowguid] [uniqueidentifier] ROWGUIDCOL  NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_SalesOrderDetail_SalesOrderID_SalesOrderDetailID] PRIMARY KEY CLUSTERED 
(
	[SalesOrderID] ASC,
	[SalesOrderDetailID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
