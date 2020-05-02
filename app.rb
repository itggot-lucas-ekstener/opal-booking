require 'rack-flash'
require 'bcrypt'

class App < Sinatra::Base
    Dir['modules/**/*.rb'].each do |file|
        require_relative file
    end

    enable :sessions
    use Rack::Flash
    
    before do
        SassCompiler.compile
        @db = DBHandler.new.db
        @login_handler = Loginhandler.new(@db)

        unless request.path == '/login' or request.path == '/do-login' or request.path == '/register' or request.path == '/do-register' or request.path == '/'
            if session[:user].nil?
                redirect '/login'
            end
        end

        # if request.path != '/login' && session[:user].nil? 
        #     redirect '/login'
        # elsif request.path != '/login' && session[:user].nil? 
        #     redirect '/login'
        # else
        #     unless request.path == '/login' && request.path == '/do-login'
        #         @current_user = session[:user]
        #         @current_user_id = @current_user.id
        #     end
        # end
        # @current_user = @db.execute("SELECT * FROM users WHERE id = ?", 1).first
        # p @current_user
        # session[:user_id] = @current_user[:id]
    end

    get '/?' do 
        slim :index
    end


    get '/login/?' do
        slim :'user/login'
    end

    post '/do-login/?' do
        username = params['username']
        password_noncrypted = params['password']
        # password_hashed = BCrypt::Password.create(password_uncrypted)

        user = @login_handler.user_login(username, password_noncrypted)
        p user

        if user
            session[:user] = user
            redirect '/'
        else
            flash[:login_error] = "Failed to login. Username, mail or password incorrect"
            p 'error'
            redirect '/login'
        end
    end

    get '/logout' do
        session.clear
        # cookies.delete('user_id')
        flash[:loggedout] = "You are logged out"
        redirect '/'
    end

    get '/register' do
        slim :'user/register'
    end

    post '/do-register' do
        username = params['register_username']
        mail = params['register_mail']
        password = params['register_password']
        confirm_password = params['confirm_password']
        p password
        p confirm_password
        flash[:register_username] = username
        flash[:register_mail] = mail
        unless @login_handler.username_unique?(username)
            flash[:register_username_error] = "Username already taken"
            error = true
        end
        unless @login_handler.mail_unique?(mail)
            flash[:register_mail_error] = "Email already connected to another account"
            error = true
        end
        unless password == confirm_password
            flash[:register_password_error] = "Passwords does not match"
            error = true
        end
        if error
            redirect '/register'
        end
        if @login_handler.user_register(username, mail, password)
            flash[:misc_msg] = "Register successful, please log in to use account"
            redirect '/login'
        else
            flash[:register_misc_error] = "An error occured, please try again"
            redirect '/register'
        end
    end

    get '/unathourized' do
        slim :unathourized
    end
    
    get '/admin/?' do
        unless User.admin_check(session[:user])
            redirect '/unathourized'
        end
        slim :'admin/admin_main'
    end

    get '/admin/requests/?' do
        unless User.admin_check(session[:user])
            redirect '/unathourized'
        end
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
        unless User.admin_check(session[:user])
            redirect '/unathourized'
        end
        @callback = request.path_info[0..14]
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
        unless User.admin_check(session[:user])
            redirect '/unathourized'
        end
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
        unless User.admin_check(session[:user])
            redirect '/unathourized'
        end
        @db.execute('UPDATE booking
            SET status_id = 2
            WHERE id = ?', params["id"])
        @db.execute('UPDATE booking
            SET answered_by = ?
            WHERE id = ?', @current_user_id, params["id"])
            p params["id"]
        redirect back
    end

    post '/admin/requests/:id/deny/?' do
        unless User.admin_check(session[:user])
            redirect '/unathourized'
        end
        # code for change in database
        @db.execute('UPDATE booking
            SET status_id = 3
            WHERE id = ?', params["id"])
            p params["id"]
        redirect back
    end

    get '/admin/rooms/?' do
        unless User.admin_check(session[:user])
            redirect '/unathourized'
        end
        @all_rooms = @db.execute('SELECT * FROM room')

        slim :'admin/admin_rooms'
    end

    get '/admin/rooms/view/:id/?' do
        unless User.admin_check(session[:user])
            redirect '/unathourized'
        end
        @current_room = @db.execute('SELECT * FROM room
            WHERE id = ?', params["id"]).first
        p @current_room
    
        slim :'admin/admin_room_details'
    end

    get '/admin/rooms/view/:id/edit/?' do
        unless User.admin_check(session[:user])
            redirect '/unathourized'
        end
        @current_room = @db.execute('SELECT * FROM room
            WHERE id = ?', params["id"]).first
        slim :'admin/admin_room_edit'
    end

    post '/admin/rooms/view/:id/delete' do 
        unless User.admin_check(session[:user])
            redirect '/unathourized'
        end
        @db.execute('DELETE FROM room 
            WHERE id = ?', params["id"])
        redirect '/admin/rooms'
    end

    get '/admin/rooms/new/?' do
        unless User.admin_check(session[:user])
            redirect '/unathourized'
        end
        slim :'admin/admin_room_new'
    end

    post '/admin/rooms/update/?' do
        unless User.admin_check(session[:user])
            redirect '/unathourized'
        end
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
        unless User.superadmin_check(session[:user])
            redirect '/unathourized'
        end
        user_role = @db.execute('SELECT role_id FROM users
            WHERE id = ?', params["user_id"]).first["role_id"]
        @db.execute('UPDATE users
            SET role_id = ?
            WHERE id = ?', (user_role + 1), params["user_id"])
        redirect back
    end
    post '/admin/users/promote/?' do
        unless User.superadmin_check(session[:user])
            redirect '/unathourized'
        end
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
            WHERE placed_by = ?', @current_user_id)
        
        @current_users_bookings.each do |booking|
            booking['start_time'] = DateTime.strptime(booking['start_time'].to_s, '%s').to_s[0...-9].gsub('T',' ')
            booking['end_time'] = DateTime.strptime(booking['end_time'].to_s, '%s').to_s[0...-9].gsub('T',' ')
        end
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
        
        slim :'bookings/new'
    end

    get '/requests/new/details/?' do
        # p DateTime.parse(Date.today.to_s).to_time.to_i
        # time_now = Time.new
        # p time_now.strftime("%k:%M")
        @booked_timestrokes = []
        booked_timestrokes_datetime = []
        if session[:overlapping_bookings].is_a?(Array) && session[:overlapping_bookings].length > 0
            session[:overlapping_bookings].each do |booking|
                timestroke = booking['start_time']
                while timestroke < booking['end_time']
                    booked_timestrokes_datetime << timestroke
                    timestroke += 15*60
                end
            end
            booked_timestrokes_datetime.each do |timestroke|
                timestroke = DateTime.strptime(timestroke.to_s, '%s')
                if timestroke.hour < 10
                    hour ="0" + timestroke.hour.to_s
                else
                    hour = timestroke.hour.to_s
                end
                if timestroke.min < 10
                    min ="0" + timestroke.min.to_s
                else
                    min = timestroke.min.to_s
                end
                timestroke = hour + ":" + min
                p"timestroke"
                p timestroke
                @booked_timestrokes << timestroke
            end
           
        else

        end

        @rooms = @db.execute('SELECT * FROM room')
        slim :'bookings/new_details'
    end

    post '/requests/date-select/?' do
        session[:selected_date] = params[:booking_date]
        date_start = session[:selected_date] + "T00:00:00"
        date_end = session[:selected_date] + "T23:59:59" 
        date_start_compare = DateTime.parse(date_start).to_time.to_i
        date_end_compare = DateTime.parse(date_end).to_time.to_i
        # p date_start_compare
        # p date_end_compare
        session[:overlapping_bookings] = @db.execute('SELECT * FROM booking 
            WHERE start_time < ? AND ? < end_time
            OR start_time < ? AND ? < end_time
            OR ? < start_time AND start_time < ?
            OR ? < end_time AND end_time < ?', date_start_compare, date_start_compare, date_end_compare, date_end_compare, date_start_compare, date_end_compare, date_start_compare, date_end_compare)

        redirect '/requests/new/details'
    end

    post '/requests/update/?' do
        # p params
        date = session[:selected_date]
        start_time = DateTime.parse("#{date}T#{params[:start_time]}:00").to_time.to_i
        end_time = DateTime.parse("#{date}T#{params[:end_time]}:00").to_time.to_i
        # p start_time
        # p end_time
        # p date
        if params[:prefilled] == "true"
            @db.transaction 
                puts "update"
                # @db.execute('DELETE from booking
                #     WHERE')
                overlap = @db.execute('SELECT id FROM booking 
                    WHERE start_time < ? AND ? < end_time
                    OR start_time < ? AND ? < end_time
                    OR ? < start_time AND start_time < ?
                    OR ? < end_time AND end_time < ?
                    OR start_time = ? AND end_time = ?', start_time, start_time, end_time, end_time, start_time, end_time, start_time, end_time, start_time, end_time)
                puts "overlap:"
                p overlap
                booking_id = params['booking_id'].to_i
                if !overlap.empty?
                    if overlap.length != 1
                        puts "it's an overlap!"
                        flash[:overlap] = "Your selected time overlaps with another. Please choose another time."
                        redirect back
                    else
                        if overlap.first['id'] == booking_id
                            p "the overlap is itself"
                        else
                            puts "it's an overlap!"
                            flash[:overlap] = "Your selected time overlaps with another. Please choose another time."
                            redirect back
                        end
                    end
                end
                @db.execute('UPDATE booking
                    SET details = ?, start_time = ?, end_time = ?
                    WHERE id = ?', params[:details], start_time, end_time, params[:booking_id])
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
                OR ? < end_time AND end_time < ?
                OR start_time = ? AND end_time = ?', start_time, start_time, end_time, end_time, start_time, end_time, start_time, end_time, start_time, end_time)
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
                @db.execute('INSERT INTO booking (details, placed_by, answered_by, status_id, start_time, end_time) VALUES(?,?,?,?,?,?)', params['details'], @current_user_id, nil, 1, start_time, end_time)
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