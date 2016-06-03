//
//  ViewController.m
//  RefreshDemo
//
//  Created by WP_YK on 16/5/31.
//  Copyright © 2016年 WP_YK. All rights reserved.
//

#import "ViewController.h"


#define ScreenWidth   [UIScreen mainScreen].bounds.size.width
#define ScreenHeight  [UIScreen mainScreen].bounds.size.height
#define headerHeight  50

typedef enum {
    RefreshStateNomal,
    RefreshStateRefreshing,
}RefreshState;

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>

// ---- 界面元素 -------
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIImageView *headerImageView;
@property (nonatomic, strong) UILabel *showLabel;

// ------ 数据相关 ------
/** tableView数据数组 */
@property (nonatomic, strong) NSArray *listArr;
/** gif图片数组 */
@property (nonatomic, strong) NSMutableArray *imageArr;
/** 刷新状态 */
@property (nonatomic, assign) RefreshState refreshState;
/** 是否正在刷新 */
@property (nonatomic, assign) BOOL refreshing;
/** 图片缩放比 */
@property (nonatomic, assign) float imageScale;
/** 初始Y轴偏移量 */
@property (nonatomic, assign) CGFloat initInsetY;

@end

@implementation ViewController
#pragma mark - 懒加载
- (NSArray *)listArr {
    if (!_listArr) {
        _listArr = [NSArray arrayWithObjects:@"第一项",@"第二项",@"第三项",@"第四项",@"第五项",@"第六项",@"第七项",@"第八项",@"第九项", nil];
    }
    return _listArr;
}

- (NSMutableArray *)imageArr {
    if (!_imageArr) {
        _imageArr = [NSMutableArray array];
        for(int i=1;i<=3;i++) {
            UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"loading_%dTest",i]];
            [_imageArr addObject:image];
        }
    }
    return _imageArr;
}

#pragma mark - 控制器生命周期方法
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.title = @"首页";
    self.refreshState = RefreshStateNomal;
    self.tableView.rowHeight = 50;
    self.tableView.tableHeaderView = [self createHeaderView];
    
    // 增加滚动区域
    UIEdgeInsets inset = _tableView.contentInset;
    inset.top = -headerHeight;
    _tableView.contentInset = inset;
    
    //  添加监听器，监听tableView的滚动距离
    [self.tableView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
    //  ps:这里用UIScrollViewDelegate应该也可以
}

#pragma mark - 私有方法
- (UIView *)createHeaderView {
    
    UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, headerHeight)];
    bgView.backgroundColor = [UIColor grayColor];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(20, 0, headerHeight, headerHeight)];
    [bgView addSubview:imageView];
    [imageView setAnimationImages:self.imageArr];
    [imageView setAnimationRepeatCount:0];
    [imageView setAnimationDuration:1];
    imageView.image = [UIImage imageNamed:@"loading_1Test"];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(100, 10, 100, 30)];
    label.text = @"下拉刷新...";
    [bgView addSubview:label];
    
    self.headerView = bgView;
    self.headerImageView = imageView;
    self.showLabel = label;
    
    return bgView;
}

/**
 设置控件状态
 */

-(void)setState:(RefreshState)state{
    
    if (_refreshState == state)return;
    
    switch (state) {
        case RefreshStateNomal:
            if ([self.headerImageView isAnimating]) {
                [self.headerImageView stopAnimating];
                [self.showLabel setText:@"下拉刷新..."];
            }
            break;
        case RefreshStateRefreshing:
            _refreshing = true;
            [self.headerImageView startAnimating];//开始动画
            break;
        default:
            break;
    }
    
    _refreshState = state;
}

- (void)beginRefresh {

    // 增加滚动区域
    UIEdgeInsets inset = _tableView.contentInset;
    inset.top = -_initInsetY+headerHeight;
    _tableView.contentInset = inset;
    
    // 设置滚动位置
//    _tableView.contentOffset = CGPointMake(0,-headerHeight);
    [_showLabel setText:@"更新中..."];
    
    [self performSelector:@selector(hide) withObject:nil afterDelay:5.0];
}

- (void)hide {
    
    UIEdgeInsets inset = _tableView.contentInset;
    inset.top = -_initInsetY;
    
    [UIView animateWithDuration:0.5 animations:^{
        _tableView.contentInset = inset;
    }];
    
    [self setState:RefreshStateNomal];
    self.imageScale = 0.0;
}

// 设置图片的缩放
- (void)setImageScale:(float)imageScale {
    if (imageScale>1) {
        imageScale = 1;
    }
    _imageScale = imageScale;
    if (![_headerImageView isAnimating]) {
        
        [UIView animateWithDuration:0.1 animations:^{
            [_headerImageView setTransform:CGAffineTransformMakeScale(imageScale, imageScale)];
        }];
    }
}

#pragma mark - 实现监听方法
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
    //  临时获取方式
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        // 获取tableView的初始Y轴偏移量
        self.initInsetY = _tableView.contentOffset.y;
    });
    
    
    if (![@"contentOffset" isEqualToString:keyPath] || _tableView.contentOffset.y>0)
        return;
    
    CGFloat offsetY = _tableView.contentOffset.y;
    
    self.imageScale = (-offsetY)/(-_initInsetY+headerHeight);
    
    if (!_tableView.isDragging && -offsetY>headerHeight && !(_refreshState == RefreshStateRefreshing)) {
        
        [self setState:RefreshStateRefreshing];
        [self beginRefresh];
        
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - UITableViewDelegate, UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.listArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdent = @"myCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdent];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdent];
    }
    
    cell.textLabel.text = _listArr[indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"点击了第%ld项",indexPath.row);
}


@end
