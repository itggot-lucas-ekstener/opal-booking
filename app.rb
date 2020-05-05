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
        @user_handler = UserHandler.new(@db)

        unless request.path == '/login' or request.path == '/do-login' or request.path == '/register' or request.path == '/do-register' or request.path == '/'
            if session[:user].nil?
                redirect '/login'
            end
        end

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
       

        user = @user_handler.user_login(username, password_noncrypted)
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
       
        flash[:loggedout] = "You are logged out"
        redirect '/'
    end

    get '/register' do
        slim :'user/register'
    end

    post '/do-register' do
        p params
        new_user_hash = {}
        params.each do |key, value|
            unless key == 'confirm_password'
                if key == 'password'
                    key = 'pwd_hash'
                    value = BCrypt::Password.create(value)
                end
                new_user_hash["#{key}"] = value
                p key
                p value
            end
        end

        flash[:register_username] = params['name']
        flash[:register_mail] = params['mail']
        unless @user_handler.username_unique?(params['name'])
            flash[:register_username_error] = "Username already taken"
            error = true
        end
        unless @user_handler.mail_unique?(params['mail'])
            flash[:register_mail_error] = "Email already connected to another account"
            error = true
        end
        unless params['password'] == params['confirm_password']
            flash[:register_password_error] = "Passwords does not match"
            error = true
        end
        if error
            redirect '/register'
        end
        if @user_handler.user_register(new_user_hash)
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
        unless session[:user].admin_check
            redirect '/unathourized'
        end
        slim :'admin/admin_main'
    end

    get '/admin/requests/?' do
        unless session[:user].admin_check
            redirect '/unathourized'
        end
       
        all_bookings = DbBase.fetch_all(Booking.new)
        
        @pending = all_bookings.select {|booking| booking.status_id == Status::PENDING}
        @accepted = all_bookings.select {|booking| booking.status_id == Status::ACCEPTED}
        @denied = all_bookings.select {|booking| booking.status_id == Status::DENIED}
        
        slim :'admin/admin_request'
    end 

    get '/admin/requests/:id/?' do
        unless session[:user].admin_check
            redirect '/unathourized'
        end
        @callback = request.path_info[0..14]
        @booking_id = params["id"].to_i
        @current_booking = DbBase.fetch_by_id(Booking.new, @booking_id)
        @booking_placer = DbBase.fetch_by_id(User.new, @current_booking.placed_by)
        unless @current_booking.answered_by.nil?
            @booking_answerer = DbBase.fetch_by_id(User.new, @current_booking.answered_by)
        end

        @current_booking_reservations = DbBase.fetch_where(RoomReservation.new, 'booking_id =', @booking_id)
        @rooms = []
        @current_booking_reservations.each do |reservation| 
            @rooms << DbBase.fetch_by_id(Room.new, reservation.room_id)
        end

        status = DbBase.fetch_by_id(Status.new, @current_booking.status_id)
        slim :"bookings/#{status.name}"
    end

    get '/admin/requests/:id/edit/?' do
        unless session[:user].admin_check
            redirect '/unathourized'
        end
        @callback = request.path_info[0..-5]
        @booking_id = params['id'].to_i
        @rooms = DbBase.fetch_all(Room.new)
        @current_booking = DbBase.fetch_by_id(Booking.new, @booking_id)
      
        @times = {}
        @times['start_time'] = DateTime.strptime(@current_booking.start_time.to_s, '%s').to_s[0..-7]
        @times['end_time'] = DateTime.strptime(@current_booking.end_time.to_s, '%s').to_s[0..-7]      
        @current_booking_reservations = DbBase.fetch_where(RoomReservation.new, 'booking_id =', @booking_id)
        @rooms = DbBase.fetch_all(Room.new)
       
      

        
        slim :'bookings/edit'
    end

    post '/admin/requests/:id/accept/?' do
        unless session[:user].admin_check
            redirect '/unathourized'
        end
        Booking.accept(params['id'].to_i, session[:user])
        redirect back
    end

    post '/admin/requests/:id/deny/?' do
        unless session[:user].admin_check
            redirect '/unathourized'
        end
       
        Booking.deny(params['id'].to_i, session[:user])
        redirect back
    end

    get '/admin/rooms/?' do
        unless session[:user].admin_check
            redirect '/unathourized'
        end
        @all_rooms = DbBase.fetch_all(Room.new)

        slim :'admin/admin_rooms'
    end

    get '/admin/rooms/view/:id/?' do
        unless session[:user].admin_check
            redirect '/unathourized'
        end
        @current_room = DbBase.fetch_by_id(Room.new, params['id'])
    
        slim :'admin/admin_room_details'
    end

    get '/admin/rooms/view/:id/edit/?' do
        unless session[:user].admin_check
            redirect '/unathourized'
        end
        @current_room =DbBase.fetch_by_id(Room.new, params['id'])
        slim :'admin/admin_room_edit'
    end

    post '/admin/rooms/view/:id/delete' do 
        unless session[:user].admin_check
            redirect '/unathourized'
        end
        @current_room = DbBase.fetch_by_id(Room.new, params['id'])
        @current_room.delete
        redirect '/admin/rooms'
    end

    get '/admin/rooms/new/?' do
        unless session[:user].admin_check
            redirect '/unathourized'
        end
        slim :'admin/admin_room_new'
    end

    post '/admin/rooms/update/?' do
        unless session[:user].admin_check
            redirect '/unathourized'
        end
        if params[:prefilled] == "true"
            puts "Update"
            @room = DbBase.fetch_by_id(Room.new, params['id'])
            @room.name = params['name']
            @room.room_details = params['room_details']
            @room.save
         
        else
            puts "New"
            p params
            @room = Room.new
            params.each do |col, value| 
                unless col == "prefilled"
                    @room.public_send("#{col}=", value)
                end
            end
            @room.save
            puts "Success"
        end
        redirect '/admin/rooms/'
    end

    get '/admin/users/?' do
        unless session[:user].admin_check
            redirect '/unathourized'
        end
        @all_users = DbBase.fetch_all(User.new)
        @admin_users = DbBase.fetch_where(User.new, "role_id =", Role::ADMIN)
        @normal_users = DbBase.fetch_where(User.new, "role_id =", Role::USER)
        

        slim :'admin/admin_users'
    end

  
    post '/admin/users/demote/?' do
        unless session[:user].superadmin_check
            redirect '/unathourized'
        end
       
        @user = DbBase.fetch_by_id(User.new, params['user_id'])
        @user.role_id = Role::USER
        @user.save
        redirect back
    end
    post '/admin/users/promote/?' do
        unless session[:user].superadmin_check
            redirect '/unathourized'
        end
        @user = DbBase.fetch_by_id(User.new, params['user_id'])
        @user.role_id = Role::ADMIN
        @user.save
        redirect back
    end

    get '/requests/?' do
        @current_users_bookings = DbBase.fetch_where(Booking.new, "placed_by =", session[:user].id)
        
        @current_users_bookings.each do |booking|
            booking.start_time = DateTime.strptime(booking.start_time.to_s, '%s').to_s[0...-9].gsub('T',' ')
            booking.end_time = DateTime.strptime(booking.end_time.to_s, '%s').to_s[0...-9].gsub('T',' ')
        end
       
        @current_users_reservations = []
        @current_users_bookings.each do |booking|
            reservations = DbBase.fetch_where(RoomReservation.new, "booking_id =", booking.id)
           
            if @current_users_reservations.length <= 1
                @current_users_reservations = reservations
            else
                reservations.each do |res|
                    @current_users_reservations << res
                end
            end
        end
        @rooms = DbBase.fetch_all(Room.new)
        p @current_users_reservations

        slim :'user/requests'
    end

    get '/requests/new/date/?' do
        
        slim :'bookings/new'
    end

    post '/requests/date-select/?' do
        session[:selected_date] = params[:booking_date]
        date_start = session[:selected_date] + "T00:00:00"
        date_end = session[:selected_date] + "T23:59:59" 
        date_start_compare = DateTime.parse(date_start).to_time.to_i
        date_end_compare = DateTime.parse(date_end).to_time.to_i
     
        session[:overlapping_bookings] = Booking.overlap?(date_start_compare, date_end_compare)

        redirect '/requests/new/details'
    end

    get '/requests/new/details/?' do
      
        @booked_timestrokes = []
        booked_timestrokes_datetime = []
        if session[:overlapping_bookings].is_a?(Array) && session[:overlapping_bookings].length > 0
            session[:overlapping_bookings].each do |booking|
                timestroke = booking.start_time
                while timestroke < booking.end_time
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
           
        end

        @rooms = DbBase.fetch_all(Room.new)
        slim :'bookings/new_details'
    end

    post '/requests/update/?' do
        date = session[:selected_date]
        start_time = DateTime.parse("#{date}T#{params[:start_time]}:00").to_time.to_i
        end_time = DateTime.parse("#{date}T#{params[:end_time]}:00").to_time.to_i
      
        if params[:prefilled] == "true"
            @db.transaction 
                puts "update"
              
                overlap = Booking.overlap?(start_time, end_time)           
                puts "overlap:"
                p overlap
                booking_id = params['booking_id'].to_i
                if !overlap.empty?
                    if overlap.length != 1
                        puts "it's an overlap!"
                        flash[:overlap] = "Your selected time overlaps with another. Please choose another time."
                        redirect back
                    else
                        if overlap.first.id == booking_id
                            p "the overlap is itself"
                        else
                            puts "it's an overlap!"
                            flash[:overlap] = "Your selected time overlaps with another. Please choose another time."
                            redirect back
                        end
                    end
                end

                @updated_booking = DbBase.fetch_by_id(Booking.new, params[:booking_id])
                @updated_booking.details = params[:details]
                @updated_booking.start_time = start_time
                @updated_booking.end_time = end_time
                @updated_booking.save

                room_reservations = DbBase.fetch_where(RoomReservation.new, "booking_id =", @updated_booking.id)
                room_reservations.each { |reservation| reservation.delete }

                params['select_room'].each do |room_id|
                    new_reservation = RoomReservation.new
                    new_reservation.booking_id = @updated_booking.id
                    new_reservation.room_id = room_id
                    new_reservation.save
                end
            @db.commit
        else
            puts "new"
            current_time = Date.today.to_s
            p params
            overlap = Booking.overlap?(start_time, end_time)
            puts "overlap:"
            if !overlap.empty?
                puts "it's an overlap!"
                flash[:overlap] = "Your selected time overlaps with another"  
                redirect back
            end

            @db.transaction
                new_booking = Booking.new
                new_booking.details = params['details']
                new_booking.placed_by = session[:user].id
                new_booking.status_id = Status::PENDING
                new_booking.start_time = start_time
                new_booking.end_time = end_time
                new_booking.save
                new_booking_id = Booking.fetch_latest.id
                p params
                params['select_room'].each do |room_id|
                    new_reservation = RoomReservation.new
                    new_reservation.booking_id = new_booking_id
                    new_reservation.room_id = room_id
                    new_reservation.save
                end
            @db.commit
        end
        puts "success"
        redirect params['callback']
    end
    
    
    
end