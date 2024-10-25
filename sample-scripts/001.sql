-- New database
CREATE DATABASE AcmeDB;
GO
 
USE AcmeDB
GO
 
CREATE TABLE UserAddress (
	AddresID INT PRIMARY KEY IDENTITY(1, 1)
	,FirstName VARCHAR(100)
	,Lastname VARCHAR(150)
	,Address VARCHAR(250)
	)
GO
 
-- New procedure
CREATE PROCEDURE sp_GetUserAddress
AS
BEGIN
	SELECT FirstName
		,Lastname
		,Address
	FROM UserAddress
END
GO
 
CREATE TABLE Address (
	ID INT NOT NULL IDENTITY(1, 1)
	,City VARCHAR(120)
	,PostalCode INT
	,UserAddressID INT FOREIGN KEY REFERENCES UserAddress(AddresID)
	)
GO
-- New View
CREATE VIEW v_Address
AS
SELECT ID
	,City
	,PostalCode
	,UserAddressID
FROM dbo.Address
GO
 
CREATE PROCEDURE sp_GetUserCity
AS
BEGIN
	SELECT UserAddress.FirstName
		,UserAddress.Lastname
		,Address.City
	FROM UserAddress
	INNER JOIN Address ON UserAddress.AddresID = Address.UserAddressID
END
GO
-- New Trigger
CREATE TRIGGER trgAfterInsert ON [dbo].[UserAddress]
FOR INSERT
AS
PRINT 'Data entered successfully'
GO