require 'sinatra'
require 'slim'
require_relative 'model'

enable :sessions

get('/characters') do
  @characters = Database.new().characters
  slim(:"characters/index")
end

get('/characters/:id') do
  @character = Database.new().characters.get(params[:id].to_i)
  if @character
    slim(:"characters/show")
  else
    slim(:"characters/notfound")
  end
end

get('/characters/tag/:id') do
  @characters = Database.new().tags.get(params[:id].to_i).characters
  slim(:"characters/index")
end

get('/scripts') do
  @scripts = Database.new().scripts
  slim(:"scripts/index")
end

