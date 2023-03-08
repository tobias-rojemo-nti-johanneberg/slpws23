CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT NOT NULL,
  pass TEXT,
  perms INTEGER NOT NULL
) STRICT;

CREATE TABLE IF NOT EXISTS characters (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  author_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  public INTEGER NOT NULL,
  type INTEGER NOT NULL,
  ability TEXT NOT NULL,
  first_night REAL NOT NULL,
  other_nights REAL NOT NULL,
  FOREIGN KEY (author_id) REFERENCES users(id)
) STRICT;

CREATE TABLE IF NOT EXISTS scripts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  author_id INTEGER NOT NULL,
  title TEXT NOT NULL,
  public INTEGER NOT NULL,
  source_id INTEGER,
  version_num TEXT,
  FOREIGN KEY (author_id) REFERENCES users(id)
  FOREIGN KEY (source_id) REFERENCES scripts(id)
) STRICT;

CREATE TABLE IF NOT EXISTS script_character_rel (
  character_id INTEGER NOT NULL,
  script_id INTEGER NOT NULL,
  featured INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (character_id, script_id),
  FOREIGN KEY (character_id) REFERENCES characters(id),
  FOREIGN KEY (script_id) REFERENCES scripts(id)
) STRICT, WITHOUT ROWID;

CREATE TABLE IF NOT EXISTS jinxes (
  source_character_id INTEGER NOT NULL,
  target_character_id INTEGER NOT NULL,
  forbidden INTEGER NOT NULL,
  rule TEXT NOT NULL,
  PRIMARY KEY (source_character_id, target_character_id),
  FOREIGN KEY (source_character_id) REFERENCES characters(id),
  FOREIGN KEY (target_character_id) REFERENCES characters(id)
) STRICT, WITHOUT ROWID;

CREATE TABLE IF NOT EXISTS tag_types (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  bg TEXT NOT NULL DEFAULT '#A0A0A0',
  text TEXT NOT NULL DEFAULT '#000000',
  display_value INT NOT NULL DEFAULT 0
) STRICT;

CREATE TABLE IF NOT EXISTS tags (
  character_id INTEGER NOT NULL,
  tag_type_id INTEGER NOT NULL,
  value INTEGER NOT NULL,
  PRIMARY KEY (character_id, tag_type_id),
  FOREIGN KEY (character_id) REFERENCES characters(id),
  FOREIGN KEY (tag_type_id) REFERENCES tag_types(id)
) STRICT, WITHOUT ROWID;

CREATE TABLE IF NOT EXISTS script_edits (
  character_id INTEGER NOT NULL,
  script_id INTEGER NOT NULL,
  edit INTEGER NOT NULL,
  PRIMARY KEY (character_id, script_id),
  FOREIGN KEY (character_id) REFERENCES characters(id),
  FOREIGN KEY (script_id) REFERENCES scripts(id)
) STRICT, WITHOUT ROWID;

CREATE TABLE IF NOT EXISTS character_comments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  character_id INTEGER NOT NULL,
  author_id INTEGER NOT NULL,
  content TEXT NOT NULL,
  created TEXT NOT NULL DEFAULT (datetime()),
  FOREIGN KEY (character_id) REFERENCES characters(id),
  FOREIGN KEY (author_id) REFERENCES users(id)
) STRICT;

CREATE TABLE IF NOT EXISTS script_comments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  script_id INTEGER NOT NULL,
  author_id INTEGER NOT NULL,
  content TEXT NOT NULL,
  created TEXT NOT NULL DEFAULT (datetime()),
  FOREIGN KEY (script_id) REFERENCES scripts(id),
  FOREIGN KEY (author_id) REFERENCES users(id)
) STRICT;