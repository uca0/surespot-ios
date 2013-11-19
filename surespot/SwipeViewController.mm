//
//  SwipeViewController.m
//  surespot
//
//  Created by Adam on 9/25/13.
//  Copyright (c) 2013 2fours. All rights reserved.
//

#import "SwipeViewController.h"
#import "NetworkController.h"
#import "ChatController.h"
#import "IdentityController.h"
#import "EncryptionController.h"
#import "MessageProcessor.h"
#import <UIKit/UIKit.h>
#import "MessageView.h"
#import "ChatUtils.h"
#import "HomeCell.h"
#import "SurespotControlMessage.h"
#import "FriendDelegate.h"
#import "UIUtils.h"
#import "LoginViewController.h"
#import "DDLog.h"
#import "REMenu.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_INFO;
#else
static const int ddLogLevel = LOG_LEVEL_OFF;
#endif

//#import <QuartzCore/CATransaction.h>

@interface SwipeViewController ()
@property (nonatomic, strong) dispatch_queue_t dateFormatQueue;
@property (nonatomic, strong) NSDateFormatter * dateFormatter;
@property (nonatomic, weak) HomeDataSource * homeDataSource;
@property (nonatomic, strong) UIViewPager * viewPager;
@property (nonatomic, strong) NSMutableDictionary * needsScroll;
@property (strong, readwrite, nonatomic) REMenu *menu;
@property (atomic, assign) NSInteger progressCount;
@property (nonatomic, weak) UIView * backImageView;
@end

@implementation SwipeViewController


- (void)viewDidLoad
{
    DDLogVerbose(@"swipeviewdidload %@", self);
    [super viewDidLoad];
    
    _needsScroll = [NSMutableDictionary new];
    
    _dateFormatQueue = dispatch_queue_create("date format queue", NULL);
    _dateFormatter = [[NSDateFormatter alloc]init];
    [_dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    
    _chats = [[NSMutableDictionary alloc] init];
    
    //configure swipe view
    _swipeView.alignment = SwipeViewAlignmentCenter;
    _swipeView.pagingEnabled = YES;
    _swipeView.wrapEnabled = NO;
    _swipeView.truncateFinalPage =NO ;
    _swipeView.delaysContentTouches = YES;
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7)
    {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    _textField.enablesReturnKeyAutomatically = NO;
    [self registerForKeyboardNotifications];
    
    
    UIButton *backButton = [[UIButton alloc] initWithFrame: CGRectMake(0, 0, 36.0f, 36.0f)];
    
    
    UIImage * backImage = [UIImage imageNamed:@"surespot_logo"];
    [backButton setBackgroundImage:backImage  forState:UIControlStateNormal];
    [backButton setContentMode:UIViewContentModeScaleAspectFit];
    _backImageView = backButton;
    
    [backButton addTarget:self action:@selector(backPressed) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    self.navigationItem.leftBarButtonItem = backButtonItem;
    
    UIBarButtonItem *anotherButton = [[UIBarButtonItem alloc] initWithTitle:@"menu" style:UIBarButtonItemStylePlain target:self action:@selector(showMenuMenu)];
    self.navigationItem.rightBarButtonItem = anotherButton;
    
    self.navigationItem.title = [[IdentityController sharedInstance] getLoggedInUser];
    
    
    //don't swipe to back stack
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
    
    
    //listen for  notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshMessages:) name:@"refreshMessages" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshHome:) name:@"refreshHome" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pushNotification:) name:@"pushNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deleteFriend:) name:@"deleteFriend" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startProgress:) name:@"startProgress" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopProgress:) name:@"stopProgress" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unauthorized:) name:@"unauthorized" object:nil];
    
    
    _homeDataSource = [[ChatController sharedInstance] getHomeDataSource];
    
    //show currently open tab immediately
    //    NSString * currentChat = _homeDataSource.currentChat;
    //    if (currentChat) {
    //        [self showChat:currentChat];
    //    }
    
    _viewPager = [[UIViewPager alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 30)];
    _viewPager.autoresizingMask =UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:_viewPager];
    _viewPager.delegate = self;
    
    
    //open active tabs, don't load data now well get it after connect
    for (Friend * afriend in [_homeDataSource friends]) {
        if ([afriend isChatActive]) {
            [self loadChat:[afriend name] show:NO availableId: -1 availableControlId:-1];
        }
    }
    
    //setup the button
    _theButton.layer.cornerRadius = 35;
    _theButton.layer.borderColor = [[UIUtils surespotBlue] CGColor];
    _theButton.layer.borderWidth = 3.0f;
    _theButton.backgroundColor = [UIColor whiteColor];
    _theButton.opaque = YES;
    
    [self updateTabChangeUI];
    
    [[ChatController sharedInstance] resume];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pause:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resume:) name:UIApplicationWillEnterForegroundNotification object:nil];
    
}

-(void) pause: (NSNotification *)  notification{
    DDLogVerbose(@"pause");
    [[ChatController sharedInstance] pause];
    
}


-(void) resume: (NSNotification *) notification {
    DDLogVerbose(@"resume");
    [[ChatController sharedInstance] resume];
    
}



- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}


// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    
    
    
    DDLogVerbose(@"keyboardWasShown");
    
    
    UITableView * tableView =(UITableView *)_friendView;
    
    KeyboardState * keyboardState = [[KeyboardState alloc] init];
    keyboardState.contentInset = tableView.contentInset;
    keyboardState.indicatorInset = tableView.scrollIndicatorInsets;
    
    
    UIEdgeInsets contentInsets =  tableView.contentInset;
    DDLogVerbose(@"pre move originy %f,content insets bottom %f, view height: %f", _textFieldContainer.frame.origin.y, contentInsets.bottom, tableView.frame.size.height);
    
    NSDictionary* info = [aNotification userInfo];
    CGRect keyboardRect = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGFloat keyboardHeight = [UIUtils keyboardHeightAdjustedForOrientation:keyboardRect.size];
    
    CGRect textFieldFrame = _textFieldContainer.frame;
    textFieldFrame.origin.y -= keyboardHeight;
    
    _textFieldContainer.frame = textFieldFrame;
    
    DDLogVerbose(@"keyboard height before: %f", keyboardHeight);
    
    keyboardState.keyboardHeight = keyboardHeight;
    
    
    DDLogVerbose(@"after move content insets bottom %f, view height: %f", contentInsets.bottom, tableView.frame.size.height);
    
    contentInsets.bottom = keyboardHeight + 2;
    tableView.contentInset = contentInsets;
    
    
    
    UIEdgeInsets scrollInsets =tableView.scrollIndicatorInsets;
    scrollInsets.bottom = keyboardHeight + 2;
    tableView.scrollIndicatorInsets = scrollInsets;
    
    
    @synchronized (_chats) {
        for (NSString * key in [_chats allKeys]) {
            UITableView * tableView = [_chats objectForKey:key];
            
            
            //  DDLogVerbose(@"saving content offset for %@, y: %f", key, tableView.contentOffset.y);
            //  [keyboardState.offsets setObject:[NSNumber numberWithFloat: tableView.contentOffset.y ] forKey:key];
            
            tableView.contentInset = contentInsets;
            tableView.scrollIndicatorInsets = scrollInsets;
            
            CGPoint newOffset = CGPointMake(0, tableView.contentOffset.y + keyboardHeight);
            [tableView setContentOffset:newOffset animated:NO];
            
            
        }
    }
    
    
    CGRect buttonFrame = _theButton.frame;
    buttonFrame.origin.y -= keyboardHeight;
    _theButton.frame = buttonFrame;
    
    self.keyboardState = keyboardState;
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    DDLogVerbose(@"keyboardWillBeHidden");
    [self handleKeyboardHide];
    
}

- (void) handleKeyboardHide {
    
    
    if (self.keyboardState) {
        
        
        CGRect textFieldFrame = _textFieldContainer.frame;
        textFieldFrame.origin.y += self.keyboardState.keyboardHeight;
        _textFieldContainer.frame = textFieldFrame;
        //reset all table view states
        
        _friendView.scrollIndicatorInsets = self.keyboardState.indicatorInset;
        _friendView.contentInset = self.keyboardState.contentInset;
        @synchronized (_chats) {
            
            for (NSString * key in [_chats allKeys]) {
                UITableView * tableView = [_chats objectForKey:key];
                tableView.scrollIndicatorInsets = self.keyboardState.indicatorInset;
                tableView.contentInset = self.keyboardState.contentInset;
                //  CGPoint oldOffset = CGPointMake(0, [[self.keyboardState.offsets objectForKey: key] floatValue]);
                //  DDLogVerbose(@"restoring content offset for %@, y: %f", key, oldOffset.y);
                //                [tableView setContentOffset:  oldOffset animated:YES];
                //    CGPoint newOffset = CGPointMake(0, tableView.contentOffset.y - self.keyboardState.keyboardHeight);
                //    [tableView setContentOffset:  newOffset animated:YES];
                //  [tableView layoutIfNeeded];
            }
        }
        CGRect buttonFrame = _theButton.frame;
        buttonFrame.origin.y += self.keyboardState.keyboardHeight;
        _theButton.frame = buttonFrame;
        
        // [self.keyboardState.offsets removeAllObjects];
        self.keyboardState = nil;
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    DDLogVerbose(@"will animate, setting table view framewidth/height %f,%f",_swipeView.frame.size.width,_swipeView.frame.size.height);
    
    //    _friendView.frame = _swipeView.frame;
    //       for (UITableView *tableView in [_chats allValues]) {
    //        tableView.frame=_swipeView.frame;
    //
    //    }
    
    //   [_swipeView updateLayout];
    //[_swipeView layOutItemViews];
    
}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
                                duration:(NSTimeInterval)duration
{
    DDLogVerbose(@"will rotate");
    _swipeView.suppressScrollEvent = YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromOrientation
{
    DDLogVerbose(@"did rotate");
    _swipeView.suppressScrollEvent= NO;
}

- (void) swipeViewDidScroll:(SwipeView *)scrollView {
    DDLogVerbose(@"swipeViewDidScroll");
    [_viewPager scrollViewDidScroll: scrollView.scrollView];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

-(void) switchToPageIndex:(NSInteger)page {
    [_swipeView scrollToPage:page duration:0.5f];
}

-(NSInteger) currentPage {
    return [_swipeView currentPage];
}

-(NSInteger) pageCount {
    return [self numberOfItemsInSwipeView:nil];
}

-(NSString * ) titleForLabelForPage:(NSInteger)page {
    DDLogVerbose(@"titleForLabelForPage %d", page);
    if (page == 0) {
        return @"home";
    }
    else {
        return [self nameForPage:page];    }
    
    return nil;
}

-(NSString * ) nameForPage:(NSInteger)page {
    
    if (page == 0) {
        return nil;
    }
    else {
        @synchronized (_chats) {
            if ([_chats count] > 0) {
                return [[self sortedChats] objectAtIndex:page-1];
            }
        }
    }
    
    return nil;
}

- (NSInteger)numberOfItemsInSwipeView:(SwipeView *)swipeView
{
    @synchronized (_chats) {
        
        return 1 + [_chats count];
    }
}

- (UIView *)swipeView:(SwipeView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view
{
    DDLogVerbose(@"view for item at index %d", index);
    if (index == 0) {
        if (!_friendView) {
            DDLogVerbose(@"creating friend view");
            
            _friendView = [[UITableView alloc] initWithFrame:swipeView.frame style: UITableViewStylePlain];
            [_friendView registerNib:[UINib nibWithNibName:@"HomeCell" bundle:nil] forCellReuseIdentifier:@"HomeCell"];
            _friendView.delegate = self;
            _friendView.dataSource = self;
            
            [self addLongPressGestureRecognizer:_friendView];
        }
        
        DDLogVerbose(@"returning friend view %@", _friendView);
        //return view
        return _friendView;
        
        
    }
    else {
        DDLogVerbose(@"returning chat view");
        @synchronized (_chats) {
            
            NSArray *keys = [self sortedChats];
            id aKey = [keys objectAtIndex:index -1];
            id anObject = [_chats objectForKey:aKey];
            
            return anObject;
        }
    }
    
}

-(void) addLongPressGestureRecognizer: (UITableView  *) tableView {
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(tableLongPress:) ];
    lpgr.minimumPressDuration = .7; //seconds
    [tableView addGestureRecognizer:lpgr];
    
}



- (void)swipeViewCurrentItemIndexDidChange:(SwipeView *)swipeView
{
    NSInteger currPage =swipeView.currentPage;
    //update page control page
    
    //   _pageControl.currentPage = swipeView.currentPage;
    //  [_swipeView reloadData];
    UITableView * tableview;
    if (currPage == 0) {
        [[ChatController sharedInstance] setCurrentChat:nil];
        tableview = _friendView;
    }
    else {
        @synchronized (_chats) {
            
            tableview = [self sortedValues][swipeView.currentPage-1];
            [[ChatController sharedInstance] setCurrentChat: [self sortedChats][currPage-1]];
        }
        
    }
    DDLogVerbose(@"swipeview index changed to %d", currPage);
    [tableview reloadData];
    
    //scroll if we need to
    NSString * name =[self nameForPage:currPage];
    @synchronized (_needsScroll ) {
        id needsit = [_needsScroll  objectForKey:name];
        if (needsit) {
            [self scrollTableViewToBottom:tableview];
            [_needsScroll removeObjectForKey:name];
        }
    }
    
    
    //update button
    [self updateTabChangeUI];
    
    
}

- (void)swipeView:(SwipeView *)swipeView didSelectItemAtIndex:(NSInteger)index
{
    DDLogVerbose(@"Selected item at index %i", index);
}



- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    DDLogVerbose(@"number of sections");
    // Return the number of sections.
    return 1;
}

- (NSInteger) indexForTableView: (UITableView *) tableView {
    if (tableView == _friendView) {
        return 0;
    }
    @synchronized (_chats) {
        NSArray * sortedChats = [self sortedChats];
        for (int i=0; i<[_chats count]; i++) {
            if ([_chats objectForKey:[sortedChats objectAtIndex:i]] == tableView) {
                return i+1;
                
            }
            
        }}
    
    return NSNotFound;
    
    
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSUInteger index = [self indexForTableView:tableView];
    
    
    if (index == NSNotFound) {
        index = [_swipeView indexOfItemViewOrSubview:tableView];
    }
    
    DDLogVerbose(@"number of rows in section, index: %d", index);
    // Return the number of rows in the section
    if (index == 0) {
        if (![[ChatController sharedInstance] getHomeDataSource]) {
            DDLogVerbose(@"returning 1 rows");
            return 1;
        }
        
        NSInteger count =[[[ChatController sharedInstance] getHomeDataSource].friends count];
        return count == 0 ? 1 : count;
    }
    else {
        NSInteger chatIndex = index-1;
        NSString * username;
        @synchronized (_chats) {
            
            NSArray *keys = [self sortedChats];
            if(chatIndex >= 0 && chatIndex < keys.count ) {
                id aKey = [keys objectAtIndex:chatIndex];
                username = aKey;
            }
        }
        if (username) {
            NSInteger count = [[ChatController sharedInstance] getDataSourceForFriendname: username].messages.count;
            return count == 0 ? 1 : count;
        }
    }
    
    return 1;
    
}



- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger index = [self indexForTableView:tableView];
    
    if (index == NSNotFound) {
        index = [_swipeView indexOfItemViewOrSubview:tableView];
    }
    
    //  DDLogVerbose(@"height for row, index: %d, indexPath: %@", index, indexPath);
    if (index == NSNotFound) {
        return 0;
    }
    
    
    
    
    if (index == 0) {
        
        NSInteger count =[[[ChatController sharedInstance] getHomeDataSource].friends count];
        //if count is 0 we returned 1 for 0 rows so
        if (count == 0) {
            return tableView.frame.size.height;
        }
        
        Friend * afriend = [[[ChatController sharedInstance] getHomeDataSource].friends objectAtIndex:indexPath.row];
        if ([afriend isInviter] ) {
            return 70;
        }
        else {
            return 44;
        }
        
    }
    else {
        @synchronized (_chats) {
            
            NSArray *keys = [self sortedChats];
            id aKey = [keys objectAtIndex:index -1];
            
            NSString * username = aKey;
            NSArray * messages =[[ChatController sharedInstance] getDataSourceForFriendname: username].messages;
            
            
            //if count is 0 we returned 1 for 0 rows so
            if (messages.count == 0) {
                return tableView.frame.size.height;
            }
            
            
            if (messages.count > 0 && (indexPath.row < messages.count)) {
                SurespotMessage * message =[messages objectAtIndex:indexPath.row];
                UIInterfaceOrientation  orientation = [[UIApplication sharedApplication] statusBarOrientation];
                NSInteger height = 44;
                if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
                    height = message.rowLandscapeHeight;
                }
                else {
                    height  = message.rowPortraitHeight;
                }
                
                if (height > 0) {
                    return height;
                }
                
                else {
                    return 44;
                }
            }
            else {
                return 0;
            }
        }
    }
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    
    NSInteger index = [self indexForTableView:tableView];
    
    if (index == NSNotFound) {
        index = [_swipeView indexOfItemViewOrSubview:tableView];
    }
    
    
    //  DDLogVerbose(@"cell for row, index: %d, indexPath: %@", index, indexPath);
    if (index == NSNotFound) {
        static NSString *CellIdentifier = @"Cell";
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        return cell;
        
    }
    
    
    
    if (index == 0) {
        NSInteger count =[[[ChatController sharedInstance] getHomeDataSource].friends count];
        
        if (count == 0) {
            static NSString *CellIdentifier = @"Cell";
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            cell.textLabel.text = @"you have no friends, now fuck off";
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.userInteractionEnabled = NO;
            return cell;
        }
        
        
        
        static NSString *CellIdentifier = @"HomeCell";
        HomeCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        // Configure the cell...
        Friend * afriend = [[[ChatController sharedInstance] getHomeDataSource].friends objectAtIndex:indexPath.row];
        cell.friendLabel.text = afriend.name;
        cell.friendName = afriend.name;
        cell.friendDelegate = [ChatController sharedInstance];
        
        BOOL isInviter =[afriend isInviter];
        
        [cell.ignoreButton setHidden:!isInviter];
        [cell.acceptButton setHidden:!isInviter];
        [cell.blockButton setHidden:!isInviter];
        
        cell.activeStatus.backgroundColor = [afriend isChatActive] ? [UIUtils surespotBlue] : [UIColor clearColor];
        
        if (afriend.isInvited || afriend.isInviter || afriend.isDeleted) {
            cell.friendStatus.hidden = NO;
            
            if (afriend.isDeleted) {
                cell.friendStatus.text = NSLocalizedString(@"friend_status_is_deleted", nil);
            }
            else {
                if (afriend.isInvited) {
                    cell.friendStatus.text = NSLocalizedString(@"friend_status_is_invited", nil);
                }
                else {
                    if (afriend.isInviter) {
                        cell.friendStatus.text = NSLocalizedString(@"friend_status_is_inviting", nil);
                    }
                    else {
                        cell.friendStatus.text = @"";
                    }
                }
            }
        }
        else {
            cell.friendStatus.hidden = YES;
        }
        
        
        UIView *bgColorView = [[UIView alloc] init];
        bgColorView.backgroundColor = [UIUtils surespotBlue];
        bgColorView.layer.masksToBounds = YES;
        cell.selectedBackgroundView = bgColorView;
        
        return cell;
    }
    else {
        id aKey;
        @synchronized (_chats) {
            NSArray *keys = [self sortedChats];
            aKey = [keys objectAtIndex:index -1];
        }
        NSString * username = aKey;
        NSArray * messages =[[ChatController sharedInstance] getDataSourceForFriendname: username].messages;
        
        if (messages.count == 0) {
            DDLogInfo(@"no chat messages");
            static NSString *CellIdentifier = @"Cell";
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            cell.textLabel.text = NSLocalizedString(@"no_messages", nil);
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.userInteractionEnabled = NO;
            return cell;
        }
        
        
        if (messages.count > 0 && indexPath.row < messages.count) {
            
            
            SurespotMessage * message =[messages objectAtIndex:indexPath.row];
            NSString * plainData = [message plainData];
            static NSString *OurCellIdentifier = @"OurMessageView";
            static NSString *TheirCellIdentifier = @"TheirMessageView";
            
            NSString * cellIdentifier;
            BOOL ours = NO;
            
            if ([ChatUtils isOurMessage:message]) {
                ours = YES;
                cellIdentifier = OurCellIdentifier;
                
            }
            else {
                cellIdentifier = TheirCellIdentifier;
            }
            MessageView *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
            if (!ours) {
                
                cell.messageSentView.backgroundColor = [UIUtils surespotBlue];
            }
            
            if (message.serverid <= 0) {
                cell.messageStatusLabel.text = NSLocalizedString(@"message_sending",nil);
                cell.messageLabel.text = plainData;
                
                if (ours) {
                    cell.messageSentView.backgroundColor = [UIColor blackColor];
                }
            }
            else {
                if (ours) {
                    cell.messageSentView.backgroundColor = [UIColor lightGrayColor];
                }
                
                if (!message.plainData) {
                    
                    cell.messageStatusLabel.text = NSLocalizedString(@"message_loading_and_decrypting",nil);
                    cell.messageLabel.text = @"";
                    
                }
                else {
                    
                    //   DDLogVerbose(@"setting text for iv: %@ to: %@", [message iv], plainData);
                    cell.messageLabel.text = plainData;
                    cell.messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
                    cell.messageStatusLabel.text = [self stringFromDate:[message dateTime]];
                    
                    if (ours) {
                        cell.messageSentView.backgroundColor = [UIColor lightGrayColor];
                    }
                    else {
                        cell.messageSentView.backgroundColor = [UIUtils surespotBlue];
                    }
                }
            }
            
            UIView *bgColorView = [[UIView alloc] init];
            bgColorView.backgroundColor = [UIUtils surespotBlue];
            bgColorView.layer.masksToBounds = YES;
            cell.selectedBackgroundView = bgColorView;
            
            return cell;
        }
        else {
            static NSString *CellIdentifier = @"Cell";
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            cell.userInteractionEnabled = NO;
            return cell;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger page = [_swipeView indexOfItemViewOrSubview:tableView];
    DDLogVerbose(@"selected, on page: %d", page);
    
    if (page == 0) {
        Friend * afriend = [[[ChatController sharedInstance] getHomeDataSource].friends objectAtIndex:indexPath.row];
        
        if (afriend && [afriend isFriend]) {
            NSString * friendname =[afriend name];
            [self showChat:friendname];
        }
        else {
            [_friendView deselectRowAtIndexPath:[_friendView indexPathForSelectedRow] animated:YES];
        }
    }
}

-(NSArray *) sortedChats {
    return [[_chats allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2];
    }];
}

-(NSArray *) sortedValues {
    NSArray * sortedKeys = [self sortedChats];
    NSMutableArray * sortedValues = [NSMutableArray new];
    for (NSString * key in sortedKeys) {
        [sortedValues addObject:[_chats objectForKey:key]];
    }
    return sortedValues;
}

-(void) loadChat:(NSString *) username show: (BOOL) show  availableId: (NSInteger) availableId availableControlId: (NSInteger) availableControlId {
    DDLogVerbose(@"entered");
    //get existing view if there is one
    UITableView * chatView;
    @synchronized (_chats) {
        chatView = [_chats objectForKey:username];
    }
    if (!chatView) {
        
        chatView = [[UITableView alloc] initWithFrame:_swipeView.frame];
        [chatView setDelegate:self];
        [chatView setDataSource: self];
        [chatView setScrollsToTop:NO];
        [chatView setDirectionalLockEnabled:YES];
        [self addLongPressGestureRecognizer:chatView];
        
        
        //create the data source
        [[ChatController sharedInstance] createDataSourceForFriendname:username availableId: availableId availableControlId:availableControlId];
        
        NSInteger index = 0;
        @synchronized (_chats) {
            
            [_chats setObject:chatView forKey:username];
            index = [[self sortedChats] indexOfObject:username] + 1          ;
            
        }
        
        DDLogVerbose(@"creatingindex: %d", index);
        
        //   [chatView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"ChatCell"];
        [chatView registerNib:[UINib nibWithNibName:@"OurMessageCell" bundle:nil] forCellReuseIdentifier:@"OurMessageView"];
        [chatView registerNib:[UINib nibWithNibName:@"TheirMessageCell" bundle:nil] forCellReuseIdentifier:@"TheirMessageView"];
        
        [_swipeView loadViewAtIndex:index];
        [_swipeView updateItemSizeAndCount];
        [_swipeView updateScrollViewDimensions];
        
        if (show) {
            [_swipeView scrollToPage:index duration:0.500];
            [[ChatController sharedInstance] setCurrentChat: username];
        }
        
    }
    
    else {
        if (show) {
            [[ChatController sharedInstance] setCurrentChat: username];
            NSInteger index;
            @synchronized (_chats) {
                index = [[self sortedChats] indexOfObject:username] + 1;
            }
            
            DDLogVerbose(@"scrolling to index: %d", index);
            [_swipeView scrollToPage:index duration:0.500];
        }
    }
}

-(void) showChat:(NSString *) username {
    DDLogVerbose(@"showChat, %@", username);
    
    Friend * afriend = [_homeDataSource getFriendByName:username];
    
    [self loadChat:username show:YES availableId:[afriend availableMessageId] availableControlId:[afriend availableMessageControlId]];
    [_textField resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self handleTextAction];
    return NO;
}

- (void) handleTextAction {
    NSString * text = _textField.text;
    
    if ([text length] > 0) {
        if (!_homeDataSource.currentChat) {

            NSString * loggedInUser = [[IdentityController sharedInstance] getLoggedInUser];
            if ([text isEqualToString:loggedInUser]) {
                [UIUtils showToastView:self.view key:@"friend_self_error"];
                return;
            }
            
            
            [[ChatController sharedInstance] inviteUser:text];
            //            [_textField resignFirstResponder];
            [_textField setText:nil];
            [self updateTabChangeUI];
        }
        else {
            [self send];
        }
    }
    else {
        [_textField resignFirstResponder];
    }
}


- (void) send {
    
    NSString* message = self.textField.text;
    
    if ([UIUtils stringIsNilOrEmpty:message]) return;
    id friendname;
    @synchronized (_chats) {
        NSArray *keys = [self sortedChats];
        friendname = [keys objectAtIndex:[_swipeView currentItemIndex] -1];
    }
    
    Friend * afriend = [[[ChatController sharedInstance] getHomeDataSource] getFriendByName:friendname];
    if ([afriend isDeleted]) {
        return;
    }
    
    
    [[ChatController sharedInstance] sendMessage: message toFriendname:friendname];
    
    [_textField setText:nil];
    
    [self updateTabChangeUI];
}

-(void) updateTabChangeUI {
    if (!_homeDataSource.currentChat) {
        [_theButton setImage:[UIImage imageNamed:@"ic_menu_invite"] forState:UIControlStateNormal];
        
    }
    else {
        Friend *afriend = [_homeDataSource getFriendByName:_homeDataSource.currentChat];
        if (afriend.isDeleted) {
            [_theButton setImage:[UIImage imageNamed:@"ic_menu_home"] forState:UIControlStateNormal];
            _textField.hidden = YES;
        }
        else {
            _textField.hidden = NO;
            if ([_textField.text length] > 0) {
                [_theButton setImage:[UIImage imageNamed:@"ic_menu_send"] forState:UIControlStateNormal];
            }
            else {
                [_theButton setImage:[UIImage imageNamed:@"ic_menu_home"] forState:UIControlStateNormal];
            }
        }
    }
}

- (void)refreshMessages:(NSNotification *)notification {
    NSString * username = notification.object;
    DDLogVerbose(@"username: %@, currentchat: %@", username, _homeDataSource.currentChat);
    
    if ([username isEqualToString: _homeDataSource.currentChat]) {
        
        UITableView * tableView;
        @synchronized (_chats) {
            tableView = [_chats objectForKey:username];
            
        }
        @synchronized (_needsScroll) {
            [_needsScroll removeObjectForKey:username];
        }
        
        if (tableView) {
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [tableView reloadData];
                [self scrollTableViewToBottom:tableView];
            });
            
            
        }
    }
    else {
        @synchronized (_needsScroll) {
            [_needsScroll setObject:@"yourmama" forKey:username];
        }
    }
}

- (void) scrollTableViewToBottom: (UITableView *) tableView {
    NSInteger numRows =[tableView numberOfRowsInSection:0];
    if (numRows > 0) {
        DDLogVerbose(@"scrolling to row: %d", numRows);
        NSIndexPath *scrollIndexPath = [NSIndexPath indexPathForRow:(numRows - 1) inSection:0];
        [tableView scrollToRowAtIndexPath:scrollIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

- (void)refreshHome:(NSNotification *)notification
{
    DDLogVerbose(@"refreshHome");
    
    if (_friendView) {
        [_friendView reloadData];
    }
    
}


-(void) removeFriend: (Friend *) afriend {
    [[[ChatController sharedInstance] getHomeDataSource] removeFriend:afriend withRefresh:YES];
}


- (NSString *)stringFromDate:(NSDate *)date
{
    __block NSString *string = nil;
    dispatch_sync(_dateFormatQueue, ^{
        string = [_dateFormatter stringFromDate:date ];
    });
    return string;
}



- (void)pushNotification:(NSNotification *)notification
{
    DDLogVerbose(@"pushNotification");
    NSDictionary * notificationData = notification.object;
    
    NSString * from =[ notificationData objectForKey:@"from"];
    if (![from isEqualToString:[[ChatController sharedInstance] getCurrentChat]]) {
        [UIUtils showNotificationToastView:[self view] data:notificationData];
    }
    
}

-(REMenu *) createMenuMenu {
    //menu menu
    
    NSMutableArray * menuItems = [NSMutableArray new];
    
    if (_homeDataSource.currentChat) {
        
        REMenuItem * closeTabItem = [[REMenuItem alloc] initWithTitle:NSLocalizedString(@"menu_close_tab", nil) image:[UIImage imageNamed:@"ic_menu_end_conversation"] highlightedImage:nil action:^(REMenuItem * item){
            [self closeTab];
        }];
        
        [menuItems addObject:closeTabItem];
        
        REMenuItem * deleteAllItem = [[REMenuItem alloc] initWithTitle:NSLocalizedString(@"menu_delete_all_messages", nil) image:[UIImage imageNamed:@"ic_menu_delete"] highlightedImage:nil action:^(REMenuItem * item){
            [[ChatController sharedInstance] deleteMessagesForFriend: [_homeDataSource getFriendByName:_homeDataSource.currentChat]];
            
        }];
        
        [menuItems addObject:deleteAllItem];
    }
    REMenuItem * logoutItem = [[REMenuItem alloc] initWithTitle:NSLocalizedString(@"logout", nil) image:[UIImage imageNamed:@"ic_lock_power_off"] highlightedImage:nil action:^(REMenuItem * item){
        [self logout];
        
    }];
    
    [menuItems addObject:logoutItem];
    
    return [self createMenu: menuItems];
}

-(REMenu *) createMenu: (NSArray *) menuItems {
    REMenu * menu = [[REMenu alloc] initWithItems:menuItems];
    menu.imageOffset = CGSizeMake(10, 0);
    menu.textAlignment = NSTextAlignmentLeft;
    menu.textColor = [UIColor whiteColor];
    menu.highlightedTextColor = [UIColor whiteColor];
    menu.highlightedBackgroundColor = [UIUtils surespotTransparentBlue];
    menu.textShadowOffset = CGSizeZero;
    menu.highlightedTextShadowOffset = CGSizeZero;
    menu.textOffset =CGSizeMake(64,0);
    menu.font = [UIFont systemFontOfSize:21.0];
    menu.cornerRadius = 2;
    
    [menu setCloseCompletionHandler:^{
        _menu = nil;
    }];
    
    return menu;
    
}


-(REMenu *) createHomeMenuFriend: (Friend *) thefriend {
    //home menu
    
    
    NSMutableArray * menuItems = [NSMutableArray new];
    
    
    if ([thefriend isChatActive]) {
        REMenuItem * closeTabHomeItem = [[REMenuItem alloc] initWithTitle:NSLocalizedString(@"menu_close_tab", nil) image:[UIImage imageNamed:@"ic_menu_end_conversation"] highlightedImage:nil action:^(REMenuItem * item){
            [self closeTabName: thefriend.name];
        }];
        [menuItems addObject:closeTabHomeItem];
    }
    
    
    REMenuItem * deleteAllHomeItem = [[REMenuItem alloc] initWithTitle:NSLocalizedString(@"menu_delete_all_messages", nil) image:[UIImage imageNamed:@"ic_menu_delete"] highlightedImage:nil action:^(REMenuItem * item){
        [[ChatController sharedInstance] deleteMessagesForFriend: thefriend];
        
        
    }];
    [menuItems addObject:deleteAllHomeItem];
    
    REMenuItem * deleteFriendItem = [[REMenuItem alloc] initWithTitle:NSLocalizedString(@"menu_delete_friend", nil) image:[UIImage imageNamed:@"ic_menu_delete"] highlightedImage:nil action:^(REMenuItem * item){
        [[ChatController sharedInstance] deleteFriend: thefriend];
    }];
    [menuItems addObject:deleteFriendItem];
    
    
    return [self createMenu: menuItems];
}

-(REMenu *) createChatMenuMessage: (SurespotMessage *) message {
    //home menu
    
    
    NSMutableArray * menuItems = [NSMutableArray new];
    
    //chat menu
    REMenuItem * deleteItem = [[REMenuItem alloc] initWithTitle:NSLocalizedString(@"menu_delete_message", nil) image:[UIImage imageNamed:@"ic_menu_delete"] highlightedImage:nil action:^(REMenuItem * item){
        
        
        [self deleteMessage: message];
        
    }];
    
    [menuItems addObject:deleteItem];
    
    
    return [self createMenu: menuItems];
}


-(void)tableLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    NSInteger _menuPage = _swipeView.currentPage;
    UITableView * currentView = _menuPage == 0 ? _friendView : [[self sortedValues] objectAtIndex:_menuPage-1];
    
    CGPoint p = [gestureRecognizer locationInView:currentView];
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        
        NSIndexPath *indexPath = [currentView indexPathForRowAtPoint:p];
        if (indexPath == nil) {
            DDLogVerbose(@"long press on table view at page %d but not on a row", _menuPage);
        }
        else {
            
            
            [currentView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            [self showMenuForPage: _menuPage indexPath: indexPath];
            DDLogInfo(@"long press on table view at page %d, row %d", _menuPage, indexPath.row);
        }
    }
}

-(void) deleteMessage: (SurespotMessage *) message {
    
    
    
    if (message) {
        DDLogVerbose(@"taking action for chat iv: %@, plaindata: %@", message.iv, message.plainData);
        
        
        [[ChatController sharedInstance] deleteMessage: message];
        
        
    }
    
    
}

-(void) showMenuMenu {
    if (!_menu) {
        _menu = [self createMenuMenu];
        if (_menu) {
            CGRect rect = CGRectMake(25, 0, self.view.frame.size.width                   - 50, self.view.frame.size.height);
            
            [_menu showFromRect:rect inView:self.view];
        }
    }
    
}

-(void) showMenuForPage: (NSInteger) page indexPath: (NSIndexPath *) indexPath {
    if (!_menu) {
        
        if (page == 0) {
            Friend * afriend = [[[ChatController sharedInstance] getHomeDataSource].friends objectAtIndex:indexPath.row];
            _menu = [self createHomeMenuFriend:afriend];
        }
        
        else {
            NSString * name = [self nameForPage:page];
            NSArray * messages =[[ChatController sharedInstance] getDataSourceForFriendname: name].messages;
            if (messages.count > 0) {
                
                
                SurespotMessage * message =[messages objectAtIndex:indexPath.row];
                
                _menu = [self createChatMenuMessage:message];
            }
        }
        
        if (_menu) {
            CGRect rect = CGRectMake(25, 0, self.view.frame.size.width - 50, self.view.frame.size.height);
            
            [_menu showFromRect:rect inView:self.view];
        }
    }
}

- (void)deleteFriend:(NSNotification *)notification
{
    NSArray * data =  notification.object;
    
    NSString * name  =[data objectAtIndex:0];
    BOOL ideleted = [[data objectAtIndex:1] boolValue];
    
    if (ideleted) {
        [self closeTabName:name];
    }
    else {
        [self updateTabChangeUI];
    }
}

-(void) closeTabName: (NSString *) name {
    if (name) {
        [[ChatController sharedInstance] destroyDataSourceForFriendname: name];
        [[_homeDataSource getFriendByName:name] setChatActive:NO];
        @synchronized (_chats) {
            [_chats removeObjectForKey:name];
        }
        [_swipeView reloadData];
        NSInteger page = [_swipeView currentPage];
        
        if ([name isEqualToString:_homeDataSource.currentChat]) {
            
            
            if (page >= _swipeView.numberOfPages) {
                page = _swipeView.numberOfPages - 1;
            }
            [_swipeView scrollToPage:page duration:0.2];
        }
        DDLogVerbose(@"page after close: %d", page);
        NSString * name = [self nameForPage:page];
        DDLogVerbose(@"name after close: %@", name);
        [_homeDataSource setCurrentChat:name];
        [_homeDataSource postRefresh];
        
    }
}

-(void) closeTab {
    [self closeTabName: _homeDataSource.currentChat];
}

-(void) logout {
    
    //blow the views away
    
    _friendView = nil;
    
    [[NetworkController sharedInstance] logout];
    [[ChatController sharedInstance] logout];
    @synchronized (_chats) {
        [_chats removeAllObjects];
    }
    [self performSegueWithIdentifier: @"returnToLogin" sender: self ];
}
- (IBAction)buttonTouchUpInside:(id)sender {
    if (_textField.text.length > 0) {
        [self handleTextAction];
    }else {
        [_swipeView scrollToPage:0 duration:0.5];
    }
    
}
- (void) backPressed {
    [_swipeView scrollToPage:0 duration:0.5];
}
- (IBAction)textFieldChanged:(id)sender {
    [self updateTabChangeUI];
}

- (void) startProgress: (NSNotification *) notification {
    
    if (_progressCount++ == 0) {
        [UIUtils startSpinAnimation: _backImageView];
    }
    
    DDLogInfo(@"progress count:%d", _progressCount);
}

-(void) stopProgress: (NSNotification *) notification {
    if (--_progressCount == 0) {
        [_backImageView.layer removeAllAnimations];
    }
    DDLogInfo(@"progress count:%d", _progressCount);
}


- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (!_homeDataSource.currentChat) {
        NSCharacterSet *alphaSet = [NSCharacterSet alphanumericCharacterSet];
        NSString * newString = [string stringByTrimmingCharactersInSet:alphaSet];
        if (![newString isEqualToString:@""]) {
            return NO;
        }
        
        NSUInteger newLength = [textField.text length] + [newString length] - range.length;
        return (newLength >= 20) ? NO : YES;
    }
    else {
        NSUInteger newLength = [textField.text length] + [string length] - range.length;
        return (newLength >= 1024) ? NO : YES;
    }
    
    return YES;
}


-(void) unauthorized: (NSNotification *) notification {
    DDLogInfo(@"unauthorized");
    [UIUtils showToastView:self.view key:@"unauthorized"];
    [self logout];
}


@end