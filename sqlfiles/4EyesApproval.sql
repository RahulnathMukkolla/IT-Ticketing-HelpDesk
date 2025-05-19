CREATE PROCEDURE sp_approve_four_eyes_task (
    IN p_task_id INT,
    IN p_approver_id INT,
    IN p_status_id INT
)
BEGIN
    -- Check if task exists
    IF NOT EXISTS (SELECT 1 FROM sd_four_eyes_tasks WHERE task_id = p_task_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Four-eyes task does not exist';
    END IF;

    -- Check if approver exists
    IF NOT EXISTS (SELECT 1 FROM sd_users WHERE user_id = p_approver_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Approver user does not exist';
    END IF;

    -- Update the task
    UPDATE sd_four_eyes_tasks
    SET approved_by = p_approver_id,
        status_id = p_status_id,
        approved_at = CURRENT_TIMESTAMP
    WHERE task_id = p_task_id;
END