//
//  ViewController.m
//  ImageCacheDemo
//
//  Created by X on 2018/2/28.
//  Copyright © 2018年 X. All rights reserved.
//

#import "ViewController.h"
#import "XAppModel.h"

@interface ViewController ()<UITableViewDataSource,UITableViewDelegate>

@property (nonatomic,strong) UITableView *tableView;
/** 从plist加载过来的数据 */
@property (nonatomic,strong) NSArray *dataArr;
/** 内存中存储图片的容器 */
@property (nonatomic,strong) NSCache *imageCaches;
/** 存储操作的字段 */
@property (nonatomic,strong) NSMutableDictionary *operationsDic;
/** 队列 */
@property (nonatomic,strong) NSOperationQueue *queue;

@end

@implementation ViewController

- (NSArray *)dataArr{
    if (!_dataArr) {
        NSMutableArray *appModelArr = [NSMutableArray array];
        NSString *path = [[NSBundle mainBundle] pathForResource:@"apps.plist" ofType:nil];
        NSLog(@"🏀🏀--%@",path);
        NSLog(@"路径--%@",[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]);
        NSArray *dictArr = [NSArray arrayWithContentsOfFile:path];
        for (NSDictionary *dict in dictArr) {
            XAppModel *app = [XAppModel appModelWithDic:dict];
            [appModelArr addObject:app];
        }
        _dataArr = appModelArr;
    }
    return _dataArr;
}

- (NSCache *)imageCaches{
    if (!_imageCaches) {
        _imageCaches = [[NSCache alloc] init];
        _imageCaches.countLimit = 100;
    }
    return _imageCaches;
}

- (NSMutableDictionary *)operationsDic{
    if (!_operationsDic) {
        _operationsDic = [NSMutableDictionary dictionary];
    }
    return _operationsDic;
}

- (NSOperationQueue *)queue{
    if (!_queue) {
        _queue = [[NSOperationQueue alloc] init];
    }
    return _queue;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    tableView.dataSource = self;
    tableView.delegate = self;
    _tableView = tableView;
    [self.view addSubview:tableView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellIdetifier = @"cellID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdetifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdetifier];
    }
    XAppModel *app = self.dataArr[indexPath.row];
    cell.textLabel.text = app.name;
    cell.detailTextLabel.text = app.download;
    //先从缓存中取
//    UIImage *image = [self.imageCaches objectForKey:app.icon];
    NSData *image = [self.imageCaches objectForKey:app.icon];
    if (image) {
        cell.imageView.image = [UIImage imageWithData:image];
    }else{//如果没有就去沙盒中取
        NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        //获取图片路径最后一个节点
        NSString *imagePath = [app.icon lastPathComponent];
        //拼接图片在沙盒中的全路径
        NSString *fullPath = [filePath stringByAppendingPathComponent:imagePath];
        //从磁盘中获取
        NSData *imageData = [NSData dataWithContentsOfFile:fullPath];
        if (imageData) {
            cell.imageView.image = [UIImage imageWithData:imageData];
        }else{
            cell.imageView.image = [UIImage imageNamed:@"placeholder"];
            //试着去存储操作的字典里找到当前进行的操作
            NSBlockOperation *operation = [self.operationsDic objectForKey:app.icon];
//            [operation cancel];
            if (!operation) {
                NSBlockOperation *download = [NSBlockOperation blockOperationWithBlock:^{
                    NSURL *url = [NSURL URLWithString:app.icon];
                    NSData *imageData = [NSData dataWithContentsOfURL:url];
                    if (!imageData) {
                        return ;
                    }
                    //缓存中保存一份
                    [self.imageCaches setObject:imageData forKey:app.icon];
                    //写入沙盒中
                    [imageData writeToFile:fullPath atomically:YES];
                    //回到主线程设置图片
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//                        [cell.imageView performSelector:@selector(setImage:) withObject:[UIImage imageWithData:imageData] afterDelay:0 inModes:@[NSDefaultRunLoopMode]];
                        //刷新表格
                        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                        [self.operationsDic removeObjectForKey:app.icon];
                    }];
                }];
                //添加到下载队列
                [self.queue addOperation:download];
                //在下载操作字典中做下记录
                [self.operationsDic setObject:download forKey:app.icon];
            }else{
                //如果找到下载操作就什么都不用做，等待下载完成后直接显示即可


            }
        }
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 100;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self.imageCaches removeAllObjects];
    [self.queue cancelAllOperations];
}


@end
