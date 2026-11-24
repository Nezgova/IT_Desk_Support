-- Donnees DEMO pour une base ITDesk NEUVE, apres ITDesk_MySQL.sql.
-- Tous les comptes de demonstration ont le mot de passe Demo@2026!
-- Le champ contient son HASH BCrypt, jamais le mot de passe en clair.
-- NE PAS reutiliser ces identifiants en production.
USE itdesk;

INSERT INTO utilisateur (id, nom, prenom, email, mot_de_passe, role) VALUES
 (1, 'Benali', 'Sara', 'sara.benali@example.test', '$2y$10$1iPVKBJU8sOiYPq5v42p8Og5bz2c2c4P1vL8uYSxTrZdmFOzWxjAG', 'EMPLOYE'),
 (2, 'Amrani', 'Omar', 'omar.amrani@example.test', '$2y$10$1iPVKBJU8sOiYPq5v42p8Og5bz2c2c4P1vL8uYSxTrZdmFOzWxjAG', 'EMPLOYE'),
 (3, 'El Fassi', 'Youssef', 'youssef.elfassi@example.test', '$2y$10$1iPVKBJU8sOiYPq5v42p8Og5bz2c2c4P1vL8uYSxTrZdmFOzWxjAG', 'TECHNICIEN'),
 (4, 'Idrissi', 'Nadia', 'nadia.idrissi@example.test', '$2y$10$1iPVKBJU8sOiYPq5v42p8Og5bz2c2c4P1vL8uYSxTrZdmFOzWxjAG', 'RESPONSABLE'),
 (5, 'Berrada', 'Salma', 'salma.berrada@example.test', '$2y$10$1iPVKBJU8sOiYPq5v42p8Og5bz2c2c4P1vL8uYSxTrZdmFOzWxjAG', 'ADMIN');

INSERT INTO employe (utilisateur_id, departement) VALUES
 (1, 'Ressources humaines'), (2, 'Comptabilite');
INSERT INTO technicien (utilisateur_id, specialite) VALUES
 (3, 'Reseaux et systemes');
INSERT INTO responsable_it (utilisateur_id) VALUES (4);
INSERT INTO administrateur (utilisateur_id) VALUES (5);

INSERT INTO categorie (id, nom) VALUES
 (1, 'Reseau et VPN'), (2, 'Materiel'), (3, 'Logiciels');
INSERT INTO article_connaissance (id, titre, contenu, categorie_id) VALUES
 (1, 'Verifier une connexion VPN',
  'Controler le reseau, relancer le client VPN et contacter le support si le probleme persiste.', 1),
 (2, 'Redemarrer une imprimante',
  'Verifier le branchement, la file d''attente d''impression et les pilotes.', 2);

INSERT INTO conversation_ia (id, question, reponse, date, employe_id) VALUES
 (1, 'Je ne peux pas me connecter au VPN.',
  'Verifiez votre connexion puis relancez le client VPN. Si cela echoue, creez un ticket.', NOW(), 1);

INSERT INTO ticket (id, titre, description, statut, priorite, date_creation,
                    employe_id, technicien_id, categorie_id, conversation_ia_id) VALUES
 (1, 'Echec de connexion VPN', 'Le probleme persiste apres les conseils de l''assistant.',
  'EN_COURS', 'HAUTE', NOW(), 1, 3, 1, 1),
 (2, 'Imprimante non detectee', 'L''imprimante du service ne repond plus.',
  'NOUVEAU', 'MOYENNE', NOW(), 2, NULL, 2, NULL);

INSERT INTO historique (id, action, date_action, ticket_id) VALUES
 (1, 'Creation depuis la conversation IA', NOW(), 1),
 (2, 'Attribution au technicien Youssef', NOW(), 1);
INSERT INTO note_interne (id, contenu, date_creation, ticket_id, technicien_id) VALUES
 (1, 'Verifier la configuration du serveur VPN.', NOW(), 1, 3);
INSERT INTO message (id, contenu, date_envoi, ticket_id, utilisateur_id) VALUES
 (1, 'Bonjour, le probleme est toujours present.', NOW(), 1, 1),
 (2, 'Je vais verifier les journaux du VPN.', NOW(), 1, 3);
INSERT INTO notification (id, message, lue, utilisateur_id) VALUES
 (1, 'Votre ticket VPN est en cours de traitement.', FALSE, 1),
 (2, 'Un nouveau ticket vous a ete attribue.', FALSE, 3);

-- Verification rapide :
SELECT * FROM v_statistiques_tickets;
SELECT * FROM v_charge_techniciens;
SELECT t.id, t.titre, t.statut, u.email AS createur, c.nom AS categorie
FROM ticket AS t
JOIN employe AS e ON e.utilisateur_id = t.employe_id
JOIN utilisateur AS u ON u.id = e.utilisateur_id
JOIN categorie AS c ON c.id = t.categorie_id;
