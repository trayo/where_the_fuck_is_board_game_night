require "open-uri"

module BoardGameNight
  class LocationFetcher
    def self.update_events_and_locations
      new(fetch_dates_and_locations).create_events_and_locations
    end

    def self.fetch_dates_and_locations
      Nokogiri::HTML(open("http://www.reddit.com/r/Denver/wiki/wednesdaymeetup"))
      .at_css("#wiki_tentative_schedule").next_element.children.map(&:text)
    end

    attr_reader :lines

    def initialize(lines)
      @lines = parse(lines).to_h
      @dates, @locations = @lines.keys, @lines.values
    end

    def create_events_and_locations
      @lines.each do |date, location_name|
        location = Location.find_by(name: location_name)
        event = Event.find_by(date: date)

        if location && location.events.include?(event)
          # do nothing?
          # print already added location and event

        elsif location # and no event
          location.events << Event.create(date)

        elsif Event.exists?(date)
          event = Event.find_by(date: date)
          location = event.location
          location.update_attribute(name: location_name)
        else
        end
      end

      # create_events
      # create_locations
    end

    private

    def remove_old_events_and_locations(lines)
      lines.reject { |date, _location| before_today?(date) }
    end

    def create_events
      @dates.each do |date|
        if Event.exists?(date: date)
          puts "Event not created on #{date}"
        else
          puts "Created event on #{date} with location id: #{@lines[date]}"
          Event.create(location_id: @lines[date], date: date)
        end
        # Event.update_or_create(date)
      end
    end

    def create_locations
      @locations
    end

    def before_today?(date)
      date < Date.today
    end

    def parse(lines)
      lines.delete("\n")
      lines.map! { |l| l.split(": ") }
      lines.map! { |date, location| [Date.parse(date), location] }
      remove_old_events_and_locations(lines)
    end
  end
end
