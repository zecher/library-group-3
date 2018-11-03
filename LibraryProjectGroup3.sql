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

--Update asset
CREATE OR ALTER PROCEDURE UpdateAsset
	@assetKey int,
	@asset varchar(100) = NULL,
	@assetDescription varchar(max) = NULL,
	@assetTag uniqueidentifier = NULL,
	@assetTypeKey int = NULL,
	@replacementCost money = NULL,
	@restricted bit = NULL,
	@createdOn datetime = NULL,
	@deactivatedOn datetime = NULL
AS
BEGIN
	IF (@asset IS NOT NULL)
		BEGIN
			UPDATE LibraryProject.Assets
			SET
				Asset = @asset
			WHERE
				LibraryProject.Assets.AssetKey = @assetKey
		END
	IF (@assetDescription IS NOT NULL)
		BEGIN
			UPDATE LibraryProject.Assets
			SET
				AssetDescription = @assetDescription
			WHERE
				LibraryProject.Assets.AssetKey = @assetKey
		END
	IF (@assetTag IS NOT NULL)
		BEGIN
			UPDATE LibraryProject.Assets
			SET
				AssetTag = @assetTag
			WHERE
				LibraryProject.Assets.AssetKey = @assetKey
		END
	IF (@assetTypeKey IS NOT NULL)
		BEGIN
			UPDATE LibraryProject.Assets
			SET
				AssetTypeKey = @assetTypeKey
			WHERE
				LibraryProject.Assets.AssetKey = @assetKey
		END
	IF (@replacementCost IS NOT NULL)
		BEGIN
			UPDATE LibraryProject.Assets
			SET
				ReplacementCost = @replacementCost
			WHERE
				LibraryProject.Assets.AssetKey = @assetKey
		END
	IF (@restricted IS NOT NULL)
		BEGIN
			UPDATE LibraryProject.Assets
			SET
				Restricted = @restricted
			WHERE
				LibraryProject.Assets.AssetKey = @assetKey
		END
	IF (@createdOn IS NOT NULL)
		BEGIN
			UPDATE LibraryProject.Assets
			SET
				CreatedOn = @createdOn
			WHERE
				LibraryProject.Assets.AssetKey = @assetKey
		END
	IF (@deactivatedOn IS NOT NULL)
		BEGIN
			UPDATE LibraryProject.Assets
			SET
				DeactivatedOn = @deactivatedOn
			WHERE
				LibraryProject.Assets.AssetKey = @assetKey
		END
END;

--Deactivate asset
CREATE OR ALTER PROCEDURE DeactivateAsset
	@assetKey int,
	@deactivatedOn datetime
AS
BEGIN
	UPDATE LibraryProject.Assets
	SET
		DeactivatedOn = @deactivatedOn
	WHERE
		LibraryProject.Assets.AssetKey = @assetKey
		
END;
------------------END STORED PROCEDURES------------------


---------------------BEGIN TRIGGERS----------------------

----------------------END TRIGGERS-----------------------