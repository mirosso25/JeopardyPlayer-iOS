//
//  JPViewController.h
//  Jeopardy
//
//  Created by Parker Wightman on 12/15/12.
//  Copyright (c) 2012 Parker Wightman Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CocoaAsyncSocket/AsyncSocket.h>

@interface JPViewController : UIViewController <AsyncSocketDelegate>
- (void) reconnect;
@end
