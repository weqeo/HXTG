//
//  HXOpenClassDetailController.m
//  HXTG
//
//  Created by grx on 2017/3/3.
//  Copyright © 2017年 grx. All rights reserved.
//

#import "HXOpenClassDetailController.h"
#import "GUIPlayerView.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "IMYWebView.h"
#import "HXPastEarlyModel.h"
#import "EarlyRequestModel.h"
#import "HSDownloadManager.h"
#import "DownLoad.h"
#import "HXPDFView.h"
#import "HXMP3View.h"

@interface HXOpenClassDetailController ()<GUIPlayerViewDelegate,IMYWebViewDelegate>{
    NSString *fileMp3_url;
    NSString *filePDF_url;
    NSDictionary *downLoadDict;
    IMYWebView *detailWebView;
    HXPDFView *pdfView;
    UIView *tipView;
    UIView *titleBgView;
    UIView *teachBgView;
    UILabel *warlyTitle;
    UILabel *teachTime;
    UILabel *teachName;
    UILabel *legionName;
    UILabel *teachNum;
}

@property (nonatomic,strong) HXPastEarlyModel *earlymodel;
@property (nonatomic,strong) GUIPlayerView *playerView;
@property (nonatomic,strong) HXMP3View *mp3View;

@end

@implementation HXOpenClassDetailController

#pragma mark - 视图进入的时候
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.playerView addSubview:self.playerView.coverImageView];
    [self.playerView addSubview:self.playerView.firstPlayButton];
    
}

#pragma mark - 视图离开的时候
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_playerView stop];
    [self.mp3View clearn];
}



- (void)viewDidLoad {
    [super viewDidLoad];
    self.backButton.hidden = NO;
    self.navigationItem.title = self.title;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(enterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(becomeActive)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];
    /*! 创建广播层 */
    [self creatRadio];
    /*! 创建播放器 */
    [self AVPlayer];
    /*! 创建PDF下载文件 */
    [self createPDFView];
    /*! 创建MP3文件 */
    [self createMP3View];
    /*! 创建网页 */
    [self creatWebView];
    /*! 网络请求 */
    [self gaintEarlyInfo];

}



#pragma mark - =============创建广播层=============
-(void)creatRadio
{
    /*! 广播层 */
    tipView = [[UIView alloc]initWithFrame:CGRectMake(0, 64, Main_Screen_Width, 40)];
    tipView.backgroundColor = UIColorBgLightTheme;
    [self.view addSubview:tipView];
    UIImageView *hornImage = [[UIImageView alloc]initWithFrame:CGRectMake(8, 11, 22, 19)];
    hornImage.image = [UIImage imageNamed:@"tongzhi"];
    [tipView addSubview:hornImage];
    UILabel *tipLable = [[UILabel alloc]initWithFrame:CGRectMake(38, 0, Main_Screen_Width-110, 40)];
    tipLable.font = UIFontSystem12;
    tipLable.textColor = UIColorRedTheme;
    tipLable.text = @"风险提示：本投顾产品投资建议仅供参考，不作为客户投资决策依据。客户须审慎独立作出投资决策，自行承担投资风险>>";
    [tipView addSubview:tipLable];
    UILabel *checkLable = [[UILabel alloc]initWithFrame:CGRectMake(Main_Screen_Width-80, 0, 72, 40)];
    checkLable.font = UIFontSystem12;
    checkLable.textColor = UIColorRedTheme;
    checkLable.textAlignment = NSTextAlignmentRight;
    checkLable.text = @"查看详情>>";
    [tipView addSubview:checkLable];
    /*! 手势 */
    UITapGestureRecognizer* singleRecognizer;
    singleRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tipViewClickTap:)];
    singleRecognizer.numberOfTapsRequired = 1;
    [tipView addGestureRecognizer:singleRecognizer];
    /*! 文章信息 */
    titleBgView = [[UIView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(tipView.frame), Main_Screen_Width, 30)];
    titleBgView.backgroundColor = UIColorWhite;
    /*! 文章标题 */
    warlyTitle = [[UILabel alloc]initWithFrame:CGRectMake(15, 0, Main_Screen_Width-30, 30)];
    warlyTitle.font = UIFontSystem15;
    warlyTitle.textColor = UIColorBlackTheme;
    [titleBgView addSubview:warlyTitle];
    [self.view addSubview:titleBgView];
}


- (void)AVPlayer{
    // 1.创建视频播放视图
    _playerView = [[GUIPlayerView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(titleBgView.frame), Main_Screen_Width, Main_Screen_Height/3.28)];
    _playerView.delegate = self;
    _playerView.hidden = YES;
    [self.view addSubview:_playerView];
    WeakSelf(weakSelf);
    _playerView.firstPlayBtnClick = ^(){
        /*! 暂停MP3 */
        [weakSelf.mp3View.avPlayer pause];
        [weakSelf.mp3View.downLoadBtn setSelected:NO];
        NSString *playUrl;
        if (weakSelf.earlymodel.video_url.length!=0) {
            playUrl = weakSelf.earlymodel.video_url;
            [weakSelf.playerView.coverImageView removeFromSuperview];
            [weakSelf.playerView.firstPlayButton removeFromSuperview];
        }else{
            playUrl = weakSelf.earlymodel.file2_url;
            [weakSelf.playerView.firstPlayButton removeFromSuperview];
        }
        NSString *currenUrl = [NSString stringWithFormat:@"%@",playUrl];
        currenUrl = [currenUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

        weakSelf.playerView.videoURL = [NSURL URLWithString:currenUrl];
        [weakSelf.playerView prepareAndPlayAutomatically:YES];
        [weakSelf.playerView showControllers];
    };
    _playerView.downLoadBtnClick = ^(){
        DDLog(@"开始下载==============");
        [weakSelf readyDownLoad:NO];
    };
    /*! 老师信息 */
    teachBgView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, Main_Screen_Width, 0)];
    teachBgView.backgroundColor = UIColorBgLightTheme;
    /*! 老师名称 */
    teachName = [[UILabel alloc]initWithFrame:CGRectMake(15, 5, 58, 30)];
    teachName.font = UIFontSystem13;
    teachName.textColor = UIColorLightTheme;
    [teachBgView addSubview:teachName];
    /*! 军团名称 */
    legionName = [[UILabel alloc]initWithFrame:CGRectMake(CGRectGetMaxX(teachName.frame), 5, 60, 30)];
    legionName.font = UIFontSystem13;
    legionName.textColor = UIColorLightTheme;
    [teachBgView addSubview:legionName];
    /*! 资格证号 */
    teachNum = [[UILabel alloc]initWithFrame:CGRectMake(CGRectGetMaxX(legionName.frame)+5, 5, Main_Screen_Width-160-30, 30)];
    teachNum.font = UIFontSystem13;
    teachNum.textColor = UIColorLightTheme;
    [teachBgView addSubview:teachNum];
    /*! 当前时间 */
    teachTime = [[UILabel alloc]initWithFrame:CGRectMake(Main_Screen_Width-50 , 5, 40, 30)];
    teachTime.font = UIFontSystem13;
    teachTime.textColor = UIColorLightTheme;
    [teachBgView addSubview:teachTime];
    [self.view addSubview:teachBgView];
}

-(void)createPDFView
{
    pdfView = [[HXPDFView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(_playerView.frame)+10, Main_Screen_Width, 45)];
    [self.view addSubview:pdfView];
    pdfView.hidden = YES;
    WeakSelf(weakSelf);
    pdfView.downLoadPdfFile = ^(){
        DDLog(@"开始下载Pdf=========%@",HSCachesDirectory);
        [weakSelf readyDownLoad:YES];
    };
}

-(void)createMP3View
{
    self.mp3View = [[HXMP3View alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(_playerView.frame)+10, Main_Screen_Width, 45)];
    [self.view addSubview:self.mp3View];
    self.mp3View.hidden = YES;
    WeakSelf(weakSelf);
    self.mp3View.playLoadPM3File = ^(){
        DDLog(@"开始播放MP3=========%@",HSCachesDirectory);
        /*! 视频暂停 */
        [weakSelf.playerView stop];
    };
}


-(void)creatWebView
{
    detailWebView = [[IMYWebView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(_playerView.frame)+10, Main_Screen_Width, Main_Screen_Height-Main_Screen_Height/3.28-65)];
    detailWebView.delegate = self;
    detailWebView.backgroundColor = UIColorWhite;
    [self.view addSubview:detailWebView] ;
}

#pragma mark - 广播层手势事件
-(void)tipViewClickTap:(UITapGestureRecognizer *)recognizer
{
    HXAlterview *alter = [[HXAlterview alloc]initWithTitle:@"风险提示" contentText:@"本投顾产品投资建议仅供参考，不作为客户投资决策依据。客户须审慎独立作出投资决策，自行承担投资风险。\n投诉热线: 010-53821559" centerButtonTitle:@"我知道了"];
    alter.alertContentLabel.textAlignment = NSTextAlignmentLeft;
    alter.centerBlock=^()
    {
        
    };
    [alter show];
}


#pragma mark - GUIPlayerViewDelegate
- (void)playerWillEnterFullscreen {
    [[self navigationController] setNavigationBarHidden:YES];
    [UIView animateWithDuration:0.6 animations:^{
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    }];
    pdfView.hidden = YES;
    self.mp3View.hidden = YES;
    detailWebView.hidden = YES;
    titleBgView.hidden = YES;
    teachBgView.hidden = YES;
    self.playerView.firstPlayButton.hidden = YES;
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
}

- (void)playerWillLeaveFullscreen {
    [[self navigationController] setNavigationBarHidden:NO];
    [UIView animateWithDuration:0.6 animations:^{
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    }];
    if (filePDF_url.length!=0) {
        pdfView.hidden = NO;
    }
    if (fileMp3_url.length!=0) {
        self.mp3View.hidden = NO;
    }
    detailWebView.hidden = NO;
    titleBgView.hidden = NO;
    teachBgView.hidden = NO;
    self.playerView.firstPlayButton.hidden = NO;
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

- (void)playerDidEndPlaying {
    [_playerView stop];
}

- (void)playerFailedToPlayToEnd {
    [self.playerView prepareAndPlayAutomatically:YES];
}



#pragma mark - 进入后台
-(void)enterBackground
{
    DDLog(@"========进入后台");
    [_playerView pause];
}

#pragma mark - 进入前台
-(void)becomeActive
{
    DDLog(@"========进入前台");
    [_playerView play];
}

-(void)playerDidResume
{
    /*! 暂停MP3 */
    [self.mp3View.avPlayer pause];
    self.mp3View.isSelect = NO;
    [self.mp3View.downLoadBtn setSelected:NO];
}

#pragma mark - ================加载完成======================
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSString *injectionJSString = @"var script = document.createElement('meta');"
    "script.name = 'viewport';"
    "script.content=\"width=device-width,initial-scale=1.0,maximum-scale=1.0, minimum-scale=1.0,user-scalable=no\";"
    "document.getElementsByTagName('head')[0].appendChild(script);"
    "document.documentElement.style.webkitTouchCallout = \"none\";"
    "document.documentElement.style.webkitUserSelect = \"none\";"
    "window.scrollBy(0, 0);";
    [webView stringByEvaluatingJavaScriptFromString:injectionJSString];
    [webView stringByEvaluatingJavaScriptFromString:
     @"var script = document.createElement('script');"
     "script.type = 'text/javascript';"
     "script.text = \"function ResizeImages() { "
     "var myimg,oldwidth;"
     "var maxwidth = 300.0;" // UIWebView中显示的图片宽度
     "for(i=0;i <document.images.length;i++){"
     "myimg = document.images[i];"
     "if(myimg.width > maxwidth){"
     "oldwidth = myimg.width;"
     "myimg.width = maxwidth;"
     "}"
     "}"
     "}\";"
     "document.getElementsByTagName('head')[0].appendChild(script);"];
    [webView stringByEvaluatingJavaScriptFromString:@"ResizeImages();"];
    [HXLoadingView hide];
}

-(void)backClick
{
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - 往日早盘网络请求
-(void)gaintEarlyInfo
{
    NSString *urlStr;
    if ([self.title isEqualToString:@"往日早盘"]) {
        urlStr = @"App/EarlyInfo";
    }else if ([self.title isEqualToString:@"公开课"]){
        urlStr = @"App/OpenClassInfo";
    }else if ([self.title isEqualToString:@"专业内参"]||[self.title isEqualToString:@"独家内参"]||[self.title isEqualToString:@"机构内参"]||[self.title isEqualToString:@"实战内参"]||[self.title isEqualToString:@"至尊内参"]||[self.title isEqualToString:@"深度实战报告"]||[self.title isEqualToString:@"私人定制报告"]||[self.title isEqualToString:@"高手追踪"]){
        urlStr = @"Investment/ConsultingReference";
    }else if ([self.title isEqualToString:@"操盘计划"]){
        urlStr = @"Investment/TraderPlanInfo";
    }else if ([self.title isEqualToString:@"培训课程"]){
        urlStr = @"Investment/TrainedInfo";
    }else if ([self.title isEqualToString:@"专属服务"]){
        urlStr = @"Investment/StrategyReportInfo";
    }else if ([self.title isEqualToString:@"操作计划A"]||[self.title isEqualToString:@"操作计划B"]||[self.title isEqualToString:@"持仓报告"]){
        urlStr = @"Investment/ReportInfo";
    }else if ([self.title isEqualToString:@"机构实盘"]){
        urlStr = @"Investment/MechanismInfo";
    }else if ([self.title isEqualToString:@"专属方案"]){
        urlStr = @"Investment/StrategyReportInfo";
    }else{
        urlStr = @"App/OpenClassInfo";
    }
    EarlyRequestModel *model = [[EarlyRequestModel alloc]init];
    model.post_id = self.postId;
    NSDictionary *dict = [model mj_keyValues];
    [HXLoadingView show];
    [[HXNetClient sharedInstance]NetRequestPOSTWithRequestURL:urlStr WithParameter:dict WithReturnValeuBlock:^(NSURLSessionDataTask *task, NSDictionary *responseDict) {
        NSString *status = [NSString stringWithFormat:@"%@",responseDict[@"status"]];
        if ([status isEqualToString:@"1"]) {
            NSDictionary *dic =responseDict[@"data"];
            NSString *fileVoide_url = [NSString stringWithFormat:@"%@",dic[@"video_url"]];
            fileMp3_url = [NSString stringWithFormat:@"%@",dic[@"file2_url"]];
            filePDF_url = [NSString stringWithFormat:@"%@",dic[@"file1_url"]];

            self.earlymodel = [HXPastEarlyModel mj_objectWithKeyValues:dic];
            warlyTitle.text = self.earlymodel.post_title;
            teachTime.text = [NSString stringWithFormat:@"%@",dic[@"post_date"]];
            teachName.text = [NSString stringWithFormat:@"%@",dic[@"post_author"]];
            legionName.text = [NSString stringWithFormat:@"%@",dic[@"lrving_name"]];
            teachNum.text = [NSString stringWithFormat:@"%@",dic[@"card_num"]];
            if (self.earlymodel.video_pic.length==0) {
                _playerView.coverImageView.image = [UIImage imageNamed:@"banner"];
            }else{
                NSString *picStr = [NSString stringWithFormat:@"%@",self.earlymodel.video_pic];
                picStr = [picStr stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
                [_playerView.coverImageView sd_setImageWithURL:[NSURL URLWithString:picStr]];
            }
            if (self.earlymodel.post_content.length!=0) {
                NSString *reasonStr = self.earlymodel.post_content;
                [detailWebView loadHTMLString:reasonStr baseURL:nil];
            }
            /*! 是否有视频源 */
            if (fileVoide_url.length==0 || [fileVoide_url isEqualToString:@"(null)"]||[fileVoide_url isEqualToString:@"<null>"]) {
                /*! 没有视频源清况 */
                _playerView.hidden = YES;
                /*! 不存在PDF文件 */
                if (filePDF_url.length==0|| [filePDF_url isEqualToString:@"(null)"]||[filePDF_url isEqualToString:@"<null>"]) {
                    pdfView.hidden = YES;
                    if (fileMp3_url.length==0|| [fileMp3_url isEqualToString:@"(null)"]||[fileMp3_url isEqualToString:@"<null>"]) {
                        /*! 不存在MP3 */
                        self.mp3View.hidden = YES;
                        teachBgView.frame = CGRectMake(0, CGRectGetMaxY(titleBgView.frame), Main_Screen_Width, 30);
                        detailWebView.frame = CGRectMake(0, CGRectGetMaxY(teachBgView.frame)+5, Main_Screen_Width, Main_Screen_Height-164);
                    }else{
                        /*! 存在MP3 */
                        teachBgView.frame = CGRectMake(0, CGRectGetMaxY(titleBgView.frame), Main_Screen_Width, 30);
                        self.mp3View.hidden = NO;
                        self.mp3View.MP3Lable.text = [NSString stringWithFormat:@"%@",self.earlymodel.file2_name];
                        self.mp3View.MP3Url = fileMp3_url;
                        self.mp3View.frame = CGRectMake(0, CGRectGetMaxY(teachBgView.frame)+5, Main_Screen_Width, 45);
                        detailWebView.frame = CGRectMake(0, CGRectGetMaxY(self.mp3View.frame)+10, Main_Screen_Width, Main_Screen_Height-164-55);
                    }
                }else{
                    /*! 存在PDF文件 */
                    pdfView.hidden = NO;
                    pdfView.pdfUrl = filePDF_url;
                    pdfView.PDFLable.text = [NSString stringWithFormat:@"%@",self.earlymodel.file1_name];
                    if (fileMp3_url.length==0|| [fileMp3_url isEqualToString:@"(null)"]||[fileMp3_url isEqualToString:@"<null>"]) {
                        /*! 不存在MP3 */
                        teachBgView.frame = CGRectMake(0, CGRectGetMaxY(titleBgView.frame), Main_Screen_Width, 30);
                        self.mp3View.hidden = YES;
                        pdfView.frame = CGRectMake(0, CGRectGetMaxY(teachBgView.frame)+5, Main_Screen_Width, 45);
                        detailWebView.frame = CGRectMake(0, CGRectGetMaxY(pdfView.frame)+10, Main_Screen_Width, Main_Screen_Height-164-55);
                    }else{
                        /*! 存在MP3 */
                        teachBgView.frame = CGRectMake(0, CGRectGetMaxY(titleBgView.frame), Main_Screen_Width, 30);
                        self.mp3View.hidden = NO;
                        self.mp3View.MP3Lable.text = [NSString stringWithFormat:@"%@",self.earlymodel.file2_name];
                        self.mp3View.MP3Url = fileMp3_url;
                        pdfView.frame = CGRectMake(0, CGRectGetMaxY(teachBgView.frame)+5, Main_Screen_Width, 45);
                        self.mp3View.frame = CGRectMake(0, CGRectGetMaxY(pdfView.frame)+10, Main_Screen_Width, 45);
                        detailWebView.frame = CGRectMake(0, CGRectGetMaxY(self.mp3View.frame)+10, Main_Screen_Width, Main_Screen_Height-164-55-55);
                    }
                }
            }else{
                _playerView.hidden = NO;
                /*! 有视频源清况 */
                /*! 不存在PDF文件 */
                if (filePDF_url.length==0|| [filePDF_url isEqualToString:@"(null)"]||[filePDF_url isEqualToString:@"<null>"]) {
                    pdfView.hidden = YES;
                    if (fileMp3_url.length==0|| [fileMp3_url isEqualToString:@"(null)"]||[fileMp3_url isEqualToString:@"<null>"]) {
                        /*! 不存在MP3 */
                        teachBgView.frame = CGRectMake(0, CGRectGetMaxY(_playerView.frame), Main_Screen_Width, 30);
                        self.mp3View.hidden = YES;
                        detailWebView.frame = CGRectMake(0, CGRectGetMaxY(teachBgView.frame)+5, Main_Screen_Width, Main_Screen_Height-Main_Screen_Height/3.28-164);
                    }else{
                        /*! 存在MP3 */
                        teachBgView.frame = CGRectMake(0, CGRectGetMaxY(_playerView.frame), Main_Screen_Width, 30);
                        self.mp3View.hidden = NO;
                        self.mp3View.MP3Lable.text = [NSString stringWithFormat:@"%@",self.earlymodel.file2_name];
                        self.mp3View.MP3Url = fileMp3_url;
                        self.mp3View.frame = CGRectMake(0, CGRectGetMaxY(teachBgView.frame)+5, Main_Screen_Width, 45);
                        detailWebView.frame = CGRectMake(0, CGRectGetMaxY(self.mp3View.frame)+10, Main_Screen_Width, Main_Screen_Height-Main_Screen_Height/3.28-164-65);
                    }
                    
                }else{
                    /*! 存在PDF文件 */
                    pdfView.hidden = NO;
                    pdfView.pdfUrl = filePDF_url;
                    pdfView.PDFLable.text = [NSString stringWithFormat:@"%@",self.earlymodel.file1_name];
                    if (fileMp3_url.length==0|| [fileMp3_url isEqualToString:@"(null)"]||[fileMp3_url isEqualToString:@"<null>"]) {
                        /*! 不存在MP3 */
                        teachBgView.frame = CGRectMake(0, CGRectGetMaxY(_playerView.frame), Main_Screen_Width, 30);
                        self.mp3View.hidden = YES;
                        pdfView.frame = CGRectMake(0, CGRectGetMaxY(teachBgView.frame)+5, Main_Screen_Width, 45);
                        detailWebView.frame = CGRectMake(0, CGRectGetMaxY(pdfView.frame)+10, Main_Screen_Width, Main_Screen_Height-Main_Screen_Height/3.28-164-65);
                    }else{
                        /*! 存在MP3 */
                        teachBgView.frame = CGRectMake(0, CGRectGetMaxY(_playerView.frame), Main_Screen_Width, 30);
                        self.mp3View.hidden = NO;
                        self.mp3View.MP3Lable.text = [NSString stringWithFormat:@"%@",self.earlymodel.file2_name];
                        self.mp3View.MP3Url = fileMp3_url;
                        pdfView.frame = CGRectMake(0, CGRectGetMaxY(teachBgView.frame)+5, Main_Screen_Width, 45);
                        self.mp3View.frame = CGRectMake(0, CGRectGetMaxY(pdfView.frame)+10, Main_Screen_Width, 45);
                        detailWebView.frame = CGRectMake(0, CGRectGetMaxY(self.mp3View.frame)+10, Main_Screen_Width, Main_Screen_Height-Main_Screen_Height/3.28-164-55-55);
                    }
                }
            }
            [HXLoadingView hide];
        }else{
            [HXLoadingView hide];
            [HXProgressHUD showMessage:self.view
                             labelText:responseDict[@"msg"]
                                  mode:MBProgressHUDModeText];
        }
    } WithErrorBlock:^(NSURLSessionDataTask *task, NSError *error) {
        [HXLoadingView hide];
    } WithFailureBlock:^{
        [HXLoadingView hide];
    }];
}


- (void)dealloc
{
    [_playerView clean];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

#pragma mark - 准备下载视频
-(void)readyDownLoad:(BOOL)isPDF
{
    /*! 暂停列表 */
    NSMutableArray *ZTarray =  [[NSMutableArray alloc] initWithArray:[userDefaults objectForKey:@"cachingList"]];
    /*! 下载列表 */
    NSMutableArray *downarray =  [[NSMutableArray alloc] initWithArray:[userDefaults objectForKey:@"downList"]];
    /*! 等待下载 */
    NSMutableArray *waitList = [[NSMutableArray alloc] initWithArray:[userDefaults objectForKey:@"waitList"]];
    /*! 失败列表 */
    NSMutableArray *failed = [[NSMutableArray alloc] initWithArray:[userDefaults objectForKey:@"failedList"]];
    
    NSDictionary *dic = [self gaintDownLoadDic:self.earlymodel IsPDF:isPDF];
    downLoadDict = dic;
    CGFloat f = [[HSDownloadManager sharedInstance] progress:dic];
    
    if (f >= 1) {
        /*! 已下载提示 */
        [HXProgressHUD showMessage:self.view labelText:@"已下载" mode:MBProgressHUDModeText];
        return;
    }
    /*! 如果已存在等待列表中 */
    if ([waitList containsObject:dic]) {
        [HXProgressHUD showMessage:self.view labelText:@"已在等待列表中" mode:MBProgressHUDModeText];
        return;
    }
    /*! 如果已在失败列表中 */
    if ([failed containsObject:dic]) {
        [failed removeObject:dic];
        [userDefaults setObject:failed forKey:@"failedList"];
        [userDefaults synchronize];
        /*! 开始下载 */
        [self startDownLoad];
    }
    /*! 如果已在下载列表中 */
    if ([downarray containsObject:dic]&&(![ZTarray containsObject:dic])) {
        [HXProgressHUD showMessage:self.view labelText:@"正在下载中..." mode:MBProgressHUDModeText];
        return;
    }
    /*! 第一次下载提示网络模式 */
    if ((downarray.count < 1) || ((downarray.count == ZTarray.count) && downarray.count != 1)) {
        /*! 检查网络状况 */
        [[HXNetClient sharedInstance]netWorkReachabilityWithReturnNetWorkStatusBlock:^(AFNetworkReachabilityStatus status) {
            if (status==1) {
                UIAlertView *alerView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"当前网络为蜂窝网,是否继续下载?" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
                alerView.delegate = self;
                [alerView show];
            }else{
                /*! 开始下载 */
                [self startDownLoad];
            }
        }];
    }else{
        /*! 添加到等待列表 */
        NSMutableArray *array1 = (NSMutableArray*)[userDefaults objectForKey:@"waitList"];
        if (array1 == nil) {
            array1 = [NSMutableArray array];
        }
        if (![array1 containsObject:dic]) {
            NSMutableArray *aRRay = [[NSMutableArray alloc] initWithArray:array1];
            [aRRay addObject:dic];
            NSMutableArray *downList = [[NSMutableArray alloc] initWithArray:[userDefaults objectForKey:@"downList"]];
            NSMutableArray *ZTList = [[NSMutableArray alloc] initWithArray:[userDefaults objectForKey:@"cachingList"]];
            [downList removeObject:dic];
            [userDefaults setObject:downList forKey:@"downList"];
            [ZTList removeObject:dic];
            [userDefaults setObject:ZTList forKey:@"cachingList"];
            [userDefaults setObject:aRRay forKey:@"waitList"];
            [userDefaults synchronize];
        }
    }
    /*! 移除暂停列表 */
    if ([ZTarray containsObject:dic]) {
        [ZTarray removeObject:dic];
        [userDefaults setObject:ZTarray forKey:@"cachingList"];
        [userDefaults synchronize];
    }
}

#pragma mark -- UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1) {
        /*! 开始下载 */
        [self startDownLoad];
    }
}


#pragma mark - 获取下载数据源
-(NSDictionary *)gaintDownLoadDic:(HXPastEarlyModel *)model IsPDF:(BOOL)isPDF
{
    NSDictionary *dic;
    /*! url地址 */
    NSString *urlString=@"";
    if (isPDF==YES) {
        NSString *file1Url = [NSString stringWithFormat:@"%@",model.file1_url];
        file1Url = [file1Url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        urlString = file1Url;
    }else{
        NSString *videoUrl = [NSString stringWithFormat:@"%@",model.video_url];
        videoUrl = [videoUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        
        urlString = videoUrl;
        if (videoUrl.length==0) {
            urlString = model.file2_url;
        }
    }
    /*! 标题 */
    NSString *post_title;
    if (isPDF==YES) {
        post_title = [NSString stringWithFormat:@"%@",model.file1_name];
    }else{
        post_title = [NSString stringWithFormat:@"%@",model.post_title];
    }
    /*! id */
    NSString *post_id;
    if (isPDF==YES) {
        post_id = [NSString stringWithFormat:@"%d",[model.post_id intValue]+10000];
    }else{
        post_id = [NSString stringWithFormat:@"%@",model.post_id];
    }
    
    dic = @{@"title":post_title,
            @"url":urlString,
            @"time":model.post_date,
            @"cache_id":post_id,
            };
    
    return dic;

}

#pragma mark - 开始下载视频
-(void)startDownLoad
{
    NSMutableArray *downarray =  [[NSMutableArray alloc] initWithArray:[userDefaults objectForKey:@"downList"]];
    if (downarray == nil) {
        downarray = [NSMutableArray array];
    }
    if (![downarray containsObject:downLoadDict]) {
        NSMutableArray *aRRay = [[NSMutableArray alloc] initWithArray:downarray];
        [aRRay addObject:downLoadDict];
        [userDefaults setObject:aRRay forKey:@"downList"];
        [userDefaults synchronize];
    }
    /*! 开始下载 */
    [DownLoad downLoadWithDictionary:downLoadDict];
    [HXProgressHUD showMessage:self.view labelText:@"已成功添加到下载列表" mode:MBProgressHUDModeText];
    
}


-(void)setLabelSpace:(UILabel*)label withValue:(NSString*)str withFont:(UIFont*)font {
    NSMutableParagraphStyle *paraStyle = [[NSMutableParagraphStyle alloc] init];
    paraStyle.lineBreakMode = NSLineBreakByCharWrapping;
    paraStyle.alignment = NSTextAlignmentLeft;
    /*! 设置行间距 */
    paraStyle.lineSpacing = 5;
    paraStyle.hyphenationFactor = 1.0;
    paraStyle.firstLineHeadIndent = 0.0;
    paraStyle.paragraphSpacingBefore = 0.0;
    paraStyle.headIndent = 0;
    paraStyle.tailIndent = 0;
    /*! 设置字间距 NSKernAttributeName:@1.5f */
    NSDictionary *dic = @{NSFontAttributeName:font, NSParagraphStyleAttributeName:paraStyle, NSKernAttributeName:@0.0f
                          };
    NSAttributedString *attributeStr = [[NSAttributedString alloc] initWithString:str attributes:dic];
    label.attributedText = attributeStr;
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
