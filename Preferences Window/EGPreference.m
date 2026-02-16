/*
	Copyright (C) 2003-2004 NAKAHASHI Ichiro
	Modified for Apple Silicon and modern macOS support by reivosar, 2026
*/

#import "EGCommon.h"
#import "EGPreference.h"
#import "EGController.h"
#import "HotkeyEvent.h"
#import "HotkeyCapture.h"

@implementation EGPreference

- (NSString *)_appNameAtIndex:(int)index
{
	NSMutableArray *appList =
			[[[appController eventKeyDefs] allKeys] mutableCopy];
	[appList removeObject:@"_Global"];
	[appList insertObject:@"_Global" atIndex:0];

	return [appList objectAtIndex:index];
}

- (void)_setupEventPrefsForApp:(NSString *)appName
{
	NSArray *keyDefs = [[appController eventKeyDefs] objectForKey:appName];
	int eventId, eventCount;
	
	HotkeyEvent *hotkey;
	NSPopUpButton *pseudoPop;
	NSTextField *label;
	HotkeyCapture *capture;
	NSTextField *menuLabel;
	HotkeyPseudoEventType et;
	NSMenu *menu;

	eventCount = (int)[keyDefs count];
	for (eventId = 0; eventId < eventCount; eventId++) {
		hotkey = [keyDefs objectAtIndex:eventId];
		pseudoPop = [pseudoEventPopUpArray objectAtIndex:eventId];
		label = [labelArray objectAtIndex:eventId];
		capture = [captureArray objectAtIndex:eventId];
		menuLabel = [menuLabelArray objectAtIndex:eventId];

		et = [hotkey pseudoEventType];
		
		menu = [[NSMenu alloc] initWithTitle:@"PopUp"];
		if (![appName isEqualToString:EGGlobalAppName]) {
			[[menu addItemWithTitle:
					NSLocalizedString(@"Use Global Setting", @"")
					action:nil keyEquivalent:@""] setTag:HotkeyInherit];
		}
		[[menu addItemWithTitle:NSLocalizedString(@"Disabled", @"")
				action:nil keyEquivalent:@""] setTag:HotkeyDisabled];
		[[menu addItemWithTitle:NSLocalizedString(@"Send Key Event", @"")
				action:nil keyEquivalent:@""] setTag:HotkeyNormalEvent];
		[[menu addItemWithTitle:NSLocalizedString(@"Pick A Menu Item", @"")
				action:nil keyEquivalent:@""] setTag:HotkeyMenuItem];
		[pseudoPop setMenu:menu];
		[pseudoPop selectItemAtIndex:[pseudoPop indexOfItemWithTag:et]];

		switch (et) {
		case HotkeyNormalEvent:
			[label setStringValue:NSLocalizedString(@"Key Sent", @"")];
			[capture setHidden:NO];
			[menuLabel setHidden:YES];
			[capture setHotkey:hotkey];
			break;
		case HotkeyMenuItem:
			[label setStringValue:NSLocalizedString(@"Menu Label", @"")];
			[capture setHidden:YES];
			[menuLabel setHidden:NO];
			[menuLabel setStringValue:[hotkey menuLabel]];
			break;
		default:
			[label setStringValue:@""];
			[capture setHidden:YES];
			[menuLabel setHidden:YES];
		}
	}
}

- (void)awakeFromNib
{
	pseudoEventPopUpArray = [[NSArray alloc] initWithObjects:
			rightPseudoPopUp, leftPseudoPopUp,
			horizontalPseudoPopUp, verticalPseudoPopUp,
			zPathPseudoPopUp, nPathPseudoPopUp,
			nil];

	labelArray = [[NSArray alloc] initWithObjects:
			rightLabel, leftLabel,
			horizontalLabel, verticalLabel,
			zPathLabel, nPathLabel,
			nil];
	
	captureArray = [[NSArray alloc] initWithObjects:
			rightCapture, leftCapture,
			horizontalCapture, verticalCapture,
			zPathCapture, nPathCapture,
			nil];
	
	menuLabelArray = [[NSArray alloc] initWithObjects:
			rightMenuLabel, leftMenuLabel,
			horizontalMenuLabel, verticalMenuLabel,
			zPathMenuLabel, nPathMenuLabel,
			nil];
	
	[gestureSizeMin setIntValue:[appController gestureSizeMin]];
	[gestureSizeMinLabel setIntValue:[appController gestureSizeMin]];

	[appTable registerForDraggedTypes:
			[NSArray arrayWithObject:NSPasteboardTypeFileURL]];

	[self _setupEventPrefsForApp:@"_Global"];
	// セレクタが見つからないエラー回避のため、メソッドを定義したので呼び出し可能
	[self notifWinPosChanged:nil];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	NSDictionary *keyDefs = [appController eventKeyDefs];
	NSMutableDictionary *keyDefsDict = [NSMutableDictionary dictionary];
	NSEnumerator *anEnum;
	NSString *key;
	
	anEnum = [[keyDefs allKeys] objectEnumerator];
	while (key = [anEnum nextObject]) {
		int idx;
		NSArray *hotkeys = [keyDefs objectForKey:key];
		NSMutableArray *appArray = [NSMutableArray array];
		for (idx = 0; idx < [hotkeys count]; idx++) {
			[appArray addObject:[[hotkeys objectAtIndex:idx] dictionary]];
		}
		[keyDefsDict setObject:appArray forKey:key];
	}
	
	[defaults setObject:keyDefsDict forKey:@"EventKeyDefs"];
	[defaults setInteger:[gestureSizeMin intValue] forKey:@"GestureSizeMin"];
	[defaults synchronize];
	
	if (![defaults boolForKey:@"ShowStatusBarMenu"])
		[appController hideStatusBarMenu];
}

- (IBAction)openPreferenceWindow:(id)sender
{
	[NSApp activateIgnoringOtherApps:YES];
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"ShowStatusBarMenu"])
		[appController showStatusBarMenu];
	[preferenceWindow makeKeyAndOrderFront:self];
}

- (IBAction)pseudoEventPopUpSelected:sender
{
	int tableRow = (int)[appTable selectedRow];
	NSString *appName = [self _appNameAtIndex:tableRow];
	NSArray *keyDefs = [[appController eventKeyDefs] objectForKey:appName];
	int eventId = (int)[sender tag];
	HotkeyEvent *hotkey = [keyDefs objectAtIndex:eventId];
	HotkeyPseudoEventType et = (HotkeyPseudoEventType)[[sender selectedItem] tag];
	[hotkey setPseudoEventType:et];
	[self _setupEventPrefsForApp:appName];
}

- (IBAction)menuLabelChanged:sender
{
	int tableRow = (int)[appTable selectedRow];
	NSString *appName = [self _appNameAtIndex:tableRow];
	NSArray *keyDefs = [[appController eventKeyDefs] objectForKey:appName];
	int eventId = (int)[sender tag];
	HotkeyEvent *hotkey = [keyDefs objectAtIndex:eventId];
	[hotkey setMenuLabel:[sender stringValue]];
}

- (void)_addEventDefForAppPath:(NSString *)appPath
{
	NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
	NSMutableDictionary *hotkeyDefRoot = [appController eventKeyDefs];
	NSArray *globalHotkeyDef = [hotkeyDefRoot objectForKey:@"_Global"];
	NSArray *newHotkeyDef = [HotkeyEvent hotkeyArrayWithArray:
			[def objectForKey:@"DefaultHotkeyDefForAnApplication"]
				count:(int)[globalHotkeyDef count]
				global:NO];
	[hotkeyDefRoot setObject:newHotkeyDef forKey:appPath];
}

- (IBAction)addApplication: (id)sender
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setAllowsMultipleSelection:YES];
	[panel setCanChooseFiles:YES];
	[panel setDirectoryURL: [NSURL fileURLWithPath: @"/Applications"]];
	[panel setAllowedFileTypes: @[@"app"]];
	[panel beginSheetModalForWindow: [sender window] completionHandler:^(NSInteger result) {
		if (result == NSModalResponseOK) {
			for (NSURL* url in panel.URLs) {
				[self _addEventDefForAppPath: [url path]];
			}
			[appTable reloadData];
			[self tableSelected:appTable];
		}
	}];
}

- (IBAction)removeApplication:(id)sender
{
	int row = (int)[appTable selectedRow];
	NSString *appName = [[[[NSFileManager defaultManager] componentsToDisplayForPath:[self _appNameAtIndex:row]] lastObject] copy];

	NSAlert* alert = [[NSAlert alloc] init];
	[alert setMessageText: NSLocalizedString(@"Remove Application", @"")];
	[alert setInformativeText: [NSString stringWithFormat: NSLocalizedString(@"Remove %@?", @""), appName]];
	[alert addButtonWithTitle: NSLocalizedString(@"Yes", @"")];
	[alert addButtonWithTitle: NSLocalizedString(@"Cancel", @"")];
	[alert beginSheetModalForWindow: preferenceWindow completionHandler: ^(NSModalResponse returnCode) {
		if (returnCode == NSAlertFirstButtonReturn) {
			int r = (int)[appTable selectedRow];
			NSString *name = [self _appNameAtIndex:r];
			[[appController eventKeyDefs] removeObjectForKey:name];
			[appTable reloadData];
			[self tableSelected:appTable];
		}
	}];
}

- (IBAction)tableSelected:(id)sender
{
	int row = (int)[sender selectedRow];
	if (row < 0) return;
	NSString *appName = [self _appNameAtIndex:row];
	[removeButton setEnabled:![appName isEqualToString:@"_Global"]];
	[self _setupEventPrefsForApp:appName];
}

- (IBAction)gestureSizeChanged:sender
{
	[appController setGestureSizeMin:[sender intValue]];
}

// ヘッダに定義されていたので追加
- (IBAction)notifWinPosChanged:sender
{
    // プレビューの更新ロジックなどが必要ならここに書く
}

// テーブル表示用メソッドの実装
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
    return (int)[[appController eventKeyDefs] count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    NSString *path = [self _appNameAtIndex:row];
    if ([path isEqualToString:@"_Global"]) return @"Global";
    return [[NSFileManager defaultManager] displayNameAtPath:path];
}

- (void)appTableView:(EGAppTableView *)view addApplicationPath:(NSString *)path
{
    [self _addEventDefForAppPath:path];
    [appTable reloadData];
}

@end
