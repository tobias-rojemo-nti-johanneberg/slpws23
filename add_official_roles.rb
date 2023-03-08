require 'json'
require 'sqlite3'
require 'fileutils'

def type_name_to_id(name)
  case name
  when "townsfolk"
    0
  when "outsider"
    1
  when "minion"
    2
  when "demon"
    3
  when "traveler"
    4
  when "fabled"
    5
  else raise `Invalid type name #{name}`
  end
end

role_file = File.open("data/roles.json")
data = JSON.load(role_file)
role_file.close()

db = SQLite3::Database.new("db/data.sqlite")
db.results_as_hash = true

TABLE_QUERIES = [
  "CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT NOT NULL, pass TEXT, perms INTEGER NOT NULL) STRICT",
  "CREATE TABLE IF NOT EXISTS characters (id INTEGER PRIMARY KEY AUTOINCREMENT, author_id INTEGER NOT NULL, name TEXT NOT NULL, public INTEGER NOT NULL, type INTEGER NOT NULL, ability TEXT NOT NULL, first_night REAL NOT NULL, other_nights REAL NOT NULL, FOREIGN KEY (author_id) REFERENCES users(id)) STRICT",
  "CREATE TABLE IF NOT EXISTS scripts (id INTEGER PRIMARY KEY AUTOINCREMENT, author_id INTEGER NOT NULL, title TEXT NOT NULL, public INTEGER NOT NULL, source_id INTEGER, version_num TEXT, FOREIGN KEY (author_id) REFERENCES users(id) FOREIGN KEY (source_id) REFERENCES scripts(id)) STRICT",
  "CREATE TABLE IF NOT EXISTS script_character_rel (character_id INTEGER NOT NULL, script_id INTEGER NOT NULL, featured INTEGER NOT NULL DEFAULT 0, PRIMARY KEY (character_id, script_id), FOREIGN KEY (character_id) REFERENCES characters(id), FOREIGN KEY (script_id) REFERENCES scripts(id)) STRICT, WITHOUT ROWID",
  "CREATE TABLE IF NOT EXISTS jinxes (source_character_id INTEGER NOT NULL, target_character_id INTEGER NOT NULL, forbidden INTEGER NOT NULL, rule TEXT NOT NULL, PRIMARY KEY (source_character_id, target_character_id), FOREIGN KEY (source_character_id) REFERENCES characters(id), FOREIGN KEY (target_character_id) REFERENCES characters(id)) STRICT, WITHOUT ROWID",
  "CREATE TABLE IF NOT EXISTS tag_types (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL) STRICT",
  "CREATE TABLE IF NOT EXISTS tags (character_id INTEGER NOT NULL, tag_type_id INTEGER NOT NULL, value INTEGER NOT NULL, PRIMARY KEY (character_id, tag_type_id), FOREIGN KEY (character_id) REFERENCES characters(id), FOREIGN KEY (tag_type_id) REFERENCES tag_types(id)) STRICT, WITHOUT ROWID",
  "CREATE TABLE IF NOT EXISTS script_edits (character_id INTEGER NOT NULL, script_id INTEGER NOT NULL, edit INTEGER NOT NULL, PRIMARY KEY (character_id, script_id), FOREIGN KEY (character_id) REFERENCES characters(id), FOREIGN KEY (script_id) REFERENCES scripts(id)) STRICT, WITHOUT ROWID",
  "CREATE TABLE IF NOT EXISTS character_comments (id INTEGER PRIMARY KEY AUTOINCREMENT, character_id INTEGER NOT NULL, author_id INTEGER NOT NULL, content TEXT NOT NULL, created TEXT NOT NULL DEFAULT (datetime()), FOREIGN KEY (character_id) REFERENCES characters(id), FOREIGN KEY (author_id) REFERENCES users(id)) STRICT",
  "CREATE TABLE IF NOT EXISTS script_comments (id INTEGER PRIMARY KEY AUTOINCREMENT, script_id INTEGER NOT NULL, author_id INTEGER NOT NULL, content TEXT NOT NULL, created TEXT NOT NULL DEFAULT (datetime()), FOREIGN KEY (script_id) REFERENCES scripts(id), FOREIGN KEY (author_id) REFERENCES users(id)) STRICT"
]

TABLE_QUERIES.each do |query|
  db.execute(query)
end

tpi = db.execute("INSERT INTO users (username, pass, perms) VALUES (?, ?, ?) RETURNING id", "The Pandemonium Institute", nil, 3)[0]["id"]

official_tag = db.execute("INSERT INTO tag_types (name) VALUES (?) RETURNING id", "Official")[0]["id"]

data.each do |character|
  id = nil
  if (character["team"] == "fabled")
    id = db.execute(
      "INSERT INTO characters (author_id, name, public, type, ability, first_night, other_nights) VALUES (?, ?, ?, ?, ?, ?, ?) RETURNING id",
      tpi,
      character["name"],
      1,
      type_name_to_id(character["team"]),
      character["ability"],
      0,
      0
    )[0]["id"]
  else
    id = db.execute(
      "INSERT INTO characters (author_id, name, public, type, ability, first_night, other_nights) VALUES (?, ?, ?, ?, ?, ?, ?) RETURNING id",
      tpi,
      character["name"],
      1,
      type_name_to_id(character["team"]),
      character["ability"],
      character["firstNight"],
      character["otherNight"]
    )[0]["id"]

    db.execute("INSERT INTO tags (character_id, tag_type_id, value) VALUES (?, ?, ?)", id, official_tag, 1)
  end

  FileUtils.cp("data/img/#{character["id"]}.png", "public/img")
  File.rename("public/img/#{character["id"]}.png", "public/img/c#{id}.png")
end

SCRIPTS = [
  {id: "tb", name: "Trouble Brewing"},
  {id: "bmr", name: "Bad Moon Rising"},
  {id: "snv", name: "Sects and Violets"}
]

SCRIPTS.each do |script|
  used = data.filter {|character| character["edition"] == script[:id] && character["team"] != "traveler"}
  used_ids = used.map {|character| db.execute("SELECT id FROM characters WHERE name = ?", character["name"])[0]["id"]}

  script_id = db.execute("INSERT INTO scripts (author_id, title, public) VALUES (?, ?, ?) RETURNING id", tpi, script[:name], 1)[0]["id"]
  used_ids.each do |character|
    db.execute("INSERT INTO script_character_rel (character_id, script_id) VALUES (?, ?)", character, script_id)
  end
end