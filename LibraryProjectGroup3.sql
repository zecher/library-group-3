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
		(AssetType)
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
		(Asset, AssetDescription, AssetTypeKey, ReplacementCost, Restricted)
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
--Create a trigger that verifies that the limit rules on the number of checkouts is adhered to
CREATE OR ALTER TRIGGER LibraryProject.CheckoutNumberLimit
ON LibraryProject.AssetLoans
INSTEAD OF INSERT
AS
BEGIN
	DECLARE @AssetKey int;
	DECLARE @UserKey int;
	DECLARE @LoanedOn date;
	DECLARE @ReturnedOn date;
	DECLARE @LostOn date;
	DECLARE @CardType varchar(50);

	SELECT @AssetKey = I.AssetKey FROM inserted I;
	SELECT @UserKey = I.UserKey FROM inserted I;
	SELECT @LoanedOn = I.LoanedOn FROM inserted I;
	SELECT @ReturnedOn = I.ReturnedOn FROM inserted I;
	SELECT @LostOn = I.LostOn FROM inserted I;

	SELECT 
		@CardType = CT.CardType
	FROM
		LibraryProject.Cards AS C
		LEFT JOIN LibraryProject.CardTypes AS CT ON CT.CardTypeKey = C.CardTypeKey
	WHERE
		C.UserKey = @UserKey

	IF @CardType = 'Adult'
	BEGIN
		IF
		(
			SELECT
				sub.CheckoutCount
			FROM
			(
				SELECT
					AL.UserKey,
					COUNT(AL.AssetLoanKey) AS CheckoutCount
				FROM 
					LibraryProject.AssetLoans AS AL
				GROUP BY
					AL.UserKey
			) AS [sub]
			WHERE
				sub.UserKey = @UserKey
		) < 6 --Checkout limit for Adult CardTypes
		BEGIN
			INSERT INTO LibraryProject.AssetLoans
				(AssetKey, UserKey, LoanedOn, ReturnedOn, LostOn)
			VALUES
				(@AssetKey, @UserKey, @LoanedOn, @ReturnedOn, @LostOn)
		END
		ELSE
		BEGIN
			RAISERROR ('ERROR: Adult card has already reached checkout limit of 6.', 8, 1)
		END
	END

	IF @CardType = 'Teen'
	BEGIN
		IF
		(
			SELECT
				sub.CheckoutCount
			FROM
			(
				SELECT
					AL.UserKey,
					COUNT(AL.AssetLoanKey) AS CheckoutCount
				FROM 
					LibraryProject.AssetLoans AS AL
				GROUP BY
					AL.UserKey
			) AS [sub]
			WHERE
				sub.UserKey = @UserKey
		) < 4 --Checkout limit for Teen CardTypes
		BEGIN
			INSERT INTO LibraryProject.AssetLoans
				(AssetKey, UserKey, LoanedOn, ReturnedOn, LostOn)
			VALUES
				(@AssetKey, @UserKey, @LoanedOn, @ReturnedOn, @LostOn)
		END
		ELSE
		BEGIN
			RAISERROR ('ERROR: Teen card has already reached checkout limit of 4.', 8, 1)
		END
	END

	IF @CardType = 'Child'
	BEGIN
		IF
		(
			SELECT
				sub.CheckoutCount
			FROM
			(
				SELECT
					AL.UserKey,
					COUNT(AL.AssetLoanKey) AS CheckoutCount
				FROM 
					LibraryProject.AssetLoans AS AL
				GROUP BY
					AL.UserKey
			) AS [sub]
			WHERE
				sub.UserKey = @UserKey
		) < 2 --Checkout limit for Child CardTypes
		BEGIN
			INSERT INTO LibraryProject.AssetLoans
				(AssetKey, UserKey, LoanedOn, ReturnedOn, LostOn)
			VALUES
				(@AssetKey, @UserKey, @LoanedOn, @ReturnedOn, @LostOn)
		END
		ELSE
		BEGIN
			RAISERROR ('ERROR: Child card has already reached checkout limit of 2.', 8, 1)
		END
	END
END

----------------------END TRIGGERS-----------------------