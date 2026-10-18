#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <substrate.h>

// تعريفات محرك Lua الخاص بروبلوكس
typedef struct lua_State lua_State;
typedef int (*luaL_loadstring_t)(lua_State *L, const char *s);
typedef int (*lua_pcall_t)(lua_State *L, int nargs, int nresults, int errfunc);

static lua_State *g_L = NULL; // هنا نخزن محرك اللعبة عشان ننفذ أوامرنا
static lua_pcall_t orig_lua_pcall = NULL;

// دالة حقن السكربت داخل اللعبة
void ExecuteRobloxLua(NSString *script) {
    if (!g_L) {
        NSLog(@"[Axiom] محرك Lua مو جاهز، انتظر اللعبة تحمل.");
        return;
    }
    if (orig_lua_pcall && orig_lua_pcall(g_L, 0, 0, 0) == 0) {
        if (luaL_loadstring_t(g_L, [script UTF8String]) == 0) {
            orig_lua_pcall(g_L, 0, 0, 0);
        }
    }
}

// خطاف (Hook) لسرقة المحرك أول ما اللعبة تشغل سكربت
static int (*orig_luaL_loadstring)(lua_State *L, const char *s);
int new_luaL_loadstring(lua_State *L, const char *s) {
    g_L = L; // سرقنا المحرك هنا!
    return orig_luaL_loadstring(L, s);
}

// ================= الواجهة (UI) =================
@interface AxiomDeltaMenu : NSObject
+ (instancetype)sharedInstance;
@end

@implementation AxiomDeltaMenu
+ (instancetype)sharedInstance {
    static AxiomDeltaMenu *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setupUI];
        });
    }
    return self;
}

- (void)setupUI {
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    if (!keyWindow) return;

    UIButton *floatButton = [UIButton buttonWithType:UIButtonTypeCustom];
    floatButton.frame = CGRectMake(50, 100, 50, 50);
    floatButton.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.85];
    [floatButton setTitle:@"Δ" forState:UIControlStateNormal];
    [floatButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    floatButton.titleLabel.font = [UIFont boldSystemFontOfSize:24];
    floatButton.layer.cornerRadius = 25;
    [floatButton addTarget:self action:@selector(toggleMenu:) forControlEvents:UIControlEventTouchUpInside];
    [keyWindow addSubview:floatButton];
}

- (void)toggleMenu:(UIButton *)sender {
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    UIView *existingMenu = [keyWindow viewWithTag:888899];
    if (existingMenu) {
        [existingMenu removeFromSuperview];
        return;
    }

    UIView *menuView = [[UIView alloc] initWithFrame:CGRectMake(60, 70, 480, 340)];
    menuView.tag = 888899;
    menuView.backgroundColor = [UIColor colorWithRed:0.07 green:0.07 blue:0.07 alpha:0.95];
    menuView.layer.cornerRadius = 14;
    menuView.layer.borderWidth = 1.5;
    menuView.layer.borderColor = [UIColor colorWithRed:0.25 green:0.25 blue:0.25 alpha:1.0].CGColor;
    menuView.userInteractionEnabled = YES;

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 12, 350, 30)];
    titleLabel.text = @"AXIOM DELTA EXECUTOR // IOS JAILBREAK";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:13];
    [menuView addSubview:titleLabel];

    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBtn.frame = CGRectMake(435, 12, 30, 30);
    [closeBtn setTitle:@"X" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:1.0] forState:UIControlStateNormal];
    [closeBtn addTarget:menuView action:@selector(removeFromSuperview) forControlEvents:UIControlEventTouchUpInside];
    [menuView addSubview:closeBtn];

    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(15, 55, 450, 265)];
    scrollView.contentSize = CGSizeMake(450, 400);
    [menuView addSubview:scrollView];

    NSArray *features = @[
        @"نط لانهائي (Infinite Jump)",
        @"اختراق الجدران (Noclip)",
        @"سرعة خارقة (Speed Hack)",
        @"كشف اللاعبين (ESP Highlights)",
        @"انتقال بالضغط (Click TP)"
    ];

    for (int i = 0; i < features.count; i++) {
        UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 10 + (i * 50), 320, 30)];
        lbl.text = features[i];
        lbl.textColor = [UIColor colorWithWhite:0.85 alpha:1.0];
        lbl.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
        [scrollView addSubview:lbl];

        UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(360, 10 + (i * 50), 0, 0)];
        sw.tag = 200 + i;
        [sw addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        [scrollView addSubview:sw];
    }
    [keyWindow addSubview:menuView];
}

- (void)switchChanged:(UISwitch *)sender {
    BOOL isOn = sender.isOn;
    NSInteger index = sender.tag - 200;
    
    // أوامر Lua حقيقية لكل زر!
    NSArray *luaCommands = @[
        @"game.Players.LocalPlayer.Character.Humanoid.JumpPower = 200", // نط
        @"game.Players.LocalPlayer.Character.Humanoid:ChangeState(11)", // اختراق جدران
        @"game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 150", // سرعة
        @"", // ESP يحتاج سكربت أطول
        @"game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = game.Players.LocalPlayer:GetMouse().Hit" // Click TP
    ];
    
    // أوامر لإيقاف التفعيل (إذا طفى الزر)
    NSArray *luaOffCommands = @[
        @"game.Players.LocalPlayer.Character.Humanoid.JumpPower = 50",
        @"game.Players.LocalPlayer.Character.Humanoid:ChangeState(3)",
        @"game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 16",
        @"",
        @""
    ];

    if (isOn && index < luaCommands.count) {
        ExecuteRobloxLua(luaCommands[index]);
        NSLog(@"[Axiom] شغلت ميزة: %ld", (long)index);
    } else if (!isOn && index < luaOffCommands.count) {
        ExecuteRobloxLua(luaOffCommands[index]);
        NSLog(@"[Axiom] طفيت ميزة: %ld", (long)index);
    }
}
@end

// ================= التشغيل =================
%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [AxiomDeltaMenu sharedInstance];
    });
}
