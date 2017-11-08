//
//  WBUser+CoreDataProperties.h
//  WisnucBox
//
//  Created by JackYang on 2017/11/6.
//  Copyright © 2017年 JackYang. All rights reserved.
//

#import "WBUser+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface WBUser (CoreDataProperties)

+ (NSFetchRequest<WBUser *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *localToken;
@property (nullable, nonatomic, copy) NSString *userName;
@property (nullable, nonatomic, copy) NSString *uuid;
@property (nullable, nonatomic, copy) NSString *cloudToken;
@property (nullable, nonatomic, copy) NSString *localAddr;
@property (nullable, nonatomic, copy) NSString *stationId;
@property (nullable, nonatomic, copy) NSString *bonjour_name;
@property (nullable, nonatomic, copy) NSString *sn_address;
@property (nonatomic) BOOL isFirstUser;
@property (nonatomic) BOOL isAdmin;
@property (nonatomic) BOOL isCloudLogin;
@property (nonatomic) BOOL autoBackUp;
@property (nonatomic) BOOL backUpInWWAN;

@end

NS_ASSUME_NONNULL_END
