require 'csv'

class Tabular
  attr_reader :files_root

  def initialize(files_root)
    @files_root = "#{Dir.pwd}#{files_root}"
  end

  def read(clazz, where = nil, sort = nil)
    unless where.nil?
      raise Exception 'You must specify the property key if you use the where clause.' if where[:property].nil?
      raise Exception 'You must specify the value key if you use the where clause.' if where[:value].nil?
      raise Exception 'You must specify the op key if you use the where clause.' if where[:op].nil?
    end

    unless sort.nil?
      raise Exception 'You must specify the property key if you use sort.' if where[:property].nil?
      raise Exception 'You must specify the order key if you use the sort clause.' if where[:order].nil?
    end

    op_data = get_read_op_data(clazz)
    data = []
    File.open(op_data[:file_path]) do |file|
      CSV.foreach(file) do |row|
        data << row
      end
    end

    header = data[0]
    rows = data.drop(1)

    data_obj_arr = []

    rows.each do |row|
      i = 0
      single_obj = {}
      row.map do |value|
        single_obj[header[i]] = value
        i += 1
      end

      if where.nil?
        data_obj_arr << single_obj
      else
        expected_value = where[:value].to_i
        actual_value = single_obj[where[:property]].to_i

        data_obj_arr << single_obj if eval "actual_value #{where[:op]} expected_value"
      end
    end

    puts data_obj_arr
  end

  def insert(entity)
    op_data = get_insert_op_data(entity)

    accessors = entity.instance_variables.map { |var| var.to_s.delete('@') }
    row_to_insert = accessors.map { |var| entity.send(var) }

    if !File.exist?(op_data[:file_path])
      accessors = entity.instance_variables.map { |var| var.to_s.delete('@') }
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

    File.write("#{files_root}/#{op_data[:file_name]}", lines.strip)
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

  def get_read_op_data(clazz)
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
end
