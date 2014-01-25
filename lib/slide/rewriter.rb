class Slide::Rewriter < Parser::Rewriter

  CLOSE_PAREN = ")"
  ELSE_IF = "else if"
  ELSIF = "elsif"
  OPEN_PAREN = "("
  QUESTION_MARK = "?"
  SPACE = " "

  BRACKET_WRAP = /\A\[.*\]\z/

  def on_if(node)
    super
    keyword = node.loc.keyword
    conditional_expression = node.children.first.loc.expression
    replace keyword, ELSE_IF if keyword.source == ELSIF
    wrap_in_existential_operator(conditional_expression)
  end

  def on_send(node)
    super
    return if node.loc.selector.source.match BRACKET_WRAP
    insert_after node.loc.selector.end, OPEN_PAREN
    insert_after node.loc.expression.end, CLOSE_PAREN
  end

  private

  def wrap_in_existential_operator(expression)
    insert_before(expression, OPEN_PAREN)
    insert_after(expression, CLOSE_PAREN + QUESTION_MARK)
  end
end
