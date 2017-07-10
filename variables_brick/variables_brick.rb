# encoding: utf-8
require 'open-uri'
require 'csv'
require 'gooddata'
include GoodData::Bricks

module GoodData
  module Bricks
    
    class VariablesBrick < GoodData::Bricks::Brick

      def call(params)
        @params = params
        @data_source = GoodData::Helpers::DataSource.new(@params['input_source'])

        check_params
        pick_segments
        load_data
        auto_toggle
        assign_workspace if @sync_mode == 'workspace'
        assign_user if @sync_mode == 'user'
      end

      def set_variable_value(user_id = nil, variable, label, values)
        @project = variable.project
        @user_id = user_id
        @variable = variable
        @label = label
        @values = values
        @client = @project.client

        @project_values = variable.project_values
        @user_values_index = self.find_index

        create_payload
        post_payload
      end

      def find_index
        @variable.user_values.map { |i| [i.data, i.to_s] }
        .find_index { |m| m[0] == @user_id }
      end

      def create_payload
        expression = GoodData::SmallGoodZilla.create_category_filter([@label] + @values, @project)
        values = expression[:expression]
        related = @user_id ? @user_id : @project.uri
        level = @sync_mode == 'user' ? 'user' : 'project'

        @payload = {
          "variable" => {
            "expression" => values,
            "level" => "#{level}",
            "type" => "filter",
            "prompt" =>  @variable.uri,
            "related" => related
          }
        }
      end

      def post_payload
        if (@sync_mode == 'workspace' && @project_values.empty?) || (@sync_mode == 'user' && @user_values_index.nil?)
          @client.post(@project.links['metadata'] + '/variables/item', @payload)
        elsif @sync_mode == 'workspace'
          post_uri = @project_values.first.uri
          @client.post(post_uri, @payload)
        elsif @sync_mode == 'user'
          post_uri = @variable.user_values[@user_values_index].uri
          @client.post(post_uri, @payload)
        end
      end

      def check_params
        @client = @params['GDC_GD_CLIENT']
        @domain_name = @params['organization'] || @params['domain']
        @segment_name = @params['segment']
        @sync_mode = @params['sync_mode'].downcase

        mandatory_params = [@data_source, @sync_mode, @client, @domain_name, @segment_name]
        mandatory_params.each { |param| 'Missing parameter' unless param }

        fail 'Input_source missing' unless @params['input_source']
        fail 'Sync mode invalid' unless @sync_mode == 'user' || @sync_mode == 'workspace'
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

      def auto_toggle
        @ads_data = @ads_data.select { |row| row['client_id'].downcase == @params['CLIENT_ID'].downcase } if @params['CLIENT_ID']
      end 

      def load_data
        @ads_data = CSV.read(File.open(@data_source.realize(@params), 'r:UTF-8'),
                    :headers => true, :return_headers => false, encoding: 'utf-8')

        expected_headers = ["client_id", "label", "variable", "value"] if @sync_mode == 'workspace'
        expected_headers = ["client_id", "login", "label", "variable", "value"] if @sync_mode == 'user'

        fail "Unexpected headers - check naming and ordering" unless @ads_data.headers == expected_headers
      end

      def assign_workspace
        @ads_data.group_by { |d| d['client_id'] }
        .map do |input_client, row|
          get_project = @client_pid_map["#{input_client}"]
          project = @client.projects(get_project)

          row.group_by { |line| [line['variable']] }
          .each do |block_result, row|
            variable  = project.variables(block_result[0])
            label     = project.labels(row.first['label'])

            set_variable_value(nil, variable, label, row.map {|l| l['value']})
          end
        end
      end

      def assign_user
        @ads_data.group_by { |d| d['client_id'] }
        .map do |input_client, row|
          get_project = @client_pid_map["#{input_client}"]
          project = @client.projects(get_project)

          row.group_by { |line| [line['variable'], line['login']] }
          .each do |block_result, row|
            user_id = project.get_user(block_result[1])
                      .json['user']['links']['self']
            variable  = project.variables(block_result[0])
            label     = project.labels(row.first['label'])

            set_variable_value(user_id, variable, label, row.map {|l| l['value']})
          end
        end
      end

    end
  end
end