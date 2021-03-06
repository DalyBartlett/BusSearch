//
//  JWMainViewController.m
//  BusRider
//
//  Created by John Wong on 12/15/14.
//  Copyright (c) 2014 John Wong. All rights reserved.
//

#import "JWMainViewController.h"
#import "JWSearchRequest.h"
#import "JWBusLineViewController.h"
#import "JWViewUtil.h"
#import "JWSearchListItem.h"
#import "JWSearchLineItem.h"
#import "JWSearchStopItem.h"
#import "JWSearchTableViewCell.h"
#import "JWUserDefaultsUtil.h"
#import "UINavigationController+SGProgress.h"
#import "JWMainTableViewCell.h"
#import "JWStopTableViewController.h"
#import "JWBusInfoItem.h"
#import "JWNavigationCenterView.h"
#import "JWCityRequest.h"
#import "JWCityItem.h"
#import "AHKActionSheet.h"
#import "CBStoreHouseRefreshControl.h"
#import "JWMainEmptyTableViewCell.h"
#import "JWSessionManager.h"
#import "JWMainTableViewStopCell.h"
#import <objc/runtime.h>
#import "WeatherViewController.h"

#define JWCellIdMain @"JWCellIdMain"
#define JWCellIdMainStop @"JWCellIdMainStop"
#define JWCellIdEmpty @"JWCellIdEmpty"
#define JWCellIdSearch @"JWCellIdSearch"

typedef NS_ENUM(NSInteger, JWSearchResultType) {
    JWSearchResultTypeNone = 0,
    JWSearchResultTypeList = 1,
    JWSearchResultTypeSingle = 2
};


@interface JWMainViewController () <UITableViewDataSource, UITableViewDelegate, JWNavigationCenterDelegate, UIScrollViewDelegate,CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *searchBarHeight;
@property (nonatomic, strong) JWSearchRequest *searchRequest;
@property (nonatomic, strong) JWSearchListItem *searchListItem;
@property (nonatomic, strong) NSString *cityName;
/**
 *  array of JWSearchLineItem
 */
@property (nonatomic, strong) NSMutableArray *collectLineItem;

@property (strong, nonatomic) IBOutlet UISearchDisplayController *searchController;

/**
 *  Pass to JWBusLineViewController
 */
@property (nonatomic, strong) JWSearchLineItem *lineItem;
/**
 *  Pass to JWBusLineViewController
 */
@property (nonatomic, strong) JWBusInfoItem *busInfoItem;
/**
 *  Pass to JWStopViewController
 */
@property (nonatomic, strong) JWSearchStopItem *selectedStop;
@property (nonatomic, strong) JWNavigationCenterView *cityButtonItem;
@property (nonatomic, strong) JWCityRequest *cityRequest;
@property (nonatomic, strong) CBStoreHouseRefreshControl *storeHouseRefreshControl;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, retain) CLLocation *currentLocation;
@property (nonatomic, assign)  CLLocationCoordinate2D Weather2d;

@end


@implementation JWMainViewController

#pragma mark lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    _cityName = [JWUserDefaultsUtil cityItem].cityName;
    
    
    self.locationManager = [CLLocationManager new];
    self.locationManager.delegate = self;
    if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedWhenInUse || [CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedAlways) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    self.locationManager.distanceFilter = kCLDistanceFilterNone;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    [self.locationManager startUpdatingLocation];
    
    UIButton * buttonright = [UIButton buttonWithType:UIButtonTypeCustom];
    [buttonright setTitle:@"☁️"
            forState:UIControlStateNormal];
    [buttonright addTarget:self action:@selector(GotoWeatherInfoViewAction:) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *RightItem = [[UIBarButtonItem alloc]initWithCustomView:buttonright];
    UIBarButtonItem *cityRightItem = [[UIBarButtonItem alloc] initWithCustomView:self.cityButtonItem];
    self.navigationItem.rightBarButtonItems = @[cityRightItem,RightItem];
//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.cityButtonItem];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:nil action:nil];
    [self.searchController.searchResultsTableView registerNib:[UINib nibWithNibName:@"JWSearchTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:JWCellIdSearch];
    self.tableView.backgroundColor = HEXCOLOR(0xefeff6);
    [self.tableView registerNib:[UINib nibWithNibName:@"JWMainTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:JWCellIdMain];
    [self.tableView registerNib:[UINib nibWithNibName:@"JWMainTableViewStopCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:JWCellIdMainStop];
    [self.tableView registerNib:[UINib nibWithNibName:@"JWMainEmptyTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:JWCellIdEmpty];
    //    self.tableView.tableFooterView = [[UIView alloc] init];
    self.searchController.searchBar.showsScopeBar = YES;
    self.storeHouseRefreshControl = [CBStoreHouseRefreshControl attachToScrollView:self.tableView
                                                                            target:self
                                                                     refreshAction:@selector(loadData)
                                                                             plist:@"bus"
                                                                             color:HEXCOLOR(0x007AFF)
                                                                         lineWidth:1
                                                                        dropHeight:90
                                                                             scale:1
                                                              horizontalRandomness:150
                                                           reverseLoadingAnimation:YES
                                                           internalAnimationFactor:1];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:kNotificationContextUpdate object:nil];
}
-(void)GotoWeatherInfoViewAction:(UIButton *)sender {
    if(self.currentLocation.coordinate.latitude == 0.0 || self.currentLocation.coordinate.longitude == 0.0)
    {
        [self _alertWithTitle:@"Propmt" message:@"No current location found,Please check whether to run the app for location permission"];
        return ;
    }else
    {
        WeatherViewController *weather = [[WeatherViewController alloc]init];
        weather.loaction = self.currentLocation;
        weather.lat = self.Weather2d.latitude;
        weather.lng = self.Weather2d.longitude;
        [self presentViewController:weather animated:YES completion:nil];
    }
}
-(void)_alertWithTitle:(NSString *)title message:(NSString *)message {
    [[[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
}

#pragma mark - CLLocationManager delegate methods

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    if ([locations count]) {
        NSLog(@"Updated locations: %@", locations);
        if ([locations[0] isKindOfClass:[CLLocation class]]) {
            self.currentLocation = locations[0];
            self.Weather2d = self.currentLocation.coordinate;
            if(self.currentLocation.coordinate.latitude > 0.00 && self.currentLocation.coordinate.longitude > 0.00)
            [self.locationManager stopUpdatingLocation];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.storeHouseRefreshControl scrollViewDidAppear];
    [self loadData];
    JWCityItem *cityItem = [JWUserDefaultsUtil cityItem];
    if (cityItem && ![cityItem.cityName isEqualToString:_cityName]) {
        _cityName = cityItem.cityName;
        _cityButtonItem = nil;
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.cityButtonItem];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController cancelSGProgress];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:JWSeguePushLineWithId]) {
        if ([segue.destinationViewController isKindOfClass:[JWBusLineViewController class]]) {
            JWBusLineViewController *busLineViewController = (JWBusLineViewController *)segue.destinationViewController;
            busLineViewController.lineId = self.selectedLineId;
            busLineViewController.lineNumber = self.selectedLineNumber;
        }
    } else if ([segue.identifier isEqualToString:JWSeguePushStopList]) {
        if ([segue.destinationViewController isKindOfClass:[JWStopTableViewController class]]) {
            JWStopTableViewController *stopTableViewController = (JWStopTableViewController *)segue.destinationViewController;
            stopTableViewController.stopItem = self.selectedStop;
        }
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.tableView) {
        return self.collectLineItem.count ?: 1;
    } else {
        if (self.searchListItem) {
            if (section == 0 && self.searchListItem.lineList.count > 0) {
                return self.searchListItem.lineList.count;
            } else {
                return self.searchListItem.stopList.count;
            }
        } else {
            return 0;
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == self.tableView) {
        return 1;
    } else {
        if (self.searchListItem) {
            return (self.searchListItem.lineList.count == 0 ? 0 : 1) + (self.searchListItem.stopList.count == 0 ? 0 : 1);
        } else {
            return 0;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.tableView) {
        if (self.collectLineItem.count > 0) {
            JWCollectItem *item = self.collectLineItem[indexPath.row];
            if (item.itemType == JWCollectItemTypeLine) {
                JWMainTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:JWCellIdMain forIndexPath:indexPath];
                cell.titleLabel.text = item.lineNumber;
                cell.stopLabel.text = item.stopName;
                cell.subTitle.text = [NSString stringWithFormat:@"%@-%@", item.from, item.to];
                return cell;
            } else {
                JWMainTableViewStopCell *cell = [tableView dequeueReusableCellWithIdentifier:JWCellIdMainStop forIndexPath:indexPath];
                cell.titleLabel.text = item.stopName;
                return cell;
            }
        } else {
            JWMainEmptyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:JWCellIdEmpty forIndexPath:indexPath];
            cell.titleLabel.text = @"未收藏公交线路";
            cell.subTitle.text = @"点击搜索框找到想要的线路。收藏后就会出现在这里";
            return cell;
        }
    } else {
        JWSearchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:JWCellIdSearch forIndexPath:indexPath];
        if (indexPath.section == 0 && self.searchListItem.lineList.count > 0) {
            JWSearchLineItem *lineItem = self.searchListItem.lineList[indexPath.row];
            cell.titleLabel.text = lineItem.lineNumber;
            cell.iconView.image = [UIImage imageNamed:@"JWIconCellBus"];
            cell.subTitleLabel.text = [NSString stringWithFormat:@"%@-%@", lineItem.from, lineItem.to];
        } else {
            JWSearchStopItem *stopItem = self.searchListItem.stopList[indexPath.row];
            cell.titleLabel.text = stopItem.stopName;
            cell.iconView.image = [UIImage imageNamed:@"JWIconCellStop"];
            cell.subTitleLabel.text = nil;
        }
        return cell;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (tableView == self.tableView) {
    } else {
        if (section == 0 && self.searchListItem.lineList.count > 0) {
            return @"公交路线";
        } else {
            return @"公交站点";
        }
    }
    return nil;
}

#pragma mark UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.tableView) {
        if (self.collectLineItem.count == 0) {
            return 54;
        } else {
            return 54;
        }
    } else {
        return 44;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == self.tableView) {
        if (self.collectLineItem.count > 0) {
            JWCollectItem *item = self.collectLineItem[indexPath.row];
            if (item.itemType == JWCollectItemTypeLine) {
                self.selectedLineId = item.lineId;
                self.selectedLineNumber = item.lineNumber;
                [self performSegueWithIdentifier:JWSeguePushLineWithId sender:self];
            } else if (item.itemType == JWCollectItemTypeStop) {
                self.selectedStop = [[JWSearchStopItem alloc] initWithStopId:item.stopId stopName:item.stopName];
                [self performSegueWithIdentifier:JWSeguePushStopList sender:self];
            }
        }
    } else {
        if (indexPath.section == 0 && self.searchListItem.lineList.count > 0) {
            JWSearchLineItem *lineItem = self.searchListItem.lineList[indexPath.row];
            self.selectedLineId = lineItem.lineId;
            self.selectedLineNumber = lineItem.lineNumber;
            [self performSegueWithIdentifier:JWSeguePushLineWithId sender:self];
        } else {
            self.selectedStop = self.searchListItem.stopList[indexPath.row];
            [self performSegueWithIdentifier:JWSeguePushStopList sender:self];
        }
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        if (indexPath.row < self.collectLineItem.count) {
            JWCollectItem *item = self.collectLineItem[indexPath.row];
            [JWUserDefaultsUtil removeCollectItemWithLineId:item.lineId];
            [self.collectLineItem removeObjectAtIndex:indexPath.row];
            if (self.collectLineItem.count > 0) {
                [self.tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
            } else {
                [self.tableView reloadData];
            }
        }
    }
}

#pragma mark JWNavigationCenterDelegate
- (void)buttonItem:(JWNavigationCenterView *)buttonItem setOn:(BOOL)isOn
{
    if (isOn) {
        [self showCityList];
    }
}

#pragma mark UISearchBarDelegate
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    JWCityItem *cityItem = [JWUserDefaultsUtil cityItem];
    if (cityItem) {
        return YES;
    } else {
        [self showCityList];
        return NO;
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self adjustSearchBar];
}

- (void)adjustSearchBar
{
    // 处理search display controller的各种问题
    dispatch_async(dispatch_get_main_queue(), ^{
        UISearchBar *searchBar = self.searchController.searchBar;
        searchBar.height = self.searchBarHeight.constant;
        UITextField *textField = [searchBar JW_safeValueForKey:@"_searchField"];
        if (textField) {
            textField.centerY = searchBar.height / 2;
        }

        UIButton *cancelButton = [searchBar JW_safeValueForKey:@"_cancelButton"];
        if (cancelButton) {
            cancelButton.centerY = searchBar.height / 2;
        }

        UIView *containerView = [self.searchController JW_safeValueForKey:@"_containerView"];
        if ([containerView isKindOfClass:NSClassFromString(@"UISearchDisplayControllerContainerView")]) {
            UIView *topView = [containerView JW_safeValueForKey:@"_topView"];
            UIView *bottomView = [containerView JW_safeValueForKey:@"_bottomView"];
            topView.top = searchBar.top;
            topView.height = searchBar.height;
            bottomView.top = topView.bottom;
            bottomView.height = containerView.height - bottomView.top;
        }
    });
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self loadRequestWithKeyword:searchText showHUD:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.searchListItem = nil;
    [self.searchController.searchResultsTableView reloadData];
}

#pragma mark getter
- (JWSearchRequest *)searchRequest
{
    if (!_searchRequest) {
        _searchRequest = [[JWSearchRequest alloc] init];
    }
    return _searchRequest;
}

- (JWCityRequest *)cityRequest
{
    if (!_cityRequest) {
        _cityRequest = [[JWCityRequest alloc] init];
    }
    return _cityRequest;
}

- (NSMutableArray *)collectLineItem
{
    if (!_collectLineItem) {
        _collectLineItem = [[[JWUserDefaultsUtil allCollectItems] reverseObjectEnumerator].allObjects mutableCopy];
    }
    return _collectLineItem;
}

- (JWNavigationCenterView *)cityButtonItem
{
    if (!_cityButtonItem) {
        _cityButtonItem = [[JWNavigationCenterView alloc] initWithTitle:_cityName ?: @"城市" isBold:NO];
        _cityButtonItem.delegate = self;
    }
    return _cityButtonItem;
}

#pragma mark action
- (void)loadData
{
    _collectLineItem = nil;
    [self.tableView reloadData];
    [self.storeHouseRefreshControl performSelector:@selector(finishingLoading) withObject:nil afterDelay:0.3 inModes:@[ NSRunLoopCommonModes ]];
}

- (void)showCityList
{
    __weak typeof(self) weakSelf = self;
    [self.cityRequest loadWithCompletion:^(NSDictionary *dict, NSError *error) {
        if (error) {
            [JWViewUtil showError:error];
            [weakSelf.cityButtonItem setOn:NO];
        } else {
            NSArray *array = dict[kJWData];
            if (array.count > 0) {
                [weakSelf showCityListActionSheet:array];
            }
        }
    }];
}

- (void)showCityListActionSheet:(NSArray *)array
{
    __weak typeof(self) weakSelf = self;
    AHKActionSheet *actionSheet = [[AHKActionSheet alloc] initWithTitle:@"选择城市"];
    actionSheet.cancelButtonTitle = @"取消";
    actionSheet.buttonHeight = 44;
    actionSheet.animationDuration = 0.4;
    actionSheet.cancelHandler = ^(AHKActionSheet *actionSheet) {
        [weakSelf.cityButtonItem setOn:NO];
    };
    for (JWCityItem *cityItem in array) {
        [actionSheet addButtonWithTitle:cityItem.cityName image:[UIImage imageNamed:@"JWIconCity"] type:AHKActionSheetButtonTypeDefault handler:^(AHKActionSheet *actionSheet) {
            [weakSelf.cityButtonItem setOn:NO];
            [weakSelf.cityButtonItem setTitle:cityItem.cityName];
            [JWUserDefaultsUtil setCityItem:cityItem];
            [weakSelf loadData];
            [[JWSessionManager defaultManager] sync];
        }];
    }
    [actionSheet show];
}

- (void)reload
{
    NSString *city = [JWUserDefaultsUtil cityItem].cityName;
    [self.cityButtonItem setTitle:city];
    [self loadData];
}

- (void)loadRequestWithKeyword:(NSString *)keyword showHUD:(BOOL)isShowHUD
{
    if (keyword.length == 0) {
        self.searchListItem = nil;
        [self.searchController.searchResultsTableView reloadData];
        return;
    }

    if (isShowHUD) {
        [JWViewUtil showProgress];
    }

    self.searchRequest.keyWord = keyword;
    __weak typeof(self) weakSelf = self;
    [self.searchRequest loadWithCompletion:^(NSDictionary *dict, NSError *error) {
        if (isShowHUD) {
            if (error) {
                [JWViewUtil showError:error];
            } else {
                [JWViewUtil hideProgress];
            }
        }
        if (error) {
            weakSelf.searchListItem = nil;
            [weakSelf.searchController.searchResultsTableView reloadData];
            return;
        }
        NSInteger result = [dict[@"type"] integerValue];
        if (result == JWSearchResultTypeNone) {
            weakSelf.searchListItem = nil;
            [weakSelf.searchController.searchResultsTableView reloadData];
        } else {
            // list result
            weakSelf.searchListItem = [[JWSearchListItem alloc] initWithDictionary:dict];
            [weakSelf.searchController.searchResultsTableView reloadData];
        }
    }];
}

#pragma mark UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.storeHouseRefreshControl scrollViewDidScroll];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [self.storeHouseRefreshControl scrollViewDidEndDragging];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    //    [self.storeHouseRefreshControl scrollViewDidEndDecelerating];
}

@end
