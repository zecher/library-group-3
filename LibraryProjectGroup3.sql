/*
Group Assignment 3
Group 3 - Quin Dixon, Samuel Gamez, Andrew Merrell
CS 3550
11/1/18
*/

-----------------BEGIN STORED PROCEDURES-----------------
--Create new asset types
CREATE OR ALTER PROCEDURE NewAssetType
	@assetType varchar(50)
AS
BEGIN
	INSERT INTO LibraryProject.AssetTypes
	(
		AssetType
	)
	VALUES
		(@assetType);
END;

--Create assets
CREATE OR ALTER PROCEDURE CreateAsset
	@asset varchar(100),
	@assetDescription varchar(max),
	@assetTypeKey int,
	@replacementCost money,
	@restricted bit
AS
BEGIN
	INSERT INTO LibraryProject.Assets
	(
		Asset,
		AssetDescription,
		AssetTypeKey,
		ReplacementCost,
		Restricted
	)
	VALUES
		(@asset, @assetDescription, @assetTypeKey, @replacementCost, @restricted);
END;

--Deactivate asset
CREATE OR ALTER PRCOEDURE DeactivateAsset
	@deactivatedOn datetime
AS
BEGIN
	INSERT INTO LibraryProject.Assets
	(
		DeactivatedOn
	)
	VALUES
		(@deactivatedOn);
END;
------------------END STORED PROCEDURES------------------