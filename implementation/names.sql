if not exists(select * from sys.databases where name='Names')
    create database Names
GO

use Names
GO

--DOWN
if exists(select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS where CONSTRAINT_NAME='fk_name_person_id')
    alter table names drop constraint fk_name_person_id
if exists(select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS where CONSTRAINT_NAME='fk_name_locale_id')
    alter table names drop constraint fk_name_locale_id
if exists(select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS where CONSTRAINT_NAME='fk_name_father_person_id')
    alter table names drop constraint fk_name_father_person_id
if exists(select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS where CONSTRAINT_NAME='fk_name_mother_person_id')
    alter table names drop constraint fk_name_mother_person_id
if exists(select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS where CONSTRAINT_NAME='fk_name__preferred_honorific_id')
    alter table names drop constraint fk_name__preferred_honorific_id
if exists(select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS where CONSTRAINT_NAME='fk_name_given_name_particle_id')
    alter table names drop constraint fk_name_given_name_particle_id
if exists(select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS where CONSTRAINT_NAME='fk_name_family_name_particle_id')
    alter table names drop constraint fk_name_family_name_particle_id
if exists(select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS where CONSTRAINT_NAME='fk_name_tribe_or_clan_particle_id')
    alter table names drop constraint fk_name_tribe_or_clan_particle_id
if exists(select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS where CONSTRAINT_NAME='fk_name_legal_alias_particle_id')
    alter table names drop constraint fk_name_legal_alias_particle_id
if exists(select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS where CONSTRAINT_NAME='fk_name_use_name_particle_id')
    alter table names drop constraint fk_name_use_name_particle_id

if exists(select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS where CONSTRAINT_NAME='fk_particles_particle_locale_id')
    alter table particles drop constraint fk_particles_particle_locale_id

if exists(select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS where CONSTRAINT_NAME='fk_particle_orders_particle_order_name_id')
    alter table particle_orders drop constraint fk_particle_orders_particle_order_name_id
if exists(select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS where CONSTRAINT_NAME='fk_particle_orders_particle_order_particle_id')
    alter table particle_orders drop constraint fk_particle_orders_particle_order_particle_id
if exists(select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS where CONSTRAINT_NAME='fk_particle_orders_particle_order_locale_id')
    alter table particle_orders drop constraint fk_particle_orders_particle_order_locale_id
drop function if exists get_particle_type_id
drop table if exists particle_types
drop table if exists particle_orders
drop function if exists get_particle_id_by_latin
drop function if exists get_particle_id
drop table if exists particles
drop table if exists honorifics
drop function if exists get_locale_id
drop table if exists locales
drop table if exists names 
drop table if exists persons
drop function if exists get_particle_type_id
drop function if exists get_particle_id
drop function if exists get_particle_id_by_latin
drop function if exists get_particle_id_by_ipa
drop function if exists get_person_id
drop procedure if exists insert_piggy
GO

--UP Metadata
create table persons (
    person_id int IDENTITY not null,
    person_email_address varchar(50),
    constraint pk_persons_person_id primary key(person_id)
)

create table names (
    name_id int IDENTITY not null,
    name_locale_id int not null,
    name_is_legal_name bit not null,
    name_is_dead_name bit not null,
    name_preferred_locale_id int,
    name_gender_identity varchar(10),
    name_preferred_honorific_id int,
    name_preferred_pronoun_nominative varchar(50),
    name_preferred_pronoun_genative varchar(50),
    name_override_full_name nvarchar(max),
    name_override_full_name_latin1 varchar(max),
    name_override_full_name_ipa nvarchar(max),
    name_given_name_particle_id int not null,
    name_family_name_particle_id int,
    name_tribe_or_clan_particle_id int,
    name_legal_alias_particle_id int,
    name_use_name_particle_id int,
    name_person_id int not null,
    name_mother_person_id int,
    name_father_person_id int,
    constraint pk_names_name_id primary key (name_id)
)

create table locales (
    locale_id int IDENTITY not null,
    locale_language varchar(4) not null,
    locale_country varchar(4) not null,
    constraint pk_locale_locale_id primary key (locale_id),
    constraint u_locale_language_country unique (locale_language, locale_country)
)

create table honorifics (
    honorific_id int IDENTITY not null,
    honorific_text nvarchar(50) not null,
    honorific_latin1 varchar(50),
    honorific_ipa nvarchar(50),
    honorific_is_prefix bit not null,
    honorific_locale_id int not null,
    constraint pk_honorifics_honorific_id primary key (honorific_id),
    constraint u_honorifics_honorific_text unique (honorific_text),
    constraint u_honorifics_honorific_locale_id unique (honorific_locale_id)
)

create table particles (
    particle_id int IDENTITY not null,
    particle_type_id int not null,
    particle_unicode nvarchar(50) not null,
    particle_latin1 varchar(50),
    particle_ipa nvarchar(50),
    particle_locale_id int not null,
    constraint pk_particles_particle_id primary key (particle_id)
)

create table particle_orders (
    particle_order_id int IDENTITY not null,
    particle_order_name_id int not null,
    particle_order_particle_id int not null,
    particle_order_order int not null,
    particle_order_locale_id int not null,
    constraint pk_particle_orders_particle_order_id primary key (particle_order_id)
)

create table particle_types (
    particle_type_id int IDENTITY not null,
    particle_type_type varchar(50),
    constraint pk_particle_types_particle_type_id primary key (particle_type_id)
)

--UP Data
alter table NAMES 
add constraint fk_name_person_id foreign key (name_person_id) references persons(person_id)
alter table NAMES
add constraint fk_name_locale_id foreign key (name_locale_id) references locales(locale_id)
alter table NAMES
add constraint fk_name_mother_person_id foreign key (name_mother_person_id) references persons(person_id)
alter table NAMES
add constraint fk_name_father_person_id foreign key (name_father_person_id) references persons(person_id)
alter table NAMES
add constraint fk_name__preferred_honorific_id foreign key (name_preferred_honorific_id) references honorifics(honorific_id)
alter table NAMES
add constraint fk_name_given_name_particle_id foreign key (name_given_name_particle_id) references particles(particle_id)
alter table NAMES
add constraint fk_name_family_name_particle_id foreign key (name_family_name_particle_id) references particles(particle_id)
alter table NAMES
add constraint fk_name_tribe_or_clan_particle_id foreign key (name_tribe_or_clan_particle_id) references particles(particle_id)
alter table NAMES
add constraint fk_name_legal_alias_particle_id foreign key (name_legal_alias_particle_id) references particles(particle_id)
alter table NAMES
add constraint fk_name_use_name_particle_id foreign key (name_use_name_particle_id) references particles(particle_id)

alter table particles
add constraint fk_particles_particle_locale_id foreign key (particle_locale_id) references locales(locale_id)


alter table particle_orders
add constraint fk_particle_orders_particle_order_particle_id foreign key (particle_order_particle_id) references particles(particle_id)
alter table particle_orders
add constraint fk_particle_orders_particle_order_locale_id foreign key (particle_order_locale_id) references locales(locale_id)
alter table particle_orders
add constraint fk_particle_orders_particle_order_name_id foreign key (particle_order_name_id) references names(name_id)

-- Initial Data

insert into locales (locale_language, locale_country)
values
('eng', 'us'),
('kat', 'ge');

go
create function get_locale_id (@language varchar(4), @country varchar(4))
returns int
begin
    declare @locale_id int;
    select @locale_id = l.locale_id
        from locales as l
        where l.locale_language = @language and l.locale_country = @country;
    return @locale_id;
end;

go

insert into particle_types (particle_type_type)
values
('Given'),
('Family'),
('Nickname'),
('Legal Alias'),
('Tribe'),
('Clan'),
('Prefix Title '),
('Suffix'),
('Suffix Title');

go
create function get_particle_type_id (@type varchar(50))
returns int
begin
    declare @particle_type_id int;
    select @particle_type_id = l.particle_type_id
        from particle_types as l
        where l.particle_type_type = @type;
    return @particle_type_id;
end;

go


insert into particles (particle_locale_id, particle_type_id, particle_unicode, particle_latin1, particle_ipa)
values
(
    dbo.get_locale_id('eng', 'us'),
    dbo.get_particle_type_id('Given'),
    'La Monte', NULL, 'lɑː ˈmɒnt'
),
(
    dbo.get_locale_id('eng', 'us'),
    dbo.get_particle_type_id('Given'),
    'Henry', NULL, 'ˈhɛnri' 
),
(
    dbo.get_locale_id('eng', 'us'),
    dbo.get_particle_type_id('Given'),
    'Piggy', NULL, 'ˈpɪɡi'
),
(
    dbo.get_locale_id('eng', 'us'),
    dbo.get_particle_type_id('Family'),
    'Yarroll', NULL, 'jərəʊl'
),
(
    dbo.get_locale_id('eng', 'us'),
    dbo.get_particle_type_id('Prefix Title'),
    'Dr.', NULL, 'dɑktɚ'
),
(
    dbo.get_locale_id('eng', 'us'),
    dbo.get_particle_type_id('Suffix Title'),
    'esq.', NULL, '[ɪˈskwaɪə'
),
(
    dbo.get_locale_id('kat', 'ge'),
    dbo.get_particle_type_id('Given'),
    'ლამონტი', 'lamonti', 'laˈmɒnti'
),
(
    dbo.get_locale_id('kat', 'ge'),
    dbo.get_particle_type_id('Given'),
    'ჰენრი', 'henri', 'ˈhenri' 
),
(
    dbo.get_locale_id('kat', 'ge'),
    dbo.get_particle_type_id('Given'),
    'პიგი', 'pigi', 'ˈpiɡi'
),
(
    dbo.get_locale_id('kat', 'ge'),
    dbo.get_particle_type_id('Family'),
    'იაროლი', 'iaroli', 'iaroli'
);

go

create function get_particle_id (@locale_id int, @particle_type_id int, @unicode varchar(50))
returns int
begin
    declare @particle_id int;
    select @particle_id = p.particle_id
        from particles as p
        where p.particle_locale_id = @locale_id
            and p.particle_type_id = @particle_type_id
            and p.particle_unicode = @unicode;
    return @particle_id;
end;

go

create function get_particle_id_by_latin (@locale_id int, @particle_type_id int, @latin1 varchar(50))
returns int
begin
    declare @particle_id int;
    select @particle_id = p.particle_id
        from particles as p
        where p.particle_locale_id = @locale_id
            and p.particle_type_id = @particle_type_id
            and p.particle_latin1 = @latin1;
    return @particle_id;
end;
GO
create function get_person_id(@email varchar(50))
returns INT
begin
    declare @person_id int;
    select @person_id = p.person_id
        from persons as p
        where p.person_email = @email;
    return @person_id;
end;
GO

-- La Monte H.P. Yarroll -- eng-us
drop procedure if exists insert_piggy;
GO
create procedure insert_piggy
AS
BEGIN
    declare @eng_us int;
    declare @person_id int;
    declare @name_id int;

    insert into persons (person_email)
    values ('piggy@cmu.edu');
    set @person_id = @@identity;

    set @eng_us = dbo.get_locale_id('eng', 'us');

    insert into names (
        name_locale_id,
        name_is_legal_name, name_is_dead_name, name_gender_identity,
        name_given_name_particle_id,
        name_family_name_particle_id,
        name_use_name_particle_id,
        name_person_id)
    values (
        dbo.get_locale_id('eng', 'us'),
        'TRUE', 'FALSE', 'male',
        dbo.get_particle_id(@eng_us, dbo.get_particle_type_id('Given'), 'La Monte'),
        dbo.get_particle_id(@eng_us, dbo.get_particle_type_id('Family'), 'Yarroll'),
        dbo.get_particle_id(@eng_us, dbo.get_particle_type_id('Given'), 'Piggy'),
        dbo.get_person_id('piggy@cmu.edu')
    );
    set @name_id = @@identity;

    insert into particle_orders (
        particle_order_order, particle_order_locale_id, particle_order_name_id, particle_order_particle_id)
    values
        (1, @eng_us, @name_id, dbo.get_particle_id(@eng_us, dbo.get_particle_type_id('Prefix Title'), 'Dr.')),
        (2, @eng_us, @name_id, dbo.get_particle_id(@eng_us, dbo.get_particle_type_id('Given'), 'La Monte')),
        (3, @eng_us, @name_id, dbo.get_particle_id(@eng_us, dbo.get_particle_type_id('Given'), 'Henry')),
        (4, @eng_us, @name_id, dbo.get_particle_id(@eng_us, dbo.get_particle_type_id('Given'), 'Piggy')),
        (5, @eng_us, @name_id, dbo.get_particle_id(@eng_us, dbo.get_particle_type_id('Family'), 'Yarroll')),
        (6, @eng_us, @name_id, dbo.get_particle_id(@eng_us, dbo.get_particle_type_id('Suffix Title'), 'esq.'));
END
go
declare @eng_us int = 1;
declare @name_id int = 1;
select         1, @eng_us, @name_id, dbo.get_particle_id(@eng_us, dbo.get_particle_type_id('Title Prefix'), 'Dr.');

GO
exec dbo.insert_piggy;
GO
--Verify

select dbo.get_locale_id('eng', 'us') as eng_us_locale;
select dbo.get_particle_type_id('Family') as family_particle_type;
select dbo.get_particle_id(
    dbo.get_locale_id('eng', 'us'),
    dbo.get_particle_type_id('Given'),
    'La Monte'
) as la_monte_given;
select dbo.get_particle_id_by_latin(
    dbo.get_locale_id('kat', 'ge'),
    dbo.get_particle_type_id('Given'),
    'lamonti'
) as la_monte_given_kat;
