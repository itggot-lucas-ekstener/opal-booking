require 'rack-flash'

class App < Sinatra::Base
    Dir['modules/**/*.rb'].each do |file|
        require_relative file
    end

    enable :sessions
    use Rack::Flash
    
    before do
        SassCompiler.compile
        @db = SQLite3::Database.new('db/opal_booking.db')
        @db.results_as_hash = true
        @current_user = @db.execute("SELECT * FROM users WHERE id = ?", 1).first
        # p @current_user
        # session[:user_id] = @current_user[:id]
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
        @booking_id = params["id"].to_i
        @current_booking_reservations = @db.execute('SELECT * from room_reservation 
            JOIN room ON room_reservation.room_id = room.id
            WHERE booking_id = ?', @booking_id)

        current_booking_status = @current_booking['status_name']
        p current_booking_status
        slim :"bookings/#{current_booking_status}"
    end

    get '/admin/requests/:id/edit/?' do
        @callback = request.path_info[0..-5]
        @rooms = @db.execute('SELECT * FROM room')
        @current_booking = @db.execute('SELECT * FROM booking 
            WHERE id = ?', params["id"]).first
        @current_booking['start_time'] = DateTime.strptime(@current_booking['start_time'].to_s, '%s').to_s[0..-7]
        @current_booking['end_time'] = DateTime.strptime(@current_booking['end_time'].to_s, '%s').to_s[0..-7]
        p @current_booking
        @booking_id = params["id"].to_i       
        @current_booking_reservations = @db.execute('SELECT * from room_reservation 
            JOIN room ON room_reservation.room_id = room.id
            WHERE booking_id = ?', @booking_id)
        # p @current_booking_reservations

        
        slim :'bookings/edit'
    end

    post '/admin/requests/:id/accept/?' do
        @db.execute('UPDATE booking
            SET status_id = 2
            WHERE id = ?', params["id"])
        @db.execute('UPDATE booking
            SET answered_by = ?
            WHERE id = ?', @current_user["id"], params["id"])
            p params["id"]
        redirect back
    end

    post '/admin/requests/:id/deny/?' do
        # code for change in database
        @db.execute('UPDATE booking
            SET status_id = 3
            WHERE id = ?', params["id"])
            p params["id"]
        redirect back
    end

    get '/admin/rooms/?' do
        @all_rooms = @db.execute('SELECT * FROM room')

        slim :'admin/admin_rooms'
    end

    get '/admin/rooms/view/:id/?' do
        @current_room = @db.execute('SELECT * FROM room
            WHERE id = ?', params["id"]).first
        p @current_room
    
        slim :'admin/admin_room_details'
    end

    get '/admin/rooms/view/:id/edit/?' do
        @current_room = @db.execute('SELECT * FROM room
            WHERE id = ?', params["id"]).first
        slim :'admin/admin_room_edit'
    end

    post '/admin/rooms/view/:id/delete' do 
        @db.execute('DELETE FROM room 
            WHERE id = ?', params["id"])
        redirect '/admin/rooms'
    end

    get '/admin/rooms/new/?' do
        slim :'admin/admin_room_new'
    end

    post '/admin/rooms/update/?' do
        if params[:prefilled] == "true"
            puts "Update"
            @db.execute('UPDATE room
                SET name = ?, room_details = ?
                WHERE id = ?', params[:room_name], params[:room_details], params[:room_id])
            puts "Success"
        else
            puts "New"
            @db.execute('INSERT INTO room (name, room_details) VALUES(?,?)', params[:room_name], params[:room_details])
            puts "Success"
        end
        redirect '/admin/rooms/'
    end

    get '/admin/users/?' do
        @all_users = @db.execute('SELECT * FROM users')
        @admin_users = @db.execute('SELECT * FROM users 
            WHERE role_id = ?', 2)
        @normal_users = @db.execute('SELECT *FROM users
            WHERE role_id = ?', 3)

        slim :'admin/admin_users'
    end

    # get '/admin/users/:id/view' do
    #     @selected_user = @db.execute('SELECT * FROM users
    #         WHERE id = ?', params[:id]).first
    #     slim :'admin/admin_users_view'
    # end

    post '/admin/users/demote/?' do
        user_role = @db.execute('SELECT role_id FROM users
            WHERE id = ?', params["user_id"]).first["role_id"]
        @db.execute('UPDATE users
            SET role_id = ?
            WHERE id = ?', (user_role + 1), params["user_id"])
        redirect back
    end
    post '/admin/users/promote/?' do
        user_role = @db.execute('SELECT role_id FROM users
            WHERE id = ?', params["user_id"]).first["role_id"]
        @db.execute('UPDATE users
            SET role_id = ?
            WHERE id = ?', (user_role - 1), params["user_id"])
        redirect back
    end

    get '/requests/?' do
        @current_users_bookings = @db.execute('SELECT *, booking.id as "booking_id", status.name as "status_name" from booking
            JOIN status ON booking.status_id = status.id
            WHERE placed_by = ?', @current_user["id"])
        # p @current_users_bookings
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

    get '/requests/new/date/?' do
        @rooms = @db.execute('SELECT * FROM room')
        # p @rooms
        p DateTime.now.to_s
        slim :'bookings/new'
    end

    get '/requests/new/details/?' do
        
    end

    post '/requests/update/?' do
        p params
        params[:start_time] = DateTime.parse("#{params[:start_time]}:00+01:00").to_time.to_i
        params[:end_time] = DateTime.parse("#{params[:end_time]}:00+01:00").to_time.to_i
        if params[:prefilled] == "true"
            puts "update"
            overlap = @db.execute('SELECT * FROM booking 
                WHERE start_time < ? AND ? < end_time
                OR start_time < ? AND ? < end_time
                OR ? < start_time AND start_time < ?
                OR ? < end_time AND end_time < ?', params[:start_time], params[:start_time], params[:end_time], params[:end_time], params[:start_time], params[:end_time], params[:start_time], params[:end_time])
            puts "overlap:"
            p overlap
            if !overlap.empty?
                puts "it's an overlap!"
                flash[:overlap] = "Your selected time overlaps with another: Please choose another time."
                redirect back
            end
            @db.transaction 
            @db.execute('UPDATE booking
                SET details = ?, start_time = ?, end_time = ?
                WHERE id = ?', params[:details], params[:start_time], params[:end_time], params[:booking_id])
            @booking_id = params["booking_id"].to_i
            p @booking_id     
            @db.execute('DELETE FROM room_reservation
                WHERE booking_id = ?', @booking_id)
            params['select_room'].each do |room_id|
                
                # room_id = @db.execute('SELECT id from room
                #     WHERE name = ?', params["select_room"]).first
                @db.execute('INSERT INTO room_reservation (booking_id, room_id) VALUES(?,?)', @booking_id, room_id)
            end
            @db.commit
        else
            puts "new"
            current_time = Date.today.to_s
            p params
            overlap = @db.execute('SELECT * FROM booking 
                WHERE start_time < ? AND ? < end_time
                OR start_time < ? AND ? < end_time
                OR ? < start_time AND start_time < ?
                OR ? < end_time AND end_time < ?', params[:start_time], params[:start_time], params[:end_time], params[:end_time], params[:start_time], params[:end_time], params[:start_time], params[:end_time])
            puts "overlap:"
            if !overlap.empty?
                puts "it's an overlap!"
                flash[:overlap] = "Your selected time overlaps with another"  
                redirect back
            end

            @db.transaction
                # p params['details']
                # p current_time
                # p @current_user
                @db.execute('INSERT INTO booking (details, placed_by, answered_by, status_id, start_time, end_time) VALUES(?,?,?,?,?,?)', params['details'], @current_user["id"], nil, 1, params['start_time'], params['end_time'])
                booking_id = @db.execute('SELECT id from booking
                ORDER BY id DESC
                LIMIT 1;').first
                # p booking_id
                p params
                params['select_room'].each do |room_id|
                    
                    # room_id = @db.execute('SELECT id from room
                    #     WHERE name = ?', params["select_room"]).first
                    @db.execute('INSERT INTO room_reservation (booking_id, room_id) VALUES(?,?)', booking_id["id"], room_id)
                end
            @db.commit
        end
        puts "success"
        redirect params['callback']
    end
    
    
    
end