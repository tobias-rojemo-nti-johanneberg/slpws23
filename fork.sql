WITH n(script_id) AS (SELECT ?)
  INSERT INTO script_character_rel (character_id, script_id, featured)
    SELECT character_id, n.script_id, featured FROM script_character_rel
      INNER JOIN n WHERE script_character_rel.script_id = ?