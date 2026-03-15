CREATE TABLE IF NOT EXISTS mdt_accounts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    citizenid VARCHAR(64) NOT NULL UNIQUE,
    username VARCHAR(64) NOT NULL,
    password_hash VARCHAR(64) NOT NULL,
    active TINYINT(1) DEFAULT 1,
    created_by VARCHAR(128) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

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

CREATE TABLE IF NOT EXISTS mdt_charges (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(32) NOT NULL UNIQUE,
    title VARCHAR(128) NOT NULL,
    category VARCHAR(64) DEFAULT 'general',
    class VARCHAR(64) DEFAULT NULL,
    fine INT DEFAULT 0,
    jail_months INT DEFAULT 0,
    points INT DEFAULT 0,
    statute TEXT,
    notes TEXT,
    active TINYINT(1) DEFAULT 1,
    created_by VARCHAR(128) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS mdt_cases (
    id INT AUTO_INCREMENT PRIMARY KEY,
    case_number VARCHAR(32) NOT NULL UNIQUE,
    title VARCHAR(128) NOT NULL,
    case_type VARCHAR(32) NOT NULL DEFAULT 'criminal',
    status VARCHAR(32) NOT NULL DEFAULT 'open',
    priority VARCHAR(16) DEFAULT 'normal',
    summary TEXT,
    suspect_cid VARCHAR(64) DEFAULT NULL,
    officer_cid VARCHAR(64) DEFAULT NULL,
    assigned_unit VARCHAR(64) DEFAULT NULL,
    tags TEXT,
    created_by VARCHAR(128) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS mdt_case_charges (
    id INT AUTO_INCREMENT PRIMARY KEY,
    case_id INT NOT NULL,
    charge_id INT DEFAULT NULL,
    charge_label VARCHAR(128) NOT NULL,
    count INT DEFAULT 1,
    enhancement TEXT,
    FOREIGN KEY (case_id) REFERENCES mdt_cases(id) ON DELETE CASCADE,
    FOREIGN KEY (charge_id) REFERENCES mdt_charges(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS mdt_reports (
    id INT AUTO_INCREMENT PRIMARY KEY,
    case_id INT DEFAULT NULL,
    report_type VARCHAR(32) DEFAULT 'incident',
    title VARCHAR(128) NOT NULL,
    narrative LONGTEXT,
    findings LONGTEXT,
    recommendations LONGTEXT,
    created_by VARCHAR(128) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (case_id) REFERENCES mdt_cases(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS mdt_evidence (
    id INT AUTO_INCREMENT PRIMARY KEY,
    evidence_number VARCHAR(32) NOT NULL UNIQUE,
    case_id INT DEFAULT NULL,
    report_id INT DEFAULT NULL,
    evidence_type VARCHAR(64) NOT NULL,
    title VARCHAR(128) NOT NULL,
    description TEXT,
    file_url TEXT,
    thumb_url TEXT,
    metadata_json LONGTEXT,
    submitted_by VARCHAR(128) NOT NULL,
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (case_id) REFERENCES mdt_cases(id) ON DELETE SET NULL,
    FOREIGN KEY (report_id) REFERENCES mdt_reports(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS mdt_evidence_chain (
    id INT AUTO_INCREMENT PRIMARY KEY,
    evidence_id INT NOT NULL,
    action_type VARCHAR(64) NOT NULL,
    from_holder VARCHAR(128) DEFAULT NULL,
    to_holder VARCHAR(128) DEFAULT NULL,
    notes TEXT,
    action_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (evidence_id) REFERENCES mdt_evidence(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS mdt_physical_evidence (
    id INT AUTO_INCREMENT PRIMARY KEY,
    evidence_id INT NOT NULL,
    locker_code VARCHAR(32) NOT NULL,
    shelf_slot VARCHAR(32) DEFAULT NULL,
    seal_number VARCHAR(64) DEFAULT NULL,
    weight_grams DECIMAL(10,2) DEFAULT NULL,
    condition_note TEXT,
    court_status VARCHAR(32) DEFAULT 'stored',
    released_to VARCHAR(128) DEFAULT NULL,
    release_date DATETIME DEFAULT NULL,
    FOREIGN KEY (evidence_id) REFERENCES mdt_evidence(id) ON DELETE CASCADE
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
