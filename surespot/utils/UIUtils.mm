//
//  UIUtils.m
//  surespot
//
//  Created by Adam on 11/1/13.
//  Copyright (c) 2013 surespot. All rights reserved.
//


#import <AssetsLibrary/AssetsLibrary.h>

#import "UIUtils.h"
#import "Toast+UIView.h"
#import "ChatUtils.h"
#import "CocoaLumberjack.h"
#import "SurespotConstants.h"
#import "SurespotAppDelegate.h"
#import "FileController.h"
#import "SDWebImageManager.h"
#import "NSBundle+FallbackLanguage.h"
#import "IdentityController.h"
#import "UIImage+Scale.h"

#ifdef DEBUG
static const DDLogLevel ddLogLevel = DDLogLevelDebug;
#else
static const DDLogLevel ddLogLevel = DDLogLevelOff;
#endif

#define ARC4RANDOM_MAX      0x100000000

@implementation UIUtils

+(UIColor *) surespotBlue {
    return [UIColor colorWithRed:0.2 green:0.71 blue:0.898 alpha:1.0];
}

+(UIColor *) surespotSelectionBlue {
    return [UIColor colorWithRed:0.2 green:0.71 blue:0.898 alpha:0.9];
}

+(UIColor *) surespotTransparentBlue {
    return [UIColor colorWithRed:0.2 green:0.71 blue:0.898 alpha:0.5];
}

+(UIColor *) surespotGrey {
    return [UIColor colorWithRed:22/255.0f green:22/255.0f blue:22/255.0f alpha:1.0f];
}

+(UIColor *) surespotForegroundGrey {
    return [UIColor colorWithRed:187/255.0f green:187/255.0f blue:187/255.0f alpha:1.0f];
}


+(UIColor *) surespotTransparentGrey {
    return [UIColor colorWithRed:22/255.0f green:22/255.0f blue:22/255.0f alpha:0.5f];
}

+(UIColor *) surespotSeparatorGrey {
    return [UIColor colorWithRed:180/255.0f green:180/255.0f blue:180/255.0f alpha:0.2f];
}



+(void) showToastMessage: (NSString *) message duration: (CGFloat) duration {
    AGWindowView * overlayView = [[AGWindowView alloc] initAndAddToKeyWindow];
    [overlayView setUserInteractionEnabled:NO];
    [overlayView  makeToast:message
                   duration: duration
                   position:@"center"
     ];
}

+(void) showToastKey: (NSString *) key {
    [self showToastKey:key duration:2.0];
}
+(void) showToastKey: (NSString *) key duration: (CGFloat) duration {
    AGWindowView * overlayView = [[AGWindowView alloc] initAndAddToKeyWindow];
    [overlayView setUserInteractionEnabled:NO];
    [overlayView  makeToast:NSLocalizedString(key, nil)
                   duration: duration
                   position:@"center"
     ];
}

+ (CGSize)threadSafeSizeString: (NSString *) string WithFont:(UIFont *)font constrainedToSize:(CGSize)size {
    
    if (string) {
        // http://stackoverflow.com/questions/12744558/uistringdrawing-methods-dont-seem-to-be-thread-safe-in-ios-6
        NSAttributedString *attributedText =
        [[NSAttributedString alloc]
         initWithString:string
         attributes:@
         {
         NSFontAttributeName: font
         }];
        CGRect rect = [attributedText boundingRectWithSize:size
                                                   options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                                                   context:nil];
        return rect.size;
    }
    else {
        return CGSizeZero;
    }
}

+ (void)setAppAppearances {
    [[UINavigationBar appearance] setBarTintColor: [self surespotGrey]];
    
    [[UIBarButtonItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [self surespotBlue],  NSForegroundColorAttributeName,nil] forState:UIControlStateNormal];
    
    [[UIButton appearance] setTitleColor:[self surespotBlue] forState:UIControlStateNormal];
    
    [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIUtils surespotForegroundGrey],  NSForegroundColorAttributeName,nil]];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    
    [[UIScrollView appearance] setIndicatorStyle: ([self isBlackTheme] ? UIScrollViewIndicatorStyleWhite : UIScrollViewIndicatorStyleBlack) ];
    
    [[UISwitch appearance] setTintColor:[UIUtils surespotBlue]];
    [[UISwitch appearance] setOnTintColor:[UIUtils surespotBlue]];
}

+(BOOL)stringIsNilOrEmpty:(NSString*)aString {
    return !(aString && aString.length);
}

+(void) setTextMessageHeights: (SurespotMessage *)  message size: (CGSize) screenSize ourUsername: (NSString *) ourUsername {
    if (message.rowPortraitHeight > 0 && message.rowLandscapeHeight > 0) {
        return;
    }
    
    CGSize size = [self sizeAdjustedForOrientation:screenSize];
    
    //figure out message height for both orientations
    NSString * plaintext = message.plainData;
    if (plaintext){
        NSInteger offset = 0;
        NSInteger heightAdj = 35;
        BOOL ours = [ChatUtils isOurMessage:message ourUsername:ourUsername];
        if (ours) {
            offset = 40;
        }
        else {
            offset = 80;
        }
        //http://stackoverflow.com/questions/12744558/uistringdrawing-methods-dont-seem-to-be-thread-safe-in-ios-6
        
        UIFont *cellFont = [UIFont systemFontOfSize:17.0];
        
        //portrait
        CGSize constraintSize = CGSizeMake(size.width - offset, MAXFLOAT);
        
        DDLogVerbose(@"computing portrait size for message: %@ for size width: %f, height: %f, constraint width: %f", message.iv, size.width,size.height, constraintSize.width);
        
        CGSize labelSize = [self threadSafeSizeString:plaintext WithFont:cellFont constrainedToSize:constraintSize];
        CGFloat height = ceilf(labelSize.height);
        DDLogVerbose(@"computed portrait width %f, height: %f", labelSize.width, height);
        [message setRowPortraitHeight:(int) (height + heightAdj > 44 ? height + heightAdj : 44) ];
        
        //landscape
        constraintSize = CGSizeMake(size.height-offset, MAXFLOAT);
        DDLogVerbose(@"computing landscape size for message: %@ for constraint width: %f", message.iv, constraintSize.width);
        labelSize = [UIUtils threadSafeSizeString:plaintext WithFont:cellFont constrainedToSize:constraintSize];
        height = ceilf(labelSize.height);
        
        DDLogVerbose(@"computed landscape width %f, height: %f", labelSize.width, height);
        [message setRowLandscapeHeight:(int) (height + heightAdj > 44 ? height + heightAdj: 44) ];
        
        DDLogVerbose(@"computed row height - portrait: %ld, landscape: %ld, for iv: %@", (long)message.rowPortraitHeight, (long)message.rowLandscapeHeight, message.iv);
    }
    else {
        DDLogVerbose(@"No plaintext yet for message iv: %@", message.iv);
    }
}

+(CGSize) sizeAdjustedForOrientation: (CGSize) size {
    UIInterfaceOrientation  orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
        DDLogVerbose(@"sizeAdjustedForOrientation adjusting size for landscape");
        return CGSizeMake(size.height, size.width);
    }
    else {
        DDLogVerbose(@"sizeAdjustedForOrientation using size for portrait");
        return CGSizeMake(size.width, size.height);
    }
}


+(void) setImageMessageHeights: (SurespotMessage *)  message size: (CGSize) size {
    NSInteger height = [self getDefaultImageMessageHeight];
    
    [message setRowPortraitHeight: height];
    [message setRowLandscapeHeight: height];
    DDLogVerbose(@"setting image row height portrait %ld landscape %ld", (long)message.rowPortraitHeight, (long)message.rowLandscapeHeight);
    
}

+(NSInteger) getDefaultImageMessageHeight {
    if ([[UIDevice currentDevice]       userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        return 448;
    }
    else {
        return 224;
    }
    
}

+(CGSize)imageSizeAfterAspectFit:(UIImageView*)imgview{
    
    
    float newwidth;
    float newheight;
    
    UIImage *image=imgview.image;
    
    if (image.size.height>=image.size.width){
        newheight=imgview.frame.size.height;
        newwidth=(image.size.width/image.size.height)*newheight;
        
        if(newwidth>imgview.frame.size.width){
            float diff=imgview.frame.size.width-newwidth;
            newheight=newheight+diff/newheight*newheight;
            newwidth=imgview.frame.size.width;
        }
        
    }
    else{
        newwidth=imgview.frame.size.width;
        newheight=(image.size.height/image.size.width)*newwidth;
        
        if(newheight>imgview.frame.size.height){
            float diff=imgview.frame.size.height-newheight;
            newwidth=newwidth+diff/newwidth*newwidth;
            newheight=imgview.frame.size.height;
        }
    }
    
    NSLog(@"image after aspect fit: width=%f height=%f",newwidth,newheight);
    
    
    //adapt UIImageView size to image size
    //imgview.frame=CGRectMake(imgview.frame.origin.x+(imgview.frame.size.width-newwidth)/2,imgview.frame.origin.y+(imgview.frame.size.height-newheight)/2,newwidth,newheight);
    
    return CGSizeMake(newwidth, newheight);
    
}


+(void) setVoiceMessageHeights: (SurespotMessage *)  message size: (CGSize) size {
    [message setRowPortraitHeight: 64];
    [message setRowLandscapeHeight: 64];
    DDLogVerbose(@"setting voice row height portrait %ld landscape %ld", (long)message.rowPortraitHeight, (long)message.rowLandscapeHeight);
    
}



+(void) startSpinAnimation: (UIView *) view {
    CABasicAnimation *rotation;
    rotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    rotation.fromValue = [NSNumber numberWithFloat:0];
    rotation.toValue = [NSNumber numberWithFloat:(2*M_PI)];
    rotation.duration = 1.1; // Speed
    rotation.repeatCount = HUGE_VALF; //
    [view.layer addAnimation:rotation forKey:@"spin"];
}

+(void) stopSpinAnimation: (UIView *) view {
    [view.layer removeAnimationForKey:@"spin"];
}

+(void) startPulseAnimation: (UIView *) view {
    CABasicAnimation *theAnimation;
    
    theAnimation=[CABasicAnimation animationWithKeyPath:@"opacity"];
    theAnimation.duration=1.0;
    theAnimation.repeatCount=HUGE_VALF;
    theAnimation.autoreverses=YES;
    theAnimation.fromValue=[NSNumber numberWithFloat:1.0];
    theAnimation.toValue=[NSNumber numberWithFloat:0.33];
    [view.layer addAnimation:theAnimation forKey:@"pulse"];
}

+(void) stopPulseAnimation: (UIView *) view {
    [view.layer removeAnimationForKey:@"pulse"];
}

+(NSString *) getMessageErrorText: (NSInteger) errorStatus mimeType: (NSString *) mimeType {
    NSString * statusText = nil;
    switch (errorStatus) {
        case 400:
            statusText = NSLocalizedString(@"error_message_generic",nil);
            break;
        case 403:
            statusText =  NSLocalizedString(@"message_error_unauthorized",nil);
            break;
        case 404:
            statusText =  NSLocalizedString(@"message_error_unauthorized",nil);
            break;
        case 429:
            statusText =  NSLocalizedString(@"error_message_throttled",nil);
            break;
        case 500:
        default:
            if ([mimeType isEqualToString:MIME_TYPE_TEXT] || [mimeType isEqualToString:MIME_TYPE_GIF_LINK]) {
                statusText =  NSLocalizedString(@"error_message_generic",nil);
            }
            else {
                if([mimeType isEqualToString:MIME_TYPE_IMAGE] || [mimeType isEqualToString:MIME_TYPE_M4A]) {
                    statusText = NSLocalizedString(@"error_message_resend",nil);
                }
            }
            
            break;
    }
    
    return statusText;
}


+(REMenu *) createMenu: (NSArray *) menuItems closeCompletionHandler: (void (^)(void))completionHandler {
    REMenu * menu = [[REMenu alloc] initWithItems:menuItems];
    menu.itemHeight = 40;
    menu.backgroundColor = [UIUtils surespotGrey];
    menu.imageOffset = CGSizeMake(10, 0);
    menu.textAlignment = NSTextAlignmentLeft;
    menu.textColor = [UIUtils surespotForegroundGrey];
    menu.highlightedTextColor = [UIColor whiteColor];
    menu.highlightedBackgroundColor = [UIUtils surespotTransparentBlue];
    menu.textShadowOffset = CGSizeZero;
    menu.highlightedTextShadowOffset = CGSizeZero;
    menu.textOffset =CGSizeMake(64,0);
    menu.font = [UIFont systemFontOfSize:18.0];
    menu.cornerRadius = 4;
    menu.bounce = NO;
    [menu setCloseCompletionHandler:completionHandler];
    return menu;
}

+(void) setLinkLabel:(TTTAttributedLabel *) label
            delegate: (id) delegate
           labelText: (NSString *) labelText
      linkMatchTexts: (NSArray *) linkMatchTexts
          urlStrings: (NSArray *) urlStrings  {
    
    label.delegate = delegate;
    label.text = labelText;
    
    if (linkMatchTexts.count != urlStrings.count) {
        NSException * e = [NSException exceptionWithName:@"IllegalArgumentException" reason:@"match and url count does not match" userInfo:nil];
        [e raise];
    }
    
    for (NSInteger i = 0;i<linkMatchTexts.count;i++) {
        NSString * linkMatchText = linkMatchTexts[i];
        NSString * urlString = [urlStrings[i] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        NSRange range = [label.text rangeOfString:linkMatchText];
        
        label.linkAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:[UIUtils surespotBlue], kCTForegroundColorAttributeName, [NSNumber numberWithInt:kCTUnderlineStyleSingle], kCTUnderlineStyleAttributeName, nil];
        
        [label addLinkToURL:[NSURL URLWithString:urlString] withRange:range];
    }
    
}


+(BOOL) getBoolPrefWithDefaultYesForUser: (NSString *) username key:(NSString *) key {
    //if the pref is not set then default to yes
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    key = [username stringByAppendingString:key];
    NSNumber * value = [defaults objectForKey:key];
    
    if (!value) return YES;
    
    return [value boolValue];
}

+(BOOL) getBoolPrefWithDefaultNoForUser: (NSString *) username key:(NSString *) key {
    //if the pref is not set then default to yes
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    key = [username stringByAppendingString:key];
    NSNumber * value = [defaults objectForKey:key];
    
    if (!value) return NO;
    
    return [value boolValue];
}

+(void) clearLocalCache {
    [FileController wipeAllState];
    [[[SDWebImageManager sharedManager] imageCache] clearMemory];
    [[[SDWebImageManager sharedManager] imageCache] clearDisk];
}

+ (NSString *) buildAliasStringForUsername: (NSString *) username alias: (NSString *) alias {
    return (alias ? [NSString stringWithFormat:@"%@ (%@)", alias, username] : username);
}

+ (NSString *)localizedStringForKey:(NSString *)key replaceValue:(NSString *)replaceValue bundle: (NSBundle *) bundle table: (NSString *) table {
    
    NSString *localizedString = [bundle localizedStringForKey:key value:@"" table:table];
    
    NSArray *preferredLanguagesIncDefault = [NSLocale preferredLanguages];
    NSString * preferredLanguage = [preferredLanguagesIncDefault objectAtIndex:0];
    NSDictionary *languageDic = [NSLocale componentsFromLocaleIdentifier:preferredLanguage];
    NSString *languageCode = [languageDic objectForKey:@"kCFLocaleLanguageCodeKey"];
    //
    //  DDLogInfo(@"localizedStringForKey: %@, preferred language: %@", key, languageCode);
    
    //if we found it or default language is english return it
    if ([languageCode isEqualToString:@"en"] || ![localizedString isEqualToString:key]) {
        //    DDLogInfo(@"localizedStringForKey: %@ found", key);
        return localizedString;
    }
    
    //didn't find it in default
    //iterate through preferred languages till we find a string
    //return english if we don't
    //already tested first language as it's the default so lop that off
    NSMutableArray *preferredLanguages = [NSMutableArray arrayWithArray:preferredLanguagesIncDefault];
    [preferredLanguages removeObjectAtIndex:0];
    
    //TODO revisit if we want to utilize country specific languages
    NSArray *supportedLanguages = [NSArray arrayWithObjects:@"en",@"de",@"it",@"es",@"fr", nil];
    
    for (NSString * language in preferredLanguages) {
        
        //add languages only
        
        NSDictionary *languageDic = [NSLocale componentsFromLocaleIdentifier:language];
        NSString *languageCode = [languageDic objectForKey:@"kCFLocaleLanguageCodeKey"];
        //    NSString *countryCode = [languageDic objectForKey:@"kCFLocaleCountryCodeKey"];
        
        //if we don't support the language don't bother looking
        if (![supportedLanguages containsObject:languageCode]) {
            //        DDLogInfo(@"localizedStringForKey: %@ no fallback translation for languageCode: %@",key, languageCode);
            continue;
        }
        
        NSString *fallbackBundlePath = [bundle pathForResource:languageCode ofType:@"lproj"];
        NSBundle *fallbackBundle = [NSBundle bundleWithPath:fallbackBundlePath];
        NSString *fallbackString = [fallbackBundle localizedStringForKey:key value:@"" table:table];
        if (fallbackString) {
            localizedString = fallbackString;
        }
        if (![localizedString isEqualToString:key]) {
            DDLogInfo(@"localizedStringForKey: %@ found fallback translation for languageCode: %@",key, languageCode);
            break;
        }
        
    }
    //if we didn't find it return english
    if ([localizedString isEqualToString:key]) {
        DDLogInfo(@"localizedStringForKey: %@ falling back to english", key);
        NSString *fallbackBundlePath = [bundle pathForResource:@"en" ofType:@"lproj"];
        NSBundle *fallbackBundle = [NSBundle bundleWithPath:fallbackBundlePath];
        NSString *fallbackString = [fallbackBundle localizedStringForKey:key value:replaceValue table:table];
        localizedString = fallbackString;
    }
    
    return localizedString;
    
}

+(BOOL) isBlackTheme {
    NSNumber * value = [[NSUserDefaults standardUserDefaults] objectForKey:@"pref_black_theme"];
    if (!value) return YES;
    return [value boolValue];
}

+(BOOL) confirmLogout {
    NSNumber * value = [[NSUserDefaults standardUserDefaults] objectForKey:@"pref_confirm_logout"];
    if (!value) return YES;
    return [value boolValue];
}

+(void) setTextFieldColors: (UITextField *) textField localizedStringKey: (NSString *) key {
    if ([self isBlackTheme]) {
        [textField setTextColor: [UIUtils surespotForegroundGrey]];
        [textField setAttributedPlaceholder: [[NSAttributedString alloc]
                                              initWithString:NSLocalizedString(key, nil)
                                              attributes:@{NSForegroundColorAttributeName:[UIUtils surespotForegroundGrey]}]];
        [textField.layer setBorderColor:[[UIUtils surespotGrey] CGColor]];
        [textField.layer setBorderWidth:1.0f];
    }
}

+(double) generateIntervalK: (NSInteger) k maxInterval: (NSInteger) maxInterval {
    NSInteger timerInterval = pow(2,k);
    
    if (timerInterval > maxInterval) {
        timerInterval = maxInterval;
    }
    
    double mult = ((double)arc4random() / ARC4RANDOM_MAX);
    double reconnectTime = mult * timerInterval;
    return reconnectTime;
}

+(void) getLocalImageFromAssetUrl: (NSString *) url callback:(CallbackBlock) callback {
    ALAssetsLibrary* assetsLibrary = [[ALAssetsLibrary alloc] init];
    [assetsLibrary assetForURL:[NSURL URLWithString: url] resultBlock:^(ALAsset *asset) {
        ALAssetRepresentation *rep = [asset defaultRepresentation];
        @autoreleasepool {
            CGImageRef iref = [rep fullResolutionImage];
            if (iref) {
                UIImage *image = [UIImage imageWithCGImage:iref
                                                     scale:1
                                               orientation:(UIImageOrientation)[rep orientation]];
                
                iref = nil;
                UIImage * scaledImage = [image imageScaledToMaxWidth:400 maxHeight:400];
                callback(scaledImage);
            }
        }
    } failureBlock:^(NSError *error) {
        callback(nil);
    }];
}

+(void) showPasswordAlertTitle: (NSString *) title
                       message: (NSString *) message
                    controller: (UIViewController *) controller
                      callback: (CallbackBlock) callback {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = NSLocalizedString(@"password", nil);
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.secureTextEntry = YES;
    }];
    
    UIAlertAction* okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action) {
                                                         NSArray * textfields = alert.textFields;
                                                         UITextField * passwordfield = textfields[0];
                                                         NSString * password = [passwordfield text];
                                                         callback(password);
                                                     }];
    
    [alert addAction:okAction];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel
                                                         handler:nil];
    
    [alert addAction:cancelAction];
    [controller presentViewController:alert animated:YES completion:nil];
}

@end
