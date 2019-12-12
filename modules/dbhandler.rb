class DBHandler
    
    def self.connect
        db = SQLite3::Database.new 'opal_booking.db'
        db.results_as_hash = true
        return db
    end

    def self.get()
    end
end