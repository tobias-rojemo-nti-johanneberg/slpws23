require 'sqlite3'

require_relative 'tag'
require_relative 'character'
require_relative 'script'
require_relative 'user'

class Database
  def initialize
    @db = SQLite3::Database.new("db/data.sqlite")
    @db.results_as_hash = true
  end

  def characters = CharacterManager.new(@db)
  def scripts = ScriptManager.new(@db)
  def users = UserManager.new(@db)
  def tags = TagTypeManager.new(@db)
end