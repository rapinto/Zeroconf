//
//  ZeroconfHost.m
//
//
//  Created by Ades on 31/08/2015.
//
// The MIT License (MIT)
// Copyright (c) 2015 Raphael Pinto.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.



#import "ZeroconfHost.h"
#import <UIKit/UIApplication.h>



@interface ZeroconfHost ()


@property (strong, nonatomic) NSNetService *service;
@property (assign, nonatomic) id<NSNetServiceDelegate> delegate;


@end



@implementation ZeroconfHost



#pragma mark -
#pragma mark Singleton Methods




static ZeroconfHost* sharedInstance = nil;



+ (ZeroconfHost*)sharedInstance
{
    if (sharedInstance == nil)
    {
        sharedInstance = [[ZeroconfHost alloc] init];
    }
    return sharedInstance;
}
 

+ (void)releaseSharedInstance
{
    if (sharedInstance != nil)
    {
        sharedInstance = nil;
    }
}



#pragma mark -
#pragma mark Public Methods



+ (void)startBroadcastingWithServiceType:(NSString*)serviceType
                                inDomain:(NSString*)domain
                             serviceName:(NSString*)serviceName
                                    port:(int)port
                                delegate:(id<NSNetServiceDelegate>)delegate
{
    [ZeroconfHost sharedInstance].delegate = delegate;
    [[ZeroconfHost sharedInstance] startBroadcastingWithServiceType:serviceType
                                                           inDomain:domain
                                                        serviceName:serviceName
                                                               port:port];
}


+ (void)stopBroadcasting
{
    if (sharedInstance != nil)
    {
        [sharedInstance.service stop];
        [ZeroconfHost releaseSharedInstance];
    }
}



#pragma mark -
#pragma mark Object Life Cycle Methods



- (id)init
{
    self = [super init];
    
    if (self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(stopBroadcastingWhileAppEnterBackground)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(startBroadcastingWhenAppReturnFromBackground)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
    }
    
    return self;
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidBecomeActiveNotification
                                                  object:nil];
}



#pragma mark -
#pragma mark Private Methods



- (void)startBroadcastingWithServiceType:(NSString*)serviceType
                                inDomain:(NSString*)domain
                             serviceName:(NSString*)serviceName
                                    port:(int)port
{
    // Initialize Service
    self.service = [[NSNetService alloc] initWithDomain:domain
                                                   type:serviceType
                                                   name:serviceName
                                                   port:port];
    
    // Configure Service
    [self.service setDelegate:self];
    
    [self.service scheduleInRunLoop:[NSRunLoop mainRunLoop]
                            forMode:NSDefaultRunLoopMode];
    
    // Publish Service
    [self.service publish];
}


- (void)stopBroadcastingWhileAppEnterBackground
{
    [sharedInstance.service stop];
}


- (void)startBroadcastingWhenAppReturnFromBackground
{
    [self.service publish];
}



#pragma mark -
#pragma mark NSNet Service Delegate Methods



- (void)netServiceWillPublish:(NSNetService *)sender
{
    if ([_delegate respondsToSelector:@selector(netServiceWillPublish:)])
    {
        [_delegate netServiceWillPublish:sender];
    }
}


- (void)netService:(NSNetService *)sender
     didNotPublish:(NSDictionary *)errorDict
{
    NSLog(@"Failed to Publish Service: domain(%@) type(%@) name(%@) - %@", [_service domain], [_service type], [_service name], errorDict);
    
    
    if ([_delegate respondsToSelector:@selector(netService:didNotPublish:)])
    {
        [_delegate netService:sender didNotPublish:errorDict];
    }
}


- (void)netServiceDidPublish:(NSNetService *)sender
{
    NSLog(@"Bonjour Service Published: domain(%@) type(%@) name(%@) port(%i)", [_service domain], [_service type], [_service name], (int)[_service port]);
    
    
    if ([_delegate respondsToSelector:@selector(netServiceDidPublish:)])
    {
        [_delegate netServiceDidPublish:sender];
    }
}


- (void)netService:(NSNetService *)sender
didUpdateTXTRecordData:(NSData *)data
{
    if ([_delegate respondsToSelector:@selector(netService:didUpdateTXTRecordData:)])
    {
        [_delegate netService:sender didUpdateTXTRecordData:data];
    }
}


- (void)netServiceDidStop:(NSNetService *)sender
{
    NSLog(@"Bonjour Service did stop: domain(%@) type(%@) name(%@) port(%i)", [_service domain], [_service type], [_service name], (int)[_service port]);
    
    
    if ([_delegate respondsToSelector:@selector(netServiceDidStop:)])
    {
        [_delegate netServiceDidStop:sender];
    }
}


- (void)netService:(NSNetService *)sender
didAcceptConnectionWithInputStream:(NSInputStream *)inputStream
      outputStream:(NSOutputStream *)outputStream
{
    if ([_delegate respondsToSelector:@selector(netService:didAcceptConnectionWithInputStream:outputStream:)])
    {
        [_delegate netService:sender
didAcceptConnectionWithInputStream:inputStream
                 outputStream:outputStream];
    }
}


@end
