TRUE = 1
FALSE = 0

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

  def count = @db.execute("SELECT id FROM scripts").size

  def each
    self.get.each do |script|
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

    @data = @db.execute("SELECT username, title, source_id, version_num, author_id FROM scripts INNER JOIN users ON scripts.author_id = users.id WHERE scripts.id = ? LIMIT 1", @id)

    @source_id = @data[0]["source_id"]
    @title = @data[0]["title"]
    @author = @data[0]["username"]
    @author_id = @data[0]["author_id"]
    @version_num = @data[0]["version_num"]
  end

  def characters
    @data = @db.execute("SELECT id FROM characters WHERE id IN (SELECT character_id FROM script_character_rel WHERE script_id = ?)", @id)
    return @data.map{|char| Character.new(@db, char["id"])}
  end

  def forks
    @data = @db.execute("SELECT id FROM scripts WHERE source_id = ?", @id)
    return @data.map{|script| Script.new(@db, script["id"])}
  end

  def comments
    @comments = @db.execute("SELECT id FROM script_comments WHERE script_id = ? ORDER BY id DESC", @id)
    @comments.map{|comment_data| ScriptComment.new(@db, comment_data["type"], comment_data["value"])}
  end

  def source = @source_id ? Script.new(@db, @source_id) : nil
  def origin = @source_id ? self.source.origin : self
  def has_img? = File.exists?("public/img/s#{@id}.png")
  def img = "/img/s#{@id}.png"
  def full_title = @version_num ? "#{@title} v#{@version_num}" : @title

  attr_accessor :id
  attr_accessor :title
  attr_accessor :author
  attr_accessor :author_id
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
  def author_name = @db.execute("SELECT username FROM scripts WHERE id = ? LIMIT 1", @script_id)[0]["username"]

  attr_accessor :id
  attr_accessor :content
  attr_accessor :created
end