#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "../lib/GameLogic.h"

struct ESPBox {
    Vector3 pos;
    CGFloat width;
    CGFloat height;
};

@interface PMNDevOverlayView : UIView

- (instancetype)initWithFrame:(CGRect)frame;
- (void)hideMenu;
- (void)showMenu;
- (void)handlePan:(UIPanGestureRecognizer *)gesture;
- (void)centerMenu;

@end