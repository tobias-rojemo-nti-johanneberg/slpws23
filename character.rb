require_relative 'tag'
require_relative 'user'
require_relative 'script'

CHARACTER_TYPES = [:townsfolk, :outsider, :minion, :demon, :traveller, :fabled]
TOWNSFOLK = 0
OUTSIDER = 1
MINION = 2
DEMON = 3
TRAVELLER = 4
FABLED = 5

# Manages fetching and creation of characters
class CharacterManager
  # @param db [SQLite3::Database]
  def initialize(db)
    @db = db
  end

  # Fetches characters from the database
  # @note Fetches all characters if no ids were given
  # @param ids [Int, Array<Int>, nil]
  # @return [Character] if single id was given
  # @return [Array<Character>] if none or multiple ids were given
  def get(*ids)
    if ids.size == 0
      @data = @db.execute("SELECT id FROM characters ORDER BY name ASC")
      return @data.map{|character| Character.new(@db, character["id"])}
    elsif ids.size == 1
      @data = @db.execute("SELECT id FROM characters WHERE id = ? LIMIT 1", ids[0])
      return Character.new(@db, @data[0]["id"]) unless @data.size == 0
    else
      @data = @db.execute("SELECT id FROM characters ORDER BY name ASC")
      return @data.filter{|character| ids.include?(character["id"])}.map{|character| Character.new(@db, character["id"])}
    end
  end

  # Alias of get
  # @see CharacterManager#get
  def [](*ids) = self.get(ids)
  
  # Iterates over all characters and keeps true matches
  # @param &block [Block]
  # @return [Array<Character>]
  def filter(&block) = self.get.filter &block

  # Iterates over all characters
  # @param &block [Block]
  # @yield [Character]
  # @return [void]
  def each
    self.get.each do |character|
      yield character
    end
  end

  # Creates a character
  # @param author_id [Int]
  # @param name [String]
  # @param is_public [Bool]
  # @param type [Int]
  # @param ability [String]
  # @return [Character]
  def create(author_id, name, is_public, type, ability)
    data = @db.execute("INSERT INTO characters (author_id, name, is_public, type, ability) VALUES (?, ?, ?, ?, ?) RETURNING id", author_id, name, is_public ? TRUE : FALSE, type, ability)
    return Character.new(@db, data[0]["id"])
  end
end

# The data associated with a character, as well as methods to modify it
class Character
  # @param db [SQLite3::Database]
  # @param id [Int]
  def initialize(db, id)
    @db = db
    @id = id
    @data = @db.execute("SELECT name, type, ability, username, author_id, is_public FROM characters INNER JOIN users ON characters.author_id = users.id WHERE characters.id = ? LIMIT 1", @id)
    @name = @data[0]["name"]
    @type_id = @data[0]["type"]
    @type = CHARACTER_TYPES[@type_id]
    @ability = @data[0]["ability"]
    @author = @data[0]["username"]
    @author_id = @data[0]["author_id"]
    @is_public = @data[0]["is_public"] > 0
  end

  # All scripts containing this character
  # @return [Array<Script>]
  def scripts
    @data = @db.execute("SELECT id FROM scripts WHERE id IN (SELECT script_id FROM script_character_rel WHERE character_id = ?)", @id)
    return @data.map {|script| Script.new(@db, script["id"])}
  end

  # All tags this character has
  # @return [Array<Tag>]
  def tags
    @tags = @db.execute("SELECT tag_type_id, value FROM tags WHERE character_id = ?", @id)
    @tags.map{|tag_data| Tag.new(@db, tag_data["tag_type_id"], tag_data["value"])}
  end

  # All comments on this character
  # @return [Array<CharacterComment>]
  def comments
    @comments = @db.execute("SELECT id FROM character_comments WHERE character_id = ? ORDER BY id DESC", @id)
    @comments.map{|comment_data| CharacterComment.new(@db, comment_data["id"])}
  end

  # Updates one or more attributes of a character
  # @note Leave a field as nil to not modify it
  # @param name [String, nil]
  # @param is_public [Bool, nil]
  # @param type [Int, nil]
  # @param ability [String, nil]
  # @return [void]
  def update(name, is_public, type, ability)
    return unless is_public != false || !@is_public || self.scripts.none? {|script| script.is_public}

    @db.execute("UPDATE characters SET name = ?, is_public = ?, type = ?, ability = ? WHERE id = ?",
      name != nil ? name : @name,
      is_public != nil ? (is_public ? TRUE : FALSE) : (@is_public ? TRUE : FALSE),
      type != nil ? type : @type,
      ability != nil ? ability : @ability,
      @id
    )
  end

  # Create a comment on a character
  # @param author_id [Int]
  # @param content [String]
  # @return [void]
  def comment(author_id, content)
    @db.execute("INSERT INTO character_comments (author_id, character_id, content) VALUES (?, ?, ?)", author_id, @id, content)
  end

  # Deletes a character if possible
  # @return [void]
  def delete 
    return unless self.scripts.empty?
    @db.execute("DELETE FROM characters WHERE id = ?", @id)
  end

  # Compares self with another object
  # @param other [Any]
  # @return [Bool]
  def ==(other) = @id == other.id

  # Checks if the character has an image
  # @return [Bool]
  def has_img? = File.exists?("public/img/c#{@id}.png")
  
  # Returns the path for the image
  # @return [String]
  def img = "/img/c#{@id}.png"

  # Returns if the character should be shown for the specified user
  # @param user [User]
  # @return [Bool]
  def can_see?(user) = @is_public || (user && (user.id == @author_id || user.has_perms?(MODERATOR)))

  attr_accessor :id
  attr_accessor :name
  attr_accessor :type_id
  attr_accessor :type
  attr_accessor :ability
  attr_accessor :author
  attr_accessor :author_id
  attr_accessor :is_public
end

# Data class for a comment on a character
class CharacterComment
  # @param db [SQLite::Database]
  # @param id [Int]
  def initialize(db, id)
    @db = db
    @id = id
    @data = @db.execute("SELECT character_id, author_id, content, created FROM character_comments WHERE id = ? LIMIT 1", @id)
    @character_id = @data[0]["character_id"]
    @author_id = @data[0]["author_id"]
    @content = @data[0]["content"]
    @created = @data[0]["created"]
  end

  # The author of the comment
  # @return [User]
  def author = User.new(@db, @author_id)
  
  # The username of the author of the comment
  # @return [String]
  def author_name = @db.execute("SELECT username FROM users WHERE id = ? LIMIT 1", @author_id)[0]["username"]

  attr_accessor :id
  attr_accessor :content
  attr_accessor :created
end