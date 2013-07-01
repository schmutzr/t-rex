#!/usr/bin/ruby -w
# 20130630 schmutzr@post.ch
require "T_rex"

test_prefix = Array.new
test_suffix = Array.new

ARGF.each_line do |line|
  break if /^$/.match line
  test_prefix << line.chomp
end

ARGF.each_line do |line|
  test_suffix << line.chomp
end

prefix = T_rex.new(test_prefix.first)

test_prefix.each do |line|
   break if /^$/.match line
   new_node = line.chomp # .sub(/^\//,"")
   puts "add: #{new_node}"
   prefix.add_child(new_node) if not prefix.member? new_node
end

suffix = T_rex.new(test_suffix.first)

test_suffix.each do |line|
   suffix.add_child(line.chomp.sub(/^\//,""))
end

puts "re: #{prefix.traverse}/?#{suffix.traverse}"
re =  Regexp.new "#{prefix.traverse}/?#{suffix.traverse}"
puts ""
#exit 0
#
#test_prefix.each do |p|
#  test_suffix.each do |s|
#    test_string = "#{p}/#{s}".gsub(/\.\*/,"X")
#    if re.match test_string
#      puts "ok"
#    else
#      puts "fail: #{test_string}"
#    end
#  end
#end
#
#
