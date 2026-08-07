#import "esp.h"
#import "mahoa.h"
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h> 
#import <objc/runtime.h>
#include <sys/mman.h>
#include <string>
#include <vector>
#include <cmath>

uint64_t Moudule_Base = -1;

// --- PMNDEV ESP Config ---
static bool isBox = YES;
static bool isBone = YES;
static bool isHealth = YES;
static bool isName = YES;
static bool isDis = YES;

// --- PMNDEV Aimbot Config ---
static bool isAimbot = NO;
static float aimFov = 150.0f;
static float aimDistance = 200.0f;

@interface PMNDevOverlayView ()
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, strong) NSMutableArray<CALayer *> *drawingLayers;
- (void)renderESPToLayers:(NSMutableArray<CALayer *> *)layers;
@end

@implementation PMNDevOverlayView {
    UIView *menuContainer;
    UIView *floatingButton;
    CGPoint _initialTouchPoint;
    
    // PMNDEV Tab Views
    UIView *espTabContainer;
    UIView *aimTabContainer;
    UIView *settingTabContainer;

    UILabel *debugStatusLabel;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
        self.backgroundColor = [UIColor clearColor];
        self.drawingLayers = [NSMutableArray array];
        
        [self SetUpBase];
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateFrame)];
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];

        [self setupFloatingButton];
        [self setupMenuUI];
        [self layoutSubviews];
    }
    return self;
}

- (void)setupFloatingButton {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(40, 40, 56, 56);
    btn.backgroundColor = [UIColor colorWithRed:0.4 green:0.1 blue:0.8 alpha:0.9];
    btn.layer.cornerRadius = 28;
    btn.layer.borderWidth = 2.5;
    btn.layer.borderColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.8 alpha:1.0].CGColor;
    btn.clipsToBounds = YES;
    
    [btn setTitle:@"PMN" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor colorWithRed:0.0 green:1.0 blue:0.8 alpha:1.0] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:16];
    [btn addTarget:self action:@selector(showMenu) forControlEvents:UIControlEventTouchUpInside];
    
    UIPanGestureRecognizer *iconPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [btn addGestureRecognizer:iconPan];
    
    floatingButton = btn;
    [self addSubview:floatingButton];
}

- (void)addFeatureRowToView:(UIView *)view title:(NSString *)title yOffset:(CGFloat)y defaultValue:(BOOL)defaultVal action:(SEL)action {
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(15, y, 160, 30)];
    lbl.text = title;
    lbl.textColor = [UIColor whiteColor];
    lbl.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:14];
    [view addSubview:lbl];
    
    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(240, y, 51, 31)];
    sw.on = defaultVal;
    sw.onTintColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.6 alpha:1.0];
    [sw addTarget:self action:action forControlEvents:UIControlEventValueChanged];
    [view addSubview:sw];
}

- (void)setupMenuUI {
    CGFloat menuWidth = 560;
    CGFloat menuHeight = 340;
    
    menuContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, menuWidth, menuHeight)];
    menuContainer.backgroundColor = [UIColor colorWithRed:0.08 green:0.08 blue:0.12 alpha:0.96];
    menuContainer.layer.cornerRadius = 16;
    menuContainer.layer.borderColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.8 alpha:0.8].CGColor;
    menuContainer.layer.borderWidth = 2;
    menuContainer.clipsToBounds = YES;
    menuContainer.hidden = YES;
    [self addSubview:menuContainer];
    
    // Header Bar
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, menuWidth, 46)];
    headerView.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.18 alpha:1.0];
    [menuContainer addSubview:headerView];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 8, 300, 30)];
    titleLabel.text = @"PMNDEV CHEAT ENGINE";
    titleLabel.textColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.8 alpha:1.0];
    titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:18];
    [headerView addSubview:titleLabel];
    
    UILabel *subTitle = [[UILabel alloc] initWithFrame:CGRectMake(310, 14, 160, 20)];
    subTitle.text = @"v1.130.1 | By PMNDev";
    subTitle.textColor = [UIColor colorWithWhite:0.7 alpha:1.0];
    subTitle.font = [UIFont systemFontOfSize:11];
    [headerView addSubview:subTitle];
    
    // Close Button
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBtn.frame = CGRectMake(menuWidth - 40, 10, 26, 26);
    closeBtn.backgroundColor = [UIColor colorWithRed:0.9 green:0.2 blue:0.2 alpha:1.0];
    closeBtn.layer.cornerRadius = 13;
    [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [closeBtn addTarget:self action:@selector(hideMenu) forControlEvents:UIControlEventTouchUpInside];
    [headerView addSubview:closeBtn];
    
    UIPanGestureRecognizer *menuPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [headerView addGestureRecognizer:menuPan];
    
    // Sidebar Tabs (Left Side)
    UIView *sidebar = [[UIView alloc] initWithFrame:CGRectMake(12, 58, 110, 266)];
    sidebar.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.18 alpha:1.0];
    sidebar.layer.cornerRadius = 12;
    [menuContainer addSubview:sidebar];
    
    NSArray *tabs = @[@"🎯 ESP", @"🔥 AIMBOT", @"⚙️ LOGS"];
    for (int i = 0; i < tabs.count; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(6, 12 + (i * 55), 98, 42);
        btn.backgroundColor = (i == 0) ? [UIColor colorWithRed:0.0 green:0.6 blue:0.6 alpha:1.0] : [UIColor colorWithRed:0.18 green:0.18 blue:0.25 alpha:1.0];
        [btn setTitle:tabs[i] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        btn.layer.cornerRadius = 8;
        btn.titleLabel.font = [UIFont boldSystemFontOfSize:12];
        btn.tag = i;
        [btn addTarget:self action:@selector(tabChanged:) forControlEvents:UIControlEventTouchUpInside];
        [sidebar addSubview:btn];
    }

    // --- TAB 1: ESP TAB ---
    espTabContainer = [[UIView alloc] initWithFrame:CGRectMake(132, 58, 416, 266)];
    espTabContainer.backgroundColor = [UIColor clearColor];
    [menuContainer addSubview:espTabContainer];
    
    [self addFeatureRowToView:espTabContainer title:@"Box ESP" yOffset:10 defaultValue:isBox action:@selector(toggleBox:)];
    [self addFeatureRowToView:espTabContainer title:@"Skeleton / Bone" yOffset:50 defaultValue:isBone action:@selector(toggleBone:)];
    [self addFeatureRowToView:espTabContainer title:@"Health Bar" yOffset:90 defaultValue:isHealth action:@selector(toggleHealth:)];
    [self addFeatureRowToView:espTabContainer title:@"Player Name" yOffset:130 defaultValue:isName action:@selector(toggleName:)];
    [self addFeatureRowToView:espTabContainer title:@"Distance Meter" yOffset:170 defaultValue:isDis action:@selector(toggleDistance:)];

    // --- TAB 2: AIMBOT TAB ---
    aimTabContainer = [[UIView alloc] initWithFrame:CGRectMake(132, 58, 416, 266)];
    aimTabContainer.backgroundColor = [UIColor clearColor];
    aimTabContainer.hidden = YES;
    [menuContainer addSubview:aimTabContainer];
    
    [self addFeatureRowToView:aimTabContainer title:@"Auto Aimbot" yOffset:10 defaultValue:isAimbot action:@selector(toggleAimbot:)];
    
    UILabel *fovLbl = [[UILabel alloc] initWithFrame:CGRectMake(15, 60, 200, 20)];
    fovLbl.text = @"FOV Radius (10 - 500):";
    fovLbl.textColor = [UIColor whiteColor];
    fovLbl.font = [UIFont systemFontOfSize:13];
    [aimTabContainer addSubview:fovLbl];
    
    UISlider *fovSlider = [[UISlider alloc] initWithFrame:CGRectMake(15, 85, 380, 30)];
    fovSlider.minimumValue = 10;
    fovSlider.maximumValue = 500;
    fovSlider.value = aimFov;
    fovSlider.tintColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.8 alpha:1.0];
    [fovSlider addTarget:self action:@selector(fovChanged:) forControlEvents:UIControlEventValueChanged];
    [aimTabContainer addSubview:fovSlider];

    // --- TAB 3: SYSTEM LOGS & DEBUG TAB ---
    settingTabContainer = [[UIView alloc] initWithFrame:CGRectMake(132, 58, 416, 266)];
    settingTabContainer.backgroundColor = [UIColor colorWithRed:0.05 green:0.05 blue:0.08 alpha:1.0];
    settingTabContainer.layer.cornerRadius = 10;
    settingTabContainer.layer.borderColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.8 alpha:0.5].CGColor;
    settingTabContainer.layer.borderWidth = 1;
    settingTabContainer.hidden = YES;
    [menuContainer addSubview:settingTabContainer];
    
    UILabel *stTitle = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, 300, 24)];
    stTitle.text = @"PMNDEV SYSTEM LOGS & DEBUG";
    stTitle.textColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.8 alpha:1.0];
    stTitle.font = [UIFont boldSystemFontOfSize:14];
    [settingTabContainer addSubview:stTitle];
    
    UIView *stLine = [[UIView alloc] initWithFrame:CGRectMake(15, 38, 386, 1)];
    stLine.backgroundColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.8 alpha:0.5];
    [settingTabContainer addSubview:stLine];
    
    debugStatusLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 45, 386, 205)];
    debugStatusLabel.textColor = [UIColor colorWithRed:0.2 green:1.0 blue:0.4 alpha:1.0];
    debugStatusLabel.font = [UIFont fontWithName:@"Courier" size:12];
    debugStatusLabel.numberOfLines = 0;
    debugStatusLabel.text = @"[PMNDEV ENGINE INITIALIZING...]\nSearching Free Fire Process...";
    [settingTabContainer addSubview:debugStatusLabel];
    
    [self centerMenu];
}

- (void)tabChanged:(UIButton *)sender {
    espTabContainer.hidden = YES;
    aimTabContainer.hidden = YES;
    settingTabContainer.hidden = YES;
    
    for (UIView *sub in sender.superview.subviews) {
        if ([sub isKindOfClass:[UIButton class]]) {
            UIButton *btn = (UIButton *)sub;
            btn.backgroundColor = [UIColor colorWithRed:0.18 green:0.18 blue:0.25 alpha:1.0];
        }
    }
    sender.backgroundColor = [UIColor colorWithRed:0.0 green:0.6 blue:0.6 alpha:1.0];
    
    if (sender.tag == 0) espTabContainer.hidden = NO;
    if (sender.tag == 1) aimTabContainer.hidden = NO;
    if (sender.tag == 2) settingTabContainer.hidden = NO;
}

- (void)toggleBox:(UISwitch *)sw { isBox = sw.isOn; }
- (void)toggleBone:(UISwitch *)sw { isBone = sw.isOn; }
- (void)toggleHealth:(UISwitch *)sw { isHealth = sw.isOn; }
- (void)toggleName:(UISwitch *)sw { isName = sw.isOn; }
- (void)toggleDistance:(UISwitch *)sw { isDis = sw.isOn; }
- (void)toggleAimbot:(UISwitch *)sw { isAimbot = sw.isOn; }
- (void)fovChanged:(UISlider *)slider { aimFov = slider.value; }

- (void)hideMenu {
    menuContainer.hidden = YES;
    floatingButton.hidden = NO;
    [self bringSubviewToFront:floatingButton];
}

- (void)showMenu {
    menuContainer.hidden = NO;
    floatingButton.hidden = YES;
    [self bringSubviewToFront:menuContainer];
}

- (void)centerMenu {
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    menuContainer.center = CGPointMake(screenBounds.size.width / 2.0, screenBounds.size.height / 2.0);
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint touchPoint = [gesture locationInView:self];
    if (gesture.state == UIGestureRecognizerStateBegan) {
        _initialTouchPoint = touchPoint;
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        CGFloat deltaX = touchPoint.x - _initialTouchPoint.x;
        CGFloat deltaY = touchPoint.y - _initialTouchPoint.y;
        UIView *viewToMove = (gesture.view == floatingButton) ? floatingButton : menuContainer;
        viewToMove.center = CGPointMake(viewToMove.center.x + deltaX, viewToMove.center.y + deltaY);
        _initialTouchPoint = touchPoint;
    }
}

- (void)SetUpBase {
    if (Moudule_Base == -1 || Moudule_Base == 0) {
        pid_t pid = GetGameProcesspid((char*)"freefireth");
        if (pid == -1) pid = GetGameProcesspid((char*)"freefire");
        if (pid == -1) pid = GetGameProcesspid((char*)"FreeFire");
        if (pid != -1) {
            Moudule_Base = (uint64_t)GetGameModule_Base((char*)"freefireth");
            if (Moudule_Base == 0) Moudule_Base = (uint64_t)GetGameModule_Base((char*)"freefire");
            if (Moudule_Base == 0) Moudule_Base = (uint64_t)GetGameModule_Base((char*)"FreeFire");
        }
    }
}

- (void)updateFrame {
    [self SetUpBase];
    
    pid_t pid = GetGameProcesspid((char*)"freefireth");
    if (pid == -1) pid = GetGameProcesspid((char*)"freefire");
    if (pid == -1) pid = GetGameProcesspid((char*)"FreeFire");
    if (pid == -1) pid = GetGameProcesspid((char*)"FF");
    
    if (debugStatusLabel) {
        NSString *connStr = (pid != -1 && Moudule_Base != 0 && Moudule_Base != -1) ? @"CONNECTED YES (ONLINE)" : @"SEARCHING GAME PROCESS...";
        debugStatusLabel.text = [NSString stringWithFormat:
            @"=== PMNDEV ENGINE SYSTEM STATUS ===\n"
            @"Developer: PMNDev (Tris)\n"
            @"Game Status: %@\n"
            @"Process PID: %d\n"
            @"Module Base: 0x%llX\n"
            @"GameFacade Offset: 0xC012848\n\n"
            @"=== PMNDEV ACTIVE FEATURES ===\n"
            @"Box: %d | Bone: %d | Health: %d\n"
            @"Name: %d | Dist: %d | Aimbot: %d\n"
            @"Aim FOV: %.0f | Target Bone: Head (0x630)",
            connStr, pid, Moudule_Base,
            isBox, isBone, isHealth, isName, isDis, isAimbot, aimFov];
    }
    
    for (CALayer *layer in self.drawingLayers) {
        [layer removeFromSuperlayer];
    }
    [self.drawingLayers removeAllObjects];
    
    if (pid != -1 && Moudule_Base != 0 && Moudule_Base != -1) {
        [self renderESPToLayers:self.drawingLayers];
        for (CALayer *layer in self.drawingLayers) {
            [self.layer addSublayer:layer];
        }
    }
}

- (void)renderESPToLayers:(NSMutableArray<CALayer *> *)layers {
    if (isAimbot) {
        CAShapeLayer *fovLayer = [CAShapeLayer layer];
        CGPoint screenCenter = CGPointMake(self.bounds.size.width / 2.0, self.bounds.size.height / 2.0);
        UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:screenCenter radius:aimFov startAngle:0 endAngle:2 * M_PI clockwise:YES];
        fovLayer.path = path.CGPath;
        fovLayer.strokeColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.8 alpha:0.8].CGColor;
        fovLayer.fillColor = [UIColor clearColor].CGColor;
        fovLayer.lineWidth = 1.5;
        [layers addObject:fovLayer];
    }

    if (Moudule_Base == -1 || Moudule_Base == 0) return;
    
    uint64_t matchGame = getMatchGame(Moudule_Base);
    if (!isVaildPtr(matchGame)) return;
    
    uint64_t localPlayer = getLocalPlayer(matchGame);
    if (!isVaildPtr(localPlayer)) return;
    
    uint64_t myPawnObject = getPawnObject(localPlayer);
    if (!isVaildPtr(myPawnObject)) return;
    
    Vector3 myLocation = getPositionExt(getHead(myPawnObject));

    std::vector<uint64_t> players = getPlayerList(matchGame);
    
    float bestFov = aimFov;
    uint64_t bestTarget = 0;
    
    for (uint64_t player : players) {
        if (!isVaildPtr(player) || player == myPawnObject) continue;
        
        if (getIsDie(player)) continue;
        if (isTeammate(myPawnObject, player)) continue;
        
        Vector3 headPos = getPositionExt(getHead(player));
        Vector3 hipPos = getPositionExt(getHip(player));
        
        if (headPos.x == 0 && headPos.y == 0 && headPos.z == 0) continue;
        
        Vector3 headScreen = WorldToScreen(headPos);
        Vector3 hipScreen = WorldToScreen(hipPos);
        
        if (headScreen.z <= 0) continue;
        
        float dis = Vector3::Distance(myLocation, headPos);
        if (dis > aimDistance) continue;
        
        float boxHeight = std::abs(hipScreen.y - headScreen.y) * 2.2f;
        if (boxHeight < 10) boxHeight = 40;
        float boxWidth = boxHeight * 0.55f;
        float x = headScreen.x - (boxWidth / 2.0f);
        float y = headScreen.y - (boxHeight * 0.15f);
        
        if (isBox) {
            CAShapeLayer *boxLayer = [CAShapeLayer layer];
            UIBezierPath *boxPath = [UIBezierPath bezierPathWithRect:CGRectMake(x, y, boxWidth, boxHeight)];
            boxLayer.path = boxPath.CGPath;
            boxLayer.strokeColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.8 alpha:1.0].CGColor;
            boxLayer.fillColor = [UIColor clearColor].CGColor;
            boxLayer.lineWidth = 1.5;
            [layers addObject:boxLayer];
        }
        
        if (isName) {
            CATextLayer *nameLayer = [CATextLayer layer];
            nameLayer.string = @"[PMNDEV ENEMY]";
            nameLayer.fontSize = 10;
            nameLayer.frame = CGRectMake(x - 20, y - 16, boxWidth + 40, 14);
            nameLayer.alignmentMode = kCAAlignmentCenter;
            nameLayer.foregroundColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.8 alpha:1.0].CGColor;
            [layers addObject:nameLayer];
        }
        
        if (isDis) {
            CATextLayer *distLayer = [CATextLayer layer];
            distLayer.string = [NSString stringWithFormat:@"[%.0fm]", dis];
            distLayer.fontSize = 9;
            distLayer.frame = CGRectMake(x - 10, y + boxHeight + 2, boxWidth + 20, 12);
            distLayer.alignmentMode = kCAAlignmentCenter;
            distLayer.foregroundColor = [UIColor whiteColor].CGColor;
            [layers addObject:distLayer];
        }
    }
}

@end

// --- OVERRIDE ANY OLD MENU AND INJECT PMNDEV OVERLAY ---
@interface MenuView : UIView
@end
@implementation MenuView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.hidden = YES;
        self.alpha = 0.0;
    }
    return self;
}
@end

__attribute__((constructor))
static void initializePMNDevOverlay(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        static UIWindow *gPMNWindow = nil;
        CGRect screenFrame = [UIScreen mainScreen].bounds;
        gPMNWindow = [[UIWindow alloc] initWithFrame:screenFrame];
        gPMNWindow.windowLevel = UIWindowLevelStatusBar + 2000;
        gPMNWindow.backgroundColor = [UIColor clearColor];
        gPMNWindow.userInteractionEnabled = YES;
        
        PMNDevOverlayView *pmnOverlay = [[PMNDevOverlayView alloc] initWithFrame:screenFrame];
        UIViewController *vc = [[UIViewController alloc] init];
        vc.view = pmnOverlay;
        gPMNWindow.rootViewController = vc;
        gPMNWindow.hidden = NO;
    });
}