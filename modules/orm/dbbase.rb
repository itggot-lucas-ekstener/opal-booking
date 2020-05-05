require 'sqlite3'
require_relative '../dbhandler.rb'

# Handles basic methods for most objects.
class DbBase
    @@db = DBHandler.new.db

    # Fetches data from the database and creates an object out of the data.
    # 
    # obj - The type of object that should be created.
    # id  - The id of the of the data in the database.
    # 
    # Example 
    # 
    #   DbBase.fetch_by_id(User.new, 2)
    #   # => <Object::User>
    # 
    # Returns the created object.
    def self.fetch_by_id(obj, id)
        row = @@db.execute("SELECT * FROM #{obj.table} WHERE id = ?", id).first
        row.each { |col, value| obj.public_send("#{col}=", value) }
        return obj
    end

    # Fetches all data from a table in the database and creates objects out of the data.
    # 
    # obj - The type of object that should be created.
    # 
    # Example 
    # 
    #   DbBase.fetch_all(User.new)
    #   # => <Object::User>
    # 
    # Returns an array of the created objects.
    def self.fetch_all(obj)
        rows = @@db.execute("SELECT * FROM #{obj.table}")
        
        objects = []
        rows.each do |row|
            new_obj = obj.class.new
            row.each { |col, value| new_obj.public_send("#{col}=", value) }
            objects << new_obj
        end
       
        return objects
    end

    # Public: Fetches the data based on a specified condition and creates objects of the data.
    # 
    # obj             - The type of object that should be created.
    # sql_condition   - The type of condition to be met.
    # condition_value - The value of the condition.
    # 
    # Example
    # 
    #   DbBase.fetch_where(User.new, 'name =', 'Tom')
    #   # => <Object::User {name = 'Tom'}
    # 
    # Returns an array of objects.

    def self.fetch_where(obj, sql_condition, condition_value)
        rows = @@db.execute("SELECT * from #{obj.table} WHERE #{sql_condition} ?", condition_value)
        objects = []
        rows.each do |row|
            new_obj = obj.class.new
            row.each { |col, value| new_obj.public_send("#{col}=", value) }
            objects << new_obj
        end
        
        return objects
    end

    # Public: Deletes the data of the object the method is executed upon in the database.
    def delete()
        @@db.execute("DELETE from #{@table} 
            WHERE id = ?", @id)
    end
end