//
//  FMHeadView.m
//  FruitMix
//
//  Created by 杨勇 on 16/4/5.
//  Copyright © 2016年 WinSun. All rights reserved.
//

#import "FMHeadView.h"

@implementation FMHeadView{
    @private
    UIView * _contentView;
    UILabel * _titleLb;
    UIButton * _choosebtn;
}

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes{
    if(!_contentView){
        _contentView = [[UIView alloc]initWithFrame:CGRectZero];
        _contentView.backgroundColor = [UIColor whiteColor];
        _titleLb = [[UILabel alloc]initWithFrame:CGRectMake((20+44+33)/2+8, 10, 100, 20)];
        _titleLb.textColor = [UIColor blackColor];
        _titleLb.font = [UIFont systemFontOfSize:14];
        _titleLb.userInteractionEnabled =YES;
        UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(_chooseBtnClick:)];
        [_titleLb addGestureRecognizer:tap];
        _choosebtn = [[UIButton alloc]initWithFrame:CGRectMake(20/2, 23/2,42-23, 42-23)];
        [_choosebtn addTarget:self action:@selector(_chooseBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        [_choosebtn setBackgroundImage:[UIImage imageNamed:[self getImageWithChoose:_isChoose]] forState:UIControlStateNormal];
        [_contentView addSubview:_titleLb];
        [_contentView addSubview:_choosebtn];
        [self addSubview:_contentView];
        
        [_contentView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self.mas_left).with.offset(-((20+44/2)));
            make.right.mas_equalTo(self.mas_right);
            make.top.mas_equalTo(self.mas_top);
            make.bottom.mas_equalTo(self.mas_bottom);
        }];
    }
}

- (void)setHeadTitle:(NSString *)headTitle{
    _headTitle = headTitle;
    if (_titleLb) {
        _titleLb.text = headTitle;
    }
}

- (void)setIsChoose:(BOOL)isChoose{
    _isChoose = isChoose;
     [_choosebtn setBackgroundImage:[UIImage imageNamed:[self getImageWithChoose:_isChoose]] forState:UIControlStateNormal];
}

- (void)setIsSelectMode:(BOOL)isSelectMode {
    _isSelectMode = isSelectMode;
    if (_isSelectMode) {
        [UIView animateWithDuration:0.5 animations:^{
            _titleLb.transform = CGAffineTransformMakeTranslation((20+44)/2 - (33-15)/2 +5, 0);
            _choosebtn.transform = CGAffineTransformMakeTranslation((20+44)/2 + 5 + 10, 0);
        }];
    }else{
        [UIView animateWithDuration:0.5 animations:^{
            _titleLb.transform = CGAffineTransformIdentity;
            _choosebtn.transform = CGAffineTransformIdentity;
        }];
    }
}

-(NSString *)getImageWithChoose:(BOOL)isChoose{
    if (isChoose) {
        return @"select";
    }else
        return @"unselected";
}

- (void)_chooseBtnClick:(id)sender{
    self.isChoose = !self.isChoose;
    [_choosebtn setBackgroundImage:[UIImage imageNamed:[self getImageWithChoose:_isChoose]] forState:UIControlStateNormal];
    if (self.fmDelegate) {
        if([_fmDelegate respondsToSelector:@selector(FMHeadView:isChooseBtn:)]){
            [_fmDelegate FMHeadView:self isChooseBtn:self.isChoose];
        }
    }
}
@end
