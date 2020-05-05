require_relative 'dbbase.rb'

# Handles the different roles of the users.
class Role < DbBase
    
    # Public: Integer of the value the superadmin role has.
    SUPERADMIN = 1
    
    # Public: Integer of the value the admin role has.
    ADMIN = 2

    # Public: Integer of the value the user role has.
    USER = 3

end