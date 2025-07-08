<p align="center">
<img src="./logo.svg" width="80px" height="80px"/>
</p>
<h1 align="center">Tabular DB</h1>
<p align="center">
<img src="https://github.com/devcarlosmolero/tabular-db/actions/workflows/rspec.yml/badge.svg"/>
</p>

Have you ever wanted to use your CSV files as a SQL database?

Ever wanted to be able to debug table views while prototyping your application locally?

Now you can.

Tabular DB allows you to use CSV files as a database and leverage existing CSV viewers to enhance the prototyping experience.

## Table of Contents

- [Create](#create)
- [Read](#read)
- [Update](#update)
- [Delete](#delete)
- [Create If Not Exist](#create-if-not-exist)
- [Drop](#drop)

## Create

Use the `create` method to add new records to a CSV file. Pass an array of instances to be created.

```ruby
db = TabularDB.new('/path/to/csv/files')
users = [User.new(name: 'John', age: 25), User.new(name: 'Jane', age: 28)]
db.create(users) # Add new users to the CSV file
```

## Read

Use the `read` method to retrieve data from a CSV file. You can specify options such as `limit`, `offset`, `where`, and `sort` to filter and sort the results.

```ruby
db = TabularDB.new('/path/to/csv/files')
options = { limit: 10, offset: 0, where: 'row["name"] == "John"', sort: 'row["age"]' }
result = db.read(User, options)
puts result[:rows] # Output the rows that match the criteria
```

## Update

Use the `update` method to modify existing records in a CSV file. You need to specify a `where` condition to identify the records to update and provide the new values.

```ruby
db = TabularDB.new('/path/to/csv/files')
where = 'row["name"] == "John"'
updated_values = { age: 30 }
result = db.update(User, where, updated_values)
puts result[:rows] # Output the updated rows
```

## Delete

Use the `delete` method to remove records from a CSV file. You can specify a `where` condition to identify the records to delete.

```ruby
db = TabularDB.new('/path/to/csv/files')
where = 'row["name"] == "John"'
db.delete(User, where) # Delete users with the name "John"
```

## Create If Not Exist

Use the `create_if_not_exist` method to create a new CSV file with a specified header if it does not already exist.

```ruby
db = TabularDB.new('/path/to/csv/files')
header = ['name', 'age']
db.create_if_not_exist(User, header) # Create a new CSV file with the specified header if it doesn't exist
```

## Drop

Use the `drop` method to delete a CSV file associated with a class.

```ruby
db = TabularDB.new('/path/to/csv/files')
db.drop(User) # Delete the CSV file associated with the User class
```
