//
//  JYThumbVC.m
//  Photos
//
//  Created by JackYang on 2017/9/25.
//  Copyright © 2017年 JackYang. All rights reserved.
//

#import "JYThumbVC.h"
#import "PHPhotoLibrary+JYEXT.h"
#import "PHAsset+JYEXT.h"
#import <Photos/Photos.h>
#import "JYConst.h"
#import "JYProgressHUD.h"
#import "JYAsset.h"
#import "JYCollectionViewCell.h"
#import "JYForceTouchPreviewController.h"
#import "JYShowBigImgViewController.h"
#import "FMHeadView.h"
#import "UIScrollView+IndicatorExt.h"
#import "TYDecorationSectionLayout.h"
#import "LCActionSheet.h"
#import "VCFloatingActionButton.h"
#import "JYProcessView.h"
#import "AppDelegate.h"

@interface JYThumbVC ()<UICollectionViewDataSource, UICollectionViewDelegate, UIImagePickerControllerDelegate, UIViewControllerPreviewingDelegate, JYShowBigImgViewControllerDelegate, FMHeadViewDelegate, floatMenuDelegate> {
    NSInteger _currentScale;
    
}

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *collectionViewHConstraint;
@property (nonatomic, strong) NSMutableArray<JYAsset *> *sortedAssetsBackup;

@property (nonatomic, strong) NSMutableArray<JYAsset *> *localArrDataSourcesBackup;

@property (nonatomic, strong) NSMutableArray<WBAsset *> *netArrDataSourcesBackup;

@property (nonatomic, strong) NSMutableArray<JYAsset *> *arrDataSources;

@property (nonatomic, strong) NSMutableArray<NSString *> *timesArr;

@property (nonatomic, strong) NSMutableArray<JYAsset *> *choosePhotos;

@property (nonatomic, strong) NSMutableArray<NSIndexPath *> *chooseSection;

@property (strong, nonatomic) VCFloatingActionButton * addButton;

@property (strong, nonatomic) JYProcessView * pv;

@property (nonatomic) UIView * chooseHeadView;

@property (nonatomic, assign) BOOL isSelectMode;

@property (nonatomic, assign) BOOL isDownloading;

@property (nonatomic, copy) void(^downloadBlock)(BOOL success ,UIImage *image);

@end

@implementation JYThumbVC {
    UIButton * _leftBtn;//导航栏左边按钮
    UIButton * _rightbtn;//导航栏右边按钮
    UILabel * _countLb;
}

- (NSMutableArray<WBAsset *> *)netArrDataSourcesBackup {
    if(!_netArrDataSourcesBackup) {
        _netArrDataSourcesBackup = [NSMutableArray arrayWithCapacity:0];
    }
    return _netArrDataSourcesBackup;
}

- (NSMutableArray<JYAsset *> *)localArrDataSourcesBackup {
    if(!_localArrDataSourcesBackup)
        _localArrDataSourcesBackup = [NSMutableArray arrayWithCapacity:0];
    return _localArrDataSourcesBackup;
}

- (NSMutableArray<JYAsset *> *)arrDataSources
{
    if (!_arrDataSources) {
        _arrDataSources = [NSMutableArray arrayWithCapacity:0];
    }
    return _arrDataSources;
}

- (NSMutableArray<JYAsset *> *)choosePhotos {
    if(!_choosePhotos) {
        _choosePhotos = [NSMutableArray arrayWithCapacity:0];
    }
    return _choosePhotos;
}

- (NSMutableArray<NSIndexPath *> *)chooseSection {
    if(!_chooseSection) {
        _chooseSection = [NSMutableArray arrayWithCapacity:0];
    }
    return _chooseSection;
}

- (void)setIsSelectMode:(BOOL)isSelectMode {
    _isSelectMode = isSelectMode;
    if(!isSelectMode){
        [self.chooseSection removeAllObjects];
        [self.choosePhotos removeAllObjects];
    }
}

- (instancetype)initWithLocalDataSource:(NSArray<JYAsset *> *)assets {
    if(self = [super init]) {
        [self.arrDataSources addObjectsFromArray:assets];
        self.localArrDataSourcesBackup = [NSMutableArray  arrayWithArray:self.arrDataSources]; // backup
        _isSelectMode = NO;
    }
    return self;
}

- (void)addNetAssets:(NSArray<WBAsset *> *)assetsArr {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.netArrDataSourcesBackup = [NSMutableArray arrayWithArray: assetsArr];
        [self sort:[self merge]];
        [self.collectionView reloadData];
    });
}

// merge localAssets and netAssets, delete net same asset which local had
- (NSArray<JYAsset *> *)merge {
    NSMutableArray * localHashs = [NSMutableArray arrayWithCapacity:0];
    [self.localArrDataSourcesBackup enumerateObjectsUsingBlock:^(JYAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(!IsNilString(obj.digest)){
            [localHashs addObject:obj.digest];
        }
    }];
    NSMutableArray * netTmpArr = [NSMutableArray arrayWithCapacity:0];
    [self.netArrDataSourcesBackup enumerateObjectsUsingBlock:^(WBAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(![localHashs containsObject:obj.fmhash])
            [netTmpArr addObject:obj];
    }];
    NSMutableArray * mergedAssets = [NSMutableArray arrayWithArray:self.localArrDataSourcesBackup];
    [mergedAssets addObjectsFromArray:netTmpArr];
    return mergedAssets;
}

-(void)dealloc {
    if (self.collectionView.indicator) {
        [self.collectionView.indicator.slider removeObserver:self forKeyPath:@"sliderState"];
        [self.collectionView removeObserver:self.collectionView.indicator forKeyPath:@"contentOffset"];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"JYThumbVC dealloc");
}

-(void)sort:(NSArray<JYAsset *> *)assetsArr {
    NSMutableArray * arr = [NSMutableArray arrayWithArray:assetsArr];
    NSComparator cmptr = ^(JYAsset * photo1, JYAsset * photo2){
        NSDate * tempDate = [photo1.createDate laterDate: photo2.createDate];
        if ([tempDate isEqualToDate:photo1.createDate]) {
            return (NSComparisonResult)NSOrderedAscending;
        }
        if ([tempDate isEqualToDate: photo2.createDate]) {
            return (NSComparisonResult)NSOrderedDescending;
        }
        return (NSComparisonResult)NSOrderedSame;
    };
    [arr sortUsingComparator:cmptr];
    self.sortedAssetsBackup = [NSMutableArray arrayWithArray:arr];
    NSMutableArray * tArr = [NSMutableArray array];//时间组
    NSMutableArray * pGroupArr = [NSMutableArray array];//照片组数组
    if (arr.count>0) {
        JYAsset * photo = arr[0];
        photo.indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        NSMutableArray * photoDateGroup1 = [NSMutableArray array];//第一组照片
        [photoDateGroup1 addObject:photo];
        [pGroupArr addObject:photoDateGroup1];
        [tArr addObject:photo.createDate];
        
        NSMutableArray * photoDateGroup2 = photoDateGroup1;//最近的一组
        for (int i = 1 ; i < arr.count; i++) {
            @autoreleasepool {
                JYAsset * photo1 =  arr[i];
                JYAsset * photo2 = arr[i-1];
                if ([self isSameDay:photo1.createDate date2: photo2.createDate]) {
                    photo1.indexPath = [NSIndexPath indexPathForRow:((NSArray *)pGroupArr[pGroupArr.count - 1]).count inSection:pGroupArr.count - 1];
                    [photoDateGroup2 addObject:photo1];
                }
                else{
                    photo1.indexPath = [NSIndexPath indexPathForRow:0 inSection:pGroupArr.count];
                    [tArr addObject: photo1.createDate];
                    photoDateGroup2 = nil;
                    photoDateGroup2 = [NSMutableArray array];
                    [photoDateGroup2 addObject:photo1];
                    [pGroupArr addObject:photoDateGroup2];
                }
            }
        }
    }
    self.arrDataSources = pGroupArr;
    self.timesArr = tArr;
}

- (BOOL)isSameDay:(NSDate *)date1 date2:(NSDate *)date2 {
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    unsigned unitFlag = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
    
    NSDateComponents *comp1 = [calendar components:unitFlag fromDate:date1];
    
    NSDateComponents *comp2 = [calendar components:unitFlag fromDate:date2];
    
    return (([comp1 day] == [comp2 day]) && ([comp1 month] == [comp2 month]) && ([comp1 year] == [comp2 year]));
    
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.showIndicator = YES;
    [self sort:self.arrDataSources];
    [self addRightBtn];
    [self initCollectionView];
    [self addPinchGesture];
    [self createControlbtn];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userAuthChange:) name:ASSETS_AUTH_CHANGE_NOTIFY object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(assetDidChangeHandle:) name:ASSETS_UPDATE_NOTIFY object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hashCalculateHandle) name:HashCalculateFinishedNotify object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self updateIndicatorFrame];
}

//!!!!: ASSETS_UPDATE_NOTIFY Handler
- (void)assetDidChangeHandle:(NSNotification *)notify {
    NSLog(@"%@", notify.object);
    NSDictionary * changeDic = notify.object;
    NSArray * removeArr = changeDic[ASSETS_REMOVEED_KEY];
    NSArray * insertArr = changeDic[ASSETS_INSERTSED_KEY];
    if(removeArr && removeArr.count)
        [self.localArrDataSourcesBackup removeObjectsInArray:removeArr];
    if(insertArr && insertArr.count)
        [self.localArrDataSourcesBackup addObjectsFromArray:insertArr];
    [self sort:[self merge]];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.collectionView reloadData];
    });
}

//!!!!: ASSETS_AUTH_CHANGE_NOTIFY
- (void)userAuthChange:(NSNotification *)notify {
    NSMutableArray * allPhotos = [NSMutableArray arrayWithArray:WB_AppServices.assetServices.allAssets];
    self.localArrDataSourcesBackup = allPhotos;
    [self sort:[self merge]];
}

//!!!!:HashCalculateFinishedNotify
- (void)hashCalculateHandle {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self sort: [self merge]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.collectionView reloadData];
        });
    });
}

-(void)createControlbtn {
    if(!_addButton){
        CGRect floatFrame = CGRectMake(__kWidth - 80 , __kHeight - 64 - 56 - 88, 56, 56);
        _addButton = [[VCFloatingActionButton alloc]initWithFrame:floatFrame normalImage:[UIImage imageNamed:@"add_album"] andPressedImage:[UIImage imageNamed:@"icon_close"] withScrollview:_collectionView];
        _addButton.automaticallyInsets = YES;
        _addButton.imageArray = @[@"fab_share"];
        _addButton.labelArray = @[@""];
        _addButton.delegate = self;
        _addButton.hidden = YES;
        [self.view addSubview:_addButton];
    }
}

-(void)addRightBtn{
    
    
    UIButton * rightBtn = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 24, 24)];
    [rightBtn setImage:[UIImage imageNamed:@"more"] forState:UIControlStateNormal];
    [rightBtn setImage:[UIImage imageNamed:@"more_highlight"] forState:UIControlStateHighlighted];    [rightBtn addTarget:self action:@selector(rightBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem * rightItem = [[UIBarButtonItem alloc]initWithCustomView:rightBtn];
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:rightItem,nil];
}

-(void)rightBtnClick:(id)sender{
    LCActionSheet *actionSheet = [[LCActionSheet alloc] initWithTitle:nil
                                                             delegate:nil
                                                    cancelButtonTitle:@"取消"
                                                otherButtonTitleArray:@[@"选择照片"]];
    actionSheet.clickedHandle = ^(LCActionSheet *actionSheet, NSInteger buttonIndex){
        if (buttonIndex == 1) {
            self.isSelectMode = YES;
            [self.collectionView reloadData];
            [self addLeftBtn];
            _addButton.hidden = NO;
        }
    };
    actionSheet.scrolling          = YES;
    actionSheet.buttonHeight       = 60.0f;
    actionSheet.visibleButtonCount = 3.6f;
    [actionSheet show];
}

//添加 可选视图 左边按钮
-(void)addLeftBtn{
    if (!_chooseHeadView) {
        _chooseHeadView = [[UIView alloc]initWithFrame:CGRectMake(0, -64, __kWidth, 64)];
        _chooseHeadView.backgroundColor = UICOLOR_RGB(0x03a9f4);
        UIButton * leftBtn = [[UIButton alloc]initWithFrame:CGRectMake(0, 16, 48, 48 )];
        UIImage * backImage = [UIImage imageNamed:@"back"];
        [leftBtn setImage:backImage forState:UIControlStateNormal];
        [leftBtn addTarget:self action:@selector(leftBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        _leftBtn = leftBtn;
        
        UILabel * countLb = [[UILabel alloc]initWithFrame:CGRectMake(__kWidth/2 - 50, 27, 100, 30)];
        countLb.textColor = [UIColor whiteColor];
        countLb.font = [UIFont fontWithName:Helvetica size:17];
        countLb.textAlignment = NSTextAlignmentCenter;
        _countLb = countLb;
        [_chooseHeadView addSubview:countLb];
        [_chooseHeadView addSubview:leftBtn];
        [self.navigationController.view addSubview:_chooseHeadView];
    }
    //    _countLb.text = @"选择照片";
    _countLb.font = [UIFont fontWithName:FANGZHENG size:16];
    [UIView animateWithDuration:0.5 animations:^{
        _chooseHeadView.transform = CGAffineTransformTranslate(_chooseHeadView.transform, 0, 64);
    }];
    [self tabBarAnimationWithHidden:YES];
}

-(void)leftBtnClick:(id)sender{
    [UIView animateWithDuration:0.5 animations:^{
        _chooseHeadView.transform = CGAffineTransformTranslate(_chooseHeadView.transform, 0, -64);
    }];
    _rightbtn.userInteractionEnabled = YES;
    self.isSelectMode = NO;
    [self.collectionView reloadData];
    _addButton.hidden = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self tabBarAnimationWithHidden:NO];
    });
    //    if (_edgeGesture) {
    //        [self.view removeGestureRecognizer:_edgeGesture];
    //        _edgeGesture = nil;
    //    }
}

//tabbar 动画
-(void)tabBarAnimationWithHidden:(BOOL)hidden{
    NSLog(@"%f", CGRectGetHeight(self.collectionView.frame));
    CYLTabBarController * tabBar = self.cyl_tabBarController;
    if (hidden) {
        [tabBar.tabBar setHidden:YES];
        self.collectionViewHConstraint.constant += 44;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self updateIndicatorFrame];
        });
    }else{
        [tabBar.tabBar setHidden:NO];
        self.collectionViewHConstraint.constant -= 44;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self updateIndicatorFrame];
        });
        
    }
}

//增加捏合手势
-(void)addPinchGesture{
    UIPinchGestureRecognizer * pin = [[UIPinchGestureRecognizer alloc]initWithTarget:self action:@selector(handlePinch:)];
    [self.collectionView addGestureRecognizer:pin];
}

//捏合响应
-(void)handlePinch:(UIPinchGestureRecognizer *)pin{
    if (pin.state == UIGestureRecognizerStateBegan) {
        BOOL isSmall = pin.scale > 1.0f;
        [self changeFlowLayoutIsBeSmall:!isSmall];
        [self.collectionView reloadData];
    }
}

-(void)changeFlowLayoutIsBeSmall:(BOOL)isSmall{
    if ((!isSmall && _currentScale == 1) || (isSmall && _currentScale == 6))
        return;
    TYDecorationSectionLayout *layout = [[TYDecorationSectionLayout alloc]init];
    //layout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
    layout.alternateDecorationViews = YES;
    // costom xib names
    layout.decorationViewOfKinds = @[@"FMHeadView"];
    layout.scrollDirection=UICollectionViewScrollDirectionVertical;
    //    layout.sectionInset = UIEdgeInsetsMake(0, 0, 20, 0);
    layout.minimumLineSpacing = 2;
    layout.minimumInteritemSpacing = 2;
    //    if(kSystemVersion >= 9.0)
    layout.sectionHeadersPinToVisibleBounds = NO;
    _currentScale = isSmall ? _currentScale + 1 : _currentScale - 1;
    
    layout.itemSize = CGSizeMake((kViewWidth- 2*(_currentScale-1))/_currentScale, (kViewWidth- 2*(_currentScale-1))/_currentScale);
    [self.collectionView setCollectionViewLayout:layout animated:YES];
    //    [self.collectionView reloadData];
}


-(void)deviceOrientationChanged:(UIDeviceOrientation)ori
{
    
}

- (void)initCollectionView
{
    _currentScale = 3;
    TYDecorationSectionLayout *_fmCollectionViewLayout = [[TYDecorationSectionLayout alloc]init];
    _fmCollectionViewLayout.alternateDecorationViews = YES;
    _fmCollectionViewLayout.decorationViewOfKinds = @[@"FMHeadView"];
    _fmCollectionViewLayout.scrollDirection=UICollectionViewScrollDirectionVertical;
    _fmCollectionViewLayout.minimumLineSpacing = 2;
    _fmCollectionViewLayout.minimumInteritemSpacing = 2;
    _fmCollectionViewLayout.itemSize = CGSizeMake((kViewWidth- 2*(_currentScale-1))/_currentScale, (kViewWidth- 2*(_currentScale-1))/_currentScale);
    
    
    self.collectionView.collectionViewLayout = _fmCollectionViewLayout;
    self.collectionView.backgroundColor = [UIColor whiteColor];
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    [self.collectionView registerClass:[FMHeadView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"headView"];
    
    [self.collectionView registerClass:NSClassFromString(@"JYCollectionViewCell") forCellWithReuseIdentifier:@"JYCollectionViewCell"];
    //注册3d touch
    if ([self forceTouchAvailable])
        [self registerForPreviewingWithDelegate:self sourceView:self.collectionView];
    [self.collectionView reloadData];
    
    if(_showIndicator) [self initIndicator];
}

- (void)initIndicator{
    [self.collectionView registerILSIndicator];
    [self.collectionView.indicator.slider addObserver:self forKeyPath:@"sliderState" options:0x01 context:nil];
    self.collectionView.indicator.frame = CGRectMake(self.collectionView.indicator.frame.origin.x, self.collectionView.indicator.frame.origin.y, 1, CGRectGetHeight(self.collectionView.frame) - 2 * kILSDefaultSliderMargin);
}

- (void)updateIndicatorFrame {
    self.collectionView.indicator.frame = CGRectMake(self.collectionView.indicator.frame.origin.x, self.collectionView.indicator.frame.origin.y, 1, CGRectGetHeight(self.collectionView.frame));
}

- (BOOL)forceTouchAvailable
{
    if ([UIDevice currentDevice].systemVersion.floatValue >= 9.0) {
        return self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable;
    } else {
        return NO;
    }
}

- (UIViewController *)getBigImageVCWithData:(NSArray<JYAsset *> *)data index:(NSInteger)index
{
    JYShowBigImgViewController *vc = [[JYShowBigImgViewController alloc] init];
    vc.delegate = self;
    vc.models = data.copy;
    vc.selectIndex = index;
    JYCollectionViewCell * cell = (JYCollectionViewCell *)[_collectionView cellForItemAtIndexPath:[_collectionView indexPathsForSelectedItems].firstObject];
    vc.senderViewForAnimation = cell;
    vc.scaleImage = cell.imageView.image;
    //    weakify(self);
    [vc setBtnBackBlock:^(NSArray<JYAsset *> *selectedModels, BOOL isOriginal) {
        //        strongify(weakSelf);
        //        [strongSelf.collectionView reloadData];
    }];
    return vc;
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.arrDataSources.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return ((NSArray *)self.arrDataSources[section]).count;
}

//head的高度
-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section{
    CGSize size = { kViewWidth, 42 };
    return size;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    JYCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"JYCollectionViewCell" forIndexPath:indexPath];
    
    JYAsset *model;
    model = ((NSMutableArray *)self.arrDataSources[indexPath.section])[indexPath.row];
    
    jy_weakify(self);
    cell.selectedBlock = ^(BOOL selected) {
        if(!weakSelf.isSelectMode) return;
        BOOL needReload = NO;
        if(selected) {
            [weakSelf.choosePhotos addObject:model];
            __block BOOL containAll = YES;
            [(NSArray *)weakSelf.arrDataSources[indexPath.section] enumerateObjectsUsingBlock:^(JYAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if(![weakSelf.choosePhotos containsObject:obj]) {
                    containAll = NO;
                    *stop = YES;
                }
            }];
            if(containAll) [weakSelf.chooseSection addObject:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
            needReload = containAll;
        }else {
            [weakSelf.choosePhotos removeObject:model];
            NSIndexPath * indexP = [NSIndexPath indexPathForRow:0 inSection:indexPath.section];
            if([weakSelf.chooseSection containsObject:indexP]){
                [weakSelf.chooseSection removeObject:indexP];
                needReload = YES;
            }
        }
        if(needReload)
            [weakSelf.collectionView reloadData];
    };
    
    cell.longPressBlock = ^() {
        if(weakSelf.isSelectMode) return;
        weakSelf.isSelectMode = true;
        [weakSelf addLeftBtn];
        weakSelf.addButton.hidden = NO;
        [weakSelf.collectionView reloadData];
    };
    
    if (collectionView.indicator) {
        collectionView.indicator.slider.timeLabel.text = [self getMouthDateStringWithPhoto:model.createDate];
    }
    cell.isSelectMode = self.isSelectMode;
    [cell setIsSelect: _isSelectMode ? [self.choosePhotos containsObject:model] : NO animation:NO];
    cell.model = model;
    
    return cell;
}

//headView
- (FMHeadView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
    FMHeadView * headView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"headView" forIndexPath:indexPath];
    headView.headTitle = [self getDateStringWithPhoto: ((JYAsset *)((NSMutableArray *)_arrDataSources[indexPath.section])[indexPath.row]).createDate];
    headView.fmIndexPath = indexPath;
    headView.isSelectMode = _isSelectMode;
    headView.isChoose = [self.chooseSection containsObject:indexPath];
    headView.fmDelegate = self;
    return headView;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if(_isSelectMode) {
        JYCollectionViewCell * cell = (JYCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
        if(cell){
            [cell btnSelectClick:nil];
        }
    }else{
        JYAsset *model = ((NSMutableArray *)self.arrDataSources[indexPath.section])[indexPath.row];
        UIViewController *vc = [self getMatchVCWithModel:model];
        if (vc) [self presentViewController:vc animated:YES completion:nil];
    }
}

- (UIViewController *)getMatchVCWithModel:(JYAsset *)model
{
    NSArray *arr = [self.sortedAssetsBackup copy];
    return [self getBigImageVCWithData:arr index: [arr indexOfObject:model]];
}
#pragma mark - UIViewControllerPreviewingDelegate
//!!!!: 3D Touch
- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location
{
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:location];
    
    if (!indexPath) {
        return nil;
    }
    
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    
    //设置突出区域
    previewingContext.sourceRect = [self.collectionView cellForItemAtIndexPath:indexPath].frame;
    JYForceTouchPreviewController *vc = [[JYForceTouchPreviewController alloc] init];
    JYAsset *model = ((NSMutableArray *)self.arrDataSources[indexPath.section])[indexPath.row];
    vc.model = model;
    vc.placeHolder = [(JYCollectionViewCell *)cell imageView].image;
    vc.allowSelectGif = YES;
    vc.allowSelectLivePhoto = YES;
    vc.preferredContentSize = [self getSize:model];
    
    return vc;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit
{
    if(_isSelectMode) return;
    JYAsset *model = [(JYForceTouchPreviewController *)viewControllerToCommit model];
    
    UIViewController *vc = [self getMatchVCWithModel:model];
    if (vc) {
        [self presentViewController:vc animated:YES completion:nil];
    }
}

- (CGSize)getSize:(JYAsset *)model
{   CGFloat w, h;
    
    if(model.asset){
        w = MIN(model.asset.pixelWidth, kViewWidth);
        h = w * model.asset.pixelHeight / model.asset.pixelWidth;
    }else{
        w = MIN([(WBAsset *)model w], kViewWidth);
        h = w * [(WBAsset *)model h] / [(WBAsset *)model w];
    }
    
    if (isnan(h)) return CGSizeZero;
    
    if (h > kViewHeight || isnan(h)) {
        h = kViewHeight;
        w = model.asset ? h * model.asset.pixelWidth / model.asset.pixelHeight
        : h * [(WBAsset *)model w]  /  [(WBAsset *)model h];
    }
    
    return CGSizeMake(w, h);
}

#pragma mark - util

-(NSString *)getDateStringWithPhoto:(NSDate *)date{
    NSDateFormatter * formatter1 = [[NSDateFormatter alloc]init];
    formatter1.dateFormat = @"yyyy-MM-dd";
    NSString * dateString = [formatter1 stringFromDate:date];
    return dateString;
}

-(NSString *)getMouthDateStringWithPhoto:(NSDate *)date{
    NSDateFormatter * formatter1 = [[NSDateFormatter alloc]init];
    formatter1.dateFormat = @"yyyy年MM月";
    NSString * dateString = [formatter1 stringFromDate:date];
    if ([dateString isEqualToString: @"1970年01月"]) {
        dateString = @"未知时间";
    }
    return dateString;
}
#pragma mark - Add Indicator

bool isAnimation = NO;
bool isDecelerating = NO;

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    isDecelerating = YES;
    
    if (self.showIndicator) {
        if (!self.collectionView.indicator) {
            //导航按钮
            [self.collectionView registerILSIndicator];
            [self.collectionView.indicator.slider addObserver:self forKeyPath:@"sliderState" options:0x01 context:nil];
        }else {
            if (!isAnimation) {
                self.collectionView.indicator.transform = CGAffineTransformIdentity;
            }else{
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    self.collectionView.indicator.transform = CGAffineTransformIdentity;
                });
            }
        }
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView{
    [self hiddenIndicator];
}

-(void)hiddenIndicator{
    if (self.showIndicator) {
        if (self.collectionView.indicator.slider.sliderState == UIControlStateNormal && CGAffineTransformIsIdentity(self.collectionView.indicator.transform)) {
            isDecelerating = NO;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if(!isDecelerating){
                    isAnimation = YES;
                    [UIView animateWithDuration:0.5 animations:^{
                        self.collectionView.indicator.transform = CGAffineTransformMakeTranslation(40, 0);
                    }completion:^(BOOL finished) {
                        isAnimation = NO;
                        isDecelerating = NO;
                    }];
                    
                }
            });
            
        }
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if(!decelerate) [self hiddenIndicator];
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    [self hiddenIndicator];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    if (self.showIndicator) {
        if ([keyPath isEqualToString:@"sliderState"]) {
            if (self.collectionView.indicator.slider.sliderState == UIControlStateNormal && CGAffineTransformIsIdentity(self.collectionView.indicator.transform)) {
                isDecelerating = NO;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if(!isDecelerating){
                        isAnimation = YES;
                        [UIView animateWithDuration:0.5 animations:^{
                            self.collectionView.indicator.transform = CGAffineTransformMakeTranslation(40, 0);
                        }completion:^(BOOL finished) {
                            isAnimation = NO;
                            isDecelerating = NO;
                        }];
                    }
                });
            }else
                isDecelerating = YES;
        }
    }
}

#pragma mark - photobrowser delegate

- (void)photoBrowser:(JYShowBigImgViewController *)browser scrollToIndexPath:(NSIndexPath *)indexPath {
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
    [self.collectionView layoutIfNeeded];
    return;
}

- (UIView *)photoBrowser:(JYShowBigImgViewController *)browser willDismissAtIndexPath:(NSIndexPath *)indexPath {
    JYCollectionViewCell *cell = (JYCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    return cell;
}

#pragma mark - FMHeadViewDelegate

-(void)FMHeadView:(FMHeadView *)headView isChooseBtn:(BOOL)isChoose {
    if(isChoose) {
        [self.chooseSection addObject:headView.fmIndexPath];
        [self.choosePhotos addObjectsFromArray:(NSArray *)self.arrDataSources[headView.fmIndexPath.section]];
    }else{
        [self.chooseSection removeObject:headView.fmIndexPath];
        [self.choosePhotos removeObjectsInArray:(NSArray *)self.arrDataSources[headView.fmIndexPath.section]];
    }
    [self.collectionView reloadData];
}

#pragma mark - floatBtn delegate
-(void)didSelectMenuOptionAtIndex:(NSInteger)row{
    NSLog(@"创建Share");
    [self clickShareBtn];
}

-(void)clickShareBtn{
    if (self.choosePhotos.count>0) {
        [self shareToOtherApp];
    }
    else
        [SXLoadingView showAlertHUD:@"请先选择照片" duration:1];
}

//其他分享
-(void)shareToOtherApp{
    //准备照片
    @weaky(self);
    [self clickDownloadWithShare:YES andCompleteBlock:^(NSArray *images) {
        UIActivityViewController *activityVC = [[UIActivityViewController alloc]initWithActivityItems:images applicationActivities:nil];
        //初始化回调方法
        UIActivityViewControllerCompletionWithItemsHandler myBlock = ^(NSString *activityType,BOOL completed,NSArray *returnedItems,NSError *activityError)
        {
            NSLog(@"activityType :%@", activityType);
            if (completed)
            {
                NSLog(@"share completed");
            }
            else
            {
                NSLog(@"share cancel");
            }
            
        };
        
        // 初始化completionHandler，当post结束之后（无论是done还是cancel）该blog都会被调用
        activityVC.completionWithItemsHandler = myBlock;
        
        //关闭系统的一些activity类型 UIActivityTypeAirDrop 屏蔽aridrop
        activityVC.excludedActivityTypes = @[];
        
        [weak_self presentViewController:activityVC animated:YES completion:nil];
    }];
}

-(void)clickDownloadWithShare:(BOOL)share andCompleteBlock:(void(^)(NSArray * images))block{
    NSArray * chooseItems = [self.choosePhotos copy];
    if (!_pv)
        _pv = [JYProcessView processViewWithType:ProcessTypeLine];
    _pv.descLb.text = share?@"正在准备照片":@"正在下载文件";
    _pv.subDescLb.text = [NSString stringWithFormat:@"%lu个项目 ",(unsigned long)chooseItems.count];
    [_pv show];
    _isDownloading = YES;
    _pv.cancleBlock = ^(){
        _isDownloading = NO;
    };
    [self downloadItems:chooseItems withShare:share andCompleteBlock:block];
    [self leftBtnClick:_leftBtn];
}

-(void)downloadItems:(NSArray *)items withShare:(BOOL)isShare andCompleteBlock:(void(^)(NSArray * images))block{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            __block float complete = 0.f;
            __block int successCount = 0;
            __block int finish = 0;
            __block NSUInteger allCount = items.count;
            @weaky(self);
            NSMutableArray * tempDownArr = [NSMutableArray arrayWithCapacity:0];
            self.downloadBlock = ^(BOOL success ,UIImage *image){
                complete ++;finish ++;
                if (successCount) successCount++;
                CGFloat progress =  complete/allCount;
                if (image && isShare) [tempDownArr addObject:image];
                [weak_self.pv setValueForProcess:progress];
                if (items.count > complete) {
                    if (weak_self.isDownloading) {
                        [weak_self downloadItem:items[finish] withShare:isShare withCompleteBlock: weak_self.downloadBlock];
                    }
                }else{
                    _isDownloading = NO;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weak_self.pv dismiss];
                        if (!isShare)
                            [SXLoadingView showAlertHUD:@"下载完成" duration:1];
                        if (block) block([tempDownArr copy]);
                    });
                }
            };
            if (_isDownloading) {
                [self downloadItem:items[0] withShare:isShare withCompleteBlock:self.downloadBlock];
            }
        }
    });
}

-(void)downloadItem:(JYAsset *)item withShare:(BOOL)share withCompleteBlock:(void(^)(BOOL isSuccess,UIImage * image))block{
    if ([item isKindOfClass:[WBAsset class]]) {
        NSLog(@"%lu",(unsigned long)item.type);
        if (item.type == JYAssetTypeNetImage) {
            __block id<SDWebImageOperation> operation =  [WB_NetService getHighWebImageWithHash:[(WBAsset *)item fmhash] completeBlock:^(NSError *error, UIImage *img) {
                if (error) {
                    NSLog(@"%@",error);
                    // TODO: Load Error Image
                    block(NO,nil);
                } else {
                    if (img) {
                        if(!share){
                            [PHPhotoLibrary saveImageToAlbum:img completion:^(BOOL isSuccess, PHAsset * asset) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    block(isSuccess,img);
                                });
                            }];
                        }else{
                            dispatch_async(dispatch_get_main_queue(), ^{
                                block(YES,img);
                            });
                        }
                    }else
                        dispatch_async(dispatch_get_main_queue(), ^{
                            block(NO,nil);
                        });
                    NSLog(@"%@",img);
                }
                [operation cancel];
                operation = nil;
            }];
        }
    }else{
        NSLog(@"%@",item.asset) ;
        if (item.asset) {
            if (!share) {
                [item.asset getFile:^(NSError *error, NSString *filePath) {
                    if (item.type == JYAssetTypeImage || item.type == JYAssetTypeLivePhoto) {
                        UIImage * image;
                        if (filePath && (image = [UIImage imageWithContentsOfFile:filePath])) {
                            [PHPhotoLibrary saveImageToAlbum:image completion:^(BOOL isSuccess, PHAsset * asset) {
                                [[NSFileManager defaultManager]removeItemAtPath:filePath error:nil];//删除image
                                block(isSuccess,image);
                            }];
                        }else block(NO,nil);
                    }
                }];
            }else{
                if (item.type == JYAssetTypeImage || item.type == JYAssetTypeLivePhoto) {
                    [PHPhotoLibrary requestOriginalImageSyncForAsset:item.asset completion:^(NSError *error, UIImage *image, NSDictionary *dic) {
                        if(error) return block(NO, nil);
                        block(YES, image);
                    }];
                }
            }
        }else
            block(NO,nil);
    }
}

@end

