/*
Group Assignment 3
Group 3 - Quin Dixon, Samuel Gamez, Andrew Merrell
CS 3550
11/1/18
*/

--You need to create stored procedures to complete the following items:
--Create new asset types
CREATE OR ALTER PROCEDURE NewAssetType
	@newType varchar(50)
AS
BEGIN
	INSERT INTO LibraryProject.AssetTypes
	(
		AssetType
	)
	VALUES
		(@newType);
END;

--Create, update, or deactivate assets
