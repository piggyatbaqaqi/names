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
drop table if exists particles
drop table if exists honorifics
drop function if exists get_locale_id
drop table if exists locales
drop table if exists names 
drop table if exists persons
GO

--UP Metadata
create table persons (
    person_id int IDENTITY not null,
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
--Verify

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


-- insert into particles (type_particle_id, particle_unicode, particle_latin1, particle_ipa, particle_locale_id)
-- values ()

select dbo.get_locale_id('eng', 'us') as eng_us_locale_id;
select dbo.get_particle_type_id('Family') as family_particle_type;
