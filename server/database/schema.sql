-- ---------------------------------------------------------------------------
-- Bitirim Stranger — database schema
-- ---------------------------------------------------------------------------
-- The resource auto-creates this table on start (server/modules/identity.lua),
-- so importing this file manually is OPTIONAL. It is provided for DBAs who
-- prefer explicit migrations.
--
-- Relationship semantics:
--   owner_citizenid  learned  known_citizenid's identity.
--   This is one-directional: owner seeing known does NOT reveal owner to known.
-- ---------------------------------------------------------------------------

-- Permanent player numbers.
-- Rows are NEVER deleted: a removed character is soft-deleted via deleted_at so
-- its number stays claimed, and AUTO_INCREMENT never reissues a value. Deleting
-- character #3 therefore leaves 3 retired and hands #4 to the next character.
CREATE TABLE IF NOT EXISTS `bitirim_player_ids` (
    `number`     INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `citizenid`  VARCHAR(64) NOT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`number`),
    UNIQUE KEY `uniq_citizenid` (`citizenid`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `bitirim_known_identities` (
    `id`               INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `owner_citizenid`  VARCHAR(64) NOT NULL,
    `known_citizenid`  VARCHAR(64) NOT NULL,
    `created_at`       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_owner_known` (`owner_citizenid`, `known_citizenid`),
    KEY `idx_owner` (`owner_citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
