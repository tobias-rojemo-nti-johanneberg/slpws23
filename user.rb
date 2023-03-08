PERMS = [:USER, :MODERATOR, :ADMIN, :NO_LOGIN]

class UserManager
  def initialize(db)
    @db = db
  end

  def register(name, pass, perms)
    data = @db.execute("INSERT INTO users (username, pass, perms) VALUES (?, ?, ?) RETURNING id", name, pass, perms)
    
    return User.new(@db, data[0]["id"])
  end
end

class User
  def initialize(db, id)
    @db = db
    @id = id
    @data = @db.execute("SELECT name, perms WHERE id = ? LIMIT 1", @id)
    @name = @data[0]["name"]
    @perms = @data[0]["perms"]
  end

  attr_accessor :id
  attr_accessor :name
  attr_accessor :perms
end