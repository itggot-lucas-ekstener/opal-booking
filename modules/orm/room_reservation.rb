require_relative 'dbbase.rb'

class RoomReservation < DbBase

    attr_accessor :booking_id, :room_id, :table

    def initialize
        @table = 'room_reservation'
    end
    
    def save()
        @@db.execute('INSERT INTO room_reservation (booking_id, room_id) VALUES(?,?)', @booking_id, @room_id)
    end
end
