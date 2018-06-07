require 'pg'

class DatabasePersistence
  def initialize(logger)
    @db = PG.connect(dbname:"todos")
    @logger = logger
  end
  
  def query(statement, *params)
    @logger.info("#{statement}: #{params}")
    @db.exec_params(statement, params)
  end

  def find_list(list_id)
    list_sql = 'SELECT * FROM lists WHERE id = $1'
    result = query(list_sql, list_id)
    tuple = result.first

    {id: list_id, name: tuple['name'], todos: find_todos_for_list(list_id)}
  end
  
  def all_lists
    sql = 'SELECT * FROM lists'
    result = query(sql)

    result.map do |tuple|
      list_id = tuple['id']
      {id: tuple['id'], name: tuple['name'], todos: find_todos_for_list(list_id)}
    end
  end
  
  def create_new_list(list_name)
    sql = 'INSERT INTO lists (name) VALUES ($1)'
    result = query(sql, list_name)
    p result
  end
  
  def update_todo_list(id, new_name)
    sql = 'UPDATE lists SET name = $1 WHERE id = $2'
    query(sql, new_name, id)
  end
  
  def delete_list(id)
    sql = 'DELETE FROM todos WHERE list_id = $1'
    query(sql, id)
    
    sql = 'DELETE FROM lists where id = $1'
    query(sql, id)
  end
  
  def create_new_todo_list(list_id, text)
    sql = 'INSERT INTO todos (name, completed, list_id) VALUES ($1, $2, $3)'
    query(sql, text, false, list_id)
  end
  
  def delete_todo_from_list(list_id, todo_id)
    sql = 'DELETE FROM todos WHERE id = $1 AND list_id = $2'
    query(sql, todo_id, list_id)
  end
  
  def update_todo_status(list_id, todo_id, todo_status)
    sql = 'UPDATE todos SET completed = $1 WHERE id = $2 AND list_id = $3'
    new_todo_status = todo_status == 'true'
    query(sql, new_todo_status, todo_id, list_id)
  end
  
  def complete_all_todos(list_id)
    sql = 'UPDATE todos SET completed = true WHERE list_id = $1'
    query(sql, list_id)
  end

  private

  def find_todos_for_list(list_id)
    todo_sql = 'SELECT * FROM todos WHERE list_id = $1'
    todos_result = query(todo_sql, list_id)

    todos_result.map do |todo_tuple|
      {id: todo_tuple['id'], name: todo_tuple['name'], completed: todo_tuple['completed'] == 't'}
    end
  end
end