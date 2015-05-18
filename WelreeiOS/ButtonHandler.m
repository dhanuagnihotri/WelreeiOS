//
//  ButtonHandler.m
//  WelreeiOS
//
//  Created by Dhanu Agnihotri on 5/18/15.
//  Copyright (c) 2015 Dhanu Agnihotri. All rights reserved.
//

#import "ButtonHandler.h"

@implementation ButtonHandler

-(IBAction)handleButton:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"notifyButtonPressed" object:self];
}

@end
