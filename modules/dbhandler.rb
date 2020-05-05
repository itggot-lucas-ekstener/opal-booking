require 'sqlite3'

# Handles database connection.
class DBHandler
    
    attr_reader :db

    # Public: Creates or accesses the database and sets the condition to return results from the database as hashes.
    # 
    # Examples
    # 
    #   DbHandler.new
    #   # => <Object::SQLite3::Database>
    # 
    # Returns the database object.
    def initialize
        @db = SQLite3::Database.new 'db/opal_booking.db'
        @db.results_as_hash = true
    end
end