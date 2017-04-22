class OrgRedmine
  class Issue
    class << self
      # Create a diff that would turn A into B when applied.
      def diff_issue(a, b)
        fail "ID not matching to diff issue versions" if a[:id] != b[:id]
        diff = { id: a[:id] }
        # Add changed values to diff.
        a.each_pair do |key, value|
          diff[key] = b[key] if b[key] != value
        end
        # Add new keys in B to diff.
        b.each_pair do |key, value|
          diff[key] = b[key] if a[key].nil?
        end
        diff
      end

      # Create a diff that would turn all issues in array A into B when
      # applied.
      def diff_issues(a, b)
        diffs = b.select { |i| !i[:id] }
        b.each do |b_issue|
          a_issue = a.find { |issue| issue[:id] == b_issue[:id] }
          a_issue ||= { id: b_issue[:id] }
          diff = diff_issue(a_issue, b_issue)
          diffs.push(diff) unless diff.keys - [:id] == []
        end
        diffs
      end

      def merge_diff(local, remote)
        merge = local.select { |i| !i[:id] }
        local.each do |l_issue|
          next unless l_issue[:id]
          m_issue = {}
          r_issue = remote.find { |issue| issue[:id] == l_issue[:id] }
          (l_issue.keys - Array(r_issue&.keys)).each do |key|
            m_issue[key] = l_issue[key]
          end
          (Array(r_issue&.keys) - l_issue.keys).each do |key|
            m_issue[key] = r_issue[key]
          end
          (Array(r_issue&.keys) & l_issue.keys).each do |key|
            if r_issue[key] == l_issue[key]
              m_issue[key] = l_issue[key]
            else
              m_issue[key] = [l_issue[key], r_issue[key]]
            end
          end
          m_issue[:id] = l_issue[:id]
          merge.push(m_issue)
        end
        remote.each do |r_issue|
          next if merge.find { |m_issue| m_issue[:id] == r_issue[:id] }
          merge.push(r_issue)
        end
        merge
      end
    end
  end
end
