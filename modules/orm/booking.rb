require_relative 'dbbase.rb'
require_relative 'status.rb'

class Booking < DbBase

    attr_accessor :id, :details, :placed_at, :placed_by, :answered_by, :status_id, :start_time, :end_time, :table

    def initialize()
        @table = "booking"
        # @id = booking_id
        # @details
        # @placed_at = placed_at
        # @placed_by = placed_by
        # @answered_by = answered_by
        # @status_id = status_id
        # @start_time = start_time
        # @end_time = end_time
    end

    def save()
        if @id.nil?
            @@db.execute('INSERT INTO booking (details, placed_at, placed_by, status_id, start_time, end_time) VALUES(?,?,?,?,?,?)', @details, @placed_at, @placed_by, @status_id, @start_time, @end_time)
        else
            @@db.execute('UPDATE booking
                SET details = ?, placed_at = ?, start_time = ?, end_time = ?
                WHERE id = ?', @details, @placed_at, @start_time, @end_time, @id)
        end
    end
    
    def self.to_pending(id, user)
        @@db.execute('UPDATE booking
            SET answered_by = ?, status_id = ?
            WHERE id = ?', user.id, Status::PENDING, id)
    end
    def self.accept(id, user)
        @@db.execute('UPDATE booking
            SET answered_by = ?, status_id = ?
            WHERE id = ?', user.id, Status::ACCEPTED, id)
    end
    def self.deny(id, user)
        @@db.execute('UPDATE booking
            SET answered_by = ?, status_id = ?
            WHERE id = ?', user.id, Status::DENIED, id)
    end

    def self.overlap?(start_time, end_time)
        overlap = @@db.execute('SELECT id FROM booking 
            WHERE start_time < ? AND ? < end_time
            OR start_time < ? AND ? < end_time
            OR ? < start_time AND start_time < ?
            OR ? < end_time AND end_time < ?
            OR start_time = ? AND end_time = ?', start_time, start_time, end_time, end_time, start_time, end_time, start_time, end_time, start_time, end_time)
        overlapping_bookings = []
        unless overlap.nil?
            overlap.each do |booking|
                overlapping_booking = DbBase.fetch_by_id(Booking.new, booking['id'])
                overlapping_bookings << overlapping_booking
            end
        end
        return overlapping_bookings
    end

    def self.fetch_latest()
        booking_id = @@db.execute('SELECT id from booking
            ORDER BY id DESC
            LIMIT 1;').first['id']
        return DbBase.fetch_by_id(Booking.new, booking_id)
    end
end