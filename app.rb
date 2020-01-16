class App < Sinatra::Base
    Dir['modules/**/*.rb'].each do |file|
        require_relative file
    end
    
    before do
        SassCompiler.compile
        @db = SQLite3::Database.new('db/opal_booking.db')
        @db.results_as_hash = true
        @current_user = @db.execute("SELECT * FROM users WHERE id = ?", 2).first
        # p @current_user
        # session[:user_id] = @current_user['id']
    end

    get '/?' do 
        slim :index
    end


    get '/login/?' do
        slim :login
    end
    
    get '/admin/?' do
        slim :'admin/admin_main'
    end

    get '/admin/requests/?' do
        all_bookings = @db.execute('SELECT *, users.id as "user_id", booking.id as "booking_id", status.name as "status_name" from booking
            JOIN status ON booking.status_id = status.id
            JOIN users ON booking.placed_by = users.id')
        p all_bookings
        
        @pending = all_bookings.select {|booking| booking['status_id'] == 1}
        @accepted = all_bookings.select {|booking| booking['status_id'] == 2}
        @denied = all_bookings.select {|booking| booking['status_id'] == 3}
        
        slim :'admin/admin_request'
    end 

    get '/admin/requests/:id/?' do
        @current_booking = @db.execute('SELECT *, users.id as "user_id", booking.id as "booking_id", status.name as "status_name", users.name as user_name from booking
            JOIN status ON booking.status_id = status.id
            JOIN users ON booking.placed_by = users.id
            WHERE booking_id = ?', params["id"]).first
        p @current_booking
        @booking_id = params['id'].to_i
        @current_booking_reservations = @db.execute('SELECT * from room_reservation 
            JOIN room ON room_reservation.room_id = room.id
            WHERE booking_id = ?', @booking_id)

        current_booking_status = @current_booking['status_name']
        
        p current_booking_status
        slim :"bookings/#{current_booking_status}"
    end

    post '/admin/requests/:id/accept/?' do
        @db.execute('UPDATE booking
            SET status_id = 2
            WHERE id = ?', params["id"])
        @db.execute('UPDATE booking
            SET answered_by = ?
            WHERE id = ?', @current_user["id"], params["id"])
            p params['id']
        redirect back
    end

    post '/admin/requests/:id/deny/?' do
        # code for change in database
        @db.execute('UPDATE booking
            SET status_id = 3
            WHERE id = ?', params["id"])
            p params['id']
        redirect back
    end

    get '/admin/rooms/?' do
        @all_rooms = @db.execute('SELECT * FROM room')

        slim :'admin/admin_rooms'
    end

    get '/admin/rooms/:id/?' do
        @current_room = @db.execute('SELECT * FROM room
            WHERE id = ?', params["id"]).first
        p @current_room
    
        slim :'admin/admin_room_details'
    end

    get '/admin/rooms/:id/edit/?' do
        @current_room = @db.execute('SELECT * FROM room
            WHERE id = ?', params["id"]).first
        slim :'admin/admin_room_edit'
    end

    get '/requests/?' do
        @current_users_bookings = @db.execute('SELECT *, booking.id as "booking_id", status.name as "status_name" from booking
            JOIN status ON booking.status_id = status.id
            WHERE placed_by = ?', @current_user["id"])
        p @current_users_bookings
        # @current_users_bookings.each do |b|
            # p b
            # puts"________________"
        # end
        # puts "____________________"
        @current_users_reservations = []
        @current_users_bookings.each do |booking|
            reservations = @db.execute('SELECT * from room_reservation
                JOIN room ON room_reservation.room_id = room.id
                WHERE booking_id = ?', booking["booking_id"])
            # p reservations
            # puts"____________________"
            if @current_users_reservations.length <= 1
                @current_users_reservations = reservations
            else
                reservations.each do |res|
                    @current_users_reservations << res
                end
            end
        end
        p @current_users_reservations

        slim :'user/requests'
    end
    
   

    get '/requests/new/?' do
        @rooms = @db.execute('SELECT * FROM room')
        # p @rooms
        slim :'bookings/new'
    end

    post '/requests/new/place/?' do
        # p params
        current_time = Date.today.to_s
        p params
        @db.transaction
            # p params['details']
            # p current_time
            # p @current_user
            @db.execute('INSERT INTO booking (details, placed_at, placed_by, answered_by, status_id, start_time, end_time) VALUES(?,?,?,?,?,?,?)', params['details'], current_time, @current_user['id'], nil, 1, params['start_time'], params['end_time'])
            booking_id = @db.execute('SELECT id from booking
                ORDER BY id DESC
                LIMIT 1;').first
            # p booking_id
            p params
            params['select_room'].each do |room_id|
                
                # room_id = @db.execute('SELECT id from room
                #     WHERE name = ?', params["select_room"]).first
                @db.execute('INSERT INTO room_reservation (booking_id, room_id) VALUES(?,?)', booking_id['id'], room_id)
            end
        @db.commit
        redirect back
    end
end


