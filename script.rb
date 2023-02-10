TRUE = 1
FALSE = 0

ADDED = 1
REMOVED = 0

SCRIPT = 0
VERSION = 1

class ScriptEdit
  def initialize(char, script, edit)
    @char = char
    @script = script
    @edit = edit
  end

  attr_accessor :char
  attr_accessor :script
  attr_accessor :edit
end

class ScriptManager
  def initialize(db)
    @db = db
  end

  def [](index)
    data = @db.execute("SELECT id FROM scripts")
    return Script.new(@db, data[index]["id"])
  end

  def create(owner_id, name, is_public, character_ids)
    data = @db.execute("INSERT INTO scripts (owner_id, name, public) VALUES (?, ?, ?) RETURNING id", owner_id, name, is_public)
    
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
  end

  def characters()
    data = @db.execute("SELECT id FROM characters WHERE id IN (SELECT character_id FROM script_character_rel WHERE script_id = ?)", @id)

    return data.map{|char| Character.new(@db, char["id"])}
  end

  def forks()
    data = @db.execute("SELECT id FROM scripts WHERE source_id = ?", @id)
    
    return data.map{|script| Script.new(@db, script["id"])}
  end

  def edits()
    data = @db.execute("SELECT * FROM script_edits WHERE script_id = ?", @id)

    return data.map{|edit| ScriptEdit.new(edit.character_id, edit.script_id, edit.edit)}
  end

  attr_accessor :id
end