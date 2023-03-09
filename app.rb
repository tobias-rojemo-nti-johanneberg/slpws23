require 'sinatra'
require 'slim'
require_relative 'model'

enable :sessions

before do
  @db = Database.new
  @user = @db.users.from_session(session[:id])
end

get('/') do
  @title = "Home"
  slim(:home)
end

get('/login') do
  @title = "Login"
  slim(:login)
end

get('/register') do
  @title = "Register"
  slim(:register)
end

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

get('/characters') do
  @title = "Characters"
  @characters = @db.characters
  slim(:"characters/index")
end

get('/characters/:id') do
  @character = @db.characters.get(params[:id].to_i)
  if @character
    slim(:"characters/show")
  else
    slim(:"characters/notfound")
  end
end

get('/characters/:id/scripts') do
  @character = @db.characters.get(params[:id].to_i)
  if @character
    @scripts = @character.scripts
    @title = "Scripts with #{@character.name}"
    slim(:"scripts/index")
  else
    slim(:"characters/notfound")
  end
end

get('/characters/tag/:id') do
  tag = @db.tags.get(params[:id].to_i)
  @title = "Characters with tag #{tag.to_s}"
  @characters = tag.characters
  slim(:"characters/index")
end

get('/scripts') do
  @title = "Scripts"
  @scripts = @db.scripts
  slim(:"scripts/index")
end

get('/scripts/:id') do
  @script = @db.scripts.get(params[:id].to_i)
  if @script
    slim(:"scripts/show")
  else
    slim(:"scripts/notfound")
  end
end

get('/scripts/:id/characters') do
  @script = @db.scripts.get(params[:id].to_i)
  @characters = @script.characters
  @title = "Characters in #{@script.title}"
  slim(:"characters/index")
end

get('/scripts/:id/forks') do
  @script = @db.scripts.get(params[:id].to_i)
  @scripts = @script.forks
  @title = "Forks of #{@script.title}"
  slim(:"/scripts/index")
end