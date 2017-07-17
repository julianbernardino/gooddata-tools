# encoding: utf-8

require 'gooddata'
require 'csv'
include GoodData::Bricks

module GoodData
  module Bricks
    class ScheduleParamsBrick < GoodData::Bricks::Brick

      def call(params)
      	@params = params
        @data_source = GoodData::Helpers::DataSource.new(@params['input_source'])

        check_params
        pick_segments
        load_data

        @client = GoodData.connect(username: "#{params['GDC_USERNAME']}",
        	                         password: "#{params['GDC_PASSWORD']}",
        	                         server: "https://#{params['CLIENT_GDC_HOSTNAME']}")

        set_param_values
      end

      def load_data
        @ads_data = CSV.read(File.open(@data_source.realize(@params), 'r:UTF-8'),
                    :headers => true, :return_headers => false, encoding: 'utf-8')

        expected_headers = ["client_id", "schedule_name", "param_name", "param_value"]
        fail "Unexpected headers - check naming and ordering" unless @ads_data.headers == expected_headers
      end

      def set_param_values
        @ads_data.group_by { |d| d['client_id'] }
        .map do |input_client, row|
          get_project = @client_pid_map["#{input_client}"]
          project = @client.projects(get_project)

          row.group_by { |line| [line['schedule_name'], line['param_name']] }
          .each do |block_result, row|
            pick_schedule = project.schedules.select { |schedule| schedule.name == row.first['schedule_name']}
            pick_schedule.each do |schedule|
              schedule.update_params("#{row.first['param_name']}" => "#{row.first['param_value']}")
              schedule.save
            end  
          end
        end
      end

      def check_params
        @client = @params['GDC_GD_CLIENT']
        @domain_name = @params['organization'] || @params['domain']
        @segment_name = @params['segment']

        mandatory_params = [@data_source, @client, @domain_name, @segment_name]
        mandatory_params.each { |param| 'Missing parameter' unless param }

        fail 'Input_source missing' unless @params['input_source']
      end

      def pick_segments
        domain = @client.domain(@domain_name)
        all_segments = domain.segments

        pick_segment = all_segments.select { |s| s.segment_id.downcase == @segment_name.downcase }

        pick_segment.each do |segment|
          @client_pid_map = {}
          segment.clients.each do |client|
            @client_pid_map["#{client.client_id}"] = "#{client.project_uri.split("/").last}"
          end
        end
      end

    end  
  end
end