#!/usr/bin/env ruby

begin
raw_key_map = `xmodmap -pke`
rescue Exception => e
	puts "**ERROR You must have installed xmodmap "
	exit	
end

unless ARGV[0]
	puts "**ERROR You must specify i3wm config file in first argument of this script"
	exit
end
#=====
key_map_hash = {}
raw_key_map.lines.each do |line| 
	begin
		key = line[/\d+ = \w+/][/\= \w+/].gsub!('= ','')
		value = line[/\d+ = \w+/][/\d+ =/].gsub!(' =','')
		key_map_hash[key] = value
	rescue
	end
end

File.open(ARGV[0], "r").each do |line|
	if line =~ / *bindsym/ and not line =~ / *\t*#/
		begin
			key = line[/\+\w+ /][/\w+/]
			newline = line.gsub!(/\+\w+ /,"+#{key_map_hash[key]} ")
			puts newline.gsub!('bindsym','bindcode')
		rescue 
			key = line[/bindsym \w+/][/ \w+/][/\w+/]
			puts line.gsub!(/bindsym \w+/,"bindcode #{key_map_hash[key]}")
		end
	else

		puts line
	end
end
