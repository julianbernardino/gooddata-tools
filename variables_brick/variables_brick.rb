# encoding: utf-8
require 'open-uri'
require 'csv'
require 'gooddata'
include GoodData::Bricks

module GoodData
  module Bricks
    
    class VariablesBrick < GoodData::Bricks::Brick

      def self.set_variable_user_value(user_id, variable, label, values)
        project = variable.project
        client = project.client
        
        expression = GoodData::SmallGoodZilla.create_category_filter([label] + values, project)
        values = expression[:expression]

        payload = {
          "variable" => {
            "expression" => values,
            "level" => "user",
            "type" => "filter",
            "prompt" =>  variable.uri,
            "related" => user_id
          }
        }

        # Get all variable objects.
        # Compare User ID to existing variable objects.
        vu_index = variable.user_values.map { |i| [i.data, i.to_s] }
                   .find_index { |m| m[0] == user_id }

        # For each user, the Post URI depends on whether 
        # or not a variable object already exists.
        if vu_index.nil?
          client.post(project.links['metadata'] + '/variables/item', payload)
        else
          post_uri = variable.user_values[vu_index].uri
          client.post(post_uri, payload)
        end
      end

      def call(params)
        
        client = params['GDC_GD_CLIENT'] || fail('GDC_GD_CLIENT is missing')
        project = client.projects(params['gdc_project']) || client.projects(params['GDC_PROJECT_ID'])

        fail 'input_source missing' unless params['input_source']
        data_source = GoodData::Helpers::DataSource.new(params['input_source'])
        
        mandatory_params = [data_source]
        mandatory_params.each { |param| fail param + ' is required' unless param }

        domain_name = params['organization'] || params['domain'] || fail('Organization parameter is empty')
        domain = client.domain(domain_name)

        segment_name = params['segment'] || fail('Segment parameter is empty')

        all_segments = domain.segments

        puts "List segments:"
        all_segments.each do |segment|
          puts "-> #{segment.segment_id}"
        end

        pick_segment = all_segments.select { |s| s.segment_id.downcase == segment_name.downcase }

        puts "Pick segment:"
        pick_segment.each do |segment|
          puts "-> #{segment.segment_id}"

          @client_pid_map = {}

          segment.clients.each do |client|
            @client_pid_map["#{client.client_id}"] = "#{client.project_uri.split("/").last}"
          end
        end

        # Load variables and values from ADS.
        data = CSV.read(File.open(data_source.realize(params), 'r:UTF-8'),
               :headers => true, :return_headers => false, encoding: 'utf-8')

        # Check header names and order.
        expected_headers = ["client_id", "login", "label", "variable", "value"]
        fail "Unexpected headers - check naming and ordering" unless data.headers == expected_headers

        # Auto-toggle to client-specific deployment
        if params['CLIENT_ID']
          data = data.select { |row| row['client_id'].to_s.downcase == params['CLIENT_ID'].to_s.downcase }
        end
        
        data.group_by { |d| d['client_id'] }
        .map do |input_client, row|
          # Set project context.
          get_project = @client_pid_map["#{input_client}"]
          project = client.projects(get_project)

          # Set user and variable context.
          row.group_by { |line| [line['variable'], line['login']] }
          .each do |block_result, row|
            # Set user id, variable, label, and values for user in project
            user_id = project.get_user(block_result[1])
                      .json['user']['links']['self']
            variable  = project.variables(block_result[0])
            label     = project.labels(row.first['label'])

            VariablesBrick.set_variable_user_value(user_id, variable, label, row.map {|l| l['value']})
          end
        end
      end
    end
  end
end