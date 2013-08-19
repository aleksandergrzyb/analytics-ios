//
//  AnalyticsJSONRequest.m
//  Analytics
//
//  Created by Tony Xiao on 8/19/13.
//  Copyright (c) 2013 Segment.io. All rights reserved.
//

#define AssertMainThread() NSAssert([NSThread isMainThread], @"%s must be called form main thread", __func__)

#import "AnalyticsJSONRequest.h"

@interface AnalyticsJSONRequest () <NSURLConnectionDataDelegate>

@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSURLRequest *urlRequest;
@property (nonatomic, strong) NSHTTPURLResponse *response;
@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic, strong) id responseJSON;
@property (nonatomic, strong) NSError *error;

@end

@implementation AnalyticsJSONRequest

- (id)initWithURLRequest:(NSURLRequest *)urlRequest {
    if (self = [super init]) {
        _urlRequest = urlRequest;
    }
    return self;
}

- (void)start {
    AssertMainThread();
    self.connection = [[NSURLConnection alloc] initWithRequest:self.urlRequest
                                                      delegate:self
                                              startImmediately:YES];
}

#pragma mark NSURLConnection Delegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    AssertMainThread();
    self.response = (NSHTTPURLResponse *)response;
    self.responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    AssertMainThread();
    [self.responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    AssertMainThread();
    int statusCode = self.response.statusCode;
    if (statusCode >= 200 && statusCode < 300) {
        NSError *error = nil;
        self.responseJSON = [NSJSONSerialization JSONObjectWithData:self.responseData
                                                            options:0
                                                              error:&error];
        self.error = error;
    } else {
        self.error = [NSError errorWithDomain:@"HTTP"
                                         code:statusCode
                                     userInfo:@{NSLocalizedDescriptionKey:
                        [NSString stringWithFormat:@"HTTP Error %d", statusCode]}];

    }
    [self.delegate requestDidComplete:self];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    AssertMainThread();
    self.error = error;
    [self.delegate requestDidComplete:self];
}

#pragma mark Class Methods

+ (instancetype)startRequestWithURLRequest:(NSURLRequest *)urlRequest
                                  delegate:(id<AnalyticsJSONRequestDelegate>)delegate {
    AnalyticsJSONRequest *request = [[self alloc] initWithURLRequest:urlRequest];
    request.delegate = delegate;
    [request start];
    return request;
}

@end
