require_relative 'dbbase.rb'

class User < DbBase
    
    attr_reader :id, :name, :mail, :pwd_hash, :role

    def initialize(id, name, mail, pwd_hash, role)
        @id = id
        @name = name
        @mail = mail
        @pwd_hash = pwd_hash
        @role = role
    end

    def self.admin_check(user)
        if user.role <= 2
            return true
        else
            return false
        end
    end
    def self.superadmin_check(user)
        if user.role <= 1
            return true
        else
            return false
        end
    end
end