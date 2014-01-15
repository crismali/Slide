require "spec_helper"

describe Slide::Rewriter do

  let(:rewriter) { Slide::Rewriter.new }

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
    let(:buffer) do
      buffer = Parser::Source::Buffer.new("test")
      buffer.source = nested_if
      buffer
    end
    let(:parser) { Parser::CurrentRuby.new }
    let(:ast) { parser.parse(buffer) }

    it "wraps the condition in the existential operator ('?')" do
      results = rewriter.rewrite(buffer, ast)
      expect(results).to eq(expected)
    end
  end
end
