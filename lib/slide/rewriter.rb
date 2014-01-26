class Slide::Rewriter < Parser::Rewriter

  AT_SIGN = "@"
  CLOSE_PAREN = ")"
  ELSE_IF = "else if"
  ELSIF = "elsif"
  OPEN_PAREN = "("
  QUESTION_MARK = "?"
  SPACE = " "

  BRACKET_WRAP = /\A\[.*\]\z/

  attr_accessor :block_starts

  def initialize
    self.block_starts = []
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
      remove node.loc.end if block_starts.include?(node)
      return
    end

    insert_after node.loc.selector.end, OPEN_PAREN

    unless block_starts.include?(node)
      insert_after node.loc.expression.end, CLOSE_PAREN
    end

  end


  def on_block(node)
    self.block_starts << node.children.first
    super
    insert_after node.loc.end, CLOSE_PAREN
    self.block_starts.pop
  end

  private

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
