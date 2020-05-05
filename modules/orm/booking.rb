require_relative 'dbbase.rb'
require_relative 'status.rb'

# The booking object with attributes the same as the columns in the database.
# Handles methods related to bookings.
class Booking < DbBase

    attr_accessor :id, :details, :placed_at, :placed_by, :answered_by, :status_id, :start_time, :end_time, :table

    # Public: Creates the object and sets the table attribute.
    # 
    # Examples
    # 
    #   Booking.new
    #   # => <Object::Booking {table => "booking"}>
    # 
    # Returns the new object.
    def initialize()
        @table = "booking"
        
    end

    # Public: Inserts or updates the attributes of the Booking object the method is executed upon in the database.
    def save()
        if @id.nil?
            @@db.execute('INSERT INTO booking (details, placed_at, placed_by, status_id, start_time, end_time) VALUES(?,?,?,?,?,?)', @details, @placed_at, @placed_by, @status_id, @start_time, @end_time)
        else
            @@db.execute('UPDATE booking
                SET details = ?, placed_at = ?, start_time = ?, end_time = ?
                WHERE id = ?', @details, @placed_at, @start_time, @end_time, @id)
        end
    end
    
    # Public: Changes the status of the of the booking by id.
    # 
    # id   - The id of the booking to be changed.
    # user - The user doing the change.
    def self.to_pending(id, user)
        @@db.execute('UPDATE booking
            SET answered_by = ?, status_id = ?
            WHERE id = ?', user.id, Status::PENDING, id)
    end

    # Public: Changes the status of the of the booking by id.
    # 
    # id   - The id of the booking to be changed.
    # user - The user doing the change.
    def self.accept(id, user)
        @@db.execute('UPDATE booking
            SET answered_by = ?, status_id = ?
            WHERE id = ?', user.id, Status::ACCEPTED, id)
    end

    # Public: Changes the status of the of the booking by id.
    # 
    # id   - The id of the booking to be changed.
    # user - The user doing the change.
    def self.deny(id, user)
        @@db.execute('UPDATE booking
            SET answered_by = ?, status_id = ?
            WHERE id = ?', user.id, Status::DENIED, id)
    end

    # Public: Checks for overlapping bookings based on a starttime and endtime and returns the overlapping bookings.
    # 
    # start_time - The beginning of the interval to check as a DateTime integer.
    # end_time   - The end of the interval to check as a DateTime integer.
    # 
    # Examples
    # 
    #   Booking.overlap?(1588762800, 1588770000)
    #   # => [Object::Booking, Object::Booking]
    # 
    # Returns an array. 
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

    # Public: Fetches the latest inputed row in the database.
    # 
    # Examples
    # 
    #   Booking.fetch_latest
    #   # => Object::Booking
    # 
    # Returns the Booking object
    def self.fetch_latest()
        booking_id = @@db.execute('SELECT id from booking
            ORDER BY id DESC
            LIMIT 1;').first['id']
        return DbBase.fetch_by_id(Booking.new, booking_id)
    end
end