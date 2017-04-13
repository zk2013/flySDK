//
//  LoginViewController.m
//  KCT_VOIP_Demo
//
//  Created by KCMac on 2017/1/7.
//  Copyright © 2017年 KCMac. All rights reserved.
//






@interface LoginViewController ()
{
    BOOL _isRember;
    NSUserDefaults *_defaults;
}

@property(weak,nonatomic)IBOutlet UITableView *tableView;
@property(weak,nonatomic)IBOutlet UIButton *remberBtn;
@property(weak,nonatomic)IBOutlet UILabel *versionLabel;


@end



@implementation LoginViewController


#pragma mark ---------UIViewController ------------

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
    [LoginManager sharedLoginManager].currentPageIndex = appPageIndexLogin;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _defaults = [NSUserDefaults standardUserDefaults];
    _isRember = [_defaults boolForKey:kIsRemberPwdKey];
    [self changeRemeberBtnState:_isRember];
    
    [_tableView registerNib:[UINib nibWithNibName:@"LoginTableViewCell" bundle:nil] forCellReuseIdentifier:@"loginCell"];
    
    NSString *version =[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    self.versionLabel.text = [NSString stringWithFormat:@"V %@",version];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark  ----------UITableView------------

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    LoginTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"loginCell"];
    
    if (!cell) {
        cell = [[LoginTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"loginCell"];
    }
    if (indexPath.row == 0) {
        cell.textField.placeholder = @"输入用户名";
        if (_isRember) {
            NSString *userid = [_defaults objectForKey:kUserNameKey];
            if (userid) {
                cell.textField.text = userid;
            } else {
                cell.textField.text = @"119140589@qq.com";
            }
        } else {
            cell.textField.text = @"119140589@qq.com";
        }
        cell.leftImageView.image = [UIImage imageNamed:@"login_admin.png"];
        
    } else {
        cell.textField.placeholder = @"输入密码";
        if (_isRember) {
            NSString *pwd = [_defaults objectForKey:kUserPwdKey];
            if (pwd) {
                cell.textField.text = pwd;
                
            } else {
                cell.textField.text = @"kc123456";
            }
        } else {
            cell.textField.text = @"kc123456";
        }
        
        cell.textField.secureTextEntry = YES;
        cell.leftImageView.image = [UIImage imageNamed:@"login_pwd.png"];
    }
    return cell;
}


#pragma mark ---------private------------

- (void)changeRemeberBtnState:(BOOL)isRember
{
    UIImage *image = nil;
    
    if (isRember) {
        image = [UIImage imageNamed:@"checkbox_on.png"];
    } else {
        image = [UIImage imageNamed:@"checkbox_off.png"];
    }
    
    [self.remberBtn setImage:image forState:UIControlStateNormal];
    [self.remberBtn setImage:image forState:UIControlStateHighlighted];
}

- (void)loginWithUser:(NSString *)userId pwd:(NSString *)pwd {
    if ([userId isEqualToString:@""] || [pwd isEqualToString:@""]) {
        [mytoast showWithText:@"用户名或密码不能为空，请看右上方的\"帮助\""];
        return;
    }
    
    [MBProgressHUD showMessage:@"正在获取账号，请稍等..." toView:self.view];
    
    __weak __typeof(self)weakSelf = self;
    
    [[HttpRequestEngine engineInstance] newLogin:userId token:pwd successBlock:^(NSDictionary *responseDict) {
        NSDictionary *newRespDic = [responseDict objectForKey:@"resp"];
        NSNumber *nRespCode = [newRespDic objectForKey:@"respCode"];
        if ([nRespCode intValue] == 0 && nRespCode != nil) {
            NSArray *newArray = [newRespDic objectForKey:@"client"];
            
            [[HttpRequestEngine engineInstance] login:userId token:pwd successBlock:^(NSDictionary *responseDict) {
                
                NSDictionary *respDic = [responseDict objectForKey:@"resp"];
                NSNumber *nRespCode = [respDic objectForKey:@"respCode"];
                if ([nRespCode intValue] == 0 && nRespCode != nil) {
                    
                    if (_isRember) {
                        [_defaults setBool:YES forKey:kIsRemberPwdKey];
                        [_defaults setObject:userId forKey:kUserNameKey];
                        [_defaults setObject:pwd forKey:kUserPwdKey];
                    } else {
                        [_defaults setBool:NO forKey:kIsRemberPwdKey];
                        [_defaults setObject:nil forKey:kUserNameKey];
                        [_defaults setObject:nil forKey:kUserPwdKey];
                    }
                    
                    
                    [MBProgressHUD hideAllHUDsForView:weakSelf.view animated:YES];
                    [mytoast showWithText:@"登录成功"];
                    
                    NSArray *array = [respDic objectForKey:@"client"];
                    CallingListViewController *controller;
                    if (_isAutoLogin) {
                        NSMutableArray *arrays = [[LoginManager sharedLoginManager] getControllerArrays];
                        if (arrays.count >= 3) {
                            controller = (CallingListViewController *)[arrays objectAtIndex:1];
                        }
                        else
                        {
                            controller = [[CallingListViewController alloc] init];
                        }
                    } else {
                        controller = [[CallingListViewController alloc] init];
                    }
                    
                    self.callController = controller;
                    controller.dataArray = array;
                    controller.flycanDataArray = newArray;
                    controller.isAutoLogin = _isAutoLogin;
                    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
                    [dic setObject:[respDic objectForKey:@"sid"] forKey:@"sid"];
                    [dic setObject:[respDic objectForKey:@"token"] forKey:@"token"];
                    controller.accountInfoDic = dic;
                    
                    [_defaults setObject:[respDic objectForKey:@"sid"] forKey:kAccountSid];
                    [_defaults setObject:[respDic objectForKey:@"token"] forKey:kAccountToken];
                    [_defaults synchronize];
                    
                    controller.loginBlock = ^(NSDictionary *dic,NSArray *arrays) {
                        NSLog(@"login success");
                    };
                    if (_isAutoLogin)
                    {
                        [controller autoConnectService];
                        [[LoginManager sharedLoginManager] addController:controller];
                    }
                    if (!_isAutoLogin) {
                        [weakSelf.navigationController pushViewController:controller animated:YES];
                    }
                    
                } else {
                    int iRespCode = [nRespCode intValue];
                    NSString *message = [NSString stringWithFormat:@"登录失败，错误码：%d",iRespCode];
                    [mytoast showWithText:message];
                    [MBProgressHUD hideAllHUDsForView:weakSelf.view animated:YES];
                }
            } failBlock:^(NSDictionary *responseDict) {
                [mytoast showWithText:@"登录失败"];
                [MBProgressHUD hideAllHUDsForView:weakSelf.view animated:YES];
            }];
        }
    } failBlock:^(NSDictionary *responseDict) {
        
        
    }];
    
}


#pragma mark ----------UIButton Event--------

- (IBAction)apphelp:(id)sender
{
    AppHelpViewController *controller = [[AppHelpViewController alloc] init];
    [self presentViewController:controller animated:YES completion:nil];
}

- (IBAction)remeberPwd:(id)sender {
    _isRember = !_isRember;
    [self changeRemeberBtnState:_isRember];
    
}

- (IBAction)loginPress:(id)sender {
    _isAutoLogin = NO;
    LoginTableViewCell *row0 = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    LoginTableViewCell *row1 = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    NSString *userId = row0.textField.text;
    NSString *pwd = row1.textField.text;
    [self loginWithUser:userId pwd:pwd];
}


#pragma mark -------Orientation------

- (BOOL)shouldAutorotate
{
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;//只支持这一个方向(正常的方向)
}


#pragma mark ------------end----------

@end