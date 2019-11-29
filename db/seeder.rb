require 'sqlite3'
require 'bcrypt'

class Seeder
    
    def self.seed!
        db = connect
        drop_tables(db)
        create_tables(db)
        populate_tables(db)
    end
    
    def self.connect
        db = SQLite3::Database.new 'opal_booking.db'
        db.results_as_hash = true
        return db
    end
    
    def self.drop_tables(db)
        db.execute('DROP TABLE IF EXISTS users;')
        db.execute('DROP TABLE IF EXISTS roles;')
        db.execute('DROP TABLE IF EXISTS booking;')
        db.execute('DROP TABLE IF EXISTS status;')
        db.execute('DROP TABLE IF EXISTS reservation;')
        db.execute('DROP TABLE IF EXISTS room;')
    end
    
    def self.create_tables(db)
        
        db.execute <<-SQL
        CREATE TABLE "users" (
            "id"	INTEGER,
            "name"	TEXT NOT NULL UNIQUE,
            "mail"	TEXT NOT NULL UNIQUE,
            "pwd_hash"	TEXT NOT NULL UNIQUE,
            "role_id"	INTEGER NOT NULL,
            PRIMARY KEY("id")
            );
        SQL
            
        db.execute <<-SQL
        CREATE TABLE "roles" (
            "id"	INTEGER,
            "name"	TEXT NOT NULL UNIQUE,
            PRIMARY KEY("id")
            );
        SQL
        db.execute <<-SQL
        CREATE TABLE "booking" (
            "id"	INTEGER,
            "details"	TEXT,
            "placed_at"	TEXT,
            "placed_by"	INTEGER,
            "answered_by" INTEGER,
            "status_id"	INTEGER,
            PRIMARY KEY("id")
        );
        SQL
        db.execute <<-SQL
        CREATE TABLE "reservation" (
            "id"	INTEGER,
            "start_time"	TEXT,
            "end_time"	TEXT,
            "booking_id"	INTEGER,
            "room_id"	INTEGER,
            PRIMARY KEY("id")
        );
        SQL
        db.execute <<-SQL
        CREATE TABLE "room" (
            "id"	INTEGER,
            "name"	TEXT NOT NULL,
            PRIMARY KEY("id")
        );
        SQL

        db.execute <<-SQL
        CREATE TABLE "status" (
            "id"	INTEGER,
            "name"	TEXT,
            PRIMARY KEY("id")
        );
        SQL
            
    end

    def self.populate_tables(db)
        users = [
            {
                name: "admin",
                mail: "admin@opalkyrkan.se",
                pwd_hash:BCrypt::Password.create('admin01'),
                role_id: 1
            },
            {
                name: "test_user",
                mail: "tester@flaskpost.se",
                pwd_hash:BCrypt::Password.create('test01'),
                role_id: 3
            }
        ]

        roles = [
            {name:"super_admin"},
            {name:"admin"},
            {name:"user"},
            {name:"guest"}
        ]

        bookings = [
            {
                details:"unanswered booking",
                placed_at:"some date",
                placed_by: 2,
                status_id: 1
            },
            {
                details:"answered booking 2",
                placed_at:"another date",
                placed_by: 2,
                answered_by: 1,
                status_id: 2
            }
        ]

        status = [
            {name:"pending"},
            {name:"accepted"},
            {name:"denied"}
        ]

        reservations = [
            {
                start_time:"08:20",
                end_time:"16:50",
                booking_id: 1,
                room_id: 1
            },
            {
                start_time:"08:20",
                end_time:"16:50",
                booking_id: 1,
                room_id: 2
            },
            {
                start_time:"08:20",
                end_time:"16:50",
                booking_id: 2,
                room_id: 3
            }
        ]

        rooms = [
            {name:"gympasal"},
            {name:"kök"},
            {name:"omklädningsrum"}
        ]

        users.each do |user|
            db.execute("INSERT INTO users (name, mail, pwd_hash, role_id) VALUES(?,?,?,?)", user[:name], user[:mail], user[:pwd_hash], user[:role_id])
        end

        roles.each do |role| 
            db.execute("INSERT INTO roles (name) VALUES(?)", role[:name])
        end
        
        bookings.each do |booking|
            p booking[:answered_by]
            db.execute("INSERT INTO booking (details, placed_at, placed_by, answered_by, status_id) VALUES(?,?,?,?,?)", booking[:details], booking[:placed_at], booking[:placed_by], booking[:answered_by], booking[:status_id])
        end
        
        status.each do |status|
            db.execute("INSERT INTO status (name) VALUES(?)", status[:name])
        end
        
        reservations.each do |res|
            db.execute("INSERT INTO reservation (start_time, end_time, booking_id, room_id) VALUES(?,?,?,?)", res[:start_time], res[:end_time], res[:booking_id], res[:room_id])
        end
        
        rooms.each do |room|
            db.execute("INSERT INTO room (name) VALUES(?)", room[:name])
        end

    end
end
        
        
Seeder.seed!