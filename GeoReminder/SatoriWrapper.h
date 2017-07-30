//
//  SatoriWrapper.h
//  GeoReminder
//
//  Created by Dhruv Shah on 7/29/17.
//  Copyright © 2017 Dhruv Shah. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <SatoriRtmSdkWrapper/SatoriRtmSdkWrapper.h>

@interface SatoriWrapper : NSObject
@property (nonatomic, retain) NSArray *geopins;
@property (nonatomic, retain) SatoriRtmConnection *rtm;

- (void)satoriInit;
- (void) publishLocation: (NSDictionary *)location;
+ (SatoriWrapper *)shared;

@end
