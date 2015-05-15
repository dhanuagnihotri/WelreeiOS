// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "FBSDKInternalUtility.h"

#import <sys/time.h>

#import <mach-o/dyld.h>

#import "FBSDKCoreKit+Internal.h"
#import "FBSDKError.h"
#import "FBSDKMacros.h"
#import "FBSDKSettings.h"
#import "FBSDKUtility.h"

typedef NS_ENUM(NSUInteger, FBSDKInternalUtilityVersionMask)
{
  FBSDKInternalUtilityMajorVersionMask = 0xFFFF0000,
  //FBSDKInternalUtilityMinorVersionMask = 0x0000FF00, // unused
  //FBSDKInternalUtilityPatchVersionMask = 0x000000FF, // unused
};

typedef NS_ENUM(NSUInteger, FBSDKInternalUtilityVersionShift)
{
  FBSDKInternalUtilityMajorVersionShift = 16,
  //FBSDKInternalUtilityMinorVersionShift = 8, // unused
  //FBSDKInternalUtilityPatchVersionShift = 0, // unused
};

@implementation FBSDKInternalUtility

#pragma mark - Class Methods

+ (NSString *)appURLScheme
{
  NSString *appID = ([FBSDKSettings appID] ?: @"");
  NSString *suffix = ([FBSDKSettings appURLSchemeSuffix] ?: @"");
  return [[NSString alloc] initWithFormat: @"fb%@%@", appID, suffix];
}

+ (NSURL *)appURLWithHost:(NSString *)host
                     path:(NSString *)path
          queryParameters:(NSDictionary *)queryParameters
                    error:(NSError *__autoreleasing *)errorRef
{
  return [self URLWithScheme:[self appURLScheme]
                        host:host
                        path:path
             queryParameters:queryParameters
                       error:errorRef];
}

+ (NSDictionary *)dictionaryFromFBURL:(NSURL *)url
{
  // version 3.2.3 of the Facebook app encodes the parameters in the query but
  // version 3.3 and above encode the parameters in the fragment;
  // merge them together with fragment taking priority.
  NSMutableDictionary *params = [NSMutableDictionary dictionary];
  [params addEntriesFromDictionary:[FBSDKUtility dictionaryWithQueryString:url.query]];

  // Only get the params from the fragment if it has authorize as the host
  if ([url.host isEqualToString:@"authorize"]) {
    [params addEntriesFromDictionary:[FBSDKUtility dictionaryWithQueryString:url.fragment]];
  }
  return params;
}

+ (void)array:(NSMutableArray *)array addObject:(id)object
{
  if (object) {
    [array addObject:object];
  }
}

+ (unsigned long)currentTimeInMilliseconds
{
  struct timeval time;
  gettimeofday(&time, NULL);
  return (time.tv_sec * 1000) + (time.tv_usec / 1000);
}

+ (BOOL)dictionary:(NSMutableDictionary *)dictionary
setJSONStringForObject:(id)object
            forKey:(id<NSCopying>)key
             error:(NSError *__autoreleasing *)errorRef
{
  if (!object || !key) {
    return YES;
  }
  NSString *JSONString = [self JSONStringForObject:object error:errorRef];
  if (!JSONString) {
    return NO;
  }
  [self dictionary:dictionary setObject:JSONString forKey:key];
  return YES;
}

+ (void)dictionary:(NSMutableDictionary *)dictionary setObject:(id)object forKey:(id<NSCopying>)key
{
  if (object && key) {
    [dictionary setObject:object forKey:key];
  }
}

+ (NSURL *)facebookURLWithHostPrefix:(NSString *)hostPrefix
                                path:(NSString *)path
                     queryParameters:(NSDictionary *)queryParameters
                               error:(NSError *__autoreleasing *)errorRef
{
  return [self facebookURLWithHostPrefix:hostPrefix
                                    path:path
                         queryParameters:queryParameters
                          defaultVersion:nil
                                   error:errorRef];
}

+ (NSURL *)facebookURLWithHostPrefix:(NSString *)hostPrefix
                                path:(NSString *)path
                     queryParameters:(NSDictionary *)queryParameters
                      defaultVersion:(NSString *)defaultVersion
                               error:(NSError *__autoreleasing *)errorRef
{
  if ([hostPrefix length] && ![hostPrefix hasSuffix:@"."]) {
    hostPrefix = [hostPrefix stringByAppendingString:@"."];
  }

  NSString *host = @"facebook.com";
  NSString *domainPart = [FBSDKSettings facebookDomainPart];
  if ([domainPart length]) {
    host = [[NSString alloc] initWithFormat:@"%@.%@", domainPart, host];
  }
  host = [NSString stringWithFormat:@"%@%@", hostPrefix ?: @"", host ?: @""];

  NSString *version = defaultVersion ?: FBSDK_TARGET_PLATFORM_VERSION;
  if ([version length]) {
    version = [@"/" stringByAppendingString:version];
  }

  if ([path length]) {
    NSScanner *versionScanner = [[NSScanner alloc] initWithString:path];
    if ([versionScanner scanString:@"/v" intoString:NULL] &&
        [versionScanner scanInteger:NULL] &&
        [versionScanner scanString:@"." intoString:NULL] &&
        [versionScanner scanInteger:NULL]) {
      version = nil;
    }
    if (![path hasPrefix:@"/"]) {
      path = [@"/" stringByAppendingString:path];
    }
  }
  path = [[NSString alloc] initWithFormat:@"%@%@", version ?: @"", path ?: @""];

  return [self URLWithScheme:@"https"
                        host:host
                        path:path
             queryParameters:queryParameters
                       error:errorRef];
}

+ (BOOL)isBrowserURL:(NSURL *)URL
{
  NSString *scheme = [URL.scheme lowercaseString];
  return ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"]);
}

+ (BOOL)isFacebookBundleIdentifier:(NSString *)bundleIdentifier
{
  return ([bundleIdentifier hasPrefix:@"com.facebook."] ||
          [bundleIdentifier hasPrefix:@".com.facebook."]);
}

+ (BOOL)isOSRunTimeVersionAtLeast:(NSOperatingSystemVersion)version
{
  static NSOperatingSystemVersion operatingSystemVersion = {
    .majorVersion = 0,
    .minorVersion = 0,
    .patchVersion = 0,
  };
  static dispatch_once_t getVersionOnce;
  dispatch_once(&getVersionOnce, ^{
    if ([NSProcessInfo instancesRespondToSelector:@selector(operatingSystemVersion)]) {
      operatingSystemVersion = [NSProcessInfo processInfo].operatingSystemVersion;
    } else {
      NSArray *components = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."];
      switch (components.count) {
        default:
        case 3:
          operatingSystemVersion.patchVersion = [components[2] integerValue];
          // fall through
        case 2:
          operatingSystemVersion.minorVersion = [components[1] integerValue];
          // fall through
        case 1:
          operatingSystemVersion.majorVersion = [components[0] integerValue];
          break;
        case 0:
          operatingSystemVersion.majorVersion = ([self isUIKitLinkTimeVersionAtLeast:FBSDKUIKitVersion_7_0] ? 7 : 6);
          break;
      }
    }
  });
  return ([self _compareOperatingSystemVersion:operatingSystemVersion toVersion:version] != NSOrderedDescending);
}

+ (BOOL)isSafariBundleIdentifier:(NSString *)bundleIdentifier
{
  return [bundleIdentifier isEqualToString:@"com.apple.mobilesafari"];
}

+ (BOOL)isUIKitLinkTimeVersionAtLeast:(FBSDKUIKitVersion)version
{
  static int32_t linkTimeMajorVersion;
  static dispatch_once_t getVersionOnce;
  dispatch_once(&getVersionOnce, ^{
    int32_t linkTimeVersion = NSVersionOfLinkTimeLibrary("UIKit");
    linkTimeMajorVersion = ((MAX(linkTimeVersion, 0) & FBSDKInternalUtilityMajorVersionMask) >> FBSDKInternalUtilityMajorVersionShift);
  });
  return (version <= linkTimeMajorVersion);
}

+ (BOOL)isUIKitRunTimeVersionAtLeast:(FBSDKUIKitVersion)version
{
  static int32_t runTimeMajorVersion;
  static dispatch_once_t getVersionOnce;
  dispatch_once(&getVersionOnce, ^{
    int32_t runTimeVersion = NSVersionOfRunTimeLibrary("UIKit");
    runTimeMajorVersion = ((MAX(runTimeVersion, 0) & FBSDKInternalUtilityMajorVersionMask) >> FBSDKInternalUtilityMajorVersionShift);
  });
  return (version <= runTimeMajorVersion);
}

+ (NSString *)JSONStringForObject:(id)object error:(NSError *__autoreleasing *)errorRef
{
  if (![NSJSONSerialization isValidJSONObject:object]) {
    if (errorRef != NULL) {
      *errorRef = [FBSDKError invalidArgumentErrorWithName:@"object"
                                                     value:object
                                                   message:@"Invalid object for JSON serialization."];
    }
    return nil;
  }
  NSData *data = [NSJSONSerialization dataWithJSONObject:object options:0 error:errorRef];
  if (!data) {
    return nil;
  }
  return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

+ (NSString *)JSONStringForObject:(id)object
                            error:(NSError *__autoreleasing *)errorRef
             invalidObjectHandler:(id(^)(id object, BOOL *stop))invalidObjectHandler
{
  if (invalidObjectHandler) {
    object = [self _convertObjectToJSONObject:object invalidObjectHandler:invalidObjectHandler stop:NULL];
  }
  return [self JSONStringForObject:object error:errorRef];
}

+ (BOOL)object:(id)object isEqualToObject:(id)other;
{
  if (object == other) {
    return YES;
  }
  if (!object || !other) {
    return NO;
  }
  return [object isEqual:other];
}

+ (id)objectForJSONString:(NSString *)string error:(NSError *__autoreleasing *)errorRef
{
  NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
  if (!data) {
    if (errorRef != NULL) {
      *errorRef = nil;
    }
    return nil;
  }
  return [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:errorRef];
}

+ (NSString *)queryStringWithDictionary:(NSDictionary *)dictionary
                                  error:(NSError *__autoreleasing *)errorRef
                   invalidObjectHandler:(id(^)(id object, BOOL *stop))invalidObjectHandler
{
  NSMutableString *queryString = [[NSMutableString alloc] init];
  __block BOOL hasParameters = NO;
  if (dictionary) {
    NSMutableArray *keys = [[dictionary allKeys] mutableCopy];
    // remove non-string keys, as they are not valid
    [keys filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
      return [evaluatedObject isKindOfClass:[NSString class]];
    }]];
    // sort the keys so that the query string order is deterministic
    [keys sortUsingSelector:@selector(compare:)];
    BOOL stop = NO;
    for (NSString *key in keys) {
      id value = dictionary[key];
      if ([value isKindOfClass:[NSURL class]]) {
        value = [(NSURL *)value absoluteString];
      }
      if ([value isKindOfClass:[NSString class]]) {
        value = [FBSDKUtility URLEncode:value];
      }
      if (invalidObjectHandler &&
          ![value isKindOfClass:[NSString class]] &&
          ![value isKindOfClass:[NSNumber class]]) {
        value = invalidObjectHandler(value, &stop);
        if (stop) {
          break;
        }
      }
      if (value) {
        if (hasParameters) {
          [queryString appendString:@"&"];
        }
        [queryString appendFormat:@"%@=%@", key, value];
        hasParameters = YES;
      }
    }
  }
  if (errorRef != NULL) {
    *errorRef = nil;
  }
  return ([queryString length] ? [queryString copy] : nil);
}

+ (BOOL)shouldManuallyAdjustOrientation
{
  return (![self isUIKitLinkTimeVersionAtLeast:FBSDKUIKitVersion_8_0] ||
          ![self isUIKitRunTimeVersionAtLeast:FBSDKUIKitVersion_8_0]);
}

+ (NSURL *)URLWithScheme:(NSString *)scheme
                    host:(NSString *)host
                    path:(NSString *)path
         queryParameters:(NSDictionary *)queryParameters
                   error:(NSError *__autoreleasing *)errorRef
{
  if (![path hasPrefix:@"/"]) {
    path = [@"/" stringByAppendingString:path ?: @""];
  }

  NSString *queryString = nil;
  if ([queryParameters count]) {
    NSError *queryStringError;
    queryString = [@"?" stringByAppendingString:[FBSDKUtility queryStringWithDictionary:queryParameters
                                                                                  error:&queryStringError]];
    if (!queryString) {
      if (errorRef != NULL) {
        *errorRef = [FBSDKError invalidArgumentErrorWithName:@"queryParameters"
                                                       value:queryParameters
                                                     message:nil
                                             underlyingError:queryStringError];
      }
      return nil;
    }
  }

  NSURL *URL = [[NSURL alloc] initWithString:[NSString stringWithFormat:
                                              @"%@://%@%@%@",
                                              scheme ?: @"",
                                              host ?: @"",
                                              path ?: @"",
                                              queryString ?: @""]];
  if (errorRef != NULL) {
    if (URL) {
      *errorRef = nil;
    } else {
      *errorRef = [FBSDKError unknownErrorWithMessage:@"Unknown error building URL."];
    }
  }
  return URL;
}

+ (void)deleteFacebookCookies
{
  NSHTTPCookieStorage *cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
  NSArray *facebookCookies = [cookies cookiesForURL:[self facebookURLWithHostPrefix:@"m."
                                                                               path:@"/dialog/"
                                                                    queryParameters:nil
                                                                              error:NULL]];

  for (NSHTTPCookie *cookie in facebookCookies) {
    [cookies deleteCookie:cookie];
  }
}

#pragma mark - Object Lifecycle

- (instancetype)init
{
  FBSDK_NOT_DESIGNATED_INITIALIZER
  return nil;
}

#pragma mark - Helper Methods

+ (NSComparisonResult)_compareOperatingSystemVersion:(NSOperatingSystemVersion)version1
                                           toVersion:(NSOperatingSystemVersion)version2
{
  if (version1.majorVersion < version2.majorVersion) {
    return NSOrderedAscending;
  } else if (version1.majorVersion > version2.majorVersion) {
    return NSOrderedDescending;
  } else if (version1.minorVersion > version2.minorVersion) {
    return NSOrderedAscending;
  } else if (version1.minorVersion < version2.minorVersion) {
    return NSOrderedDescending;
  } else if (version1.patchVersion > version2.patchVersion) {
    return NSOrderedAscending;
  } else if (version1.patchVersion < version2.patchVersion) {
    return NSOrderedDescending;
  } else {
    return NSOrderedSame;
  }
}

+ (id)_convertObjectToJSONObject:(id)object
            invalidObjectHandler:(id(^)(id object, BOOL *stop))invalidObjectHandler
                            stop:(BOOL *)stopRef
{
  __block BOOL stop = NO;
  if ([object isKindOfClass:[NSString class]] || [object isKindOfClass:[NSNumber class]]) {
    // good to go, keep the object
  } else if ([object isKindOfClass:[NSDictionary class]]) {
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    [(NSDictionary *)object enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *dictionaryStop) {
      [FBSDKInternalUtility dictionary:dictionary
                     setObject:[self _convertObjectToJSONObject:obj invalidObjectHandler:invalidObjectHandler stop:&stop]
                        forKey:[FBSDKTypeUtility stringValue:key]];
      if (stop) {
        *dictionaryStop = YES;
      }
    }];
    object = dictionary;
  } else if ([object isKindOfClass:[NSArray class]]) {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (id obj in (NSArray *)object) {
      [FBSDKInternalUtility array:array
                addObject:[self _convertObjectToJSONObject:obj invalidObjectHandler:invalidObjectHandler stop:&stop]];
      if (stop) {
        break;
      }
    }
    object = array;
  } else {
    object = invalidObjectHandler(object, stopRef);
  }
  if (stopRef != NULL) {
    *stopRef = stop;
  }
  return object;
}

@end
