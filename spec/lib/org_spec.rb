describe Org do
  describe '::TIMESTAMP_REGEX' do
    it 'matches date' do
      expect(Org::TIMESTAMP_REGEX).to match('[2017-06-03]')
    end
    it 'matches date with day' do
      expect(Org::TIMESTAMP_REGEX).to match('[2017-06-03 Sat]')
    end
    it 'matches date with day and time' do
      expect(Org::TIMESTAMP_REGEX).to match('[2017-06-03 Sat 10:00]')
    end
    it 'matches date with day and time with seconds' do
      expect(Org::TIMESTAMP_REGEX).to match('[2017-06-03 Sat 10:00:22]')
    end
  end
end
