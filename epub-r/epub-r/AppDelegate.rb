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
        @viewer = EpubViewer.new(webView)
        @viewer.delegate = self
        @viewer.tmp_dir = @tmp_dir
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
            # One one file is allowed to be selected
            path = dialog.filenames.first
            destination_path.stringValue = path
            @book.cleanup if @book
            @book = Epub.new(path, @tmp_dir)
        
            @viewer.open @book
            
            # Get table of content
            @btn_toc.removeAllItems
            @btn_toc.addItemsWithTitles @book.toc_list.map{|a| a[:title]}
            
            # Set window title
            @window.setTitle(@book.title)
            
        end
    end
    
    private
    
    def toc_selection_changed(sender)
        selected_item = @btn_toc.titleOfSelectedItem
        @viewer.load_by_page @book.toc_list.find{|f| f[:title] == selected_item}[:src].split('#')[0]
    end
    
    def text_larger(sender)
        @viewer.larger_text sender
    end
    
    def text_smaller(sender)
        @viewer.smaller_text sender
    end    
    
    def prev_page(sender)
        @viewer.prev_page
    end
    
    def next_page(sender)
        @viewer.next_page
    end
end

