//
//  NetworkController.h
//  surespot
//
//  Created by Adam on 6/16/13.
//  Copyright (c) 2013 surespot. All rights reserved.
//


#import "AFNetworking.h"
#import "AFHTTPSessionManager.h"
#import "SurespotConstants.h"

typedef void (^HTTPCookieSuccessBlock) (NSURLSessionTask* task, id responseObject, NSHTTPCookie * cookie);
typedef void (^HTTPSuccessBlock) (NSURLSessionTask* task, id responseObject);
typedef void (^HTTPFailureBlock) (NSURLSessionTask* task, NSError *error );

@interface NetworkController : AFHTTPSessionManager

-(NetworkController*)init: (NSString*) username;

-(void) loginWithUsername:(NSString*) username andPassword:(NSString *)password andSignature: (NSString *) signature successBlock:(HTTPCookieSuccessBlock) successBlock failureBlock: (HTTPFailureBlock) failureBlock;
-(void) createUser3WithUsername: (NSString *) username derivedPassword: (NSString *)derivedPassword dhKey: (NSString *)encodedDHKey dsaKey: (NSString *)encodedDSAKey authSig: (NSString *)authSig clientSig: (NSString *) clientSig successBlock:(HTTPCookieSuccessBlock)successBlock failureBlock: (HTTPFailureBlock) failureBlock;
-(void) getFriendsSuccessBlock:(HTTPSuccessBlock)successBlock failureBlock: (HTTPFailureBlock) failureBlock;
-(void) inviteFriend: (NSString *) friendname successBlock: (HTTPSuccessBlock)successBlock failureBlock: (HTTPFailureBlock) failureBlock ;
-(void) getKeyVersionForUsername:(NSString *)username successBlock:(HTTPSuccessBlock)successBlock failureBlock: (HTTPFailureBlock) failureBlock;
-(void) getPublicKeys2ForUsername:(NSString *)username andVersion:(NSString *)version successBlock:(HTTPSuccessBlock)successBlock failureBlock: (HTTPFailureBlock) failureBlock;
-(void) getMessageDataForUsername:(NSString *)username andMessageId:(NSInteger)messageId andControlId:(NSInteger) controlId successBlock:(HTTPSuccessBlock)successBlock failureBlock: (HTTPFailureBlock) failureBlock;
-(void) respondToInviteName:(NSString *) friendname action: (NSString *) action successBlock:(HTTPSuccessBlock)successBlock failureBlock: (HTTPFailureBlock) failureBlock;
-(void) getLatestDataSinceUserControlId: (NSInteger) latestUserControlId spotIds: (NSArray *) spotIds successBlock:(HTTPSuccessBlock)successBlock failureBlock: (HTTPFailureBlock) failureBlock;
-(void) logout;
-(void) deleteFriend:(NSString *) friendname successBlock:(HTTPSuccessBlock)successBlock failureBlock: (HTTPFailureBlock) failureBlock;
-(void) deleteMessageName:(NSString *) name serverId: (NSInteger) serverid successBlock:(HTTPSuccessBlock)successBlock failureBlock: (HTTPFailureBlock) failureBlock;
-(void) deleteMessagesUTAI:(NSInteger) utaiId name: (NSString *) name successBlock:(HTTPSuccessBlock)successBlock failureBlock: (HTTPFailureBlock) failureBlock;
-(void) userExists: (NSString *) username successBlock: (HTTPSuccessBlock)successBlock failureBlock: (HTTPFailureBlock) failureBlock;
-(void) setUnauthorized;
-(void) getEarlierMessagesForUsername: (NSString *) username messageId: (NSInteger) messageId successBlock:(HTTPSuccessBlock)successBlock failureBlock: (HTTPFailureBlock) failureBlock;
-(void) validateUsername: (NSString *) username password: (NSString *) password signature: (NSString *) signature successBlock:(HTTPSuccessBlock)successBlock failureBlock: (HTTPFailureBlock) failureBlock;
-(void) postFileStreamData: (NSData *) data
                ourVersion: (NSString *) ourVersion
             theirUsername: (NSString *) theirUsername
              theirVersion: (NSString *) theirVersion
                    fileid: (NSString *) fileid
                  mimeType: (NSString *) mimeType
              successBlock: ( void (^)(id JSON)) successBlock
              failureBlock: ( void (^)(NSURLResponse * response, NSError * error)) failureBlock;

-(void) setMessageShareable:(NSString *) name
                   serverId: (NSInteger) serverid
                  shareable: (BOOL) shareable
               successBlock:(HTTPSuccessBlock)successBlock
               failureBlock: (HTTPFailureBlock) failureBlock;

-(void) postFriendStreamData: (NSData *) data
                  ourVersion: (NSString *) ourVersion
               theirUsername: (NSString *) theirUsername
                          iv: (NSString *) iv
                successBlock: ( void (^)(id responseObject)) successBlock
                failureBlock: ( void (^)(NSURLResponse * response, NSError * error)) failureBlock;

-(void) getKeyTokenForUsername:(NSString*) username andPassword:(NSString *)password andSignature: (NSString *) signature
                  successBlock:(HTTPSuccessBlock)successBlock failureBlock: (HTTPFailureBlock) failureBlock;

-(void) updateKeys3ForUsername:(NSString *) username
                     password:(NSString *) password
                  publicKeyDH:(NSString *) pkDH
                 publicKeyDSA:(NSString *) pkDSA
                      authSig:(NSString *) authSig
                     tokenSig:(NSString *) tokenSig
                   keyVersion:(NSString *) keyversion
                    clientSig:(NSString *) clientSig
                successBlock:(HTTPSuccessBlock) successBlock
                 failureBlock:(HTTPFailureBlock) failureBlock;

-(void) getDeleteTokenForUsername:(NSString*) username andPassword:(NSString *)password andSignature: (NSString *) signature
                     successBlock:(HTTPSuccessBlock)successBlock failureBlock: (HTTPFailureBlock) failureBlock;

-(void) deleteUsername:(NSString *) username
              password:(NSString *) password
               authSig:(NSString *) authSig
              tokenSig:(NSString *) tokenSig
            keyVersion:(NSString *) keyversion
          successBlock:(HTTPSuccessBlock) successBlock
          failureBlock:(HTTPFailureBlock) failureBlock;

-(void) getPasswordTokenForUsername:(NSString*) username andPassword:(NSString *)password andSignature: (NSString *) signature
                       successBlock:(HTTPSuccessBlock)successBlock failureBlock: (HTTPFailureBlock) failureBlock;

-(void) changePasswordForUsername:(NSString *) username
                      oldPassword:(NSString *) password
                      newPassword:(NSString *) newPassword
                          authSig:(NSString *) authSig
                         tokenSig:(NSString *) tokenSig
                       keyVersion:(NSString *) keyversion
                     successBlock:(HTTPSuccessBlock) successBlock
                     failureBlock:(HTTPFailureBlock) failureBlock;

-(void) deleteFromCache: (NSURLRequest *) request;
-(NSString *) buildPublicKeyPathForUsername: (NSString *) username version: (NSString *) version;

-(void) getShortUrl:(NSString*) longUrl callback: (CallbackBlock) callback;

//-(void) uploadReceipt: (NSString *) receipt
//         successBlock:(HTTPSuccessBlock) successBlock
//         failureBlock: (HTTPFailureBlock) failureBlock;

-(void) setCookie: (NSHTTPCookie *) cookie;
-(BOOL) reloginSuccessBlock:(HTTPSuccessBlock) successBlock failureBlock: (HTTPFailureBlock) failureBlock;

-(void) assignFriendAlias:(NSString *) cipherAlias friendname: (NSString *) friendname version: (NSString *) version iv: (NSString *) iv successBlock:(HTTPSuccessBlock)successBlock failureBlock: (HTTPFailureBlock) failureBlock;
-(void) deleteFriendAlias:(NSString *) friendname successBlock:(HTTPSuccessBlock)successBlock failureBlock: (HTTPFailureBlock) failureBlock;
-(void) deleteFriendImage:(NSString *) friendname successBlock:(HTTPSuccessBlock)successBlock failureBlock: (HTTPFailureBlock) failureBlock;
-(void) updateSigs: (NSDictionary *) sigs;
-(void) sendMessages: (NSArray *) messages successBlock:(HTTPSuccessBlock)successBlock failureBlock: (HTTPFailureBlock) failureBlock;

@end
