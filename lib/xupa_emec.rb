require "rubygems"
require "bundler/setup"

require 'nokogiri'
require "mechanize"
require 'active_support'
require 'trollop'
require 'fastercsv'

opts = Trollop::options do
  version "xupa emec #{open('VERSION').read} (c) 2010 Bernardo de Pádua"
  banner <<-EOS
Xupe as informações do e-mec a partir de uma lista de IESs exportada no site.

Uso:
       xupa_emec -i rela.xls -o ies.csv
as opções são:
  EOS
  opt :entrada, "Arquivo fonte com lista de faculdades exportadas pelo emec", :short => 'i', :default => 'in.xls'
  opt :saida, "Arquivo csv que será gerado", :short => 'o', :default => 'out.csv'
end

#monkey patches string for mb_chars
class String
  def mb_chars
    ActiveSupport::Multibyte::Chars.new(self)
  end
end


agent = Mechanize.new { |a|
  a.user_agent_alias = 'Mac Safari'
}

File.open(opts[:entrada], "r") do |input|

  in_html = doc = Nokogiri::HTML(input)
  iess_to_search = in_html.css('table:nth-child(2) tbody tr')

  puts "Vamos importar #{iess_to_search.size} IESs..."
  puts

  iess_to_search.each_with_index do |line, index|

    FasterCSV.open(opts[:saida], "w", 
      :write_headers => true,
      :headers => ['nome', 'tipo', 'cidade', 'tel', 'site', 'email', 'mantenedora', 'representante_nome', 'representante_primeiro_nome', 'representante_cargo']) do |out_csv|


      raw_name = line.css('td:nth-child(2)').text.strip
      ies_search_name = raw_name.split('-').max{|a,b| a.length <=> b.length } #pega o nome maior

      puts
      puts "#{index + 1} - Buscando nome da instituição '#{ies_search_name}'..."

      r = agent.post('http://emec.mec.gov.br/emec/consulta-cadastro/listar-ies', {
          'data[buscar_por]' => "IES",
          'data[hid_order]' => 'vw_cdst_consulta_interativa.no_ies ASC',
          'data[rad_tp_buscar_curso]' => '2',
          'data[rad_tp_buscar_ies]' => '1',
          'data[txt_no_ies]' => ies_search_name
        })


      ies_url = r.search('#lista_resultado > table > tbody > tr > td')[2].inner_html.match( /detalhamento\/(.*)\' \)/ )[1]

      puts "Buscando dados de '#{ies_search_name}' em #{ies_url}..."
      ies_data = agent.get("http://emec.mec.gov.br/emec/consulta-ies/index/#{ies_url}")

      ies_info = {}

      ies_info['mantenedora'] = ies_data.search("table.tab_paleta > tr:nth-child(2) tr:nth-child(1) > td:nth-child(2)").first.text.strip

      if representante_line = ies_data.search("table.tab_paleta > tr:nth-child(2) tr:nth-child(3) > td:nth-child(2)").first
        rep = representante_line.text.strip
        r_match = rep.match(/([^()]*)\(([^()]*)\)/)
        ies_info['representante_nome'] = r_match[1].mb_chars.titleize.strip.to_s
        ies_info['representante_primeiro_nome'] = ies_info['representante_nome'].split(' ').first
        ies_info['representante_cargo'] = r_match[2].mb_chars.titleize.strip.to_s
      end

      ies_info['nome'] = ies_data.search("table.tab_paleta > tr:nth-child(4) tr:nth-child(1) > td:nth-child(2)").first.text.strip

      ies_info['cidade'] = ies_data.search("table.tab_paleta > tr:nth-child(4) tr:nth-child(5) > td:nth-child(2)").first.text.strip

      ies_info['tel'] = ies_data.search("table.tab_paleta > tr:nth-child(4) tr:nth-child(6) > td:nth-child(2)").first.text.strip

      ies_info['tipo'] = ies_data.search("table.tab_paleta > tr:nth-child(4) tr:nth-child(7) > td:nth-child(2)").first.text.strip

      ies_info['site'] = ies_data.search("table.tab_paleta > tr:nth-child(4) tr:nth-child(7) > td:nth-child(4)").first.text.strip

      ies_info['email'] = ies_data.search("table.tab_paleta > tr:nth-child(4) tr:nth-child(8) > td:nth-child(2)").first.text.strip

      out_csv << ies_info

      puts "Informação processada para '#{ies_search_name}' :"
      puts ies_info.to_yaml

    end

  end

end



