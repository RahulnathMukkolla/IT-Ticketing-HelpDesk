from flask import Flask, render_template, request, redirect, session
from db import get_db_connection
import os

app = Flask(__name__)
app.secret_key = os.urandom(24)

# -------------------------------
# Route: Login Page
# -------------------------------
@app.route('/')
def login_page():
    return render_template('login.html')

# -------------------------------
# Route: Login Form Submit
# -------------------------------
@app.route('/login', methods=['POST'])
def login():
    email = request.form['email']
    password = request.form['password']

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("SELECT * FROM sd_users WHERE email = %s", (email,))
    user = cursor.fetchone()

    cursor.close()
    conn.close()

    if user and user['password_hash'] == password:  # No hashing for now
        session['user_id'] = user['user_id']
        session['username'] = user['username']
        return redirect('/dashboard')
    else:
        return "Invalid credentials", 401

# -------------------------------
# Route: Dashboard
# -------------------------------
@app.route('/dashboard')
def dashboard():
    if 'user_id' not in session:
        return redirect('/')

    user_id = session['user_id']

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    # Tickets requested by user (Requester tickets)
    cursor.execute('''
        SELECT * FROM vw_ticket_details
        WHERE requester_name = %s
    ''', (session['username'],))
    my_requested_tickets = cursor.fetchall()

    # Tickets waiting for user's approval (CAB approver tickets)
    cursor.execute('''
        SELECT v.* 
        FROM sd_approvals a
        JOIN vw_ticket_details v ON a.ticket_id = v.ticket_id
        WHERE a.approver_id = %s AND a.status_id = 1
    ''', (user_id,))
    my_approval_tickets = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template('dashboard.html',
                           my_requested_tickets=my_requested_tickets,
                           my_approval_tickets=my_approval_tickets)

    if 'user_id' not in session:
        return redirect('/')

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("SELECT * FROM vw_ticket_details WHERE requester_name = %s", (session['username'],))
    tickets = cursor.fetchall()
    print(tickets)
    cursor.close()
    conn.close()

    return render_template('dashboard.html', tickets=tickets)

# -------------------------------
# Route: Create Ticket
# -------------------------------
@app.route('/create_ticket', methods=['GET', 'POST'])
def create_ticket():
    if 'user_id' not in session:
        return redirect('/')

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    # Fetch dropdown data
    cursor.execute("SELECT * FROM sd_change_types")
    change_types = cursor.fetchall()

    cursor.execute("SELECT * FROM sd_ticket_statuses")
    statuses = cursor.fetchall()

    cursor.execute("SELECT * FROM sd_environments")
    environments = cursor.fetchall()

    cursor.execute("SELECT * FROM sd_countries")
    countries = cursor.fetchall()

    cursor.execute("SELECT * FROM sd_risk_levels")
    risks = cursor.fetchall()

    cursor.execute("SELECT * FROM sd_change_categories")
    change_categories = cursor.fetchall()

    cursor.execute("SELECT * FROM sd_categories")
    categories = cursor.fetchall()

    cursor.execute("SELECT * FROM sd_departments")
    departments = cursor.fetchall()

    cursor.execute("SELECT * FROM sd_users")
    users = cursor.fetchall()

    cursor.execute("SELECT * FROM sd_users WHERE user_id = %s", (session['user_id'],))
    requester = cursor.fetchone()

    if request.method == 'POST':
        # Get form data
        title = request.form['title']
        description = request.form['description']
        change_type_id = request.form['change_type_id']
        status_id = request.form['status_id']
        env_id = request.form['env_id']
        country_id = request.form['country_id']
        risk_id = request.form['risk_id']
        change_category_id = request.form['change_category_id']
        deployment_team_id = request.form['deployment_team_id']
        implementation_start = request.form.get('implementation_start') or None
        implementation_end = request.form.get('implementation_end') or None
        assigned_piv = request.form['assigned_piv']
        project_manager_id = request.form['project_manager_id']
        category_id = request.form['category_id']

        department_id = requester['department_id']

        cab_approvers = request.form.getlist('cab_approvers')  # MULTIPLE approvers
        four_eyes_approver = request.form['four_eyes_approver']  # SINGLE user

        # Insert ticket first
        cursor.execute('''
            INSERT INTO sd_tickets (title, description, requester_id, assigned_to, department_id, deployment_team_id,
                                    change_type_id, status_id, env_id, country_id, risk_id, change_category_id,
                                    implementation_start, implementation_end, assigned_piv, project_manager_id, category_id)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        ''', (title, description, session['user_id'], session['user_id'], department_id, deployment_team_id,
            change_type_id, status_id, env_id, country_id, risk_id, change_category_id,
            implementation_start, implementation_end, assigned_piv, project_manager_id, category_id))

        conn.commit()

        ticket_id = cursor.lastrowid  # Get the inserted ticket ID

        # Insert CAB approvers into sd_approvals table
        for approver_id in cab_approvers:
            cursor.execute('''
                INSERT INTO sd_approvals (ticket_id, approver_id, is_cab, status_id)
                VALUES (%s, %s, %s, %s)
            ''', (ticket_id, approver_id, True, 1))  # 1 = Pending status

        # Insert Four Eyes task into sd_four_eyes_tasks table
        cursor.execute('''
            INSERT INTO sd_four_eyes_tasks (ticket_id, created_by, approved_by, status_id)
            VALUES (%s, %s, NULL, %s)
        ''', (ticket_id, four_eyes_approver, 1))  # 1 = Pending status

        conn.commit()

        cursor.close()
        conn.close()

        return redirect('/dashboard')

    cursor.close()
    conn.close()

    return render_template('create_ticket.html',
                           change_types=change_types,
                           statuses=statuses,
                           environments=environments,
                           countries=countries,
                           risks=risks,
                           change_categories=change_categories,
                           categories=categories,
                           departments=departments,
                           users=users,
                           requester_name=requester['username'])


#-------------------------------------
# Route: View Ticket
#--------------------------------------
@app.route('/view_ticket/<int:ticket_id>')
def view_ticket(ticket_id):
    if 'user_id' not in session:
        return redirect('/')

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    current_user_id = session['user_id']

    # Ticket
    cursor.execute('SELECT * FROM vw_ticket_details WHERE ticket_id = %s', (ticket_id,))
    ticket = cursor.fetchone()

    if not ticket:
        cursor.close()
        conn.close()
        return "Ticket not found", 404

    # CAB Approvers
    cursor.execute('''
        SELECT a.approval_id, a.approver_id, u.username, aps.status_name, a.comment
        FROM sd_approvals a
        JOIN sd_users u ON a.approver_id = u.user_id
        JOIN sd_approval_statuses aps ON a.status_id = aps.status_id
        WHERE a.ticket_id = %s
    ''', (ticket_id,))
    cab_approvers = cursor.fetchall()

    # Four-Eyes Task
    # Correct version (no f.status)
    cursor.execute('''
        SELECT f.task_id, f.created_by, u.username as created_by_name,
            f.approved_by, u2.username as approved_by_name, aps.status_name
        FROM sd_four_eyes_tasks f
        JOIN sd_users u ON f.created_by = u.user_id
        LEFT JOIN sd_users u2 ON f.approved_by = u2.user_id
        JOIN sd_approval_statuses aps ON f.status_id = aps.status_id
        WHERE f.ticket_id = %s
    ''', (ticket_id,))

    four_eyes_task = cursor.fetchone()

    # Comments
    cursor.execute('''
        SELECT c.content, u.username, c.created_at
        FROM sd_comments c
        JOIN sd_users u ON c.user_id = u.user_id
        WHERE c.ticket_id = %s
        ORDER BY c.created_at ASC
    ''', (ticket_id,))
    comments = cursor.fetchall()

    # Check if current user is CAB approver
    cursor.execute('''
        SELECT * FROM sd_approvals
        WHERE ticket_id = %s AND approver_id = %s
    ''', (ticket_id, current_user_id))
    is_cab_approver = bool(cursor.fetchone())

    # Check if current user is Four-Eyes approver
    cursor.execute('''
        SELECT * FROM sd_four_eyes_tasks
        WHERE ticket_id = %s AND created_by = %s
    ''', (ticket_id, current_user_id))
    is_four_eyes_approver = bool(cursor.fetchone())

    cursor.close()
    conn.close()

    return render_template('view_ticket.html', ticket=ticket,
                           cab_approvers=cab_approvers,
                           four_eyes_task=four_eyes_task,
                           comments=comments,
                           is_cab_approver=is_cab_approver,
                           is_four_eyes_approver=is_four_eyes_approver)


#---------------------------------------
# Route: addcomment route
#----------------------------------------
@app.route('/add_comment/<int:ticket_id>', methods=['POST'])
def add_comment(ticket_id):
    if 'user_id' not in session:
        return redirect('/')

    comment_content = request.form['content']

    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute('''
        INSERT INTO sd_comments (ticket_id, user_id, content)
        VALUES (%s, %s, %s)
    ''', (ticket_id, session['user_id'], comment_content))

    conn.commit()
    cursor.close()
    conn.close()

    return redirect(f'/view_ticket/{ticket_id}')


#---------------------------------------
# Route: Edit ticket
#---------------------------------------
@app.route('/edit_ticket/<int:ticket_id>', methods=['GET', 'POST'])
def edit_ticket(ticket_id):
    if 'user_id' not in session:
        return redirect('/')

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    # Fetch ticket
    cursor.execute('SELECT * FROM sd_tickets WHERE ticket_id = %s', (ticket_id,))
    ticket = cursor.fetchone()

    if not ticket:
        cursor.close()
        conn.close()
        return "Ticket not found", 404

    # Fetch statuses
    cursor.execute('SELECT * FROM sd_ticket_statuses')
    statuses = cursor.fetchall()

    current_user_id = session['user_id']

    # Determine user role
    is_requester = (ticket['requester_id'] == current_user_id)

    cursor.execute('''
        SELECT * FROM sd_approvals
        WHERE ticket_id = %s AND approver_id = %s
    ''', (ticket_id, current_user_id))
    cab_approval = cursor.fetchone()
    is_cab_approver = bool(cab_approval)

    can_edit = is_requester or is_cab_approver  # Only requester or cab approver can edit
    can_full_edit = is_requester  # Only requester can full edit
    can_approve = is_cab_approver  # Only CAB can approve

    if request.method == 'POST' and can_edit:
        if is_requester:
            # Requester: update title, description, status
            title = request.form['title']
            description = request.form['description']
            status_id = request.form['status_id']

            cursor.execute('''
                UPDATE sd_tickets
                SET title = %s, description = %s, status_id = %s
                WHERE ticket_id = %s
            ''', (title, description, status_id, ticket_id))

        elif is_cab_approver:
            # CAB Approver: approve or reject
            approval_status_id = request.form['approval_status_id']
            comment = request.form['comment']

            cursor.execute('''
                UPDATE sd_approvals
                SET status_id = %s, comment = %s, decision_time = NOW()
                WHERE ticket_id = %s AND approver_id = %s
            ''', (approval_status_id, comment, ticket_id, current_user_id))

        conn.commit()
        cursor.close()
        conn.close()

        return redirect(f'/view_ticket/{ticket_id}')

    cursor.close()
    conn.close()

    return render_template('edit_ticket.html',
                           ticket=ticket,
                           statuses=statuses,
                           can_edit=can_edit,
                           can_full_edit=can_full_edit,
                           can_approve=can_approve)


#---------------------------------------
#Route: CAB Approve route
#----------------------------------------
@app.route('/approve_ticket/<int:ticket_id>', methods=['POST'])
def approve_ticket(ticket_id):
    if 'user_id' not in session:
        return redirect('/')

    approval_status_id = request.form['approval_status_id']
    comment = request.form['comment']

    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute('''
        UPDATE sd_approvals
        SET status_id = %s, comment = %s, decision_time = NOW()
        WHERE ticket_id = %s AND approver_id = %s
    ''', (approval_status_id, comment, ticket_id, session['user_id']))

    conn.commit()
    cursor.close()
    conn.close()

    return redirect(f'/view_ticket/{ticket_id}')


#---------------------------------------
#Route: FourEyes  Approve route
#----------------------------------------
@app.route('/approve_four_eyes/<int:ticket_id>', methods=['POST'])
def approve_four_eyes(ticket_id):
    if 'user_id' not in session:
        return redirect('/')

    four_eyes_status_id = request.form['four_eyes_status_id']

    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute('''
        UPDATE sd_four_eyes_tasks
        SET status_id = %s, approved_by = %s, approved_at = NOW()
        WHERE ticket_id = %s
    ''', (four_eyes_status_id, session['user_id'], ticket_id))

    conn.commit()
    cursor.close()
    conn.close()

    return redirect(f'/view_ticket/{ticket_id}')

# My Requested Tickets
@app.route('/my_tickets')
def my_tickets():
    if 'user_id' not in session:
        return redirect('/')

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute('''
        SELECT * FROM vw_ticket_details
        WHERE requester_name = %s
    ''', (session['username'],))

    my_requested_tickets = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template('my_tickets.html', tickets=my_requested_tickets)


# Tickets Awaiting My CAB Approval
@app.route('/approval_tickets')
def approval_tickets():
    if 'user_id' not in session:
        return redirect('/')

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute('''
        SELECT v.*
        FROM sd_approvals a
        JOIN vw_ticket_details v ON a.ticket_id = v.ticket_id
        WHERE a.approver_id = %s
          AND a.status_id = 1  -- Pending approvals only
    ''', (session['user_id'],))

    approval_tickets = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template('approval_tickets.html', tickets=approval_tickets)


# Tickets Awaiting My Four Eyes Approval
@app.route('/four_eyes_tickets')
def four_eyes_tickets():
    if 'user_id' not in session:
        return redirect('/')

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute('''
        SELECT v.*
        FROM sd_four_eyes_tasks f
        JOIN vw_ticket_details v ON f.ticket_id = v.ticket_id
        WHERE f.created_by = %s
          AND f.status_id = 1  -- Pending four eyes only
    ''', (session['user_id'],))

    four_eyes_tickets = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template('four_eyes_tickets.html', tickets=four_eyes_tickets)

@app.route('/all_tickets')
def all_tickets():
    if 'user_id' not in session:
        return redirect('/')

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute('SELECT * FROM vw_ticket_details')
    all_tickets = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template('all_tickets.html', tickets=all_tickets)

if __name__ == "__main__":
    app.run(debug=True)
