
ARGV.each do |_file|
  content = File.open(_file, "r") do |_input|
    _input.readlines
  end

  File.open(_file, "wb") do |_output|
    _output.write(content)
  end
end
