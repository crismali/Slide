class Slide::Rewriter < Parser::Rewriter

  AT_SIGN = "@"
  CLOSE_PAREN = ")"
  COMMA = ","
  ELIPSES = "..."
  ELSE_IF = "else if"
  ELSIF = "elsif"
  EQUAL_SIGN = "="
  FAT_ARROW = "=>"
  NEW_LINE = "\n"
  OPEN_PAREN = "("
  QUESTION_MARK = "?"
  SPACE = " "
  SPLAT = "*"
  THIS = "this"
  TWO = 2

  BRACKET_WRAP = /\A\[.*\]\z/

  attr_accessor :block_start_nodes

  def initialize
    self.block_start_nodes = []
  end

  def on_if(node)
    super
    keyword = node.loc.keyword
    conditional_expression = node.children.first.loc.expression
    replace keyword, ELSE_IF if keyword.source == ELSIF
    wrap_in_existential_operator(conditional_expression)
  end

  def on_send(node)
    super
    return if bracket_method?(node)
    prepend_with_at_sign(node) if node.loc.dot.nil?

    if method_parentheses?(node)
      process_send_with_parentheses(node)
    else
      process_send_without_parentheses(node)
    end
  end

  def on_block(node)
    block_start_nodes << node.children.first
    super
    remove node.loc.begin
    replace node.loc.end, CLOSE_PAREN
    block_start_nodes.pop
  end

  def on_args(node)
    super
    return if node.loc.expression.nil?

    if node.loc.begin.nil?
      insert_before node.loc.expression, OPEN_PAREN
      insert_after node.loc.expression, (CLOSE_PAREN + SPACE + FAT_ARROW + NEW_LINE)
    else
      replace node.loc.begin, (SPACE + OPEN_PAREN)
      replace node.loc.end, (CLOSE_PAREN + SPACE + FAT_ARROW + NEW_LINE)
    end
  end

  def on_splat(node)
    super
    remove node.loc.operator
    insert_after node.loc.expression, ELIPSES
  end

  def on_restarg(node)
    super
    replacement = node.loc.expression.source.gsub(SPLAT, SPACE) + ELIPSES
    replace node.loc.expression, replacement
  end

  def on_self(node)
    replace node.loc.expression, THIS
  end

  def on_or_asgn(node)
    super
    replace node.loc.operator, (QUESTION_MARK + EQUAL_SIGN)
  end

  private

  def process_send_with_parentheses(node)
    if block_start_node?(node)
      remove node.loc.end
      insert_after node.loc.end, COMMA if node.children.size > TWO
    end
  end

  def process_send_without_parentheses(node)
    insert_after node.loc.selector.end, OPEN_PAREN
    unless block_start_node?(node)
      insert_after node.loc.expression.end, CLOSE_PAREN
    end
  end

  def block_start_node?(node)
    block_start_nodes.last == node
  end

  def prepend_with_at_sign(node)
    insert_before node.loc.expression, AT_SIGN
  end

  def bracket_method?(node)
    node.loc.selector.source.match BRACKET_WRAP
  end

  def method_parentheses?(node)
    node.loc.end
  end

  def wrap_in_existential_operator(expression)
    insert_before(expression, OPEN_PAREN)
    insert_after(expression, CLOSE_PAREN + QUESTION_MARK)
  end
end
