require 'csv'
require "faker"
require_relative "./tabular_db_error"

class TabularDB
  def initialize(files_root)
    raise TabularDBError, "files_root argument is required" if files_root.nil?
    @files_root = "#{Dir.pwd}#{files_root}"
  end

  def count(where)
    op_data = get_read_update_delete_op_data(clazz)
    unfiltered_rows = CSV.read(op_data[:file_path])
    rows = unfiltered_rows.map { |row| row_to_object(row, header) }

    if where
      rows.select! { |row| eval where }
    end

    rows.sort_by! { |row| eval sort } if sort
    rows = rows.drop(offset)
    rows = rows.first(limit) unless limit == 0

    return rows.count
  end

  def create(instances)
    raise TabularDBError, "instances must be an array" unless instances.is_a?(Array)

    first_instance = instances.first
    instances.each do |instance|
      raise TabularDBError, "all the instances must be created from the same Class" if instance.class != first_instance.class
    end

    op_data = get_create_op_data(first_instance)
    accessors = first_instance.instance_variables.map { |var| var.to_s.delete('@') }
    rows_to_create = instances.map do |instance|
      accessors.map { |accessor| instance.send(accessor) }
    end

    lines = ""
    if !table_exist?(nil, op_data)
      header = accessors
      lines = "#{CSV.generate_line(header)}#{rows_to_create.map { |row| CSV.generate_line(row) }.join('')}"
    else
      existing_rows = CSV.read(op_data[:file_path])
      rows = existing_rows + rows_to_create
      lines = rows.map { |row| CSV.generate_line(row) }.join('')
    end

    File.write(op_data[:file_path], lines.strip)
  end

  def read(clazz, options = nil)
    raise TabularDBError, 'clazz argument is required' if clazz.nil?
    raise TabularDBError, 'options argument is required, you must pass at least an empty object {}' if options.nil?

    limit = options[:limit].nil? ? 0 : options[:limit]
    offset = options[:offset].nil? ? 0 : options[:offset]

    op_data = get_read_update_delete_op_data(clazz)
    unfiltered_rows = CSV.read(op_data[:file_path])

    header = unfiltered_rows.shift
    rows = unfiltered_rows.map { |row| row_to_object(row, header) }

    if !options[:where].nil?
      rows.select! { |row| eval options[:where] }
    end

    rows.sort_by! { |row| eval options[:sort] } if !options[:sort].nil?
    filtered_count = rows.size
    rows = rows.drop(offset)
    rows = rows.first(limit) unless limit == 0

    {
      header: header,
      rows: rows,
      total_count: unfiltered_rows.size,
      has_next: offset + rows.size < filtered_count,
      has_prev: offset > 0
    }
  end

  def update(clazz, where = nil, updated_values = nil)
    raise TabularDBError, 'clazz argument is required' if clazz.nil?
    raise TabularDBError, "where argument is required for update operations" if where.nil?
    raise TabularDBError, "updated_values argument is required for update operations" if updated_values.nil?

    op_data = get_read_update_delete_op_data(clazz)
    data = read(clazz, {})
    header = data[:header]
    rows = data[:rows]

    updated_rows = []
    new_rows = rows.map do |row|
      if eval where
        updated_values.each { |key, value| row[key.to_s] = value.to_s unless value.nil? }
        updated_rows << row
        row
      else
        row
      end
    end

    lines = CSV.generate_line(header)
    new_rows.each do |row|
      lines += CSV.generate_line(row.values)
    end

    File.write(op_data[:file_path], lines.strip)

    {
      header: header,
      rows: updated_rows
    }
  end

  def delete(clazz, where = nil)
    raise TabularDBError, 'clazz argument is required' if clazz.nil?

    op_data = get_read_update_delete_op_data(clazz)
    data = read(clazz, {})
    header = data[:header]
    rows = data[:rows]

    if where
      rows.reject! { |row| eval where }
    else
      rows = []
    end

    lines = CSV.generate_line(header)
    rows.each do |row|
      lines += CSV.generate_line(row.values)
    end

    File.write(op_data[:file_path], lines.strip)
  end

  def create_if_not_exist(clazz, header)
    raise TabularDBError, 'clazz argument is required' if clazz.nil?
    raise TabularDBError, 'header must be an array' if !header.is_a?(Array)

    if !table_exist?(clazz)
      file_name = get_file_name(clazz.name)
      file_path = get_file_path(file_name)

      File.write(file_path, CSV.generate_line(header).strip)
    end
  end

  def table_exist?(clazz = nil, op_data = nil)
    raise TabularDBError, 'you must provide a Class or the operation data to use table_exist?' if op_data.nil? and clazz.nil?
    File.exist?(op_data ? op_data[:file_path] : get_file_path(get_file_name(clazz.name)))
  end

  def drop(clazz)
    raise TabularDBError, 'clazz argument is required' if clazz.nil?
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
    raise TabularDBError, "row must be an array" unless row.is_a?(Array)
    raise TabularDBError, "header must be an array" unless header.is_a?(Array)

    i = 0
    row_as_obj = {}
    row.map do |value|
      row_as_obj[header[i]] = value
      i += 1
    end

    row_as_obj
  end
end
