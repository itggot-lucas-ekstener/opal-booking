require 'sqlite3'
require_relative 'dbhandler.rb'

$db = DBHandler.new
# $db.results_as_hash = true

# print $db.db

class DbBase
    def fetch_all
        return $db.execute("SELECT * FROM #{self.name.downcase}")
    end
end