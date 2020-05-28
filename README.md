# org-redmine.rb

[Help Wanted] [WIP] Ruby tool to synchronize redmine and org-mode

`org-redmine.rb` aims to be a two-way synchronization tool between redmine and an opinionated org-mode file structure.

Currently it only synchronizes new issues and time-entries one-way:

```
* # - Issue Title
```

It allows a hierarchy of projects, milestones, issues and sub-issues.

## Todos

- [ ] Improve the naive parser implementation
- [ ] Implement two-way synchronization with a local cache
- [ ] Add tests
- [ ] Link to Redmine issue via org-link in heading
