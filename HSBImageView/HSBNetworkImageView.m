//
//  RedImageView.m
//  imageNetwork
//
//  Created by hsb9kr on 2017. 8. 28..
//  Copyright © 2017년 hsb9kr. All rights reserved.
//

#import "HSBNetworkImageView.h"

@interface HSBNetworkImageView() {
    struct {
        unsigned int success    :1;
        unsigned int error      :1;
        unsigned int received   :1;
        unsigned int request    :1;
        unsigned int response   :1;
    }_delegateFlage;
}
@property (strong, nonatomic) NSMutableData *data;
@property (nonatomic) NSUInteger expectedContentLength;
@property (strong, nonatomic) NSURLSession *session;
@property (strong, nonatomic) NSURLSessionTask *task;
@property (strong, nonatomic) NSURL *url;
@end
@implementation HSBNetworkImageView

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)dealloc {
    NSLog(@"%@ dealloc", self.class);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (!_progressView || _isAutoResize) {
        [self initProgessView];
    }
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self initProgessView];
}

- (void)setDelegate:(id<HSBImageViewDelegate>)delegate {
    _delegate = delegate;
    _delegateFlage.success = [_delegate respondsToSelector:@selector(hsbImageView:image:url:userInfo:isCached:)];
    _delegateFlage.error = [_delegate respondsToSelector:@selector(hsbImageView:error:userInfo:)];
    _delegateFlage.received = [_delegate respondsToSelector:@selector(hsbImageView:dataTask:currentByteLength:totalByteLength:didReceivedData:userInfo:)];
    _delegateFlage.request = [_delegate respondsToSelector:@selector(hsbImageView:beforeRequest:userInfo:)];
    _delegateFlage.response = [_delegate respondsToSelector:@selector(hsbImageView:receiveResponse:userInfo:)];
}

#pragma mark <Public>

- (void)imageWithURLString:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    [self imageWithURL:url];
}

- (void)imageWithURL:(NSURL *)url {
    _url = url;
    _data = nil;
    if (!url) {
        if (_delegateFlage.error) {
            NSError *error = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:@{@"description": @"url is nil"}];
            [_delegate hsbImageView:self error:error userInfo:_userInfo];
        }
        return;
    }
    if (_cache) {
        NSPurgeableData *cacheData = [_cache objectForKey:url.absoluteString];
        if (cacheData) {
            [cacheData beginContentAccess];
            _data = cacheData;
            [cacheData endContentAccess];
        }
        if (_data && _data.length != 0 && (self.image = [UIImage imageWithData:_data])) {
            if (_delegateFlage.success) {
                [_delegate hsbImageView:self image:self.image url: url userInfo:_userInfo isCached:YES];
            }
            return;
        }
    }
    [self requestImageWithURL:url];
}

- (void)invalidateSession {
    [_session invalidateAndCancel];
}

#pragma mark <Private>

- (void)initProgessView {
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    CGFloat distance = width > height ? height / 3.0 : width / 3.0;
    if (_progressView) {
        _progressView.frame = CGRectMake(width / 2.0 - distance / 2.0, height / 2.0 - distance / 2.0, distance, distance);
    } else {
        _progressView = [[HSBCircleProgressView alloc] initWithFrame:CGRectMake(width / 2.0 - distance / 2.0, height / 2.0 - distance / 2.0, distance, distance)];
        [self addSubview:_progressView];
    }
    _progressView.hidden = YES;
}

- (void)requestImageWithURL:(NSURL *)url {
    _progressView.hidden = _isHiddenProgressView;
    if (_task) {
        switch (_task.state) {
            case NSURLSessionTaskStateCanceling:
            case NSURLSessionTaskStateCompleted:
            case NSURLSessionTaskStateSuspended:
                break;
            case NSURLSessionTaskStateRunning:
                [_task cancel];
                [_session invalidateAndCancel];
                break;
        }
    }
    if (_timeoutInterval <= 0) {
        _timeoutInterval = 30.f;
    }
    _session = [NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.defaultSessionConfiguration delegate:self delegateQueue:NSOperationQueue.mainQueue];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:_timeoutInterval];
    _data = [NSMutableData new];
    _task = [_session dataTaskWithRequest: request];
    if (_delegateFlage.request) [_delegate hsbImageView:self beforeRequest:request userInfo:_userInfo];
    [_task resume];
}

- (void)initialize {
    self.userInteractionEnabled = YES;
    _retryBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _retryBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [_retryBtn setTitle:@"Retry" forState:UIControlStateNormal];
    [_retryBtn addTarget:self action:@selector(didTouchUpInsideRetryBtn) forControlEvents:UIControlEventTouchUpInside];
    _retryBtn.hidden = YES;
    [self addSubview:_retryBtn];
    NSLayoutConstraint *centerX = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_retryBtn attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
    NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_retryBtn attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
    [self addConstraints:@[centerX, centerY]];
    _isAutoResize = YES;
    if (!_progressView) {
        [self initProgessView];
    }
}

#pragma mark <NSURLSession delegate>

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    _expectedContentLength = (NSUInteger)response.expectedContentLength;
    completionHandler(NSURLSessionResponseAllow);
    _progressView.hidden = _isHiddenProgressView;
    _retryBtn.hidden = YES;
    if (_delegateFlage.response) [_delegate hsbImageView:self receiveResponse:response userInfo:_userInfo];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [_data appendData:data];
    Float64 percent = (Float64)_data.length / (Float64)_expectedContentLength;
    _progressView.rate = percent;
    _progressView.textLabel.text = [NSString stringWithFormat:@"%.0f%%", percent * 100];
    if (_delegateFlage.received) [_delegate hsbImageView:self dataTask:dataTask currentByteLength:_data.length totalByteLength:_expectedContentLength didReceivedData:data userInfo:_userInfo];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    _progressView.hidden = YES;
    _retryBtn.hidden = YES;
    [_session finishTasksAndInvalidate];
    if (error || _data.length != _expectedContentLength) {
        if (!error) return;
        if (error.code == -999) return;
        _retryBtn.hidden = NO;
        if (_delegateFlage.error) [_delegate hsbImageView:self error:error userInfo:_userInfo];
        return;
    }
    if (_cache) {
        NSPurgeableData *purgeableData = [NSPurgeableData dataWithData:_data];
        [_cache setObject: purgeableData forKey: task.response.URL.absoluteString cost: purgeableData.length];
    }
    self.image = [UIImage imageWithData:_data];
    if (_delegateFlage.success) [_delegate hsbImageView:self image:self.image url: task.response.URL userInfo:_userInfo isCached:NO];
}

#pragma mark <Touch>

- (void)didTouchUpInsideRetryBtn {
    if (!_url) return;
    _retryBtn.hidden = YES;
    [self requestImageWithURL:_url];
}

@end
