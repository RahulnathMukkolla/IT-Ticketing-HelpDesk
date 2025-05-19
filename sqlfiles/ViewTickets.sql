CREATE OR REPLACE VIEW vw_ticket_details AS
SELECT 
    t.ticket_id,
    t.title,
    t.description,
    u1.username AS requester_name,
    u2.username AS assigned_to_name,
    d1.name AS department_name,
    d2.name AS deployment_team_name,
    ct.type_name AS change_type,
    ts.status_name AS ticket_status,
    env.env_name AS deployment_environment,
    ctry.country_name AS country,
    rl.risk_name AS risk_level,
    cc.category_name AS change_category,
    cat.name AS category,
    t.changeraised_on,
    t.implementation_start,
    t.implementation_end,
    t.created_at,
    t.updated_at
FROM sd_tickets t
LEFT JOIN sd_users u1 ON t.requester_id = u1.user_id
LEFT JOIN sd_users u2 ON t.assigned_to = u2.user_id
LEFT JOIN sd_departments d1 ON t.department_id = d1.department_id
LEFT JOIN sd_departments d2 ON t.deployment_team_id = d2.department_id
LEFT JOIN sd_change_types ct ON t.change_type_id = ct.type_id
LEFT JOIN sd_ticket_statuses ts ON t.status_id = ts.status_id
LEFT JOIN sd_environments env ON t.env_id = env.env_id
LEFT JOIN sd_countries ctry ON t.country_id = ctry.country_id
LEFT JOIN sd_risk_levels rl ON t.risk_id = rl.risk_id
LEFT JOIN sd_change_categories cc ON t.change_category_id = cc.category_id
LEFT JOIN sd_categories cat ON t.category_id = cat.category_id;
