def org_date_to_datetime(str)
  match = str.match(/(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2}) [A-Za-z]{3} (?<hour>\d+):(?<minute>\d+)/)
  DateTime.new(
    match[:year].to_i,
    match[:month].to_i,
    match[:day].to_i,
    match[:hour].to_i,
    match[:minute].to_i,
    0,
    DateTime.now.offset
  )
end

def org_time_to_time(str)
  time = str.match(/(?<hour>\d+):(?<minute>\d+)/)
  time[:hour].to_i * 60 + time[:minute].to_i
end
