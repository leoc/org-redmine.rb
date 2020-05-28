# org-redmine.rb

[Help Wanted] [WIP] Ruby tool to synchronize redmine and org-mode

`org-redmine.rb` aims to be a two-way synchronization tool between redmine and an opinionated org-mode file structure.

Currently it only synchronizes new issues and time-entries one-way:

```org
* # - New Issue Title
```

It allows a hierarchy of projects, milestones, issues and sub-issues:

```org
* Redmine Project
:PROPERTIES:
:redmine_project_id: project-identifier
:END:
** Milestone 1.0
:PROPERTIES:
:redmine_version_id: 1
:END:
*** #123 - Existing Issue   :@bug:

Some content here ...

*** # - New Issue Title

What am I about to do?

**** # - Sub-Issue

Something nice to divide and conquer ...
```

## Todos

- [ ] Improve the naive parser implementation
- [ ] Implement two-way synchronization with a local cache
- [ ] Add tests
- [ ] Link to Redmine issue via org-link in heading
- [ ] Create org-redmine-mode to quickly pull information, link issues, add comments, etc 
