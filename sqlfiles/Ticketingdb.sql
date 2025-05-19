show databases;

create database ticketingdb;
show tables;
use ticketingdb;

-- -----------------------------
-- 🔧 DEPARTMENTS
-- -----------------------------
CREATE TABLE sd_departments (
    department_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) UNIQUE NOT NULL
);

-- -----------------------------
-- 👥 USERS
-- -----------------------------
CREATE TABLE sd_users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    department_id INT,
    FOREIGN KEY (department_id) REFERENCES sd_departments(department_id)
);

-- -----------------------------
-- 📂 CATEGORIES (Change Categories)
-- -----------------------------
CREATE TABLE sd_categories (
    category_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) UNIQUE NOT NULL
);

-- -----------------------------
-- 🗂️ CHANGE CATEGORIES (Normalized)
-- -----------------------------
CREATE TABLE sd_change_categories (
    category_id INT PRIMARY KEY AUTO_INCREMENT,
    category_name VARCHAR(100) UNIQUE NOT NULL
);

-- -----------------------------
-- 🔄 CHANGE TYPES
-- -----------------------------
CREATE TABLE sd_change_types (
    type_id INT PRIMARY KEY AUTO_INCREMENT,
    type_name VARCHAR(50) UNIQUE NOT NULL
);

-- -----------------------------
-- 📊 STATUS TABLE
-- -----------------------------
CREATE TABLE sd_ticket_statuses (
    status_id INT PRIMARY KEY AUTO_INCREMENT,
    status_name VARCHAR(50) UNIQUE NOT NULL
);

-- -----------------------------
-- 🌐 DEPLOYMENT ENVIRONMENTS
-- -----------------------------
CREATE TABLE sd_environments (
    env_id INT PRIMARY KEY AUTO_INCREMENT,
    env_name VARCHAR(50) UNIQUE NOT NULL
);

-- -----------------------------
-- 🌍 COUNTRIES
-- -----------------------------
CREATE TABLE sd_countries (
    country_id INT PRIMARY KEY AUTO_INCREMENT,
    country_name VARCHAR(50) UNIQUE NOT NULL
);

-- -----------------------------
-- ⚠️ RISK LEVELS
-- -----------------------------
CREATE TABLE sd_risk_levels (
    risk_id INT PRIMARY KEY AUTO_INCREMENT,
    risk_name VARCHAR(50) UNIQUE NOT NULL
);

-- -----------------------------
-- 🚦 APPROVAL STATUS
-- -----------------------------
CREATE TABLE sd_approval_statuses (
    status_id INT PRIMARY KEY AUTO_INCREMENT,
    status_name VARCHAR(50) UNIQUE NOT NULL
);

-- -----------------------------
-- 📝 TICKETS
-- -----------------------------
CREATE TABLE sd_tickets (
    ticket_id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,

    requester_id INT NOT NULL,
    assigned_to INT,
    department_id INT,
    deployment_team_id INT,

    change_type_id INT NOT NULL,
    status_id INT NOT NULL,
    env_id INT NOT NULL,
    country_id INT NOT NULL,
    risk_id INT NOT NULL,
    change_category_id INT,

    changeraised_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    implementation_start DATETIME,
    implementation_end DATETIME,

    assigned_piv INT,
    project_manager_id INT,
    category_id INT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (requester_id) REFERENCES sd_users(user_id),
    FOREIGN KEY (assigned_to) REFERENCES sd_users(user_id),
    FOREIGN KEY (department_id) REFERENCES sd_departments(department_id),
    FOREIGN KEY (deployment_team_id) REFERENCES sd_departments(department_id),
    FOREIGN KEY (assigned_piv) REFERENCES sd_users(user_id),
    FOREIGN KEY (project_manager_id) REFERENCES sd_users(user_id),
    FOREIGN KEY (category_id) REFERENCES sd_categories(category_id),

    FOREIGN KEY (change_type_id) REFERENCES sd_change_types(type_id),
    FOREIGN KEY (status_id) REFERENCES sd_ticket_statuses(status_id),
    FOREIGN KEY (env_id) REFERENCES sd_environments(env_id),
    FOREIGN KEY (country_id) REFERENCES sd_countries(country_id),
    FOREIGN KEY (risk_id) REFERENCES sd_risk_levels(risk_id),
    FOREIGN KEY (change_category_id) REFERENCES sd_change_categories(category_id)
);



-- -----------------------------
-- ✅ APPROVALS
-- -----------------------------
CREATE TABLE sd_approvals (
    approval_id INT PRIMARY KEY AUTO_INCREMENT,
    ticket_id INT NOT NULL,
    approver_id INT NOT NULL,
    is_cab BOOLEAN DEFAULT FALSE,
    status_id INT NOT NULL,
    decision_time TIMESTAMP NULL,
    comment TEXT,

    FOREIGN KEY (ticket_id) REFERENCES sd_tickets(ticket_id),
    FOREIGN KEY (approver_id) REFERENCES sd_users(user_id),
    FOREIGN KEY (status_id) REFERENCES sd_approval_statuses(status_id)
);

-- -----------------------------
-- 💬 COMMENTS
-- -----------------------------
CREATE TABLE sd_comments (
    comment_id INT PRIMARY KEY AUTO_INCREMENT,
    ticket_id INT NOT NULL,
    user_id INT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (ticket_id) REFERENCES sd_tickets(ticket_id),
    FOREIGN KEY (user_id) REFERENCES sd_users(user_id)
);

-- -----------------------------
-- 🔐 FOUR-EYES TASKS
-- -----------------------------
CREATE TABLE sd_four_eyes_tasks (
    task_id INT PRIMARY KEY AUTO_INCREMENT,
    ticket_id INT NOT NULL,
    created_by INT NOT NULL,
    approved_by INT,
    status_id INT NOT NULL,
    approved_at TIMESTAMP NULL,

    FOREIGN KEY (ticket_id) REFERENCES sd_tickets(ticket_id),
    FOREIGN KEY (created_by) REFERENCES sd_users(user_id),
    FOREIGN KEY (approved_by) REFERENCES sd_users(user_id),
    FOREIGN KEY (status_id) REFERENCES sd_approval_statuses(status_id)
);

-- -----------------------------
-- 🧠 PLANNING
-- -----------------------------
CREATE TABLE sd_planning (
    planning_id INT PRIMARY KEY AUTO_INCREMENT,
    ticket_id INT NOT NULL,
    rollout_plan TEXT,
    backout_plan TEXT,

    FOREIGN KEY (ticket_id) REFERENCES sd_tickets(ticket_id)
);
