#
#  AppDelegate.rb
#  epub-r
#
#  Created by Patrik Schlund on 1/20/13.
#  Copyright 2013 Patrik Schlund. All rights reserved.
#

class AppDelegate
    attr_accessor :window
    attr_accessor :webView
    attr_accessor :btn_prev_page
    attr_accessor :btn_next_page
    attr_accessor :destination_path
    attr_accessor :btn_toc

    def applicationDidFinishLaunching(a_notification)
        window.backgroundColor = NSColor.whiteColor
        # TODO: Switch this to bundle path
        @tmp_dir =  File.join(NSTemporaryDirectory(), 'iRead/')
        puts "The temp dir is: #{@tmp_dir}"
        
        # Clear default items from toc
        @btn_toc.removeAllItems
        
        
        # Wire up viewer
        #@viewer = EpubViewer.new(@webView)
        
    end
    
    # WebView delegates
    def webView(view, identifierForInitialRequest:request, fromDataSource:dataSource)
        
        p =  request.URL.relativePath
        return if p.include?('http') # This is web request, skip
        
        puts "Relative path is #{p}"
        file = p.gsub(@tmp_dir, '')
        puts "Request epub file #{file}"
        @book.extract file
    end
    
    # button delegates
    
    def browse(sender)
        # Create the File Open Dialog class.
        dialog = NSOpenPanel.openPanel
        # Disable the selection of files in the dialog.
        dialog.canChooseFiles = true
        # Enable the selection of directories in the dialog.
        dialog.canChooseDirectories = false
        # Disable the selection of multiple items in the dialog.
        dialog.allowsMultipleSelection = false
        
        # Display the dialog and process the selected folder
        if dialog.runModalForDirectory(nil, file:nil) == NSOKButton
            # if we had a allowed for the selection of multiple items
            # we would have want to loop through the selection
            path = dialog.filenames.first
            destination_path.stringValue = path
            @book.cleanup if @book
            @book = Epub.new(path, @tmp_dir)
            @current_page = @book.toc_list[0][:src].split('#')[0]
            url = "file://#{File.join(@tmp_dir, @current_page)}"
            load_web_view url
            @btn_toc.removeAllItems
            @btn_toc.addItemsWithTitles @book.toc_list.map{|a| a[:title]}            
        end
    end
    
    
    private
    def load_web_view(url)
        req = NSURLRequest.requestWithURL(NSURL.URLWithString(url))
        
        webView.setCustomUserAgent 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_2; en-us) AppleWebKit/531.21.8 (KHTML, like Gecko) Version/4.0.4 Safari/531.21.10'
        webView.mainFrame.loadRequest req
        
        # TODO: Need to figure out how to scale properly
        #webView.scaleUnitSquareToSize(NSMakeSize(1.5, 1.5))
    end
    
    def toc_selection_changed(sender)
        selected_item = @btn_toc.titleOfSelectedItem
        @current_page = @book.toc_list.find{|f| f[:title] == selected_item}[:src].split('#')[0]
        url = "file://#{File.join(@tmp_dir, @current_page)}"
        load_web_view url
    end
    
    def text_larger(sender)
        # TODO: Figure out why this is not working
        webView.makeTextLarger sender
    end
    
    def text_smaller(sender)
        webView.makeTextSmaller sender
    end
    
    
    def open_title(sender)
        @current_page = @book.cover_path
        url = "file://#{File.join(@tmp_dir, @book.cover_path)}"
        load_web_view url
    end
    
    def open_toc(sender)
        @current_page = @book.toc_path
        url = "file://#{File.join(@tmp_dir, @book.toc_path)}"
        load_web_view url
    end
    
    def prev_page(sender)
        new_page = @book.get_previous_page(@book.url_to_id[@current_page])
        puts "New page #{new_page}"
        if new_page
            @current_page = @book.id_to_url[new_page]
            url = "file://#{File.join(@tmp_dir, @current_page)}"
            load_web_view url
        end
    end
    
    def next_page(sender)
        new_page = @book.get_next_page(@book.url_to_id[@current_page])
        if new_page
            @current_page = @book.id_to_url[new_page]
            url = "file://#{File.join(@tmp_dir, @current_page)}"
            load_web_view url
        end
    end
    
end

