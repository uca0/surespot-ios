//
//  ChatDataSource.h
//  surespot
//
//  Created by Adam on 8/6/13.
//  Copyright (c) 2013 surespot. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SurespotMessage.h"
#import "SurespotControlMessage.h"
#import "SurespotConstants.h"

@interface ChatDataSource : NSObject

@property (nonatomic, strong) NSMutableArray * messages;
@property (nonatomic, assign) NSInteger latestMessageId;
@property (nonatomic, assign) NSInteger latestHttpMessageId;
@property (nonatomic, assign) NSInteger latestControlMessageId;

-(ChatDataSource*)initWithTheirUsername:(NSString *) theirUsername ourUsername: (NSString * ) ourUsername availableId: (NSInteger) availableId availableControlId: (NSInteger) availableControlId callback: (CallbackBlock) initCallback;
-(BOOL) addMessage:(SurespotMessage *) message refresh:(BOOL) refresh;
-(void) postRefresh;
-(void) deleteMessage: (SurespotMessage *) message initiatedByMe: (BOOL) initiatedByMe;
-(SurespotMessage *) getMessageById: (NSInteger) serverId;
-(SurespotMessage *) getMessageByIv: (NSString *) iv;
-(void) deleteMessageByIv: (NSString *) iv;
-(BOOL) handleMessages: (NSArray *) messages;

-(void) handleControlMessages: (NSArray *) controlMessages;
-(void) handleControlMessage: (SurespotControlMessage *) message;
-(void) deleteAllMessagesUTAI: (NSInteger) messageId;
-(void) userDeleted;
-(void) loadEarlierMessagesCallback: (CallbackBlock) callback;
-(void) setMessageId: (NSInteger) serverid shareable: (BOOL) shareable;
@end
