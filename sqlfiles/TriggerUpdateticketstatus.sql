DELIMITER //

DECLARE v_total_approvals INT DEFAULT 0;
DECLARE v_approved_approvals INT DEFAULT 0;
DECLARE v_cab_approved_status_id INT DEFAULT 0;

-- Get the ID of the 'CAB Approved' status
SELECT status_id INTO v_cab_approved_status_id
FROM sd_ticket_statuses
WHERE status_name = 'CAB Approved'
LIMIT 1;

-- Count total approvals required for this ticket
SELECT COUNT(*) INTO v_total_approvals
FROM sd_approvals
WHERE ticket_id = NEW.ticket_id;

-- Count how many have been approved (assuming 'Approved' status)
SELECT COUNT(*) INTO v_approved_approvals
FROM sd_approvals a
JOIN sd_approval_statuses s ON a.status_id = s.status_id
WHERE a.ticket_id = NEW.ticket_id
  AND s.status_name = 'Approved';

-- If all required approvals are approved, update ticket status
IF v_total_approvals > 0 AND v_total_approvals = v_approved_approvals THEN
    UPDATE sd_tickets
    SET status_id = v_cab_approved_status_id
    WHERE ticket_id = NEW.ticket_id;
END IF;//

DELIMITER ;