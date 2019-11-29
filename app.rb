class App < Sinatra::Base
    
    before do
        @current_user = 1
        @db = SQLite3::Database.new('db/opal_booking.db')
        @db.results_as_hash = true
    end
    
    get '/admin/requests' do
        all_bookings = @db.execute('SELECT * from booking
            JOIN status ON booking.status_id = status.id
            JOIN users ON booking.placed_by = users.id')

        @pending = all_bookings.select {|booking| booking['status_id'] == 1}
        @accepted = all_bookings.select {|booking| booking['status_id'] == 2}
        @denied = all_bookings.select {|booking| booking['status_id'] == 3}

        slim :admin_request
    end 

end