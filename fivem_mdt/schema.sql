CREATE TABLE IF NOT EXISTS mdt_profiles (
    citizenid VARCHAR(64) PRIMARY KEY,
    callsign VARCHAR(32) DEFAULT NULL,
    rank_title VARCHAR(64) DEFAULT NULL,
    badge_image_url TEXT,
    profile_image_url TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS mdt_warrants (
    id INT AUTO_INCREMENT PRIMARY KEY,
    suspect_name VARCHAR(128) NOT NULL,
    suspect_cid VARCHAR(64) DEFAULT NULL,
    charges LONGTEXT,
    notes TEXT,
    created_by VARCHAR(128) NOT NULL,
    status VARCHAR(16) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS mdt_bolos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(128) NOT NULL,
    notes TEXT,
    vehicle_plate VARCHAR(16) DEFAULT NULL,
    status VARCHAR(16) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS mdt_suspects (
    id INT AUTO_INCREMENT PRIMARY KEY,
    suspect_cid VARCHAR(64) NOT NULL UNIQUE,
    first_name VARCHAR(64) DEFAULT NULL,
    last_name VARCHAR(64) DEFAULT NULL,
    dob VARCHAR(32) DEFAULT NULL,
    photo_url TEXT,
    fingerprint_url TEXT,
    dna_profile VARCHAR(128) DEFAULT NULL,
    phone VARCHAR(32) DEFAULT NULL,
    address VARCHAR(255) DEFAULT NULL,
    parole_status VARCHAR(32) DEFAULT 'none',
    risk_level VARCHAR(32) DEFAULT 'low',
    notes TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS ems_cases (
    id INT AUTO_INCREMENT PRIMARY KEY,
    patient_cid VARCHAR(64) NOT NULL,
    summary TEXT,
    injury_type VARCHAR(64),
    treatment TEXT,
    severity VARCHAR(32),
    created_by VARCHAR(128) NOT NULL,
    status VARCHAR(16) NOT NULL DEFAULT 'open',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
