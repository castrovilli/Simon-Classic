//
//  SimonViewController.m
//  Simon Classic
//
//  Created by Michael on 2/20/10.
//  Copyright 2010 Michael Sanders. All rights reserved.
//

#import "SimonViewController.h"
#import "SimonSettingsViewController.h"
#import "UIViewController+ModalToolbar.h"
#import "IFPreferencesModel.h"
#import "FlurryAPI.h"

NSString * const kSimonButtonSoundSetDefault = @"Default";
NSString * const kSimonButtonSoundSetMarimba = @"Marimba";

@implementation SimonViewController
@synthesize delegate;

@synthesize simonButtons;
@synthesize greenButton;
@synthesize redButton;
@synthesize blueButton;
@synthesize yellowButton;

@synthesize bgView;
@synthesize currentScoreLabel;
@synthesize bestScoreLabel;
@synthesize settingsButton;
@synthesize playButton;

- (id)init
{
    BOOL iPad = NO;

    // For reasons unbeknownst to me, the UI_USER_INTERFACE_IDIOM is undefined in
    // all SDKs outside of iOS 3.2 (the iPad SDK), making it impossible to detect
    // an iPad in a universal app without this ugly macro.
#ifdef UI_USER_INTERFACE_IDIOM
    iPad = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
#endif

    NSString *nibName = iPad ? @"Simon-iPad" : @"Simon";
    return [super initWithNibName:nibName bundle:nil];
}

- (void)viewDidLoad
{
    [settingsButton setTitle:NSLocalizedString(@"Settings", nil)];
    [playButton setTitle:NSLocalizedString(@"Play", nil)];

    simonButtons = [[NSArray alloc] initWithObjects:greenButton,
                                                    redButton,
                                                    blueButton,
                                                    yellowButton, nil];
    for (SoundButton *button in simonButtons) {
        [button setTarget:self action:@selector(tappedSimonButton:)];
    }

    if ([delegate respondsToSelector:@selector(simonViewControllerReady:)]) {
        [delegate simonViewControllerReady:self];
    }
}

- (void)dealloc
{
    [simonButtons release];
    [super dealloc];
}

#pragma mark UIBarButtonItem Actions

- (IBAction)showSettings:(id)sender
{
    SimonSettingsViewController *simonSettingsViewController =
        [[SimonSettingsViewController alloc] init];
    [simonSettingsViewController setTitle:[settingsButton title]];

    // A wrapper around NSUserDefaults that sets key based on the user input we
    // may receive.
    IFPreferencesModel *settingsModel = [IFPreferencesModel preferencesModel];
    [simonSettingsViewController setModel:settingsModel];

    NSString *backButtonName = NSLocalizedString(@"Back", nil);
    [self presentModalViewControllerWithToolbar:simonSettingsViewController
                                       animated:YES
                                 backButtonName:backButtonName];
    [simonSettingsViewController release];

    [FlurryAPI logEvent:@"LoadedSettings"];
}

#pragma mark -

#pragma mark UINavigationController delegate

// Called by the UINavigationController that presents the setting
// view controller.
//
// TODO: Is there a cleaner way (e.g. a delegate method or notification) to do this?
- (void)dismissModalViewControllerAnimated:(BOOL)animated
{
    [super dismissModalViewControllerAnimated:animated];

    // We are just going to assume that the view controller dismissed was the
    // settings pane, since that is all that gets presented by us.
    if ([delegate respondsToSelector:@selector(settingsChanged)]) {
        [delegate settingsChanged];
    }
}

#pragma mark -

#pragma mark UIViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    BOOL iPad = NO;

#ifdef UI_USER_INTERFACE_IDIOM
    iPad = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
#endif

    return orientation == UIInterfaceOrientationPortrait ||
           orientation == UIInterfaceOrientationPortraitUpsideDown ||
           (iPad && // Landscape mode is only supported on the iPad.
            (orientation == UIInterfaceOrientationLandscapeLeft ||
             orientation == UIInterfaceOrientationLandscapeRight));
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)orientation
                                         duration:(NSTimeInterval)duration
{
    BOOL iPad = NO;

#ifdef UI_USER_INTERFACE_IDIOM
    iPad = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
#endif

    if (iPad) {
        if (orientation == UIInterfaceOrientationLandscapeLeft ||
            orientation == UIInterfaceOrientationLandscapeRight) {
            [playButton setWidth:500.0];
            [settingsButton setWidth:500.0];

            [bgView setImage:[UIImage imageNamed:@"bg-iPad-Landscape.png"]];
        } else if (orientation == UIInterfaceOrientationPortrait ||
                   orientation == UIInterfaceOrientationPortraitUpsideDown) {
            [playButton setWidth:372.0];
            [settingsButton setWidth:372.0];

            [bgView setImage:[UIImage imageNamed:@"bg-iPad.png"]];
        }
    }
}

#pragma mark -

#pragma mark Sounds

- (void)setSoundsOfPrefix:(NSString *)prefix
{
    [greenButton setSoundToFileInBundle:[prefix stringByAppendingString:@"green"]
                                 ofType:@"caf"];
    [redButton setSoundToFileInBundle:[prefix stringByAppendingString:@"red"]
                               ofType:@"caf"];
    [blueButton setSoundToFileInBundle:[prefix stringByAppendingString:@"blue"]
                                ofType:@"caf"];
    [yellowButton setSoundToFileInBundle:[prefix stringByAppendingString:@"yellow"]
                                  ofType:@"caf"];
}

- (void)setSimonButtonSoundSet:(NSString *)soundSet
{
    if ([soundSet isEqualToString:kSimonButtonSoundSetDefault]) {
        DLog(@"Using default soundset");
        [self setSoundsOfPrefix:@"default_"];
    } else if ([soundSet isEqualToString:kSimonButtonSoundSetMarimba]) {
        DLog(@"Using marimba soundset");
        [self setSoundsOfPrefix:@"marimba_"];
    } else {
        DLog(@"Unrecognized soundset; removing sound");
        [simonButtons makeObjectsPerformSelector:@selector(removeSound)];
    }
}

#pragma mark -

#pragma mark SoundButton action

- (void)tappedSimonButton:(SoundButton *)button
{
    if ([delegate respondsToSelector:@selector(tappedSimonButton:)]) {
        [delegate tappedSimonButton:button];
    }
}

#pragma mark -

@end
