//
//  main.m
//  epub-r
//
//  Created by Patrik Schlund on 1/20/13.
//  Copyright (c) 2013 Patrik Schlund. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <MacRuby/MacRuby.h>

int main(int argc, char *argv[])
{
    return macruby_main("rb_main.rb", argc, argv);
}
