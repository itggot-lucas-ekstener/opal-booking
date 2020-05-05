require_relative 'orm/role.rb'
require_relative 'orm/user.rb'
require 'bcrypt'

# Handles user-related functions and methods.
class UserHandler

    # Public: Creates the db attribute when a new object of the class is created.
    # 
    # db - The database
    # 
    # Examples

    #   UserHandler.new(<Object::SQLite3::Database>)
    #   # => <Object::UserHandler {db => <Object::SQLite3::Database>}
    #
    # Returns the UserHandler object.
    def initialize(db)
        @db = db
    end

    # Public: Compares the username and password inputs to see if there is a match in the database.
    # 
    # username            - The username in question.  
    # password_noncrypted - The password in question.
    # 
    # Examples
    # 
    #   UserHandler.user_login('Tom', 'tomdoc123')
    #   # => True
    # 
    # Returns True or False.
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

    # Public: Checks if the username inputed already exists.
    # 
    # username - The username in question.
    # 
    # Examples
    # 
    #   UserHandler.username_unique?('Tom')
    #   # => True
    # 
    # Returns True or False
    def username_unique?(username)
        unless DbBase.fetch_where(User.new, 'name =', username).empty?
            return false
        else
            return true
        end
    end

    # Public: Checks if the mail inputed already exists.
    # 
    # mail - The mail in question.
    # 
    # Examples
    # 
    #   UserHandler.mail_unique?('tomdoc@example.com')
    #   # => True
    # 
    # Returns True or False
    def mail_unique?(mail)
        unless DbBase.fetch_where(User.new, 'mail =', mail).empty?
            return false
        else
            return true
        end
    end

    # Public: Creates a new user from register and saves it in the database.
    # 
    # user_data - A hash of the fata of the new user.
    # 
    # Examples
    # 
    #   UserHandler.user_register(hash_of_information)
    #   # => True
    # 
    # Returns true if the process is completed.
    def user_register(user_data)
        
        new_user = User.new
        user_data.each { |col, value| new_user.public_send("#{col}=", value) }
        new_user.public_send("role_id=", Role::USER)
        new_user.save
        return true
    end

    # Public: Encrypts a password from cleartext to BCrypt hash.
    # 
    # password_cleartext - The password to be encrypted.
    # 
    # Examples
    # 
    #   UserHandler.hash_password('secret_password')
    #   # => "$2a$12$.Qm0lbjfMVYUvjwrmanrtuRaXy4uQuY7hAGnGooHYHPMJham20dzO"
    # 
    # Returns the hashed password.
    def hash_password(password_cleartext)
        return BCrypt::Password.create(password_cleartext)
    end
    
end