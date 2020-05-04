require_relative 'dbbase.rb'

class Room < DbBase

    attr_accessor :id, :name, :room_details, :table

    def initialize
        @table = 'room'
    end

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