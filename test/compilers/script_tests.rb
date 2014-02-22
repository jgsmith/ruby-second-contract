require 'second-contract/compiler/script'

describe SecondContract::Compiler::Script do
  let(:compiler) { SecondContract::Compiler::Script.new }
  
  describe "#new" do
    it "takes no parameters and returns a Script parsing object" do
      expect(compiler).to be_an_instance_of SecondContract::Compiler::Script
    end
  end

  describe "#compile" do
    let(:compile_result) {
      compiler.compile([
        :MPY,
        [ :INT, 6 ],
        [ :INT, 2 ]
      ])
    }

    it "compiles multiplication" do
      expect(compile_result).to be_an_instance_of Array
      expect(compile_result).to eq [ :PUSH, 6, :PUSH, 2, :PUSH, 2, :PRODUCT ]
    end
  end
end