require_relative 'dbbase.rb'

class User < DbBase
    
    def initialize(id, name, mail, pwd_hash)
        @id = id
        @name = name
        @mail = mail
        @pwd_hash = pwd_hash
    end

    
end