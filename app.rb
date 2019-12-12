class App < Sinatra::Base
    Dir['modules/**/*.rb'].each do |file|
        require_relative file
    end
    
    before do
        SassCompiler.compile
        @current_user = 1
        @db = SQLite3::Database.new('db/opal_booking.db')
        @db.results_as_hash = true
        
    end
    
    get '/admin/requests/?' do
        all_bookings = @db.execute('SELECT *, users.id as "user_id", booking.id as "booking_id", status.name as "status_name" from booking
            JOIN status ON booking.status_id = status.id
            JOIN users ON booking.placed_by = users.id')
        
        @pending = all_bookings.select {|booking| booking['status_id'] == 1}
        @accepted = all_bookings.select {|booking| booking['status_id'] == 2}
        @denied = all_bookings.select {|booking| booking['status_id'] == 3}
        
        slim :admin_request
    end 

    get '/admin/requests/:id/?' do
        @current_booking = @db.execute('SELECT *, users.id as "user_id", booking.id as "booking_id", status.name as "status_name", users.name as user_name from booking
            JOIN status ON booking.status_id = status.id
            JOIN users ON booking.placed_by = users.id
            WHERE booking_id = ?', params["id"]).first
        p @current_booking
        @booking_id = params['id'].to_i
        @current_booking_reservations = @db.execute('SELECT * from reservation 
            JOIN room ON reservation.room_id = room.id
            WHERE booking_id = ?', @booking_id)

        current_booking_status = @current_booking['status_name']
        
        slim :"bookings/#{current_booking_status}"
    end

    post '/admin/requests/:id/accept/?' do
        @db.execute('UPDATE booking
            SET status_id = 2
            WHERE id = ?', params["id"])
            p params['id']
        redirect back
    end

    post '/admin/requests/:id/deny/?' do
        # code for change in database
    end
end


