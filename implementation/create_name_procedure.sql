--NOTES:
-- 1.) add person_email_address to persons table varchar(100) not null
-- 2.) add accusative_pronouns to the names table varchar(50)
-- 3.) Validate if we have a uniqueness constraint on the particle table (unicode, type).  This allows for unicode, latin1, ipa to have the same particle ID.

use Names
GO

-- ************************* --
-- DEFINE FUNCTIONS NEEDED TO SUPPORT CREATE NAME PROCEDURE --
-- ************************* --



-- ************************* --
-- function to retrieve person_id for an email address
-- returns null if no match
-- ************************* --

DROP FUNCTION IF EXISTS f_find_person_from_email;
GO

CREATE FUNCTION f_find_person_from_email (@new_email_address VARCHAR)
RETURNS INT
AS
BEGIN
    DECLARE @person_id int;

    set @person_id = (select p.person_id from persons p where p.person_email_address=trim(lower(@new_email_address)))

    RETURN @person_id;
END;
GO


-- ************************* --
-- function to check particles to see if the text is already in the database 
-- ************************* --

DROP FUNCTION IF EXISTS f_validate_particle_id;
GO

CREATE FUNCTION f_validate_name_id_unicode (@particle_text nvarchar(50), @particle_type_type varchar(50))
RETURNS INT
BEGIN
    DECLARE @name_particle_id int;

    SELECT @name_particle_id = p.particle_id
        from particles p 
        JOIN particle_types pt on p.particle_type_id = pt.particle_type_id
        WHERE pt.particle_type_type = trim(@particle_type_type)
        AND p.particle_unicode = trim(@particle_text)

    RETURN @name_particle_id;
END;
GO


-- ************************* --
-- This secton simulates the submission of values from the front-end form to the back-end
-- First a custom table type is created to organize all submitted name particles and their orders
-- This table is then passed along with all other paramaters to a stored procedure that orchestrates the database inserts
-- ************************* --

DROP TYPE IF EXISTS OrderedParticles;

CREATE TYPE OrderedParticles AS TABLE ( particle_order_order INT NOT NULL, particle_unicode NVARCHAR(50) NOT NULL, particle_latin1 VARCHAR(50), particle_ipa NVARCHAR(50), particle_type_type varchar(50));
GO

DECLARE @UL OrderedParticles;

INSERT @UL VALUES (1,'Dr.',NULL,NULL,'Prefix Title'),(2,'La Monte',NULL,NULL,'Given'),(3,'Henry',NULL,NULL,'Given'),(4,'Piggy',NULL,NULL,'Given'),(5,'Yarroll',NULL,NULL,'Family'),(6,'esq.',NULL,NULL,'Suffix Title');

--EXEC dbo.p_create_name(@UL);
GO




-- ************************* --
-- DEFINE THE STORED PROCEDURE TO CREATE A NAME 
-- ************************* --
DROP PROCEDURE IF EXISTS p_create_name;
GO


CREATE PROCEDURE p_create_eng_us_name
    (
    -- Define paramaters passed into stored procedure from application UI
    -- Default optional paramaters to NULL

    -- ****** CORE NAME INFORMATION ****** --
    @OrderedParticles AS OrderedParticles READONLY,         -- *required
    @locale_country AS INT,                                 -- *required
    @locale_language AS INT,                                -- *required
    @email_address AS VARCHAR,                              -- *required

    @given_name_unicode AS NVARCHAR,                        -- *required. delimied list.
    @given_name_latin1 AS VARCHAR = NULL,                   -- optional. delimied list.
    @given_name_list_ipa AS NVARCHAR = NULL,                -- optional. delimied list.

    @family_nameunicode as NVARCHAR,                        -- *required.
    @family_name_latin1 as VARCHAR = NULL,                  -- optional
    @family_name_ipa AS NVARCHAR = NULL,                    -- optional

    @is_dead_name as BIT,                                   -- *required
    @preferred_name_unicode AS NVARCHAR = NULL,             -- optional.  
    @preferred_name_latin1 AS VARCHAR = NULL,               -- optional. 
    @preferred_name_ipa AS NVARCHAR = NULL,                 -- optional. 

    @is_legal_name as BIT,                                  -- *required
    @legal_alias_given_name_unicode AS NVARCHAR = NULL,     -- optional. 
    @legal_alias_given_name_latin1 AS VARCHAR = NULL,       -- optional. 
    @legal_alias_given_name_ipa AS NVARCHAR = NULL,         -- optional. 

    @legal_alias_family_name_unicode as NVARCHAR = NULL,    -- optional. 
    @legal_alias_family_name_latin1 as VARCHAR = NULL,      -- optional. 
    @legal_alias_family_name_ipa AS NVARCHAR = NULL,        -- optional. 

    @preferred_locale_id as INT = NULL,                     -- optional.

    -- ****** GENDER IDENTITY INFORMATION ****** --
    @gender_identity AS VARCHAR = NULL,                     -- optional.

    @nominative_pronouns AS VARCHAR = NULL,                 -- optional.
    @accusative_pronouns AS VARCHAR = NULL,                 -- optional.
    @genative_pronouns AS VARCHAR = NULL,                   -- optional.

    @honorific_text As VARCHAR = NULL,                      -- optional.

    -- ****** CULTERAL IDENTITY INFORMATION ****** --
    @tribe_clan_name_unicode  AS NVARCHAR = NULL,           -- optional.
    @tribe_clan_name_latin1 as VARCHAR = NULL,              -- optional.
    @tribe_clan_name_ipa AS VARCHAR = NULL,                -- optional.

    @mother_family_name_unicode as NVARCHAR = NULL,         -- optional. 
    @mother_family_name_latin1 as VARCHAR = NULL,           -- optional. 
    @mother_family_name_ipa AS VARCHAR = NULL,             -- optional. 

    @father_family_name_unicode as NVARCHAR = NULL,         -- optional. 
    @father_family_name_latin1 as VARCHAR = NULL,           -- optional. 
    @father_family_name_ipa AS VARCHAR = NULL,             -- optional. 


    -- ****** NAME OVERRIDE INFORMATION ****** --
    @override_full_name_unicode as NVARCHAR = NULL,         -- optional.
    @override_full_name_latin1 as VARCHAR = NULL,           -- optional.
    @override_full_name_ipa AS VARCHAR = NULL              -- optional.

)
AS BEGIN
    BEGIN TRANSACTION
        BEGIN TRY
            -- Orchestrate proper order of operations for inserting a name

            -- Step 1: Call f_find_person_from_email and retrieve the person_id if already in the database.
            DECLARE @person_id int;
            set @person_id = dbo.f_find_person_from_email(@email_address);
            
            -- Step 2: if @person_id is null, create a new person
                -- @person_id, @person_email_address
                -- set @person_id = @@identity; 

            -- Step 3: loop through each particle in the table and check if it is in the datbase already
                -- if so, return identity
                -- if not, insert into particles and return identity
                -- note: check only identity?

            -- Step 4: insert into particle_order for each particle ID

            -- Step 5: insert into names

        COMMIT
        END TRY
    BEGIN CATCH
        ROLLBACK
        ;
        THROW 51001, 'p_insert_name: An Error occurred when attempting to insert a new name.',1
    END CATCH
END;
GO
