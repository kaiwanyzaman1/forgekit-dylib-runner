#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

/* ================= KEY ENGINE =================
   هەمان ئەلگۆریتمی سایتەکە — کلیلەکان لە سایتەکە دروست دەکرێن
   و لێرە کار دەکەن. کێش نەکات!
================================================= */

static NSString *ALPHA   = @"ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
static NSString *SECRET  = @"KW1020LC";
static NSString *SECRET2 = @"KAIWAN1020X";

static uint32_t fnv32(NSString *s){
    uint32_t h = 0x811c9dc5;
    const char *p = [s UTF8String];
    while(*p){ h ^= (uint8_t)*p++; h *= 16777619U; }
    return h;
}

static int alphaIdx(unichar c){
    for(int i=0;i<32;i++) if([ALPHA characterAtIndex:i]==c) return i;
    return -1;
}

static NSMutableDictionary *keyInfo(NSString *raw){
    if(!raw) return nil;
    NSString *k = [raw uppercaseString];
    NSMutableString *m = [NSMutableString new];
    for(NSUInteger i=0;i<k.length;i++){
        unichar c=[k characterAtIndex:i];
        for(int j=0;j<32;j++) if(c==[ALPHA characterAtIndex:j]){ [m appendFormat:@"%C",c]; break; }
    }
    k = m;
    if(k.length!=16) return nil;

    NSString *payload = [k substringToIndex:8];
    NSString *check   = [k substringFromIndex:8];

    uint32_t h1 = fnv32([payload stringByAppendingString:SECRET]);
    uint32_t h2 = fnv32([payload stringByAppendingString:SECRET2]);

    NSMutableString *calc = [NSMutableString new];
    for(int i=0;i<6;i++) [calc appendFormat:@"%C", [ALPHA characterAtIndex:((h1>>(5*i))&31)]];
    [calc appendFormat:@"%C%C",
        [ALPHA characterAtIndex:(h2&31)],
        [ALPHA characterAtIndex:((h2>>5)&31)]];

    if(![calc isEqualToString:check]) return nil;

    int tier = alphaIdx([payload characterAtIndex:0]);
    int dur  = alphaIdx([payload characterAtIndex:1]);
    if(tier<0 || tier>3 || dur<0 || dur>4) return nil;

    uint32_t day=0;
    for(int i=0;i<4;i++){
        int v = alphaIdx([payload characterAtIndex:2+i]);
        if(v<0) return nil;
        day |= ((uint32_t)v) << (5*i);
    }

    int durDays;
    if(dur==0) durDays=1;       // ڕۆژانە
    else if(dur==1) durDays=7;  // حەفتەی
    else if(dur==2) durDays=30; // مانگانە
    else durDays=-1;            // هەتاهەتا (3) و کلیلی تایبەت (4)

    time_t now = time(NULL);
    time_t expiry = (durDays<0) ? 0 : (time_t)(1577836800.0 + (double)(day+durDays)*86400.0);
    BOOL valid = (durDays<0) ? YES : (now < expiry);

    return [@{@"tier":@(tier), @"dur":@(dur), @"valid":@(valid),
              @"expiry":@(expiry), @"days":@(durDays)} mutableCopy];
}

static NSString *tierName(int t){
    switch(t){ case 0: return @"100 MOBAIL"; case 1: return @"500 MOBAIL";
               case 2: return @"1000 MOBAIL"; default: return @"HATAHATAI (∞)"; }
}
static NSString *durName(int d){
    switch(d){ case 0: return @"ROZANA 1ROJ"; case 1: return @"HAFTANA";
               case 2: return @"MANGANA"; default: return @"HATAHATAI"; }
}

/* ================= LICENSE UI ================= */

static UIButton *tgButton;
static UILabel  *counterLabel;
static int remain = 30;
static UIWindow *licenseWindow;

@interface KWLicenseVC : UIViewController
@property(nonatomic,strong) UITextField *field;
@property(nonatomic,strong) UILabel *msg;
@end

@implementation KWLicenseVC

-(void)viewDidLoad{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];

    // پشتی مینۆکە — گرادیەنتی جوانی تڵخ
    CAGradientLayer *g = [CAGradientLayer layer];
    g.frame = self.view.bounds;
    g.colors = @[(id)[UIColor colorWithRed:0.05 green:0.02 blue:0.15 alpha:1].CGColor,
                 (id)[UIColor colorWithRed:0.15 green:0.04 blue:0.35 alpha:1].CGColor,
                 (id)[UIColor colorWithRed:0.01 green:0.01 blue:0.05 alpha:1].CGColor];
    g.locations = @[@0,@(0.5),@1];
    [self.view.layer insertSublayer:g atIndex:0];

    // پانێلی شوشەیی
    UIVisualEffectView *blur = [[UIVisualEffectView alloc] initWithEffect:
        [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemChromeMaterialDark]];
    blur.frame = CGRectMake(25, self.view.bounds.size.height*0.18,
                             self.view.bounds.size.width-50, self.view.bounds.size.height*0.62);
    blur.layer.cornerRadius = 28;
    blur.layer.masksToBounds = YES;
    [self.view addSubview:blur];
    UIView *panel = blur.contentView;

    // ناونیشان
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 30, panel.bounds.size.width, 55)];
    title.text = @"🔐 LICENSE";
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont boldSystemFontOfSize:34];
    title.textAlignment = NSTextAlignmentCenter;
    [panel addSubview:title];

    UILabel *sub = [[UILabel alloc] initWithFrame:CGRectMake(0, 85, panel.bounds.size.width, 25)];
    sub.text = @"KAIWAN SECURITY SYSTEM";
    sub.textColor = [UIColor colorWithRed:0.6 green:0.4 blue:1 alpha:1];
    sub.font = [UIFont systemFontOfSize:12];
    sub.textAlignment = NSTextAlignmentCenter;
    [panel addSubview:sub];

    // خانەی کلیل
    self.field = [[UITextField alloc] initWithFrame:CGRectMake(25, 140, panel.bounds.size.width-50, 55)];
    self.field.placeholder = @"CLILEK LEBEDA NAW XANAYA...";
    self.field.textColor = [UIColor whiteColor];
    self.field.font = [UIFont boldSystemFontOfSize:18];
    self.field.textAlignment = NSTextAlignmentCenter;
    self.field.backgroundColor = [UIColor colorWithWhite:1 alpha:0.08];
    self.field.layer.cornerRadius = 15;
    self.field.layer.borderWidth = 1.5;
    self.field.layer.borderColor = [UIColor colorWithRed:0.5 green:0.3 blue:0.9 alpha:0.7].CGColor;
    self.field.autocorrectionType = UITextAutocorrectionTypeNo;
    self.field.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
    [panel addSubview:self.field];

    // کلیلی چالاکردن
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(25, 215, panel.bounds.size.width-50, 55);
    [btn setTitle:@"✅ ACTIVE KIRDIN" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont boldSystemFontOfSize:19];
    btn.layer.cornerRadius = 15;
    btn.layer.shadowColor = [UIColor purpleColor].CGColor;
    btn.layer.shadowOffset = CGSizeMake(0,4);
    btn.layer.shadowOpacity = 0.7;
    btn.layer.shadowRadius = 10;
    [btn setBackgroundImage:[UIImage imageNamed:nil] forState:UIControlStateNormal];
    btn.backgroundColor = [UIColor colorWithRed:0.35 green:0.15 blue:0.85 alpha:1];
    [btn addTarget:self action:@selector(checkKey) forControlEvents:UIControlEventTouchUpInside];
    [panel addSubview:btn];

    // نامەی هەڵە/سەرکەوتن
    self.msg = [[UILabel alloc] initWithFrame:CGRectMake(0, 278, panel.bounds.size.width, 25)];
    self.msg.textAlignment = NSTextAlignmentCenter;
    self.msg.font = [UIFont boldSystemFontOfSize:14];
    [panel addSubview:self.msg];

    // دوگمەی تیلیگرام
    tgButton = [UIButton buttonWithType:UIButtonTypeCustom];
    tgButton.frame = CGRectMake(25, 315, panel.bounds.size.width-50, 50);
    [tgButton setTitle:@"📞 TELEGRAM ➜ @kaiwan1020" forState:UIControlStateNormal];
    [tgButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    tgButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    tgButton.backgroundColor = [UIColor colorWithRed:0.1 green:0.45 blue:0.85 alpha:1];
    tgButton.layer.cornerRadius = 15;
    [tgButton addTarget:self action:@selector(openTg) forControlEvents:UIControlEventTouchUpInside];
    [panel addSubview:tgButton];

    // ژمێرەوەی 30 چرکە
    counterLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 378, panel.bounds.size.width, 30)];
    counterLabel.textAlignment = NSTextAlignmentCenter;
    counterLabel.font = [UIFont boldSystemFontOfSize:18];
    counterLabel.textColor = [UIColor colorWithRed:1 green:0.3 blue:0.3 alpha:1];
    [panel addSubview:counterLabel];

    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(tick) userInfo:nil repeats:YES];
}

-(void)openTg{
    [[UIApplication sharedApplication] openURL:
        [NSURL URLWithString:@"https://t.me/kaiwan1020"] options:@{} completionHandler:nil];
}

-(void)tick{
    remain--;
    counterLabel.text = [NSString stringWithFormat:@"⏳ %d SANIA CRASH DAKAT...", remain];
    if(remain<=0){ exit(0); }
}

-(void)shake:(UIView*)v{
    CABasicAnimation *a = [CABasicAnimation animationWithKeyPath:@"transform.translation.x"];
    a.duration = 0.07; a.repeatCount = 4; a.autoreverses = YES;
    a.fromValue = @(-14); a.toValue = @(14);
    [v.layer addAnimation:a forKey:@"shake"];
}

-(void)checkKey{
    NSMutableDictionary *info = keyInfo(self.field.text);
    if(info && [info[@"valid"] boolValue]){
        remain = 9999;
        [[NSUserDefaults standardUserDefaults] setObject:self.field.text forKey:@"kw_key"];
        self.msg.text = [NSString stringWithFormat:@"✅ BE SERKETUWEE! %@ | %@ | @kaiwan1020",
                          tierName([info[@"tier"] intValue]), durName([info[@"dur"] intValue])];
        self.msg.textColor = [UIColor colorWithRed:0.2 green:1 blue:0.4 alpha:1];
        counterLabel.text = @"✅ LICENSE ACTIVE - BY KAIWAN";
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2*NSEC_PER_SEC),
            dispatch_get_main_queue(), ^{ [self dismissViewControllerAnimated:YES completion:nil]; });
    } else if(info){
        self.msg.text = @"❌ CLILAK BESERCHWIWE (EXPIRED)!";
        self.msg.textColor = [UIColor orangeColor];
        [self shake:self.field];
    } else {
        self.msg.text = @"❌ CLILAK HALATYE ! DOBARA HIBINAWA";
        self.msg.textColor = [UIColor redColor];
        [self shake:self.field];
    }
}
@end

/* ================= INJECT ================= */

static UIWindow *kwActiveWindow(void){
    UIApplication *app = [UIApplication sharedApplication];
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in app.connectedScenes) {
            if (scene.activationState == UISceneActivationStateUnattached) continue;
            if (![scene isKindOfClass:[UIWindowScene class]]) continue;
            UIWindowScene *sceneWindow = (UIWindowScene *)scene;
            if (sceneWindow.keyWindow) return sceneWindow.keyWindow;
            if (sceneWindow.windows.firstObject) return sceneWindow.windows.firstObject;
        }
    }
    if (app.keyWindow) return app.keyWindow;
    return app.windows.firstObject;
}

static void showLicense(void){
    dispatch_async(dispatch_get_main_queue(), ^{
        if (licenseWindow) return;
        licenseWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        licenseWindow.windowLevel = UIWindowLevelAlert + 100;
        if (@available(iOS 13.0, *)) {
            UIWindow *host = kwActiveWindow();
            licenseWindow.windowScene = host.windowScene;
        }
        licenseWindow.rootViewController = [[KWLicenseVC alloc] init];
        [licenseWindow makeKeyAndVisible];
    });
}

static void showToast(void){
    UILabel *t = [[UILabel alloc] initWithFrame:CGRectMake(40, 60, [UIScreen mainScreen].bounds.size.width-80, 45)];
    t.text = @"✅ LICENSE ACTIVE - @kaiwan1020";
    t.textColor = [UIColor whiteColor];
    t.textAlignment = NSTextAlignmentCenter;
    t.font = [UIFont boldSystemFontOfSize:15];
    t.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.75];
    t.layer.cornerRadius = 12; t.clipsToBounds = YES;
    UIWindow *w = kwActiveWindow();
    if (!w) return;
    [w addSubview:t];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.6 animations:^{ t.alpha = 0; } completion:^(BOOL f){ [t removeFromSuperview]; }];
    });
}

%ctor {
    @autoreleasepool {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2*NSEC_PER_SEC),
            dispatch_get_main_queue(), ^{
            NSString *saved = [[NSUserDefaults standardUserDefaults] stringForKey:@"kw_key"];
            NSMutableDictionary *info = keyInfo(saved);
            if(info && [info[@"valid"] boolValue]) showToast();
            else showLicense();
        });
    }
}