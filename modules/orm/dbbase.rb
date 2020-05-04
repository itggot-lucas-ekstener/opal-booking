require 'sqlite3'
require_relative '../dbhandler.rb'

# $db = DBHandler.new
# $db.results_as_hash = true

# print $db.db

class DbBase
    @@db = DBHandler.new.db
    def initialize
    end
    
    def self.fetch_by_id(obj, id)
        row = @@db.execute("SELECT * FROM #{obj.table} WHERE id = ?", id).first
        row.each { |col, value| obj.public_send("#{col}=", value) }
        return obj
    end

    def self.fetch_all(obj)
        rows = @@db.execute("SELECT * FROM #{obj.table}")
        # p obj.class
        objects = []
        rows.each do |row|
            new_obj = obj.class.new
            row.each { |col, value| new_obj.public_send("#{col}=", value) }
            objects << new_obj
        end
        # p objects
        return objects
    end

    def self.fetch_where(obj, sql_condition, condition_value)
        rows = @@db.execute("SELECT * from #{obj.table} WHERE #{sql_condition} ?", condition_value)
        objects = []
        rows.each do |row|
            new_obj = obj.class.new
            row.each { |col, value| new_obj.public_send("#{col}=", value) }
            objects << new_obj
        end
        # p objects
        return objects
    end
    
    def self.save(obj)
        if obj.id.nil?
            attributes = obj.attributes
            column_string = ""
            num_of_values = ""
            attributes.each do |attribute|
                col_comp, value_comp = attribute.first
                column_string += "#{col_comp},"
                num_of_values += "?,"
            end
            column_string = column_string[0..-2]
            num_of_values = num_of_values[0..-2]
            @@db.execute("INSERT INTO #{obj.table} (#{column_string})")
        end
    end

    def delete()
        @@db.execute("DELETE from #{@table} 
            WHERE id = ?", @id)
    end
end