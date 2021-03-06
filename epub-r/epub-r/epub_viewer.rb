#
#  epub_viewer.rb
#  epub-r
#
#  Created by Patrik Schlund on 2/7/13.
#  Copyright 2013 Patrik Schlund. All rights reserved.
#

require 'forwardable'

class EpubViewer
    extend Forwardable
    attr_accessor :web_view, :delegate, :book, :tmp_dir, :current_page
    def_delegators :@delegate, :page_loading, :page_loaded
    
    # TODO: Figure our if we really need to set this
    CUSTOM_USER_AGENT = 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_2; en-us) AppleWebKit/531.21.8 (KHTML, like Gecko) Version/4.0.4 Safari/531.21.10'
    
    def initialize(web_view)
        @web_view = web_view
        # web_view.UIDelegate = self
        web_view.ResourceLoadDelegate = self
        web_view.setCustomUserAgent  CUSTOM_USER_AGENT
    end
    
    def open(book)
        close
        @book = book
        
        # Open first page in toc
        load_by_page @book.toc_list[0][:src].split('#')[0]        
    end
    
    def close
        if @book
            @book.cleanup
        end
    end
    
    def next_page
        new_page = @book.get_next_page(@book.url_to_id[@current_page])
        if new_page
            load_by_id new_page
        end
    end
    
    def prev_page
        new_page = @book.get_previous_page(@book.url_to_id[@current_page])
        if new_page
            load_by_id new_page
        end
    end
    
    def larger_text(sender)
        web_view.makeTextLarger sender
    end
    
    def smaller_text(sender)
        web_view.makeTextSmaller sender
    end
    
    def webView(view, identifierForInitialRequest:request, fromDataSource:dataSource)
        # We intercept file request from the web browser and make sure that
        # the file has been extracted
        path =  request.URL.relativePath
        
        # Skip extraction if the file is located on the web
        return if path.include?('http')
        
        # Strip the temporary directory from path
        file = path.gsub(@tmp_dir, '')
        
        @book.extract file
    end
    
    def load_by_page(page)
        @current_page = page
        url = "file://#{File.join(@tmp_dir, @current_page)}"
        load url
    end

    protected
    
    def load_by_id(id)
        load_by_page @book.id_to_url[id]
    end
    
    
    def load(url)
        req = NSURLRequest.requestWithURL(NSURL.URLWithString(url))
        @web_view.mainFrame.loadRequest req
    end
end

