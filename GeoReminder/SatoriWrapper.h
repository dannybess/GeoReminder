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

@interface SatoriWrapper : NSObject {
    void (^receiveCompletionHandler)(SatoriPdu* pdu);
}
@property (nonatomic, retain) NSArray *geopins;
@property (nonatomic, retain) SatoriRtmConnection *rtm;

- (void)satoriInit:(void(^)(SatoriPdu *))handler;
- (void) publishLocation: (NSDictionary *)location;
+ (SatoriWrapper *)shared;

@end
