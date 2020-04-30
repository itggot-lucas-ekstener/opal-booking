

class LoginHandler

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

    def create_new_user(user_id, username, mail, pwd_hash, role)
        if role == 1
            return Superadmin.new(user_id, username, pwd_hash, role)
        elsif role == 2
            return Admin.new(user_id, username, pwd_hash, role)
        elsif role == 3
            return User.new(user_id, username, pwd_hash, role)
        else
            return false
        end
    end
end