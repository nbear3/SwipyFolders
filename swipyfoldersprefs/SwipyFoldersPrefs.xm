#include "SwipyFoldersPrefs.h"

#import "SFSwitchTableCell.h"
#import "SFSliderTableCell.h"

@implementation SwipyFoldersPrefs

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"SwipyFoldersPrefs" target:self] retain];

		Class DisplayController = %c(PSUIDisplayController); // Appears to be iOS 9+.
		if (!DisplayController) { // iOS 8.
			DisplayController = %c(DisplayController);
		}
	}
	
	return _specifiers;
}

- (id)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];

	// Oh god the hacks. Remove the separator between the slider cell and the cell before it.
	// This hack is from http://stackoverflow.com/a/32818943.
	if ([cell isKindOfClass:%c(PSTableCell)]) {
		PSSpecifier *specifier = ((PSTableCell *) cell).specifier;
		NSString *identifier = specifier.identifier;

		if ([identifier isEqualToString:@"shortHoldTimeText"] || [identifier isEqualToString:@"doubleTapTimeText"] ) {
			CGFloat inset = cell.bounds.size.width * 10;
			cell.separatorInset = UIEdgeInsetsMake(0, inset, 0, 0);
			cell.indentationWidth = -inset;
			cell.indentationLevel = 1;
		} else if ([identifier isEqualToString:@"singleTapMethod"] || [identifier isEqualToString:@"swipeUpMethod"] || [identifier isEqualToString:@"swipeDownMethod"] || [identifier isEqualToString:@"doubleTapMethod"] || [identifier isEqualToString:@"shortHoldMethod"] || [identifier isEqualToString:@"forceTouchMethod"]) {
			NSUserDefaults *preferences = [[NSUserDefaults alloc] initWithSuiteName:@"nl.jessevandervelden.swipyfoldersprefs"];
			int method  = [preferences integerForKey:identifier];
			if(method == 5) {
				int customAppIndex  = [preferences integerForKey:[NSString stringWithFormat:@"%@CustomAppIndex", identifier]];
				cell.detailTextLabel.text = [NSString stringWithFormat:@"Custom: open app #%d", customAppIndex];
			}
		}

	}
	return cell;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	UITableView *tableView = MSHookIvar<UITableView*>(self, "_table");
	[tableView reloadData];


}

- (void)respring {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
	system("killall -9 SpringBoard");
#pragma GCC diagnostic pop
}

- (void)github {
		NSURL *githubURL = [NSURL URLWithString:@"https://github.com/megacookie/SwipyFolders"];
		[[UIApplication sharedApplication] openURL:githubURL];
}

- (void)contact {
	NSURL *url = [NSURL URLWithString:@"mailto:mail@jessevandervelden.nl?subject=SwipyFolders"];
	[[UIApplication sharedApplication] openURL:url];
}

- (void)paypal {
	NSURL *url = [NSURL URLWithString:@"https://paypal.me/JessevanderVelden"];
	[[UIApplication sharedApplication] openURL:url];
}

- (void)twitter {
	NSURL *url = [NSURL URLWithString:@"https://twitter.com/JesseVelden"];
	[[UIApplication sharedApplication] openURL:url];
}


@end

@implementation SFListItemsController


- (PSTableCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	PSTableCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];

	if(indexPath.row == 4) {
		NSUserDefaults *preferences = [[NSUserDefaults alloc] initWithSuiteName:@"nl.jessevandervelden.swipyfoldersprefs"];
		int customAppIndex  = [preferences integerForKey:[NSString stringWithFormat:@"%@CustomAppIndex", self.specifier.identifier]];
		cell.textLabel.text = [NSString stringWithFormat:@"Custom: open app #%d", customAppIndex];
	}

	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[super tableView:tableView didSelectRowAtIndexPath:indexPath]; //Instead of %orig();
	
	NSInteger selectedRow = indexPath.row;
	if(selectedRow == 4) {

		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"SwipyFolders"
			message:@"Enter an app's position in the folder. Example: the third app will be: 3"
			preferredStyle:UIAlertControllerStyleAlert];

		UIAlertAction *cancelAction = [UIAlertAction 
			actionWithTitle:@"Cancel"
			style:UIAlertActionStyleCancel
			handler:nil];

		UIAlertAction *okAction = [UIAlertAction 
			actionWithTitle:@"Enter"
			style:UIAlertActionStyleDefault
			handler:^(UIAlertAction *action) {

				NSString *appIndexText = alertController.textFields.firstObject.text;
				NSNumber *appIndex = @([appIndexText intValue]);
				if (!appIndex || appIndex.integerValue < 1) {
					UIAlertController * alert=   [UIAlertController alertControllerWithTitle:@"SwipyFolders" message:@"Please enter a valid number" preferredStyle:UIAlertControllerStyleAlert];
					UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:nil];
					[alert addAction:dismissAction];
					[self presentViewController:alert animated:YES completion:nil];
					return;
				}

				NSIndexPath *ip = [NSIndexPath indexPathForRow:4 inSection:0];
				UITableViewCell *cell = [tableView cellForRowAtIndexPath:ip];

				cell.textLabel.text = [NSString stringWithFormat:@"Custom: open app #%@", appIndexText]; 

				NSUserDefaults *preferences = [[NSUserDefaults alloc] initWithSuiteName:@"nl.jessevandervelden.swipyfoldersprefs"];
				[preferences setInteger:appIndex.integerValue forKey:[NSString stringWithFormat:@"%@CustomAppIndex", self.specifier.identifier]];
				[preferences synchronize];



				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
						// notify after file write
						CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge CFStringRef)[self.specifier propertyForKey:@"PostNotification"], NULL, NULL, YES);
				});

				

			}];

		[alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
			textField.placeholder = @"e.g. 3, 5, 99";
			[textField resignFirstResponder];
			[textField setKeyboardType:UIKeyboardTypeNumberPad];
			UIView *spacerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
			[textField setLeftViewMode:UITextFieldViewModeAlways];
			[textField setLeftView:spacerView];
		}];

		[alertController addAction:cancelAction];
		[alertController addAction:okAction];
		[self presentViewController:alertController animated:YES completion:nil];

		/*
		alert = [[UIAlertView alloc] initWithTitle:@"SwipyFolders"
													message:@"Enter an app's position in the folder. Example: the third app will be: 3"
													delegate:self
													cancelButtonTitle:@"Cancel"
													otherButtonTitles:@"Enter"
													, nil];
		alert.alertViewStyle = UIAlertViewStylePlainTextInput;
		
		[alert show];

		UITextField *indexPromptTextField = [alert textFieldAtIndex:0];
		[indexPromptTextField setDelegate:self];
		[indexPromptTextField resignFirstResponder];
		
		[indexPromptTextField setKeyboardType:UIKeyboardTypeNumberPad];
		indexPromptTextField.placeholder = @"e.g. 3, 5, 99";

		UIView *spacerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
		[indexPromptTextField setLeftViewMode:UITextFieldViewModeAlways];
		[indexPromptTextField setLeftView:spacerView];
		*/
	}
	
}

-(NSString *) addSuffixToNumber:(int) number {
    NSString *suffix;
    int ones = number % 10;
    int tens = (number/10) % 10;

    if (tens ==1) {
        suffix = @"th";
    } else if (ones ==1){
        suffix = @"st";
    } else if (ones ==2){
        suffix = @"nd";
    } else if (ones ==3){
        suffix = @"rd";
    } else {
        suffix = @"th";
    }

    NSString * completeAsString = [NSString stringWithFormat:@"%d%@", number, suffix];
    return completeAsString;
}


/*
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	if(buttonIndex != [alertView cancelButtonIndex]) {
		NSString *appIndexText = [alertView textFieldAtIndex:0].text;
		NSNumber *appIndex = @([appIndexText intValue]);

		if (!appIndex || appIndex.integerValue < 1) {
			[[[UIAlertView alloc] initWithTitle:@"SwipyFolders" message:@"This index is not a valid number!" delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
			return;
		}

		NSUserDefaults *preferences = [[NSUserDefaults alloc] initWithSuiteName:@"nl.jessevandervelden.swipyfoldersprefs"];
		[preferences setInteger:appIndex.integerValue forKey:[NSString stringWithFormat:@"%@AppIndex", self.specifier]];
		[preferences synchronize];

		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
				// notify after file write
				CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge CFStringRef)[self.specifier propertyForKey:@"PostNotification"], NULL, NULL, YES);
		});

	}
}
*/
@end
