//
//  SatoriWrapper.m
//  GeoReminder
//
//  Created by Dhruv Shah on 7/29/17.
//  Copyright © 2017 Dhruv Shah. All rights reserved.
//

#import "SatoriWrapper.h"

@implementation SatoriWrapper

+ (SatoriWrapper *)shared {
    static SatoriWrapper *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
        sharedMyManager.rtm = [[SatoriRtmConnection alloc] initWithUrl:@"wss://tpbbrhnn.api.satori.com" andAppkey:@"75cad2bfBC2edC554B8ED5C58D9EBeBa"];
        sharedMyManager.rtm.enableVerboseLogging = YES;
    });
    return sharedMyManager;
}

- (id)init {
    if (self = [super init]) {
        
    }
    return self;
}

- (void) satoriInit:(void(^)(SatoriPdu *))handler; {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
        // Perform async operation
        unsigned int reqId = 123;
        receiveCompletionHandler = [handler copy];
        rtm_status status = [[self rtm] connectWithPduHandler:receiveCompletionHandler];
        [[self rtm] subscribe:@"geopins" andRequestId:&reqId];
        while ([[self rtm] poll] >= 0) {
            sleep(1);
        }
    });
    
     
}

- (void) publishLocation: (NSDictionary *)location {
    unsigned int reqId = 124;
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:location
                                                       options:0 // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    
    if (! jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        rtm_status rc = [[self rtm] publishJson:jsonString toChannel:@"geopins" andRequestId:&reqId];
        if (RTM_OK != rc) {
            fprintf(stderr, "Failed to publish: %s\n", rtm_error_string(rc));
        }
        rc = [[self rtm] wait];
        if (RTM_OK != rc) {
            fprintf(stderr, "Failed to receive publish reply: %s\n", rtm_error_string(rc));
        }
    }
}

@end
