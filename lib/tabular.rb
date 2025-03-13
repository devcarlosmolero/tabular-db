require 'csv'
require_relative "exceptions/query_option_exception"

class Tabular
  def initialize(files_root)
    @files_root = "#{Dir.pwd}#{files_root}"
  end

  def delete(clazz, where = nil)
    unless where.nil?
      raise_where where
    end

    op_data = get_read_delete_op_data(clazz)
    data = read(clazz)
    header = data[:header]

    if where.nil?
      lines = CSV.generate_line(header)
      File.write(op_data[:file_path], lines.strip)
    else
      unfiltered_rows = data[:rows]
      filtered_rows = []
      unfiltered_rows.each do |row|
        expected_value = where[:value].to_i
        actual_value = row[where[:property]].to_i

        filtered_rows << row unless eval "actual_value #{where[:op]} expected_value"
      end

      lines = CSV.generate_line(header)
      filtered_rows.each do |row|
        row_as_array = row.keys.map { |key| row[key] }
        lines += CSV.generate_line(row_as_array)
      end

      File.write(op_data[:file_path], lines.strip)
    end
  end

  # TODO: Return as clazz (Class) entities option, replace individual options for 'options' variable
  def read(clazz, where = nil, sort = nil, as_instance = false)
    unless where.nil?
      raise_where where
    end

    unless sort.nil?
      raise_sort sort
    end

    op_data = get_read_delete_op_data(clazz)
    unfiltered_rows = []
    File.open(op_data[:file_path]) do |file|
      CSV.foreach(file) do |row|
        unfiltered_rows << row
      end
    end

    header = unfiltered_rows[0]
    rows = unfiltered_rows.drop(1)

    filtered_rows = []

    rows.each do |row|
      i = 0
      single_obj = {}
      row.map do |value|
        single_obj[header[i]] = value
        i += 1
      end

      if where.nil?
        filtered_rows << single_obj
      else
        expected_value = where[:value].to_i
        actual_value = single_obj[where[:property]].to_i

        filtered_rows << single_obj if eval "actual_value #{where[:op]} expected_value"
      end
    end

    {
      header: header,
      rows: filtered_rows
    }
  end

  def insert(entity)
    puts entity.inspect
    op_data = get_insert_op_data(entity)
    puts op_data.inspect

    accessors = entity.instance_variables.map { |var| var.to_s.delete('@') }
    row_to_insert = accessors.map { |var| entity.send(var) }

    if !File.exist?(op_data[:file_path])
      header = accessors
      lines = "#{CSV.generate_line(header)}#{CSV.generate_line(row_to_insert)}"
    else
      data = []
      File.open(op_data[:file_path]) do |file|
        CSV.foreach(file) do |row|
          data << row
        end
      end

      data << row_to_insert
      lines = data.map { |row| CSV.generate_line(row) }.join('')
    end
    File.write(op_data[:file_path], lines.strip)
  end

  private

  def get_insert_op_data(entity)
    class_name = entity.class.name
    file_name = get_file_name(class_name)
    file_path = get_file_path(file_name)

    {
      class_name: class_name,
      file_name: file_name,
      file_path: file_path
    }.transform_keys(&:to_sym)
  end

  def get_read_delete_op_data(clazz)
    file_name = get_file_name(clazz.name)
    file_path = get_file_path(file_name)

    {
      file_name: file_name,
      file_path: file_path
    }.transform_keys(&:to_sym)
  end

  def get_file_name(class_name)
    "#{class_name.downcase}s.csv"
  end

  def get_file_path(file_name)
    "#{@files_root}/#{file_name}"
  end

  def get_entity_accessors(entity)
    entity.instance_variables.map { |var| var.to_s.delete('@') }
  end

  def raise_where(where)
    raise QueryOptionException "where" "property" if where[:property].nil?
    raise QueryOptionException "where" "op" if where[:op].nil?
    raise QueryOptionException "where" "value" if where[:value].nil?
  end

  def raise_sort (sort)
    raise QueryOptionException "where" "property" if where[:property].nil?
    raise QueryOptionException "where" "order" if where[:order].nil?
  end

  def use_where(unfiltered_rows, where)
  end
end
