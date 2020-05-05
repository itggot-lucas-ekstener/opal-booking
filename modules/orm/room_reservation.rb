require_relative 'dbbase.rb'

# The room_reservation object with attributes the same as the columns in the database.
# Handles methods related to room_reservations.
class RoomReservation < DbBase

    attr_accessor :booking_id, :room_id, :table

    # Public: Creates the object with the table attribute set to 'room_reservation'.
    # 
    # Example
    # 
    #   RoomReservation.new
    #   # => <Object::RoomReservation {table = 'room_reservation'}>
    # 
    # Returns an object.
    def initialize
        @table = 'room_reservation'
    end
    
    # Public: Saves itself in the database.
    def save()
        @@db.execute('INSERT INTO room_reservation (booking_id, room_id) VALUES(?,?)', @booking_id, @room_id)
    end

    # Public: Deletes itself from the database.
    def delete()
        @@db.execute("DELETE from #{@table} 
            WHERE booking_id = ?", @booking_id)
    end
end
