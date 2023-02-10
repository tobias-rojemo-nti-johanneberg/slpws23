CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  pass TEXT,
  perms INTEGER NOT NULL
) STRICT;

CREATE TABLE IF NOT EXISTS characters (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  owner_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  public INTEGER NOT NULL,
  type INTEGER NOT NULL,
  ability TEXT NOT NULL,
  first_night REAL NOT NULL,
  other_nights REAL NOT NULL,
  FOREIGN KEY (owner_id) REFERENCES users(id)
) STRICT;

CREATE TABLE IF NOT EXISTS scripts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  owner_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  public INTEGER NOT NULL,
  source_id INTEGER,
  version_num TEXT,
  FOREIGN KEY (owner_id) REFERENCES users(id)
  FOREIGN KEY (source_id) REFERENCES scripts(id)
) STRICT;

CREATE TABLE IF NOT EXISTS script_character_rel (
  character_id INTEGER NOT NULL,
  script_id INTEGER NOT NULL,
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
  name TEXT NOT NULL
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