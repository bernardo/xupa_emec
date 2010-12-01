module XupaEmec
  class Crawler
    def initialize(agent = Mechanize.new)
      @agent = agent
    end
    
    attr_reader :agent
    
    def crawl(ies_search_name)      

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

      puts "Informação processada para '#{ies_search_name}' :"
      puts ies_info.to_yaml
      
      ies_info
      
    end
    
    
  end
  
end