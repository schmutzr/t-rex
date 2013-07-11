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
   puts "DEBUG: #{stuff}"
end

class T_rex
   attr_reader :node # for <=>
   attr_writer :terminal # ugly, probably the default for compacted-tree mode

   def initialize(node = Array.new, children = Array.new)
      @children = children
      @terminal = false   # ( not node.nil? ) and children.empty?
      @node     = (node.kind_of? String) ? node.tr_tokenize : node
      return self
   end

   def member?(path)
      return !lookup(path).nil?
   end

   def lookup(path)
      path = path.tr_tokenize if path.kind_of? String
      debug "lookup(\"#{path.join}\") : @node=#{@node.inspect}"
      (match, rest) = (@node.empty? && !path.empty?) ? [[], path] : @node.tr_comparator(path)
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
	    best_matching_child = find_best_child(rest)
	    if best_matching_child.nil?
	       # NEW: no match of rest among children -> new child
	       @children << (best_matching_child = T_rex.new(rest))
	       best_matching_child.terminal = true
	    else
	       # DELEGATE:
	       best_matching_child.add_child(rest)
	    end
	 when @node.length > match.length
         # SPLIT: split current node, one child inherits all current children, the other equals rest (with no children)
	    # "clone" this node with non-matching path
	    split_child = T_rex.new(@node[match.length..-1], @children)
	    split_child.terminal = @terminal
	    new_child   = T_rex.new(rest)
	    new_child.terminal = true
	    new_children = [ split_child, new_child ] # slighly confusing... this node has only two children, the first one inherits all our previous children
	    @node = @node[0..(match.length-1)]
	    @children = new_children
	    @terminal = false # can't be terminal immediately after splitting
	 else debug "T_rex::add_child: return self (fall-through)"
      end
      return self
   end

   def to_re
      subex = ""
      if not @children.empty?
	 subtree = @children.collect { |child| child.to_re } 
	 if subtree.length==1 and not @terminal
	    subex = "#{subtree.first}"
	 else
	    subex = "(#{subtree.join("|")})#{"?" if @terminal}"
	 end
      end
      return "#{@node.join if not @node.nil?}#{subex}"
   end

   def compact_suffix(path="")
      node = "#{@node.join if not @node.nil?}"
      path = "#{path}#{node}"
      if !@children.empty? and !@children.nil? # recursion-case
	 subtree = (@children.collect { |child| child.compact_suffix path }).flatten # actual recursion
<<<<<<< HEAD
	 subex   = "#{node}(#{(subtree.collect {|s| s['subex']}).sort.join("|")})#{"?" if @terminal}"
	 return subtree.flatten.concat [ { 'path'=>path, 'subex'=>subex } ]
      else
	 return { 'path'=>path, 'subex'=>node } # base-case/leaf
=======
	 subex   = "(#{(subtree.collect {|s| s['subex']}).join("|")})#{"?" if @terminal}"
	 return [{ 'path'=>path, 'subex'=>subex }].concat subtree
      else
	 return [{ 'path'=>path, 'subex'=>node }] # base-case/leaf
>>>>>>> 7e8035a71e6d4e24fd49fa9da3171da25c2867dc
      end
   end

   def to_dot(path=nil)
      prefix = path.nil? ? [ "digraph {", "edge [arrowtail=\"none\",arrowhead=\"none\"]", "node [shape=\"box\",style=\"rounded\"]" ] : nil
      suffix = path.nil? ? "}" : nil
      path="#{path}#{@node.join if not @node.nil?}"
      subtree_dot = @children.sort.collect { |child| [ "#{self.object_id} -> #{child.object_id}", "#{child.to_dot(path)}" ] } if not @children.empty? 
      node_dot    = "#{self.object_id} [label=\"#{((@node.nil?) ? "" : @node.join)}\",tooltip=\"#{path}\"#{",style=\"rounded,filled\"" if @terminal}]"
      return ([ prefix, node_dot, subtree_dot, suffix ].compact.flatten.reject {|r| /^$/.match r}).join(";\n")
   end

   def <=>(b)
      @node <=> b.node
   end

end
