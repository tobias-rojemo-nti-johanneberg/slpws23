require 'sinatra'
require 'slim'
require_relative 'model'

enable :sessions

before do
  @db = Database.new
  @logged_in_user = @db.users.from_session(session[:id])
end

cooldowns = {}

before do
  if request.request_method == "POST"
    ip = request.ip
    now = Time.now.to_i
    if cooldowns[ip] && now - cooldowns[ip] < 1
      halt "Please slow down your requests"
    end
    cooldowns[ip] = now
  end
end

[
  {route: '/', slim: :home, title: "Home"},
  {route: '/home', slim: :home, title: "Home"},
  {route: '/login', slim: :login, title: "Login"},
  {route: '/register', slim: :register, title: "Register"},
  {route: '/invalid', slim: :invalid, title: "Invalid operation"},
  {route: '/permissiondenied', slim: :permissiondenied, title: "Permission denied"},
  {route: '/scripts/notfound', slim: :"/scripts/notfound", title: "Script not found"},
  {route: '/characters/notfound', slim: :"/characters/notfound", title: "Character not found"},
  {route: '/notloggedin', slim: :notloggedin, title: "You are not logged in"},
  {route: '/notfound', slim: :notfound, title: "Resource not found"}
].each {|route|
  get route[:route] do
    @title = route[:title]
    slim(route[:slim])
  end
}

helpers do
  def req(val) = val ? val : redirect("notfound")
  def reqp(param, redirect_uri) = params[param] ? params[param] : redirect(redirect_uri)
  def reqsess(user) = user ? user : redirect(:"/notloggedin")
end

# Attempts to login
# @param [String] name
# @param [String] pass
post '/login' do
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

# Attempts to create an account
# @param [String] name
# @param [String] pass
# @param [String] verifyPass
post '/register' do
  name = reqp(:name, :"/register")
  pass = reqp(:pass, :"/register")
  verify = reqp(:verifyPass, :"/register")
  redirect back unless pass == verify

  @db.users.register(name, pass)
  redirect(:/)
end

# Clears a user's session and removes it from the store
post '/logout' do
  @db.users.logout(session[:id])
  session[:id] = nil
  redirect(:/)
end

# Displays all characters
get '/characters' do
  @title = "Characters"
  @characters = @db.characters.filter{|char| char.can_see?(@logged_in_user)}
  @create = {href: "/characters/create", text: "Create character"}
  slim(:"characters/index")
end

# Displays a character creation form
get '/characters/create' do
  reqsess(@logged_in_user)
  @title = "Create a character"
  slim(:"characters/create")
end

# Displays details about a specific character
# @param [Int] :id
get '/characters/:id' do |id|
  @character = req @db.characters[id]
  slim(:"characters/show")
end

# Displays all scripts containing a specific character
# @param [Int] :id
get '/characters/:id/scripts' do |id|
  @character = req @db.characters[id]
  @scripts = @character.scripts.filter{|script| script.can_see?(@logged_in_user)}
  @title = "Scripts with #{@character.name}"
  @create = {href: "/scripts/create", text: "Create script"}
  slim(:"scripts/index")
end

# Displays a character edit form for a specific character
# @param [Int] :id
get '/characters/:id/edit' do |id|
  reqsess(@logged_in_user)
  @character = req @db.characters[id]
  redirect(:"/permissiondenied") unless @logged_in_user.id == @character.author_id || @logged_in_user.has_perms?(ADMIN)
  @character ? slim(:"characters/edit") : redirect(:"/characters/notfound")
end

# Displays all characters with a specific tag type
# @param [Int] :id
get '/characters/tag/:id' do |id|
  @tag = req @db.tags[id]
  @title = "Characters with tag #{@tag.to_s}"
  @characters = @tag.characters.filter{|char| char.can_see?(@logged_in_user)}
  @create = {href: "/characters/create", text: "Create character"}
  slim(:"characters/index")
end

# Displays all scripts
get '/scripts' do
  @title = "Scripts"
  @scripts = @db.scripts.filter{|script| script.can_see?(@logged_in_user)}
  @create = {href: "/scripts/create", text: "Create script"}
  slim(:"scripts/index")
end

# Displays a script creation form
get '/scripts/create' do
  reqsess(@logged_in_user)
  @title = "Create a script"
  slim(:"/scripts/create")
end

# Displays details about a specific script
# @param [Int] :id
get '/scripts/:id' do |id|
  @script = req @db.scripts[id]
  @title = @script.title
  slim(:"scripts/show")
end

# Displays all characters in a specific script
# @param [Int] :id
get '/scripts/:id/characters' do |id|
  @script = req @db.scripts[id]
  @characters = @script.characters.filter{|char| char.can_see?(@logged_in_user)}
  @title = "Characters in #{@script.title}"
  @create = {href: "/characters/create", text: "Create character"}
  slim(:"characters/index")
end

# Displays all forks of a specific script
# @param [Int] :id
get '/scripts/:id/forks' do |id|
  @script = req @db.scripts[id]
  @scripts = @script.forks.filter{|script| script.can_see?(@logged_in_user)}
  @title = "Forks of #{@script.title}"
  @create = {href: "/scripts/create", text: "Create script"}
  slim(:"scripts/index")
end

# Displays all edits from the source script to a specific fork
# @param [Int] :id
get '/scripts/:id/edits' do |id|
  @script = req @db.scripts[id]
  @edits = req @script.edits
  @title = "Changes from #{@script.source.title} to #{@script.title}"
  slim(:"scripts/edits")
end

# Displays all edits from the origin script to a specific fork
# @param [Int] :id
get '/scripts/:id/edits/origin' do |id|
  @script = req @db.scripts[id]
  @edits = req @script.edits_from_origin
  @title = "Changes from #{@script.origin.title} to #{@script.title}"
  slim(:"scripts/edits")
end

# Displays all edits from a specific script to another specific script
# @param [Int] :id
# @param [Int] :other_id
get '/scripts/:id/compare/:other_id' do |id, other_id|
  @script = req @db.scripts[id]
  @other_script = req @db.scripts[other_id]
  @edits = req @script.compare(@other_script)
  @title = "Changes from #{@other_script.title} to #{@script.title}"
  slim(:"scripts/edits")
end

# Displays all users
get '/users' do
  @users = @db.users
  @title = "Users"
  slim(:"users/index")
end

# Displays details about a specific user
# @param [Int] :id
get '/users/:id' do |id|
  @user = req @db.users[id]
  slim(:"users/show")
end

# Displays all characters created by a specific user
# @param [Int] :id
get '/users/:id/characters' do |id|
  @user = req @db.users[id]
  @characters = @user.characters.filter{|char| char.can_see?(@logged_in_user)}
  @title = "Characters made by #{@user.name}"
  @create = {href: "/characters/create", text: "Create character"}
  slim(:"characters/index")
end

# Displays all scripts created by a specific user
# @param [Int] :id
get '/users/:id/scripts' do |id|
  @user = req @db.users[id]
  @scripts = @user.scripts.filter{|script| script.can_see?(@logged_in_user)}
  @title = "Scripts made by #{@user.name}"
  @create = {href: "/scripts/create", text: "Create script"}
  slim(:"scripts/index")
end

# Creates a new character
# @param [String] name
# @param [Int] type
# @param [File<image/png>] image
# @param [String] ability
post '/characters/create' do
  reqsess(@logged_in_user)
  name = reqp(:name, :"/characters")
  type = reqp(:type, :"/characters")
  image = reqp(:image, :"/characters")
  ability = reqp(:ability, :"/characters")

  @character = @db.characters.create(@logged_in_user.id, name, false, type, ability)
  File.open("public/img/c#{@character.id}.png", "wb") {|f| f.write(image[:tempfile].read)}
  redirect("/characters/#{@character.id}".to_sym)
end

# Edits a specific character if allowed
# @param [Int] :id
# @param name [String, nil]
# @param type [Int, nil]
# @param is_public [Bool, nil]
# @param ability [String, nil]
# @param image [File<image/png>, nil]
post '/characters/:id/edit' do |id|
  reqsess(@logged_in_user)
  @character = req @db.characters[id]
  redirect(:"/permissiondenied") unless @character.author_id == @logged_in_user.id || @logged_in_user.has_perms?(ADMIN)
  is_public = params.has_key?("is_public") ? true : false

  File.open("public/img/c#{@character.id}.png", "wb") {|f| f.write(params[:image][:tempfile].read)} unless !params[:image]
  @character.update(params[:name], is_public, params[:type], params[:ability])
  redirect("/characters/#{@character.id}".to_sym)
end

# Deletes a specific character if allowed
# @param [Int] :id
post '/characters/:id/delete' do |id|
  reqsess(@logged_in_user)
  @character = req @db.characters[id]
  redirect(:"/permissiondenied") unless @character.author_id == @logged_in_user.id || @logged_in_user.has_perms?(ADMIN)

  @character.delete
  redirect(:"/characters")
end

# Creates a new script
# @param [String] title
post '/scripts/create' do
  reqsess(@logged_in_user)
  title = reqp(:title, :"/scripts")

  @script = @db.scripts.create(@logged_in_user.id, title, false)
  redirect("/scripts/#{@script.id}".to_sym)
end

# Displays a script edit form for a specific script
# @param [Int] :id
get '/scripts/:id/edit' do |id|
  reqsess(@logged_in_user)
  @script = req @db.scripts[id]
  redirect(:"/permissiondenied") unless @script.author_id == @logged_in_user.id || @logged_in_user.has_perms?(ADMIN)
  @characters = @db.characters.filter{|char| char.can_see?(@logged_in_user)}
  @back = {href: "/scripts/#{id}", text: "Return to script"}
  @title = "Editing #{@script.title}"
  @script ? slim(:"scripts/edit") : redirect(:"/scripts/notfound")
end

# Edits a specific script if allowed
# @param [Int] :id
# @param title [String, nil]
# @param is_public [Bool, nil]
post '/scripts/:id/edit' do |id|
  reqsess(@logged_in_user)
  @script = req @db.scripts[id]
  redirect(:"/permissiondenied") unless @script.author_id == @logged_in_user.id || @logged_in_user.has_perms?(ADMIN)
  is_public = params.has_key?("is_public") ? true : false

  @script.update(params[:title], is_public)
  redirect("/scripts/#{@script.id}".to_sym)
end

# Adds a specific character to a specific script if allowed
# @param [Int] script_id
# @param [Int] char_id
post '/scripts/:script_id/add/:char_id' do |script_id, char_id|
  reqsess(@logged_in_user)
  @script = req @db.scripts[script_id]
  @character = req @db.characters[char_id]
  redirect(:"/invalid") if @script.include?(@character)
  redirect(:"/permissiondenied") unless @script.author_id == @logged_in_user.id || @logged_in_user.has_perms?(ADMIN)
  redirect(:"/permissiondenied") unless @character.is_public || @character.author_id == @logged_in_user.id
  
  @script.add(char_id)
  redirect back
end

# Removes a specific character from a specific script if allowed
# @param [Int] script_id
# @param [Int] char_id
post '/scripts/:script_id/remove/:char_id' do |script_id, char_id|
  reqsess(@logged_in_user)
  @script = req @db.scripts[script_id]
  @character = req @db.characters[char_id]
  redirect(:"/invalid") unless @script.include?(@character)
  redirect(:"/permissiondenied") unless @script.author_id == @logged_in_user.id || @logged_in_user.has_perms?(ADMIN)
  redirect(:"/permissiondenied") unless @character.is_public || @character.author_id == @logged_in_user.id
  
  @script.remove(char_id)
  redirect back
end

# Features a specific character in a specific script if allowed
# @param [Int] script_id
# @param [Int] char_id
post '/scripts/:script_id/feature/:char_id' do |script_id, char_id|
  reqsess(@logged_in_user)
  @script = req @db.scripts[script_id]
  @character = req @db.characters[char_id]
  redirect(:"/invalid") unless @script.include?(@character)
  redirect(:"/permissiondenied") unless @script.author_id == @logged_in_user.id || @logged_in_user.has_perms?(ADMIN)
  redirect(:"/permissiondenied") unless @character.is_public || @character.author_id == @logged_in_user.id
  
  @script.feature(char_id)
  redirect back
end

# Unfeatures a specific character in a specific script if allowed
# @param [Int] script_id
# @param [Int] char_id
post '/scripts/:script_id/unfeature/:char_id' do |script_id, char_id|
  reqsess(@logged_in_user)
  @script = req @db.scripts[script_id]
  @character = req @db.characters[char_id]
  redirect(:"/invalid") unless @script.include?(@character)
  redirect(:"/permissiondenied") unless @script.author_id == @logged_in_user.id || @logged_in_user.has_perms?(ADMIN)
  redirect(:"/permissiondenied") unless @character.is_public || @character.author_id == @logged_in_user.id
  
  @script.unfeature(char_id)
  redirect back
end

# Deletes a specific script if allowed
# @param [Int] :id
post '/scripts/:id/delete' do |id|
  reqsess(@logged_in_user)
  @script = req @db.scripts[id]
  redirect(:"/permissiondenied") unless @script.author_id == @logged_in_user.id || @logged_in_user.has_perms?(ADMIN)

  @script.delete
  redirect(:"/scripts")
end

# Creates a fork of a specific script if allowed
# @param [Int] :id
post '/scripts/:id/fork' do |id|
  reqsess(@logged_in_user)
  @script = req @db.scripts[id]
  redirect(:"/permissiondenied") unless @script.is_public || @script.author_id == @logged_in_user.id || @logged_in_user.has_perms?(ADMIN)

  @fork = @script.fork(@logged_in_user.id)
  redirect("/scripts/#{@fork.id}".to_sym)
end

# Creates a comment on a specific script
# @param [Int] :id
# @param [String] content
post '/scripts/:id/comment' do |id|
  reqsess(@logged_in_user)
  @script = req @db.scripts[id]
  redirect(:"/permissiondenied") unless @script.is_public
  @script.comment(@logged_in_user.id, reqp(:content, "/scripts/#{id}".to_sym))
  redirect back
end

# Creates a comment on a specific character
# @param [Int] :id
# @param [String] content
post '/characters/:id/comment' do |id|
  reqsess(@logged_in_user)
  @character = req @db.characters[id]
  redirect(:"/permissiondenied") unless @character.is_public
  @character.comment(@logged_in_user.id, reqp(:content, "/characters/#{id}".to_sym))
  redirect back
end