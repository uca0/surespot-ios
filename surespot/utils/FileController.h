//
//  FileController.h
//  surespot
//
//  Created by Adam on 7/22/13.
//  Copyright (c) 2013 surespot. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const IDENTITY_EXTENSION;

@interface FileController : NSObject
+(NSString *)   getHomeFilename: (NSString *) ourUsername;
+(NSString *)   getChatDataFilenameForSpot: (NSString *) spot ourUsername: (NSString *) ourUsername;
+(NSString *)   getAppSupportDir;
+(void)         wipeDataForUsername: (NSString *) username friendUsername: (NSString *) friendUsername;
+(NSString*)    getPublicKeyFilenameForOurUsername: (NSString *) ourUsername theirUsername: (NSString *) theirUsername version: (NSString *)version;
+(void)         wipeIdentityData: (NSString *) username preserveBackedUpIdentity: (BOOL) preserveBackedUpIdentity;
+(NSString *)   getIdentityDir;
+(NSString *)   getIdentityFile: (NSString *) username;
+(void)         saveSharedSecrets:(NSDictionary *) sharedSecretsDict forUsername: (NSString *) username withPassword: (NSString *) password;
+(NSDictionary *) loadSharedSecretsForUsername: (NSString *) username withPassword: (NSString *) password;
+(void)         deleteDataForUsername:  (NSString *)username;
+(NSData *)     gunzipIfNecessary: (NSData *) identityBytes;
+(NSString *)   getUploadsDir;
+(void)         saveLatestVersions:(NSDictionary *) latestVersionsDict forUsername: (NSString *) username;
+(NSDictionary *) loadLatestVersionsForUsername: (NSString *) username;
+(NSString*)    getCacheDir;
+(NSString *)   getBackgroundImageFilename: (NSString *) ourUsername;
+(void)         wipeAllState;
+(NSString *)   getIdentityFileDocuments: (NSString *) username;
+(NSString*)    getDocumentsDir;
+(void)         saveCookie:(NSHTTPCookie *) cookie forUsername: (NSString *) username withPassword: (NSString *) password;
+(NSHTTPCookie *) loadCookieForUsername: (NSString *) username password: password;
+(void)         deleteOldSecrets;
+(NSString *) getMessageQueueFilename: (NSString *) ourUsername;
@end
