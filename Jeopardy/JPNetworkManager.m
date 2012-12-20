//
//  JPNetworkManager.m
//  Jeopardy
//
//  Created by Parker Wightman on 12/16/12.
//  Copyright (c) 2012 Parker Wightman Inc. All rights reserved.
//

#import "JPNetworkManager.h"

typedef NS_ENUM(NSInteger, JPNetworkProtocol) {
	JPNetworkProtocolSignedIn = 9,
	JPNetworkProtocolBeginBuzzing = 5,
	JPNetworkProtocolBuzzIn = 10,
	JPNetworkProtocolStopBuzzing = 0,
	JPNetworkProtocolDailyDouble = 14,
	JPNetworkProtocolScoreUpdate = 12,
	JPNetworkProtocolReconnect = 18
};

@interface JPNetworkManager	()

@property (assign, nonatomic) NSInteger identifier;
@property (nonatomic, strong) AsyncSocket *socket;
@property (atomic, strong) NSArray *data;
@property (nonatomic, strong) NSLock *readDataLock;
@property (nonatomic, strong) NSString *hostIp;

@end

@implementation JPNetworkManager

- (id) init {
	self = [super init];
	if (self) {
		_socket = [[AsyncSocket alloc] initWithDelegate:self];
		_readDataLock = [[NSLock alloc] init];
		_data = @[];
	}
	
	return self;
}

- (void) connectWithIp:(NSString *)ip username:(NSString *)username {
	if (_socket.isConnected) return;
	
	NSError *error = nil;
	
	[_socket connectToHost:ip onPort:3366 error:&error];
	
	_hostIp = ip;
	
	if (error) {
		@throw error.localizedDescription;
	}
	
	[_socket writeData:[[NSString stringWithFormat:@"8\nplayer\n%@\n", username]  dataUsingEncoding:NSUTF8StringEncoding] withTimeout:300 tag:1];
}

- (void) disconnect {
	[_socket disconnect];
}

- (void) reconnect {
	if (_socket.isConnected) return;
	
	NSError *error = nil;
	
	[_socket connectToHost:_hostIp onPort:3366 error:&error];
	
	if (error) {
		@throw error.localizedDescription;
	}
	
	[_socket writeData:[[NSString stringWithFormat:@"%d\nplayer\n%d\n", JPNetworkProtocolReconnect, _identifier]  dataUsingEncoding:NSUTF8StringEncoding] withTimeout:300 tag:1];
}

- (void) sendBuzzedIn {
	[_socket writeData:[[NSString stringWithFormat:@"%d\n", JPNetworkProtocolBuzzIn] dataUsingEncoding:NSUTF8StringEncoding] withTimeout:300 tag:1];
}

- (void) sendDailyDoubleWager:(NSInteger)amount {
	[_socket writeData:[[NSString stringWithFormat:@"%d\n%d\n", JPNetworkProtocolDailyDouble, amount] dataUsingEncoding:NSUTF8StringEncoding] withTimeout:300 tag:1];
}

- (void) startReading {
	[_socket readDataWithTimeout:300 tag:1];
}

- (NSArray *) attemptParse:(NSArray *)data {
	NSInteger protocol = [[data objectAtIndex:0] integerValue];
	NSInteger unitsUsed = 0;
	NSInteger maxWager = 0;
	NSInteger currentScore = 0;
	NSMutableArray *playerNames = [@[] mutableCopy];
	NSMutableArray *playerScores = [@[] mutableCopy];
	NSInteger temp = 0;
	
	switch (protocol) {
		case JPNetworkProtocolSignedIn:
			if (data.count < 2) break;
			_identifier = [[data objectAtIndex:1] integerValue];
			unitsUsed += 2;
			NSLog(@"DB - Received Signed In, id: %d", _identifier);
			if (_didSignIn) _didSignIn(_identifier);
			break;
		case JPNetworkProtocolBeginBuzzing:
			unitsUsed += 1;
			NSLog(@"DB - Received Begin Buzzing");
			if (_didBeginBuzzing) _didBeginBuzzing();
			break;
		case JPNetworkProtocolStopBuzzing:
			unitsUsed += 1;
			NSLog(@"DB - Received Stop Buzzing");
			if (_didEndBuzzing) _didEndBuzzing();
			break;
		case JPNetworkProtocolDailyDouble:
			if (data.count < 3) break;
			maxWager = [[data objectAtIndex:1] integerValue];
			currentScore = [[data objectAtIndex:2] integerValue];
			unitsUsed += 3;
			NSLog(@"DB - Received Daily Double, wager: %d, score %d", maxWager, currentScore);
			if (_didReceiveDailyDouble) _didReceiveDailyDouble(maxWager, currentScore);
			break;
		case JPNetworkProtocolScoreUpdate:
			if (data.count < 4) break;
			temp = [[data objectAtIndex:1] integerValue];
			if (data.count < temp*2 + 2) break;
			unitsUsed += 2;
			for (NSInteger i = 0; i < temp; i++) {
				[playerNames addObject:[data objectAtIndex:2 + i*2]];
				[playerScores addObject:[data objectAtIndex:3 + i*2]];
				unitsUsed += 2;
			}
			NSLog(@"DB - Received score update:\nnames: %@\n scores:%@", playerNames, playerScores);
			if (_didReceiveScoreUpdate) _didReceiveScoreUpdate(playerNames, playerScores);
			
			
		default:
			break;
	}
	
	return [self array:data objectsFromIndex:unitsUsed];
}

- (NSArray *) array:(NSArray *)array objectsFromIndex:(NSInteger)index {
	NSMutableArray *objs = [@[] mutableCopy];
	
	for (NSInteger i = index; i < array.count; i++) {
		[objs addObject:[array objectAtIndex:i]];
	}
	
	return objs;
}

#pragma AsyncSocketDelegate

- (void) onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
	if (_didConnect) _didConnect();
	[self startReading];
}

- (void) onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
	NSLog(@"NetworkManager didReadData called: %@", [NSString stringWithUTF8String:[data bytes]]);
	
	NSString *string = [NSString stringWithUTF8String:[data bytes]];
	
	[_readDataLock lock];
	
	NSArray *newData = [self.data arrayByAddingObjectsFromArray:[string componentsSeparatedByString:@"\n"]];
	NSMutableArray *newFilteredData = [@[] mutableCopy];
	
	[newData enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		NSRange range = [obj rangeOfString:@"^\\s*" options:NSRegularExpressionSearch];
		NSString *result = [obj stringByReplacingCharactersInRange:range withString:@""];
		
		range = [obj rangeOfString:@"\\s*$" options:NSRegularExpressionSearch];
		result = [obj stringByReplacingCharactersInRange:range withString:@""];
		if (![result isEqualToString:@""]) {
			[newFilteredData addObject:obj];
		}
	}];
	
	NSInteger currentCount = newFilteredData.count;
	NSInteger newCount = 0;
	
	do {
		self.data = newFilteredData = [[self attemptParse:newFilteredData] mutableCopy];
		newCount = newFilteredData.count;
	} while (currentCount != newCount && newCount != 0);
	
	[_readDataLock unlock];
	[self startReading];
	
}

- (void) onSocketDidDisconnect:(AsyncSocket *)sock {
	if (_didDisconnect) _didDisconnect();
	NSLog(@"disconnected");
}





@end
