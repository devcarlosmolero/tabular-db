require 'csv'
require_relative "exceptions/tabular_error"

class Tabular
  def initialize(files_root)
    if files_root.nil?
      raise TabularError, "files_root argument is required"
    end

    @files_root = "#{Dir.pwd}#{files_root}"
  end

  def create(instances)
    if !instances.is_a?(Array)
      raise TabularError, "instances should be an array"
    end

    first_instance = instances.first

    instances.each do |instance|
      if instance.class != first_instance.class
        raise TabularError, "all the instances must be created from the same Class"
      end
    end

    op_data = get_create_op_data(first_instance)
    accessors = first_instance.instance_variables.map { |var| var.to_s.delete('@') }
    rows_to_create = []

    instances.each do |instance|
      row_from_instance = []
      accessors.each do |accessor|
        row_from_instance << instance.send(accessor)
      end
      rows_to_create << row_from_instance
    end

    lines = ""

    if !table_exist?(nil, op_data)
      header = accessors
      lines = "#{CSV.generate_line(header)}#{rows_to_create.map { |row| CSV.generate_line(row) }.join('')}"
    else
      existing_rows = []
      File.open(op_data[:file_path]) do |file|
        CSV.foreach(file) do |existing_row|
          existing_rows << existing_row
        end
      end

      rows = existing_rows + rows_to_create
      lines = rows.map { |row| CSV.generate_line(row) }.join('')
    end

    File.write(op_data[:file_path], lines.strip)
  end

  def read(clazz, where = nil, sort = nil)
    if clazz.nil?
      raise TabularError, 'clazz argument is required'
    end

    op_data = get_read_update_delete_op_data(clazz)
    unfiltered_rows = []
    File.open(op_data[:file_path]) do |file|
      CSV.foreach(file) do |row|
        unfiltered_rows << row
      end
    end

    header = unfiltered_rows[0]
    rows = unfiltered_rows.drop(1)

    obj_array = []

    rows.each do |row|
      row_as_obj = row_to_object(row, header)

      if where.nil?
        obj_array << row_as_obj
      else
        instance = clazz.new(row_as_obj.transform_keys(&:to_sym))
        obj_array << row_as_obj if eval where
      end
    end

    {
      header: header,
      rows: obj_array
    }
  end

  def update(clazz, where = nil, updated_values = nil)
    if clazz.nil?
      raise TabularError, 'clazz argument is required'
    end

    if where.nil?
      raise TabularError, "where argument is required for update operations"
    end

    if updated_values.nil?
      raise TabularError, "updated_values argument is required for update operations"
    end

    op_data = get_read_update_delete_op_data(clazz)
    data = read(clazz)
    header = data[:header]

    obj_array = data[:rows]
    updated_obj_arr = []

    obj_array = obj_array.map do |obj|
      instance = clazz.new(obj.transform_keys(&:to_sym))
      if eval where
          new_obj = obj
          header.each do |key|
            if !updated_values[key.to_sym].nil?
              new_obj[key] = updated_values[key.to_sym]
            end
          end
          updated_obj_arr << new_obj
          new_obj
      else
          obj
      end
    end

    lines = CSV.generate_line(header)
    obj_array.each do |obj|
      obj_as_array = obj.keys.map { |key| obj[key] }
      lines += CSV.generate_line(obj_as_array)
    end

    File.write(op_data[:file_path], lines.strip)

    {
      header: header,
      rows: updated_obj_arr
    }
  end

  def delete(clazz, where = nil)
    if clazz.nil?
      raise TabularError, 'clazz argument is required'
    end

    op_data = get_read_update_delete_op_data(clazz)
    data = read(clazz)
    header = data[:header]

    if where.nil?
      lines = CSV.generate_line(header)
      File.write(op_data[:file_path], lines.strip)
    else
      unfiltered_obj_array = data[:rows]
      filtered_obj_array = []

      unfiltered_obj_array.each do |obj|
        instance = clazz.new(row_to_object(obj.values, header).transform_keys(&:to_sym))
        filtered_obj_array << obj unless eval where
      end

      lines = CSV.generate_line(header)
      filtered_obj_array.each do |obj|
        obj_as_array = obj.keys.map { |key| obj[key] }
        lines += CSV.generate_line(obj_as_array)
      end

      File.write(op_data[:file_path], lines.strip)
    end
  end

  def create_if_not_exist(clazz, header)
    if clazz.nil?
      raise TabularError, 'clazz argument is required'
    end

    if !header.is_a(Array)
      raise TabularError, 'header should be an array'
    end

    file_name = get_file_name(clazz.name)
    file_path = get_file_path(file_name)

    if !table_exist?
      File.write(op_data[:file_path], CSV.generate_line(header).strip)
    end
  end

  def table_exist?(clazz = nil, op_data = nil)
    if op_data.nil? and clazz.nil?
      raise TabularError, 'you must provide a Class or the operation data to use table_exist?'
    end

    File.exist?(op_data ? op_data[:file_path] : get_file_path(get_file_name(clazz.name)))
  end

  def drop(clazz)
    if clazz.nil?
      raise TabularError, 'clazz argument is required'
    end

    File.delete(get_file_path(get_file_name(clazz.name))) if table_exist?(clazz)
  end

  private

  def get_create_op_data(instance)
    class_name = instance.class.name
    file_name = get_file_name(class_name)
    file_path = get_file_path(file_name)

    {
      class_name: class_name,
      file_name: file_name,
      file_path: file_path
    }.transform_keys(&:to_sym)
  end

  def get_read_update_delete_op_data(clazz)
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

  def get_instance_accessors(instance)
    instance.instance_variables.map { |var| var.to_s.delete('@') }
  end

  def row_to_object(row, header)
    unless row.is_a?(Array)
      raise TabularError, "row must be an array"
    end

    i = 0
    row_as_obj = {}
    row.map do |value|
      row_as_obj[header[i]] = value
      i += 1
    end

    row_as_obj
  end
end
