//
//  DragDetectionView.h
//  SpriteSheetUnpack
//
//  Created by Alan YU on 26/8/15.
//  Copyright (c) 2015 yDiva.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DragDetectionView : NSView

@property (nonatomic, copy) void (^filePathHandlerBlock) (NSArray *files);

@end
