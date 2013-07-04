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
	 #debug "      tr_comparator: \"#{self.join}\"=?\"#{b.join}\" -> [[], #{b}]"  
	 return [ [], b ]
      else
	 #debug "      tr_comparator: \"#{self.join}\"=?\"#{b.join}\" -> [#{b[0..(split_index-1)]}], [#{b[split_index..-1]}]"
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
      #debug "T_rex::initialize([#{@node.join}], [#{@children.join(",") if !@children.empty?}])"
      return self
   end

   def member?(path)
      return false
   end

   def add_child(path)
      # return self if self.member? path
      path = path.tr_tokenize if path.kind_of? String
      (match, rest) = @node.empty? ? [ [], path ] : @node.tr_comparator(path)
      #debug "T_rex::add_child: node=[#{@node.join}], match=[#{match.join}], rest=[#{rest.join}]"
      case true
	 when ( match.empty? and rest.empty? )      # terminate recursion
	    debug "### 1"
	    debug "T_rex::add_child: return self"	
	    @terminal = true
	 when ( !rest.empty? and ( @node == match or @node.empty? )) # add child, check for (partially) matching children, delegate
	    debug "### 2"
	    if @children.empty?
	       best_matching_child_candidates = []
	    else
	       best_matching_child_candidates = @children.collect do |child|
		  #debug "   T_rex::add_child: check child \"#{child.to_s}\""
		  (m, r) = child.node.tr_comparator rest
		  child_match_length = m.length
		  #debug "   T_rex::add_child: check child [#{child.node.join}] against [#{rest.join}] match: [#{m.join}] length: #{m.length}"
		  [ child, child_match_length ] if child_match_length > 0
	       end
	    end
	    best_matching_child_candidates.compact!
	    if best_matching_child_candidates.empty?
	       debug "T_rex::add_child: CREATE CHILD : parent=\"#{@node.join}\"   [#{rest.join}]"
	       @children << T_rex.new(rest)
	    else
	       #debug "T_rex::add_child: update candidates length=#{best_matching_child_candidates.length} [#{best_matching_child_candidates.to_s}]"
	       best_matching_child = (best_matching_child_candidates.sort {|a,b| a[1]<=>b[1]})[-1][0]
	       debug "T_rex::add_child: UPDATE CHILD : parent=\"#{@node.join}\"   [#{best_matching_child.node.join}] <- [#{rest.join}]"
	       best_matching_child.add_child rest
	    end
	 when @node.length > match.length           # split
	    debug "### 3"
	    debug "T_rex::add_child: SPLIT        : \"#{@node.join}\" -> \"#{@node[0..(match.length-1)].join}\", children \"#{@node[match.length..-1].join}\" and \"#{rest.join}\""
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
