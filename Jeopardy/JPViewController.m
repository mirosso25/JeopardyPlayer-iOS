//
//  JPViewController.m
//  Jeopardy
//
//  Created by Parker Wightman on 12/15/12.
//  Copyright (c) 2012 Parker Wightman Inc. All rights reserved.
//

#import "JPViewController.h"
#import <MTBlockTableView/MTBlockTableView.h>
#import "JPNetworkManager.h"
#import <PSAlertView/PSPDFAlertView.h>
#import <PSAlertView/PSPDFActionSheet.h>

@interface JPViewController ()
@property (strong, nonatomic) IBOutlet MTBlockTableView *tableView;
@property (strong, nonatomic) IBOutlet UIButton *buzzButton;
@property (strong, nonatomic) JPNetworkManager *networkManager;
@property (strong, nonatomic) NSArray *names;
@property (strong, nonatomic) IBOutlet UILabel *connectedLabel;
@property (strong, nonatomic) IBOutlet UIButton *connectButton;
@property (strong, nonatomic) NSArray *scores;
@end

@implementation JPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	_names = @[];
	_scores = @[];
	
	[self presentConnectDialog];
	
	[_tableView setNumberOfSectionsInTableViewBlock:^NSInteger(UITableView *tableView) {
		return 1;
	}];
	
	[_tableView setNumberOfRowsInSectionBlock:^NSInteger(UITableView *tableView, NSInteger section) {
		return _names.count;
	}];
	
	[_tableView setCellForRowAtIndexPathBlock:^UITableViewCell *(UITableView *tableView, NSIndexPath *indexPath) {
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
		cell.textLabel.text = [_names objectAtIndex:indexPath.row];
		UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
		label.text = [_scores objectAtIndex:indexPath.row];
		cell.accessoryView = label;
		return cell;
	}];
	
	// Do any additional setup after loading the view, typically from a nib.
}

- (void) presentConnectDialog {
	if (_networkManager) [_networkManager disconnect];
	
	_networkManager = [[JPNetworkManager alloc] init];
	
	PSPDFAlertView *alertView = [[PSPDFAlertView alloc] initWithTitle:@"IP Address" message:@"What IP Address should I connect to?"];
	
	__block __weak typeof(alertView) blockAlertView;
	
	[alertView addButtonWithTitle:@"Cancel" block:^{
		[blockAlertView dismissWithClickedButtonIndex:0 animated:YES];
	}];
	
	[alertView addButtonWithTitle:@"Connect" block:^{
		PSPDFAlertView *nameAlertView = [[PSPDFAlertView alloc] initWithTitle:@"Team Name" message:@"What is your team name?"];
		NSString *host = [alertView textFieldAtIndex:0].text;
		[nameAlertView addButtonWithTitle:@"Send" block:^{
			[_networkManager connectWithIp:host username:[nameAlertView textFieldAtIndex:0].text];
		}];
		nameAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
		[nameAlertView show];
	}];
	
	
	alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
	[alertView textFieldAtIndex:0].keyboardType = UIKeyboardTypeNumbersAndPunctuation;
	
	[alertView show];
	
	[self setupNetworkBlocks];
	
}

- (void) setupNetworkBlocks {
	__block __weak typeof(self) blockSelf = self;
	_networkManager.didBeginBuzzing = ^{ _buzzButton.backgroundColor = [UIColor greenColor]; };
	_networkManager.didEndBuzzing = ^{ _buzzButton.backgroundColor = [UIColor redColor]; };
	_networkManager.didReceiveScoreUpdate = ^(NSArray *names, NSArray *scores){
		blockSelf.names = names;
		blockSelf.scores = scores;
		[blockSelf.tableView reloadData];
	};
	_networkManager.didReceiveDailyDouble = ^(NSInteger maxWager, NSInteger currentScore) {
		PSPDFAlertView *alertView = [[PSPDFAlertView alloc] initWithTitle:@"Daily Double!" message:[NSString stringWithFormat:@"How much do you wager? (Max is %d)", maxWager]];
		[alertView addButtonWithTitle:@"OK" block:^{
			[blockSelf.networkManager sendDailyDoubleWager:[[alertView textFieldAtIndex:0].text integerValue]];
		}];
		alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
		[alertView textFieldAtIndex:0].keyboardType = UIKeyboardTypeNumbersAndPunctuation;
		
		[alertView show];
	};
	
	_networkManager.didConnect = ^{ _connectedLabel.text = @"Connected!"; };
	_networkManager.didDisconnect = ^{ _connectedLabel.text = @"Disconnected! Try reconnecting."; };
}

- (IBAction)reconnectTapped:(id)sender {
	if (_networkManager) {
		PSPDFActionSheet *actionSheet = [[PSPDFActionSheet alloc] initWithTitle:@"Would you like to reconnect to the current server, or a new one?"];
		
		[actionSheet addButtonWithTitle:@"Reconnect" block:^{
			[_networkManager reconnect];
		}];
		
		[actionSheet addButtonWithTitle:@"New Connection" block:^{
			[self presentConnectDialog];
		}];
		
		[actionSheet addButtonWithTitle:@"Cancel" block:^{
		}];
		
		[actionSheet showInView:_connectButton];
	} else {
		[self presentConnectDialog];
	}
}

- (void) reconnect {
	[_networkManager reconnect];
}

- (IBAction)disconnectTapped:(id)sender {
	[_networkManager disconnect];
}

- (IBAction)buzzTapped:(id)sender {
	[_networkManager sendBuzzedIn];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
	[self setConnectedLabel:nil];
	[self setConnectButton:nil];
	[super viewDidUnload];
}
@end
