describe Org::Buffer do
  let(:buffer) do
    Org::Buffer.new(<<FILE)
* First Parent
** Sub
*** SubSub
** SecondSub
* Second Parent
FILE
  end

  before(:each) do
    buffer.position(0)
    buffer.position(15)
    buffer.position(22)
    buffer.position(33)
    buffer.position(46)
  end

  describe '#insert' do
    before(:each) do
      buffer.insert(15, "** Inserted Sub\n")
    end

    it 'inserts given text' do
      expect(buffer.string).to eq(<<FILE)
* First Parent
** Inserted Sub
** Sub
*** SubSub
** SecondSub
* Second Parent
FILE
    end

    it 'updates existing positions' do
      expect(buffer.positions.map(&:value)).to eq([0, 31, 38, 49, 62])
    end
  end

  describe '#delete' do
    before(:each) do
      buffer.delete(15, 33)
    end

    it 'deletes given region' do
      expect(buffer.string).to eq(<<FILE)
* First Parent
** SecondSub
* Second Parent
FILE
    end

    it 'updates existing positions' do
      expect(buffer.positions.map(&:value)).to eq([0, 15, 28])
    end
  end

  describe '#replace' do
    before(:each) do
      buffer.replace(15, 33, "** Replaced Heading\n")
    end

    it 'replaces specified region' do
      expect(buffer.string).to eq(<<FILE)
* First Parent
** Replaced Heading
** SecondSub
* Second Parent
FILE
    end

    it 'removes positions in between' do
      expect(buffer.positions.map(&:value)).to eq([0, 35, 48])
    end
  end
end
