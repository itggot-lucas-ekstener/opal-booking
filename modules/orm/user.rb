require_relative 'dbbase.rb'

class User < DbBase
    
    attr_accessor :id, :name, :mail, :pwd_hash, :role_id, :table

    @table_name = 'users'

    def initialize()
    @table = 'users'
    #     @id = nil
    #     @name = name
    #     @mail = mail
    #     @pwd_hash = pwd_hash
    #     @role_id = role_id
    #     @table = "users"
    end

    def self.admin_check(user)
        if user.role_id <= 2
            return true
        else
            return false
        end
    end
    def self.superadmin_check(user)
        if user.role_id <= 1
            return true
        else
            return false
        end
    end

    def save()
        if @id.nil?
            @@db.execute('INSERT INTO users (name, mail, pwd_hash, role_id) VALUES(?,?,?,?)', @name, @mail, @pwd_hash, @role_id)
        else
            @@db.execute('UPDATE users
                SET name = ?
                SET mail = ?
                SET pwd_hash = ?
                SET role_id = ?
                WHERE id = ?', @name, @mail, @pwd_hash, @role_id, @id)
        end
    end


    def self.fetch_by_name(name)
        user_row = @@db.execute('SELECT * FROM users WHERE name = ?', name).first

        user = User.new
        user_row.each { |col, value| user.public_send("#{col}=", value) }
        p user

        user2 = DbBase.fetch_by_id(User.new, user.id);

        DbBase.fetch_all(User.new)

        return user2
    end
end