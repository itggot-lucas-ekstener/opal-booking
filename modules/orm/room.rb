require_relative 'dbbase.rb'

# The room object with attributes the same as the columns in the database.
# Handles methods related to rooms.
class Room < DbBase

    attr_accessor :id, :name, :room_details, :table

    # Public: Creates the object with the table attribute set to 'room'.
    # 
    # Example
    # 
    #   Room.new
    #   # => <Object::Room {table = 'room'}>
    # 
    # Returns an object.
    def initialize
        @table = 'room'
    end

    # Public: Saves itself to the database. Either update or insert depending on if it exists or not.
    def save()
        if @id.nil?
            @@db.execute('INSERT INTO room (name, room_details) VALUES(?,?)', @name, @room_details)
        else
            @@db.execute('UPDATE room
                SET name = ?, room_details = ?
                WHERE id = ?', @name, @room_details, @id)
        end
    end
end