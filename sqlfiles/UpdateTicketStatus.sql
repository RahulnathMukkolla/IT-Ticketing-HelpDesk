CREATE PROCEDURE sp_update_ticket_status (
    IN p_ticket_id INT,
    IN p_new_status_id INT
)
BEGIN
    -- Check if ticket exists
    IF NOT EXISTS (SELECT 1 FROM sd_tickets WHERE ticket_id = p_ticket_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ticket does not exist';
    END IF;

    -- Check if status exists
    IF NOT EXISTS (SELECT 1 FROM sd_ticket_statuses WHERE status_id = p_new_status_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Status does not exist';
    END IF;

    -- Update the ticket status
    UPDATE sd_tickets
    SET status_id = p_new_status_id,
        updated_at = CURRENT_TIMESTAMP
    WHERE ticket_id = p_ticket_id;
END
