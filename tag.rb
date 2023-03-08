require_relative 'character'

TRUE = 1

class TagTypeManager
  def initialize(db)
    @db = db
  end

  def get(*ids)
    @data = @db.execute("SELECT id FROM tag_types ORDER BY name ASC")
    if ids.size == 0
      return @data.map{|tag| TagType.new(@db, tag["id"])}
    elsif ids.size == 1
      return TagType.new(@db, @data[0]["id"])
    else
      return @data.filter{|tag| ids.include?(tag["id"])}.map{|tag| TagType.new(@db, tag["id"])}
    end
  end

  def count()
    @data = @db.execute("SELECT id FROM tag_types")
    return @data.size
  end

  def each
    @tags = get()
    @tags.each do |tag|
      yield tag
    end
  end
end

class TagType
  def initialize(db, type)
    @db = db
    @type = type
  end

  def characters
    data = @db.execute("SELECT id FROM characters WHERE id IN (SELECT character_id FROM tags WHERE tag_type_id = ?) ORDER BY name ASC", @type)
    
    return data.map{|char| Character.new(@db, char["id"])}
  end

  def to_s
    type_name = @db.execute("SELECT name FROM tag_types WHERE id = ?", @type)

    return type_name[0]["name"] 
  end
end

class Tag
  def initialize(db, type, value)
    @db = db
    @type = type
    @value = value

    @data = @db.execute("SELECT bg, text, display_value FROM tag_types WHERE id = ?", @type)

    @bg = @data[0]["bg"]
    @text = @data[0]["text"]
    @display_value = @data[0]["display_value"]
  end

  def characters(same_value)
    data = nil
    if same_value
      data = @db.execute("SELECT id FROM characters WHERE id IN (SELECT character_id FROM tags WHERE tag_type_id = ? AND value = ?) ORDER BY name ASC", @type, @value)
    else
      data = @db.execute("SELECT id FROM characters WHERE id IN (SELECT character_id FROM tags WHERE tag_type_id = ?) ORDER BY name ASC", @type)
    end

    return data.map{|char| Character.new(@db, char["id"])}
  end

  def to_s()
    type_name = @db.execute("SELECT name FROM tag_types WHERE id = ?", @type)

    return @display_value == TRUE ? "#{type_name[0]["name"]}:#{@value}" : type_name[0]["name"]
  end

  attr_accessor :type
  attr_accessor :value
  attr_accessor :bg
  attr_accessor :text
end