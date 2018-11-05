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
	@assetTypeKey int = NULL,
	@replacementCost money = NULL,
	@restricted bit = NULL,
	@createdOn datetime = NULL,
	@deactivatedOn datetime = NULL,
	@newAssetTag uniqueidentifier = NULL,
	@assetTag uniqueidentifier = NULL
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
	IF (@assetTag IS NOT NULL)
		BEGIN
			UPDATE LibraryProject.Assets
			SET
				AssetTag = @assetTag
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


--Pay fees (one at a time)
CREATE OR ALTER PROCEDURE PayFee
	@feeKey int
AS
BEGIN
	UPDATE LibraryProject.Fees
	SET
		Paid = 1
	WHERE
		FeeKey = @feeKey
END;

------------------END STORED PROCEDURES------------------


---------------------BEGIN TRIGGERS----------------------

--Verify that the limit rules on the number of checkouts is adhered to
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
	SELECT @UserKey	= I.UserKey FROM inserted I;
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
				COUNT(AL.AssetLoanKey) AS CheckoutCount
			FROM 
				LibraryProject.AssetLoans AS AL
			WHERE
				AL.UserKey = @UserKey
		) < 6 --Checkout limit for Adult CardTypes 
		BEGIN
			INSERT INTO LibraryProject.AssetLoans
				(AssetKey, UserKey, LoanedOn, ReturnedOn, LostOn)
			VALUES
				(@AssetKey, @UserKey, @LoanedOn, @ReturnedOn, @LostOn)
		END
		ELSE
		BEGIN
			RAISERROR ('ERROR: Adult card has already reached checkout limit of 6', 8, 1)
		END
	END

	IF @CardType = 'Teen'
	BEGIN
		IF
		(
			SELECT
				COUNT(AL.AssetLoanKey) AS CheckoutCount
			FROM 
				LibraryProject.AssetLoans AS AL
			WHERE
				AL.UserKey = @UserKey
		) < 4 --Checkout limit for Teen CardTypes
		BEGIN
			INSERT INTO LibraryProject.AssetLoans
				(AssetKey, UserKey, LoanedOn, ReturnedOn, LostOn)
			VALUES
				(@AssetKey, @UserKey, @LoanedOn, @ReturnedOn, @LostOn)
		END
		ELSE
		BEGIN
			RAISERROR ('ERROR: Teen card has already reached checkout limit of 4', 8, 1)
		END
	END

	IF @CardType = 'Child'
	BEGIN
		IF
		(
			SELECT
				COUNT(AL.AssetLoanKey) AS CheckoutCount
			FROM 
				LibraryProject.AssetLoans AS AL
			WHERE
				AL.UserKey = @UserKey
		) < 2 --Checkout limit for Child CardTypes
		BEGIN
			INSERT INTO LibraryProject.AssetLoans
				(AssetKey, UserKey, LoanedOn, ReturnedOn, LostOn)
			VALUES
				(@AssetKey, @UserKey, @LoanedOn, @ReturnedOn, @LostOn)
		END
		ELSE
		BEGIN
			RAISERROR ('ERROR: Child card has already reached checkout limit of 2', 8, 1)
		END
	END
END

----------------------END TRIGGERS-----------------------


--------------------BEGIN FUNCTIONS----------------------

--Create a function that provides an all-in cost for replacing an asset
CREATE OR ALTER FUNCTION LostAssetFee(@AssetKey int)
RETURNS money
AS
BEGIN
	DECLARE @AssetType varchar(50);
	DECLARE @FeeAmount money;

	SELECT
		@AssetType = AT.AssetType
	FROM
		LibraryProject.Assets A
		LEFT JOIN LibraryProject.AssetTypes AT ON AT.AssetTypeKey = A.AssetTypeKey
	WHERE
		A.AssetKey = @AssetKey;

	SELECT
		@FeeAmount = A.ReplacementCost
	FROM
		LibraryProject.Assets A
	WHERE
		A.AssetKey = @AssetKey;

	IF (@AssetType = 'Book')
	BEGIN
		SET @FeeAmount += 1.99 --Extra preparation cost for Book AssetTypes
	END

	IF (@AssetType = 'Movie')
	BEGIN
		SET @FeeAmount += .99 --Extra preparation cost for Movie AssetTypes
	END

	RETURN @FeeAmount;
END;

CREATE or ALTER FUNCTION LibraryProject.GetFine 
(
	@CheckOut DATE,
	@CheckIn DATE
) RETURNS DECIMAL
AS
BEGIN
	DECLARE @DueDate DATE = DATEADD(dy,21,@CheckOut)
	DECLARE @DaysLate DECIMAL = DATEDIFF(dy,@DueDate,@CheckIn)
	DECLARE @Fee DECIMAL;
	SET @Fee =
		CASE 
			WHEN @DaysLate < 4 THEN 0.00
			WHEN @DaysLate < 8 THEN 1.00
			WHEN @DaysLate < 15 THEN 2.00
			ELSE 3.00
		END

	RETURN @Fee
END

---------------------END FUNCTIONS-----------------------


/*************************************************************
		Andrew's section...
*/

-- instead of procedure, this could have been a function, but, oh well

CREATE or ALTER PROCEDURE GetFine -- prepend LibraryProject.?
	@CheckOut date,
	@CheckIn date,
	@Fee decimal OUTPUT
AS
	declare @DueDate date = dateAdd(dy,21,@CheckOut)
	declare @DaysLate decimal = datediff(dy,@DueDate,@CheckIn)
	set @Fee =
		case 
			when @DaysLate < 4 then 0.00
			when @DaysLate < 8 then 1.00
			when @DaysLate < 15 then 2.00
			else 3.00
		end

RETURN @Fee

-- Test some scenarios
DECLARE @myFee decimal
EXEC GetFine @CheckOut = '2018-06-24', @CheckIn = '2018-07-14', @fee = @myFee OUTPUT
SELECT @myFee
EXEC GetFine @CheckOut = '2018-06-24', @CheckIn = '2018-07-20', @fee = @myFee OUTPUT
SELECT @myFee
EXEC GetFine @CheckOut = '2018-06-24', @CheckIn = '2018-07-24', @fee = @myFee OUTPUT
SELECT @myFee
EXEC GetFine @CheckOut = '2018-06-24', @CheckIn = '2018-08-24', @fee = @myFee OUTPUT
SELECT @myFee
-- end test

-- Uh, just in case we need to do that, assumes we have already told them what they owe
create or ALTER PROCEDURE PayAllFeesForUser
	@UserKey int
as
	update LibraryProject.Fees 
	set Paid = 1 
	where UserKey = @UserKey 
		and Paid = 0

/* TODO: check out a book return it x days late and therefore charge a fee */


-- INSERT LibraryProject.Fees (Amount, UserKey) VALUES (3.00, 5) --example 

/* Mark a book as lost, apply replacement fee to user */
CREATE or ALTER PROCEDURE ReportAssetLost
	-- or do we use the unique identifier?
	@AssetKey int
	 --with that we can find the most recent person where checkedin is null
as
-- wait, don't we wanna check to make sure there is an outstanding check out with no check in??

	update LibraryProject.Assets
	set DeactivatedOn = getDate()
	where AssetKey = @AssetKey
	-- that's the easy part, 
	-- now we need to create a fee entry for the responsible party, 

	insert into LibraryProject.Fees (UserKey, Amount) 
	-- there should be a CONSTRAINT in the fees to max out at 29.99 

	-- but think about the children!
	SELECT CASE
			   WHEN U.ResponsibleUserKey IS NULL
			   THEN U.UserKey
			   ELSE U.ResponsibleUserKey
		   END, 
		   u.ResponsibleUserKey,
		   UserFee.ReplacementCost
	FROM LibraryProject.Users AS U
		 INNER JOIN
	(
		SELECT l.UserKey, 
			   a.ReplacementCost
		FROM LibraryProject.AssetLoans l
			 INNER JOIN LibraryProject.Assets a ON a.AssetKey = l.AssetKey
		WHERE --l.AssetKey = @AssetKey
			  --AND -- more than one most likely
			  l.ReturnedOn IS NULL		-- should really only be one
	) AS UserFee ON U.UserKey = UserFee.UserKey;

/*
 TODO: have a child try to check out 3 books
 Should get an error on the 3rd
 Try to have someone check out a book that isn't returned
 
*/
*/


-------------------- BEGIN CONSTRAINTS ----------------------

ALTER TABLE LibraryProject.Assets
ADD CONSTRAINT AssetReplacementCostLimit
	CHECK (ReplacementCost <= 29.99)
;

-------------------- END CONSTRAINTS ----------------------

-------------------- BEGIN VIEWS ----------------------

CREATE OR ALTER VIEW LibraryProject.AssetFeeView
AS
	SELECT
		AssetFee.*
	FROM
		(SELECT
			A.Asset,
			CASE 
				WHEN AL.ReturnedOn IS NOT NULL THEN LibraryProject.GetFine(AL.LoanedOn, AL.ReturnedOn)
				WHEN AL.LostOn IS NOT NULL THEN LibraryProject.GetFine(AL.LoanedOn, AL.ReturnedOn)
				ELSE LibraryProject.GetFine(AL.LoanedOn, GETDATE())
			END AS Fee
		FROM
			LibraryProject.Assets A
			INNER JOIN LibraryProject.AssetLoans AL
				ON A.AssetKey = AL.AssetKey) AS AssetFee
WHERE
	AssetFee.Fee > 0
;
		

-------------------- END VIEWS ----------------------
