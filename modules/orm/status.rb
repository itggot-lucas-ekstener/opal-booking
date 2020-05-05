require_relative 'dbbase.rb'

# Handles the different statuses of the bookings.
class Status < DbBase 

    # Public: Integer of the value the pending status has.
    PENDING = 1
    # Public: Integer of the value the accepted status has.
    ACCEPTED = 2
    # Public: Integer of the value the denied status has.
    DENIED = 3

    
end