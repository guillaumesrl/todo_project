require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'sinatra/content_for'
require 'securerandom'

configure do
  enable :sessions
  set :session_secret, ENV.fetch('SESSION_SECRET') { SecureRandom.hex(64) }
end

before do
  session[:lists] ||= []
end

helpers do
  def list_completed?(list)
    list[:todos].all? { |todo| todo[:completed] } && !list[:todos].empty?
  end

  def list_class(list)
    "complete" if list_completed?(list)
  end

  def remaining_todos(list)
    "#{list[:todos].count { |todo| todo[:completed] }} / #{list[:todos].size}"
  end

  def sorted_lists(lists)
    complete, incomplete = lists.partition { |list| list_completed?(list) }
    incomplete.each { |list| yield list, lists.index(list) }
    complete.each { |list| yield list, lists.index(list) }
  end

  def sorted_todos(todos, &)
    complete, incomplete = todos.partition { |todo| todo[:completed] }
    incomplete.each { |todo| yield todo, todos.index(todo) }
    complete.each { |todo| yield todo, todos.index(todo) }
  end
end

get '/' do
  redirect '/lists'
end

# View all the lists
get '/lists' do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

# Render the new list form
get '/lists/new' do
  erb :new_list, layout: :layout
end

# Return an error messagefor invalid name
def error_list_name(name)
  if session[:lists].any? { |list| list[:name] == name }
    'You already have a list with that name'
  elsif !(2...100).cover?(name.size)
    'List name must be between 1 and 100 characters'
  end
end

def error_fort_todo(todo_name)
  if !(1..100).cover?(todo_name.size)
    'Todo name must be between 1 and 100 chars'
  end
end

# Create a new lit
post '/lists/new' do
  list_name = params[:list_name].strip
  error = error_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = 'The list has been created'
    redirect '/lists'
  end
end

# Render a list and its todos
get '/lists/:list_id' do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  erb :list, layout: :layout
end

get '/lists/:list_id/edit' do
  @list = session[:lists][params[:list_id].to_i]
  erb :edit, layout: :layout
end

post '/lists/:list_id/edit' do
  list_id = params[:list_id].to_i
  new_list_name = params[:list_name].strip
  @list = session[:lists][list_id]
  error = error_list_name(new_list_name)
  if error
    session[:error] = error
    erb :edit, layout: :layout
  else
    @list[:name] = new_list_name
    session[:success] = "List name updated"
    redirect "/lists"
  end
end

post '/lists/:list_id/delete' do
  list_id = params[:list_id].to_i
  session[:lists].delete_at(list_id)
  session[:success] = "List has been deleted"
  redirect '/lists'
end

# add new todo

post '/lists/:list_id/todos' do
  todo_name = params[:todo].strip
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  error = error_fort_todo(todo_name)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @list[:todos] << { name: todo_name, completed: false }
    session[:success] = "the todo was added"
    redirect "/lists/#{@list_id}"
  end
end

post '/lists/:list_id/todos/:todo_id/delete' do
  list_id = params[:list_id].to_i
  todo_id = params[:todo_id].to_i
  list = session[:lists][list_id]
  list[:todos].delete_at(todo_id)
  session[:succes] = "The todo has been deleted"
  redirect "/lists/#{list_id}"
end

post '/lists/:list_id/todos/:todo_id/toggle' do
  list_id = params[:list_id].to_i
  todo_id = params[:todo_id].to_i
  list = session[:lists][list_id]
  is_completed = params[:completed] == 'true'
  p list
  p params
  list[:todos][todo_id][:completed] = is_completed

  p params
  p list
  redirect "/lists/#{list_id}"
end

post '/lists/:list_id/todos/complete-all' do
  list_id = params[:list_id].to_i
  list = session[:lists][list_id]
  list[:todos].each { |todo| todo[:completed] = true }
  session[:success] = "All todos have been completed"
  redirect "/lists/#{list_id}"
end
