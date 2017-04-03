//
//  ChatController.h
//  surespot
//
//  Created by Adam on 8/6/13.
//  Copyright (c) 2013 surespot. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChatDataSource.h"
#import "HomeDataSource.h"
#import "Friend.h"
#import "FriendDelegate.h"
#import "SurespotMessage.h"
#import "SurespotConstants.h"

@interface ChatController : NSObject <FriendDelegate>

-(ChatController *) init: (NSString *) username;

-(HomeDataSource *) getHomeDataSource;
-(ChatDataSource *) createDataSourceForFriendname: (NSString *) friendname availableId: (NSInteger) availableId availableControlId: (NSInteger) availableControlId callback:(CallbackBlock) createCallback;
-(ChatDataSource *) getDataSourceForFriendname: (NSString *) friendname;
-(void) destroyDataSourceForFriendname: (NSString *) friendname;
-(void) sendMessage: (NSString *) message toFriendname: (NSString *) friendname;
-(void) inviteUser: (NSString *) username;
-(void) setCurrentChat: (NSString *) username;
-(NSString *) getCurrentChat;
//-(void) login;
-(void) logout;
-(void) deleteFriend: (Friend *) thefriend;
-(void) deleteMessage: (SurespotMessage *) message;
-(void) pause;
-(void) resume;
-(void) deleteMessagesForFriend: (Friend *) afriend;
-(void) enqueueResendMessage: (SurespotMessage * ) message;
-(void) loadEarlierMessagesForUsername: username callback: (CallbackBlock) callback;
-(void) toggleMessageShareable: (SurespotMessage *) message;
-(void) resendFileMessage: (SurespotMessage *) message;
-(void) setFriendImageUrl: (NSString *) url forFriendname: (NSString *) name version: (NSString *) version iv: (NSString *) iv hashed:(BOOL)hashed;
-(void) clearData;
-(BOOL) isConnected;
-(void) assignFriendAlias: (NSString *) alias toFriendName: (NSString *) friendname  callbackBlock: (CallbackBlock) callbackBlock;
-(void) removeFriendAlias: (NSString *) friendname callbackBlock: (CallbackBlock) callbackBlock;
-(void) removeFriendImage: (NSString *) friendname callbackBlock: (CallbackBlock) callbackBlock;
@property (nonatomic, assign) BOOL hasInet;
@property (assign, atomic) BOOL paused;
-(void) disconnect;
-(void) reconnect;

@end
