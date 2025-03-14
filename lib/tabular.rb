require 'csv'
require_relative "exceptions/tabular_error"

class Tabular
  def initialize(files_root)
    @files_root = "#{Dir.pwd}#{files_root}"
  end

  def update

  end

  def delete(clazz, where = nil)
    op_data = get_read_delete_op_data(clazz)
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

  def read(clazz, as_instances = false, where = nil, sort = nil)
    op_data = get_read_delete_op_data(clazz)
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

  def insert(instances)
    if !instances.is_a?(Array)
      raise TabularError, "insert accepts an array of instances"
    end

    first_instance = instances.first


    instances.each do |instance|
      if instance.class != first_instance.class
        raise TabularError, "all the instances passed to insert must be created from the same Class"
      end
    end

    op_data = get_insert_op_data(first_instance)
    accessors = first_instance.instance_variables.map { |var| var.to_s.delete('@') }
    rows_to_insert = []

    instances.each do |instance|
      row_from_instance = []
      accessors.each do |accessor|
        row_from_instance << instance.send(accessor)
      end
      rows_to_insert << row_from_instance
    end

    lines = ""

    if !table_exists?(nil, op_data)
      header = accessors
      lines = "#{CSV.generate_line(header)}#{rows_to_insert.map { |row| CSV.generate_line(row) }.join('')}"
    else
      existing_rows = []
      File.open(op_data[:file_path]) do |file|
        CSV.foreach(file) do |existing_row|
          existing_rows << existing_row
        end
      end

      existing_rows.push(*rows_to_insert)
      lines = existing_rows.map { |row| CSV.generate_line(row) }.join('')
    end

    File.write(op_data[:file_path], lines.strip)
  end

  def table_exists?(clazz = nil, op_data = nil)
    if op_data.nil? and clazz.nil?
      raise TabularError, 'you must provide a Class or the operation data to use table_exists?'
    end

    File.exist?(op_data ? op_data[:file_path] : get_file_path(get_file_name(clazz.name)))
  end

  def drop(clazz)
    File.delete(get_file_path(get_file_name(clazz.name))) if table_exists?(clazz)
  end

  private

  def get_insert_op_data(instance)
    class_name = instance.class.name
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
