#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

static dispatch_source_t clickTimer = nil;
static CGPoint targetPoint = CGPointMake(350, 700); 

// دالة حديثة لجلب النافذة بدون أخطاء التحذير
UIWindow *getKeyWindow() {
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                for (UIWindow *window in ((UIWindowScene *)scene).windows) {
                    if (window.isKeyWindow) return window;
                }
            }
        }
    }
    return [UIApplication sharedApplication].keyWindow;
}

void SimulateTouch(CGPoint point) {
    UIWindow *window = getKeyWindow();
    if (!window) return;
    
    UITouch *touch = [[UITouch alloc] init];
    [touch setValue:@(UITouchPhaseBegan) forKey:@"phase"];
    [touch setValue:window forKey:@"window"];
    [touch setValue:@(point.x) forKey:@"locationInWindow.x"];
    [touch setValue:@(point.y) forKey:@"locationInWindow.y"];
    
    UIEvent *event = [[UIEvent alloc] init];
    [window sendEvent:event];
    
    [touch setValue:@(UITouchPhaseEnded) forKey:@"phase"];
    [window sendEvent:event];
}

@interface AxiomClicker : NSObject <UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIView *targetDot;
+ (instancetype)sharedInstance;
@end

@implementation AxiomClicker

+ (instancetype)sharedInstance {
    static AxiomClicker *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ sharedInstance = [[self alloc] init]; });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) { dispatch_async(dispatch_get_main_queue(), ^{ [self setupUI]; }); }
    return self;
}

- (void)setupUI {
    UIWindow *keyWindow = getKeyWindow();
    if (!keyWindow) return;

    UIButton *floatButton = [UIButton buttonWithType:UIButtonTypeCustom];
    floatButton.frame = CGRectMake(50, 100, 50, 50);
    floatButton.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.85];
    [floatButton setTitle:@"⚡" forState:UIControlStateNormal];
    [floatButton setTitleColor:[UIColor yellowColor] forState:UIControlStateNormal];
    floatButton.titleLabel.font = [UIFont boldSystemFontOfSize:24];
    floatButton.layer.cornerRadius = 25;
    [floatButton addTarget:self action:@selector(toggleMenu:) forControlEvents:UIControlEventTouchUpInside];
    [keyWindow addSubview:floatButton];
    
    self.targetDot = [[UIView alloc] initWithFrame:CGRectMake(targetPoint.x - 15, targetPoint.y - 15, 30, 30)];
    self.targetDot.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.5];
    self.targetDot.layer.cornerRadius = 15;
    self.targetDot.userInteractionEnabled = YES;
    self.targetDot.hidden = YES;
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self.targetDot addGestureRecognizer:pan];
    [keyWindow addSubview:self.targetDot];
}

- (void)handlePan:(UIPanGestureRecognizer *)pan {
    CGPoint translation = [pan translationInView:pan.view.superview];
    pan.view.center = CGPointMake(pan.view.center.x + translation.x, pan.view.center.y + translation.y);
    [pan setTranslation:CGPointZero inView:pan.view.superview];
    targetPoint = pan.view.center;
}

- (void)toggleMenu:(UIButton *)sender {
    UIWindow *keyWindow = getKeyWindow();
    UIView *existingMenu = [keyWindow viewWithTag:888899];
    if (existingMenu) { [existingMenu removeFromSuperview]; return; }

    UIView *menuView = [[UIView alloc] initWithFrame:CGRectMake(60, 70, 280, 150)];
    menuView.tag = 888899;
    menuView.backgroundColor = [UIColor colorWithRed:0.07 green:0.07 blue:0.07 alpha:0.95];
    menuView.layer.cornerRadius = 14;
    menuView.layer.borderWidth = 1.5;
    menuView.layer.borderColor = [UIColor colorWithRed:0.25 green:0.25 blue:0.25 alpha:1.0].CGColor;
    menuView.userInteractionEnabled = YES;

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 12, 250, 30)];
    titleLabel.text = @"AXIOM FAST CLICKER";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:13];
    [menuView addSubview:titleLabel];

    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBtn.frame = CGRectMake(235, 12, 30, 30);
    [closeBtn setTitle:@"X" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [closeBtn addTarget:menuView action:@selector(removeFromSuperview) forControlEvents:UIControlEventTouchUpInside];
    [menuView addSubview:closeBtn];

    UISwitch *autoClicker = [[UISwitch alloc] initWithFrame:CGRectMake(15, 60, 0, 0)];
    [autoClicker addTarget:self action:@selector(toggleAutoClick:) forControlEvents:UIControlEventValueChanged];
    [menuView addSubview:autoClicker];
    
    UILabel *clickLbl = [[UILabel alloc] initWithFrame:CGRectMake(70, 60, 200, 30)];
    clickLbl.text = @"تكبيس سريع جداً (ON/OFF)";
    clickLbl.textColor = [UIColor whiteColor];
    [menuView addSubview:clickLbl];
    
    UILabel *hintLbl = [[UILabel alloc] initWithFrame:CGRectMake(15, 105, 250, 30)];
    hintLbl.text = @"اسحب النقطة الحمراء لمكان الزر";
    hintLbl.textColor = [UIColor lightGrayColor];
    hintLbl.font = [UIFont systemFontOfSize:11];
    [menuView addSubview:hintLbl];

    [keyWindow addSubview:menuView];
}

- (void)toggleAutoClick:(UISwitch *)sender {
    self.targetDot.hidden = !sender.isOn;
    
    if (sender.isOn) {
        clickTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        dispatch_source_set_timer(clickTimer, DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC, 0); 
        dispatch_source_set_event_handler(clickTimer, ^{
            SimulateTouch(targetPoint);
        });
        dispatch_resume(clickTimer);
    } else {
        if (clickTimer) { 
            dispatch_source_cancel(clickTimer); 
            clickTimer = nil; 
        }
    }
}
@end

%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [AxiomClicker sharedInstance];
    });
}
