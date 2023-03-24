require 'sinatra'
require 'slim'
require_relative 'model'

enable :sessions

before do
  @db = Database.new
  @logged_in_user = @db.users.from_session(session[:id])
end

[
  {route: '/', slim: :home, title: "Home"},
  {route: '/login', slim: :login, title: "Login"},
  {route: '/register', slim: :register, title: "Register"},
  {route: '/invalid', slim: :invalid, title: "Invalid operation"},
  {route: '/permissiondenied', slim: :permissiondenied, title: "Permission denied"},
  {route: '/scripts/notfound', slim: :"/scripts/notfound", title: "Script not found"},
  {route: '/characters/notfound', slim: :"/characters/notfound", title: "Character not found"},
  {route: '/notloggedin', slim: :notloggedin, title: "You are not logged in"}
].each {|route|
  get(route[:route]) do
    @title = route[:title]
    slim(route[:slim])
  end
}

post('/login') do
  name = params[:name]
  pass = params[:pass]
  if !name || !pass
    redirect back
  end

  session_id = @db.users.login(name, pass)
  if session_id
    session[:id] = session_id
  else
    redirect back
  end
  redirect(:/)
end

post('/register') do
  name = params[:name]
  pass = params[:pass]
  verify = params[:verifyPass]
  if !name || !pass
    redirect back
  elsif pass != verify
    redirect back
  end

  @db.users.register(name, pass)
  redirect(:/)
end

post('/logout') do
  @db.users.logout(session[:id])
  session[:id] = nil
  redirect(:/)
end

get('/characters') do
  @title = "Characters"
  @characters = @db.characters
  slim(:"characters/index")
end

get('/characters/create') do
  redirect(:"/notloggedin") unless @logged_in_user
  @title = "Create a character"
  slim(:"characters/create")
end

get('/characters/:id') do
  @character = @db.characters.get(params[:id].to_i)
  @character ? slim(:"characters/show") : redirect(:"/characters/notfound")
end

get('/characters/:id/scripts') do
  @character = @db.characters.get(params[:id].to_i)
  redirect(:"/characters/notfound") unless @character
  @scripts = @character.scripts
  @title = "Scripts with #{@character.name}"
  slim(:"scripts/index")
end

get('/characters/:id/edit') do
  redirect(:"/notloggedin") unless @logged_in_user
  id = params[:id].to_i
  redirect(:"/invalid") unless id
  @character = @db.characters.get(id)
  redirect(:"/permissiondenied") unless @logged_in_user.id == @character.author_id || @logged_in_user.has_perms?(ADMIN)
  @character ? slim(:"characters/edit") : redirect(:"/characters/notfound")
end

get('/characters/tag/:id') do
  @tag = @db.tags.get(params[:id].to_i)
  @title = "Characters with tag #{@tag.to_s}"
  @characters = @tag.characters
  slim(:"characters/index")
end

get('/scripts') do
  @title = "Scripts"
  @scripts = @db.scripts
  slim(:"scripts/index")
end

get('/scripts/:id') do
  @script = @db.scripts.get(params[:id].to_i)
  @script ? slim(:"scripts/show") : redirect(:"/scripts/notfound")
end

get('/scripts/:id/characters') do
  @script = @db.scripts.get(params[:id].to_i)
  redirect(:"/scripts/notfound") unless @script
  @characters = @script.characters
  @title = "Characters in #{@script.title}"
  slim(:"characters/index")
end

get('/scripts/:id/forks') do
  @script = @db.scripts.get(params[:id].to_i)
  redirect(:"/scripts/notfound") unless @script
  @scripts = @script.forks
  @title = "Forks of #{@script.title}"
  slim(:"scripts/index")
end

get('/scripts/:id/edits') do
  @script = @db.scripts.get(params[:id].to_i)
  redirect(:"/scripts/notfound") unless @script
  @edits = @script.edits
  redirect(:"/invalid") unless @edits
  @title = "Changes from #{@script.source.title} to #{@script.title}"
  slim(:"scripts/edits")
end

get('/scripts/:id/edits/origin') do
  @script = @db.scripts.get(params[:id].to_i)
  redirect(:"/scripts/notfound") unless @script
  @edits = @script.edits_from_origin
  redirect(:"/invalid") unless @edits
  @title = "Changes from #{@script.source.title} to #{@script.title}"
  slim(:"scripts/edits")
end

get('/scripts/:id/compare/:other_id') do
  id = params[:id].to_i
  other_id = params[:other_id].to_i
  redirect(:"/invalid") unless id
  redirect(:"/invalid") unless other_id
  @script = @db.scripts.get(id)
  @other_script = @db.scripts.get(other_id)
  redirect(:"/scripts/notfound") unless @script
  redirect(:"/scripts/notfound") unless @other_script
  @edits = @script.compare(@other_script)
  redirect(:"/invalid") unless @edits
  @title = "Changes from #{@other_script.title} to #{@script.title}"
  slim(:"scripts/edits")
end

get('/users') do
  @users = @db.users.get
  @title = "Users"
  slim(:"users/index")
end

get('/users/:id') do
  @user = @db.users.get(params[:id].to_i)
  @user ? slim(:"users/show") : redirect(:"/users/notfound")
end

get('/users/:id/characters') do
  @user = @db.users.get(params[:id].to_i)
  redirect(:"/users/notfound") unless @user
  @characters = @user.characters
  @title = "Characters made by #{@user.name}"
  slim(:"characters/index")
end

get('/users/:id/scripts') do
  @user = @db.users.get(params[:id].to_i)
  redirect(:"/users/notfound") unless @user
  @scripts = @user.scripts
  @title = "Scripts made by #{@user.name}"
  slim(:"scripts/index")
end

post('/characters/create') do
  redirect(:"/notloggedin") unless @logged_in_user
  name = params[:name]
  type = params[:type]
  image = params[:image]
  ability = params[:ability]
  redirect back unless name && type && image && ability

  @character = @db.characters.create(@logged_in_user.id, name, false, type, ability)
  File.open("public/img/c#{@character.id}.png", "wb") {|f| f.write(image[:tempfile].read)}
  redirect("/characters/#{@character.id}".to_sym)
end

post('/characters/:id/edit') do
  redirect(:"/notloggedin") unless @logged_in_user
  id = params[:id].to_i
  redirect(:"/invalid") unless id
  @character = @db.characters.get(id)
  redirect(:"/invalid") unless @character
  redirect(:"/permissiondenied") unless @character.author_id == @logged_in_user.id || @logged_in_user.has_perms?(ADMIN)
  is_public = params[:is_public] ? (params[:is_public] == "on" ? true : false) : nil

  File.open("public/img/c#{@character.id}.png", "wb") {|f| f.write(params[:image][:tempfile].read)} unless !params[:image]
  @character.update(params[:name], is_public, params[:type], params[:ability])
  redirect("/characters/#{@character.id}".to_sym)
end

post('/characters/:id/delete') do
  redirect(:"/notloggedin") unless @logged_in_user
  id = params[:id].to_i
  redirect(:"/invalid") unless id
  @character = @db.characters.get(id)
  redirect(:"/invalid") unless @character
  redirect(:"/permissiondenied") unless @character.author_id == @logged_in_user.id || @logged_in_user.has_perms?(ADMIN)

  @character.delete
  redirect(:"/characters")
end

post('/scripts/create') do
  redirect(:"/notloggedin") unless @logged_in_user
  title = params[:title]
  redirect back unless title

  @script = @db.scripts.create(@logged_in_user.id, title)
  redirect("/scripts/#{@script.id}".to_sym)
end

get('/scripts/:id/edit') do
  redirect(:"/notloggedin") unless @logged_in_user
  id = params[:id].to_i
  redirect(:"/invalid") unless id
  @script = @db.scripts.get(id)
  redirect(:"/invalid") unless @script
  redirect(:"/permissiondenied") unless @script.author_id == @logged_in_user.id || @logged_in_user.has_perms?(ADMIN)
  @characters = @db.characters
  @script ? slim(:"scripts/edit") : redirect(:"/scripts/notfound")
end

post('/scripts/:id/edit') do
  redirect(:"/notloggedin") unless @logged_in_user
  id = params[:id].to_i
  redirect(:"/invalid") unless id
  @script = @db.scripts.get(id)
  redirect(:"/invalid") unless @script
  redirect(:"/permissiondenied") unless @script.author_id == @logged_in_user.id || @logged_in_user.has_perms?(ADMIN)
  is_public = params[:is_public] ? (params[:is_public] == "on" ? true : false) : nil

  @script.update(params[:title], is_public)
  redirect("/scripts/#{@script.id}".to_sym)
end

post('/scripts/:script_id/add/:char_id') do
  redirect(:"/notloggedin") unless @logged_in_user
  script_id = params[:script_id].to_i
  char_id = params[:char_id].to_i
  redirect(:"/invalid") unless script_id
  redirect(:"/invalid") unless char_id
  @script = @db.scripts.get(script_id)
  @character = @db.characters.get(char_id)
  redirect(:"/invalid") unless @script
  redirect(:"/invalid") unless @character
  redirect(:"/invalid") if @script.include?(@character)
  redirect(:"/permissiondenied") unless @script.author_id == @logged_in_user.id || @logged_in_user.has_perms?(ADMIN)
  redirect(:"/permissiondenied") unless @character.is_public || @character.author_id == @logged_in_user.id
  
  @script.add(char_id)
  redirect back
end

post('/scripts/:script_id/remove/:char_id') do
  redirect(:"/notloggedin") unless @logged_in_user
  script_id = params[:script_id].to_i
  char_id = params[:char_id].to_i
  redirect(:"/invalid") unless script_id
  redirect(:"/invalid") unless char_id
  @script = @db.scripts.get(script_id)
  @character = @db.characters.get(char_id)
  redirect(:"/invalid") unless @script
  redirect(:"/invalid") unless @character
  redirect(:"/invalid") unless @script.include?(@character)
  redirect(:"/permissiondenied") unless @script.author_id == @logged_in_user.id || @logged_in_user.has_perms?(ADMIN)
  redirect(:"/permissiondenied") unless @character.is_public || @character.author_id == @logged_in_user.id
  
  @script.remove(char_id)
  redirect back
end

post('/scripts/:script_id/feature/:char_id') do
  redirect(:"/notloggedin") unless @logged_in_user
  script_id = params[:script_id].to_i
  char_id = params[:char_id].to_i
  redirect(:"/invalid") unless script_id
  redirect(:"/invalid") unless char_id
  @script = @db.scripts.get(script_id)
  @character = @db.characters.get(char_id)
  redirect(:"/invalid") unless @script
  redirect(:"/invalid") unless @character
  redirect(:"/invalid") unless @script.include?(@character)
  redirect(:"/permissiondenied") unless @script.author_id == @logged_in_user.id || @logged_in_user.has_perms?(ADMIN)
  redirect(:"/permissiondenied") unless @character.is_public || @character.author_id == @logged_in_user.id
  
  @script.feature(char_id)
  redirect back
end

post('/scripts/:script_id/unfeature/:char_id') do
  redirect(:"/notloggedin") unless @logged_in_user
  script_id = params[:script_id].to_i
  char_id = params[:char_id].to_i
  redirect(:"/invalid") unless script_id
  redirect(:"/invalid") unless char_id
  @script = @db.scripts.get(script_id)
  @character = @db.characters.get(char_id)
  redirect(:"/invalid") unless @script
  redirect(:"/invalid") unless @character
  redirect(:"/invalid") unless @script.include?(@character)
  redirect(:"/permissiondenied") unless @script.author_id == @logged_in_user.id || @logged_in_user.has_perms?(ADMIN)
  redirect(:"/permissiondenied") unless @character.is_public || @character.author_id == @logged_in_user.id
  
  @script.unfeature(char_id)
  redirect back
end

post('/scripts/:id/delete') do
  redirect(:"/notloggedin") unless @logged_in_user
  id = params[:id].to_i
  redirect(:"/invalid") unless id
  @script = @db.scripts.get(id)
  redirect(:"/invalid") unless @script
  redirect(:"/permissiondenied") unless @script.author_id == @logged_in_user.id || @logged_in_user.has_perms?(ADMIN)

  @script.delete
  redirect(:"/scripts")
end

post('/scripts/:id/fork') do
  redirect(:"/notloggedin") unless @logged_in_user
  id = params[:id].to_i
  redirect(:"/invalid") unless id
  @script = @db.scripts.get(id)
  redirect(:"/invalid") unless @script
  redirect(:"/permissiondenied") unless @script.is_public || @script.author_id == @logged_in_user.id || @logged_in_user.has_perms?(ADMIN)

  @fork = @script.fork(@logged_in_user.id)
  redirect("/scripts/#{@fork.id}".to_sym)
end