//
//  WeatherViewController.m
//  CandidateProject
//
//  Created by Louis Zhu on 2017/11/14.
//  Copyright © 2017年 PerrchicK. All rights reserved.
//

#import "WeatherViewController.h"
#import "SmileWeatherDownLoader.h"
//#import "PhotoClass.h"
//#import <AFNetworking.h>
//#import <SDImageCache.h>
//#import <UIImageView+WebCache.h>
@interface WeatherViewController ()<NSXMLParserDelegate>
{
    UIButton *_btn;
}
//解析XML字符串
@property (nonatomic, strong) NSXMLParser *par;
//@property (nonatomic, strong) PhotoClass *person;
@property (nonatomic, copy) NSString *currentElement;

@property (nonatomic,strong) SmileWeatherDownLoader *loader;
@property (nonatomic,strong) UIView * BackView;
@property (nonatomic,strong) UIImageView *BackgroundImage;
@end
NSString *const FlickrAPIKey = @"efa79d0bdd62e8c0aac32dea400a8333";
@implementation WeatherViewController

-(void)searchFlickrPhotos
{
    // Build the string to call the Flickr API
    NSString *urlString = [NSString stringWithFormat:@"https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=%@&lat=%.6f&lon=%.6f&per_page=1", FlickrAPIKey,self.lat,self.lng];
    //&format=json&nojsoncallback=1
    // Create NSURL string from formatted string
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSURLSession *session =  [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
    
    // 创建任务
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:[NSURLRequest requestWithURL:url] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
//        NSLog(@"data ~~~ %@ ~~~ response ~~~ %@ ~~~ error~~~ %@", data, response , error);
        NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"jsonString ~~~ %@", jsonString);
        if(jsonString.length>10)
        {
            self.par = [[NSXMLParser alloc]initWithData:data];
             self.par.delegate = self;
            [self.par parse];
        }else
            ;
    }];
    
    // 启动任务
    [dataTask resume];
}
//#pragma mark  解析Image
////开始解析
//- (void)parserDidStartDocument:(NSXMLParser *)parser{
//    NSLog(@"parserDidStartDocument...");
//}
////准备节点
//- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(nullable NSString *)namespaceURI qualifiedName:(nullable NSString *)qName attributes:(NSDictionary<NSString *, NSString *> *)attributeDict{
//
//    self.currentElement = elementName;
//
//    if ([self.currentElement isEqualToString:@"photo"]){
//        self.person = [[PhotoClass alloc]init];
//        if( [[attributeDict allKeys] containsObject:@"id"])
//        {
//             [self.person setPhotoid:attributeDict[@"id"]];
//        }
//
//        if ( [[attributeDict allKeys] containsObject:@"secret"])
//        {
//             [self.person setSecret:attributeDict[@"secret"]];
//        }
//
//        if ( [[attributeDict allKeys] containsObject:@"server"])
//        {
//            [self.person setServerid:attributeDict[@"server"]];
//        }
//
//        if ( [[attributeDict allKeys] containsObject:@"farm"])
//        {
//            [self.person setFarmid:attributeDict[@"farm"]];
//        }
//    }
//
//}
////获取节点内容
//- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
//
////    if ([self.currentElement isEqualToString:@"id"]) {
////
////        [self.person setPhotoid:string];
////    }else if ([self.currentElement isEqualToString:@"secret"]){
////        [self.person setSecret:string];
////    }else if ([self.currentElement isEqualToString:@"server"]){
////        [self.person setServerid:string];
////    }else if ([self.currentElement isEqualToString:@"farm"]){
////
////        [self.person setFarmid:string];
////    }
//}
//
////解析完一个节点
//- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(nullable NSString *)namespaceURI qualifiedName:(nullable NSString *)qName{
//    self.currentElement = nil;
//}
//
////解析结束
//- (void)parserDidEndDocument:(NSXMLParser *)parser{
//    if(self.person.photoid == nil || [self.person.photoid isKindOfClass:[NSNull class]] || [self.person.photoid isEqualToString:@""])
//    {
//        self.BackgroundImage.image = [UIImage imageNamed:@"bg"];
//    }else
//    {
//        NSString *photoURLString = [NSString stringWithFormat:@"https://farm%@.static.flickr.com/%@/%@_%@_b.jpg",self.person.farmid,self.person.serverid,self.person.photoid, self.person.secret];
//        [self.BackgroundImage sd_setImageWithURL:[NSURL URLWithString:photoURLString] placeholderImage:[UIImage imageNamed:@"bg"]];
//    }
//    [UIView animateWithDuration:0.5 animations:^{
//        [_btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//    }];
//
//    NSLog(@"parserDidEndDocument... %@,%@,%@,%@",self.person.farmid,self.person.serverid,self.person.photoid, self.person.secret);
//}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.BackgroundImage = [[UIImageView alloc]initWithFrame:self.view.bounds];
    self.BackgroundImage.backgroundColor = [UIColor whiteColor];
    [self.BackgroundImage setContentScaleFactor:[[UIScreen mainScreen] scale]];
    self.BackgroundImage.contentMode =  UIViewContentModeScaleAspectFill;
    self.BackgroundImage.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    self.BackgroundImage.clipsToBounds  = YES;
    [self.view addSubview:self.BackgroundImage];
//    self.BackgroundImage.image = [UIImage imageNamed:@"bg"];
//    [self searchFlickrPhotos];
    self.BackView = [[UIView alloc]initWithFrame:CGRectMake(0, 20, self.view.bounds.size.width, self.view.bounds.size.height/4*2.5)];
    self.BackView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.BackView];
    self.BackView.userInteractionEnabled = NO;
    SmileWeatherDemoVC *demoVC = [SmileWeatherDemoVC DemoVCToView:self.BackView];
    [[SmileWeatherDownLoader sharedDownloader]getWeatherDataFromLocation:self.loaction completion:^(SmileWeatherData * _Nullable data, NSError * _Nullable error) {
        if(data.currentData.currentTemperature.celsius == 0.0)
        {
            [self _TemperturealertWithTitle:nil message:@"Weather condition network is loading abnormally, please Back and reload weather forecast"];
        }
        [demoVC setData:data];
         
        
    }];
    _btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btn setFrame:CGRectMake(0, self.view.bounds.size.height-40, 70, 40)];
    [_btn setTitle:@"Back" forState:UIControlStateNormal];
    _btn.titleLabel.font = [UIFont systemFontOfSize:23];
    [_btn addTarget:self action:@selector(BackAddView) forControlEvents:UIControlEventTouchUpInside];
    [_btn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.view addSubview:_btn];
    // Do any additional setup after loading the view.
}

-(void)_TemperturealertWithTitle:(NSString *)title message:(NSString *)message {
    [[[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
}

-(void)BackAddView
{
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
