require 'base64'

module XupaEmec
  class Crawler
    def initialize(options={})
      @search_courses = options[:search_courses]
      @vacancies_estimation = options[:vacancies_estimation]
      @agent = options[:agent] || Mechanize.new
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


      ies_name_cell = r.search('#lista_resultado > table > tbody > tr > td')[2]
      return unless ies_name_cell
      ies_url = ies_name_cell.inner_html.match( /detalhamento\/(.*)\' \)/ )[1]

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

      ies_info['sigla'] = ies_info['nome'].split(' - ')[1..-1].join('-')

      ies_info['nome_limpo'] = ies_info['nome'].split(' - ')[0].mb_chars.titleize

      ies_info['cidade'] = ies_data.search("table.tab_paleta > tr:nth-child(4) tr:nth-child(5) > td:nth-child(2)").first.text.strip

      ies_info['uf'] = ies_data.search("table.tab_paleta > tr:nth-child(4) tr:nth-child(5) > td:nth-child(4)").first.text.strip.upcase

      ies_info['tel'] = ies_data.search("table.tab_paleta > tr:nth-child(4) tr:nth-child(6) > td:nth-child(2)").first.text.strip

      ies_info['tipo'] = ies_data.search("table.tab_paleta > tr:nth-child(4) tr:nth-child(7) > td:nth-child(2)").first.text.strip

      ies_info['site'] = ies_data.search("table.tab_paleta > tr:nth-child(4) tr:nth-child(7) > td:nth-child(4)").first.text.strip

      ies_info['email'] = ies_data.search("table.tab_paleta > tr:nth-child(4) tr:nth-child(8) > td:nth-child(2)").first.text.strip.split(/\s*[\s,;\/\\]\s*/).join(',')

      if @search_courses
        courses_page= agent.get("http://emec.mec.gov.br/emec/consulta-ies/listar-curso-agrupado/#{ies_url}/page/1/list/1000")
        match_results = courses_page.search("div.campform > div:first-child").text.match(/Registro\(s\)\: 1 a \d+ de (\d+)/)
        if match_results
          ies_info['num_cursos'] = match_results[1]
          if @vacancies_estimation
            ies_info['total_vagas'] ||= 0
            ies_info['vagas_presencias'] ||= 0
            ies_info['vagas_a_distancia'] ||= 0
            courses_pages = courses_page.search("table#listar-ies-cadastro > tbody > tr").map{ |l| l.search('td > a').first.attributes['href'].value }
            courses_pages.each do |courses_url|
              # http://emec.mec.gov.br/emec/consulta-curso/listar-curso-desagrupado/9f1aa921d96ca1df24a34474cc171f61/MQ==/d96957f455f6405d14c6542552b0f6eb/MTIzMA==
              courses_url.gsub!('detalhamento', 'listar-curso-desagrupado').gsub!('consulta-cadastro', 'consulta-curso')
              courses_in_campus = agent.get(courses_url)
              puts " *** URL: #{courses_url}"
              courses_in_campus.search("table > tbody > tr").map{ |l| [l.search('td').first.text.strip, l.search('td:nth-child(2)').first.text.strip == "A Distância"] }.each do |course_in_campus_id, distance|
                # Macaco das URLs bizarras do e-mec:
                #   http://emec/consulta-curso/detalhe-curso-tabela/ + md5('co_ies_curso') + / base64(course_in_campus_id)
                #   md5('co_ies_curso') => c1999930082674af6577f0c513f05a96
                # Exemplos:
                #   http://emec.mec.gov.br/emec/consulta-curso/detalhe-curso-tabela/c1999930082674af6577f0c513f05a96/NDQ5Mjc=
                #   http://emec.mec.gov.br/emec/consulta-curso/detalhe-curso-tabela/c1999930082674af6577f0c513f05a96/NDQ2MTU=
                course_in_campus_page = agent.get "http://emec.mec.gov.br/emec/consulta-curso/detalhe-curso-tabela/c1999930082674af6577f0c513f05a96/#{Base64.encode64 course_in_campus_id}"
                vacancies = 0
                course_in_campus_page.search("table.avalTabCampos > tr:nth-child(4) > td:nth-child(4)").first.text.strip.scan(/\:(\d*)/).each do |data|
                  vacancies += data[0].to_i
                end
                puts "    *** ID: #{course_in_campus_id}"
                puts "    *** VAGAS: #{vacancies}"
                ies_info['total_vagas'] += vacancies
                if distance
                  ies_info['vagas_a_distancia'] += vacancies
                else
                  ies_info['vagas_presencias'] += vacancies
                end
              end
            end
          end
          ies_info['lista_cursos'] = courses_page.search("table#listar-ies-cadastro > tbody > tr").map{|l| l.search('td').first.text.gsub('&nbsp;', '').strip}.join(', ')
          
        end
      end
      if @vacancies_estimation
        ies_info['media_de_vagas_por_curso'] = ies_info['total_vagas'].to_f / ies_info['num_cursos'].to_i
      end

      puts "Informação processada para '#{ies_search_name}' :"
      puts ies_info.to_yaml
      
      ies_info
      
    end
    
    
  end
  
end