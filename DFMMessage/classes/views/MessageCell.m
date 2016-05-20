//
//  MessageCell.m
//  DFMMessage
//
//  Created by dangfm on 14-5-6.
//  Copyright (c) 2014年 dangfm. All rights reserved.
//

#import "MessageCell.h"
#import "MessageFrame.h"
#import "NSData+Base64.h"
#import "NSString+Base64.h"
#import <AVFoundation/AVFoundation.h>
#import "lame.h"

#define kSay_png [UIImage imageNamed:@"say"]
#define kSayMe_png [UIImage imageNamed:@"sayme"]
#define kNoReadPiont_png [UIImage imageNamed:@"noReadPoint"]

@interface MessageCell ()<AVAudioPlayerDelegate>
{
    UIButton     *_timeBtn;
    UIImageView *_iconView;
    UIButton    *_contentBtn;
    NSData *_datas;
    AVAudioPlayer *_currentPlayer;
    UIImageView *_sayView;
    UILabel *_secondView;
    UIImage *_say_png;
    UIImage *_sayMe_png;
    UIImageView *_isReadView;
    
    EMessages *_msm;
    
    UIImageView *picImg;
}

@end

static AVAudioPlayer *_player;
static NSString *_time;

@implementation MessageCell

-(void)dealloc{
    _timeBtn = nil;
    _iconView = nil;
    _contentBtn = nil;
    _datas = nil;
    _currentPlayer = nil;
    _sayView = nil;
    _secondView = nil;
    _say_png = nil;
    _sayMe_png = nil;
    _player = nil;
    _msm = nil;
}
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // warning 必须先设置为clearColor，否则tableView的背景会被遮住
        self.backgroundColor = [UIColor clearColor];
        _say_png = kSay_png;
        _sayMe_png = kSayMe_png;
        // 1、创建时间按钮
        _timeBtn = [[UIButton alloc] init];
        [_timeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _timeBtn.titleLabel.font = kTimeFont;
        _timeBtn.enabled = NO;
        _timeBtn.layer.cornerRadius = 5;
        _timeBtn.layer.backgroundColor = UIColorWithHex(0x000000).CGColor;
        _timeBtn.alpha = 0.1;
        [self.contentView addSubview:_timeBtn];
        
        // 2、创建头像
        _iconView = [[UIImageView alloc] init];
        [self.contentView addSubview:_iconView];
        
        // 3、创建内容
        _contentBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_contentBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        
        _contentBtn.titleLabel.font = kContentFont;
        _contentBtn.titleLabel.numberOfLines = 0;
        
        [self.contentView addSubview:_contentBtn];
        
        _sayView = [[UIImageView alloc] init];
        _sayView.tag = 10;
        [_contentBtn addSubview:_sayView];
        _secondView = [[UILabel alloc] init];
        _secondView.textColor = UIColorWithHex(0xCCCCCC);
        _secondView.backgroundColor = KClearColor;
        [_contentBtn addSubview:_secondView];
        
        //未读图标
        _isReadView = [[UIImageView alloc] initWithImage:kNoReadPiont_png];
        [_contentBtn addSubview:_isReadView];
        _isReadView.hidden = NO;
        
        
        picImg=[[UIImageView alloc]init];
        [self.contentView addSubview:picImg];
    }
    return self;
}

- (void)setMessageFrame:(MessageFrame *)messageFrame{
    
    _messageFrame = messageFrame;
    _msm = _messageFrame.message;
    // 1、设置时间
    if (_messageFrame.showTime) {
        _timeBtn.hidden = NO;
        NSString *tt = [CommonOperation toDescriptionStringWithTimestamp:_msm.time];
        [_timeBtn setTitle:tt forState:UIControlStateNormal];
        _timeBtn.frame = _messageFrame.timeF;
        tt = nil;
    }else{
        _timeBtn.hidden = YES;
    }
        // 2、设置头像
    _iconView.image = [UIImage imageNamed:@"noface"];
    _iconView.frame = _messageFrame.iconF;
    
    // 3、设置内容
    NSString *body = _msm.content;
    _contentBtn.frame = _messageFrame.contentF;
    int second = _msm.second;
    //文本
    if (_msm.sendTyep==0) {
        _isReadView.hidden = YES;
        _contentBtn.tag = 10;
        _contentBtn.hidden=NO;
        _datas = nil;
        _sayView.image = nil;
        _secondView.text = nil;
        [_contentBtn setTitle:body forState:UIControlStateNormal];
    }
    //语音
    if (_msm.sendTyep==1) {
        if ([body hasPrefix:@"base64"] &&[[body substringWithRange:NSMakeRange(0, 11)] isEqualToString:@"base64Audio"]) {
            _contentBtn.tag = 100;
            body = @"";
            if (_msm.content.length>0) {
                _datas = [[_msm.content substringFromIndex:11] base64DecodedData];
            }
            
            UIImage *sayimg = _say_png;
            CGFloat x = 20;
            CGFloat y = 10;
            
            if (_msm.messageType==0) {
                sayimg = _sayMe_png;
                x = _contentBtn.frame.size.width-30;
            }
            _sayView.frame = CGRectMake(x, y, sayimg.size.width, sayimg.size.height);
            _sayView.image = sayimg;
            
            x = -25;
            y = 0;
            if (_msm.messageType==1) {
                x = _contentBtn.frame.size.width+10;
            }
            _secondView.text = [NSString stringWithFormat:@"%d'",second];
            [_secondView sizeToFit];
            _secondView.frame = CGRectMake(x, y, _secondView.frame.size.width, _contentBtn.frame.size.height);
            sayimg = nil;
            
            if (!_msm.isRead) {
                _isReadView.hidden = NO;
                _isReadView.frame = CGRectMake(x-5, y, kNoReadPiont_png.size.width, kNoReadPiont_png.size.height);
            }else{
                _isReadView.hidden = YES;
            }
        }
    }
    //图片
    if (_msm.sendTyep==2) {
        if ([body hasPrefix:@"base64"]&&[[body substringWithRange:NSMakeRange(0, 11)] isEqualToString:@"base64Image"] ) {
        _isReadView.hidden = YES;
            [_contentBtn setImage:[UIImage imageWithData:[[_msm.content substringFromIndex:11] base64DecodedData]] forState:UIControlStateNormal];
            _contentBtn.imageEdgeInsets=UIEdgeInsetsMake(-5, -60, -10, 0);
            [_contentBtn setBackgroundImage:nil forState:UIControlStateNormal];
            if (_msm.messageType == 1) {
                _contentBtn.imageEdgeInsets=UIEdgeInsetsMake(-5, 0, -10, -60);
                [_contentBtn setBackgroundImage:nil forState:UIControlStateNormal];
            }
        }
    }
    
     [_contentBtn addTarget:self action:@selector(clickButtonCell:) forControlEvents:UIControlEventTouchUpInside];
}

-(void)clickButtonCell:(UIButton*)sender{
    if (sender.tag==100) {
        //NSLog(@"%@",sender);
        NSError *playerError;
        if (_player) {
            [_player stop];
        }
        if (_currentPlayer==_player && _currentPlayer && _player) {
            _player = nil;
            return;
        }
        _player = [[AVAudioPlayer alloc] initWithData:_datas error:&playerError];
        _player.delegate = self;
        [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategorySoloAmbient error: nil];
        _currentPlayer = _player ;
        if (_player == nil)
        {
            NSLog(@"ERror creating player: %@", [playerError description]);
        }
        
        NSLog(@"秒：%f",_player.duration);
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self play];
        });
        
        // 隐藏红点
        _isReadView.hidden = YES;
        _msm.isRead = YES;
        [DataOperation save];

    }
    

}

- (void)play{
    if([_player isPlaying])
    {
        [_player stop];
    }
      else
    {
        [_player play];
    }
}

-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    NSLog(@"完成播放%f秒",player.duration);
}

@end
