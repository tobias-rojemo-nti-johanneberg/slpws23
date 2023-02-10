require_relative 'tag'

CHARACTER_TYPES = [:townsfolk, :outsider, :minion, :demon, :traveller, :fabled]

class CharacterManager
  def initialize(db)
    @db = db
  end

  def [](index)
    data = @db.execute("SELECT id FROM characters")
    return Character.new(@db, data[index]["id"])
  end

  def create(owner_id, name, is_public, type, ability, first_night, other_nights)
    data = @db.execute("INSERT INTO characters (owner_id, name, public, type, ability, first_night, other_nights) VALUES (?, ?, ?, ?, ?, ?, ?) RETURNING id", owner_id, name, is_public, type, ability, first_night, other_nights)
    return Character.new(@db, data[0]["id"])
  end
end

class Character
  def initialize(db, id)
    @db = db
    @id = id
    @data = @db.execute("SELECT * FROM characters WHERE id = ?", @id)
    @tags = @db.execute("SELECT tag_type_id, value FROM tags WHERE character_id = ?", @id)
  end

  def tags
    @tags.map{|tag_data| Tag.new(@db, tag_data.type, tag_data.value)}
  end

  attr_accessor :id
end