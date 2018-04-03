/*
 Copyright (C) 2018  Matt Clarke
 
 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License along
 with this program; if not, write to the Free Software Foundation, Inc.,
 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

#import "XENHSetupHomescreenImportController.h"
#import "XENHResources.h"
#import "XENSetupFinalController.h"

@interface XENHSetupHomescreenImportController ()

@end

@implementation XENHSetupHomescreenImportController

-(NSString*)headerTitle {
    return @"Homescreen Setup";
}

-(NSString*)cellReuseIdentifier {
    return @"setupCell";
}

-(NSInteger)rowsToDisplay {
    NSInteger availableRows = 1;
    
    if ([self hasSBHTML]) availableRows++;
    
    return availableRows;
}

-(BOOL)hasSBHTML {
    return [[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/Preferences/com.groovycarrot.SBHTML.plist"];
}

-(UIImage*)footerImage {
    NSString *imagePath = [NSString stringWithFormat:@"/Library/PreferenceBundles/XenHTMLPrefs.bundle/Setup/Homescreen%@", [XENHResources imageSuffix]];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
        // Oh for crying out loud CoolStar
        imagePath = [NSString stringWithFormat:@"/bootstrap/Library/PreferenceBundles/XenHTMLPrefs.bundle/Setup/Homescreen%@", [XENHResources imageSuffix]];
    }
    
    UIImage *img = [UIImage imageWithContentsOfFile:imagePath];
    
    return [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

-(NSString*)footerTitle {
    return [XENHResources localisedStringForKey:@"What does Importing do?" value:@"What does Importing do?"];
}

-(NSString*)footerBody {
    return [XENHResources localisedStringForKey:@"Importing allows you to move existing Homescreen settings across to Xen HTML." value:@"Importing allows you to move existing Homescreen settings across to Xen HTML."];
}

-(NSString*)titleForCellAtIndex:(NSInteger)index {
    // Will remain in this order.
    int shown = 0;
    
    // Handle first row.
    if ([self hasSBHTML] && index == 1) {
        shown = 1;
    }
    
    switch (shown) {
        case 0:
            return [XENHResources localisedStringForKey:@"Setup Without Importing" value:@"Setup Without Importing"];
            break;
        case 1:
            return [XENHResources localisedStringForKey:@"Import from SBHTML" value:@"Import from SBHTML"];
            break;
            
        default:
            return @"";
            break;
    }
}

-(void)userDidSelectCellAtIndex:(NSInteger)index {
    // Setup as appropriate.
    int shown = 0;
    
    // Handle first row.
    if ([self hasSBHTML] && index == 1) {
        shown = 1;
    }
    
    switch (shown) {
        case 0:
            // No changes, so continue as normal!
            
            [XENHResources setPreferenceKey:@"SBHideDockBlur" withValue:[NSNumber numberWithBool:NO] andPost:NO];
            [XENHResources setPreferenceKey:@"SBAllowTouch" withValue:[NSNumber numberWithBool:YES] andPost:NO];
            [XENHResources setPreferenceKey:@"SBLocation" withValue:@"" andPost:YES];
            
            break;
            
        case 1: {
            // SBHTML
            NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.groovycarrot.SBHTML.plist"];
            
            NSString *activeTheme = [settings objectForKey:@"ActiveTheme"] ? [settings objectForKey:@"ActiveTheme"] : @"";
            BOOL dockhidden = [settings objectForKey:@"RemoveBlurredDock"] ? [[settings objectForKey:@"RemoveBlurredDock"] boolValue] : NO;
            
            // Sort out activeTheme
            if (![activeTheme isEqualToString:@""]) {
                activeTheme = [NSString stringWithFormat:@"/var/mobile/SBHTML/%@/Wallpaper.html", activeTheme];
            }
            
            // XXX: Now, we port to XenHTML.
            [XENHResources setPreferenceKey:@"SBHideDockBlur" withValue:[NSNumber numberWithBool:dockhidden] andPost:NO];
            [XENHResources setPreferenceKey:@"SBLocation" withValue:activeTheme andPost:NO];
            
            // Next, pull metadata for this one.
            NSMutableDictionary *metadata = [[XENHResources rawMetadataForHTMLFile:activeTheme] mutableCopy];
            
            NSMutableDictionary *widgetPrefs = [[XENHResources getPreferenceKey:@"widgetPrefs"] mutableCopy];
            if (!widgetPrefs) {
                widgetPrefs = [NSMutableDictionary dictionary];
            }
            
            [widgetPrefs setObject:metadata forKey:@"SBBackground"];
            
            [XENHResources setPreferenceKey:@"widgetPrefs" withValue:widgetPrefs andPost:YES];
            
            break;
        }
        default:
            break;
    }
    
    [XENHResources reloadSettings];
}

// This will either be the user selected cell, or whatever is currently checkmarked.
-(UIViewController*)controllerToSegueForIndex:(NSInteger)index {
    return [[XENHSetupFinalController alloc] init];
}

-(BOOL)shouldSegueToNewControllerAfterSelectingCell {
    return YES;
}

@end