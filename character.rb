require_relative 'tag'
require_relative 'user'
require_relative 'script'

CHARACTER_TYPES = [:townsfolk, :outsider, :minion, :demon, :traveller, :fabled]

class CharacterManager
  def initialize(db)
    @db = db
  end

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

  def count = @db.execute("SELECT id FROM characters").size

  def each
    self.get.each do |character|
      yield character
    end
  end

  def create(author_id, name, is_public, type, ability)
    data = @db.execute("INSERT INTO characters (author_id, name, is_public, type, ability) VALUES (?, ?, ?, ?, ?) RETURNING id", author_id, name, is_public, type, ability)
    return Character.new(@db, data[0]["id"])
  end
end

class Character
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
    @is_public = @data[0]["is_public"]
  end

  def scripts
    @data = @db.execute("SELECT id FROM scripts WHERE id IN (SELECT script_id FROM script_character_rel WHERE character_id = ?)", @id)
    return @data.map {|script| Script.new(@db, script["id"])}
  end

  def tags
    @tags = @db.execute("SELECT tag_type_id, value FROM tags WHERE character_id = ?", @id)
    @tags.map{|tag_data| Tag.new(@db, tag_data["tag_type_id"], tag_data["value"])}
  end

  def comments
    @comments = @db.execute("SELECT id FROM character_comments WHERE character_id = ? ORDER BY id DESC", @id)
    @comments.map{|comment_data| CharacterComment.new(@db, comment_data["type"], comment_data["value"])}
  end

  def update(name, is_public, type, ability)
    return unless is_public != false || !@is_public || self.scripts.empty?

    @db.execute("UPDATE characters SET name = ?, is_public = ?, type = ?, ability = ? WHERE id = ?",
      name != nil ? name : @name,
      is_public != nil ? (is_public ? TRUE : FALSE) : @is_public,
      type != nil ? type : @type,
      ability != nil ? ability : @ability,
      @id
    )
  end

  def delete = @db.execute("DELETE FROM characters WHERE id = ?", @id)
  def has_img? = File.exists?("public/img/c#{@id}.png")
  def img = "/img/c#{@id}.png"

  attr_accessor :id
  attr_accessor :name
  attr_accessor :type_id
  attr_accessor :type
  attr_accessor :ability
  attr_accessor :author
  attr_accessor :author_id
  attr_accessor :is_public
end

class CharacterComment
  def initialize(db, id)
    @db = db
    @id = id
    @data = @db.execute("SELECT character_id, author_id, content, created FROM character_comments WHERE id = ? LIMIT 1", @id)
    @character_id = @data[0]["character_id"]
    @author_id = @data[0]["author_id"]
    @content = @data[0]["content"]
    @created = @data[0]["created"]
  end

  def character = Character.new(@db, @character_id)
  def character_name = @db.execute("SELECT name FROM characters WHERE id = ? LIMIT 1", @character_id)[0]["name"]
  def author = User.new(@db, @author_id)
  def author_name = @db.execute("SELECT username FROM characters WHERE id = ? LIMIT 1", @character_id)[0]["username"]

  attr_accessor :id
  attr_accessor :content
  attr_accessor :created
end