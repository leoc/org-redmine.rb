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
    let(:file) { Org::File.new('./spec/files/headline_level_spec.org') }
    let(:headlines) { file.headlines }

    it 'decreases level' do
      headlines[6].level = 1
      expect(file.buffer.string).to eq(<<FILE)
* First Parent                                                    :inherited:
** TODO First Sub
** NEXT Second Sub
*** DONE First SubSub                                            :@feature:
**** TODO First SubSubSub
* Second Parent
Some contents for this heading.

* TODO Third Sub
:PROPERTIES:
:STYLE: habit
:END:
Some description.
FILE
    end

    it 'decreases the level of subheadings accordingly' do
      headlines[2].level = 1
      expect(file.buffer.string).to eq(<<FILE)
* First Parent                                                    :inherited:
** TODO First Sub
* NEXT Second Sub
** DONE First SubSub                                            :@feature:
*** TODO First SubSubSub
* Second Parent
Some contents for this heading.

** TODO Third Sub
:PROPERTIES:
:STYLE: habit
:END:
Some description.
FILE
    end

    it 'increases level' do
      headlines[5].level = 2
      expect(file.buffer.string).to eq(<<FILE)
* First Parent                                                    :inherited:
** TODO First Sub
** NEXT Second Sub
*** DONE First SubSub                                            :@feature:
**** TODO First SubSubSub
** Second Parent
Some contents for this heading.

*** TODO Third Sub
:PROPERTIES:
:STYLE: habit
:END:
Some description.
FILE
    end

    it 'increases the level of subheadings accordingly' do
      headlines[2].level = 3
      expect(file.buffer.string).to eq(<<FILE)
* First Parent                                                    :inherited:
** TODO First Sub
*** NEXT Second Sub
**** DONE First SubSub                                            :@feature:
***** TODO First SubSubSub
* Second Parent
Some contents for this heading.

** TODO Third Sub
:PROPERTIES:
:STYLE: habit
:END:
Some description.
FILE
    end
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
    it 'updates existing title' do
      headlines[3].title = 'Some new title for SubSub'
      expect(headlines[3].string)
        .to eq('*** DONE Some new title for SubSub                                            :@feature:')
    end
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
    it 'updates existing tags' do
      headlines[3].tags = %w[@feature newtag]
      expect(headlines[3].string)
        .to eq('*** DONE First SubSub                                            :@feature:newtag:')
    end
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
    it 'updates existing TODO' do
      headlines[5].todo = 'DONE'
      expect(headlines[5].string).to eq('** DONE Third Sub')
    end

    it 'adds new TODO' do
      headlines[4].todo = 'TODO'
      expect(headlines[4].string).to eq('* TODO Second Parent')
    end
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
      expect(headlines[0].level_ending.to_i).to eq(191)
      expect(headlines[1].level_ending.to_i).to eq(96)
      expect(headlines[2].level_ending.to_i).to eq(191)
      expect(headlines[3].level_ending.to_i).to eq(191)
      expect(headlines[4].level_ending.to_i).to eq(309)
      expect(headlines[5].level_ending.to_i).to eq(309)
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
    it 'goes through all ancestors'
  end

  describe '#find_ancestor' do
    it 'finds the filtered ancestor'
  end

  describe '#append_subheading' do
    it 'appends a heading to the given heading'
  end

  describe '#each_child' do
    let(:file) { Org::File.new('./spec/files/headline_level_spec.org') }
    let(:headlines) { file.headlines }

    it 'finds each child' do
      titles = []
      headlines[0].each_child do |child|
        titles << child.title
      end
      expect(titles).to eq(['First Sub', 'Second Sub'])
    end

    it 'finds any child' do
      titles = []
      headlines[0].each_child(any: true) do |child|
        titles << child.title
      end
      expect(titles).to eq(['First Sub', 'Second Sub', 'First SubSub', 'First SubSubSub'])
    end

    it 'finds any child' do
      titles = []
      headlines[2].each_child(any: true) do |child|
        titles << child.title
      end
      expect(titles).to eq(['First SubSub', 'First SubSubSub'])
    end
  end

  describe 'Redmine' do
    let(:file) { Org::File.new('./spec/files/redmine_headline_spec.org') }
    let(:headlines) { file.headlines }

    describe '#redmine_issue_id' do
      let(:file) { Org::File.new('./spec/files/redmine_headline_issue_spec.org') }
      let(:headlines) { file.headlines }

      it 'returns the redmine issue ids' do
        expect(headlines[0].redmine_issue_id).to be_nil
        expect(headlines[1].redmine_issue_id).to be_nil
        expect(headlines[2].redmine_issue_id).to eq(125)
        expect(headlines[3].redmine_issue_id).to eq(130)
        expect(headlines[4].redmine_issue_id).to be_nil
        expect(headlines[5].redmine_issue_id).to be_nil
        expect(headlines[6].redmine_issue_id).to be_nil
        expect(headlines[7].redmine_issue_id).to be_nil
        expect(headlines[8].redmine_issue_id).to eq(111)
        expect(headlines[9].redmine_issue_id).to eq(99)
        expect(headlines[10].redmine_issue_id).to be_nil
        expect(headlines[11].redmine_issue_id).to be_nil
      end
    end

    describe '#redmine_issue_id=' do
      let(:file) { Org::File.new('./spec/files/redmine_headline_issue_spec.org') }
      let(:headlines) { file.headlines }

      it 'updates the associated Org::File' do
        headlines[11].redmine_issue_id = 200
        expect(file.buffer.string).to include(<<ISSUE)
** TODO #200 - Some Issue
ISSUE
        headlines[2].redmine_issue_id = 300
        expect(file.buffer.string).to include(<<ISSUE.strip)
*** NEXT #300 - Parent Issue
**** DONE #130 - Sub Issue
ISSUE
      end
    end

    describe '#redmine_project?' do
      it 'returns the redmine project identifier' do
        expect(headlines[0].redmine_project?).to be_truthy
        expect(headlines[1].redmine_project?).to be_falsy
        expect(headlines[2].redmine_project?).to be_falsy
        expect(headlines[3].redmine_project?).to be_falsy
      end
    end

    describe '#redmine_project_id' do
      it 'returns the redmine project identifier' do
        expect(headlines[0].redmine_project_id).to eq('some_project')
        expect(headlines[1].redmine_project_id).to eq('some_project')
        expect(headlines[2].redmine_project_id).to eq('some_project')
        expect(headlines[3].redmine_project_id).to eq('some_project')
      end
    end

    describe '#redmine_project_id=' do
      it 'moves the headline to the specific project Headline' do
        headlines[2].redmine_project_id = 'other_project'
        expect(file.buffer.string).to eq(<<FILE)
#+ORG_REDMINE_TRACKERS: @bug:1 @feature:2 @support:3 !@task:4 @feedback:5 @planning:6 @doc:7 @requirement:8
* First Parent                                                    :inherited:
:PROPERTIES:
:redmine_project_id: some_project
:END:
** TODO First Sub
* Second Parent
:PROPERTIES:
:redmine_project_id: other_project
:END:
Some contents for this heading.

** TODO Third Sub
:PROPERTIES:
:STYLE: habit
:END:
Some description.
** Third Parent
:PROPERTIES:
:redmine_project_id: nested_project
:END:
** NEXT Second Sub
*** DONE First SubSub                                            :@feature:
FILE
      end

      it 'increases level according to project heading level' do
        headlines[2].redmine_project_id = 'nested_project'
        expect(file.buffer.string).to eq(<<FILE)
#+ORG_REDMINE_TRACKERS: @bug:1 @feature:2 @support:3 !@task:4 @feedback:5 @planning:6 @doc:7 @requirement:8
* First Parent                                                    :inherited:
:PROPERTIES:
:redmine_project_id: some_project
:END:
** TODO First Sub
* Second Parent
:PROPERTIES:
:redmine_project_id: other_project
:END:
Some contents for this heading.

** TODO Third Sub
:PROPERTIES:
:STYLE: habit
:END:
Some description.
** Third Parent
:PROPERTIES:
:redmine_project_id: nested_project
:END:
*** NEXT Second Sub
**** DONE First SubSub                                            :@feature:
FILE
      end
    end

    describe '#redmine_tracker' do
      it 'returns the redmine tracker' do
        expect(headlines[1].redmine_tracker).to eq(4)
        expect(headlines[2].redmine_tracker).to eq(4)
        expect(headlines[3].redmine_tracker).to eq(2)
        expect(headlines[5].redmine_tracker).to eq(4)
      end
    end

    describe '#redmine_tracker=' do
      it 'updates the associated Org::File' do
        headlines[3].redmine_tracker = 'bug'
        expect(file.buffer.string).to include('*** DONE First SubSub                                            :@bug:')
        headlines[3].redmine_tracker = 1
        expect(file.buffer.string).to include('*** DONE First SubSub                                            :@bug:')
        headlines[3].redmine_tracker = '@bug'
        expect(file.buffer.string).to include('*** DONE First SubSub                                            :@bug:')
      end
    end

    describe '#redmine_version_id' do
      let(:file) { Org::File.new('./spec/files/redmine_headline_version_spec.org') }
      let(:headlines) { file.headlines }

      it 'returns the redmine version id' do
        expect(headlines[0].redmine_version_id).to be_nil
        expect(headlines[1].redmine_version_id).to eq(1)
        expect(headlines[2].redmine_version_id).to eq(1)
        expect(headlines[3].redmine_version_id).to eq(1)
        expect(headlines[4].redmine_version_id).to eq(2)
        expect(headlines[5].redmine_version_id).to be_nil
        expect(headlines[6].redmine_version_id).to be_nil
        expect(headlines[7].redmine_version_id).to eq(3)
        expect(headlines[8].redmine_version_id).to eq(3)
        expect(headlines[9].redmine_version_id).to be_nil
        expect(headlines[10].redmine_version_id).to eq(4)
        expect(headlines[11].redmine_version_id).to be_nil
      end
    end

    describe '#redmine_version_id=' do
      let(:file) { Org::File.new('./spec/files/redmine_headline_version_spec.org') }
      let(:headlines) { file.headlines }

      describe 'setting to nil' do
        before(:each) do
          headlines[2].redmine_version_id = nil
        end

        it 'updates the associated Org::File' do
          expect(file.buffer.string).to eq(<<FILE)
#+ORG_REDMINE_TRACKERS: @bug:1 @feature:2 @support:3 !@task:4 @feedback:5 @planning:6 @doc:7 @requirement:8
* First Parent                                                    :inherited:
:PROPERTIES:
:redmine_project_id: some_project
:END:
** Version 1                                                   :milestone:
:PROPERTIES:
:redmine_version_id: 1
:END:
** Version 2                                                   :milestone:
:PROPERTIES:
:redmine_version_id: 2
:END:
** NEXT # - Parent Issue
*** DONE # - Sub Issue                                         :@feature:
* Second Parent
:PROPERTIES:
:redmine_project_id: other_project
:END:
Some contents for this heading.
** Third Parent
:PROPERTIES:
:redmine_project_id: nested_project
:END:
*** Version 3                                                   :milestone:
:PROPERTIES:
:redmine_version_id: 3
:END:
**** TODO # - Super Issue
*** TODO # - Other Issue
** Version 4                                                     :milestone:
:PROPERTIES:
:redmine_version_id: 4
:END:
** TODO # - Some Issue
Some description.
FILE
        end
      end
      describe 'setting to same projects same version' do
        before(:each) do
          headlines[2].redmine_version_id = 1
        end

        it 'updates the associated Org::File' do
          expect(file.buffer.string).to eq(<<FILE)
#+ORG_REDMINE_TRACKERS: @bug:1 @feature:2 @support:3 !@task:4 @feedback:5 @planning:6 @doc:7 @requirement:8
* First Parent                                                    :inherited:
:PROPERTIES:
:redmine_project_id: some_project
:END:
** Version 1                                                   :milestone:
:PROPERTIES:
:redmine_version_id: 1
:END:
*** NEXT # - Parent Issue
**** DONE # - Sub Issue                                         :@feature:
** Version 2                                                   :milestone:
:PROPERTIES:
:redmine_version_id: 2
:END:
* Second Parent
:PROPERTIES:
:redmine_project_id: other_project
:END:
Some contents for this heading.
** Third Parent
:PROPERTIES:
:redmine_project_id: nested_project
:END:
*** Version 3                                                   :milestone:
:PROPERTIES:
:redmine_version_id: 3
:END:
**** TODO # - Super Issue
*** TODO # - Other Issue
** Version 4                                                     :milestone:
:PROPERTIES:
:redmine_version_id: 4
:END:
** TODO # - Some Issue
Some description.
FILE
        end
      end
      describe 'setting to same projects other version' do
        before(:each) do
          headlines[2].redmine_version_id = 2
        end

        it 'updates the associated Org::File' do
          expect(file.buffer.string).to eq(<<FILE)
#+ORG_REDMINE_TRACKERS: @bug:1 @feature:2 @support:3 !@task:4 @feedback:5 @planning:6 @doc:7 @requirement:8
* First Parent                                                    :inherited:
:PROPERTIES:
:redmine_project_id: some_project
:END:
** Version 1                                                   :milestone:
:PROPERTIES:
:redmine_version_id: 1
:END:
** Version 2                                                   :milestone:
:PROPERTIES:
:redmine_version_id: 2
:END:
*** NEXT # - Parent Issue
**** DONE # - Sub Issue                                         :@feature:
* Second Parent
:PROPERTIES:
:redmine_project_id: other_project
:END:
Some contents for this heading.
** Third Parent
:PROPERTIES:
:redmine_project_id: nested_project
:END:
*** Version 3                                                   :milestone:
:PROPERTIES:
:redmine_version_id: 3
:END:
**** TODO # - Super Issue
*** TODO # - Other Issue
** Version 4                                                     :milestone:
:PROPERTIES:
:redmine_version_id: 4
:END:
** TODO # - Some Issue
Some description.
FILE
        end
      end
      describe 'setting to other projects version' do
        before(:each) do
          headlines[2].redmine_version_id = 3
        end

        it 'updates the associated Org::File' do
          expect(file.buffer.string).to eq(<<FILE)
#+ORG_REDMINE_TRACKERS: @bug:1 @feature:2 @support:3 !@task:4 @feedback:5 @planning:6 @doc:7 @requirement:8
* First Parent                                                    :inherited:
:PROPERTIES:
:redmine_project_id: some_project
:END:
** Version 1                                                   :milestone:
:PROPERTIES:
:redmine_version_id: 1
:END:
** Version 2                                                   :milestone:
:PROPERTIES:
:redmine_version_id: 2
:END:
* Second Parent
:PROPERTIES:
:redmine_project_id: other_project
:END:
Some contents for this heading.
** Third Parent
:PROPERTIES:
:redmine_project_id: nested_project
:END:
*** Version 3                                                   :milestone:
:PROPERTIES:
:redmine_version_id: 3
:END:
**** TODO # - Super Issue
**** NEXT # - Parent Issue
***** DONE # - Sub Issue                                         :@feature:
*** TODO # - Other Issue
** Version 4                                                     :milestone:
:PROPERTIES:
:redmine_version_id: 4
:END:
** TODO # - Some Issue
Some description.
FILE
        end
      end
    end
  end
end
