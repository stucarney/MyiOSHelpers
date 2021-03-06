//
//  MYLocationController.m
//  Pods
//
//  Created by Vincil Bishop on 1/8/14.
//
//

#import "MYLocationManager.h"
#import "MYiOSLogicCategories.h"
#import "NSTimer+Blocks.h"

@implementation MYLocationManager

static MYLocationManager *_sharedManager;

+ (MYLocationManager*) sharedManager
{
    if (!_sharedManager) {
        _sharedManager = [[MYLocationManager alloc] init];
    }
    
    return _sharedManager;
}

- (id) init
{
    self = [super init];
    
    if (self) {
        
        self.locationManager = [CLLocationManager new];
        self.locationManager.delegate = self;
    }
    
    return self;
}

#pragma mark - Location Convenience Methods -

- (void) startMonitoringLocationWithUpdateInterval:(NSTimeInterval)updateInterval
{
    self.locationTimer = [NSTimer timerWithTimeInterval:updateInterval block:^{
        [self getLocationAndStopWithCompletion:NULL];
    } repeats:YES];
    [self.locationTimer fire];
}

- (void) getLocationAndStopWithCompletion:(MYCompletionBlock)completionBlock
{
    [self getLocationOnce:YES withCompletion:NULL];
}

- (void) getLocationOnce:(BOOL)once withCompletion:(MYCompletionBlock)completionBlock
{
    __block id observer = nil;
    observer = [[NSNotificationCenter defaultCenter] addObserverForName:kMYLocationManager_DidUpdateLocations_Notification object:observer queue:[NSOperationQueue backgroundQueue] usingBlock:^(NSNotification *note) {
        
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
        
        if (completionBlock) {
            // TODO: Make a check for manager instance, date, sanity, etc.
            completionBlock(self,YES,nil,self.lastLocation);

        }
        
        if (once) {
            [[NSOperationQueue backgroundQueue] addOperationWithBlock:^{
                [self.locationManager stopMonitoringSignificantLocationChanges];
            }];
        }
        
    }];
    
    [self.locationManager startMonitoringSignificantLocationChanges];
}

#pragma mark - Beacon Convenience Methods -

- (void) startMonitoringBeaconsInRegion:(CLBeaconRegion*)region withUpdateInterval:(NSTimeInterval)updateInterval
{
    NSAssert(region,@"Region cannot be nil...");
    // TODO: We need to figure out how to make this monitor multiple beacon regions...
    self.beaconTimer = [NSTimer scheduledTimerWithTimeInterval:updateInterval block:^{
         [self getBeaconsAndStopInRegion:region completion:NULL];
    } repeats:YES];
    [self.beaconTimer fire];
    
    /*
    [[NSOperationQueue backgroundQueue] addOperationWithBlock:^{
        [self.beaconTimer fire];
    } afterDelay:0.25];
     */
    
}

- (void) getBeaconsAndStopInRegion:(CLBeaconRegion*)region completion:(MYCompletionBlock)completionBlock
{
    [self getBeaconsInRegion:region once:YES completion:completionBlock];
}

- (void) getBeaconsInRegion:(CLBeaconRegion*)region once:(BOOL)once completion:(MYCompletionBlock)completionBlock
{
    NSAssert(region,@"Region cannot be nil...");
    __block BOOL found = NO;
    
    __block id observer = nil;
    observer = [[NSNotificationCenter defaultCenter] addObserverForName:kMYLocationManager_DidRangeBeaconsInRegion_Notification object:observer queue:[NSOperationQueue backgroundQueue]  usingBlock:^(NSNotification *note) {
        
        if (once) {
            [[NSOperationQueue backgroundQueue] addOperationWithBlock:^{
                [self.locationManager stopRangingBeaconsInRegion:region];
            }];
        }
        
        found = YES;
        
        // TODO: Make a check for manager instance, date, sanity, etc.
        // Make sure that this is the right call for the beacon region we were monitoring...
        if (completionBlock) {
            completionBlock(self,YES,nil,self.beacons);
        }
        
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
    }];
    
    [self.locationManager startRangingBeaconsInRegion:region];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (!found) {
            [[NSNotificationCenter defaultCenter] removeObserver:observer];
            
            [self.locationManager stopRangingBeaconsInRegion:region];
            
            if (completionBlock) {
                completionBlock(self,NO,nil,nil);
            }
        }

    } afterDelay:30.0];
}

#pragma mark - Location Information -

- (CLLocation*) lastLocation
{
    // TODO: Uncomment the following line when we are ready for real locations
    //return [self.locations lastObject];
    
    // +37.78735890,-122.40822700
    if (self.mockLocation) {
        return self.mockLocation;
    } else if ([self.locations lastObject]) {
        return [self.locations lastObject];
    } else {
        return [self.locations lastObject];
    }
//    CLLocation *mockLocation = [[CLLocation alloc] initWithLatitude:37.78735890 longitude:-122.40822700];
//    
//    return mockLocation;
}

#pragma mark - CLLocationManagerDelegate Locations -

/*
 *  locationManager:didRangeBeacons:inRegion:
 *
 *  Discussion:
 *    Invoked when a new set of beacons are available in the specified region.
 *    beacons is an array of CLBeacon objects.
 *    If beacons is empty, it may be assumed no beacons that match the specified region are nearby.
 *    Similarly if a specific beacon no longer appears in beacons, it may be assumed the beacon is no longer received
 *    by the device.
 */
- (void)locationManager:(CLLocationManager *)manager
        didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    self.beacons = beacons;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kMYLocationManager_DidRangeBeaconsInRegion_Notification object:self userInfo:@{@"locationManager":manager,@"beacons":beacons,@"region":region}];
    
    // TODO: add a flag here so that when starting location updates, one can choose whether to only update location once, or continually monitor locations as the user moves....
    //[manager stopRangingBeaconsInRegion:region];
}

#pragma mark - CLLocationManagerDelegate Locations -

/*
 *  locationManager:didUpdateLocations:
 *
 *  Discussion:
 *    Invoked when new locations are available.  Required for delivery of
 *    deferred locations.  If implemented, updates will
 *    not be delivered to locationManager:didUpdateToLocation:fromLocation:
 *
 *    locations is an array of CLLocation objects in chronological order.
 */
- (void)locationManager:(CLLocationManager *)manager
	 didUpdateLocations:(NSArray *)locations
{
    self.locations = locations;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kMYLocationManager_DidUpdateLocations_Notification object:self userInfo:@{@"locationManager":manager,@"locations":locations}];
    
    // TODO: add a flag here so that when starting location updates, one can choose whether to only update location once, or continually monitor locations as the user moves....
    [manager stopUpdatingLocation];
}

/*
 *  locationManager:rangingBeaconsDidFailForRegion:withError:
 *
 *  Discussion:
 *    Invoked when an error has occurred ranging beacons in a region. Error types are defined in "CLError.h".
 */
- (void)locationManager:(CLLocationManager *)manager
rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region
              withError:(NSError *)error
{}

/*
 *  locationManager:didEnterRegion:
 *
 *  Discussion:
 *    Invoked when the user enters a monitored region.  This callback will be invoked for every allocated
 *    CLLocationManager instance with a non-nil delegate that implements this method.
 */
- (void)locationManager:(CLLocationManager *)manager
         didEnterRegion:(CLRegion *)region
{}

/*
 *  locationManager:didExitRegion:
 *
 *  Discussion:
 *    Invoked when the user exits a monitored region.  This callback will be invoked for every allocated
 *    CLLocationManager instance with a non-nil delegate that implements this method.
 */
- (void)locationManager:(CLLocationManager *)manager
          didExitRegion:(CLRegion *)region
{}

/*
 *  locationManager:didFailWithError:
 *
 *  Discussion:
 *    Invoked when an error has occurred. Error types are defined in "CLError.h".
 */
- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    DDLogVerbose(@"error: %@", error);
}



@end
