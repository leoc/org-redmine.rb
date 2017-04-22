describe OrgRedmine::Issue do
  describe '#diff_issue' do
    let(:a) do
      {
        id: 123,
        subject: 'Old Subject',
        assigned_to_id: 5
      }
    end

    let(:b) do
      {
        id: 123,
        subject: 'New Subject',
        assigned_to_id: 5,
        start_date: '2016-12-01'
      }
    end

    it 'should create correct diff' do
      expect(OrgRedmine::Issue.diff_issue(a, b))
        .to eq(id: 123, subject: 'New Subject', start_date: '2016-12-01')
    end
  end

  describe '#diff_issue' do
    let(:a) do
      [
        { id: 123, subject: 'Old Subject', assigned_to_id: 5 },
        { id: 124, subject: 'Old Subject', assigned_to_id: 6 }
      ]
    end

    let(:b) do
      [
        { id: 123, subject: 'New Subject', assigned_to_id: 5, start_date: '2016-12-01' },
        { id: 124, subject: 'Old Subject', assigned_to_id: 1 },
        { id: 125, subject: 'Other Subject', assigned_to_id: 2 },
        { subject: 'Completely new issue', assigned_to_id: 3 }
      ]
    end

    let(:diff) { OrgRedmine::Issue.diff_issues(a, b) }

    it 'has correct diff' do
      expect(diff).to include(id: 123, subject: 'New Subject', start_date: '2016-12-01')
      expect(diff).to include(id: 124, assigned_to_id: 1)
      expect(diff).to include(id: 125, subject: 'Other Subject', assigned_to_id: 2)
    end

    it 'has new issues' do
      expect(diff).to include(subject: 'Completely new issue', assigned_to_id: 3)
    end
  end

  describe '#merge_diff' do
    let(:local) do
      [
        { subject: 'Completely new issue', assigned_to_id: 3 },
        { id: 123, subject: 'Local New 123 Subject' },
        { id: 124, assigned_to_id: 6 },
        { id: 125, assigned_to_id: 6 }
      ]
    end

    let(:remote) do
      [
        { id: 123, subject: 'Remote New 123 Subject' },
        { id: 124, subject: 'Remote New 124 Subject' },
        { id: 125, assigned_to_id: 6 }
      ]
    end

    let(:merge_diff) { OrgRedmine::Issue.merge_diff(local, remote) }

    it 'merges conflicts' do
      expect(merge_diff).to include({ id: 123, subject: ['Local New 123 Subject', 'Remote New 123 Subject'] })
    end

    it 'merges non-conflicting changes' do
      expect(merge_diff).to include({ id: 124, subject: 'Remote New 124 Subject', assigned_to_id: 6 })
    end

    it 'keeps all new issues' do
      expect(merge_diff).to include({ subject: 'Completely new issue', assigned_to_id: 3 })
    end

    it 'merges the same values' do
      expect(merge_diff).to include({ id: 125, assigned_to_id: 6 })
    end
  end
end
