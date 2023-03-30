TRUE = 1
FALSE = 0
ADDED = 1
REMOVED = 0

class ScriptManager
  def initialize(db)
    @db = db
  end

  def get(*ids)
    if ids.size == 0
      @data = @db.execute("SELECT id FROM scripts ORDER BY title ASC")
      return @data.map{|script| Script.new(@db, script["id"])}
    elsif ids.size == 1
      @data = @db.execute("SELECT id FROM scripts WHERE id = ? LIMIT 1", ids[0])
      return Script.new(@db, @data[0]["id"]) unless @data.size == 0
    else
      @data = @db.execute("SELECT id FROM scripts ORDER BY title ASC")
      return @data.filter{|script| ids.include(script.id)}.map{|script| Script.new(@db, script["id"])}
    end
  end

  def [](*ids) = self.get(ids)
  def count = @db.execute("SELECT id FROM scripts").size

  def each
    self.get.each do |script|
      yield script
    end
  end

  def create(author_id, title, is_public)
    data = @db.execute("INSERT INTO scripts (author_id, title, is_public) VALUES (?, ?, ?) RETURNING id", author_id, title, is_public ? TRUE : FALSE)
    return Script.new(@db, data[0]["id"])
  end
end

class Script
  def initialize(db, id)
    @db = db
    @id = id

    @data = @db.execute("SELECT username, title, source_id, author_id, is_public FROM scripts INNER JOIN users ON scripts.author_id = users.id WHERE scripts.id = ? LIMIT 1", @id)

    @source_id = @data[0]["source_id"]
    @title = @data[0]["title"]
    @author = @data[0]["username"]
    @author_id = @data[0]["author_id"]
    @is_public = @data[0]["is_public"]
  end

  def characters
    @data = @db.execute("SELECT id FROM characters WHERE id IN (SELECT character_id FROM script_character_rel WHERE script_id = ?) ORDER BY type, name ASC", @id)
    return @data.map{|char| Character.new(@db, char["id"])}
  end

  def featured
    @data = @db.execute("SELECT id FROM characters WHERE id IN (SELECT character_id FROM script_character_rel WHERE script_id = ? AND featured = 1) ORDER BY type, name ASC LIMIT 3", @id)
    return @data.map{|char| Character.new(@db, char["id"])}
  end

  def forks
    @data = @db.execute("SELECT id FROM scripts WHERE source_id = ?", @id)
    return @data.map{|script| Script.new(@db, script["id"])}
  end

  def comments
    @comments = @db.execute("SELECT id FROM script_comments WHERE script_id = ? ORDER BY id DESC", @id)
    @comments.map{|comment_data| ScriptComment.new(@db, comment_data["id"])}
  end

  def delete
    return unless self.forks.empty?
    @db.execute("DELETE FROM scripts WHERE id = ?", @id)
  end

  def fork(author_id)
    @data = @db.execute("INSERT INTO scripts (title, author_id, is_public, source_id) VALUES (?, ?, 0, ?) RETURNING id", "Fork of #{self.title}", author_id, @id)
    @fork = Script.new(@db, @data[0]["id"])
    @db.execute("INSERT INTO script_character_rel (character_id, script_id, featured) SELECT character_id, ?, featured FROM script_character_rel WHERE script_character_rel.script_id = ?", @fork.id, @id)
    return @fork
  end

  def update(title, is_public)
    return unless is_public != false || !@is_public || self.forks.empty?

    @db.execute("UPDATE scripts SET title = ?, is_public = ? WHERE id = ?",
      title != nil ? title : @title,
      is_public != nil ? (is_public ? TRUE : FALSE) : @is_public,
      @id
    )
  end

  def comment(author_id, content)
    @db.execute("INSERT INTO script_comments (author_id, script_id, content) VALUES (?, ?, ?)", author_id, @id, content)
  end

  def add(char_id) = @db.execute("INSERT INTO script_character_rel (script_id, character_id) VALUES (?, ?)", @id, char_id)
  def remove(char_id) = @db.execute("DELETE FROM script_character_rel WHERE script_id = ? AND character_id = ?", @id, char_id)
  def feature(char_id) = @db.execute("UPDATE script_character_rel SET featured = 1 WHERE script_id = ? AND character_id = ?", @id, char_id)
  def unfeature(char_id) = @db.execute("UPDATE script_character_rel SET featured = 0 WHERE script_id = ? AND character_id = ?", @id, char_id)
  def include?(char) = self.characters.include?(char)
  def features?(char) = self.featured.include?(char)
  def ==(other) = @id == other.id
  def source = @source_id ? Script.new(@db, @source_id) : nil
  def origin = @source_id ? self.source.origin : self
  def edits = self.source ? self.characters.filter {|char| !self.source.characters.include?(char)}.map {|char| ScriptEdit.new(char, ADDED)}.concat(self.source.characters.filter {|char| !self.characters.include?(char)}.map {|char| ScriptEdit.new(char, REMOVED)}) : nil
  def edits_from_origin = self.origin != self ? self.characters.filter {|char| !self.origin.characters.include?(char)}.map {|char| ScriptEdit.new(char, ADDED)}.concat(self.origin.characters.filter {|char| !self.characters.include?(char)}.map {|char| ScriptEdit.new(char, REMOVED)}) : nil
  def compare(other) = self.characters.filter {|char| !other.characters.include?(char)}.map {|char| ScriptEdit.new(char, ADDED)}.concat(other.characters.filter {|char| !self.characters.include?(char)}.map {|char| ScriptEdit.new(char, REMOVED)})

  attr_accessor :id
  attr_accessor :title
  attr_accessor :author
  attr_accessor :author_id
  attr_accessor :is_public
end

class ScriptComment
  def initialize(db, id)
    @db = db
    @id = id
    @data = @db.execute("SELECT script_id, author_id, content, created FROM script_comments WHERE id = ? LIMIT 1", @id)
    @script_id = @data[0]["script_id"]
    @author_id = @data[0]["author_id"]
    @content = @data[0]["content"]
    @created = @data[0]["created"]
  end

  def script = Script.new(@db, @script_id)
  def script_title = @db.execute("SELECT name FROM scripts WHERE id = ? LIMIT 1", @script_id)[0]["title"]
  def author = User.new(@db, @author_id)
  def author_name = @db.execute("SELECT username FROM users WHERE id = ? LIMIT 1", @author_id)[0]["username"]

  attr_accessor :id
  attr_accessor :content
  attr_accessor :created
end

class ScriptEdit
  def initialize(char, edit)
    @char = char
    @edit = edit
  end

  def img = "/img/#{self.alt}.svg"
  def alt = @edit == ADDED ? "added" : "removed"

  attr_accessor :char
  attr_accessor :edit
end