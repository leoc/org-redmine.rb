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

  describe '::timestamp_to_date' do
    it 'creates date' do
      expect(Org::timestamp_to_date('<2017-06-03 Sat>'))
        .to eq(Date.new(2017, 6, 3))
    end
  end

  describe '::format_timestamp' do
    let(:date) { Date.new(2017, 6, 3) }
    let(:datetime) { DateTime.new(2017, 6, 3, 12, 0) }
    let(:time) { Time.at(1497608953) }

    it 'formats date' do
      expect(Org::format_timestamp(date)).to eq('<2017-06-03 Sat>')
    end
    it 'formats datetime' do
      expect(Org::format_timestamp(datetime)).to eq('<2017-06-03 Sat 12:00>')
    end
    it 'formats time' do
      expect(Org::format_timestamp(time)).to eq('<2017-06-16 Fri 12:29>')
    end
  end
end
