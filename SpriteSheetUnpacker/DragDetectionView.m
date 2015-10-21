//
//  DragDetectionView.m
//  SpriteSheetUnpack
//
//  Created by Alan YU on 26/8/15.
//  Copyright (c) 2015 yDiva.com. All rights reserved.
//

#import "DragDetectionView.h"

@interface DragDetectionView()

@end

@implementation DragDetectionView

- (void)commonInit {
    [self registerForDraggedTypes:@[NSFilenamesPboardType]];
    
    NSInteger opts = (NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways);
    NSTrackingArea *trackingArea = [ [NSTrackingArea alloc] initWithRect:[self bounds]
                                                                 options:opts
                                                                   owner:self
                                                                userInfo:nil];
    [self addTrackingArea:trackingArea];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self commonInit];
}

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
        return self;
    }
    return self;
}

- (NSDragOperation)draggingEntered:(id )sender
{
    return NSDragOperationCopy;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
    return NSDragOperationCopy;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{

}

- (BOOL)prepareForDragOperation:(id )sender {
    return YES;
}

- (BOOL)performDragOperation:(id )sender {
    
    NSPasteboard *pasteboard = [sender draggingPasteboard];
    
    NSString *desiredType = [pasteboard availableTypeFromArray:@[NSFilenamesPboardType]];
    
    if ([desiredType isEqualToString:NSFilenamesPboardType]) {
        
        NSArray *fileNamesList = [pasteboard propertyListForType:NSFilenamesPboardType];
        
        if (self.filePathHandlerBlock) {
            self.filePathHandlerBlock(fileNamesList);
        }
        
        return YES;
        
    }
    
    return NO;
    
}

- (void)concludeDragOperation:(id )sender {
    
}

- (void)drawRect:(NSRect)dirtyRect {
    // Fill in background Color
    CGContextRef context = (CGContextRef) [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSetRGBFillColor(context, 0.227,0.251,0.337,0.8);
    CGContextFillRect(context, NSRectToCGRect(dirtyRect));
}

@end
