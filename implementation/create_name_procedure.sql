--NOTES:
-- add accusative_pronouns to the names table varchar(50)
-- Validate if we have a uniqueness constraint on the particle table (unicode, type).  This allows for unicode, latin1, ipa to have the same particle ID.

use Names
GO




-- ************************* --
-- upsert person record
-- ************************* --


DROP PROCEDURE IF EXISTS p_upsert_person_id;
GO

CREATE PROCEDURE p_upsert_person_id (
    @upsert_email_address AS VARCHAR(50)
)
AS BEGIN
    BEGIN TRANSACTION
        BEGIN TRY
            DECLARE @person_id int = NULL;

            set @person_id = (select p.person_id from persons p where p.person_email=trim(lower(@upsert_email_address)));

            if (@person_id is NULL)
                BEGIN
                    INSERT INTO Persons (person_email) VALUES (@upsert_email_address);
                    SET @person_id = SCOPE_IDENTITY();
                END
            COMMIT
            
        END TRY
        BEGIN CATCH
            ROLLBACK
            ;
            THROW 51005, 'p_upsert_person_id: An Error occurred when upserting person.',1
        END CATCH
        RETURN @person_id
    END;
GO



-- ************************* --
-- DROP THE PROCEDURE TO CREATE A NAME 
-- this is done first as the procedure references the custom type OrderedParticles
-- ************************* --

DROP PROCEDURE IF EXISTS p_create_name;
GO


-- ************************* --
-- DROP THE CUSTOM TYPE 
-- ************************* --


DROP TYPE IF EXISTS OrderedParticles;

-- ************************* --
-- CREATE a custom table type to organize all submitted name particles and their orders
-- ************************* --

CREATE TYPE OrderedParticles AS TABLE ( particle_order_order INT NOT NULL, particle_unicode NVARCHAR(50) NOT NULL, particle_latin1 VARCHAR(50), particle_ipa NVARCHAR(50), particle_type_type varchar(50));
GO


-- ************************* --
-- upsert particles
-- ************************* --


DROP PROCEDURE IF EXISTS p_upsert_particles;
GO

CREATE PROCEDURE p_upsert_particles (
    @upsert_particle_type AS varchar,
    @upsert_particle_unicode_text as NVARCHAR,
    @upsert_particle_latin1_text as VARCHAR,
    @upsert_particle_ipa_text as NVARCHAR
)
AS BEGIN
    BEGIN TRANSACTION
        BEGIN TRY
            DECLARE @type_id int = NULL;

        END TRY
        BEGIN CATCH
            ROLLBACK
            ;
            THROW 51005, 'p_upsert_person_id: An Error occurred when upserting person.',1
        END CATCH
    END;
GO


-- ************************* --
-- DEFINE THE STORED PROCEDURE TO CREATE A NAME 
-- ************************* --

CREATE PROCEDURE p_create_name
    (
    -- Define paramaters passed into stored procedure from application UI
    -- Default optional paramaters to NULL

    -- ****** CORE NAME INFORMATION ****** --
    @UL AS OrderedParticles READONLY,                       -- *required
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

            -- Step 1: upsert particles
            
            
            -- Step 2: upsert person.
            DECLARE @person_id int
            EXEC @person_id = DBO.p_upsert_person_id @upsert_email_address = @email_address;

            
            

            --Step 3: insert into particle_order for each particle ID

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


-- ************************* --
-- PERFORM THE INSERTS
-- This secton simulates the submission of values from the front-end form
-- ************************* --

DECLARE @UL OrderedParticles;

INSERT @UL VALUES (1,'Dr.',NULL,NULL,'Prefix Title'),(2,'La Monte',NULL,NULL,'Given'),(3,'Henry',NULL,NULL,'Given'),(4,'Piggy',NULL,NULL,'Given'),(5,'Yarroll',NULL,NULL,'Family'),(6,'esq.',NULL,NULL,'Suffix Title');

--EXEC dbo.p_create_name(@UL, add paramaters );
select * from @UL;

GO