# 20130628 schmutzr@post.ch
# (f) Free 2013 for post.ch

PATH_SEP = "" # seperate nodes, ie "/" for directory nodes verbatim, "" for per-character nodes (more efficient, less readable)
INFIX_SEP = "  /  " # seperate prefix (path) from suffix (file/resource) part on output, empty if PATH_SEP not empty

#
# MONKEY PATCH STUFF
# FIXME: need namespace-containment
class Array
   def tr_comparator(b) # compares self + b element wise, returns array of arrays: [ matching_elements, rest_elements_of_b ]
      # non-lispy style this time...
      split_index = ( self.zip(b).take_while { |pair| pair[0]==pair[1] } ).length
      if split_index == 0
	 return [ [], b ]
      else
	 return [b[0..(split_index-1)], b[split_index..-1]]
      end
   end
end

class String
   def tr_tokenize # not exactly, take lines including metacharacters verbatim (ie, no further subdivision)
      if /\.[\*\?]/.match self
	 return [ self ]
      else
	 return self.split(PATH_SEP)
      end
   end
end


#
#
# T_rex (roar!)
#
#
# this version uses token-arrays instead if simple (one-character) string as node-names/content
# - enabling acceptable tree-compression on add
# - more general tokenize handling (all in String#tr_tokenize)

def debug(stuff)
   true or  
   puts "DEBUG: #{stuff}"
end

class T_rex
   attr_reader :node # for <=>
   attr_writer :terminal # for add_child, ugly, needs fix

   def initialize(node = Array.new, children = Array.new)
      @children = children
      @terminal = false   # ( not node.nil? ) and children.empty?
      @node     = (node.kind_of? String) ? node.split() : node
      return self
   end

   def member?(path)
      return !lookup(path).nil?
   end

   def lookup(path)
      path = path.tr_tokenize if path.kind_of? String
      (match, rest) = (@node.empty? && !path.empty) ? [[], path] : @node.tr_comparator(path)
      if match==@node
	 if rest.empty?
	    return self # found
	 else
	    best_matching_child = self.find_best_child(rest)
	    return best_matching_child.lookup(rest) if not best_matching_child.nil?
	 end
      end
      return false
   end

private
   def find_best_child(rest)
      candidates = []
      if not @children.empty?
	 candidates = @children.collect do |child|
	    (m, r) = child.node.tr_comparator rest
	    child_match_length = m.length
	    [ child, child_match_length ] if child_match_length > 0
	 end
      end
      candidates.compact!
      if not candidates.empty?
	 best_matching_child = (candidates.sort {|a,b| a[1]<=>b[1]})[-1][0]
      else
	 best_matching_child = nil
      end
      return best_matching_child
   end

public

   def add_child(path)
      # return self if self.member? path
      path = path.tr_tokenize if path.kind_of? String
      (match, rest) = (@node.empty?) ? [ [], path ] : @node.tr_comparator(path)
      case true
	 when ( match.empty? and rest.empty? )
         # terminate recursion
	    @terminal = true
	 when ( !rest.empty? and ( @node == match or @node.empty? ))
         # add child, check for (partially) matching children, delegate
	    if @children.empty?
	       candidates = []
	    else
	       candidates = @children.collect do |child|
		  (m, r) = child.node.tr_comparator rest
		  child_match_length = m.length
		  [ child, child_match_length ] if child_match_length > 0
	       end
	    end
	    candidates.compact!
	    if not candidates.empty?
               # DELEGATE: find longest (element/character wise) match of rest among children
	       best_matching_child = (candidates.sort {|a,b| a[1]<=>b[1]})[-1][0]
	       best_matching_child.add_child rest
	    else
               # NEW: no match of rest among children -> new child
	       @children << T_rex.new(rest)
	    end
	 when @node.length > match.length
         # SPLIT: split current node, one child inherits all current children, the other equals rest (with no children)
	    # "clone" this node with non-matching path
	    split_child_path = @node[match.length..-1]
	    new_children = [ T_rex.new(split_child_path, @children), T_rex.new(rest) ] # slighly confusing... this node has only two children, the first one inherits all our previous children
	    @node = @node[0..(match.length-1)]
	    @children = new_children
	 else debug "T_rex::add_child: return self (fall-through)"
      end

      return self
   end

   def make_re
      result = ""
      if not @children.empty?
	 subtree = @children.collect { |child| child.make_re } 
	 if subtree.length==1 and not @terminal
	    result = "#{subtree.first}"
	 else
	    result = "(#{subtree.join("|")})#{"?" if @terminal}"
	 end
      end
      return "#{@node.join if not @node.nil?}#{result}"
   end

   def make_dot(path=nil)
      prefix = path.nil? ? [ "digraph {", "edge [arrowtail=\"none\",arrowhead=\"none\"]", "node [shape=\"box\",style=\"rounded\"]" ] : nil
      suffix = path.nil? ? "}" : nil
      path="#{path}#{@node.join if not @node.nil?}"
      subtree_dot = @children.sort.collect { |child| [ "#{self.object_id} -> #{child.object_id}", "#{child.make_dot(path)}" ] } if not @children.empty? 
      node_dot    = "#{self.object_id} [label=\"#{(@terminal) ? path : ((@node.nil?) ? "" : @node.join)}\",tooltip=\"#{path}\"#{",style=\"filled\"" if @terminal}]"
      return ([ prefix, node_dot, subtree_dot, suffix ].compact.flatten.reject {|r| /^$/.match r}).join(";\n")
   end

   def <=>(b)
      @node <=> b.node
   end

end
