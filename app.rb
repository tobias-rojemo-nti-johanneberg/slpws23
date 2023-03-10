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
    redirect(:/)
  end
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