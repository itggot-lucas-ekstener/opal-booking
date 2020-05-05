require_relative 'dbbase.rb'
require_relative 'role.rb'

# The user object with attributes the same as the columns in the database.
# Handles methods related to users.
class User < DbBase
    
    attr_accessor :id, :name, :mail, :pwd_hash, :role_id, :table

    # Public: Creates the object and sets the table attribute.
    # 
    # Examples
    # 
    #   Booking.new
    #   # => <Object::User {table => 'users'}>
    # 
    # Returns the new object.
    def initialize()
        @table = 'users'
    end

    # Public: Checks if the user object the method is executed upon has the admin authority.
    # 
    # Example
    # 
    #   <Object::User>.admin_check
    #   # => true
    # 
    # Returns a boolean.
    def admin_check()
        if @role_id <= Role::ADMIN
            return true
        else
            return false
        end
    end
    # Public: Checks if the user object the method is executed upon has the superadmin authority.
    # 
    # Example
    # 
    #   <Object::User>.admin_check
    #   # => false
    # 
    # Returns a boolean.
    def superadmin_check()
        if @role_id <= Role::SUPERADMIN
            return true
        else
            return false
        end
    end

    # Public: Saves itself to the database. Either update or insert depending on if it exists or not.
    def save()
        if @id.nil?
            @@db.execute('INSERT INTO users (name, mail, pwd_hash, role_id) VALUES(?,?,?,?)', @name, @mail, @pwd_hash, @role_id)
        else
            @@db.execute('UPDATE users
                SET name = ?, mail = ?, pwd_hash = ?, role_id = ?
                WHERE id = ?', @name, @mail, @pwd_hash, @role_id, @id)
        end
    end
end