class Slide::Rewriter < Parser::Rewriter

  OPEN_PAREN = "("
  CLOSE_PAREN = ")"
  QUESTION_MARK = "?"

  def on_if(node)
    super
    conditional_expression = node.children.first.loc.expression
    wrap_in_existential_operator(conditional_expression)
  end

  private

  def wrap_in_existential_operator(expression)
    insert_before(expression, OPEN_PAREN)
    insert_after(expression, CLOSE_PAREN + QUESTION_MARK)
  end
end
