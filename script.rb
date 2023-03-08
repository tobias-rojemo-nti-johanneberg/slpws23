TRUE = 1
FALSE = 0

class ScriptManager
  def initialize(db)
    @db = db
  end

  def get(*ids)
    @data = @db.execute("SELECT id FROM scripts ORDER BY id DESC")
    if ids.size == 0
      return @data.map{|script| Script.new(@db, script["id"])}
    elsif ids.size == 1
      return Script.new(@db, @data[0]["id"])
    else
      return @data.filter{|script| ids.include(script.id)}.map{|script| Script.new(@db, script["id"])}
    end
  end

  def count()
    @data = @db.execute("SELECT id FROM scripts")
    return @data.size
  end

  def each
    @scripts = get()
    @scripts.each do |script|
      yield script
    end
  end

  def create(author_id, title, is_public, character_ids)
    data = @db.execute("INSERT INTO scripts (author_id, title, public) VALUES (?, ?, ?) RETURNING id", author_id, title, is_public)
    
    script_id = data[0]["id"]

    character_ids.each do |character|
      @db.execute("INSERT INTO script_character_rel (character_id, script_id) VALUES (?, ?)", character, script_id)
    end

    return Script.new(@db, script_id)
  end
end

class Script
  def initialize(db, id)
    @db = db
    @id = id

    @data = @db.execute("SELECT username, title FROM scripts INNER JOIN users ON scripts.author_id = users.id WHERE scripts.id = ? LIMIT 1", @id)

    @title = @data[0]["title"]
    @author = @data[0]["username"]
  end

  def characters()
    @data = @db.execute("SELECT id FROM characters WHERE id IN (SELECT character_id FROM script_character_rel WHERE script_id = ?)", @id)

    return @data.map{|char| Character.new(@db, char["id"])}
  end

  def forks()
    @data = @db.execute("SELECT id FROM scripts WHERE source_id = ?", @id)
    
    return @data.map{|script| Script.new(@db, script["id"])}
  end

  attr_accessor :id
  attr_accessor :title
  attr_accessor :author
end