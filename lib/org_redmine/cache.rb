class OrgRedmine
  class Cache
    attr_reader :file

    def initialize(file)
      @file = file
      @cache =
        if File.exist?(file)
          JSON.load(File.new(file)).deep_symbolize_keys
        else
          {}.deep_symbolize_keys
        end
    end

    def cache
      @cache ||= {}
    end

    def versions
      cache[:versions] ||= []
    end

    def apply_versions_diff(versions_diff)
      apply_diff(versions, versions_diff)
    end

    def add_version(version)
      versions.push(version.symbolize_keys)
    end

    def issues
      cache[:issues] ||= []
    end

    def apply_issues_diff(issues_diff)
      apply_diff(issues, issues_diff)
    end

    def add_issue(issue)
      issues.push(issue.symbolize_keys)
    end

    def save
      File.open(file, 'w+') do |f|
        f.write(cache.to_json)
      end
    end

    private

    def apply_diff(list, diff)
      diff = diff.map(&:symbolize_keys)
      diff.each do |diff_obj|
        existing_element = list.find do |issue|
          issue[:id] == diff_obj[:id]
        end
        if existing_element
          diff_obj.each_pair do |key, value|
            existing_element[key] = value
          end
        else
          list.push(diff_obj)
        end
      end
    end
  end
end
