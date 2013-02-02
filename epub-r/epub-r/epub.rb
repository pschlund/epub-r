#
#  epub.rb
#  epub-r
#
#  Created by Patrik Schlund on 1/20/13.
#  Copyright 2013 Patrik Schlund. All rights reserved.
#

require 'rubygems'
require 'rexml/document'
require 'fileutils'
require 'zip/zip'

class Epub
    
    def initialize(filename, tmp_path)
        @filename = filename
        @tmp_path = tmp_path
    end
    
    def title
        @title ||= get_metadata "metadata/dc:title"
    end
    
    def language
        @language ||= get_metadata "metadata/dc:language"
    end
    
    def publisher
        @publisher ||= get_metadata "metadata/dc:publisher"
    end
    
    def date
        @date ||= get_metadata "metadata/dc:date"
    end
    
    def rights
        @rights ||= get_metadata "metadata/dc:rights"
    end
    
    def creator
        @creator ||= get_metadata "metadata/dc:creator"
    end
    
    def identifier
        @identifier ||= get_metadata "metadata/dc:identifier"
    end
    
    def cover_path
        @cover_path ||= opf.root.elements["//guide/reference[@type='cover']"].attribute('href').value
    end
    
    def toc_path
        @toc_path ||= opf.root.elements["guide/reference[@type='toc']"].attribute('href').value
    end
    
    def spine
        @spine ||= opf.root.elements["spine"].elements.map{|e| e.attributes['idref']}
    end
    
    def id_to_url
        @id_to_url ||= opf.root.elements["manifest"].elements.each_with_object({}){|e,r| r[e.attributes['id']] = e.attributes['href']}
    end
    
    def url_to_id
        @url_to_id ||= opf.root.elements["manifest"].elements.each_with_object({}){|e,r| r[e.attributes['href']] = e.attributes['id']}
    end
    
    def get_previous_page(id)
        i = spine.index(id) - 1
        i < 0 ? nil : spine[i]
    end
    
    def get_next_page(id)
        i = spine.index(id) + 1
        spine.size == i ? nil : spine[i]
    end
    
    def cover_image
        # Refactor this method and check for valid functionality
        img_item = opf.root.elements["manifest/item[@id='cover-image']"]
        if img_item
            img_url = 'OEBPS/' + img_item.attributes['href']
            # puts img_url
            @image_cover = zipfile.get_input_stream(img_url) {|f| f.read}
            return @image_cover
        end
    end
    
    def extract(file)
        path = File.join(@tmp_path, file)
        puts "The file is #{file} and the path is #{path}"
        FileUtils.mkdir_p(File.dirname(path))
        file = lookup_file_path file
        #file = File.join(@root_path, file) if @root_path
        zipfile.extract(file, path){true} # True for overriding existing files
    end
    
    def cleanup
        FileUtils.rm_rf("#{@tmp_path}/.", secure: true)
    end
    
    def toc_list
        unless @toc_list
        @toc_list = []
        toc.root.elements.each("navMap/navPoint"){|e| @toc_list << {order: e.attributes['playOrder'].to_i, id: e.attributes['id'], src: e.elements["content"].attributes["src"], title: e.elements["navLabel/text"].text}}
            @toc_list.sort!{|a, b| a[:order] <=> b[:order]}
       end
        @toc_list
    end

    def lookup_file_path(file)
        file_list.find{ |a| a =~ /#{file}$/ }
    end

    def file_list
        @file_list ||= zipfile.map{ |e| e.name }
    end
    
    private

    
    def get_metadata(selector)
        opf.root.elements[selector].text if opf.root.elements[selector]
    end

    def toc
        unless @toc
            id = opf.root.elements["spine"].attribute('toc').value
            url = lookup_file_path id_to_url[id]
            puts url
            #url = File.join(@root_path, url) if @root_path
            toc_file = zipfile.get_input_stream(url)
            @toc = REXML::Document.new toc_file
        end
        @toc
    end
    
    def opf
        unless @opf
            container_file = zipfile.get_input_stream("META-INF/container.xml")
            container = REXML::Document.new container_file
            opf_path = container.root.elements["rootfiles/rootfile"].attributes["full-path"]
            opf_file = zipfile.get_input_stream(opf_path)
            @root_path = File.dirname(opf_path)
            @opf = REXML::Document.new opf_file
        end
        @opf
    end
    
    def zipfile
        @zipfile ||= Zip::ZipFile.open(@filename)
    end
    
end
