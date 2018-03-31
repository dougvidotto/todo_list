require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/content_for'
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  # The same as session[:list] || session[:list] = [] (a || a = b)
  session[:lists] ||= []
end

get '/' do
  redirect '/lists'
end

# View all the existent lists
get '/lists' do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

# Render new list form
get '/lists/new' do
  erb :new_list, layout: :layout
end

# Return an error message if the name is invalid.
# Return nil if the name is valid.
def error_for_list_name(name)
  if !(1..100).cover? name.size
    'List name must be between 1 and 100 characters.'
  elsif session[:lists].any? { |list| list[:name] == name }
    'List name must be unique.'
  end
end

# Create a new list
post '/lists' do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = 'The list has been created.'
    redirect '/lists'
  end
end

# View a list with its todos
get '/lists/:idx' do
  @list_id = params[:idx].to_i
  @list_detail = session[:lists][@list_id]
  erb :list, layout: :layout
end

# Editing an existing todo list
get '/lists/:idx/edit' do
  @list_id = params[:idx].to_i
  @list_detail = session[:lists][@list_id]
  erb :list_edit, layout: :layout
end

# Edit a name of a list
post '/lists/:idx' do
  list_name = params[:list_name].strip
  list_idx = params[:idx].to_i
  @list_detail = session[:lists][list_idx]
  error = error_for_list_name(list_name)
  if error && @list_detail[:name] != list_name
    session[:error] = error
    erb :list_edit, layout: :layout
  else
    @list_detail[:name] = list_name
    session[:success] = 'The list has been editted successfully.'
    redirect "/lists/#{list_idx}"
  end
end

# Destroy an entire todo list
post '/lists/:idx/delete' do
  list_idx = params[:idx].to_i
  session[:lists].delete_at(list_idx)
  session[:success] = 'The list has been editted successfully.'
  redirect "/lists"
end

def error_for_todo_name(todo_name, todos)
  if !(1..100).cover? todo_name.size
    'Todo item must have between 1 and 100 characters.'
  end
end

# Create a new todo item into the list
post '/lists/:idx/todos' do
  @list_id = params[:idx].to_i
  @list_detail = session[:lists][@list_id]
  todo = params[:todo].strip  
  error = error_for_todo_name(todo, @list_detail[:todos])
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @list_detail[:todos] << { name: todo, completed: false }
    session[:success] = 'The todo was added.'
    redirect "lists/#{@list_id}"
  end
end

# Delete a todo item from the list
post '/lists/:list_index/todos/:todo_index/delete' do
  @list_id = params[:list_index].to_i
  todo_id = params[:todo_index].to_i
  @list_detail = session[:lists][@list_id]
  @list_detail[:todos].delete_at(todo_id)
  session[:success] = 'The todo has been deleted.'
  redirect "lists/#{@list_id}"
end

# Complete a todo item from a list
post '/lists/:list_id/todos/:todo_index/complete' do
  @list_id = params[:list_id].to_i
  todo_id = params[:todo_index].to_i
  @list_detail = session[:lists][@list_id]
  @list_detail[:todos][todo_id][:completed] = params[:completed] == 'true'
  session[:success] = 'The todo has been updated.'
  redirect "lists/#{@list_id}"
end

post '/lists/:list_id/complete_all' do
  list_id = params[:list_id].to_i
  list_detail = session[:lists][list_id]
  list_detail[:todos].each { |todo| todo[:completed] = true }

  redirect "lists/#{list_id}"
end

helpers do
  def is_complete?(list)
    return false if list[:todos].empty?
    remaining_todos(list) == 0
  end

  def list_class(list)
    'complete' if is_complete?(list)
  end

  def remaining_todos(list)
    list[:todos].count { |todo| !todo[:completed] }
  end

  def sort_by_completed(list)
    list[:todos].sort_by { |todo| todo[:completed] ? 1 : 0 }
  end
end
