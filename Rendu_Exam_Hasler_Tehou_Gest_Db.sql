/*1) Créer une table commande
create table commande (
    id_commande serial,
    bookcode varchar(10),
    nb_exemplaire integer,
    prix_unitaire money,
    date_commande date,
    date_reception date,
    annulation boolean
);*/
create table commande (
    id_commande serial,
    bookcode varchar(10),
    nb_exemplaire integer,
    prix_unitaire money,
    date_commande date,
    date_reception date,
    annulation boolean,
    constraint pk_commande primary key (id_commande),
    constraint fk_commande_bookcode foreign key (bookcode) references livre(bookcode)
);

-- Resultat de la commande :
/*
    biblio_exam=# create table commande (
    id_commande serial,
    bookcode varchar(10),
    nb_exemplaire integer,
    prix_unitaire money,
    date_commande date,
    date_reception date,
    annulation boolean,
    constraint pk_commande primary key (id_commande),
    constraint fk_commande_bookcode foreign key (bookcode) references livre(bookcode)
);
CREATE TABLE
biblio_exam=# \dt
             List of relations
 Schema |    Name    | Type  |    Owner
--------+------------+-------+-------------
 public | adresse    | table | postgres
 public | auteur     | table | kuassitehou
 public | bateau     | table | postgres
 public | client     | table | postgres
 public | commande   | table | kuassitehou
 public | ecrit      | table | kuassitehou
 public | emprunte   | table | kuassitehou
 public | etat       | table | kuassitehou
 public | exemplaire | table | kuassitehou
 public | habite     | table | kuassitehou
 public | livre      | table | kuassitehou
 public | localite   | table | kuassitehou
 public | location   | table | postgres
 public | pays       | table | postgres
 public | type       | table | postgres
 public | ville      | table | postgres
(16 rows)

biblio_exam=# \dt commande
            List of relations
 Schema |   Name   | Type  |    Owner
--------+----------+-------+-------------
 public | commande | table | kuassitehou
(1 row)
*/

-- 2) Créer une fonction affiche_auteur (bookcode varchar(10)) qui retourne les auteurs d'un livre

alter table livre add column id_auteur integer;
alter table auteur add column bookcode varchar(10);

alter table livre add constraint fk_livre_auteur foreign key (id_auteur) references auteur(id_auteur);
alter table auteur add constraint fk_auteur_livre foreign key (bookcode) references livre(bookcode);

insert into auteur values (6, 'Nom_1', 'Prenom_1', 'NP1','', 'IP21510312');
insert into auteur values (7, 'Nom_2', 'Prenom_2', 'NP2','', 'IP21510312');
insert into auteur values (8, 'Nom_3', 'Prenom_3', 'NP3','', 'IP21510312');


insert into livre values ('IP21510313', '000-3-5555-77','Titre_1', 6);
insert into livre values ('IP21510314', '000-3-5555-78','Titre_2', 7);
insert into livre values ('IP21510315', '000-3-5555-79','Titre_3', 8);

-- la fonction qui retourne les auteurs d'un livre
create or replace function affiche_auteur(book_code_param VARCHAR)
returns table (nom varchar, prenom varchar, bookcode varchar, titre varchar)
as $$
begin
    return query
    select auteur.nom, auteur.prenom, auteur.bookcode, livre.titre
    from auteur, livre
    where auteur.bookcode = livre.bookcode and livre.bookcode = book_code_param;
end;
$$ language plpgsql;

-- test de la fonction
select affiche_auteur('IP21510312');

-- Resultat de la fonction :
/*biblio_exam=# select affiche_auteur('IP21510312');
                            affiche_auteur
-----------------------------------------------------------------------
 (Nom_1,Prenom_1,IP21510312,"Java in Two Semesters: Featuring JavaFX")
 (Nom_2,Prenom_2,IP21510312,"Java in Two Semesters: Featuring JavaFX")
 (Nom_3,Prenom_3,IP21510312,"Java in Two Semesters: Featuring JavaFX")
(3 rows)*/

-- 3) Créer une vue 'commandes_en_cours' qui permet d'afficher la liste des commandes en cours
--     bookcode, titre, (les auteurs), nb_exemplaire, date_commande
create view commandes_en_cours as
select livre.bookcode, livre.titre, auteur.nom, auteur.prenom, commande.nb_exemplaire, commande.date_commande
from livre, auteur, commande
where livre.bookcode = commande.bookcode and auteur.bookcode = livre.bookcode and commande.annulation = true;

-- test de la vue
select * from commandes_en_cours;

-- supprimer la vue
drop view commandes_en_cours;

-- Resultat de la vue :
/*biblio_exam=# select * from commandes_en_cours;
 bookcode | titre | nom | prenom | nb_exemplaire | date_commande
----------+-------+-----+--------+---------------+---------------
(0 rows)*/

-- 4) Créer une procédure 'annulation_commande(id int)' qui annule une commande de livres_en_pret
create or replace procedure annulation_commande (id int)
as $$
begin
    update commande
    set annulation = true
    where id_commande = id;
    raise notice 'Commande annulée';
end;
$$ language plpgsql;

-- test de la procédure
call annulation_commande(2);

-- Resultat de la procédure :
/*biblio_exam=# call annulation_commande(2);
NOTICE:  Commande annulée
CALL
biblio_exam=# select * from commande;
 id_commande |  bookcode  | nb_exemplaire | prix_unitaire | date_commande | date_reception | annulation
-------------+------------+---------------+---------------+---------------+----------------+------------
           1 | IP21510312 |             2 |        $37.00 | 2024-03-12    | 2024-03-22     | t
           2 | IP21510312 |             2 |        $35.00 | 2024-03-18    | 2024-03-21     | t
(2 rows)
 */

-- 5) Créer une procédure 'reception_commande(id int)' qui indique que la commande a été réceptionnée
create or replace procedure reception_commande (id int)
as $$
begin
    update commande
    set date_reception = current_date + 2 -- test pour juste décaler la date de réception en ajoutant x jours
    where id_commande = id;
    raise notice 'Commande réceptionnée';
end;
$$ language plpgsql;

-- test de la procédure
call reception_commande(2);

-- Resultat de la procédure :
/*biblio_exam=# call reception_commande(2);
NOTICE:  Nouvel exemplaire créé
NOTICE:  Commande réceptionnée
CALL
biblio_exam=# select * from commande;
 id_commande |  bookcode  | nb_exemplaire | prix_unitaire | date_commande | date_reception | annulation
-------------+------------+---------------+---------------+---------------+----------------+------------
           1 | IP21510312 |             2 |        $37.00 | 2024-03-12    | 2024-03-22     | t
           2 | IP21510312 |             2 |        $35.00 | 2024-03-18    | 2024-03-23     | t
(2 rows)
 */


-- 6) Créer un trigger 'after_reception' (chaque record) qui va créer les entrées dans la table exemplaire si la commande a été réceptionnée
create or replace function new_exemplaire()
returns trigger
as $$
begin
    if new.date_reception is not null then
        insert into exemplaire (id_exemplaire, numex, prix, declasse, id_etat, bookcode)
        values (default, (select max(numex) + 1 from exemplaire), new.prix_unitaire, false, 1, new.bookcode);
        raise notice 'Nouvel exemplaire créé';
    end if;
    return new;
end;
$$ language plpgsql;

create trigger after_reception
after update of date_reception
on commande
for each row
execute procedure new_exemplaire();

--test du trigger
update commande
set date_reception = current_date + 2 -- ajouter plus x jour pour que la date de réception soit différente de la date actuelle
where id_commande = 1;

-- Resultat du trigger :
/*biblio_exam=# update commande
set date_reception = current_date + 2 -- ajouter plus x jour pour que la date de réception soit différente de la date actuelle
where id_commande = 1;
NOTICE:  Nouvel exemplaire créé
UPDATE 1
biblio_exam=# select * from commande;
 id_commande |  bookcode  | nb_exemplaire | prix_unitaire | date_commande | date_reception | annulation
-------------+------------+---------------+---------------+---------------+----------------+------------
           2 | IP21510312 |             2 |        $35.00 | 2024-03-18    | 2024-03-23     | t
           1 | IP21510312 |             2 |        $37.00 | 2024-03-12    | 2024-03-23     | t
(2 rows)
 */

-- 7) Créer un trigger 'before_commande' (une fois par INSERT) qui va afficher les commandes en cours avant d'en créer une nouvelle
create or replace function affiche_commandes_en_cours()
returns trigger
as $$
begin
    /*raise notice 'Commandes en cours :';
    for cmd in select * from commandes_en_cours loop
        raise notice 'Bookcode : %, Titre : %, Auteur : %, Nb exemplaire : %, Date commande : %', cmd.bookcode, cmd.titre, cmd.nom, cmd.nb_exemplaire, cmd.date_commande;
    end loop;
    return new;*/
end;
$$ language plpgsql;

create trigger before_commande
before insert
on commande
for each row
execute procedure affiche_commandes_en_cours();

-- test du trigger
insert into commande values (default, 'IP21510312', 2, 37, '2024-03-12',null,true);

-- Resultat du trigger :
/*Aucune proposition de résultat
 */

-- 8) Créer un trigger 'before_new_exemplaire' qui s'assurera que le numéro d'exemplaire d'un nouvel exemplaire est bien séquentiel (numéro suivant)
create or replace function check_numex()
returns trigger
as $$
begin
    if new.numex != (select max(numex) + 1 from exemplaire) then -- il va sélectionner le numex le plus grand + 1 pour vérifier si le nouveau numex est bien séquentiel
        raise exception 'Le numéro d''exemplaire doit être séquentiel';
        else
        raise notice 'Nouvel exemplaire créé';
    end if;
    return new;
end;
$$ language plpgsql;

create trigger before_new_exemplaire
before insert
on exemplaire
for each row
execute procedure check_numex();

-- test du trigger avec des numéros d'exemplaires séquentiels
insert into exemplaire (id_exemplaire, numex, prix, declasse, id_etat, bookcode)
values (default, 17, 37, false, 1, 'IP21510312');

insert into exemplaire (id_exemplaire, numex, prix, declasse, id_etat, bookcode)
values (default, 18, 37, false, 1, 'IP21510312');

insert into exemplaire (id_exemplaire, numex, prix, declasse, id_etat, bookcode)
values (default, 19, 37, false, 1, 'IP21510312');

-- test du trigger avec des numéros d'exemplaires non séquentiels

insert into exemplaire (id_exemplaire, numex, prix, declasse, id_etat, bookcode)
values (default, 100, 37, false, 1, 'IP21510312');

insert into exemplaire (id_exemplaire, numex, prix, declasse, id_etat, bookcode)
values (default, 200, 37, false, 1, 'IP21510312');

-- Proposition de résultat :
/*biblio_exam=# insert into exemplaire (id_exemplaire, numex, prix, declasse, id_etat, bookcode)
values (default, 17, 37, false, 1, 'IP21510312');
ERROR:  Le numéro d'exemplaire doit être séquentiel
CONTEXT:  PL/pgSQL function check_numex() line 4 at RAISE
biblio_exam=# insert into exemplaire (id_exemplaire, numex, prix, declasse, id_etat, bookcode)
values (default, 100, 37, false, 1, 'IP21510312');
ERROR:  Le numéro d'exemplaire doit être séquentiel
CONTEXT:  PL/pgSQL function check_numex() line 4 at RAISE
 */












