require_relative 'dbbase.rb'

class Booking < DbBase

    attr_accessor :booking_id, :placed_at, :placed_by, :answered_by, :status_id, :start_time, :end_time

    def initialize(booking_id, placed_at, placed_by, answered_by, status_id, start_time, end_time)
        @booking_id = booking_id
        @placed_at = placed_at
        @placed_by = placed_by
        @answered_by = answered_by
        @status_id = status_id
        @start_time = start_time
        @end_time = end_time
    end

    def save()
        if @booking_id.nil?
            @@db.execute('INSERT INTO @table (name, mail, pwd_hash, role_id) VALUES(?,?,?,?)', @name, @mail, @pwd_hash, @role_id)
        else
            @@db.execute('UPDATE users
                SET name = ?
                SET mail = ?
                SET pwd_hash = ?
                SET role_id = ?
                WHERE id = ?', @name, @mail, @pwd_hash, @role_id, @id)
        end
    end

end