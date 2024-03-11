-- Quelques requêtes SQL pour tester les données

select * from client;
select * from adresse;
select * from localite;
select * from exemplaire;
select * from livre;
select * from etat;
select * from emprunte;
select * from auteur;
select * from ecrit;
select * from pays;
select * from habite;
select * from ville;
select * from location;

-- 1. Créer une vue 'livres_en_pret' qui affiche titre, bookcode, numex, date_emprunt, nom, prenom

-- Création de la vue 'livres_en_pret'

CREATE VIEW livres_en_pret AS
SELECT titre, exemplaire.bookcode, numex, date_emprunt, nom, prenom
FROM emprunte
JOIN
    client ON emprunte.id_client = client.id_client
JOIN
    exemplaire ON emprunte.id_exemplaire = exemplaire.id_exemplaire
JOIN
    livre ON exemplaire.bookcode = livre.bookcode;

-- Exécution de la vue 'livres_en_pret'
SELECT * FROM livres_en_pret;

-- 2. Créer une vue 'liste_tous_les_emprunts' qui affiche
-- titre, bookcode, numex, date_emprunt, date_retour, etat_emprunt, etat_retour, nom, prenom

-- Création de la vue 'liste_tous_les_emprunts'

CREATE VIEW liste_tous_les_emprunts AS
SELECT titre, exemplaire.bookcode, numex, date_emprunt, date_retour, etat_emprunt, etat_retour, nom, prenom
FROM emprunte
JOIN
    client ON emprunte.id_client = client.id_client
JOIN
    exemplaire ON emprunte.id_exemplaire = exemplaire.id_exemplaire
JOIN
    livre ON exemplaire.bookcode = livre.bookcode;

-- Exécution de la vue 'liste_tous_les_emprunts'
SELECT * FROM liste_tous_les_emprunts;

-- 3. Créer une procédure 'ajout_exemplaire' qui permet d'ajouter un exemplaire d'un livre (si le livre n'existe pas il faut le créer avant d'ajouter un exemplaire)

-- Création de la procédure 'ajout_exemplaire'

CREATE OR REPLACE PROCEDURE ajout_exemplaire(
    IN pcd_numex integer,
    IN pcd_prix money,
    IN pcd_declasse boolean,
    IN pcd_id_etat integer,
    IN pcd_bookcode varchar(10),
    IN pcd_isbn varchar(13),
    IN pcd_titre varchar(100)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT * FROM livre WHERE bookcode = pcd_bookcode) THEN
        INSERT INTO livre(bookcode, isbn, titre) VALUES (pcd_bookcode, pcd_isbn, pcd_titre);
        RAISE NOTICE 'Livre ajouté';
        INSERT INTO exemplaire(numex, prix, declasse, id_etat, bookcode) VALUES (pcd_numex, pcd_prix, pcd_declasse, pcd_id_etat, pcd_bookcode);
        RAISE NOTICE 'Exemplaire ajouté';
    ELSE
        RAISE EXCEPTION 'Le livre existe déjà';
    END IF;
    COMMIT;
END;
$$;

-- Exécution de la procédure 'ajout_exemplaire'
CALL ajout_exemplaire(3, '15.99'::money, false, 1, 'MP25014554'::varchar(10), '978-2-1234-5680-3'::varchar(13), 'Le Seigneur des Anneaux'::varchar(100));
CALL ajout_exemplaire(4, '50.99'::money, true, 2, 'IX25014664'::varchar(10), '978-6-1234-5680-1'::varchar(13), 'Dutch for Dummies'::varchar(100));
CALL ajout_exemplaire(5, '70.99'::money, false, 3, 'QQ25014554'::varchar(10), '978-9-1234-5680-6'::varchar(13), 'La Wallonie en 1000 questions'::varchar(100));
CALL ajout_exemplaire(6, '25.99'::money, false, 1, 'MX30004554'::varchar(10), '999-2-222-5555-3'::varchar(13), 'La Belgique en 1000 questions'::varchar(100));

-- 4. Créer une procédure 'ajout_livre' qui permet d'ajouter un livre (vérifier s'il n'existe pas)

-- Création de la procédure 'ajout_livre'

CREATE OR REPLACE PROCEDURE ajout_livre(
    IN pcd_bookcode varchar(10),
    IN pcd_isbn varchar(13),
    IN pcd_titre varchar(100)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT * FROM livre WHERE bookcode = pcd_bookcode) THEN
        INSERT INTO livre(bookcode, isbn, titre) VALUES (pcd_bookcode, pcd_isbn, pcd_titre);
        RAISE NOTICE 'Livre ajouté';
    ELSE
        RAISE EXCEPTION 'Le livre existe déjà';
    END IF;
    COMMIT;
END;
$$;

-- Exécution de la procédure 'ajout_livre'
CALL ajout_livre('MP25014554'::varchar(10), '978-2-1234-5680-3'::varchar(13), 'Le Seigneur des Anneaux'::varchar(100));
CALL ajout_livre('IX25014664'::varchar(10), '978-6-1234-5680-1'::varchar(13), 'Dutch for Dummies'::varchar(100));
CALL ajout_livre('QQ25014554'::varchar(10), '978-9-1234-5680-6'::varchar(13), 'La Wallonie en 1000 questions'::varchar(100));

CALL ajout_livre('XX00004554'::varchar(10), '333-2-4444-6666-0'::varchar(13), 'Bruxelles et ses mystères'::varchar(100));

-- 5. Créer une fonction 'derniere_adresse' pour un client; la fonction retourne
-- nom, prenom, libelle, numero, cp, ville

-- Création de la fonction 'derniere_adresse'

CREATE OR REPLACE FUNCTION derniere_adresse()
RETURNS TABLE (nom varchar, prenom varchar, libelle varchar, numero varchar, cp integer, ville varchar)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT c.nom, c.prenom,
           (SELECT a.libelle
            FROM adresse a
            WHERE a.id_adresse = h.id_adresse) AS libelle,
           (SELECT a.numero
            FROM adresse a
            WHERE a.id_adresse = h.id_adresse) AS numero,
           (SELECT l.cp
            FROM localite l
            WHERE l.id_localite =
                  (SELECT a.id_localite
                   FROM adresse a
                   WHERE a.id_adresse = h.id_adresse)) AS cp,
           (SELECT l.ville
            FROM localite l
            WHERE l.id_localite =
                  (SELECT a.id_localite
                   FROM adresse a
                   WHERE a.id_adresse = h.id_adresse)) AS ville
    FROM client c
    JOIN habite h ON c.id_client = h.id_client
    WHERE NOT EXISTS (
        SELECT *
        FROM habite h2
        WHERE h2.id_client = c.id_client
          AND h2.datemodif > h.datemodif
    );
END;
$$;

-- Exécution de la fonction 'derniere_adresse'
SELECT * FROM derniere_adresse();

--6. Créer une fonction 'calcul_prix_emprunt' qui retourne le prix à payer
-- formule = (date retour - date emprunt + 1)  *  2 * ratio etat exemplaire date emprunt + 1 euro pénalité si état retour est moins bon que état emprunt

-- Création de la fonction 'calcul_prix_emprunt'

CREATE OR REPLACE FUNCTION calcul_prix_emprunt()
RETURNS TABLE (id_emprunte integer, date_emprunt date, date_retour date, prix_emprunt money)
LANGUAGE plpgsql
AS $$
DECLARE
    x_id_emprunte integer;
    x_date_emprunt date;
    x_date_retour date;
    x_prix_emprunt money;
BEGIN
    FOR x_id_emprunte, x_date_emprunt, x_date_retour IN
        SELECT e.id_emprunte, e.date_emprunt, e.date_retour
        FROM emprunte e
    LOOP
        x_prix_emprunt := ((x_date_retour - x_date_emprunt + 1) * 2 *
                            (SELECT ratio FROM etat WHERE id_etat = (SELECT etat_emprunt FROM emprunte WHERE emprunte.id_emprunte = x_id_emprunte))) +
                            CASE
                                WHEN
                                    (SELECT etat_retour FROM emprunte e2 WHERE e2.id_emprunte = x_id_emprunte) <
                                      (SELECT etat_emprunt FROM emprunte e3 WHERE e3.id_emprunte = x_id_emprunte)
                                 THEN 1 ELSE 0 END;
        RETURN QUERY SELECT x_id_emprunte, x_date_emprunt, x_date_retour, x_prix_emprunt;
    END LOOP;
END;
$$;

-- Exécution de la fonction 'calcul_prix_emprunt' qui retourne le prix à payer
SELECT * FROM calcul_prix_emprunt();


-- 7. Créer un trigger 'before_emprunt'

-- Création du trigger 'before_emprunt'

CREATE OR REPLACE FUNCTION before_emprunt()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT *
        FROM exemplaire
        WHERE id_exemplaire = NEW.id_exemplaire
          AND id_etat = 1
    ) THEN
        RAISE EXCEPTION 'Aucun exemplaire disponible pour ce livre';
        ELSE
        RAISE NOTICE 'Exemplaire disponible';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER before_emprunt
BEFORE INSERT ON emprunte
FOR EACH ROW
EXECUTE FUNCTION before_emprunt();

-- Utilisation du trigger 'before_emprunt'
INSERT INTO emprunte(id_client, id_exemplaire, date_emprunt, date_retour, etat_emprunt, etat_retour)
VALUES (1, 1, '2021-01-01', '2021-01-15', 1, 1);

-- 8. Créer un trigger 'after_retour_emprunt'

-- Création du trigger 'after_retour_emprunt'

CREATE OR REPLACE FUNCTION after_retour_emprunt()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.etat_retour < OLD.etat_emprunt THEN
        UPDATE exemplaire
        SET id_etat = 3
        WHERE id_exemplaire = NEW.id_exemplaire;
        RAISE NOTICE 'Exemplaire déclassé';
        ELSE
        RAISE NOTICE 'Exemplaire non déclassé';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER after_retour_emprunt
AFTER UPDATE ON emprunte
FOR EACH ROW
EXECUTE FUNCTION after_retour_emprunt();

-- Utilisation du trigger 'after_retour_emprunt'
UPDATE emprunte
SET etat_retour = 1
WHERE id_emprunte = 2;





