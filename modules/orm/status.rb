require_relative 'dbbase.rb'

class Status < DbBase 

    attr_accessor :id, :name, :table
    PENDING = 1
    ACCEPTED = 2
    DENIED = 3
    
    def initialize
        @table = "status"
    end

    
end