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

  def self.write_qp(dir_dml, dir_qp, ads_username, ads_password, ads_hostname, ads_instance_id, flag_if_missing)
    ads_url = "jdbc:gdc:datawarehouse://#{ads_hostname}:443/gdc/datawarehouse/instances/#{ads_instance_id}"

    @connection = ::Helpers.connect_ADS(:username => ads_username,
                                        :password => ads_password,
                                        :ads_instance_url => ads_url)

    Dir.glob("#{dir_dml}/*") do |item|
      file_content = File.read(item).upcase
      add_stats = 1 if file_content.to_s.include?("ANALYZE_STATISTICS") && flag_if_missing.include?("ANALYZE_STATISTICS")

      file_content.gsub!("TRUNCATE", "--TRUNCATE")
      file_content.gsub!("SELECT ANALYZE_STATISTICS", "--SELECT ANALYZE_STATISTICS")

      qp = @connection.read_data("EXPLAIN " << file_content)
      qp_content = ""

      qp.each do |result|
        qp_content << result[:"query plan"] << "\n"
      end

      file_name = "#{dir_qp}/#{@ts}/#{item.split("/").last}"

      qp_content << "\n#{'-' * 30}\nADS LINT NOTES:\n#{'-' * 30}\n\n"
      qp_content << "ANALYZE_STATISTICS present." if add_stats == 1

      Dir.mkdir("#{dir_qp}") unless File.exists?("#{dir_qp}")
      Dir.mkdir("#{dir_qp}/#{@ts}") unless File.exists?("#{dir_qp}/#{@ts}")
      File.open(file_name, 'w') { |file| file.write(qp_content) }

      puts "WRITING query plan for: #{item.split("/").last}"
    end
  end

  def self.read_qp(dir_qp, cost_min, flag_if_present, flag_if_missing, projection_recommendations)
    @files_scanned, @files_above_cost, @files_list = 0, 0, []
    @keypairs, @tables = [[]], []

    @body, @rec_body = "", ""

    @header = "#{'=' * 25} ADS LINT RESULTS #{'=' * 25}\n"
    @header << "This validation executed at: #{Time.now}\n\n"

    Dir.glob("#{dir_qp}/#{@ts}/*") do |item|
      @files_scanned = @files_scanned + 1;
      @flags_list = Hash.new(Array.new)

      costs = File.read(item).scan(/Cost: \d+[a-zA-z]?+/)
      costs.each { |text| convert_abbr(text.to_s, "to_i").gsub!(/[^\d]+/, "") }

      cost_max = costs.map(&:to_i).max
      cost_min = convert_abbr(cost_min.to_s, "to_i").to_i

      puts "READING query plan for: #{item.split("/").last}"

      check_flags(item, cost_max, flag_if_present, flag_if_missing) if cost_max > cost_min
      get_join_keys(item) if cost_max > cost_min && projection_recommendations == "ON"
    end

    write_recs if projection_recommendations == "ON"
    puts "WRITING summary file..."

    @header << "Files scanned: #{@files_scanned}\n"
    @header << "Files above cost threshold: #{@files_above_cost}\n"
    @header << "Files above cost threshold + keyword flagged: #{@files_list.uniq.length}\n"
    @header << "#{'=' * 68}\n\nADS Lint has flagged the following files:\n"
    @header << "Great! No query plans were flagged in: #{dir_qp}/#{@ts}" if @files_above_cost == 0

    if projection_recommendations == "ON" && @key_mag.length > 0
      @rec_body.prepend("\n#{'=' * 68}\n\nADS Lint recommends the following clauses for your default projections. Please compare to your DDL:\n\n")
    elsif projection_recommendations == "ON"
      @rec_body.prepend("\n#{'=' * 68}\n\nADS Lint does not have any projection recommendations because it did not detect any joins.\n")
    else
      @rec_body.prepend("\n#{'=' * 68}\n\nProjection recommendations are off. To enable, turn it \"ON\" in the configuration file.\n")
    end

    puts "\nADS Lint has completed. Type 'open lint.txt' to review.\n\n#{'=' * 15}\n"
    File.open('./lint.txt', 'w') { |file| file.write(@header << @body << @rec_body) }

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
         @flags_list["#{file_name}"] += ["MISSING #{smell}"]
         @files_list += ["#{file_name}"]
       end
    end         

    @flags_list.each do |file_name, flags|
      @body << "\n+ File: #{file_name}\n" 
      @body << "+---> HIGH COST: #{convert_abbr(cost_max, 'to_s')}\n"

      flags.each do |flag|
        @body << "+---> #{flag}\n"
      end
    end
  end

  def self.get_join_keys(item)
    keys = File.read(item).scan(/Join Cond:\s\((.[\s\da-zA-z._=]*)/)

    keys.each do |join_cond|
      left_key, right_key = join_cond[0].split[0], join_cond[0].split[2]
      @keypairs.push([left_key, right_key])
      @tables.push(left_key.split('.')[0], right_key.split('.')[0])
    end
  end

  def self.write_recs
    @table_counts, @key_mag, @key_seg, table_used = {}, {}, {}, {}

    @tables.uniq.each do |name| 
      @connection.read_data("SELECT COUNT(*) FROM " << name) .each do |result|
        @table_counts[:"#{name}"] = result[:"count"]
      end
    end

    puts "COMPARING joins and table sizes in all queries..."
    @keypairs.reject! { |k| k.blank? }
    compare_joins

    @key_mag.sort_by { |k, m| [k.to_s.split('.')[0], -m] }.each do |key, mag|
      table, field = key.to_s.split('.')[0], key.to_s.split('.')[1]

      next if table_used[:"#{table}"]
      table_used[:"#{table}"] = 1

      @rec_body << "+ Table: #{table}\n"

      if @key_seg[:"#{table}"] == -1
        @rec_body << "+---> ORDER BY #{field}\n+---> UNSEGMENTED ALL NODES\n\n" 
      else
        @rec_body << "+---> ORDER BY #{field}\n+---> SEGMENTED BY HASH(#{field}) ALL NODES\n\n"
      end
    end
  end

  def self.compare_joins
    @keypairs.each do |left_key, right_key|
      left_table, right_table = left_key.split('.')[0], right_key.split('.')[0]
      left_field, right_field = left_key.split('.')[1], right_key.split('.')[1]

      magnitude = @table_counts[:"#{left_table}"] * @table_counts[:"#{right_table}"]

      @key_mag[:"#{left_key}"] = magnitude unless @key_mag.key?(:"#{left_key}") && @key_mag[:"#{left_key}"] > magnitude
      @key_mag[:"#{right_key}"] = magnitude unless @key_mag.key?(:"#{right_key}") && @key_mag[:"#{right_key}"] > magnitude

      @key_seg[:"#{left_table}"] = -1 if @table_counts[:"#{left_table}"] * 15 < @table_counts[:"#{right_table}"].to_i
      @key_seg[:"#{right_table}"] = -1 if @table_counts[:"#{right_table}"] * 15 < @table_counts[:"#{left_table}"].to_i
    end
  end

  def self.convert_abbr(text, mode)
    if mode == "to_i"
      text.gsub!(",", "")
      text.gsub!("B", "0" * 9)
      text.gsub!("M", "0" * 6)
      text.gsub!("K", "0" * 3)
    else
      text = text.to_s.reverse
      text.gsub!("0" * 9, "B")
      text.gsub!("0" * 6, "M")
      text.gsub!("0" * 3, "K")
      text.reverse!
    end

    text
  end

end

puts "#{'=' * 15}\n\nADS LINT\n\n"

ADSLint.write_qp(@m_params['dir_dml'],
                 @m_params['dir_qp'],
                 @m_params['ads_username'],
                 @m_params['ads_password'],
                 @m_params['ads_hostname'],
                 @m_params['ads_instance_id'],
                 @o_params['flag_if_missing'])

ADSLint.read_qp(@m_params['dir_qp'],
                @m_params['cost_minimum'],
                @o_params['flag_if_present'],
                @o_params['flag_if_missing'],
                @m_params['projection_recommendations'])