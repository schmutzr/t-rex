#!/usr/bin/ruby -w
# 20130628 schmutzr@post.ch
#

PATH_SEP = "/"

class Tree
   def initialize(path)
      @children = Hash.new
      path_a = path.split(PATH_SEP)
      @node = path_a.shift
      self.add_child(path_a.join(PATH_SEP)) if(not path_a.empty?)
      self
   end

   def add_child(child_path)
      child_path_a = child_path.split(PATH_SEP)
      child_name = child_path_a.shift
      if @children.member?(child_name)
	 child = @children[child_name]
      else
	 child = Tree.new(child_name)
	 @children[child_name] = child
      end
      child.add_child(child_path_a.join(PATH_SEP)) if(not child_path_a.empty?)
      self
   end

   def traverse
      if @children.empty?
	 @node
      else
	 subtree_result_a = @children.values.collect{|c| c.traverse}
	 if subtree_result_a.length > 1
	    subtree_result = "(#{subtree_result_a.join("|").gsub(/[\n\r]/,"")})"
	 else
	    subtree_result = subtree_result_a[0]
	 end
	 "#{@node}#{PATH_SEP}#{subtree_result}"
      end
   end
end

t = Tree.new(ARGF.gets)

ARGF.each_line do |l|
   break if /^$/.match l
   t.add_child(l.chomp.sub(/^\//,""))
end

puts "#{t.traverse}#{PATH_SEP}(#{ARGF.to_a.map {|e| e.chomp} .join("|")})"
