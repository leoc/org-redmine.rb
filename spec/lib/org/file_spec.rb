describe Org::File do
  describe '#headlines' do
    let(:file) { Org::File.new('./spec/files/file_spec.org') }
    let(:headlines) { file.headlines }

    it 'returns all headlines' do
      headlines.map do |headline|
        expect(headline).to be_a(Org::Object)
      end
    end
  end

  describe '#find_headline' do
    describe 'offset by first heading' do

    end

    describe 'limited by third heading' do

    end

    describe 'with level' do
      describe 'range' do
        it 'returns'
      end

      describe 'number' do
        it 'returns'
      end
    end

    describe 'with tag' do

    end

    describe 'with todo' do

    end

    describe 'with title' do

    end
  end
end
