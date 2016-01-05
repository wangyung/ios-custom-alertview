//
//  CustomIOSAlertView.m
//  CustomIOSAlertView
//
//  Created by Richard on 20/09/2013.
//  Copyright (c) 2013-2015 Wimagguc.
//
//  Lincesed under The MIT License (MIT)
//  http://opensource.org/licenses/MIT
//

#import "CustomIOSAlertView.h"
#import "HoleyView.h"
#import <QuartzCore/QuartzCore.h>

const static CGFloat kCustomIOSAlertViewDefaultButtonHeight       = 50;
const static CGFloat kCustomIOSAlertViewDefaultButtonSpacerHeight = 1;
const static CGFloat kCustomIOSAlertViewCornerRadius              = 7;
const static CGFloat kCustomIOS7MotionEffectExtent                = 10.0;

@implementation CustomIOSAlertView

CGFloat buttonHeight = 0;
CGFloat buttonSpacerHeight = 1.0;

NSMutableArray *styleHandlers;
HoleyView *holeyView;
UIColor *dimColor;
UIColor *seperatorColor;

@synthesize parentView, containerView, dialogView, onButtonTouchUpInside;
@synthesize delegate;
@synthesize buttonTitles;
@synthesize useMotionEffects;
@synthesize useBlurEffect;

- (id)initWithParentView: (UIView *)_parentView
{
    self = [self init];
    if (_parentView) {
        self.frame = _parentView.frame;
        self.parentView = _parentView;
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        
        useMotionEffects = false;
        useBlurEffect = true;
        
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
        
        styleHandlers = [[NSMutableArray alloc] init];
        buttonTitles = [[NSMutableArray alloc] init];
        dimColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];
    }
    return self;
}

// Create the dialog view, and animate opening the dialog
- (void)show
{
    dialogView = [self createContainerView];
    
    dialogView.layer.shouldRasterize = YES;
    dialogView.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    
    self.layer.shouldRasterize = YES;
    self.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    
#if (defined(__IPHONE_7_0))
    if (useMotionEffects) {
        [self applyMotionEffects];
    }
#endif
    self.backgroundColor = [UIColor clearColor];
    
    holeyView = [[HoleyView alloc] initWithHoleRect:dialogView.frame parentFrame:self.frame];
    holeyView.dimColor = dimColor;
    
    [self addSubview:dialogView];
    
    // Can be attached to a view or to the top most window
    // Attached to a view:
    if (parentView != NULL) {
        [parentView addSubview:self];
        
        // Attached to the top most window
    } else {
        
        // On iOS7, calculate with orientation
        if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1) {
            
            UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
            switch (interfaceOrientation) {
                case UIInterfaceOrientationLandscapeLeft:
                    self.transform = CGAffineTransformMakeRotation(M_PI * 270.0 / 180.0);
                    break;
                    
                case UIInterfaceOrientationLandscapeRight:
                    self.transform = CGAffineTransformMakeRotation(M_PI * 90.0 / 180.0);
                    break;
                    
                case UIInterfaceOrientationPortraitUpsideDown:
                    self.transform = CGAffineTransformMakeRotation(M_PI * 180.0 / 180.0);
                    break;
                    
                default:
                    break;
            }
            
            [self setFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
            
            // On iOS8, just place the dialog in the middle
        } else {
            
            CGSize screenSize = [self countScreenSize];
            CGSize dialogSize = [self countDialogSize];
            CGSize keyboardSize = CGSizeMake(0, 0);
            
            dialogView.frame = CGRectMake((screenSize.width - dialogSize.width) / 2, (screenSize.height - keyboardSize.height - dialogSize.height) / 2, dialogSize.width, dialogSize.height);
            
        }
        
        [[[UIApplication sharedApplication] keyWindow] addSubview:self];
    }
    
    dialogView.layer.opacity = 1.0f;
    dialogView.layer.transform = CATransform3DMakeScale(1.3f, 1.3f, 1.0f);
    self.backgroundColor = [UIColor clearColor];
    
    [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         
                         dialogView.layer.transform = CATransform3DMakeScale(1, 1, 1);
                         self.backgroundColor = dimColor;
                     }
                     completion:^(BOOL finished){
                         self.backgroundColor = [UIColor clearColor];
                         dialogView.backgroundColor = [UIColor clearColor];
                         holeyView.holeFrame = dialogView.frame;
                         [self addSubview:holeyView];
                     }
     ];
    
}

// Button has been touched
- (IBAction)dialogButtonTouchUpInside:(id)sender
{
    if (delegate != NULL) {
        [delegate dialogButtonTouchUpInside:self clickedButtonAtIndex:[sender tag]];
    }
    
    if (onButtonTouchUpInside != NULL) {
        onButtonTouchUpInside(self, (int)[sender tag]);
    }
    
    [self close];
}

// Default button behaviour
- (void)dialogButtonTouchUpInside: (CustomIOSAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self close];
}

// Dialog close animation then cleaning and removing the view from the parent
- (void)close
{
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1) {
        CGFloat startRotation = [[dialogView valueForKeyPath:@"layer.transform.rotation.z"] floatValue];
        CATransform3D rotation = CATransform3DMakeRotation(-startRotation + M_PI * 270.0 / 180.0, 0.0f, 0.0f, 0.0f);
        
        dialogView.layer.transform = CATransform3DConcat(rotation, CATransform3DMakeScale(1, 1, 1));
    }
    
    holeyView.layer.opacity = 0.0f;
    for (UIView *v in [self subviews]) {
        [v removeFromSuperview];
    }
    self.backgroundColor = dimColor;
    
    [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.backgroundColor = [UIColor clearColor];
                     }
                     completion:^(BOOL finished) {
                         [self removeFromSuperview];
                     }
     ];
}

- (void)setSubView: (UIView *)subView
{
    containerView = subView;
}

// Creates the container view here: create the dialog, then add the custom content and buttons
- (UIView *)createContainerView
{
    if (containerView == NULL) {
        containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 150)];
    }
    
    CGSize screenSize = [self countScreenSize];
    CGSize dialogSize = [self countDialogSize];
    
    // For the black background
    [self setFrame:CGRectMake(0, 0, screenSize.width, screenSize.height)];
    
    // This is the dialog's container; we attach the custom content and the buttons to this one
    
    UIBlurEffect *blurEffect = nil;
    CGFloat shadowOpacity = 1.0;
    UIColor *containerBackgroundColor = [UIColor colorWithRed:220.0/255.0 green:220.0/255.0 blue:220.0/255.0 alpha:1.0];
    if (self.useBlurEffect) {
        blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        shadowOpacity = 0.1f;
        containerBackgroundColor = [UIColor clearColor];
    }
    
    UIVisualEffectView *dialogContainer = [[UIVisualEffectView alloc] initWithEffect: blurEffect];
    [dialogContainer setFrame: CGRectMake((screenSize.width - dialogSize.width) / 2, (screenSize.height - dialogSize.height) / 2, dialogSize.width, dialogSize.height)];
    
    CGFloat cornerRadius = kCustomIOSAlertViewCornerRadius;
    dialogContainer.layer.cornerRadius = cornerRadius;
    dialogContainer.clipsToBounds = YES;
    
    dialogContainer.contentView.layer.cornerRadius = cornerRadius;
    dialogContainer.contentView.layer.shadowRadius = cornerRadius + 5;
    dialogContainer.contentView.layer.shadowOpacity = shadowOpacity;
    dialogContainer.contentView.layer.shadowOffset = CGSizeMake(0 - (cornerRadius+5)/2, 0 - (cornerRadius+5)/2);
    dialogContainer.contentView.layer.shadowColor = [UIColor blackColor].CGColor;
    dialogContainer.contentView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:dialogContainer.bounds cornerRadius:dialogContainer.layer.cornerRadius].CGPath;
    dialogContainer.contentView.backgroundColor = containerBackgroundColor;
    
    // There is a line above the button
    seperatorColor = [UIColor colorWithRed:198.0/255.0 green:198.0/255.0 blue:198.0/255.0 alpha:1.0f];
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, dialogContainer.bounds.size.height - buttonHeight - buttonSpacerHeight, dialogContainer.bounds.size.width, buttonSpacerHeight)];
    lineView.backgroundColor = seperatorColor;
    [dialogContainer.contentView addSubview:lineView];
    
    // There are also vertical lines between the buttons
    if (buttonTitles.count > 1) {
        for (int i = 1; i < buttonTitles.count; i++) {
            UIView *verticalLineView = [[UIView alloc] initWithFrame:CGRectMake(dialogContainer.bounds.size.width / buttonTitles.count * i, dialogContainer.bounds.size.height - buttonHeight - buttonSpacerHeight, buttonSpacerHeight, buttonHeight)];
            verticalLineView.backgroundColor = seperatorColor;
            [dialogContainer addSubview:verticalLineView];
        }
    }
    
    // Add the custom container if there is any
    [dialogContainer.contentView addSubview:containerView];
    dialogContainer.backgroundColor = [UIColor whiteColor];
    
    // Add the buttons too
    [self addButtonsToView:dialogContainer.contentView];
    
    return dialogContainer;
}

// Helper function: add buttons to container
- (void)addButtonsToView: (UIView *)container
{
    if ([buttonTitles count] == 0) {
        [buttonTitles addObject:@"Close"];
    }
    
    CGFloat buttonWidth = container.bounds.size.width / [buttonTitles count];
    
    NSUInteger styleHandlersCount = [styleHandlers count];
    for (int i=0; i<[buttonTitles count]; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setFrame:CGRectMake(i * buttonWidth, container.bounds.size.height - buttonHeight, buttonWidth, buttonHeight)];
        [button addTarget:self action:@selector(dialogButtonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
        [button setTag:i];
        [button setTitle:[buttonTitles objectAtIndex:i] forState:UIControlStateNormal];
        
        if (i < styleHandlersCount && styleHandlers[i] != nil) {
            ButtonStyleHandler handler = (ButtonStyleHandler) styleHandlers[i];
            handler(button);
        } else {
            [button setTitleColor:[UIColor colorWithRed:0.0f green:0.5f blue:1.0f alpha:1.0f] forState:UIControlStateNormal];
            [button setTitleColor:[UIColor colorWithRed:0.2f green:0.2f blue:0.2f alpha:0.5f]  forState:UIControlStateHighlighted];
            //            [button.titleLabel setFont:[UIFont boldSystemFontOfSize:14.0f]];
        }
        
        [button.layer setCornerRadius:kCustomIOSAlertViewCornerRadius];
        
        [container addSubview:button];
    }
}

// Helper function: count and return the dialog's size
- (CGSize)countDialogSize
{
    CGFloat dialogWidth = containerView.frame.size.width;
    CGFloat dialogHeight = containerView.frame.size.height + buttonHeight + buttonSpacerHeight;
    
    return CGSizeMake(dialogWidth, dialogHeight);
}

// Helper function: count and return the screen's size
- (CGSize)countScreenSize
{
    if (buttonTitles!=NULL && [buttonTitles count] > 0) {
        buttonHeight       = kCustomIOSAlertViewDefaultButtonHeight;
        buttonSpacerHeight = kCustomIOSAlertViewDefaultButtonSpacerHeight;
    } else {
        buttonHeight = 0;
        buttonSpacerHeight = 0;
    }
    
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    
    // On iOS7, screen width and height doesn't automatically follow orientation
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1) {
        UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
            CGFloat tmp = screenWidth;
            screenWidth = screenHeight;
            screenHeight = tmp;
        }
    }
    
    return CGSizeMake(screenWidth, screenHeight);
}

#if (defined(__IPHONE_7_0))
// Add motion effects
- (void)applyMotionEffects {
    
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        return;
    }
    
    UIInterpolatingMotionEffect *horizontalEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x"
                                                                                                    type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    horizontalEffect.minimumRelativeValue = @(-kCustomIOS7MotionEffectExtent);
    horizontalEffect.maximumRelativeValue = @( kCustomIOS7MotionEffectExtent);
    
    UIInterpolatingMotionEffect *verticalEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y"
                                                                                                  type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    verticalEffect.minimumRelativeValue = @(-kCustomIOS7MotionEffectExtent);
    verticalEffect.maximumRelativeValue = @( kCustomIOS7MotionEffectExtent);
    
    UIMotionEffectGroup *motionEffectGroup = [[UIMotionEffectGroup alloc] init];
    motionEffectGroup.motionEffects = @[horizontalEffect, verticalEffect];
    
    [dialogView addMotionEffect:motionEffectGroup];
}
#endif

- (void)dealloc
{
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
}

// Rotation changed, on iOS7
- (void)changeOrientationForIOS7 {
    
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    CGFloat startRotation = [[self valueForKeyPath:@"layer.transform.rotation.z"] floatValue];
    CGAffineTransform rotation;
    
    switch (interfaceOrientation) {
        case UIInterfaceOrientationLandscapeLeft:
            rotation = CGAffineTransformMakeRotation(-startRotation + M_PI * 270.0 / 180.0);
            break;
            
        case UIInterfaceOrientationLandscapeRight:
            rotation = CGAffineTransformMakeRotation(-startRotation + M_PI * 90.0 / 180.0);
            break;
            
        case UIInterfaceOrientationPortraitUpsideDown:
            rotation = CGAffineTransformMakeRotation(-startRotation + M_PI * 180.0 / 180.0);
            break;
            
        default:
            rotation = CGAffineTransformMakeRotation(-startRotation + 0.0);
            break;
    }
    
    [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionTransitionNone
                     animations:^{
                         dialogView.transform = rotation;
                         
                     }
                     completion:nil
     ];
    
}

// Rotation changed, on iOS8
- (void)changeOrientationForIOS8: (NSNotification *)notification {
    
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    
    [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionTransitionNone
                     animations:^{
                         CGSize dialogSize = [self countDialogSize];
                         CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
                         self.frame = CGRectMake(0, 0, screenWidth, screenHeight);
                         dialogView.frame = CGRectMake((screenWidth - dialogSize.width) / 2, (screenHeight - keyboardSize.height - dialogSize.height) / 2, dialogSize.width, dialogSize.height);
                     }
                     completion:nil
     ];
    
    
}

// Handle device orientation changes
- (void)deviceOrientationDidChange: (NSNotification *)notification
{
    // If dialog is attached to the parent view, it probably wants to handle the orientation change itself
    if (parentView != NULL) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1) {
            [self changeOrientationForIOS7];
        } else {
            [self changeOrientationForIOS8:notification];
        }
    });
}

// Handle keyboard show/hide changes
- (void)keyboardWillShow: (NSNotification *)notification
{
    CGSize screenSize = [self countScreenSize];
    CGSize dialogSize = [self countDialogSize];
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UIInterfaceOrientationIsLandscape(interfaceOrientation) && NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1) {
        CGFloat tmp = keyboardSize.height;
        keyboardSize.height = keyboardSize.width;
        keyboardSize.width = tmp;
    }
    
    [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionTransitionNone
                     animations:^{
                         dialogView.frame = CGRectMake((screenSize.width - dialogSize.width) / 2, (screenSize.height - keyboardSize.height - dialogSize.height) / 2, dialogSize.width, dialogSize.height);
                     }
                     completion:nil
     ];
}

- (void)keyboardWillHide: (NSNotification *)notification
{
    CGSize screenSize = [self countScreenSize];
    CGSize dialogSize = [self countDialogSize];
    
    [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionTransitionNone
                     animations:^{
                         dialogView.frame = CGRectMake((screenSize.width - dialogSize.width) / 2, (screenSize.height - dialogSize.height) / 2, dialogSize.width, dialogSize.height);
                     }
                     completion:nil
     ];
}

- (void)addButtonWithTitle:(NSString *)title styleHandler: (ButtonStyleHandler) styleHandler {
    [buttonTitles addObject:title];
    [styleHandlers addObject:styleHandler];
}

@end
