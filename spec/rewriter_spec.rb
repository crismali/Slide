require "spec_helper"

describe Slide::Rewriter do

  let(:rewriter) { Slide::Rewriter.new }
  let(:buffer) { Parser::Source::Buffer.new("test") }
  let(:parser) { Parser::CurrentRuby.new }
  let(:ast) { parser.parse(buffer) }

  describe "#on_if" do

    it "converts elsif to 'else if'" do
      buffer.source = <<EOF
        if self
          true
        elsif 5
          true
        end
EOF
      expected = <<EOF
        if (self)?
          true
        else if (5)?
          true
        end
EOF
      results = rewriter.rewrite(buffer, ast)
      expect(results).to eq(expected)
    end

    context "wrapping conditions in existential operator (?)" do
      let(:nested_if) do
        %|
          if (5 if nil)
            true
          else
            false
          end
        |
      end

      let(:expected) do
        %|
          if ((5 if (nil)?))?
            true
          else
            false
          end
        |
      end

      it "when an if" do
        buffer.source = nested_if
        results = rewriter.rewrite(buffer, ast)
        expect(results).to eq(expected)
      end

      it "when an unless" do
        buffer.source = "5 unless nil"
        results = rewriter.rewrite(buffer, ast)
        expect(results).to eq("5 unless (nil)?")
      end

      it "when an elsif" do
        buffer.source = <<EOF
          if self
            true
          elsif 5
            true
          end
EOF
        expected = <<EOF
          if (self)?
            true
          else if (5)?
            true
          end
EOF
        results = rewriter.rewrite(buffer, ast)
        expect(results).to eq(expected)
      end
    end
  end

  describe "BRACKET_WRAP" do

    let(:bracket_wrap) { Slide::Rewriter::BRACKET_WRAP }

    it "matches strings that start and end with curly brackets" do
      expect("[]").to match(bracket_wrap)
      expect("[5]").to match(bracket_wrap)
      expect("[]").to match(bracket_wrap)
      expect(" []").to_not match(bracket_wrap)
      expect("]").to_not match(bracket_wrap)
      expect("[").to_not match(bracket_wrap)
    end
  end


  describe "#on_send" do

    it "puts parentheses after method calls with no arguments" do
      buffer.source = "self.call"
      results = rewriter.rewrite(buffer, ast)
      expect(results).to eq("self.call()")
    end

    it "puts parentheses after implicit method calls on self" do
      buffer.source = "invoke"
      results = rewriter.rewrite(buffer, ast)
      expect(results).to eq("invoke()")
    end

    it "puts parentheses around the method's arguments" do
      buffer.source = "invoke arg_1, arg_2"
      results = rewriter.rewrite(buffer, ast)
      expect(results).to eq("invoke( arg_1(), arg_2())")
    end

    it "doesn't invoke bracket ('[]') methods" do
      code = "self[5]"
      buffer.source = code
      results = rewriter.rewrite(buffer, ast)
      expect(results).to eq(code)
    end

    it "puts parentheses around block arguments"
  end
end
