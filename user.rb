PERMS = [:USER, :MODERATOR, :ADMIN, :NO_LOGIN]

class UserManager
  def initialize(db)
    @db = db
  end

  def register(name, pass, perms)
    data = @db.execute("INSERT INTO users (name, pass, perms) VALUES (?, ?, ?) RETURNING id", name, pass, perms)
    
    return User.new(@db, data[0]["id"])
  end
end

class User
  def initialize(db, id)
    @db = db
    @id = id
  end

  attr_accessor :id
end