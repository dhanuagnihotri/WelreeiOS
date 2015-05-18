//
//  DisplayContentSegue.m
//  WelreeiOS
//
//  Created by Dhanu Agnihotri on 5/15/15.
//  Copyright (c) 2015 Dhanu Agnihotri. All rights reserved.
//

#import "DisplayContentSegue.h"
#import "MenuViewController.h"
#import "MenuDrawViewController.h"

@implementation DisplayContentSegue


-(void)perform
{
    MenuDrawViewController* menuDrawViewController = ((MenuViewController*)self.sourceViewController).menuDrawViewController;
    menuDrawViewController.content = self.destinationViewController;
}

@end

