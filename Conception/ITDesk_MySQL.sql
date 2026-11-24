-- ============================================================================
-- ITDesk - Support informatique interne avec assistant IA
-- SCHEMA MySQL 8.0.16+ (InnoDB / utf8mb4)
-- Base sur les diagrammes UML de l'equipe : UML.pdf et use_case.pdf
-- Les 4 sous-classes d'Utilisateur et ConversationIA(question/reponse) sont
-- CONSERVEES a l'identique sur le plan conceptuel.
--
-- ATTENTION : CREATE DATABASE IF NOT EXISTS et CREATE TABLE IF NOT EXISTS
-- ne suppriment pas les donnees preexistantes. Lancer sur une base neuve.
-- Fichier de donnees d'exemple separe : ITDesk_Donnees_Demo.sql
-- ============================================================================

CREATE DATABASE IF NOT EXISTS itdesk
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE itdesk;

-- ENUM UML : Role / identite abstraite de la super-classe Utilisateur.
CREATE TABLE IF NOT EXISTS utilisateur (
    id             INT UNSIGNED NOT NULL AUTO_INCREMENT,
    nom            VARCHAR(100) NOT NULL,
    prenom         VARCHAR(100) NOT NULL,
    email          VARCHAR(190) NOT NULL,
    mot_de_passe   VARCHAR(255) NOT NULL COMMENT 'Hash BCrypt/Argon2id, jamais le mot de passe en clair',
    role           ENUM('EMPLOYE', 'TECHNICIEN', 'RESPONSABLE', 'ADMIN') NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_utilisateur_email (email)
) ENGINE=InnoDB;

-- Heritage UML (mapping JOINED) : PK = FK vers Utilisateur.
CREATE TABLE IF NOT EXISTS employe (
    utilisateur_id INT UNSIGNED NOT NULL,
    departement    VARCHAR(120) NOT NULL,
    PRIMARY KEY (utilisateur_id),
    CONSTRAINT fk_employe_utilisateur
      FOREIGN KEY (utilisateur_id) REFERENCES utilisateur(id)
      ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS technicien (
    utilisateur_id INT UNSIGNED NOT NULL,
    specialite     VARCHAR(120) NOT NULL,
    PRIMARY KEY (utilisateur_id),
    CONSTRAINT fk_technicien_utilisateur
      FOREIGN KEY (utilisateur_id) REFERENCES utilisateur(id)
      ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS responsable_it (
    utilisateur_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (utilisateur_id),
    CONSTRAINT fk_responsable_it_utilisateur
      FOREIGN KEY (utilisateur_id) REFERENCES utilisateur(id)
      ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS administrateur (
    utilisateur_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (utilisateur_id),
    CONSTRAINT fk_administrateur_utilisateur
      FOREIGN KEY (utilisateur_id) REFERENCES utilisateur(id)
      ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS categorie (
    id      INT UNSIGNED NOT NULL AUTO_INCREMENT,
    nom     VARCHAR(150) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_categorie_nom (nom)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS article_connaissance (
    id             INT UNSIGNED NOT NULL AUTO_INCREMENT,
    titre          VARCHAR(255) NOT NULL,
    contenu        TEXT NOT NULL,
    categorie_id   INT UNSIGNED NOT NULL,
    PRIMARY KEY (id),
    KEY idx_article_categorie (categorie_id),
    CONSTRAINT fk_article_categorie
      FOREIGN KEY (categorie_id) REFERENCES categorie(id)
      ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Une conversation = une question et sa reponse (comme dans l'UML original).
CREATE TABLE IF NOT EXISTS conversation_ia (
    id             INT UNSIGNED NOT NULL AUTO_INCREMENT,
    question       TEXT NOT NULL,
    reponse        TEXT NULL,
    date           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    employe_id     INT UNSIGNED NOT NULL,
    PRIMARY KEY (id),
    KEY idx_conversation_employe (employe_id),
    CONSTRAINT fk_conversation_employe
      FOREIGN KEY (employe_id) REFERENCES employe(utilisateur_id)
      ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS ticket (
    id                 INT UNSIGNED NOT NULL AUTO_INCREMENT,
    titre              VARCHAR(255) NOT NULL,
    description        TEXT NOT NULL,
    statut             ENUM('NOUVEAU', 'EN_COURS', 'RESOLU', 'FERME') NOT NULL DEFAULT 'NOUVEAU',
    priorite           ENUM('BASSE', 'MOYENNE', 'HAUTE') NOT NULL DEFAULT 'MOYENNE',
    date_creation      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    employe_id         INT UNSIGNED NOT NULL,
    technicien_id      INT UNSIGNED NULL,
    categorie_id       INT UNSIGNED NOT NULL,
    conversation_ia_id INT UNSIGNED NULL,
    PRIMARY KEY (id),
    KEY idx_ticket_employe (employe_id),
    KEY idx_ticket_technicien (technicien_id),
    KEY idx_ticket_categorie (categorie_id),
    KEY idx_ticket_statut_priorite (statut, priorite),
    UNIQUE KEY uk_ticket_conversation_ia (conversation_ia_id),
    CONSTRAINT fk_ticket_employe
      FOREIGN KEY (employe_id) REFERENCES employe(utilisateur_id)
      ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_ticket_technicien
      FOREIGN KEY (technicien_id) REFERENCES technicien(utilisateur_id)
      ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_ticket_categorie
      FOREIGN KEY (categorie_id) REFERENCES categorie(id)
      ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_ticket_conversation_ia
      FOREIGN KEY (conversation_ia_id) REFERENCES conversation_ia(id)
      ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS historique (
    id           INT UNSIGNED NOT NULL AUTO_INCREMENT,
    action       VARCHAR(255) NOT NULL,
    date_action  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ticket_id    INT UNSIGNED NOT NULL,
    PRIMARY KEY (id),
    KEY idx_historique_ticket_date (ticket_id, date_action),
    CONSTRAINT fk_historique_ticket
      FOREIGN KEY (ticket_id) REFERENCES ticket(id)
      ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS note_interne (
    id             INT UNSIGNED NOT NULL AUTO_INCREMENT,
    contenu        TEXT NOT NULL,
    date_creation  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ticket_id      INT UNSIGNED NOT NULL,
    technicien_id  INT UNSIGNED NOT NULL,
    PRIMARY KEY (id),
    KEY idx_note_ticket (ticket_id),
    KEY idx_note_technicien (technicien_id),
    CONSTRAINT fk_note_ticket
      FOREIGN KEY (ticket_id) REFERENCES ticket(id)
      ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_note_technicien
      FOREIGN KEY (technicien_id) REFERENCES technicien(utilisateur_id)
      ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS message (
    id              INT UNSIGNED NOT NULL AUTO_INCREMENT,
    contenu         TEXT NOT NULL,
    date_envoi      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ticket_id       INT UNSIGNED NOT NULL,
    utilisateur_id  INT UNSIGNED NOT NULL,
    PRIMARY KEY (id),
    KEY idx_message_ticket_date (ticket_id, date_envoi),
    KEY idx_message_auteur (utilisateur_id),
    CONSTRAINT fk_message_ticket
      FOREIGN KEY (ticket_id) REFERENCES ticket(id)
      ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_message_utilisateur
      FOREIGN KEY (utilisateur_id) REFERENCES utilisateur(id)
      ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS notification (
    id              INT UNSIGNED NOT NULL AUTO_INCREMENT,
    message         VARCHAR(500) NOT NULL,
    lue             BOOLEAN NOT NULL DEFAULT FALSE,
    utilisateur_id  INT UNSIGNED NOT NULL,
    PRIMARY KEY (id),
    KEY idx_notification_destinataire (utilisateur_id, lue),
    CONSTRAINT fk_notification_utilisateur
      FOREIGN KEY (utilisateur_id) REFERENCES utilisateur(id)
      ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- Vues de consultation (sans ajouter de nouvelles entites a l'UML).
CREATE OR REPLACE VIEW v_statistiques_tickets AS
SELECT statut, COUNT(*) AS nombre_tickets
FROM ticket
GROUP BY statut;

CREATE OR REPLACE VIEW v_charge_techniciens AS
SELECT tech.utilisateur_id AS technicien_id,
       CONCAT(u.prenom, ' ', u.nom) AS nom_technicien,
       COUNT(t.id) AS nombre_tickets
FROM technicien AS tech
JOIN utilisateur AS u ON u.id = tech.utilisateur_id
LEFT JOIN ticket AS t ON t.technicien_id = tech.utilisateur_id
GROUP BY tech.utilisateur_id, u.prenom, u.nom;

-- Notes importantes :
-- 1. Les tables de sous-classes preservent l'heritage JOINED. L'application
--    verifie la correspondance entre utilisateur.role et la table fille,
--    ainsi que l'unicite de la specialisation (pas de trigger ici).
-- 2. Consultation des articles par l'IA : dependance applicative de l'UML ;
--    aucune FK conversation_ia -> article_connaissance n'est ajoutee.
-- 3. Authentification, droits et transitions de statut : regles des services
--    Java / Jakarta EE ; elles ne se reduisent pas a une contrainte SQL.
-- 4. Les suppressions de comptes/tickets lies a des donnees historiques
--    peuvent etre refusees volontairement par ON DELETE RESTRICT.
