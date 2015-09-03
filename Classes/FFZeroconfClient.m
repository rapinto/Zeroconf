//
//  ZeroconfClient.m
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



#import "FFZeroconfClient.h"
#import <UIKit/UIApplication.h> 
#include <arpa/inet.h>



@interface FFZeroconfClient ()

@property (strong, nonatomic) NSMutableArray* services;
@property (strong, nonatomic) NSNetServiceBrowser* serviceBrowser;
@property (assign, nonatomic) id<NSNetServiceBrowserDelegate, NSNetServiceDelegate> delegate;
@property (strong, nonatomic) NSString* domain;
@property (strong, nonatomic) NSString* serviceType;

@end




@implementation FFZeroconfClient



#pragma mark -
#pragma mark Singleton Methods



static FFZeroconfClient* sharedInstance = nil;


+ (FFZeroconfClient*)sharedInstance
{
    if (sharedInstance == nil)
    {
        sharedInstance = [[FFZeroconfClient alloc] init];
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
#pragma mark Object Life Cycle Methods



- (id)init
{
    self = [super init];
    
    if (self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(stopBrowsingWhileAppEnterBackground)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(startBrowsingWhenAppReturnFromBackground)
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
#pragma mark Public Methods



+ (void)startBrowsingWithServiceType:(NSString*)serviceType
                            inDomain:(NSString*)domain
                            delegate:(id<NSNetServiceBrowserDelegate, NSNetServiceDelegate>)delegate
{
    [FFZeroconfClient sharedInstance].delegate = delegate;
    [[FFZeroconfClient sharedInstance] startBrowsingWithServiceType:serviceType
                                                           inDomain:domain];
}


+ (void)stopBrowsing
{
    if (sharedInstance != nil)
    {
        [[FFZeroconfClient sharedInstance] stopBrowsing];
        [FFZeroconfClient releaseSharedInstance];
    }
}


+ (NSArray*)currentServices
{
    if (sharedInstance != nil)
    {
        return [NSArray arrayWithArray:sharedInstance.services];
    }
    
    return nil;
}



#pragma mark -
#pragma mark Internal Methods



- (void)startBrowsingWithServiceType:(NSString*)serviceType
                            inDomain:(NSString*)domain
{
    if (self.services)
    {
        [self.services removeAllObjects];
    }
    else
    {
        self.services = [[NSMutableArray alloc] init];
    }
    
    // Initialize Service Browser
    self.serviceBrowser = [[NSNetServiceBrowser alloc] init];
    
    // Configure Service Browser
    _serviceBrowser.delegate = self;
    
    [self.serviceBrowser scheduleInRunLoop:[NSRunLoop mainRunLoop]
                                   forMode:NSDefaultRunLoopMode];
    
    
    NSString* lServiceType = serviceType;
    if ([serviceType length] == 0)
    {
        lServiceType = @"_http._tcp.";
    }
    self.serviceType = lServiceType;
    
    
    NSString* lDomain = domain;
    if ([domain length] == 0)
    {
        lDomain = @"local.";
    }
    self.domain = lDomain;
    
    [self.serviceBrowser searchForServicesOfType:lServiceType inDomain:lDomain];
}


- (void)stopBrowsing
{
    if (self.serviceBrowser)
    {
        [self.serviceBrowser stop];
        [self.serviceBrowser setDelegate:nil];
        [self setServiceBrowser:nil];
    }
}


- (void)stopBrowsingWhileAppEnterBackground
{
    [sharedInstance.serviceBrowser stop];
}


- (void)startBrowsingWhenAppReturnFromBackground
{
    [self.serviceBrowser searchForServicesOfType:_serviceType inDomain:_domain];
}



#pragma mark -
#pragma mark Network Service Browser Delegate Methods



- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser
            didFindDomain:(NSString *)domainName
               moreComing:(BOOL)moreDomainsComing
{
    if ([_delegate respondsToSelector:@selector(netServiceBrowser:didFindDomain:moreComing:)])
    {
        [_delegate netServiceBrowser:netServiceBrowser
                       didFindDomain:domainName
                          moreComing:moreDomainsComing];
    }
}


- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser
          didRemoveDomain:(NSString *)domainName
               moreComing:(BOOL)moreDomainsComing
{
    if ([_delegate respondsToSelector:@selector(netServiceBrowser:didRemoveDomain:moreComing:)])
    {
        [_delegate netServiceBrowser:netServiceBrowser
                     didRemoveDomain:domainName
                          moreComing:moreDomainsComing];
    }
}


- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser
           didFindService:(NSNetService *)netService
               moreComing:(BOOL)moreServicesComing
{
    netService.delegate = self;
    [netService resolveWithTimeout:10];
    
    [_services addObject:netService];
    
    if ([_delegate respondsToSelector:@selector(netServiceBrowser:didFindService:moreComing:)])
    {
        [_delegate netServiceBrowser:netServiceBrowser
                      didFindService:netService
                          moreComing:moreServicesComing];
    }
}


- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser
         didRemoveService:(NSNetService *)netService
               moreComing:(BOOL)moreServicesComing
{
    [_services removeObject:netService];
    
    if ([_delegate respondsToSelector:@selector(netServiceBrowser:didRemoveService:moreComing:)])
    {
        [_delegate netServiceBrowser:netServiceBrowser
                    didRemoveService:netService
                          moreComing:moreServicesComing];
    }
}


- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)netServiceBrowser
{
    if ([_delegate respondsToSelector:@selector(netServiceBrowserWillSearch:)])
    {
        [_delegate netServiceBrowserWillSearch:netServiceBrowser];
    }
}


- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser
             didNotSearch:(NSDictionary *)errorInfo
{
    [self stopBrowsing];
    
    if ([_delegate respondsToSelector:@selector(netServiceBrowser:didNotSearch:)])
    {
        [_delegate netServiceBrowser:netServiceBrowser
                        didNotSearch:errorInfo];
    }
}


- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)netServiceBrowser
{
    if ([_delegate respondsToSelector:@selector(netServiceBrowserDidStopSearch:)])
    {
        [_delegate netServiceBrowserDidStopSearch:netServiceBrowser];
    }
}



#pragma mark -
#pragma mark Resolvation Methods



- (void)netServiceWillResolve:(NSNetService *)service
{
    if ([_delegate respondsToSelector:@selector(netServiceWillResolve:)])
    {
        [_delegate netServiceWillResolve:service];
    }
}


- (void)netServiceDidResolveAddress:(NSNetService *)service
{
    if ([_delegate respondsToSelector:@selector(netServiceDidResolveAddress:)])
    {
        [_delegate netServiceDidResolveAddress:service];
    }
}


- (void)netService:(NSNetService *)service didNotResolve:(NSDictionary *)errorDict
{
    if ([_delegate respondsToSelector:@selector(netService:didNotResolve:)])
    {
        [_delegate netService:service didNotResolve:errorDict];
    }
}


+ (NSString *)getStringFromAddressData:(NSData *)datas
{
    struct sockaddr_in  *socketAddress = nil;
    NSString            *ipString = nil;
    
    socketAddress = (struct sockaddr_in *)[datas bytes];
    ipString = [NSString stringWithFormat: @"%s",
                inet_ntoa(socketAddress->sin_addr)];
    return ipString;
}



@end
