//
//  CCFShowPrivateMessageViewController.m
//  CCF
//
//  Created by 迪远 王 on 16/3/25.
//  Copyright © 2016年 andforce. All rights reserved.
//

#import "CCFShowPrivateMessageViewController.h"

#import "CCFThreadDetailCell.h"
#import "UrlBuilder.h"
#import "CCFParser.h"

#import "MJRefresh.h"
#import "AutoRelayoutUITextView.h"

#import "ShowThreadPage.h"
#import "SVProgressHUD.h"

#import <UITableView+FDTemplateLayoutCell.h>
#import "ShowPrivateMessage.h"
#import "CCFShowPMTableViewCell.h"
#import "PrivateMessage.h"
#import "CCFProfileTableViewController.h"

#import "ShowThreadPage.h"
#import <MJRefresh.h>
#import "SDImageCache+URLCache.h"
#import "CCFWebViewController.h"
#import <NYTPhotosViewController.h>
#import <NYTPhotoViewer/NYTPhoto.h>
#import "NYTExamplePhoto.h"
#import "LCActionSheet.h"
#import "Thread.h"
#import "TransValueDelegate.h"
#import "UrlBuilder.h"
#import "SVProgressHUD.h"
#import "UIStoryboard+CCF.h"
#import "ActionSheetPicker.h"
#import "ReplyCallbackDelegate.h"
#import "CCFSimpleReplyNavigationController.h"
#import "CCFPCH.pch"
#import "NSString+Extensions.h"
#import "DRLTabBarController.h"
#import "ForumConfig.h"



#import "ForumApi.h"

@interface CCFShowPrivateMessageViewController ()<UIWebViewDelegate, UIScrollViewDelegate,TransValueDelegate>{

    PrivateMessage * transPrivateMessage;
    
    UIStoryboardSegue * selectSegue;
}

@end

@implementation CCFShowPrivateMessageViewController


-(void)transValue:(PrivateMessage *)value{
    transPrivateMessage = value;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.dataList = [NSMutableArray array];

    [self.webView setScalesPageToFit:YES];
    self.webView.dataDetectorTypes = UIDataDetectorTypeNone;
    self.webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
    self.webView.delegate = self;
    self.webView.backgroundColor = [UIColor whiteColor];
    
    for(UIView *view in [[[self.webView subviews] objectAtIndex:0] subviews]) {
        if([view isKindOfClass:[UIImageView class]]) {
            view.hidden = YES; }
    }
    [self.webView setOpaque:NO];
    
    // scrollView
    self.webView.scrollView.delegate = self;
    
    self.webView.scrollView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{

        [self.ccfApi showPrivateContentById:[transPrivateMessage.pmID intValue] handler:^(BOOL isSuccess, id message) {
            ShowPrivateMessage * content = message;
            NSString * postInfo = [NSString stringWithFormat:PRIVATE_MESSAGE,content.pmUserInfo.userID,content.pmUserInfo.userAvatar, content.pmUserInfo.userName, content.pmTime, content.pmContent];
            
            NSString *html = [NSString stringWithFormat:THREAD_PAGE ,content.pmTitle ,postInfo];
            
            [self.webView loadHTMLString:html baseURL:[NSURL URLWithString:BBS_URL]];
            
            [self.webView.scrollView.mj_header endRefreshing];
        }];
    }];
    
    [self.webView.scrollView.mj_header beginRefreshing];
}


-(void)showUserProfile:(NSIndexPath *)indexPath{
    CCFProfileTableViewController * controller = (CCFProfileTableViewController *)selectSegue.destinationViewController;
    self.transValueDelegate = (id<TransValueDelegate>)controller;
    
    ShowPrivateMessage * message = self.dataList[indexPath.row];
    
    [self.transValueDelegate transValue:message];
}

- (NSDictionary*)dictionaryFromQuery:(NSString*)query usingEncoding:(NSStringEncoding)encoding {
    NSCharacterSet* delimiterSet = [NSCharacterSet characterSetWithCharactersInString:@"&;"];
    NSMutableDictionary* pairs = [NSMutableDictionary dictionary];
    NSScanner* scanner = [[NSScanner alloc] initWithString:query];
    while (![scanner isAtEnd]) {
        NSString* pairString = nil;
        [scanner scanUpToCharactersFromSet:delimiterSet intoString:&pairString];
        [scanner scanCharactersFromSet:delimiterSet intoString:NULL];
        NSArray* kvPair = [pairString componentsSeparatedByString:@"="];
        if (kvPair.count == 2) {
            NSString* key = [[kvPair objectAtIndex:0]
                             stringByReplacingPercentEscapesUsingEncoding:encoding];
            NSString* value = [[kvPair objectAtIndex:1]
                               stringByReplacingPercentEscapesUsingEncoding:encoding];
            [pairs setObject:value forKey:key];
        }
    }
    
    return [NSDictionary dictionaryWithDictionary:pairs];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    if (navigationType == UIWebViewNavigationTypeLinkClicked && ([request.URL.scheme isEqualToString:@"http"] || [request.URL.scheme isEqualToString:@"https"])) {
        
        
        NSString * path = request.URL.path;
        if ([path rangeOfString:@"showthread.php"].location != NSNotFound) {
            // 显示帖子
            NSDictionary * query = [self dictionaryFromQuery:request.URL.query usingEncoding:NSUTF8StringEncoding];
            
            NSString * t = [query valueForKey:@"t"];

            
            
            UIStoryboard * storyboard = [UIStoryboard mainStoryboard];
            
            CCFWebViewController * showThreadController = [storyboard instantiateViewControllerWithIdentifier:@"CCFWebViewController"];
            
            self.transValueDelegate = (id<TransValueDelegate>)showThreadController;
            
            TransValueBundle *transBundle = [[TransValueBundle alloc] init];
            if (t) {
                [transBundle putIntValue:[t intValue] forKey:@"threadID"];
            } else{
                NSString * p = [query valueForKey:@"p"];
                [transBundle putIntValue:[p intValue] forKey:@"p"];
            }
            
            
            [self.transValueDelegate transValue:transBundle];
            [self.navigationController pushViewController:showThreadController animated:YES];
            
            return NO;
        } else{
            [[UIApplication sharedApplication] openURL:request.URL];
            
            return NO;
        }
    }
    
    if ([request.URL.scheme isEqualToString:@"avatar"]) {
        NSDictionary * query = [self dictionaryFromQuery:request.URL.query usingEncoding:NSUTF8StringEncoding];
        
        NSString * userid = [query valueForKey:@"userid"];
        
        
        UIStoryboard * storyboard = [UIStoryboard mainStoryboard];
        CCFProfileTableViewController * showThreadController = [storyboard instantiateViewControllerWithIdentifier:@"CCFProfileTableViewController"];
        self.transValueDelegate = (id<TransValueDelegate>)showThreadController;
        TransValueBundle *showTransBundle = [[TransValueBundle alloc] init];
        [showTransBundle putIntValue:[userid intValue] forKey:@"userid"];
        [self.transValueDelegate transValue:showTransBundle];
        
        [self.navigationController pushViewController:showThreadController animated:YES];
        
        return NO;
    }
    
    return YES;
}


#pragma mark Controller跳转
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if ([segue.identifier isEqualToString:@"ShowUserProfile"]){
        selectSegue = segue;
    }
}

- (IBAction)back:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}
@end
