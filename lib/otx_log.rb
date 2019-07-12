
class OTXLog

    include Enumerable

    def self.open filepath
        new filepath
    end

    def initialize filepath
        @filepath = filepath
        @csv = CSV.open filepath
        @header = csv.first
    end

    def select *columns
        selected_columns_array =
            columns.map do |column_name|
                column_index = header.index column_name
                raise ArgumentError, "Column not found: #{column_name}" unless column_index
                [ column_name, column_index ]
            end
        @selected_columns = Hash[selected_columns_array]
        self
    end

    def each &block
        Enumerator.new do |enum|
            csv.rewind
            csv.first
            if selected_columns.nil?
                csv.each { |line| enum.yield Hash[header.zip line] }
            else
                csv.each { |line| enum.yield Hash[selected_columns.map { |column_name, column_index| [column_name, line[column_index]] }] }
            end
        end.each &block
    end

    def last
        to_a[-1]
    end

    def kml_linestring_coordinates
        map { |log_data| self.class.to_kml_linestring_coordinates(log_data) }.join(' ')
    end

    def kml_track_coords
        map { |log_data| self.class.to_kml_track_coords(log_data) }
    end

    def self.require_columns log_data, *columns
        missing_columns = columns - log_data.keys
        raise ArgumentError, "missing required data columns: #{missing_columns.join(', ')}", caller[1..-1] unless missing_columns.empty?
    end

    def self.to_kml_datetime log_data
        require_columns log_data, *%w[ Date Time ]
        "#{log_data['Date']}T#{log_data['Time'][0..-2]}Z"
    end

    def self.to_kml_linestring_coordinates log_data
        require_columns log_data, *%w[ GPS Alt(m) ]
        coordinates = log_data['GPS'].split /\s+/
        altitude = log_data['Alt(m)']
        [ *coordinates.reverse, altitude ].join ','
    end

    def self.to_kml_track_coords log_data
        require_columns log_data, *%w[ GPS ]
        coordinates = log_data['GPS'].split /\s+/
        [ *coordinates.reverse, 0 ].join ' '
    end

    attr_reader :filepath, :header

    private

    attr_reader :csv, :selected_columns, :rewind

end

