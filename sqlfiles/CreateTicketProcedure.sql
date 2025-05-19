CREATE PROCEDURE sp_create_ticket (
    IN p_title VARCHAR(255),
    IN p_description TEXT,
    IN p_requester_id INT,
    IN p_assigned_to INT,
    IN p_department_id INT,
    IN p_deployment_team_id INT,
    IN p_change_type_id INT,
    IN p_status_id INT,
    IN p_env_id INT,
    IN p_country_id INT,
    IN p_risk_id INT,
    IN p_change_category_id INT,
    IN p_implementation_start DATETIME,
    IN p_implementation_end DATETIME,
    IN p_assigned_piv INT,
    IN p_project_manager_id INT,
    IN p_category_id INT,
    OUT p_ticket_id INT  -- << Output Parameter!
)
BEGIN
    -- Validate requester exists
    IF NOT EXISTS (SELECT 1 FROM sd_users WHERE user_id = p_requester_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Requester does not exist';
    END IF;

    -- Validate assigned_to exists (if given)
    IF p_assigned_to IS NOT NULL AND NOT EXISTS (SELECT 1 FROM sd_users WHERE user_id = p_assigned_to) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Assigned user does not exist';
    END IF;

    -- Validate department exists
    IF NOT EXISTS (SELECT 1 FROM sd_departments WHERE department_id = p_department_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Department does not exist';
    END IF;

    -- Validate deployment team exists
    IF NOT EXISTS (SELECT 1 FROM sd_departments WHERE department_id = p_deployment_team_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Deployment team does not exist';
    END IF;

    -- Insert into tickets
    INSERT INTO sd_tickets (
        title, description, requester_id, assigned_to, department_id,
        deployment_team_id, change_type_id, status_id, env_id,
        country_id, risk_id, change_category_id,
        implementation_start, implementation_end, assigned_piv,
        project_manager_id, category_id
    )
    VALUES (
        p_title, p_description, p_requester_id, p_assigned_to, p_department_id,
        p_deployment_team_id, p_change_type_id, p_status_id, p_env_id,
        p_country_id, p_risk_id, p_change_category_id,
        p_implementation_start, p_implementation_end, p_assigned_piv,
        p_project_manager_id, p_category_id
    );

    -- Return newly inserted ticket ID
    SET p_ticket_id = LAST_INSERT_ID();

END



