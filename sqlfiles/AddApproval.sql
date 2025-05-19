CREATE PROCEDURE sp_add_approval (
    IN p_ticket_id INT,
    IN p_approver_id INT,
    IN p_is_cab BOOLEAN,
    IN p_status_id INT,
    IN p_comment TEXT
)
BEGIN
    -- Check if ticket exists
    IF NOT EXISTS (SELECT 1 FROM sd_tickets WHERE ticket_id = p_ticket_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ticket does not exist';
    END IF;

    -- Check if approver (user) exists
    IF NOT EXISTS (SELECT 1 FROM sd_users WHERE user_id = p_approver_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Approver user does not exist';
    END IF;

    -- Check if approval status exists
    IF NOT EXISTS (SELECT 1 FROM sd_approval_statuses WHERE status_id = p_status_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Approval status does not exist';
    END IF;

    -- Insert the approval
    INSERT INTO sd_approvals (ticket_id, approver_id, is_cab, status_id, decision_time, comment)
    VALUES (p_ticket_id, p_approver_id, p_is_cab, p_status_id, CURRENT_TIMESTAMP, p_comment);
END
