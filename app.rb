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
  {route: '/notloggedin', slim: :notloggedin, title: "You are not logged in"},
  {route: '/notfound', slim: :notfound, title: "Resource not found"}
].each {|route|
  get(route[:route]) do
    @title = route[:title]
    slim(route[:slim])
  end
}

helpers do
  def req(val) = val ? val : redirect("notfound")
  def reqp(param, redirect_uri) = params[param] ? params[param] : redirect(redirect_uri)
  def reqsess(user) = user ? user : redirect(:"/notloggedin")
end

post('/login') do
  name = reqp(:name, :"/login")
  pass = reqp(:pass, :"/login")

  session_id = @db.users.login(name, pass)
  if session_id
    session[:id] = session_id
  else
    redirect back
  end
  redirect(:/)
end

post('/register') do
  name = reqp(:name, :"/register")
  pass = reqp(:pass, :"/register")
  verify = reqp(:verifyPass, :"/register")
  redirect back unless pass == verify

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
  @create = {href: "/characters/create", text: "Create character"}
  slim(:"characters/index")
end

get('/characters/create') do
  reqsess(@logged_in_user)
  @title = "Create a character"
  slim(:"characters/create")
end

get('/characters/:id') do |id|
  @character = req @db.characters[id]
  slim(:"characters/show")
end

get('/characters/:id/scripts') do |id|
  @character = req @db.characters[id]
  @scripts = @character.scripts
  @title = "Scripts with #{@character.name}"
  @create = {href: "/scripts/create", text: "Create script"}
  slim(:"scripts/index")
end

get('/characters/:id/edit') do |id|
  reqsess(@logged_in_user)
  @character = req @db.characters[id]
  redirect(:"/permissiondenied") unless @logged_in_user.id == @character.author_id || @logged_in_user.has_perms?(ADMIN)
  @character ? slim(:"characters/edit") : redirect(:"/characters/notfound")
end

get('/characters/tag/:id') do |id|
  @tag = req @db.tags[id]
  @title = "Characters with tag #{@tag.to_s}"
  @characters = @tag.characters
  @create = {href: "/characters/create", text: "Create character"}
  slim(:"characters/index")
end

get('/scripts') do
  @title = "Scripts"
  @scripts = @db.scripts
  @create = {href: "/scripts/create", text: "Create script"}
  slim(:"scripts/index")
end

get('/scripts/create') do
  reqsess(@logged_in_user)
  @title = "Create a script"
  slim(:"/scripts/create")
end

get('/scripts/:id') do |id|
  @script = req @db.scripts[id]
  @title = @script.title
  slim(:"scripts/show")
end

get('/scripts/:id/characters') do |id|
  @script = req @db.scripts[id]
  @characters = @script.characters
  @title = "Characters in #{@script.title}"
  @create = {href: "/characters/create", text: "Create character"}
  slim(:"characters/index")
end

get('/scripts/:id/forks') do |id|
  @script = req @db.scripts[id]
  @scripts = @script.forks
  @title = "Forks of #{@script.title}"
  @create = {href: "/scripts/create", text: "Create script"}
  slim(:"scripts/index")
end

get('/scripts/:id/edits') do |id|
  @script = req @db.scripts[id]
  @edits = req @script.edits
  @title = "Changes from #{@script.source.title} to #{@script.title}"
  slim(:"scripts/edits")
end

get('/scripts/:id/edits/origin') do |id|
  @script = req @db.scripts[id]
  @edits = req @script.edits_from_origin
  @title = "Changes from #{@script.origin.title} to #{@script.title}"
  slim(:"scripts/edits")
end

get('/scripts/:id/compare/:other_id') do |id, other_id|
  @script = req @db.scripts[id]
  @other_script = req @db.scripts[other_id]
  @edits = req @script.compare(@other_script)
  @title = "Changes from #{@other_script.title} to #{@script.title}"
  slim(:"scripts/edits")
end

get('/users') do
  @users = @db.users
  @title = "Users"
  slim(:"users/index")
end

get('/users/:id') do |id|
  @user = req @db.users[id]
  slim(:"users/show")
end

get('/users/:id/characters') do |id|
  @user = req @db.users[id]
  @characters = @user.characters
  @title = "Characters made by #{@user.name}"
  @create = {href: "/characters/create", text: "Create character"}
  slim(:"characters/index")
end

get('/users/:id/scripts') do |id|
  @user = req @db.users[id]
  @scripts = @user.scripts
  @title = "Scripts made by #{@user.name}"
  @create = {href: "/scripts/create", text: "Create script"}
  slim(:"scripts/index")
end

post('/characters/create') do
  reqsess(@logged_in_user)
  name = reqp(:name, :"/characters")
  type = reqp(:type, :"/characters")
  image = reqp(:image, :"/characters")
  ability = reqp(:ability, :"/characters")

  @character = @db.characters.create(@logged_in_user.id, name, false, type, ability)
  File.open("public/img/c#{@character.id}.png", "wb") {|f| f.write(image[:tempfile].read)}
  redirect("/characters/#{@character.id}".to_sym)
end

post('/characters/:id/edit') do |id|
  reqsess(@logged_in_user)
  @character = req @db.characters[id]
  redirect(:"/permissiondenied") unless @character.author_id == @logged_in_user.id || @logged_in_user.has_perms?(ADMIN)
  is_public = params[:is_public] ? (params[:is_public] == "on" ? true : false) : nil

  File.open("public/img/c#{@character.id}.png", "wb") {|f| f.write(params[:image][:tempfile].read)} unless !params[:image]
  @character.update(params[:name], is_public, params[:type], params[:ability])
  redirect("/characters/#{@character.id}".to_sym)
end

post('/characters/:id/delete') do |id|
  reqsess(@logged_in_user)
  @character = req @db.characters[id]
  redirect(:"/permissiondenied") unless @character.author_id == @logged_in_user.id || @logged_in_user.has_perms?(ADMIN)

  @character.delete
  redirect(:"/characters")
end

post('/scripts/create') do
  reqsess(@logged_in_user)
  title = reqp(:title, :"/scripts")

  @script = @db.scripts.create(@logged_in_user.id, title, false)
  redirect("/scripts/#{@script.id}".to_sym)
end

get('/scripts/:id/edit') do |id|
  reqsess(@logged_in_user)
  @script = req @db.scripts[id]
  redirect(:"/permissiondenied") unless @script.author_id == @logged_in_user.id || @logged_in_user.has_perms?(ADMIN)
  @characters = @db.characters
  @back = {href: "/scripts/#{id}", text: "Return to script"}
  @title = "Editing #{@script.title}"
  @script ? slim(:"scripts/edit") : redirect(:"/scripts/notfound")
end

post('/scripts/:id/edit') do |id|
  reqsess(@logged_in_user)
  @script = req @db.scripts[id]
  redirect(:"/permissiondenied") unless @script.author_id == @logged_in_user.id || @logged_in_user.has_perms?(ADMIN)
  is_public = params[:is_public] ? (params[:is_public] == "on" ? true : false) : nil

  @script.update(params[:title], is_public)
  redirect("/scripts/#{@script.id}".to_sym)
end

post('/scripts/:script_id/add/:char_id') do |script_id, char_id|
  reqsess(@logged_in_user)
  @script = req @db.scripts[script_id]
  @character = req @db.characters[char_id]
  redirect(:"/invalid") if @script.include?(@character)
  redirect(:"/permissiondenied") unless @script.author_id == @logged_in_user.id || @logged_in_user.has_perms?(ADMIN)
  redirect(:"/permissiondenied") unless @character.is_public || @character.author_id == @logged_in_user.id
  
  @script.add(char_id)
  redirect back
end

post('/scripts/:script_id/remove/:char_id') do |script_id, char_id|
  reqsess(@logged_in_user)
  @script = req @db.scripts[script_id]
  @character = req @db.characters[char_id]
  redirect(:"/invalid") unless @script.include?(@character)
  redirect(:"/permissiondenied") unless @script.author_id == @logged_in_user.id || @logged_in_user.has_perms?(ADMIN)
  redirect(:"/permissiondenied") unless @character.is_public || @character.author_id == @logged_in_user.id
  
  @script.remove(char_id)
  redirect back
end

post('/scripts/:script_id/feature/:char_id') do |script_id, char_id|
  reqsess(@logged_in_user)
  @script = req @db.scripts[script_id]
  @character = req @db.characters[char_id]
  redirect(:"/invalid") unless @script.include?(@character)
  redirect(:"/permissiondenied") unless @script.author_id == @logged_in_user.id || @logged_in_user.has_perms?(ADMIN)
  redirect(:"/permissiondenied") unless @character.is_public || @character.author_id == @logged_in_user.id
  
  @script.feature(char_id)
  redirect back
end

post('/scripts/:script_id/unfeature/:char_id') do |script_id, char_id|
  reqsess(@logged_in_user)
  @script = req @db.scripts[script_id]
  @character = req @db.characters[char_id]
  redirect(:"/invalid") unless @script.include?(@character)
  redirect(:"/permissiondenied") unless @script.author_id == @logged_in_user.id || @logged_in_user.has_perms?(ADMIN)
  redirect(:"/permissiondenied") unless @character.is_public || @character.author_id == @logged_in_user.id
  
  @script.unfeature(char_id)
  redirect back
end

post('/scripts/:id/delete') do |id|
  reqsess(@logged_in_user)
  @script = req @db.scripts[id]
  redirect(:"/permissiondenied") unless @script.author_id == @logged_in_user.id || @logged_in_user.has_perms?(ADMIN)

  @script.delete
  redirect(:"/scripts")
end

post('/scripts/:id/fork') do |id|
  reqsess(@logged_in_user)
  @script = req @db.scripts[id]
  redirect(:"/permissiondenied") unless @script.is_public || @script.author_id == @logged_in_user.id || @logged_in_user.has_perms?(ADMIN)

  @fork = @script.fork(@logged_in_user.id)
  redirect("/scripts/#{@fork.id}".to_sym)
end

post('/scripts/:id/comment') do |id|
  reqsess(@logged_in_user)
  @script = req @db.scripts[id]
  redirect(:"/permissiondenied") unless @script.is_public
  @script.comment(@logged_in_user.id, reqp(:content, "/scripts/#{id}".to_sym))
  redirect back
end

post('/characters/:id/comment') do |id|
  reqsess(@logged_in_user)
  @character = req @db.characters[id]
  redirect(:"/permissiondenied") unless @character.is_public
  @character.comment(@logged_in_user.id, reqp(:content, "/characters/#{id}".to_sym))
  redirect back
end