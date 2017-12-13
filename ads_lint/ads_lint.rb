# encoding: utf-8

require 'gooddata'
require 'jdbc/dss'
require 'json'
require 'sequel'

require_relative './lib/helpers'

@m_params = JSON.parse(File.read('config.json'))['mandatory_params']
@o_params = JSON.parse(File.read('config.json'))['optional_params']

class ADSLint
  @ts_pp = Time.now
  @ts = @ts_pp.strftime("%Y-%m-%d_%H-%M-%S")

  def self.write_qp(dir_dml, dir_qp, ads_username, ads_password, ads_hostname, ads_instance_id)
    ads_base_url = "jdbc:gdc:datawarehouse://#{ads_hostname}:443"
    ads_ext_url = "/gdc/datawarehouse/instances/#{ads_instance_id}"

    @connection = ::Helpers.connect_ADS(:username => ads_username,
                                        :password => ads_password,
                                        :ads_instance_url => ads_base_url << ads_ext_url
                                       )

    Dir.glob("#{dir_dml}/*") do |item|
      file_content = File.read(item).upcase
      file_content.gsub!("TRUNCATE", "--TRUNCATE")
      file_content.gsub!("SELECT ANALYZE_STATISTICS", "--SELECT ANALYZE_STATISTICS")

      qp = @connection.read_data("EXPLAIN " << file_content)
      qp_content = ""

      qp.each do |text|
        qp_content << text[:"query plan"] << "\n"
      end

      file_name = "#{dir_qp}/#{@ts}/#{item.split("/").last}"

      Dir.mkdir("#{dir_qp}") unless File.exists?("#{dir_qp}")
      Dir.mkdir("#{dir_qp}/#{@ts}") unless File.exists?("#{dir_qp}/#{@ts}")
      File.open(file_name, 'w') { |file| file.write(qp_content) }

      puts "WRITING query plan for: #{item.split("/").last}"
    end
  end

  def self.read_qp(dir_qp, cost_min, flag_if_present, flag_if_missing)
    @files_scanned = 0
    @files_above_cost = 0
    @body = ""
    @files_list = []

    @header = "#{'=' * 25} ADS LINT RESULTS #{'=' * 25}\n"
    @header << "This validation executed at: #{Time.now}\n\n"

    Dir.glob("#{dir_qp}/#{@ts}/*") do |item|
      @files_scanned = @files_scanned + 1;
      @flags_list = Hash.new(Array.new)

      costs = File.read(item).scan(/Cost: \d+[a-zA-z]?+/)
      costs.each { |text| convert_abbr(text.to_s, "to_i").gsub!(/[^\d]+/, "") }

      cost_max = costs.map(&:to_i).max
      cost_min = convert_abbr(cost_min.to_s, "to_i").to_i

      check_flags(item, cost_max, flag_if_present, flag_if_missing) if cost_max > cost_min

      puts "READING query plan for: #{item.split("/").last}"
    end

    @header << "Files scanned: #{@files_scanned}\n"
    @header << "Files above cost threshold: #{@files_above_cost}\n"
    @header << "Files above cost threshold + keyword flagged: #{@files_list.uniq.length}\n"
    @header << "#{'=' * 68}\n"

    @header << "Great! No query plans were flagged in: #{dir_qp}/#{@ts}" if @files_above_cost == 0

    puts "ADS Lint has completed. Type 'open flags.csv' to review."
    File.open('./flags.csv', 'w') { |file| file.write(@header << @body) }

  end

  def self.convert_abbr(text, mode)
    if mode == "to_i"
      text.gsub!("B", "0" * 9)
      text.gsub!("M", "0" * 6)
      text.gsub!("K", "0" * 3)
    else
      text = text.to_s
      text.gsub!("0" * 9, "B")
      text.gsub!("0" * 6, "M")
      text.gsub!("0" * 3, "K")
    end

    text
  end

  def self.check_flags(item, cost_max, flag_if_present, flag_if_missing)
    @files_above_cost += 1      

    flag_if_present.each do |smell|
      if File.foreach(item).any? { |text| text.upcase["#{smell}"] }
        file_name = item.split("/").last
        @flags_list["#{file_name}"] += ["#{smell}"]
        @files_list += ["#{file_name}"]
      end
    end      

    flag_if_missing.each do |smell|
       if File.foreach(item).none? { |text| text.upcase["#{smell}"] }
         file_name = item.split("/").last
         @flags_list["#{file_name}"] += ["#{smell}"]
         @files_list += ["#{file_name}"]
       end
    end         

    @flags_list.each do |file_name, flags|
      @body << "\n#{file_name}\n" 
      @body << "- High cost: #{convert_abbr(cost_max, 'to_s')}\n"

      flags.each do |flag|
        @body << "- #{flag}\n"
      end
    end
  end

end

ADSLint.write_qp(@m_params['dir_dml'],
                 @m_params['dir_qp'],
                 @m_params['ads_username'],
                 @m_params['ads_password'],
                 @m_params['ads_hostname'],
                 @m_params['ads_instance_id']
                )

ADSLint.read_qp(@m_params['dir_qp'],
                @m_params['cost_minimum'],
                @o_params['flag_if_present'],
                @o_params['flag_if_missing']
               )