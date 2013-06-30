require t-rex

prefix = Tree.new(ARGF.gets)

ARGF.each_line do |line|
   break if /^$/.match line
   prefix.add_child(line.chomp.sub(/^\//,""))
end

suffix = Tree.new(ARGF.gets)

ARGF.each_line do |line|
   suffix.add_child(line.chomp.sub(/^\//,""))
end

puts "#{prefix.traverse}#{INFIX_SEP}#{suffix.traverse}"
