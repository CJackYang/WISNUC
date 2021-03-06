//
//  WBStationManageTimeViewController.m
//  WisnucBox
//
//  Created by wisnuc-imac on 2017/11/28.
//  Copyright © 2017年 JackYang. All rights reserved.
//

#import "WBStationManageTimeViewController.h"
#import "WBStationManageTimedateAPI.h"
#import "WBStationManageTimeDateModel.h"
#import "WBStationManageTableViewCell.h"

@interface WBStationManageTimeViewController ()
<
UITableViewDelegate,
UITableViewDataSource
>
@property (nonatomic) UITableView *tableView;
@property (nonatomic) UIImageView *timeImageView;
@property (nonatomic) NSMutableArray *dataArray;
@end


@implementation WBStationManageTimeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"时间与日期";
    [self getData];
    [self.view addSubview:self.timeImageView];
    [self.view addSubview:self.tableView];
    [self addLeftBarButtonWithImage:[UIImage imageNamed:@"back"] andHighlightButtonImage:nil andSEL:@selector(backbtnClick:)];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageWithColor:UICOLOR_RGB(0x03a9f4)] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageWithColor:[UIColor whiteColor]] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor darkTextColor]}];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
}
- (void)backbtnClick:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)getData{
    WBStationManageTimedateAPI *api = [[WBStationManageTimedateAPI alloc]init];
    [SXLoadingView showProgressHUD:@"正在获取..."];
    [api startWithCompletionBlockWithSuccess:^(__kindof JYBaseRequest *request) {
        NSDictionary * responseDic = WB_UserService.currentUser.isCloudLogin ? request.responseJsonObject[@"data"] : request.responseJsonObject;
        WBStationManageTimeDateModel *model = [WBStationManageTimeDateModel yy_modelWithDictionary:responseDic];
        [self.dataArray addObject:model];
        [SXLoadingView hideProgressHUD];
        [self.tableView reloadData];
        NSLog(@"%@",request.responseJsonObject);
    } failure:^(__kindof JYBaseRequest *request) {
        [SXLoadingView hideProgressHUD];
        NSLog(@"%@",request.error);
        [self.tableView reloadData];
    }];
}


#pragma tableViewDelegate;

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    WBStationManageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([WBStationManageTableViewCell class])];
    if (!cell) {
        cell =  [[WBStationManageTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NSStringFromClass([WBStationManageTableViewCell class])];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    WBStationManageTimeDateModel *model;
    if (self.dataArray.count >0) {
        model = self.dataArray[0];
    }
   
    switch (indexPath.row) {
        case 0:
            cell.normalLabel.text = model.localTime;
            cell.detailLabel.text = @"本地时间";
            break;
        case 1:
            cell.normalLabel.text = model.universalTime;
            cell.detailLabel.text = @"世界时间";
            break;
        case 2:
            cell.normalLabel.text = model.wbRTCTime;
            cell.detailLabel.text = @"RTC时间";
            break;
        case 3:
            cell.normalLabel.text = model.timeZone;
            cell.detailLabel.text = @"时区";
            break;
        case 4:
            cell.normalLabel.text = [model.wbNTPSynchronized boolValue]?@"Yes" : @"No";
            cell.detailLabel.text = @"已完成时间同步";
            break;
        case 5:
            cell.normalLabel.text =[model.wbNetworkTimeOn boolValue]?@"Yes" : @"No";
            cell.detailLabel.text = @"使用网络时间";
            break;
        default:
            break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    switch (indexPath.row) {
        case 0:
            
            break;
        case 1:
            
            break;
        case 2:
            
            break;
        case 3:
            
            break;
        case 4:
            
            break;
            
        default:
            break;
    }
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 6;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 64;
}

- (UITableView *)tableView{
    if (!_tableView) {
        _tableView = [[UITableView alloc]initWithFrame:CGRectMake(CGRectGetMaxX(self.timeImageView.frame) + 20, 0, __kWidth - 16 - 24 - 20, __kHeight - 64) style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
        _tableView.separatorStyle = UITableViewCellAccessoryNone;
        _tableView.contentInset = UIEdgeInsetsMake(KDefaultOffset, 0, 0, 0);
        _tableView.scrollEnabled = NO;
    }
    return _tableView;
}

- (UIImageView *)timeImageView{
    if (!_timeImageView) {
        _timeImageView = [[UIImageView alloc]initWithFrame:CGRectMake(16, 16, 24, 24)];
        _timeImageView.image = [UIImage imageNamed:@"ic_access_time"];
    }
    return _timeImageView;
}

- (NSMutableArray *)dataArray{
    if (!_dataArray) {
        _dataArray = [NSMutableArray arrayWithCapacity:0];
    }
    return _dataArray;
}
@end


