require "csv"

class Tabular
  attr_reader :files_root

  def initialize(files_root)
    @files_root = "#{Dir.pwd}#{files_root}"
  end

  def insert(entity, name = nil)
    class_name = entity.class.name
    file_name = ""

    file_name = if name.nil?
      "#{class_name.downcase}s.csv"
    else
      name
    end

    accessors = entity.instance_variables.map { |var| var.to_s.delete("@") }
    row = accessors.map { |var| entity.send(var) }.join(",")
    header = ""
    data = ""

    if !File.exist?("#{files_root}/#{file_name}")
      header = accessors.join(",")
      data = "#{header}\n#{row}"
    else
      # TODO: Fetch the whole CSV file and append a new row
    end

    File.write("#{files_root}/#{file_name}", data)
  end
end
