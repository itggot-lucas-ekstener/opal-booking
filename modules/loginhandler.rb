class Loginhandler

    def initialize(db)
        @db = db
    end

    def get_user_by_id(user_id)
        user = @db_handler.db.execute('SELECT * 
            FROM users 
            WHERE id = ?', user_id).first
        unless user
            return false
        end

        user_id = user['id']
        username = user['name']
        mail = user['mail']
        pwd_hash = user['pwd_hash']
        role = user['role_id']

        return create_new_user(user_id, username, mail, pwd_hash, role)
    end

    def user_login(username, password_noncrypted)
        user = @db.execute('SELECT * FROM users
                WHERE name = ?', username).first
        p user
        p user['pwd_hash']
        unless user
            user = @db.execute('SELECT * FROM users
                    WHERE mail = ?', username).first
            unless user
                return false
            end
        end

        user_id = user['id'].to_i
        username = user['name'].to_s
        mail = user['mail'].to_s
        db_password_hashed = user['pwd_hash']
        role = user['role_id']

        p role
        test_db_password_hashed = BCrypt::Password.create('admin01')
        password_hash = BCrypt::Password.new(db_password_hashed)
        if password_hash == password_noncrypted
            return create_new_user(user_id, username, mail, db_password_hashed, role)
        else
            p 'Login Failed'
            return false
        end
    end

    def username_unique?(username)
        unless @db.execute('SELECT * FROM users WHERE name = ?', username).empty?
            return false
        else
            return true
        end
    end

    def mail_unique?(mail)
        unless @db.execute('SELECT * FROM users WHERE mail = ?', mail).empty?
            return false
        else
            return true
        end
    end

    def user_register(username, mail, password)
        password_hashed = BCrypt::Password.create(password)
        @db.execute('INSERT INTO users (name, mail, pwd_hash, role_id) VALUES(?,?,?,?)', username, mail, password_hashed, 3)
        return true
    end

    def hash_password(password_cleartext)
        return BCrypt::Password.create(password_cleartext)
    end

    def create_new_user(user_id, username, mail, pwd_hash, role)
        p role
        if role == 1
            return Superadmin.new(user_id, username, mail, pwd_hash, role)
        elsif role == 2
            return Admin.new(user_id, username, mail, pwd_hash, role)
        elsif role == 3
            return User.new(user_id, username, mail, pwd_hash, role)
        else
            return false
        end
    end
end