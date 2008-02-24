#!/usr/bin/env ruby

class Application
  def start
    ARGV.each do |_file|
      content = File.open(_file, "r") do |_input|
        _input.readlines.map { |_line|
          _line.chomp
        }
      end

      File.open(_file, "wb") do |_output|
        _output.puts(content)
      end
    end
  end
end

unless defined? Test::Unit
  Application.new.start
  exit 0
end
  
