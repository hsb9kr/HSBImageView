//
//  RedImageView.h
//  imageNetwork
//
//  Created by hsb9kr on 2017. 8. 28..
//  Copyright © 2017년 hsb9kr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <HSBCircleProgress/HSBCircleProgress.h>

@protocol HSBImageViewDelegate;

@interface HSBNetworkImageView : UIImageView<NSURLSessionDataDelegate, NSURLSessionDelegate, NSURLSessionTaskDelegate>
@property (strong, nonatomic, readonly) HSBCircleProgressView *progressView;
@property (strong, nonatomic, readonly) UIButton *retryBtn;
@property (weak, nonatomic) id userInfo;
@property (weak, nonatomic) NSCache *cache;
@property (weak, nonatomic) id<HSBImageViewDelegate> delegate;
@property (nonatomic) NSTimeInterval timeoutInterval;
@property (nonatomic) BOOL isHiddenProgressView;
@property (nonatomic) BOOL isAutoResize;

- (void)imageWithURLString:(NSString *)urlString;
- (void)imageWithURL:(NSURL *)url;
- (void)invalidateSession;
@end

@protocol HSBImageViewDelegate <NSObject>
@optional
- (void)hsbImageView:(HSBNetworkImageView *)imageView beforeRequest:(NSURLRequest *)request userInfo:(id)userInfo;
- (void)hsbImageView:(HSBNetworkImageView *)imageView receiveResponse:(NSURLResponse *)response userInfo:(id)userInfo;
- (void)hsbImageView:(HSBNetworkImageView *)imageView dataTask:(NSURLSessionDataTask *)dataTask currentByteLength:(NSUInteger)currentLength totalByteLength:(NSUInteger)totalLength didReceivedData:(NSData *)data userInfo:(id)userInfo;
- (void)hsbImageView:(HSBNetworkImageView *)imageView image:(UIImage *)image url:(NSURL *)url userInfo:(id)userInfo isCached:(BOOL)isCached;
- (void)hsbImageView:(HSBNetworkImageView *)imageView error:(NSError *)error userInfo:(id)userInfo;
@end
