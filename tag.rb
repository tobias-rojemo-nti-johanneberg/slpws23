require_relative 'character'

class Tag
  def initialize(db, type, value)
    @db = db
    @type = type
    @value = value
  end

  def characters(same_value)
    data = nil
    if same_value
      data = @db.execute("SELECT id FROM characters WHERE id IN (SELECT character_id FROM tags WHERE tag_type_id = ? AND value = ?)", @type, @value)
    else
      data = @db.execute("SELECT id FROM characters WHERE id IN (SELECT character_id FROM tags WHERE tag_type_id = ?)", @type)
    end

    return data.map{|char| Character.new(@db, char["id"])}
  end

  def to_s()
    type_name = db.execute("SELECT name FROM tag_types WHERE id = ?", @type)

    return `#{type_name[0].name}:@value`
  end

  attr_accessor :id
end