if not exists(select * from sys.databases where name='names')
    create database names;
GO

use names;
GO

-- DOWN

drop table if exists persons;
drop table if exists particles;
GO

-- UP Metadata

-- SQL Server does not support arrays.
create table particles (
    particle_id integer identity not null,
    particle_person_id integer not null,
    particle_type varchar(50) not null, -- 'given', 'nick', 'alias'
    particle_order int not null,
    particle_name nvarchar(100) not null,
    particle_ascii varchar(100),
    particle_ipa nvarchar(100), -- pronunciation

    CONSTRAINT pk_particles_particle_id PRIMARY KEY (particle_id)
)

create table titles (
    title_id integer identity not null,
    title_title nvarchar(100) not null,
    title_ascii varchar(100),
    title_ipa nvarchar(100),

    CONSTRAINT pk_titles_title_id PRIMARY KEY (title_id)
)

-- This is a mostly unnormalized table.
create table persons (
    person_id int IDENTITY not null,
    person_given_name nvarchar(100) null,
    person_family_name nvarchar(100) null,
    person_additional_given_name_id integer, -- middle names in the English-speaking world
    person_mothers_given_name nvarchar(100) null, -- Needed for Icelandic and Russian locales
    person_mothers_family_name nvarchar(100) null, -- Meeded fpr Spanish locale
    person_fathers_given_name nvarchar(100) null, -- Needed for Icelandic and Russian locales
    peron_fathers_family_name nvarchar(100) null, -- Needed for Spanish locale
    -- 
    person_tribe_or_clan nvarchar(100) null,
    -- 
    person_nick_name_ids integer,
    person_preferred_locale nvarchar(50),
    person_dead_name bit, -- TODO figure out how to represent this.
    person_gender_identity nvarchar(50) null, -- Needed by many locales.
    person_preferred_pronouns_nominative nvarchar(50) null,
    person_legal_alias_id integer,
    person_use_name nvarchar(100) null, -- This is the name you want to use in most informal situations.

    -- overrides
    person_override_full_name nvarchar(100),
    person_override_full_name_ascii varchar(100),

    -- prefixes and suffixes
    person_prefix_titles integer,
    preson_prefix_honorific nvarchar(50) null,
    person_suffix_titles integer,
    person_suffix_honorific nvarchar(50) null,
    person_suffix_suffix varchar(50),

    CONSTRAINT pk_persons_person_id PRIMARY KEY (person_id)
);

-- UP Views
-- These views are selected by locale and use case.

-- UP Data

-- Verify
select * from persons;
