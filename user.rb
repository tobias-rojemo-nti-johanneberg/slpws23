require 'bcrypt'
require 'securerandom'

PERMS = [:USER, :MODERATOR, :ADMIN, :NO_LOGIN]

Sessions = SQLite3::Database.new(":memory:")
Sessions.results_as_hash = true
Sessions.execute("CREATE TABLE sessions (id INTEGER PRIMARY KEY, session TEXT) STRICT, WITHOUT ROWID")

class UserManager
  def initialize(db)
    @db = db
  end

  def is_taken(name)
    @data = @db.execute("SELECT id FROM users WHERE username = ?")

    p @data

    return !@data.empty?
  end

  def register(name, pass, perms = 0)
    if self.is_taken(name)
      return nil
    end

    @digest = BCrypt::Password.create(pass)

    @data = @db.execute("INSERT INTO users (username, pass, perms) VALUES (?, ?, ?) RETURNING id", name, @digest, perms)

    return User.new(@db, @data[0]["id"])
  end

  def login(name, pass)
    @data = @db.execute("SELECT id, pass FROM users WHERE username = ? LIMIT 1", name)

    digest = @data[0]["pass"]

    if BCrypt::Password.new(digest) == pass
      session = SecureRandom.hex
      @session_data = Sessions.execute("INSERT INTO sessions (id, session) VALUES (?, ?)", @data[0]["id"], session)

      return session
    end
  end

  def from_session(session)
    @data = Sessions.execute("SELECT id FROM sessions WHERE session = ? LIMIT 1", session)

    if @data.empty?
      return nil
    end

    return User.new(@db, @data[0]["id"])
  end
end

class User
  def initialize(db, id)
    @db = db
    @id = id
    @data = @db.execute("SELECT username, perms, pfp FROM users WHERE id = ? LIMIT 1", @id)
    @name = @data[0]["username"]
    @perms = @data[0]["perms"]
    @pfp = @data[0]["pfp"]
  end

  attr_accessor :id
  attr_accessor :name
  attr_accessor :perms
  attr_accessor :pfp
end