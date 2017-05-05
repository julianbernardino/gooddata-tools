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
        
        puts "Setting values: #{values}"

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
        
        client = params['GDC_GD_CLIENT'] || fail('GDC_GD_CLIENT missing')
        project = client.projects(params['gdc_project']) || client.projects(params['GDC_PROJECT_ID'])
        fail 'input_source missing' unless params['input_source']
        data_source = GoodData::Helpers::DataSource.new(params['input_source'])
        
        mandatory_params = [data_source]
        mandatory_params.each { |param| fail param + ' is required' unless param }
        
        # Load variables and values from ADS.
        data = CSV.read(File.open(data_source.realize(params), 'r:UTF-8'),
               :headers => true, :return_headers => false, encoding: 'utf-8')
        
        # Check header names and order.
        expected_headers = ["login", "variable", "value", "label", "pid"]
        fail "Headers: #{data.headers.join(', ')} | Expected: #{expected_headers.join(', ')}" unless data.headers == expected_headers
        
        puts 'data:' + data.to_s
        data.group_by { |d| d['pid'] }
        .map do |project, row|
          # Set project context.
          project = client.projects(project)

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