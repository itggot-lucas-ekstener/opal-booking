require 'sqlite3'
require 'bcrypt'

class Seeder
    
    def self.seed!
        db = connect
        drop_tables(db)
        puts "Tables dropped"
        create_tables(db)
        puts "New tables created"
        populate_tables(db)
        puts "Tables populated"
    end
    
    def self.connect
        db = SQLite3::Database.new 'db/opal_booking.db'
        db.results_as_hash = true
        return db
    end
    
    def self.drop_tables(db)
        db.execute('DROP TABLE IF EXISTS users;')
        db.execute('DROP TABLE IF EXISTS roles;')
        db.execute('DROP TABLE IF EXISTS booking;')
        db.execute('DROP TABLE IF EXISTS status;')
        db.execute('DROP TABLE IF EXISTS room_reservation;')
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
            "start_time" TEXT,
            "end_time" TEXT,
            PRIMARY KEY("id")
        );
        SQL
        db.execute <<-SQL
        CREATE TABLE "room_reservation" (
            "booking_id"	INTEGER,
            "room_id"	INTEGER,
            PRIMARY KEY("booking_id","room_id")
        );
        SQL
        db.execute <<-SQL
        CREATE TABLE "room" (
            "id"	INTEGER,
            "name"	TEXT NOT NULL,
            "room_details" TEXT,
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
                status_id: 1,
                start_time: "2020-01-01T21:00",
                end_time: "2020-01-01T22:00"
            },
            {
                details:"answered booking 2",
                placed_at:"another date",
                placed_by: 2,
                answered_by: 1,
                status_id: 2,
                start_time: "2020-01-01T21:00",
                end_time: "2020-01-01T22:00"
            }
        ]

        status = [
            {name:"pending"},
            {name:"accepted"},
            {name:"denied"}
        ]

        reservations = [
            {
                booking_id: 1,
                room_id: 1
            },
            {
                booking_id: 1,
                room_id: 2
            },
            {
                booking_id: 2,
                room_id: 3
            }
        ]

        rooms = [
            {name:"gympasal", details:"Lorem ipsum dolor sit amet consectetur adipisicing elit. Unde nemo distinctio explicabo vitae ipsum culpa voluptatibus odio accusamus optio. Perspiciatis ea est deserunt veritatis commodi, non nobis reiciendis. Qui repudiandae ex praesentium fuga vel nulla odio, debitis veniam, enim obcaecati, fugiat ea! At veritatis, et libero asperiores velit corporis vitae!"},
            {name:"kök", details:"Ett kök kort sagt. Inte så mycket mer att säga :)"},
            {name:"omklädningsrum", details:"Bra att ha om man ska använda gympasalen. Finns dusch om man blir svettig."}
        ]

        users.each do |user|
            db.execute("INSERT INTO users (name, mail, pwd_hash, role_id) VALUES(?,?,?,?)", user[:name], user[:mail], user[:pwd_hash], user[:role_id])
        end

        roles.each do |role| 
            db.execute("INSERT INTO roles (name) VALUES(?)", role[:name])
        end
        
        bookings.each do |booking|
            # p booking[:answered_by]
            db.execute("INSERT INTO booking (details, placed_at, placed_by, answered_by, status_id, start_time, end_time) VALUES(?,?,?,?,?,?,?)", booking[:details], booking[:placed_at], booking[:placed_by], booking[:answered_by], booking[:status_id], booking[:start_time], booking[:end_time])
        end
        
        status.each do |status|
            db.execute("INSERT INTO status (name) VALUES(?)", status[:name])
        end
        
        reservations.each do |res|
            db.execute("INSERT INTO room_reservation (booking_id, room_id) VALUES(?,?)", res[:booking_id], res[:room_id])
        end
        
        rooms.each do |room|
            db.execute("INSERT INTO room (name, room_details) VALUES(?,?)", room[:name], room[:details])
        end

    end
end
        
        
Seeder.seed!
puts "All Done"