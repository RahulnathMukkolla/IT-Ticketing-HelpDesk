CREATE PROCEDURE sp_add_comment (
    IN p_ticket_id INT,
    IN p_user_id INT,
    IN p_content TEXT
)
BEGIN
    -- Check if ticket exists
    IF NOT EXISTS (SELECT 1 FROM sd_tickets WHERE ticket_id = p_ticket_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ticket does not exist';
    END IF;

    -- Check if user exists
    IF NOT EXISTS (SELECT 1 FROM sd_users WHERE user_id = p_user_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User does not exist';
    END IF;

    -- Insert the comment
    INSERT INTO sd_comments (ticket_id, user_id, content, created_at)
    VALUES (p_ticket_id, p_user_id, p_content, CURRENT_TIMESTAMP);
END
