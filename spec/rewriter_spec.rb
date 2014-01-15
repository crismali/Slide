require "spec_helper"

describe Slide::Rewriter do

  let(:rewriter) { Slide::Rewriter.new }
  let(:buffer) { Parser::Source::Buffer.new("test") }
  let(:parser) { Parser::CurrentRuby.new }
  let(:ast) { parser.parse(buffer) }

  describe "#on_if" do

    let(:nested_if) do
      %|
        if (x = 5 if y == 3)
          puts "true"
        else
          puts "false"
        end
      |
    end

    let(:expected) do
      %|
        if ((x = 5 if (y == 3)?))?
          puts "true"
        else
          puts "false"
        end
      |
    end

    it "wraps the condition in the existential operator ('?')" do
      buffer.source = nested_if
      results = rewriter.rewrite(buffer, ast)
      expect(results).to eq(expected)
    end
  end
end
