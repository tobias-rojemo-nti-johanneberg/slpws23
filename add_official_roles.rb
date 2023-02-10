require 'json'

require_relative 'model'

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

file = File.open("data/roles.json")
data = JSON.load(file)
file.close()

db = Database.new()

# SCRIPTS = [
#   {id: "tb", name: "Trouble Brewing"},
#   {id: "bmr", name: "Bad Moon Rising"},
#   {id: "snv", name: "Sects and Violets"}
# ]
# 
# SCRIPTS.each do |script|
#   used = data.filter {|character| character["edition"] == script[:id] && character["team"] != "traveler"}
#   used_ids = used.map {|character| db.db.execute("SELECT id FROM characters WHERE name = ?", character["name"])[0]["id"]}
# 
#   db.scripts.create(0, script[:name], 1, used_ids)
# end
# 
# tpi = db.users.register("The Pandemonium Institute", nil, 3)
# 
# data.each do |character|
#   db.characters.create(
#     tpi.id,
#     character["name"],
#     1,
#     type_name_to_id(character["team"]),
#     character["ability"],
#     character["firstNight"],
#     character["otherNight"]
#   )
# end