//
//  SignupViewController.m
//  surespot
//
//  Created by Adam on 7/22/13.
//  Copyright (c) 2013 surespot. All rights reserved.
//

#import "SignupViewController.h"
#import "EncryptionController.h"
#import "IdentityController.h"
#import "NetworkManager.h"
#import "NSData+Base64.h"
#import "NSData+SRB64Additions.h"
#import "UIUtils.h"
#import "CocoaLumberjack.h"
#import "LoadingView.h"
#import "RestoreIdentitiesViewController.h"
#import "HelpViewController.h"
#import "SwipeViewController.h"
#import "LoginViewController.h"
#import "BackupIdentityViewController.h"
#import "AboutViewController.h"
#import "NSBundle+FallbackLanguage.h"
#import "ChatManager.h"
#import "SurespotLeftNavButton.h"

#ifdef DEBUG
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
#else
static const DDLogLevel ddLogLevel = DDLogLevelOff;
#endif


@interface SignupViewController ()
@property (atomic, strong) id progressView;
@property (nonatomic, strong) NSString * lastCheckedUsername;
@property (nonatomic, assign) CGFloat delta;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UILabel *helpLabel;
@property (strong, readwrite, nonatomic) REMenu *menu;
@property (nonatomic, strong) UIPopoverController * popover;
@end

@implementation SignupViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationItem setTitle:NSLocalizedString(@"create", nil)];
    
    NSString * usernamesCaseSensitive =    NSLocalizedString(@"usernames_case_sensitive", nil);
    NSString * pwWarning = NSLocalizedString(@"warning_password_reset", nil);
    
    NSString * labelText = [NSString stringWithFormat:@"%@ %@ %@ %@",
                            NSLocalizedString(@"enter_username_and_password", nil),
                            usernamesCaseSensitive,
                            NSLocalizedString(@"aware_username_password", nil),
                            pwWarning];
    
    NSRange rr1 = [labelText rangeOfString:usernamesCaseSensitive];
    NSRange rr2 = [labelText rangeOfString:pwWarning];
    
    NSMutableAttributedString * helpString = [[NSMutableAttributedString alloc] initWithString:labelText];
    if ([UIUtils isBlackTheme]) {
        [helpString addAttribute:NSForegroundColorAttributeName value:[UIUtils surespotForegroundGrey] range:[labelText rangeOfString:labelText]];
    }
    [helpString addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range: rr1];
    [helpString addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range: rr2];
	   
    
    _helpLabel.attributedText = helpString;
    
    _tbUsername.returnKeyType = UIReturnKeyNext;
    [_tbUsername setRightViewMode: UITextFieldViewModeNever];
    [_tbUsername setPlaceholder:NSLocalizedString(@"username", nil)];
    
    _tbPassword.returnKeyType = UIReturnKeyNext;
    [_tbPassword setPlaceholder:NSLocalizedString(@"password", nil)];
    
    _tbPasswordConfirm.returnKeyType = UIReturnKeyGo;
    [_tbPasswordConfirm setPlaceholder:NSLocalizedString(@"confirm_password", nil)];
    
    _delta = 0.0f;
    
    if ([[[IdentityController sharedInstance] getIdentityNames] count] == 0) {
        self.navigationItem.hidesBackButton = YES;
    }
    
    UIBarButtonItem *anotherButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"menu",nil) style:UIBarButtonItemStylePlain target:self action:@selector(showMenu)];
    self.navigationItem.rightBarButtonItem = anotherButton;
    
    [_bCreateIdentity setTintColor:[UIUtils surespotBlue]];
    [_bCreateIdentity setTitle:NSLocalizedString(@"create_identity", nil) forState:UIControlStateNormal];
    
    
    [_scrollView setContentSize: CGSizeMake(self.view.frame.size.width, _bCreateIdentity.frame.origin.y + _bCreateIdentity.frame.size.height)];
    
    //theme
    if ([UIUtils isBlackTheme]) {
        [self.scrollView setBackgroundColor:[UIColor blackColor]];
        
        [self.tbUsername setTextColor: [UIUtils surespotForegroundGrey]];
        [self.tbUsername setAttributedPlaceholder: [[NSAttributedString alloc] initWithString:NSLocalizedString(@"username", nil) attributes:@{NSForegroundColorAttributeName:[UIUtils surespotForegroundGrey]}]];
        [self.tbUsername.layer setBorderColor:[[UIUtils surespotGrey] CGColor]];
        [self.tbUsername.layer setBorderWidth:1.0f];
        
        [self.tbPassword setTextColor: [UIUtils surespotForegroundGrey]];
        [self.tbPassword setAttributedPlaceholder: [[NSAttributedString alloc] initWithString:NSLocalizedString(@"password", nil) attributes:@{NSForegroundColorAttributeName:[UIUtils surespotForegroundGrey]}]];
        [self.tbPassword.layer setBorderColor:[[UIUtils surespotGrey] CGColor]];
        [self.tbPassword.layer setBorderWidth:1.0f];
        
        [self.tbPasswordConfirm setTextColor: [UIUtils surespotForegroundGrey]];
        [self.tbPasswordConfirm setAttributedPlaceholder: [[NSAttributedString alloc] initWithString:NSLocalizedString(@"confirm_password", nil) attributes:@{NSForegroundColorAttributeName:[UIUtils surespotForegroundGrey]}]];
        [self.tbPasswordConfirm.layer setBorderColor:[[UIUtils surespotGrey] CGColor]];
        [self.tbPasswordConfirm.layer setBorderWidth:1.0f];
    }
    
    [self setBackButtonIcon];
}

-(void) setBackButtonIcon {
    if (self.navigationController.viewControllers.count == 1) {
        SurespotLeftNavButton *backButton = [[SurespotLeftNavButton alloc] initWithFrame: CGRectMake(0, 0, 36.0f, 36.0f) inset:2];
        UIBarButtonItem * backButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
        UIImage * backImage = [UIImage imageNamed:@"surespot_logo"];
        [backButton setBackgroundImage:backImage  forState:UIControlStateNormal];
        [backButton setContentMode:UIViewContentModeScaleAspectFit];
        self.navigationItem.leftItemsSupplementBackButton = NO;
        self.navigationItem.hidesBackButton = YES;
        self.navigationItem.leftBarButtonItem = backButtonItem;
    }
}

- (void)viewDidUnload {
    [self setBCreateIdentity:nil];
    [self setTbUsername:nil];
    [self setTbPassword:nil];
    [super viewDidUnload];
}

- (IBAction)createIdentity:(id)sender {
    NSString * username = self.tbUsername.text;
    NSString * password = self.tbPassword.text;
    NSString * confirmPassword = self.tbPasswordConfirm.text;
    
    if ([[ChatManager sharedInstance] networkReachabilityStatus] == AFNetworkReachabilityStatusNotReachable) {
        [UIUtils showToastKey: @"no_network_connection"];
        return;
    }
    
    
    if ([UIUtils stringIsNilOrEmpty:username] || [UIUtils stringIsNilOrEmpty:password] || [UIUtils stringIsNilOrEmpty:confirmPassword]) {
        return;
    }
    
    
    [_tbUsername resignFirstResponder];
    [_tbPassword resignFirstResponder];
    [_tbPasswordConfirm resignFirstResponder];
    
    if (![confirmPassword isEqualToString:password]) {
        [UIUtils showToastKey:@"passwords_do_not_match" duration:1.5];
        _tbPassword.text = @"";
        _tbPasswordConfirm.text = @"";
        [_tbPassword becomeFirstResponder];
        return;
    }
    
    _progressView = [LoadingView showViewKey:@"create_user_progress"];
    
    dispatch_queue_t q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    
    dispatch_async(q, ^{
        
        
        NSDictionary *derived = [EncryptionController deriveKeyFromPassword:password];
        
        NSString * salt = [[derived objectForKey:@"salt" ] SR_stringByBase64Encoding];
        NSString * encPassword = [[derived objectForKey:@"key" ] SR_stringByBase64Encoding];
        
        
        IdentityKeys * keys = [EncryptionController generateKeyPairs];
        
        NSString * encodedDHKey = [EncryptionController encodeDHPublicKey: [keys dhPubKey]];
        NSString * encodedDSAKey = [EncryptionController encodeDSAPublicKey:[keys dsaPubKey]];
        NSString * sDhPub = [[EncryptionController encodeDHPublicKeyData:[keys dhPubKey]] SR_stringByBase64Encoding];
        NSString * sDsaPub = [[EncryptionController encodeDSAPublicKeyData:[keys dsaPubKey]] SR_stringByBase64Encoding];
        NSString * authSig = [[EncryptionController signUsername:username andPassword: [encPassword dataUsingEncoding:NSUTF8StringEncoding] withPrivateKey:keys.dsaPrivKey] SR_stringByBase64Encoding];
        NSString * clientSig = [[EncryptionController signUsername:username andVersion:1 andDhPubKey:sDhPub andDsaPubKey:sDsaPub withPrivateKey:keys.dsaPrivKey] SR_stringByBase64Encoding];
        
        [[[NetworkManager sharedInstance] getNetworkController:nil]
         createUser3WithUsername: username
         derivedPassword: encPassword
         dhKey: encodedDHKey
         dsaKey: encodedDSAKey
         authSig: authSig
         clientSig: clientSig
         successBlock:^(NSURLSessionTask *operation, id responseObject, NSHTTPCookie * cookie) {
             DDLogVerbose(@"signup response: %ld",  (long)[(NSHTTPURLResponse*)operation.response statusCode]);
             [[IdentityController sharedInstance] createIdentityWithUsername:username andPassword:password andSalt:salt andKeys:keys cookie:cookie];
             UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle: nil];
             SwipeViewController * svc = [storyboard instantiateViewControllerWithIdentifier:@"swipeViewController"];
             BackupIdentityViewController * bvc = [[BackupIdentityViewController alloc] initWithNibName:@"BackupIdentityView" bundle:nil];
             bvc.selectUsername = username;
             
             NSMutableArray *  controllers = [NSMutableArray new];
             [controllers addObject:svc];
             [controllers addObject:bvc];
             
             
             //show help view on iphone if it hasn't been shown
             BOOL tosClicked = [[NSUserDefaults standardUserDefaults] boolForKey:@"hasClickedTOS"];
             if ((!tosClicked) && [UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad) {
                 HelpViewController *hvc = [[HelpViewController alloc] initWithNibName:@"HelpView" bundle:nil];
                 [controllers addObject:hvc];
             }
             
             [self.navigationController setViewControllers:controllers animated:YES];
             [_progressView removeView];
             _progressView = nil;
         }
         failureBlock:^(NSURLSessionTask *operation, NSError *Error) {
             
             DDLogVerbose(@"signup response failure: %@",  Error);
             
             [_progressView removeView];
             _progressView = nil;
             
             switch ([(NSHTTPURLResponse*)operation.response statusCode]) {
                 case 429:
                     [UIUtils showToastKey: @"user_creation_throttled" duration:3];
                     [_tbUsername becomeFirstResponder];
                     break;
                 case 409:
                     [UIUtils showToastKey: @"username_exists" duration:2];
                     [_tbUsername becomeFirstResponder];
                     break;
                 case 403:
                     [UIUtils showToastKey: @"signup_update" duration:4];
                     break;
                 default:
                     [UIUtils showToastKey: @"could_not_create_user" duration:2];
             }
             
             self.navigationItem.rightBarButtonItem.enabled = YES;
         }
         ];
        
    });
    
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == _tbUsername) {
        //        if (![UIUtils stringIsNilOrEmpty: textField.text]) {
        //            [_tbPassword becomeFirstResponder];
        //            [_tbUsername resignFirstResponder];
        //        }
        [self checkUsername];
        return NO;
    }
    else {
        if (textField == _tbPassword) {
            if (![UIUtils stringIsNilOrEmpty: textField.text]) {
                [_tbPasswordConfirm becomeFirstResponder];
                [textField resignFirstResponder];
                return NO;
            }
        }
        else {
            if (textField == _tbPasswordConfirm) {
                [textField resignFirstResponder];
                [self createIdentity:nil];
                return YES;
                
            }
        }
    }
    
    
    return NO;
}

- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == _tbUsername) {
        
        
        
        NSCharacterSet *alphaSet = [NSCharacterSet alphanumericCharacterSet];
        NSString * newString = [string stringByTrimmingCharactersInSet:alphaSet];
        if (![newString isEqualToString:@""]) {
            return NO;
        }
        
        NSUInteger newLength = [textField.text length] + [newString length] - range.length;
        if (newLength == 0) {
            [_tbUsername setRightViewMode:UITextFieldViewModeNever];
            _lastCheckedUsername = nil;
        }
        return (newLength >= 20) ? NO : YES;
    }
    else {
        if ((textField == _tbPassword) || (textField == _tbPasswordConfirm)) {
            NSUInteger newLength = [textField.text length] + [string length] - range.length;
            return (newLength >= 256) ? NO : YES;
        }
    }
    
    return YES;
}

-(void) checkUsername {
    NSString * username = self.tbUsername.text;
    
    if ([UIUtils stringIsNilOrEmpty:username]) {
        return;
    }
    
    if ([_lastCheckedUsername isEqualToString: username]) {
        return;
    }
    
    if ([[ChatManager sharedInstance] networkReachabilityStatus] == AFNetworkReachabilityStatusNotReachable) {
        [UIUtils showToastKey: @"no_network_connection"];
        return;
    }
    
    _lastCheckedUsername = username;
    _progressView = [LoadingView showViewKey:@"user_exists_progress"];
    
    [[[NetworkManager sharedInstance] getNetworkController:nil] userExists:username successBlock:^(NSURLSessionTask *operation, id responseObject) {
        NSString * response = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        
        [_progressView removeView];
        _progressView = nil;
        
        
        if ([response isEqualToString:@"true"]) {
            [UIUtils showToastKey:@"username_exists"];
            [self setUsernameValidity:NO];
            [_tbUsername becomeFirstResponder];
        }
        else {
            [self setUsernameValidity:YES];
            [_tbPassword becomeFirstResponder];
        }
    } failureBlock:^(NSURLSessionTask *operation, NSError *error) {
        [_tbUsername becomeFirstResponder];
        [_progressView removeView];
        _progressView = nil;
        [UIUtils showToastKey:@"user_exists_error"];
        _lastCheckedUsername = nil;
    }];
}


-(void) setUsernameValidity: (BOOL) valid {
    [_tbUsername setRightViewMode:UITextFieldViewModeAlways];
    if (valid) {
        _tbUsername.rightView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"btn_check_buttonless_on"] ];
    }
    else {
        _tbUsername.rightView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_delete"] ];
        
    }
    
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
    
    if (textField == _tbUsername) {
        [self checkUsername];
    }
}


-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self registerForKeyboardNotifications];
}

-(void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self unregisterKeyboardNotifications];
}


- (void)registerForKeyboardNotifications
{
    //use old positioning pre ios 8
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeShown:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

-(void) unregisterKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}



// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWillBeShown:(NSNotification*) aNotification {
    DDLogInfo(@"keyboard shown");
    
    NSDictionary* info = [aNotification userInfo];
    NSTimeInterval animationDuration;
    UIViewAnimationOptions curve;
    [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&curve];
    CGRect keyboardRect = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat keyboardHeight = keyboardRect.size.height;
    CGFloat totalHeight = self.view.frame.size.height;
    CGFloat keyboardTop = totalHeight - keyboardHeight;
    
    // run animation using keyboard's curve and duration
    [UIView animateWithDuration:animationDuration delay:0.0 options:curve animations:^{
        CGRect buttonFrame = _bCreateIdentity.frame;
        CGFloat createButtonBottom = buttonFrame.origin.y + buttonFrame.size.height ;
        CGFloat delta = keyboardTop - createButtonBottom;
        CGFloat deltaDelta = _delta - delta;
        _delta = delta;
        
        DDLogInfo(@"delta %f loginBottom %f keyboardtop: %f", deltaDelta, createButtonBottom, keyboardTop);
        
        if (delta < 10 ) {
            UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardHeight, 0.0);
            _scrollView.contentInset = contentInsets;
            _scrollView.scrollIndicatorInsets = contentInsets;
            CGPoint scrollPoint = CGPointMake(0.0, _scrollView.contentOffset.y + deltaDelta);
            
            [_scrollView setContentOffset:scrollPoint animated:NO];
        }
        
        [self.view layoutIfNeeded];
        
    } completion:^(BOOL completion) {
        
    }];
    
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification *) aNotification {
    DDLogInfo(@"keyboard hide");
    NSDictionary* info = [aNotification userInfo];
    NSTimeInterval animationDuration;
    UIViewAnimationOptions curve;
    [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&curve];
    // run animation using keyboard's curve and duration
    [UIView animateWithDuration:animationDuration delay:0.0 options:curve animations:^{
        UIEdgeInsets contentInsets = UIEdgeInsetsZero;
        _scrollView.contentInset = contentInsets;
        _scrollView.scrollIndicatorInsets = contentInsets;
    } completion:^(BOOL completion) {
    }];
    
    _delta = 0.0f;
}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
                                duration:(NSTimeInterval)duration
{
    DDLogInfo(@"will rotate");
    [_tbUsername resignFirstResponder];
    [_tbPassword resignFirstResponder];
    [_tbPasswordConfirm resignFirstResponder];
    _delta = 0.0f;
}

-(void) showMenu {
    if (!_menu) {
        _menu = [self createMenu];
        if (_menu) {
            [_menu showSensiblyInView:self.view];
        }
    }
    else {
        [_menu close];
    }
    
}

-(REMenu *) createMenu {
    //menu menu
    
    NSMutableArray * menuItems = [NSMutableArray new];
    
    
    REMenuItem * restoreItem = [[REMenuItem alloc] initWithTitle:NSLocalizedString(@"import_identities", nil) image:[UIImage imageNamed:@"ic_menu_archive"] highlightedImage:nil action:^(REMenuItem * item){
        RestoreIdentitiesViewController * controller = [[RestoreIdentitiesViewController alloc] init];
        [self.navigationController pushViewController:controller animated:YES];
        
    }];
    
    [menuItems addObject:restoreItem];
    
    REMenuItem * aboutItem = [[REMenuItem alloc] initWithTitle:NSLocalizedString(@"about", nil) image:[UIImage imageNamed:@"surespot_logo48"] highlightedImage:nil action:^(REMenuItem * item){
        [self showAbout];
    }];
    
    
    [menuItems addObject:aboutItem];
    
    
    
    return [UIUtils createMenu: menuItems closeCompletionHandler:^{
        _menu = nil;
    }];
}


- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    self.popover = nil;
}


-(void) showAbout {
    AboutViewController * controller = [[AboutViewController alloc] initWithNibName:@"AboutView" bundle:nil];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        _popover = [[UIPopoverController alloc] initWithContentViewController:controller];
        _popover.delegate = self;
        CGFloat x = self.view.bounds.size.width;
        CGFloat y =self.view.bounds.size.height;
        DDLogInfo(@"setting popover x, y to: %f, %f", x/2,y/2);
        [_popover setPopoverContentSize:CGSizeMake(320, 480) animated:NO];
        [_popover presentPopoverFromRect:CGRectMake(x/2,y/2, 1,1 ) inView:self.view permittedArrowDirections:0 animated:YES];
        
    } else {
        [self.navigationController pushViewController:controller animated:YES];
    }
    
}

-(void)popoverController:(UIPopoverController *)popoverController willRepositionPopoverToRect:(inout CGRect *)rect inView:(inout UIView *__autoreleasing *)view {
    CGFloat x =self.view.bounds.size.width;
    CGFloat y =self.view.bounds.size.height;
    DDLogInfo(@"setting popover x, y to: %f, %f", x/2,y/2);
    
    CGRect newRect = CGRectMake(x/2,y/2, 1,1 );
    *rect = newRect;
}


-(BOOL) shouldAutorotate {
    return _progressView == nil;
}


@end
