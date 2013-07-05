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

prefix = T_rex.new()

test_prefix.each do |line|
   new_node = line.chomp # .sub(/^\//,"")
   prefix.add_child(new_node)
end

suffix = T_rex.new()

test_suffix.each do |line|
   suffix.add_child(line.chomp.sub(/^\//,""))
end

re_t = "#{prefix.make_re}/?#{suffix.make_re}"

puts "re: #{re_t}"
re =  Regexp.new re_t
puts ""

#test_prefix.each do |p|
#  test_suffix.each do |s|
#    test_string = "#{p}/#{s}".gsub(/\.\*/,"X")
#    if re.match test_string
#      puts "ok  : #{test_string}"
#    else
#      puts "fail: #{test_string}"
#    end
#  end
#end

#puts prefix.make_dot
