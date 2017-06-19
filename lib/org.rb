require 'date'

module Org
  TIMESTAMP_DAY_REGEX = /(Mon|Tue|Wed|Thu|Fri|Sat|Sun)/
  TIMESTAMP_DATE_REGEX = /(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})/
  TIMESTAMP_TIME_REGEX = /(?<hours>\d{1,2}):(?<minutes>\d{2})(:(?<seconds>\d{2}))?/
  TIMESTAMP_REGEX = /(\[|<)#{TIMESTAMP_DATE_REGEX.source}( #{TIMESTAMP_DAY_REGEX.source})?( #{TIMESTAMP_TIME_REGEX.source})?(\]|>)/
  WEEKDAY_MAPPING = {
    0 => 'Sun',
    1 => 'Mon',
    2 => 'Tue',
    3 => 'Wed',
    4 => 'Thu',
    5 => 'Fri',
    6 => 'Sat',
    7 => 'Sun'
  }

  def self.timestamp_to_date(timestamp)
    return if timestamp.nil?
    match = timestamp.match(TIMESTAMP_REGEX)
    Date.new(
      match[:year].try(:to_i),
      match[:month].try(:to_i),
      match[:day].try(:to_i)
    )
  end

  def self.timestamp_to_datetime(timestamp)
    return if timestamp.nil?
    match = timestamp.match(TIMESTAMP_REGEX)
    Date.new(
      match[:year].try(:to_i),
      match[:month].try(:to_i),
      match[:day].try(:to_i),
      match[:hour].try(:to_i),
      match[:minute].try(:to_i)
    )
  end

  def self.format_timestamp(date)
    return if date.nil?
    year = date.year
    month = date.month.to_s.rjust(2, '0')
    day = date.day.to_s.rjust(2, '0')
    weekday = WEEKDAY_MAPPING[date.wday]
    case date
    when DateTime
      format_timestamp(date.to_time)
    when Time
      hour = date.hour.to_s.rjust(2, '0')
      minute = date.min.to_s.rjust(2, '0')
      "<#{year}-#{month}-#{day} #{weekday} #{hour}:#{minute}>"
    when Date
      "<#{year}-#{month}-#{day} #{weekday}>"
    end
  end
end

require 'org/helpers'
require 'org/buffer'
require 'org/position'
require 'org/file'
require 'org/properties'
require 'org/property'
require 'org/planning'
require 'org/logbook'
require 'org/clock'
require 'org_redmine/issue'
require 'org_redmine/cache'
