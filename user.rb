require 'bcrypt'
require 'securerandom'

USER = 0
MODERATOR = 1
ADMIN = 2
NO_LOGIN = 3

# An in-memory session store
Sessions = SQLite3::Database.new(":memory:")
Sessions.results_as_hash = true
Sessions.execute("CREATE TABLE sessions (id INTEGER PRIMARY KEY, session TEXT) STRICT, WITHOUT ROWID")

# Manages user login and registering, as well as the session store
class UserManager
  # @param db [SQLite3::Database]
  def initialize(db)
    @db = db
  end

  # Return true if a name is already taken
  # @param name [String]
  # @return [Bool]
  def is_taken(name)
    @data = @db.execute("SELECT id FROM users WHERE username = ?")
    return @data.any?
  end

  # Creates a new account
  # @param name [String]
  # @param pass [String]
  # @param perms [Int = 0]
  # @return [User] if successfully created
  # @return [nil] if account name is taken
  def register(name, pass, perms = 0)
    if self.is_taken(name)
      return nil
    else
      @digest = BCrypt::Password.create(pass)
      @data = @db.execute("INSERT INTO users (username, pass, perms) VALUES (?, ?, ?) RETURNING id", name, @digest, perms)
      
      return User.new(@db, @data[0]["id"])
    end
  end

  # Logs in to account with specified name and pass
  # @param name [String]
  # @param pass [String]
  # @return [User] if successful login
  # @return [nil] if account does not exist
  def login(name, pass)
    @data = @db.execute("SELECT id, pass FROM users WHERE username = ? LIMIT 1", name)
    return nil unless @data.size == 1
    digest = @data[0]["pass"]

    if BCrypt::Password.new(digest) == pass
      session = SecureRandom.hex
      @session_data = Sessions.execute("INSERT INTO sessions (id, session) VALUES (?, ?)", @data[0]["id"], session)

      return session
    end
  end

  # Removes a session from the store
  # @param session [Hex]
  # @return [void]
  def logout(session)
    Sessions.execute("DELETE FROM sessions WHERE session = ?", session)
  end

  # Fetches a User from session id
  # @param session [Hex]
  # @return [User] if existing session
  # @return [nil] if not
  def from_session(session)
    @data = Sessions.execute("SELECT id FROM sessions WHERE session = ? LIMIT 1", session)

    if @data.empty?
      return nil
    end

    return User.new(@db, @data[0]["id"])
  end

  # Fetches users from the database
  # @note Fetches all users if no ids were given
  # @param ids [Int, Array<Int>, nil]
  # @return [User] if single id was given
  # @return [Array<User>] if none or multiple ids were given
  def get(*ids)
    if ids.size == 0
      @data = @db.execute("SELECT id FROM users ORDER BY username ASC")
      return @data.map{|user| User.new(@db, user["id"])}
    elsif ids.size == 1
      @data = @db.execute("SELECT id FROM users WHERE id = ? LIMIT 1", ids[0])
      return User.new(@db, @data[0]["id"]) unless @data.size == 0
    else
      @data = @db.execute("SELECT id FROM users ORDER BY title ASC")
      return @data.filter{|user| ids.include(user.id)}.map{|user| User.new(@db, user["id"])}
    end
  end

  # Alias of get
  # @see UserManager#get
  def [](*ids) = self.get(ids)

  # Iterates over all users
  # @param [Block] &block
  # @yield [User]
  # @return [void]
  def each
    self.get.each do |user|
      yield user
    end
  end
end

# The data associated with a user, as well as methods to modify it
class User
  # @param db [SQLite3::Database]
  # @param id [Int]
  def initialize(db, id)
    @db = db
    @id = id
    @data = @db.execute("SELECT username, perms, pfp FROM users WHERE id = ? LIMIT 1", @id)
    @name = @data[0]["username"]
    @perms = @data[0]["perms"]
    @pfp = @data[0]["pfp"]
  end

  # All scripts created by the user
  # @return [Array<Script>]
  def scripts
    @data = @db.execute("SELECT id FROM scripts WHERE author_id = ? ORDER BY title ASC", @id)
    return @data.map{|script| Script.new(@db, script["id"])}
  end

  # All characters created by the user
  # @return [Array<Character>]
  def characters
    @data = @db.execute("SELECT id FROM characters WHERE author_id = ? ORDER BY name ASC", @id)
    return @data.map{|char| Character.new(@db, char["id"])}
  end

  # Deletes a user
  # @return [void]
  def delete
    @db.execute("DELETE FROM users WHERE id = ?", @id)
  end

  # Whether a user has the specified perm level or above
  # @param perm_level [Int]
  # @return [Bool]
  def has_perms?(perm_level) = perm_level <= @perms

  attr_accessor :id
  attr_accessor :name
  attr_accessor :perms
  attr_accessor :pfp
end