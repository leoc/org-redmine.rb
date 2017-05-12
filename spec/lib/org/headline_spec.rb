describe Org::Headline do
  let(:file) { Org::File.new('./spec/files/headline_spec.org') }
  let(:headlines) { file.headlines }

  describe '#level' do
    it 'returns the correct levels' do
      expect(headlines[0].level).to eq(1)
      expect(headlines[1].level).to eq(2)
      expect(headlines[2].level).to eq(2)
      expect(headlines[3].level).to eq(3)
      expect(headlines[4].level).to eq(1)
      expect(headlines[5].level).to eq(2)
    end
  end

  describe '#level=' do
    it 'changes level'
    it 'indents all subheadings'
  end

  describe '#title' do
    it 'returns the correct titles' do
      expect(headlines[0].title).to eq('First Parent')
      expect(headlines[1].title).to eq('First Sub')
      expect(headlines[2].title).to eq('Second Sub')
      expect(headlines[3].title).to eq('First SubSub')
      expect(headlines[4].title).to eq('Second Parent')
      expect(headlines[5].title).to eq('Third Sub')
    end
  end

  describe '#title=' do
    it 'updates the associated Org::File'
  end

  describe '#tags' do
    it 'returns immediate titles' do
      expect(headlines[0].tags).to include('inherited')
      expect(headlines[3].tags).to include('@feature')
    end

    it 'returns inherited tags' do
      expect(headlines[1].tags).to include('inherited')
      expect(headlines[2].tags).to include('inherited')
      expect(headlines[3].tags).to include('inherited')
      expect(headlines[4].tags).not_to include('inherited')
      expect(headlines[5].tags).not_to include('inherited')
    end
  end

  describe '#tags=' do
    it 'updates the associated Org::File'
  end

  describe '#immediate_tags' do
    it 'returns immediate tags' do
      expect(headlines[0].immediate_tags).to eq(%w[inherited])
      expect(headlines[1].immediate_tags).to eq(%w[])
      expect(headlines[2].immediate_tags).to eq(%w[])
      expect(headlines[3].immediate_tags).to eq(%w[@feature])
      expect(headlines[4].immediate_tags).to eq(%w[])
      expect(headlines[5].immediate_tags).to eq(%w[])
    end

    it 'does not return inherited tags' do
      expect(headlines[0].immediate_tags).to include('inherited')
      expect(headlines[1].immediate_tags).not_to include('inherited')
      expect(headlines[2].immediate_tags).not_to include('inherited')
      expect(headlines[3].immediate_tags).not_to include('inherited')
      expect(headlines[4].immediate_tags).not_to include('inherited')
      expect(headlines[5].immediate_tags).not_to include('inherited')
    end
  end

  describe '#inherited_tags' do
    it 'does not return immediate tags' do
      expect(headlines[0].inherited_tags).not_to include('inherited')
      expect(headlines[3].inherited_tags).not_to include('@feature')
    end

    it 'returns inherited tags' do
      expect(headlines[0].inherited_tags).not_to include('inherited')
      expect(headlines[1].inherited_tags).to include('inherited')
      expect(headlines[2].inherited_tags).to include('inherited')
      expect(headlines[3].inherited_tags).to include('inherited')
      expect(headlines[4].inherited_tags).not_to include('inherited')
      expect(headlines[5].inherited_tags).not_to include('inherited')
    end
  end

  describe '#tag?' do
    it 'returns true if given tag is found' do
      expect(headlines[0].tag?('inherited')).to be_truthy
      expect(headlines[0].tag?('@feature')).to be_falsy
      expect(headlines[1].tag?('inherited')).to be_truthy
      expect(headlines[1].tag?('@feature')).to be_falsy
      expect(headlines[2].tag?('inherited')).to be_truthy
      expect(headlines[2].tag?('@feature')).to be_falsy
      expect(headlines[3].tag?('inherited')).to be_truthy
      expect(headlines[3].tag?('@feature')).to be_truthy
      expect(headlines[4].tag?('inherited')).to be_falsy
      expect(headlines[4].tag?('@feature')).to be_falsy
      expect(headlines[5].tag?('inherited')).to be_falsy
      expect(headlines[5].tag?('@feature')).to be_falsy
    end

    describe 'only immediate' do
      it 'returns true if given tag is found in immediate tags' do
        expect(headlines[0].tag?('inherited', immediate: true)).to be_truthy
        expect(headlines[0].tag?('@feature', immediate: true)).to be_falsy
        expect(headlines[1].tag?('inherited', immediate: true)).to be_falsy
        expect(headlines[1].tag?('@feature', immediate: true)).to be_falsy
        expect(headlines[2].tag?('inherited', immediate: true)).to be_falsy
        expect(headlines[2].tag?('@feature', immediate: true)).to be_falsy
        expect(headlines[3].tag?('inherited', immediate: true)).to be_falsy
        expect(headlines[3].tag?('@feature', immediate: true)).to be_truthy
        expect(headlines[4].tag?('inherited', immediate: true)).to be_falsy
        expect(headlines[4].tag?('@feature', immediate: true)).to be_falsy
        expect(headlines[5].tag?('inherited', immediate: true)).to be_falsy
        expect(headlines[5].tag?('@feature', immediate: true)).to be_falsy
      end
    end

    describe 'only inherited' do
      it 'returns true if given tag is found in inherited tags' do
        expect(headlines[0].tag?('inherited', inherited: true)).to be_falsy
        expect(headlines[0].tag?('@feature', inherited: true)).to be_falsy
        expect(headlines[1].tag?('inherited', inherited: true)).to be_truthy
        expect(headlines[1].tag?('@feature', inherited: true)).to be_falsy
        expect(headlines[2].tag?('inherited', inherited: true)).to be_truthy
        expect(headlines[2].tag?('@feature', inherited: true)).to be_falsy
        expect(headlines[3].tag?('inherited', inherited: true)).to be_truthy
        expect(headlines[3].tag?('@feature', inherited: true)).to be_falsy
        expect(headlines[4].tag?('inherited', inherited: true)).to be_falsy
        expect(headlines[4].tag?('@feature', inherited: true)).to be_falsy
        expect(headlines[5].tag?('inherited', inherited: true)).to be_falsy
        expect(headlines[5].tag?('@feature', inherited: true)).to be_falsy
      end
    end
  end

  describe '#todo' do
    it 'returns true if given tag is found in inherited tags' do
      expect(headlines[0].todo).to eq(nil)
      expect(headlines[1].todo).to eq('TODO')
      expect(headlines[2].todo).to eq('NEXT')
      expect(headlines[3].todo).to eq('DONE')
      expect(headlines[4].todo).to eq(nil)
      expect(headlines[5].todo).to eq('TODO')
    end
  end

  describe '#todo=' do
    it 'updates the associated Org::File'
  end

  describe '#contents_beginning' do
    it 'returns end of level' do
      expect(headlines[0].contents_beginning).to eq(77)
      expect(headlines[1].contents_beginning).to eq(95)
      expect(headlines[2].contents_beginning).to eq(114)
      expect(headlines[3].contents_beginning).to eq(190)
      expect(headlines[4].contents_beginning).to eq(206)
      expect(headlines[5].contents_beginning).to eq(257)
    end
  end

  describe '#contents_ending' do
    it 'returns end of level' do
      expect(headlines[0].contents_ending).to eq(77)
      expect(headlines[1].contents_ending).to eq(95)
      expect(headlines[2].contents_ending).to eq(114)
      expect(headlines[3].contents_ending).to eq(190)
      expect(headlines[4].contents_ending).to eq(239)
      expect(headlines[5].contents_ending).to eq(309)
    end
  end

  describe '#level_ending' do
    it 'returns end of level' do
      expect(headlines[0].level_ending).to eq(190)
      expect(headlines[1].level_ending).to eq(95)
      expect(headlines[2].level_ending).to eq(190)
      expect(headlines[3].level_ending).to eq(225)
      expect(headlines[4].level_ending).to eq(225)
      expect(headlines[5].level_ending).to eq(225)
    end
  end

  describe '#contents' do
    it 'returns heading contents' do
      expect(headlines[0].contents).to eq('')
      expect(headlines[1].contents).to eq('')
      expect(headlines[2].contents).to eq('')
      expect(headlines[3].contents).to eq('')
      expect(headlines[4].contents).to eq("Some contents for this heading.\n")
      expect(headlines[5].contents).to eq("Some description.\n")
    end
  end

  describe '#properties' do
    it 'returns heading properties' do
      expect(headlines[5].properties[:STYLE]).to eq('habit')
    end
  end

  describe '#each_ancestor' do

  end

  describe '#ancestor_if' do

  end

  describe '#append_subheading' do

  end

  describe 'Redmine' do
    describe '#redmine_issue_id' do
      it 'returns the redmine issue ids'
    end

    describe '#redmine_issue_id=' do
      it 'updates the associated Org::File'
    end

    describe '#redmine_project' do
      it 'returns the redmine project identifier'
    end

    describe '#redmine_project=' do
      it 'updates the associated Org::File'
    end

    describe '#redmine_tracker_id' do
      it 'returns the redmine tracker id'
    end

    describe '#redmine_tracker_id=' do
      it 'updates the associated Org::File'
    end

    describe '#redmine_version_id' do
      it 'returns the redmine version id'
    end

    describe '#redmine_version_id=' do
      it 'updates the associated Org::File'
    end
  end
end
