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
  {route: '/register', slim: :register, title: "Register"}
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
    redirect(:"/login")
  end

  session_id = @db.users.login(name, pass)

  if session_id
    session[:id] = session_id
  end

  redirect(:/)
end

post('/register') do
  name = params[:name]
  pass = params[:pass]
  verify = params[:verifyPass]

  if !name || !pass
    redirect(:"/register")
  elsif pass != verify
    redirect(:"/register")
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
  return "You must be logged in to perform this action" unless @logged_in_user
  @title = "Create a character"
  slim(:"characters/create")
end

get('/characters/:id') do
  @character = @db.characters.get(params[:id].to_i)
  @character ? slim(:"characters/show") : slim(:"characters/notfound")
end

get('/characters/:id/scripts') do
  @character = @db.characters.get(params[:id].to_i)
  return slim(:"characters/notfound") unless @character
  @scripts = @character.scripts
  @title = "Scripts with #{@character.name}"
  slim(:"scripts/index")
end

get('/characters/:id/edit') do
  return "You must be logged in to perform this action" unless @logged_in_user
  @character = @db.characters.get(params[:id].to_i)
  return "Invalid permissions" unless @logged_in_user.id == @character.author_id || @logged_in_user.has_perms?(ADMIN)
  @character ? slim(:"characters/edit") : slim(:"characters/notfound")
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
  @script ? slim(:"scripts/show") : slim(:"scripts/notfound")
end

get('/scripts/:id/characters') do
  @script = @db.scripts.get(params[:id].to_i)
  return slim(:"scripts/notfound") unless @script
  @characters = @script.characters
  @title = "Characters in #{@script.full_title}"
  slim(:"characters/index")
end

get('/scripts/:id/forks') do
  @script = @db.scripts.get(params[:id].to_i)
  return slim(:"scripts/notfound") unless @script
  @scripts = @script.forks
  @title = "Forks of #{@script.full_title}"
  slim(:"scripts/index")
end

get('/users') do
  @users = @db.users.get
  @title = "Users"
  slim(:"users/index")
end

get('/users/:id') do
  @user = @db.users.get(params[:id].to_i)
  @user ? slim(:"users/show") : slim(:"users/notfound")
end

get('/users/:id/characters') do
  @user = @db.users.get(params[:id].to_i)
  return slim(:"users/notfound") unless @user
  @characters = @user.characters
  @title = "Characters made by #{@user.name}"
  slim(:"characters/index")
end

get('/users/:id/scripts') do
  @user = @db.users.get(params[:id].to_i)
  return slim(:"users/notfound") unless @user
  @scripts = @user.scripts
  @title = "Scripts made by #{@user.name}"
  slim(:"scripts/index")
end

post('/characters') do
  name = params[:name]
  type = params[:type]
  image = params[:image]
  ability = params[:ability]

  return redirect(:"/characters/create") unless name && type && image && ability

  @character = @db.characters.create(@logged_in_user.id, name, FALSE, type, ability)
  File.write("/public/img/c#{@character.id}.png", File.read(image[:tempfile]))

  redirect(:"/characters/create")
end

patch('/characters/:id') do
  id = params[:id].to_i

  return redirect(:"/invalid") unless id

  @character = @db.character.get(id)

  return redirect(:"/invalid") unless @character
  return redirect(:"/permissiondenied") unless @character.author_id == @logged_in_user.id || @logged_in_user.has_perms?(ADMIN)

  name = params[:name] ? params[:name] : @character.name
  type = params[:type] ? params[:type] : @character.type
  ability = params[:ability] ? params[:ability] : @character.ability

  File.write("/public/img/c#{@character.id}.png", File.read(image[:tempfile])) unless !image
  @db.characters.update()
end

get('/invalid') do
  "Invalid operation"
end