//
//  LoginViewController.m
//  WelreeiOS
//
//  Created by Dhanu Agnihotri on 4/29/15.
//  Copyright (c) 2015 Dhanu Agnihotri. All rights reserved.
//

#import "LoginViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginButton.h>

#import "AppDelegate.h"

@interface LoginViewController () <FBSDKLoginButtonDelegate>
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *signupButton;
@property (weak, nonatomic) IBOutlet FBSDKLoginButton *FBLoginButton;
@property (strong, nonatomic) NSURLSession *session;
@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if ([FBSDKAccessToken currentAccessToken]) {
        // User is logged in, do work such as go to next view controller.
        NSLog(@"User is already logged in");
    }
    
//    FBSDKLoginButton *loginButton = [[FBSDKLoginButton alloc] init];
    self.FBLoginButton.readPermissions = @[@"public_profile",@"user_friends"];
//    loginButton.center = self.view.center;
//    [self.view addSubview:loginButton];
    self.FBLoginButton.delegate = self;
    
    self.loginButton.layer.borderColor = [UIColor blackColor].CGColor;
    self.loginButton.layer.borderWidth = 1.0;
    self.loginButton.layer.cornerRadius = 5;
    
    self.signupButton.layer.borderColor = [UIColor blackColor].CGColor;
    self.signupButton.layer.borderWidth = 1.0;
    self.signupButton.layer.cornerRadius = 5;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)signupPressed:(id)sender {
    NSLog(@"Signup a new user");
    /*curl -X POST -H "Content-Type:application/json" -d '{"email":"xyz@welree.com","password":"xyz@xyz","first_name":"xyz","last_name":"xyz"}' http://dev.welree.com/api/v1/user/signup/
     */
    
    NSError *error;
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    NSURL *url = [NSURL URLWithString:@"http://dev.welree.com/api/v1/user/signup/"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:60.0];
    
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
//    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    [request setHTTPMethod:@"POST"];
    NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: @"iosxyz@welree.com", @"email",
                             @"iosxyz@xyz", @"password",
                             @"iosxyz", @"first_name",
                             @"iosxyz", @"last_name",
                             nil];
    NSData *postData = [NSJSONSerialization dataWithJSONObject:mapData options:0 error:&error];
    [request setHTTPBody:postData];
    
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if(error == nil)
        {
            NSLog(@"Signup was successful");
        }
        else
            NSLog(@"Error %@",[error userInfo]);
        
    }];
    
    [postDataTask resume];
    
}

- (IBAction)loginPressed:(id)sender {
    
    NSLog(@"login a user");
    /*curl -c cookies.txt -X POST -H "Content-Type:application/json" -d '{"username":"dhanuagnihotri@gmail.com","password”:”test123"}' http://dev.welree.com/api/v1/user/login/     */
    
    NSError *error;
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    self.session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    NSURL *url = [NSURL URLWithString:@"http://dev.welree.com/api/v1/user/login/"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:60.0];
    
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    //    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    [request setHTTPMethod:@"POST"];
    NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: @"dhanuagnihotri@gmail.com", @"username",
                             @"test123", @"password",
                             nil];
    NSData *postData = [NSJSONSerialization dataWithJSONObject:mapData options:0 error:&error];
    [request setHTTPBody:postData];
   
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request
                                                                 completionHandler:^(NSData *data,
                                                                                     NSURLResponse *response,
                                                                                     NSError *error)
    {
     
        if(error == nil)
        {
            NSLog(@"login was successful");
        }
        else
            NSLog(@"Error %@",[error userInfo]);
        
        NSHTTPURLResponse *httpResp = (NSHTTPURLResponse*) response;
        
        NSArray *cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:[httpResp allHeaderFields] forURL:[response URL]];
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookies:cookies forURL:[response URL] mainDocumentURL:nil];
        for (NSHTTPCookie *cookie in cookies) {
            NSMutableDictionary *cookieProperties = [NSMutableDictionary dictionary];
            [cookieProperties setObject:cookie.name forKey:NSHTTPCookieName];
            [cookieProperties setObject:cookie.value forKey:NSHTTPCookieValue];
            [cookieProperties setObject:cookie.domain forKey:NSHTTPCookieDomain];
            [cookieProperties setObject:cookie.path forKey:NSHTTPCookiePath];
            [cookieProperties setObject:[NSNumber numberWithInt:cookie.version] forKey:NSHTTPCookieVersion];
            
            [cookieProperties setObject:[[NSDate date] dateByAddingTimeInterval:31536000] forKey:NSHTTPCookieExpires];
            
            NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:cookieProperties];
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
            NSLog(@"name:%@ value:%@", cookie.name, cookie.value);
        }
        
        //Try to get some data at this point
        [self getData];
    }];
    
    
    [task resume];

}

-(void)getData
{
    NSLog(@"Get data for logged in user");
    /*curl -b cookies.txt -i -H "Accept: application/json" "http://dev.welree.com/api/v1/collection/“      */
    
    NSURL *url = [NSURL URLWithString:@"http://dev.welree.com/api/v1/collection/"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:60.0];
    
    //[request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    [request setHTTPMethod:@"GET"];
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request
                                                 completionHandler:^(NSData *data,
                                                                     NSURLResponse *response,
                                                                     NSError *error)
                                  {
                                      
                                      if(error == nil)
                                      {
                                          NSLog(@"got data successfully");
                                          NSString * text = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
                                          NSLog(@"Data = %@",text);
                                      }
                                      else
                                          NSLog(@"Error %@",[error userInfo]);
                                  }];
    [task resume];
}

- (void)  loginButton:(FBSDKLoginButton *)loginButton
didCompleteWithResult:(FBSDKLoginManagerLoginResult *)result
                error:(NSError *)error;
{
    if (error) {
        NSLog(@"login error: %@", error);
        NSString *alertMessage = error.userInfo[FBSDKErrorLocalizedDescriptionKey] ?: @"There was a problem logging in. Please try again later.";
        NSString *alertTitle = error.userInfo[FBSDKErrorLocalizedTitleKey] ?: @"Oops";
        [[[UIAlertView alloc] initWithTitle:alertTitle
                                    message:alertMessage
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    } else {
        NSLog(@"Logged in successfully");
    }
}

- (void)loginButtonDidLogOut:(FBSDKLoginButton *)loginButton
{
    NSLog(@"Button used to logout");
    
    //clear out cookies on logout
    //    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    //    for (NSHTTPCookie *each in cookieStorage.cookies) {
    //        [cookieStorage deleteCookie:each];
    //    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
