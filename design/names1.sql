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
if exists(select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS where CONSTRAINT_NAME='fk_particle_orders_particle_order_locale')
    alter table particle_orders drop constraint fk_particle_orders_particle_order_locale
drop table if exists persons
drop table if exists names 
drop table if exists locale
drop table if exists honorifics
drop table if exists particles
drop table if exists particle_orders
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
    name_preferred_locale varchar(50),
    name_gender_identity bit,
    name_preferred_honorific_id int,
    name_preferred_pronoun_nominative varchar(50),
    name_preferred_pronoun_genative varchar(50),
    name_override_full_name varchar(50),
    name_override_full_name_latin1 varchar(50),
    name_override_full_name_ipa varchar(50),
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

create table locale (
    locale_id int IDENTITY not null,
    language varchar(50) not null,
    country varchar(50) not null,
    constraint pk_locale_locale_id primary key (locale_id),
    constraint u_locale_language unique (language),
    constraint u_locale_country unique (country)
)

create table honorifics (
    honorific_id int IDENTITY not null,
    honorific_text varchar(50) not null,
    honorific_latin1 varchar(50),
    honorific_ipa varchar(50),
    honorific_is_prefix bit not null,
    honorific_locale_id int not null,
    constraint pk_honorifics_honorific_id primary key (honorific_id),
    constraint u_honorifics_honorific_text unique (honorific_text),
    constraint u_honorifics_honorific_locale_id unique (honorific_locale_id)
)

create table particles (
    particle_id int IDENTITY not null,
    particle_type varchar(50) not null,
    particle_unicode int not null,
    particle_latin1 varchar(50),
    particle_ipa varchar(50),
    particle_locale int,
    constraint pk_particles_particle_id primary key (particle_id)
)

create table particle_orders (
    particle_order_id int IDENTITY not null,
    particle_order_name_id int not null,
    particle_order_particle_id int not null,
    particle_order_order int not null,
    particle_order_locale int not null
    constraint pk_particle_orders_particle_order_id primary key (particle_order_id)
)

--UP Data
alter table NAMES 
add constraint fk_name_person_id foreign key (name_person_id) references persons(person_id)
alter table NAMES
add constraint fk_name_locale_id foreign key (name_locale_id) references locale(locale_id)
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
add constraint fk_particles_particle_locale_id foreign key (particle_locale) references locale(locale_id)


alter table particle_orders
add constraint fk_particle_orders_particle_order_particle_id foreign key (particle_order_particle_id) references particles(particle_id)
alter table particle_orders
add constraint fk_particle_orders_particle_order_locale foreign key (particle_order_locale) references locale(locale_id)
alter table particle_orders
add constraint fk_particle_orders_particle_order_name_id foreign key (particle_order_name_id) references names(name_id)
--Verify

