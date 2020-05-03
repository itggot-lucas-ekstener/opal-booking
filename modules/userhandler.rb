require_relative 'orm/role.rb'
require_relative 'orm/user.rb'

class UserHandler

    def initialize(db)
        @db = db
    end

    def user_login(username, password_noncrypted)
        user = DbBase.fetch_where(User.new, 'name =', username).first
        unless user
            return false
        end
        db_password = BCrypt::Password.new(user.pwd_hash)
        if db_password == password_noncrypted
            return user
        else
            p 'Login Failed'
            return false
        end
    end

    def username_unique?(username)
        unless DbBase.fetch_where(User.new, 'name =', username).empty?
            return false
        else
            return true
        end
    end

    def mail_unique?(mail)
        unless DbBase.fetch_where(User.new, 'name =', mail).empty?
            return false
        else
            return true
        end
    end

    def user_register(user_data)
        # password_hashed = BCrypt::Password.create(password)
        # new_user = User.new(username, mail, password_hashed, Role.new.User)
        new_user = User.new
        user_data.each { |col, value| new_user.public_send("#{col}=", value) }
        new_user.public_send("role_id=", Role::USER)
        new_user.save
        return true
    end

    def hash_password(password_cleartext)
        return BCrypt::Password.create(password_cleartext)
    end
    
end