//
//  FMUserLoginViewController.h
//  FruitMix
//
//  Created by wisnuc on 2017/8/15.
//  Copyright © 2017年 WinSun. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "UserModel.h"
#import "FMSerachService.h"

@interface FMUserLoginViewController : FABaseVC
@property (nonatomic) UserModel * user;

@property (nonatomic) FMSerachService * service;
@end
