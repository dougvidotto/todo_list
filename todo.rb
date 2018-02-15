require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"


configure do
  enable :sessions
  set :session_secret, 'secret'
end

get "/" do
  redirect "/lists"
end

get "/lists" do
  @lists = [
    {name: "Lunch groceries", todos: []},
    {name: "Dinner groceries", todos: []}
  ]
  erb :lists, layout: :layout
end
