require 'sinatra'
require 'slim'
require_relative 'model'

enable :sessions

before do
  @user = Database.new.users.from_session(session[:id])
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
    redirect(:/)
  end

  session_id = Database.new.users.login(name, pass)

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
    redirect(:/)
  elsif pass != verify
    redirect(:/)
  end

  p Database.new

  Database.new.users.register(name, pass)
end

get('/characters') do
  @title = "Characters"
  @characters = Database.new.characters
  slim(:"characters/index")
end

get('/characters/:id') do
  @character = Database.new.characters.get(params[:id].to_i)
  if @character
    slim(:"characters/show")
  else
    slim(:"characters/notfound")
  end
end

get('/characters/tag/:id') do
  tag = Database.new.tags.get(params[:id].to_i)
  @title = "Characters with tag #{tag.to_s}"
  @characters = tag.characters
  slim(:"characters/index")
end

get('/scripts') do
  @title = "Scripts"
  @scripts = Database.new.scripts
  slim(:"scripts/index")
end

