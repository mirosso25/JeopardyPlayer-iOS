//
//  JPNetworkManager.h
//  Jeopardy
//
//  Created by Parker Wightman on 12/16/12.
//  Copyright (c) 2012 Parker Wightman Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CocoaAsyncSocket/AsyncSocket.h>

@interface JPNetworkManager : NSObject <AsyncSocketDelegate>

@property (nonatomic, strong) void (^didSignIn)(NSInteger identifier);
@property (nonatomic, strong) void (^didBeginBuzzing)();
@property (nonatomic, strong) void (^didEndBuzzing)();
@property (nonatomic, strong) void (^didReceiveScoreUpdate)(NSArray *names, NSArray *scores);
@property (nonatomic, strong) void (^didReceiveDailyDouble)(NSInteger maxWager, NSInteger currentScore);
@property (nonatomic, strong) void (^didDisconnect)();
@property (nonatomic, strong) void (^didConnect)();

- (void) connectWithIp:(NSString *)ip username:(NSString *)username;
- (void) sendBuzzedIn;
- (void) sendDailyDoubleWager:(NSInteger)amount;
- (void) disconnect;
- (void) reconnect;
	
@end
