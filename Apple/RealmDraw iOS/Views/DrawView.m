////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

#import "DrawView.h"
#import "DrawPath.h"
#import "SwatchesView.h"
#import "CanvasView.h"
#import "UIColor+Realm.h"
#import <Realm/Realm.h>

@interface DrawView ()

@property DrawPath *drawPath;
@property NSMutableArray<DrawPath *> *lastDrawPaths;
@property NSString *pathID;
@property RLMResults *paths;
@property RLMNotificationToken *notificationToken;
@property CanvasView *canvasView;
@property SwatchesView *swatchesView;
@property NSString *currentColorName;

@property UIButton *undo;

@end

@implementation DrawView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        typeof(self) __weak weakSelf = self;
        self.notificationToken = [[RLMRealm defaultRealm] addNotificationBlock:^(NSString *notification, RLMRealm *realm) {
        
            if (weakSelf.paths.count == 0) {
                [weakSelf.canvasView clearCanvas];
            }
            else {
                [weakSelf.canvasView setNeedsDisplay];
            }
        }];
        self.paths = [DrawPath allObjects];
        
        self.canvasView = [[CanvasView alloc] init];
        self.canvasView.paths = self.paths;
        [self addSubview:self.canvasView];
        
        self.swatchesView = [[SwatchesView alloc] initWithFrame:CGRectZero];
        [self addSubview:self.swatchesView];
        
        self.swatchesView.swatchColorChangedHandler = ^{
            weakSelf.currentColorName = weakSelf.swatchesView.selectedColor;
        };
        
        self.currentColorName = @"Black";
        [self becomeFirstResponder];

        self.undo = [[UIButton alloc] init];
        self.undo.translatesAutoresizingMaskIntoConstraints = false;
        [self.undo setTitleColor:UIColor.lightGrayColor forState:UIControlStateNormal];
        [self.undo setTitle:@"Undo" forState:UIControlStateNormal];
        [self.undo addTarget:self action:@selector(undoTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.undo];

        [[NSLayoutConstraint constraintWithItem:self.undo attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0f constant:-15.0f] setActive:true];
        [[NSLayoutConstraint constraintWithItem:self.undo attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0f constant:15.0f] setActive:true];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGSize boundsSize = self.bounds.size;
    CGFloat maxDimension = MAX(boundsSize.width, boundsSize.height);
    
    CGRect frame = self.canvasView.frame;
    frame.size.width = maxDimension;
    frame.size.height = maxDimension;
    frame.origin.x = (boundsSize.width - maxDimension) * 0.5f;
    self.canvasView.frame = CGRectIntegral(frame);
    
    frame = self.swatchesView.frame;
    frame.size.width = CGRectGetWidth(self.frame);
    frame.origin.y = CGRectGetHeight(self.frame) - CGRectGetHeight(frame) + 40;
    self.swatchesView.frame = frame;
    [self.swatchesView setNeedsLayout];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Create a draw path object
    self.drawPath = [[DrawPath alloc] init];
    self.drawPath.lineWidth = ([self.currentColorName isEqualToString:@"whiteColor"]) ? 20.0f : 4.0f;
    self.drawPath.color = self.currentColorName;
    
    // Create a draw point object
    CGPoint point = [[touches anyObject] locationInView:self.canvasView];
    DrawPoint *drawPoint = [[DrawPoint alloc] init];
    drawPoint.x = point.x;
    drawPoint.y = point.y;
    
    // Add the draw point to the draw path
    [self.drawPath.points addObject:drawPoint];
    
    // Add the draw path to the Realm
    RLMRealm *defaultRealm = [RLMRealm defaultRealm];
    [defaultRealm transactionWithBlock:^{
        [defaultRealm addObject:self.drawPath];
    }];
    
    [self.canvasView setNeedsDisplay];
}

- (void)addPoint:(CGPoint)point
{
    [[RLMRealm defaultRealm] transactionWithBlock:^{
        if (self.drawPath.isInvalidated) {
            self.drawPath = [[DrawPath alloc] init];
            self.drawPath.lineWidth = ([self.currentColorName isEqualToString:@"whiteColor"]) ? 20.0f : 4.0f;
            self.drawPath.color = self.currentColorName ?: @"blackColor";
            [[RLMRealm defaultRealm] addObject:self.drawPath];
        }

        DrawPoint *newPoint = [DrawPoint createInDefaultRealmWithValue:@[@(point.x), @(point.y)]];
        [self.drawPath.points addObject:newPoint];
    }];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint point = [[touches anyObject] locationInView:self.canvasView];
    [self addPoint:point];
    
    [self.canvasView setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint point = [[touches anyObject] locationInView:self.canvasView];
    [self addPoint:point];
    [[RLMRealm defaultRealm] transactionWithBlock:^{ self.drawPath.completed = YES; }];

    if (!self.lastDrawPaths) {
        self.lastDrawPaths = [[NSMutableArray<DrawPath *> alloc] init];
    }
    [self.lastDrawPaths insertObject:self.drawPath atIndex:0];

    if (self.lastDrawPaths.count > 0) {
        [self.undo setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    }

    self.drawPath = nil;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesEnded:touches withEvent:event];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion != UIEventSubtypeMotionShake) {
        return;
    }
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Reset Canvas?"
                                                                             message:@"This will clear the Realm database and reset the canvas. Are you sure you wish to proceed?"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    typeof(self) __weak weakSelf = self;
    [alertController addAction:[UIAlertAction actionWithTitle:@"Reset"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
        [[RLMRealm defaultRealm] transactionWithBlock:^{
            [[RLMRealm defaultRealm] deleteAllObjects];
        }];
        
       [weakSelf.canvasView clearCanvas];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:alertController animated:YES completion:nil];
}\

- (void)undoTapped:(id)sender
{
    if (self.lastDrawPaths.count > 0) {
        [[RLMRealm defaultRealm] transactionWithBlock:^{
            [[RLMRealm defaultRealm] deleteObject:self.lastDrawPaths[0]];
            [self.lastDrawPaths removeObjectAtIndex:0];

            if (self.lastDrawPaths.count == 0) {
                [self.undo setTitleColor:UIColor.lightGrayColor forState:UIControlStateNormal];
            }
        }];
    }
}

@end
