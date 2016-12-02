class Hash
  def pick(*keys)
    values = values_at(*keys)
    Hash[keys.zip(values)]
  end
end
