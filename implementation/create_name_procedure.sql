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
            THROW 51105, 'p_upsert_person_id: An Error occurred when upserting person.',1
        END CATCH
        RETURN @person_id
    END;
GO


-- ************************* --
-- upsert particles
-- ************************* --


DROP PROCEDURE IF EXISTS p_upsert_particle;
GO

CREATE PROCEDURE p_upsert_particle (
    @upsert_particle_type AS varchar,
    @upsert_particle_unicode_text as NVARCHAR,
    @upsert_particle_latin1_text as VARCHAR,
    @upsert_particle_ipa_text as NVARCHAR,
    @upsert_locale_id as INT
)
AS BEGIN
    BEGIN TRANSACTION
        BEGIN TRY
            DECLARE @upsert_particle_id int = NULL;

            set @upsert_particle_id = (select p.particle_id from particles p where p.particle_unicode = @upsert_particle_unicode_text)

            if(@upsert_particle_id is NULL)
                BEGIN
                    INSERT INTO particles (particle_type_id, particle_unicode, particle_latin1, particle_ipa, particle_locale_id)
                    VALUES(dbo.get_particle_type_id(@upsert_particle_type), @upsert_particle_unicode_text,
                    @upsert_particle_latin1_text, @upsert_particle_ipa_text, @upsert_locale_id)
                    SET @upsert_particle_id = SCOPE_IDENTITY();
                END
            ELSE
                BEGIN
                    UPDATE particles 
                    SET  particle_type_id = dbo.get_particle_type_id(@upsert_particle_type),
                    particle_latin1 = @upsert_particle_latin1_text,
                    particle_ipa = @upsert_particle_ipa_text,
                    particle_locale_id = @upsert_locale_id
                    WHERE particle_id = @upsert_particle_id;
                END
            COMMIT
        END TRY
        BEGIN CATCH
            ROLLBACK
            ;
            THROW 51110, 'p_upsert_particle: An Error occurred when upserting a particle.',1
        END CATCH
    END;
GO



-- ************************* --
-- DROP THE PROCEDURE TO CREATE A NAME 
-- this is done first as the procedure references the custom type OrderedParticles
-- ************************* --

DROP PROCEDURE IF EXISTS p_create_name;
GO


-- ************************* --
-- DROP THE CUSTOM TYPE ORDEREDPARTICLES
-- ************************* --


DROP TYPE IF EXISTS OrderedParticles;
GO



-- ************************* --
-- CREATE a custom table type to organize all submitted name particles and their orders
-- ************************* --

CREATE TYPE OrderedParticles AS TABLE ( particle_order_order INT NOT NULL, particle_unicode NVARCHAR(50) NOT NULL, particle_latin1 VARCHAR(50), particle_ipa NVARCHAR(50), particle_type_type varchar(50));
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
    @locale_country AS VARCHAR,                             -- *required
    @locale_language AS VARCHAR,                            -- *required
    @email_address AS VARCHAR,                              -- *required

    @given_name_unicode AS NVARCHAR,                        -- *required. delimied list.
    @given_name_latin1 AS VARCHAR = NULL,                   -- optional. delimied list.
    @given_name_ipa AS NVARCHAR = NULL,                     -- optional. delimied list.

    @family_name_unicode as NVARCHAR = NULL,                -- *required.
    @family_name_latin1 as VARCHAR = NULL,                  -- optional
    @family_name_ipa AS NVARCHAR = NULL,                    -- optional

    @is_dead_name as BIT,                                   -- *required
    @use_name_unicode AS NVARCHAR = NULL,                   -- optional.  
    @use_name_latin1 AS VARCHAR = NULL,                     -- optional. 
    @use_name_ipa AS NVARCHAR = NULL,                       -- optional. 

    @is_legal_name as BIT,                                  -- *required
    @legal_alias_unicode AS NVARCHAR = NULL,                -- optional. 
    @legal_alias_latin1 AS VARCHAR = NULL,                  -- optional. 
    @legal_alias_ipa AS NVARCHAR = NULL,                    -- optional. 

    @preferred_locale_country as VARCHAR = NULL,            -- optional.
    @preferred_locale_language as VARCHAR = NULL,           -- optional.

    -- ****** GENDER IDENTITY INFORMATION ****** --
    @gender_identity AS VARCHAR = NULL,                     -- optional.

    @pronoun_nominative AS NVARCHAR = NULL,                  -- optional.
    @pronoun_accusative AS NVARCHAR = NULL,                  -- optional.
    @pronoun_genative AS NVARCHAR = NULL,                    -- optional.

    @preferred_honorific_unicode as NVARCHAR = NULL,         -- optional
    @preferred_honorific_latin1 as VARCHAR = NULL,           -- optional
    @preferred_honorific_ipa AS NVARCHAR = NULL,             -- optional

    -- ****** CULTERAL IDENTITY INFORMATION ****** --
    @tribe_clan_name_unicode  AS NVARCHAR = NULL,           -- optional.
    @tribe_clan_name_latin1 as VARCHAR = NULL,              -- optional.
    @tribe_clan_name_ipa AS VARCHAR = NULL,                 -- optional.

    @mother_email as VARCHAR = NULL,                        -- optional. 
    @father_email as VARCHAR = NULL,                        -- optional. 


    -- ****** NAME OVERRIDE INFORMATION ****** --
    @override_full_name_unicode as NVARCHAR = NULL,         -- optional.
    @override_full_name_latin1 as VARCHAR = NULL,           -- optional.
    @override_full_name_ipa AS VARCHAR = NULL               -- optional.

)
AS BEGIN
    BEGIN TRANSACTION
        BEGIN TRY
            -- Orchestrate proper order of operations for inserting a name

            -- Step 1: upsert particles
            DECLARE 
                @UL_Cursor CURSOR,
                @Rows INTEGER,
                @_particle_unicode NVARCHAR,
                @_particle_latin1 VARCHAR,
                @_particle_ipa NVARCHAR,
                @_particle_type_type VARCHAR,
                @_locale_id INT;

            SET @_locale_id = dbo.get_locale_id(@locale_language, @locale_country);

            SET @UL_Cursor = CURSOR FORWARD_ONLY STATIC READ_ONLY FOR
                Select particle_unicode,particle_latin1,particle_ipa,particle_type_type from @UL;

            OPEN @UL_Cursor;

            SET @Rows = @@CURSOR_ROWS;

            While @Rows > 0
            BEGIN
                FETCH NEXT FROM @UL_Cursor INTO 
                 @_particle_unicode,  @_particle_latin1,  @_particle_ipa, @_particle_type_type;

                EXEC p_upsert_particle 
                @upsert_particle_type = @_particle_type_type, 
                @upsert_particle_unicode_text = @_particle_unicode, 
                @upsert_particle_latin1_text = @_particle_latin1, 
                @upsert_particle_ipa_text =  @_particle_ipa,
                @upsert_locale_id = @_locale_id;

                SET @Rows -=1;
            END;

            -- Step 2: upsert person.
            DECLARE @person_id int
            EXEC @person_id = DBO.p_upsert_person_id @upsert_email_address = @email_address;
            
            -- Step 3: insert into names
            DECLARE 
                @given_name_partcile_id INT,
                @family_name_particle_id INT = NULL,
                @preferred_honorific_particle_id INT = NULL,
                @tribe_or_clan_particle_id INT = NULL,
                @legal_alias_particle_id INT = NULL,
                @use_name_particle_id INT = NULL,
                @preferred_locale_id INT = NULL,
                @mother_person_id INT = NULL,
                @father_person_id INT = NULL;

                EXEC @given_name_partcile_id = dbo.p_upsert_particle 
                @upsert_particle_type = 'Given', 
                @upsert_particle_unicode_text = @given_name_unicode, 
                @upsert_particle_latin1_text = @given_name_latin1, 
                @upsert_particle_ipa_text =  @given_name_ipa,
                @upsert_locale_id = @_locale_id;

                if (@family_name_unicode is NOT NULL)
                BEGIN
                    EXEC @family_name_particle_id = dbo.p_upsert_particle 
                    @upsert_particle_type = 'Family', 
                    @upsert_particle_unicode_text = @family_name_unicode, 
                    @upsert_particle_latin1_text = @family_name_latin1, 
                    @upsert_particle_ipa_text =  @family_name_ipa,
                    @upsert_locale_id = @_locale_id;
                END

                if (@preferred_honorific_unicode is NOT NULL)
                BEGIN
                    EXEC @preferred_honorific_particle_id = dbo.p_upsert_particle 
                    @upsert_particle_type = 'Prefix Title', 
                    @upsert_particle_unicode_text = @preferred_honorific_unicode, 
                    @upsert_particle_latin1_text = @preferred_honorific_latin1, 
                    @upsert_particle_ipa_text =  @preferred_honorific_ipa,
                    @upsert_locale_id = @_locale_id;
                END

                if (@tribe_clan_name_unicode is NOT NULL)
                BEGIN
                    EXEC @tribe_or_clan_particle_id = dbo.p_upsert_particle 
                    @upsert_particle_type = 'Tribe or Clan', 
                    @upsert_particle_unicode_text = @tribe_clan_name_unicode, 
                    @upsert_particle_latin1_text = @tribe_clan_name_latin1, 
                    @upsert_particle_ipa_text =  @tribe_clan_name_ipa,
                    @upsert_locale_id = @_locale_id;
                END


                if (@legal_alias_unicode is NOT NULL)
                BEGIN
                    EXEC @legal_alias_particle_id = dbo.p_upsert_particle 
                    @upsert_particle_type = 'Legal Alias', 
                    @upsert_particle_unicode_text = @legal_alias_unicode, 
                    @upsert_particle_latin1_text = @legal_alias_latin1, 
                    @upsert_particle_ipa_text =  @legal_alias_ipa,
                    @upsert_locale_id = @_locale_id;
                END


                if (@use_name_unicode is NOT NULL)
                BEGIN
                    EXEC @use_name_particle_id = dbo.p_upsert_particle 
                    @upsert_particle_type = 'Nickname', 
                    @upsert_particle_unicode_text = @use_name_unicode, 
                    @upsert_particle_latin1_text = @use_name_latin1, 
                    @upsert_particle_ipa_text =  @use_name_ipa,
                    @upsert_locale_id = @_locale_id;
                END

                if (@mother_email is not null)
                BEGIN
                    SET @mother_person_id = dbo.get_person_id(@mother_email)
                END

                if (@father_email is NOT NULL)
                BEGIN
                    SET @father_person_id = dbo.get_person_id(@father_email)
                END

                if (@preferred_locale_country is not null)
                BEGIN
                    SET  @preferred_locale_id = dbo.get_locale_id(@preferred_locale_language, @preferred_locale_country)
                END


                INSERT INTO dbo.Names (
                    name_locale_id, 
                name_is_legal_name, 
                name_is_dead_name, 
                name_preferred_locale_id, 
                name_gender_identity, 
                name_preferred_honorific_id, 
                name_preferred_pronoun_nominative,
                name_preferred_pronoun_accusative, 
                name_preferred_pronoun_genative,  
                name_override_full_name, 
                name_override_full_name_latin1, 
                name_override_full_name_ipa,
                name_given_name_particle_id,
                name_family_name_particle_id,
                name_tribe_or_clan_particle_id,
                name_legal_alias_particle_id,
                name_use_name_particle_id,
                name_person_id,
                name_mother_person_id,
                name_father_person_id)
                values(@_locale_id,
                @is_legal_name,
                @is_dead_name,
                @preferred_locale_id,
                @gender_identity,
                @preferred_honorific_particle_id,
                @pronoun_nominative,
                @pronoun_accusative,
                @pronoun_genative,
                @override_full_name_unicode,
                @override_full_name_latin1,
                @override_full_name_ipa,
                @given_name_partcile_id,
                @family_name_particle_id,
                @tribe_or_clan_particle_id,
                @legal_alias_particle_id,
                @use_name_particle_id,
                @person_id,
                @mother_person_id,
                @father_person_id
                )

            -- Step 3: insert into particle_order for each particle ID
select * from particle_types
            COMMIT
        END TRY
        BEGIN CATCH
            ROLLBACK
            ;
            THROW 51115, 'p_create_name: An Error occurred when attempting to insert a new name.',1
        END CATCH
    END;
GO


-- ************************* --
-- PERFORM THE INSERTS
-- This secton simulates the submission of values from the front-end form
-- ************************* --

DECLARE @ParticleList OrderedParticles;

INSERT @ParticleList VALUES (1,'Dr.',NULL,NULL,'Prefix Title'),(2,'La Monte',NULL,NULL,'Given'),(3,'Henry',NULL,NULL,'Given'),(4,'Piggy',NULL,NULL,'Given'),(5,'Yarroll',NULL,NULL,'Family'),(6,'esq.',NULL,NULL,'Suffix Title');

--EXEC dbo.p_create_name @UL = @ParticleList, @locale_country = 'us', @locale_language='eng', @email_address='piggy@cmu.edu', @given_name_unicode="La Monte", @is_dead_name=0,@is_legal_name=0;

select * from particles;

select * from persons;

GO