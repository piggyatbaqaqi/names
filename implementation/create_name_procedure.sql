-- Piggy: This would be a lot easier with the github comment process. Create a new branch named 'create_names/murphy' and send a merge request.
-- We don't necesarily plan to merge right away, but it gives a way have a discussion thread about each point attached
-- to the source code.

-- OPEN QUESTIONS:
-- 1.) How are particle orders defined for each name and locale combination?


use Names
GO

-- DEFINE FUNCTIONS NEEDED TO SUPPORT CREATE NAME PROCEDURE

DROP FUNCTION IF EXISTS f_validate_email;
GO

CREATE FUNCTION f_validate_email (@email_address VARCHAR)
RETURNS BIT
BEGIN
    DECLARE @is_new_email bit;

    IF EXISTS(select * from persons p where p.email_address=trim(lower(@email_address)))
        select @is_new_email = 1
    ELSE
        select @is_new_email = 0
    RETURN @is_new_email;
END;
GO

DROP FUNCTION IF EXISTS f_validate_name_id_unicode;
GO

-- function to check unicode particles to see if the text is already in the database 
CREATE FUNCTION f_validate_name_id_unicode (@name_text nvarchar(50), @particle_type varchar(50))
RETURNS INT
BEGIN
    DECLARE @name_particle_id int;

    SELECT @name_particle_id = p.particle_id
        from particles p 
        JOIN particle_types pt on p.particle_type_id = pt.particle_type_id
        WHERE pt.particle_type_type = trim(lower(@particle_type))
        AND p.particle_unicode = trim(lower(@name_text))

    RETURN @name_particle_id;
END;
GO

DROP FUNCTION IF EXISTS f_validate_name_id_latin1;
GO

-- function to check latin1 particles to see if the text is already in the database 
CREATE FUNCTION f_validate_name_id_latin1 (@name_text nvarchar(50), @particle_type varchar(50))
RETURNS INT
BEGIN
    DECLARE @name_particle_id int;

    SELECT @name_particle_id = p.particle_id
        from particles p 
        JOIN particle_types pt on p.particle_type_id = pt.particle_type_id
        WHERE pt.particle_type_type = trim(lower(@particle_type))
        AND p.particle_latin1 = trim(lower(@name_text))

    RETURN @name_particle_id;
END;
GO

DROP FUNCTION IF EXISTS f_validate_name_id_ipa;
GO

-- function to check latin1 particles to see if the text is already in the database 
CREATE FUNCTION f_validate_name_id_ipa (@name_text nvarchar(50), @particle_type varchar(50))
RETURNS INT
BEGIN
    DECLARE @name_particle_id int;

    SELECT @name_particle_id = p.particle_id
        from particles p 
        JOIN particle_types pt on p.particle_type_id = pt.particle_type_id
        WHERE pt.particle_type_type = trim(lower(@particle_type))
        AND p.particle_ipa = trim(lower(@name_text))

    RETURN @name_particle_id;
END;
GO

-- DEFINE THE STORED PROCEDURE TO CREATE A NAME
DROP PROCEDURE IF EXISTS p_create_name;
GO

-- There's a different procedure for each locale.
-- CREATE PROCEDURE p_create_name
CREATE PROCEDURE p_create_eng_us_name
    (
    --define paramaters passed into stored procedure from application UI
    -- Piggy: We want optional parameters like this: https://stackoverflow.com/questions/1810638/optional-parameters-in-sql-server-stored-procedure
    -- ****** CORE NAME INFORMATION (see UI mockup) ****** --
    @locale_id AS INT,                                  -- passed by UI when locale selected before browsing create name form
    @email_address AS VARCHAR,                          -- unique email address associated with a unique person

    @given_name_unicode AS NVARCHAR,                    -- unicode given name entered into the UI.
    @given_name_latin1 AS VARCHAR,                      -- latin1 given name entered into the UI.
    @given_name_list_ipa AS NVARCHAR,                   -- IPA for the given name entered into the UI.

    @family_nameunicode as NVARCHAR,                    -- unicode for family name entered into the UI.
    @family_name_latin1 as VARCHAR,                     -- latin1 family name entered into the UI.
    @family_name_ipa AS NVARCHAR,                       -- IPA for family name  entered into the UI.

    @is_dead_name as BIT,                               -- 1 if checkbox selected, 0 if checkbox not selected
    @preferred_name_unicode AS NVARCHAR,                -- delimied list of unicode preferred names (first, middle, etc.) entered into the UI.  1 or more. maps to use name.  
    @preferred_name_latin1 AS VARCHAR,                  -- delimied list of latin1 preferred names (first, middle, etc.) entered into the UI.  1 or more. maps to use name.  
    @preferred_name_ipa AS NVARCHAR,                    -- delimied list of IPA for each preferred name (first, middle, etc.) entered into the UI.  1 or more. maps to use name.  

    @is_legal_name as BIT,                              -- 1 if checkbox selected, 0 if checkbox not selected  
    @legal_alias_given_name_unicode AS NVARCHAR,        -- unicode legal alias given name entered into the UI.
    @legal_alias_given_name_latin1 AS VARCHAR,          -- latin1 legal alias given name entered into the UI.
    @legal_alias_given_name_ipa AS NVARCHAR,            -- ipa for legal alias given name entered into the UI..

    @legal_alias_family_name_unicode as NVARCHAR,       -- unicode for legal alias family name entered into the UI.
    @legal_alias_family_name_latin1 as VARCHAR,         -- latin1 for legal alias family name entered into the UI.
    @legal_alias_family_name_ipa AS NVARCHAR,           -- IPA for legal alias family name entered into the UI.

    @preferred_locale_id as INT,                        -- passed by UI when locale preference selected on name create name form

    -- ****** GENDER IDENTITY INFORMATION (see UI mockup) ****** --
    @gender_identity AS VARCHAR,                        -- Gender identity entered via text field in the UI
    @nominative_pronouns AS VARCHAR,                    -- Gender pronouns entered via text field in the UI
    @genative_pronouns AS VARCHAR,                      -- Name Prefix - logically grouped with gender information
    @honorific_text As VARCHAR, 

    -- ****** CULTERAL IDENTITY INFORMATION (see UI mockup) ****** --
    @tribe_clan_name_unicode  AS NVARCHAR,               -- text of tribe or clan unicode name enered into the UI.
    @tribe_clan_name_latin1 as VARCHAR,                 -- text of tribe or clan unicode name enered into the UI.
    @tribe_clan_name_ipa AS NVARCHAR,                   -- text of tribe or clan unicode name enered into the UI.

    @mother_person_id as INT,                           -- passed if association is made on the name record, null if not
    @father_person_id as INT,                           -- passed if association is made on the name record, null if not

    -- ****** OVERRIDE IDENTITY INFORMATION (See UI mockup) ****** --
    @override_full_name_unicode as NVARCHAR,           -- text of unicode full override name entered into the UI.
    @override_full_name_latin1 as VARCHAR,             -- text of latin1 full override name entered into the UI.
    @override_full_name_ipa AS NVARCHAR,               -- text for ipa of full override name value entered into the UI.

)
AS BEGIN
    BEGIN TRANSACTION
        BEGIN TRY
            -- Orchestrate proper order of operations for inserting a name

            -- Step 1: Call f_validate_email and throw error if email already in the database
                -- if there is a match, throw an error
                -- Piggy: No, if the email is already in the database, get the person_id that goes with it and use that going forward.
                --        It is perfectly reasonable to create more than one name for a given person.

                -- if no match, perform an insert into the persons table and capture new ID in a variable
                -- variables created: @new_person_id
            
            -- Piggy: Rather than these validation functions, provide conditional insert functions that return the id.
            --- If the particle exists, just return the id, otherwise create the entry and return the id.

            -- Step 2: Call a f_validate_name_id function (unicode, latin1, ipa) to confirm if entry already in database. 
                -- If function returns null, proceed with insert and capture new ID in a variable
                -- If function returns an ID, simply store the ID in a new variable.
                -- repeat this process for all submitted name information that maps to unique particles

                -- Piggy: I recommend not checking the latin1 or ipa components of the record. All three forms should
                --    should resolve to the same id. If we didn't specify a uniqueness constraint on (unicode, type),
                --    we should have.
                -- We should only create one id per triple. It's OK to check that the latin1 and ipa match, but
                --    that is a low priority. I suggest we add that as a refinement later, if we have time.
                -- variables created: @given_name_particle_id_unicode, @given_name_particle_id_latin1, @given_name_particle_id_ipa, @family_name_particle_id_unicode, 
                    -- @family_name_particle_id_latin1, @family_name_particle_id_ipa, @tribe_or_clan_unicode_id, @tribe_or_clan_latin1_id, @tribe_or_clan_ipa_id, @legal_alias_unicode_id, @legal_alias_latin1_id, @legal_alias_ipa_id,
                    -- @preferred_name_unicode_id, @preferred_name_latin1_id, @preferred_name_ipa_id

                    -- Piggy: revised variables created: @given_name_particle_id, @family_name_particle_id, 
                    -- @tribe_or_clan_particle_id, @legal_alias_particle_id, @preferred_name_particle_id
                    -- We only use the variables 
                    --NOTE: there will be multiple given name particle ID's on one name record (i.e. particle reference ID's) if values are submtited for unicode, latin1 and ipa.  the unicode text value is required.
                    --NOTE: there will be multiple family name particle ID's on one name record (i.e. particle reference ID's) if values are submtited for unicode, latin1 and ipa.   the unicode text value is required.
                    --NOTE: there will be multiple tribe or clan particle ID's on one name record (i.e. particle reference ID's) if values are submtited for unicode, latin1 and ipa.   the unicode text value is required.
                    --NOTE: there will be multiple legal alias particle ID's on one name record (i.e. particle reference ID's) if values are submtited for unicode, latin1 and ipa.   the unicode text value is required.
                    --NOTE: there will be multiple preferred name (names.use_name) particle ID's on one name record (i.e. particle reference ID's) if values are submtited for unicode, latin1 and ipa.  the unicode text value is required.

            -- Looks like https://stackoverflow.com/questions/42448596/how-do-i-pass-a-list-as-a-parameter-in-a-stored-procedure
            -- The second answer as of 2024/05/31 looks like what we want. We create a temporary table and insert into it and
            -- pass that to the procedure. The UI will need to generate the SQL to build the temporary table.
            -- Hmm... That would allow the application front-end to implement the locale-specific ordering, so maybe
            -- this could be locale-agnostic after all.
            -- step 3: assign ordering to the particles based on the name and the locale
                -- ** LA MONTE: We need to discuss

            -- Step 4: take all returned ID's and perform insert
                -- paramaters passed in: @locale_id, @is_legal_name, @is_dead_name, @preferred_locale_id, @gender_identity, @honorfic_text,  @nominative_pronoun_text, @genative_pronoun_text,
                    -- @override_full_name_unicode, @override_full_name_latin1, @override_full_name_ipa
                -- insert the values into names
                --

        COMMIT
        END TRY
    BEGIN CATCH
        ROLLBACK
        ;
        THROW 51001, 'p_insert_name: An Error occurred when attempting to insert a new name.',1
    END CATCH;
GO
