//
//  ViewController.m
//  SimpleChatDemo
//
//  Created by 王勇 on 2019/3/17.
//  Copyright © 2019年 王勇. All rights reserved.
//

#import "ViewController.h"
#import "UdpManager.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *toBottom;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UITextField *textField;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"路人甲";
    
    [UdpManager initSocketWithReceiveHandle:^{

        dispatch_async(dispatch_get_main_queue(), ^{
            
            self.title = [NSString stringWithFormat:@"%@---%@",[[UdpManager shareManager] valueForKey:@"_destHost"],[[UdpManager shareManager] valueForKey:@"_destPort"]];
            
            [self reloadData];
        });
    }];

    // 添加通知监听见键盘弹出/退出
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardAction:) name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardAction:) name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark - data

- (void)reloadData
{
    [self.tableView reloadData];
    
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:UdpManager.messageArray.count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

- (CGFloat)getLabelHeight:(MessageModel *)model
{
    CGFloat labelWidth = [self getLabelWidth:model];
    
    CGFloat labelHeight = 40;
    
    labelWidth = MIN(self.view.frame.size.width*0.7, labelWidth);
    
    if (labelWidth >= self.view.frame.size.width*0.7) {
        
        labelHeight = MAX([model.message boundingRectWithSize:CGSizeMake(self.view.frame.size.width*0.7, MAXFLOAT) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:17.0]} context:nil].size.height, 20) + 20;
    }
    
    return labelHeight;
}

- (CGFloat)getLabelWidth:(MessageModel *)model
{
    return  MIN(self.view.frame.size.width*0.7, [model.message boundingRectWithSize:CGSizeMake(MAXFLOAT, 20) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:17.0]} context:nil].size.width);
}


#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (self.textField.text.length == 0) return YES;
    
    [UdpManager sendMessage:self.textField.text];
    
    [self reloadData];
    
    self.textField.text = nil;
    
    return YES;
}
// 键盘监听事件
- (void)keyboardAction:(NSNotification*)sender{
    
    NSDictionary *useInfo = [sender userInfo];
    
    NSValue *value = [useInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    
    if([sender.name isEqualToString:UIKeyboardWillShowNotification]) self.toBottom.constant = -[value CGRectValue].size.height;
    
    else self.toBottom.constant = 0;
    
    [UIView animateWithDuration:[[useInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey] floatValue]  animations:^{
        
        [self.view layoutIfNeeded];
    }];
}
#pragma mark - touch
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.textField endEditing:YES];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView;
{
    [self.textField endEditing:YES];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return  UdpManager.messageArray.count;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self getLabelHeight:UdpManager.messageArray[indexPath.row]] + 10;
}
- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString * cellId = @"cellId";
    
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    
    if (cell == nil) {
        
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    }
    
    [cell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    MessageModel * model = UdpManager.messageArray[indexPath.row];
    
    CGFloat labelWidth = [self getLabelWidth:model];
    
    CGFloat labelHeight = [self getLabelHeight:model];
    
    UIView * backView = [[UIView alloc] initWithFrame:CGRectMake(model.role ? (self.view.frame.size.width - labelWidth - 40) : 20, 5, labelWidth + 20, labelHeight)];
    
    backView.backgroundColor = model.role ? [UIColor greenColor] : [UIColor whiteColor];
    
    backView.layer.cornerRadius = 3;
    
    backView.layer.masksToBounds = YES;
    
    UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, labelWidth, labelHeight)];
    
    label.text = model.message;
    
    label.numberOfLines = 0;

    [backView addSubview:label];
    
    [cell.contentView addSubview:backView];
    
    cell.contentView.backgroundColor = self.tableView.backgroundColor;
    
    return cell;
}
@end
