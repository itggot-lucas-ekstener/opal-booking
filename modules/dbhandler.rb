require 'sqlite3'

class DBHandler
    
    attr_reader :db

    def initialize
        @db = SQLite3::Database.new 'db/opal_booking.db'
        @db.results_as_hash = true
    end

    def self.connect
        db = SQLite3::Database.new 'db/opal_booking.db'
        db.results_as_hash = true
        return db
    end
end