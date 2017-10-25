//
//  RedCircleProgressView.h
//  imageNetwork
//
//  Created by hsb9kr on 2017. 8. 28..
//  Copyright © 2017년 hsb9kr. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HSBCircleProgressView : UIView
@property (nonatomic) CGFloat rate;
@property (nonatomic) CGFloat radius;
@property (nonatomic) CGFloat progressWidth;
@property (nonatomic) CGFloat progressBarWidth;
@property (strong, nonatomic) UIColor *progressColor;
@property (strong, nonatomic) UIColor *progressBarColor;
@property (strong, nonatomic, readonly) UILabel *textLabel;
@end
