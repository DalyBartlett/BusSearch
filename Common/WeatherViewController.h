//
//  WeatherViewController.h
//  CandidateProject
//
//  Created by Louis Zhu on 2017/11/14.
//  Copyright © 2017年 PerrchicK. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SmileWeatherDemoVC.h"
@interface WeatherViewController : UIViewController
@property (nonatomic,strong) CLLocation *loaction;
@property (nonatomic,assign) double lat;
@property (nonatomic,assign) double lng;
@end
