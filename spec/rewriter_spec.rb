require "spec_helper"

describe Slide::Rewriter do

  let(:rewriter) { Slide::Rewriter.new }
  let(:buffer) { Parser::Source::Buffer.new("test") }
  let(:parser) { Parser::CurrentRuby.new }
  let(:ast) { parser.parse(buffer) }
  let(:results) { rewriter.rewrite(buffer, ast) }

  describe "#initialize" do
    it "sets @block_start_nodes to an empty array" do
      expect(rewriter.block_start_nodes).to eq([])
    end
  end

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
        expect(results).to eq(expected)
      end

      it "when an unless" do
        buffer.source = "5 unless nil"
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
      expect(results).to eq("self.call()")
    end

    it "doesn't add parentheses after method calls that already have them but lack arguments" do
      code = "self.call()"
      buffer.source = code
      expect(results).to eq(code)
    end

    it "puts parentheses after implicit method calls on self" do
      buffer.source = "invoke"
      expect(results).to eq("@invoke()")
    end

    it "puts an '@' before methods implicitly called on self" do
      buffer.source = "invoke()"
      expect(results).to eq("@invoke()")
    end

    it "puts parentheses around the method's arguments" do
      buffer.source = "invoke arg_1, arg_2"
      expect(results).to eq("@invoke( @arg_1(), @arg_2())")
    end

    it "doesn't invoke bracket ('[]') methods" do
      code = "self[5]"
      buffer.source = code
      expect(results).to eq(code)
    end

    it "puts parentheses around block arguments" do
      buffer.source = "self.map { |x| x.go }"
      expect(results).to eq("self.map(  |x| x.go() )")
    end

    it "puts parentheses around block arguments when there are already parentheses" do
      buffer.source = "self.map() { |x| x.go }"
      expect(results).to eq("self.map(  |x| x.go() )")
    end

    it "puts parentheses around regular and block arguments" do
      buffer.source = "self.each_with_object({}) { |x| x.go }"
      expect(results).to eq("self.each_with_object({},  |x| x.go() )")
    end

    it "puts a comma after the last argument before the block" do
      buffer.source = "self.each_with_object({}, []) { |x| x.go }"
      expect(results).to eq("self.each_with_object({}, [],  |x| x.go() )")
    end
  end

  describe "#on_block" do

    context "do-end" do

      it "removes the do and end" do
        buffer.source = <<EOF
        self.map do |thing|
          thing.go
        end
EOF
        expected = <<EOF
        self.map(  |thing|
          thing.go()
        )
EOF
        expect(results).to eq(expected)
      end
    end

    context "curly braces" do

      it "removes the braces" do
        buffer.source = "self.takes_a_block { self.go }"
        expect(results).to eq("self.takes_a_block(  self.go() )")
      end
    end
  end
end
