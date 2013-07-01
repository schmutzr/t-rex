# 20130628 schmutzr@post.ch
# (f) Free 2013 for post.ch

PATH_SEP = "" # seperate nodes, ie "/" for directory nodes verbatim, "" for per-character nodes (more efficient, less readable)
INFIX_SEP = "  /  " # seperate prefix (path) from suffix (file/resource) part on output, empty if PATH_SEP not empty

class T_rex
  attr_reader :node # for <=>
  attr_writer :terminal # for add_child, ugly, needs fix

  def initialize(node = nil)
    @children = Hash.new
    @terminal = false
    @node     = node
    self
  end

  def member?(path)
    path_a = self.tokenize path
    node_name = path_a.shift
    if node_name == @node
      return true if path_a.empty?
      if @children.member? path_a.first
        return @children[path_a.first].member? path_a
      end
    end
    return false
  end

  def add_child(path)
    self if self.member? path
    path_a = self.tokenize path
    child_name = path_a.shift
    if @children.member?(child_name)
      child = @children[child_name]
    else
      child = T_rex.new(child_name)
      @children[child_name] = child
    end
    if path_a.empty?
      child.terminal = true # this is slighly ugly (ie, via accessor)
    else
      child.add_child path_a.join(PATH_SEP) # re-join might also seem a bit ugly :)
    end
    self
  end

  def traverse
    result = @node
    if not @children.empty?
      subtree = @children.values.sort.collect { |c| c.traverse } 
      if subtree.length==1 and not @terminal
        result = "#{@node}#{subtree.first}"
      else
        result = "#{@node}(#{subtree.join("|")})#{"?" if @terminal}"
      end
    end
    return result
  end

  def dot
    puts "#{self.object_id} [label=\"#{@node}\"#{",style=\"filled\"" if @terminal}];"
    @children.values.sort.each { |c| puts "#{self.object_id} -> #{c.object_id};"; c.dot } if not @children.empty?
  end

  def <=>(b)
    @node <=> b.node
  end

  def tokenize(path) # not exactly, take lines including metacharacters verbatim (ie, no further subdivision)
    path_a = Array.new
    if /\.[\*\?]/.match path
      path_a[0] = path
    else
      path_a = path.split(PATH_SEP)
    end
    return path_a
  end
end
