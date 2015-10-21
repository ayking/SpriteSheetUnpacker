//
//  AppDelegate.m
//  SpriteSheetUnpack
//
//  Created by Alan YU on 26/8/15.
//  Copyright (c) 2015 yDiva.com. All rights reserved.
//

#import "AppDelegate.h"
#import "DragDetectionView.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet DragDetectionView *dragDetectView;
@property (weak) IBOutlet NSTextField *exportPathLabel;
@property (strong) dispatch_queue_t worker;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    self.worker = dispatch_queue_create("workerQueue", DISPATCH_QUEUE_CONCURRENT);
    
    __block AppDelegate *me = self;
    [self.dragDetectView setFilePathHandlerBlock:^(NSArray *files) {
        [me exportSprites:files];
    }];
    
    NSString *path = [[NSUserDefaults standardUserDefaults] valueForKey:@"ExportPath"];
    if (path) {
        self.exportPathLabel.stringValue = path;
    }
    
}

- (void)exportSprites:(NSArray *)files
{
    NSMutableDictionary *fileMap = [NSMutableDictionary dictionary];
    [files enumerateObjectsUsingBlock:^(NSString *path, NSUInteger idx, BOOL *stop) {
        
        NSString *lastPathComponent = [path lastPathComponent];
        NSString *ext = [lastPathComponent pathExtension];
        NSString *filename = [lastPathComponent stringByDeletingPathExtension];
        
        NSMutableDictionary *pair = fileMap[filename];
        if (pair == nil) {
            pair = [NSMutableDictionary dictionary];
            [fileMap setValue:pair forKey:filename];
        }
        
        if ([[ext lowercaseString] isEqualToString:@"plist"]) {
            pair[@"plist"] = path;
        } else if ([[ext lowercaseString] isEqualToString:@"png"]) {
            pair[@"png"] = path;
        }
        
    }];
    
    dispatch_async(self.worker, ^{
        
        [fileMap enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *paths, BOOL *stop) {
            [self splitPNGFromPlist:key path:paths];
        }];
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSAlert *alert = [[NSAlert alloc] init];
            
            [alert setMessageText:@"Done"];
            
            [alert runModal];
            
        });
        
    });
    
}

- (void)splitPNGFromPlist:(NSString *)name path:(NSDictionary *)paths {
    
    NSString *PListPath = paths[@"plist"];
    NSString *PNGPath = paths[@"png"];
    NSString *exportPath = [self.exportPathLabel.stringValue stringByAppendingPathComponent:name];
    NSFileManager  *fm = [NSFileManager defaultManager];
    
    [fm createDirectoryAtPath:exportPath withIntermediateDirectories:YES attributes:nil error:nil];
    
    if ([fm fileExistsAtPath:PListPath] && [fm fileExistsAtPath:PNGPath]) {
        
        NSArray *(^toList)(NSString *text) = ^(NSString *text) {
            return [[[text stringByReplacingOccurrencesOfString:@"{" withString:@""] stringByReplacingOccurrencesOfString:@"}" withString:@""] componentsSeparatedByString:@","];
        };
        
        CIImage *image = [CIImage imageWithContentsOfURL:[NSURL fileURLWithPath:PNGPath]];
        NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:PListPath];
        
        NSDictionary *frames = plist[@"frames"];
        
        [frames enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *frame, BOOL *stop) {
            
            NSArray *rectList = toList(frame[@"frame"]);
            BOOL rotated = [frame[@"rotated"] boolValue];
            NSArray *realRectList = toList(frame[@"sourceSize"]);
            NSArray *offsetList = toList(frame[@"offset"]);
            
            CGFloat width = [rectList[2] floatValue];
            if (rotated) {
                width = [rectList[3] floatValue];
            }
            
            CGFloat height = [rectList[3] floatValue];
            if (rotated) {
                height = [rectList[2] floatValue];
            }
            
            CGFloat offsetX = [offsetList[0] floatValue];
            if (rotated) {
                offsetX = [offsetList[1] floatValue];
            }
            
            CGFloat offsetY = [offsetList[1] floatValue];
            if (rotated) {
                offsetY = [offsetList[0] floatValue];
            }
            
            CGFloat realWidth = [realRectList[0] floatValue];
            if (rotated) {
                realWidth = [realRectList[1] floatValue];
            }
            
            CGFloat realHeight = [realRectList[1] floatValue];
            if (rotated) {
                realHeight = [realRectList[0] floatValue];
            }
            
            if (width > 0 && height > 0) {
                
                CIImage *bigImage = [image imageByCroppingToRect:CGRectMake(
                                                                            [rectList[0] floatValue],
                                                                            [image extent].size.height - [rectList[1] floatValue] - height,
                                                                            width,
                                                                            height
                                                                            )];
                
                CGPoint drawPoint = CGPointMake(
                                                (realWidth  - width) / 2 + offsetX,
                                                (realHeight - height) / 2 + offsetY
                                                );
                
                NSImage* resultImage = [[NSImage alloc] initWithSize:CGSizeMake(realWidth, realHeight)];
                
                [resultImage lockFocus];
                [bigImage drawAtPoint:drawPoint fromRect:[bigImage extent] operation:NSCompositeSourceOver fraction:1.0];
                [resultImage unlockFocus];
                
                if (rotated) {
                    
                    NSSize size = [resultImage size];
                    NSSize maxSize = NSMakeSize(size.height, size.width);
                    
                    NSAffineTransform *rot = [NSAffineTransform transform];
                    [rot rotateByDegrees:90];
                    
                    NSAffineTransform *center = [NSAffineTransform transform];
                    [center translateXBy:maxSize.width / 2. yBy:maxSize.height / 2.];
                    
                    [rot appendTransform:center];
                    
                    NSPoint corner = NSMakePoint(-size.width / 2., -size.height / 2.);
                    NSRect rect = NSMakeRect(0, 0, size.width, size.height);
                    
                    NSImage* rotatedImage = [[NSImage alloc] initWithSize:maxSize];
                    [rotatedImage lockFocus];
                    
                    [rot concat];
                    [resultImage drawAtPoint:corner fromRect:rect operation:NSCompositeCopy fraction:1.0];
                    
                    [rotatedImage unlockFocus];
                    
                    resultImage = rotatedImage;
                    
                }
                
                NSString *destPath = [exportPath stringByAppendingPathComponent:key];
                NSBitmapImageRep *bitmapRep = [NSBitmapImageRep imageRepWithData:[resultImage TIFFRepresentation]];
                
                [[bitmapRep representationUsingType:NSPNGFileType properties:nil] writeToFile:destPath atomically:YES];
                
            } else {
                NSLog(@"Skip for zero - %@", key);
            }
            
        }];
        
    } else {
        
        NSLog(@"Missing files - %@ vs %@" ,PListPath, PNGPath);
        
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (IBAction)exportPath:(NSButton *)sender {
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    
    [panel setAllowsMultipleSelection:NO];
    [panel setCanChooseDirectories:YES];
    [panel setCanChooseFiles:NO];
    
    if ([panel runModal] == NSFileHandlingPanelOKButton) {
        
        NSString *path = [[[panel URLs] lastObject] relativePath];
        [self.exportPathLabel setStringValue:path];
        
        [[NSUserDefaults standardUserDefaults] setObject:path forKey:@"ExportPath"];
    }
    
}

@end
