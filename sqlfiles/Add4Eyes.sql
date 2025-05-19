CREATE PROCEDURE sp_create_four_eyes_task (
    IN p_ticket_id INT,
    IN p_created_by INT
)
BEGIN
    INSERT INTO sd_four_eyes_tasks (
        ticket_id,
        created_by,
        status_id
    )
    VALUES (
        p_ticket_id,
        p_created_by,
        (SELECT status_id FROM sd_approval_statuses WHERE status_name = 'pending' LIMIT 1)
    );

    -- Return the created task_id
    SELECT LAST_INSERT_ID() AS task_id;
END 