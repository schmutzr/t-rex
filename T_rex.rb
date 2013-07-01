# 20130628 schmutzr@post.ch
# (f) Free 2013 for post.ch

PATH_SEP = "" # seperate nodes, ie "/" for directory nodes verbatim, "" for per-character nodes (more efficient, less readable)
INFIX_SEP = "  /  " # seperate prefix (path) from suffix (file/resource) part on output, empty if PATH_SEP not empty

class T_rex
  attr_reader :node
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
        child = @children[path_a.first]
        return child.member? path_a
      else
        return false
      end
    else
      return false
    end
  end

  def add_child(path)
    path_a = self.tokenize path
    child_name = path_a.shift
    puts "T_rex.add_child(#{path}): child_name=#{child_name}, tokenize=#{path_a.join(",")}"
    if @children.member?(child_name)
      child = @children[child_name]
    else
      child = T_rex.new(child_name)
      @children[child_name] = child
    end
    if path_a.empty?
      @terminal = true
      puts "\tterminal"
    else
      child.add_child(path_a.join(PATH_SEP))
    end
    self
  end

  def traverse
    result = @node
    if not @children.empty?
      subtree_result_a = @children.values.sort.collect{|c| c.traverse}
      if subtree_result_a.length > 1
        subtree_result = "(#{subtree_result_a.join("|").gsub(/[\n\r]/,"")})"
      else
        subtree_result = subtree_result_a.first
      end
      if @terminal
        result = "(#{@node}|#{@node}#{PATH_SEP}#{subtree_result})"
      else
        result = "#{@node}#{PATH_SEP}#{subtree_result}"
      end
    end
    return result
  end

  def <=>(b)
    @node <=> b.node
  end

  def tokenize(path)
    path_a = Array.new
    if /\.[\*\?]/.match path
      path_a[0] = path
      puts "tokenize: take #{path} verbatim"
    else
      path_a = path.split(PATH_SEP)
    end
    return path_a
  end
end
