require 'sqlite3'
require 'bcrypt'

require_relative 'tag'
require_relative 'character'
require_relative 'script'
require_relative 'user'

class Database
  def initialize
    @db = SQLite3::Database.new("db/data.sqlite")
    @db.results_as_hash = true
  end

  def characters
    return CharacterManager.new(@db)
  end

  def scripts
    return ScriptManager.new(@db)
  end

  def users
    return UserManager.new(@db)
  end
end