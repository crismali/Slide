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

  describe "#block_start_nodes" do

    it "empties block start nodes as they're used" do
      buffer.source = "code.start { |n| n += 2 }"
      results
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
      expect(results).to_not match("elsif")
      expect(results).to match("else if")
    end

    context "wrapping conditions in existential operator (?)" do

      it "when an if" do
        buffer.source = <<EOF
        if (5 if nil)
          true
        else
          false
        end
EOF
        expect(results).to match(/\(\(5 if \(nil\)\?\)\)\?/)
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
        expect(results).to match(/\(5\)\?/)
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
      expect(results).to eq("this.call()")
    end

    it "doesn't add parentheses after method calls that already have them but lack arguments" do
      buffer.source = "self.call()"
      expect(results).to eq("this.call()")
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
      buffer.source = "self[5]"
      expect(results).to eq("this[5]")
    end

    it "puts parentheses around blocks " do
      buffer.source = "self.map { |x| x }"
      expect(results).to match(/map\(.*\)/)
    end

    it "puts parentheses around blocks when there are already parentheses" do
      buffer.source = "self.map() { |x| x }"
      expect(results).to match(/map\(.*x.*=>.*\)/m)
    end

    it "puts parentheses around regular arguments and blocks" do
      buffer.source = "self.each_with_object({}) { |x| x }"
      expect(results).to match(/_object\({}[^\)].*x\s\)/m)
    end

    it "puts a comma after the last argument before the block" do
      buffer.source = "self.each_with_object({}, []) { |x| x }"
      expect(results).to match(/\[\]\,/)
    end
  end

  describe "#on_args" do

    context "blocks" do

      it "removes the pipes ('|obj|')" do
        buffer.source = "self.map { |obj| obj.to_s }"
        expect(results).to_not match(/\|/)
      end

      it "adds a fat arrow and newline after them" do
        buffer.source = "self.map { |obj| obj.to_s }"
        expect(results).to match("\=\>\n")
      end

      it "wraps the arguments in parentheses" do
        buffer.source = "self.map { |obj| obj.to_s }"
        expect(results).to match(/\(obj\)/)
      end

    end

    context "method definitions" do

      it "adds parentheses when there are none" do
        buffer.source = <<EOF
        def my_method arg
        end
EOF
        expect(results).to match(/\s\(arg\)/)
      end

      it "leaves parentheses when they are already there (but adds a space)" do
        buffer.source = <<EOF
        def my_method(arg)
        end
EOF
        expect(results).to match(/\s\(arg\)/)
      end

      it "adds a fat arrow after them (parens already there)" do
        buffer.source = <<EOF
        def my_method(arg)
        end
EOF
        expect(results).to match("\=\>")
      end

      it "adds a fat arrow after them (no parens)" do
        buffer.source = <<EOF
        def my_method arg
        end
EOF
        expect(results).to match("\=\>")
      end
    end
  end

  describe "#on_splat" do

    it "converts splats to '...'" do
      buffer.source = "self.invoke(*planets)"
      expect(results).to eq("this.invoke(@planets()...)")
    end
  end

  describe "#on_or_asgn" do

    it "uses the existential operator for ||=" do
      buffer.source = "dog ||= 5"
      expect(results).to_not match(/\|\|\=/)
      expect(results).to match(/\?\=/)
    end
  end

  describe "#on_def" do
    before do
      buffer.source = %|
        def my_method(arg, arg2)
        end
      |
    end

    it "removes the def" do
      expect(results).to_not match("def")
    end

    it "removes the end" do
      expect(results).to_not match("end")
    end

    it "puts a colone after the name" do
      expect(results).to match(/my_method\:/)
    end
  end

  describe "#on_restarg" do
    it "converts splats to '...'" do
      buffer.source = "def my_method(arg, arg2, *args) end"
      expect(results).to match(/,\s\sargs\.\.\./)
    end
  end

  describe "#on_self" do

    it "converts 'self' to 'this'" do
      buffer.source = "self"
      expect(results).to eq("this")
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
        expect(results).to_not match("do")
        expect(results).to_not match("end")
      end
    end

    context "curly braces" do

      it "removes the braces" do
        buffer.source = "self.takes_a_block { self.go }"
        expect(results).to_not match(/\{/)
        expect(results).to_not match(/\}/)
      end
    end
  end
end
