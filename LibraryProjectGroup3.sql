/*
Group Assignment 3
Group 3 - Quin Dixon, Samuel Gamez, Andrew Merrell
CS 3550
11/1/18
*/

-----------------BEGIN STORED PROCEDURES-----------------


-- Create new users
CREATE OR ALTER PROCEDURE LibraryProject.CreateUser
	@FirstName VARCHAR(40),
	@LastName VARCHAR(40),
	@Email VARCHAR(50),
	@Address1 VARCHAR(50),
	@Address2 VARCHAR(30),
	@City VARCHAR(30),
	@StateAbbv CHAR(2),
	@Birthdate DATE
AS
BEGIN
	INSERT INTO LibraryProject.Users
		(FirstName, LastName, Email, Address1, Address2, City, StateAbbreviation, Birthdate, CreatedOn)
	VALUES
		(@FirstName, @LastName, @Email, @Address1, @Address2, @City, @StateAbbv, @Birthdate, GETDATE());
END;

--Create new asset types
CREATE OR ALTER PROCEDURE LibraryProject.NewAssetType
	@assetType varchar(50)
AS
BEGIN
	INSERT INTO LibraryProject.AssetTypes
		(AssetType)
	VALUES
		(@assetType);
END;

--Create assets
CREATE OR ALTER PROCEDURE LibraryProject.CreateAsset
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

-- Update user
CREATE OR ALTER PROCEDURE LibraryProject.UpdateUser
	@UserKey INT,
	@FirstName VARCHAR(40) = NULL,
	@LastName VARCHAR(40) = NULL,
	@Email VARCHAR(50) = NULL,
	@Address1 VARCHAR(50) = NULL,
	@Address2 VARCHAR(30) = NULL,
	@City VARCHAR(30) = NULL,
	@StateAbbv CHAR(2) = NULL,
	@Birthdate DATE = NULL
AS
BEGIN
	IF (@FirstName IS NOT NULL)
		BEGIN
			UPDATE LibraryProject.Users
			SET
				FirstName = @FirstName
			WHERE
				LibraryProject.Users.UserKey = @UserKey
		END
	IF (@LastName IS NOT NULL)
		BEGIN
			UPDATE LibraryProject.Users
			SET
				LastName = @LastName
			WHERE
				LibraryProject.Users.UserKey = @UserKey
		END
	IF (@Email IS NOT NULL)
		BEGIN
			UPDATE LibraryProject.Users
			SET
				Email = @Email
			WHERE
				LibraryProject.Users.UserKey = @UserKey
		END
	IF (@Address1 IS NOT NULL)
		BEGIN
			UPDATE LibraryProject.Users
			SET
				Address1 = @Address1
			WHERE
				LibraryProject.Users.UserKey = @UserKey
		END
	IF (@Address2 IS NOT NULL)
		BEGIN
			UPDATE LibraryProject.Users
			SET
				Address2 = @Address2
			WHERE
				LibraryProject.Users.UserKey = @UserKey
		END
	IF (@City IS NOT NULL)
		BEGIN
			UPDATE LibraryProject.Users
			SET
				City = @City
			WHERE
				LibraryProject.Users.UserKey = @UserKey
		END
	IF (@StateAbbv IS NOT NULL)
		BEGIN
			UPDATE LibraryProject.Users
			SET
				StateAbbreviation = @StateAbbv
			WHERE
				LibraryProject.Users.UserKey = @UserKey
		END
	IF (@Birthdate IS NOT NULL)
		BEGIN
			UPDATE LibraryProject.Users
			SET
				Birthdate = @Birthdate
			WHERE
				LibraryProject.Users.UserKey = @UserKey
		END
END;

--Update asset
CREATE OR ALTER PROCEDURE LibraryProject.UpdateAsset
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

---- is this called from another function that asseses the lost item fee?

CREATE OR ALTER PROCEDURE LibraryProject.DeactivateAsset
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
CREATE OR ALTER PROCEDURE LibraryProject.PayFee
	@feeKey int
AS
BEGIN
	UPDATE LibraryProject.Fees
	SET
		Paid = 1
	WHERE
		FeeKey = @feeKey
END;

--Check out an asset
CREATE OR ALTER PROCEDURE LibraryProject.LoanAsset
	@UserKey INT,
	@AssetKey INT,
	@LoanDate DATE
AS
BEGIN
	IF 
	(SELECT 
		SUM(Amount)
	FROM LibraryProject.Fees
	WHERE UserKey = @UserKey
		  AND Paid = 0
	GROUP BY Amount) > 0
	Begin
		RAISERROR ('ERROR: User must pay fees first', 8, 1)
		return 
	End

	DECLARE @ExistingKey INT;
	DECLARE @ReturnedOn DATE;
	DECLARE @LostOn DATE;

	SELECT TOP 1
		@ExistingKey = AL.AssetLoanKey,
		@ReturnedOn = AL.ReturnedOn,
		@LostOn = AL.LostOn
	FROM
		LibraryProject.AssetLoans AS AL
	WHERE
		AL.AssetKey = @AssetKey
	ORDER BY
		AL.LoanedOn DESC
	-- This checks for assets that have never been checked out so they won't have any AssetLoans records.
	IF (@ExistingKey IS NOT NULL)
	BEGIN
		IF (@LostOn IS NOT NULL)
		BEGIN
			RAISERROR ('ERROR: That asset is marked as lost', 8, 1)
			RETURN
		END

		IF (@ReturnedOn IS NOT NULL)
		BEGIN
			INSERT INTO LibraryProject.AssetLoans
				(UserKey, AssetKey, LoanedOn)
			VALUES
				(@UserKey, @AssetKey, @LoanDate)
		END
		ELSE
		BEGIN
			RAISERROR ('ERROR: That asset is currently checked out', 8, 1)
			RETURN
		END
	END
	-- If no record was found, we can simply go through with the insert because this asset has never been checked out.
	ELSE
	BEGIN
		INSERT INTO LibraryProject.AssetLoans
			(UserKey, AssetKey, LoanedOn)
		VALUES
			(@UserKey, @AssetKey, @LoanDate)
	END
END;
-----------------
-- As we return an asset, if it's overdue, should we insert a fine into the fines table?
CREATE OR ALTER PROCEDURE LibraryProject.ReturnAsset
	@AssetLoanKey INT,
	@ReturnDate DATE
AS
BEGIN
	DECLARE @Fine INT
	DECLARE @UserKey INT;

	-- Set return date on loan record.
	UPDATE LibraryProject.AssetLoans
	SET
		ReturnedOn = @ReturnDate
	WHERE
		AssetLoanKey = @AssetLoanKey

	-- Get the user key and associated fine.
	SELECT
		@UserKey = CASE 
						WHEN U.ResponsibleUserKey IS NULL
						THEN U.UserKey
						ELSE U.ResponsibleUserKey
					END,
		@Fine = LibraryProject.GetFine(AL.LoanedOn, AL.ReturnedOn) 
	FROM
		LibraryProject.AssetLoans AL
		INNER JOIN LibraryProject.Users U
			ON AL.UserKey = U.UserKey
	;

	-- If the book was turned in late, insert fee record.
	IF (@FINE > 0)
	BEGIN
		INSERT INTO LibraryProject.Fees
			(Amount, UserKey, Paid)
		VALUES
			(@Fine, @UserKey, 0)
		;
	END
END;
----------------
-- Lost book to fees table?

CREATE OR ALTER PROCEDURE LibraryProject.ReportAssetLost
	@AssetLoanKey INT,
	@ReportDate DATE
AS
BEGIN
	UPDATE LibraryProject.AssetLoans
	SET
		LostOn = @ReportDate
	WHERE
		AssetLoanKey = @AssetLoanKey
END;

-------- Needed to move the function here because I'm about to use it below

CREATE OR ALTER FUNCTION LibraryProject.GetCardType (@Birthdate DATE)
RETURNS int
AS
BEGIN
	DECLARE @Age int = DATEDIFF(yyyy,@Birthdate,GetDate());
	DECLARE @CardTypeKey int;

	IF (@Age <= 12)
	BEGIN
		SET @CardTypeKey = 3; -- Child
	END
	IF (@Age >= 13 AND @Age <= 17)
	BEGIN
		SET @CardTypeKey = 2; -- Teen
	END
	IF (@Age >= 18)
	BEGIN
		SET @CardTypeKey = 1; -- Adult
	END

	RETURN @CardTypeKey;
END;
--------
CREATE OR ALTER PROCEDURE LibraryProject.DeactivateCards
@UserKey INT
as
BEGIN
UPDATE LibraryProject.Cards
   SET 
      DeactivatedOn = GETDATE()
   WHERE
     UserKey = @UserKey
   AND DeactivatedOn IS NULL;
END
-------- 
CREATE OR ALTER PROCEDURE LibraryProject.IssueCard
	@UserKey INT,
	@CardNumber char(14)
AS
BEGIN
	--First of all, do you have any fines?
	if 
	(
		SELECT SUM(Amount)
		FROM LibraryProject.Fees
		WHERE UserKey = @UserKey
			  AND
			   Paid = 0
	) > 0
	BEGIN 
		PRINT('There are outstanding fines.  Card can not be issued.')
	END
	ELSE
	BEGIN
		declare @UserBirthdate date =
			(select Birthdate
			from LibraryProject.Users
			where UserKey = @UserKey)
			-- Yes, this will deactivate all active cards for the user... 
			-- Shouldn't be more than one though
		declare @CardTypeKey int = (LibraryProject.GetCardType(@UserBirthdate) )
		--declare @CardNumber char(14) -- this might need to just be passed in??
	
		IF
		(
			SELECT COUNT(CardKey)
			FROM LibraryProject.Cards
			WHERE UserKey = @UserKey 
			AND
			DeactivatedOn IS NULL
		) > 0 -- any previously owned cards that aren't deactivated?
			exec LibraryProject.DeactivateCards @UserKey
		insert into LibraryProject.Cards 
			(CardNumber
			,UserKey
			,CardTypeKey
			,CreatedOn)
		Values   
			(@CardNumber
			,@UserKey
			,@CardTypeKey
			,getDate())
	END
END --issueCard
--
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
	DECLARE @Restricted bit;

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

	
	SELECT
		@Restricted = A.Restricted
	FROM
		LibraryProject.Assets A
	WHERE
		A.AssetKey = @AssetKey

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
				AND AL.ReturnedOn IS NULL
				AND AL.LostOn IS NULL
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
			RETURN
		END
	END
	-- If the cardholder is not an adult cardholder check if their asset is restricted.
	ELSE
	BEGIN
		IF
		(
			@Restricted = 1
		)
		BEGIN
			RAISERROR ('ERROR: Only Adult cardholders can check out restricted assets.', 8, 1)
			RETURN
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
				AND AL.ReturnedOn IS NULL
				AND AL.LostOn IS NULL
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
			RETURN
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
				AND AL.ReturnedOn IS NULL
				AND AL.LostOn IS NULL
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
			RETURN
		END
	END
END -- checkoutLimit

----------------------END TRIGGERS-----------------------


--------------------BEGIN FUNCTIONS----------------------

--Create a function that provides an all-in cost for replacing an asset
CREATE OR ALTER FUNCTION LibraryProject.LostAssetFee(@AssetKey int)
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

	IF (@AssetType = 'Audio')
	BEGIN
		SET @FeeAmount += 1.49 --Extra preparation cost for Audio AssetTypes
	END

	RETURN @FeeAmount;
END;


CREATE or ALTER FUNCTION LibraryProject.GetFine 
(
	@CheckOut DATE,
	@CheckIn DATE
) RETURNS MONEY
AS
BEGIN
	DECLARE @DueDate DATE = DATEADD(dy,21,@CheckOut)
	DECLARE @DaysLate DECIMAL = DATEDIFF(dy,@DueDate,@CheckIn)
	DECLARE @Fee MONEY;
	SET @Fee =
		CASE 
			WHEN @DaysLate < 4  THEN 0.00
			WHEN @DaysLate < 8  THEN 1.00
			WHEN @DaysLate < 15 THEN 2.00
			ELSE 3.00
		END

	RETURN @Fee;
END;



/*--- test code
select 
	LibraryProject.GetCardType('06/24/2010') as Child,
	LibraryProject.GetCardType('06/24/2001') as Teen, 
	LibraryProject.GetCardType('06/24/2000') as Adult
*/

---------------------END FUNCTIONS-----------------------


/*************************************************************
	
-- instead of procedure, this could have been a function, but, oh well
-- Update: See above function

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
*/

-- Uh, just in case we need to do that, assumes we have already told them what they owe
create or ALTER PROCEDURE LibraryProject.PayAllFeesForUser
	@UserKey int
as
	BEGIN
		update LibraryProject.Fees 
		set Paid = 1 
		where UserKey = @UserKey 
			and Paid = 0
	END
/* TODO: check out a book return it x days late and therefore charge a fee */

-- INSERT LibraryProject.Fees (Amount, UserKey) VALUES (3.00, 5) --example 

/* Mark a book as lost, apply replacement fee to user */
CREATE or ALTER PROCEDURE LibraryProject.ReportAssetLost
	-- or do we use the unique identifier?
	@AssetKey int
	 --with that we can find the most recent person where checkedin is null
as
-- wait, don't we wanna check to make sure there is an outstanding check out with no check in??
-- uh, cause if it's been checked in, it's not lost

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
		   END as UserKey, 
		  -- u.ResponsibleUserKey, -- debug
		   LibraryProject.LostAssetFee(@AssetKey) as Amount
	FROM LibraryProject.Users AS U
		 INNER JOIN
	(
		SELECT l.UserKey, 
			   a.ReplacementCost
		FROM LibraryProject.AssetLoans l
			 INNER JOIN LibraryProject.Assets a ON a.AssetKey = l.AssetKey
		WHERE --l.AssetKey = @AssetKey
			  --AND -- more than one most likely
			  l.ReturnedOn IS NULL		-- should really only be one -- What if there's 0?
	) AS UserFee ON U.UserKey = UserFee.UserKey;

/*
 TODO: have a child try to check out 3 books
 Should get an error on the 3rd
 Try to have someone check out a book that isn't returned
 
*/


-------------------- BEGIN CONSTRAINTS ----------------------

ALTER TABLE LibraryProject.Assets
ADD CONSTRAINT AssetReplacementCostLimit
	CHECK (ReplacementCost <= 29.99)
;

-------------------- END CONSTRAINTS ----------------------

-------------------- BEGIN VIEWS ----------------------
--Create a view that leverages your fee function to show what fees were 
--generated for each asset that has been checked out and returned (or lost).
--Have your view only return records where there is a fee of some sort.
CREATE OR ALTER VIEW LibraryProject.AssetFeeView
AS
	SELECT
		AssetFee.*
	FROM
		(SELECT
			A.Asset,
			CASE
			   WHEN U.ResponsibleUserKey IS NULL
			   THEN U.UserKey
			   ELSE U.ResponsibleUserKey
			END AS UserKey, 
			CASE 
				WHEN AL.ReturnedOn IS NOT NULL THEN LibraryProject.GetFine(AL.LoanedOn, AL.ReturnedOn)
				WHEN AL.LostOn IS NOT NULL THEN LibraryProject.LostAssetFee(A.AssetKey)
				ELSE LibraryProject.GetFine(AL.LoanedOn, GETDATE())
			END AS Fee
		FROM
			LibraryProject.Assets A
			INNER JOIN LibraryProject.AssetLoans AL
				ON A.AssetKey = AL.AssetKey
			INNER JOIN LibraryProject.Users U
				ON AL.UserKey = U.UserKey) AS AssetFee
	WHERE
		AssetFee.Fee > 0
;


--Create a view that shows all overdue books and which of the fee buckets they currently fall in (based on the function above).
--Include the responsible user (parent if kids books are late) and an email address.
--This view should only include books that are checked out and currently overdue.
CREATE OR ALTER VIEW LibraryProject.OverdueBookFees
AS (
	SELECT
		A.Asset,
		A.AssetDescription,
		AL.LoanedOn,
		CASE
			WHEN AL.ReturnedOn IS NOT NULL THEN LibraryProject.GetFine(AL.LoanedOn, AL.ReturnedOn)
			ELSE LibraryProject.GetFine(AL.LoanedOn, GETDATE())
		END AS FeeAmount,
		U.Email,
		CASE
			WHEN U.ResponsibleUserKey IS NULL THEN 'None'
			ELSE
			(
				SELECT
					LibraryProject.Users.FirstName + ' ' + LibraryProject.Users.LastName
				FROM
					LibraryProject.Users
				WHERE
					LibraryProject.Users.UserKey = U.ResponsibleUserKey
			)
			END AS ResponsibleUser,
		CASE
			WHEN U.ResponsibleUserKey IS NULL THEN 'None'
			ELSE
			(
				SELECT
					LibraryProject.Users.Email
				FROM
					LibraryProject.Users
				WHERE
					LibraryProject.Users.UserKey = U.ResponsibleUserKey
			)
		END AS ResponsibleUserEmail
	FROM
		LibraryProject.AssetLoans AS AL
		LEFT JOIN LibraryProject.Assets AS A ON A.AssetKey = AL.AssetKey
		LEFT JOIN LibraryProject.AssetTypes AS AT ON AT.AssetTypeKey = A.AssetTypeKey
		LEFT JOIN LibraryProject.Users AS U ON U.UserKey = AL.UserKey
	WHERE
		AT.AssetType = 'Book'
		AND AL.ReturnedOn IS NULL
		AND AL.LostOn IS NULL
);

-------------------- END VIEWS ----------------------


------------------- BEGIN TASKS ---------------------

--Create a new asset type
Exec LibraryProject.NewAssetType 'Audio';
-- Tyler Durden has lost the book ï¿½Mistbornï¿½.  
-- His library card was in the book (used as a bookmark).  
-- Report the book lost, 
exec LibraryProject.ReportAssetLost 2 -- Internal knowledge, 2 = Mistborn
-- make sure he pays his fees, 
exec LibraryProject.PayAllFeesForUser 5 -- Shotgun approach, sure, and yeah Tyler is user 5
-- and issue him a new card
exec LibraryProject.IssueCard 5, 'a123-456-7890' --the a could have been procedurally generated, but whatever
---------------------------------------------------------------------------


---------------------------------------------------------------------------

--Create 10 new assets.  Make sure two of these assets are restricted.
--Create assets of the various types you have in your database, including the new one you created above
EXEC LibraryProject.CreateAsset 'Harry Potter and the Sorcerer''s Stone', 'Book 1 in the Harry Potter series by J.K. Rowling', 2, 29.99, 0;
EXEC LibraryProject.CreateAsset 'Shrek', 'Adventures of an cranky ogre who falls in love with a princess', 1, 9.99, 0;
EXEC LibraryProject.CreateAsset '19 Naughty III', 'Album by Naught By Nature', 3, 14.99, 1; --Restricted
EXEC LibraryProject.CreateAsset 'Cloud Atlas', 'Sci-fi movie baed off of book', 1, 19.99, 1; --Restricted
EXEC LibraryProject.CreateAsset 'Ender''s Game', 'One of the best sci-fi books ever', 2, 8.99, 0;
EXEC LibraryProject.CreateAsset 'The BFG', 'The classic Big Friendly Giant by Roald Dahl', 2, 4.99, 0;
EXEC LibraryProject.CreateAsset 'Help!', 'Album by The Beatles', 3, 9.99, 0;
EXEC LibraryProject.CreateAsset 'To Kill A Mockingbird', 'Classic novel by Harper Lee', 2, 6.99, 0;
EXEC LibraryProject.CreateAsset 'Fifty Shades of Grey', 'Erotic romance novel by E. L. James', 2, 13.99, 1; --Restricted
EXEC LibraryProject.CreateAsset 'The Lion King', 'Classic animatred film by Walt Disney Pictures', 1, 4.99, 0;

BEGIN
	DECLARE @Today DATE = GETDATE();

	-- User key 2 has a teen card.
	-- Asset 7 is restricted.
	exec LibraryProject.LoanAsset 2, 7, @Today;
-- Also, try to check out a book to someone who has a fee, Tyler
	EXEC LibraryProject.LoanAsset 5, 9, @Today;
END
-- Tyler Durden has lost the book Mistborn.  ----------------------------
-- His library card was in the book (used as a bookmark).  
-- Report the book lost, 
exec LibraryProject.ReportAssetLost 2 -- Internal knowledge, 2 = Mistborn
-- while we know he has a fee, let's try to checkl out a book
-- make sure he pays his fees, 
exec LibraryProject.PayAllFeesForUser 5 -- Shotgun approach, sure, and yeah Tyler is user 5
-- and issue him a new card 
--(this method is also lazy/ssumptive.... deactivates all cards they own)

exec LibraryProject.IssueCard 5, 'a123-456-7890' --the a could have been procedurally generated, but whatever
---------------------
--Try to check out enough items to exceed the threshold for a user.
--This is probably easiest done for a child user

--UserKey 4 Jordan Smith is a child user
DECLARE @Today2 DATE = GETDATE();
EXEC LibraryProject.LoanAsset 4, 18, @Today2; --1 item checked out...
EXEC LibraryProject.LoanAsset 4, 16, @Today2; --2 items checked out...
EXEC LibraryProject.LoanAsset 4, 10, @Today2; --3 items checked out, should fail...

--Two or three that work as expected
DECLARE @Today3 DATE = GETDATE();
EXEC LibraryProject.LoanAsset 6, 3, @Today3; --1 that works as expected...
EXEC LibraryProject.LoanAsset 6, 6, @Today3; --1 that works as expected...
EXEC LibraryProject.LoanAsset 6, 9, @Today3; --1 that works as expected...

EXEC LibraryProject.CreateUser 
'Andrew','Merrell','AndrewMerrell1@weber.edu','1234 w 321 s','','Clearfield','UT','01/01/1980'
EXEC LibraryProject.CreateUser 
'Jonas','Riney-Merrell','AndrewMerrell1@weber.edu','1234 w 321 s','','Clearfield','UT','01/01/2001'
EXEC LibraryProject.CreateUser 
'Naia','Riney-Merrell','AndrewMerrell1@weber.edu','1234 w 321 s','','Clearfield','UT','01/01/2010'
--- ok, so maybe there should be a create children funtion where you 
---  pass names and birthdays for children and a user key for the adult?  Ohh well
update LibraryProject.Users 
set ResponsibleUserKey = 7 
where LastName = 'Riney-Merrell'

--Select * from LibraryProject.Users
exec LibraryProject.IssueCard 7, 'a801-651-5127'
exec LibraryProject.IssueCard 8, 't801-651-5127'
exec LibraryProject.IssueCard 9, 'c801-651-5127'
--select * from LibraryProject.Cards

--Keyser Soze has moved to 4242 Not Here Way in Plain City, UT.
--Use your stored procedure to update his address
SELECT * FROM LibraryProject.Users
EXEC LibraryProject.UpdateUser @UserKey = 6, @Address1 = '4242 Not Here Way', @City = 'Plain City', @StateAbbv = 'UT';

-------------------- END TASKS ----------------------
--This checkouts then checks in 3 books.
BEGIN
	-- Variables for the test checkout and checkin date. 
	DECLARE @CheckoutDate DATE = '2018-10-25'; -- Checkout Date is more than 21 days in the past.
	DECLARE @CheckinDate DATE = '2018-10-30';
	DECLARE @Today4 DATE = GETDATE();
	
	-- Variables used to store the new asset loan keys.
	DECLARE @AssetLoanKey1 INT;
	DECLARE @AssetLoanKey2 INT;
	DECLARE @AssetLoanKey3 INT;

	-- First checks out a book.
	EXEC LibraryProject.LoanAsset 1, 6, @CheckoutDate;

	-- Second gets its asset loan key.
	SELECT TOP 1
		@AssetLoanKey1 = AssetLoanKey
	FROM
		LibraryProject.AssetLoans
	ORDER BY
		AssetLoanKey DESC

	-- Rinse and Repeat.
	EXEC LibraryProject.LoanAsset 1, 3, @CheckoutDate;

	SELECT TOP 1
		@AssetLoanKey2 = AssetLoanKey
	FROM
		LibraryProject.AssetLoans
	ORDER BY
		AssetLoanKey DESC

	EXEC LibraryProject.LoanAsset 1, 4, @CheckoutDate;

	SELECT TOP 1
		@AssetLoanKey3 = AssetLoanKey
	FROM
		LibraryProject.AssetLoans
	ORDER BY
		AssetLoanKey DESC
	
	-- Checks in the 3 books. 
	EXEC LibraryProject.ReturnAsset @AssetLoanKey1, @Today4; -- This will be late and should generate a fee.
	EXEC LibraryProject.ReturnAsset @AssetLoanKey2, @CheckinDate;
	EXEC LibraryProject.ReturnAsset @AssetLoanKey3, @CheckinDate;
END


-------------------- END TASKS ----------------------
-------------------- END TASKS ----------------------
