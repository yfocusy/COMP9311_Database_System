-- COMP9311 16s2 Assignment 1
-- Schema for KensingtonCars
--
-- Written by Li Yu
-- Student ID: z3492782
--

-- Some useful domains; you can define more if needed.
create domain URLType as varchar(100) check (value like 'http://%');

create domain EmailType as varchar(100) check (value like '%@%.%');

create domain PhoneType as char(10) check (value ~ '[0-9]{10}');




-- 1 EMPLOYEE
-- done
create table Employees (
	EID         serial,
	TFN         char(9) not null unique check (TFN ~'[0-9]{9}'),        
	firstname   varchar(50) not null,
	lastname    varchar(50) not null,
	Salary      integer not null check (Salary > 0),
    primary key (EID)
);

create table Admin (   
    EID         integer references Employees(EID),
    primary key (EID)   
);

create table Mechanic (
    EID         integer references Employees(EID),
    license     char(8) not null unique check (license ~ '[0-9A-Za-z]{8}'),
    primary key (EID)  
);

create table Salesman (
    EID         integer references Employees(EID),
    commRate    integer not null check (commRate>=5 and commRate<=20),
    primary key (EID)

);

-- 2 CLIENT done--
create table Client (
	CID         serial,
	name        varchar(100) not null ,
	address     varchar(200) not null ,
	phone       PhoneType not null,
	email       EmailType,
	primary key (CID)
);

create table Company (
	CID         integer references Client(CID),
    ABN         char(11) not null unique check (ABN ~'[0-9]{11}'),
    url         URLType,
	primary key (CID)
);

--3 CAR ----
create domain CarLicenseType as varchar(6) check (value ~ '[0-9A-Za-z]{1,6}');

create domain OptionType as varchar(12)
	check (value in ('sunroof','moonroof','GPS','alloy wheels','leather'));
create domain VINType as char(17) check (value ~ '[0-9A-HJ-NPR-Z]{17}');

create domain YearType as integer check (value>=1970 and value<=2099);
-- 3
create table Car (
	VIN          VINType,
	manufacturer varchar(40) not null,
	model        varchar(40) not null,
	year         YearType not null,
    primary key (VIN)
);

create table options (
    VIN          VINType references Car(VIN),
    options      OptionType,  
    primary key (VIN)
);
 
create table NewCar (
 	VIN          VINType references Car(VIN),
    cost         numeric(8,2) not null check (cost>0),
    charges      numeric(8,2) not null check (charges>0),
    primary key (VIN)
);

create table UsedCar (
    VIN          VINType references Car(VIN),
    plateNumber  CarLicenseType not null,
--  plateNumber  CarLicenseType not null unique, 
    primary key (VIN)
);

-- 4 --done-parts get rid of not null--
create table RepairJob(
	CID         integer unique not null references Client(CID),
	VIN         VINType references UsedCar(VIN),
	description varchar(250),
    "number"    integer not null check ("number">=1 and "number"<=999),
	parts       numeric(8,2) check (parts>0),
	work        numeric(8,2) not null check (parts>0),
	"date"      date not null,
	primary key (VIN,"number")
);
-- 5 ------
create table Does(
	EID         integer references Mechanic(EID),
	"number"    integer not null check ("number">=1 and "number"<=999),
	VIN         VINType,
--	CID         integer not null references Client(CID),
	foreign key ("number",VIN) references RepairJob("number",VIN),
	primary key (EID,"number",VIN)
);
-- 6 ------
create table Buys(
	EID         integer references Salesman(EID),
	CID         integer references Client(CID),
	VIN         VINType references UsedCar(VIN),	
	price       numeric(8,2) not null check (price>0),
	"date"      date not null,
	commission  numeric(8,2) not null check (commission>0),
    primary key (EID,CID,VIN,"date")
);

create table Sells(
	EID         integer references Salesman(EID),
	CID         integer references Client(CID),
	VIN         VINType references UsedCar(VIN),	
	price       numeric(8,2) not null check (price>0),
	"date"      date not null,
	commission  numeric(8,2) not null check (commission>0),
	primary key (EID,CID,VIN,"date")

);

create table SellsNew(
	EID         integer references Salesman(EID),
	CID         integer references Client(CID),
	VIN         VINType references NewCar(VIN),	
	price       numeric(8,2) not null check (price>0),
	"date"      date,
	plateNumber CarLicenseType not null,
	commission  numeric(8,2) not null check (commission>0),
--	primary key (EID,CID,VIN,plateNumber,"date")
    primary key (EID,CID,VIN)
);





----------------------------------
--create table OwnBy(
	---不写?----

--	primary key ()
   
--);


   



