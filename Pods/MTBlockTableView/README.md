MTBlockTableView
================

An iOS Table View that uses block-based delegation instead of protocols. Try it, we dare you.

Installation
============

1. Preferred way is CocoaPods, just add `pod 'MTBlockTableView'` to your Podfile.
2. Copy `MTBlockTableView.h` and `MTBlockTableView.m` into your project from the `MTBlockTableView` target

Usage
=====

`MTBlockTableView` is an experimental, drop-in replacement for `UITableView` which uses blocks for all protocol methods:

```
- (void)viewDidLoad
{
    [super viewDidLoad];

    [_tableView setNumberOfRowsInSectionBlock:^NSInteger(UITableView *tableView, NSInteger section) {
        return 10;
    }];
    
    [_tableView setCellForRowAtIndexPathBlock:^UITableViewCell *(UITableView *tableView, NSIndexPath *indexPath) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
        
        cell.textLabel.text = [@(indexPath.row) stringValue];
        
        return cell;
    }];
}
```

Discussion
==========

The motivation for this library is a proof-of-concept that delegation through protocols could be replaced by delegation through blocks, and in many circumstances would be much move expressive and convenient for programmers. See [this blog post](http://mysteriousdevs.tumblr.com/post/29415817039/blocks-a-case-against-protocol-delegation) for more thorough examples.
