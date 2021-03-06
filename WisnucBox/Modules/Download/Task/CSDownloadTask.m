//
//  CSDownloadTask.m
//  WisnucBox
//
//  Created by wisnuc-imac on 2017/11/13.
//  Copyright © 2017年 JackYang. All rights reserved.
//

#import "CSDownloadTask.h"
#import "NSObject+KVOBlock.h"

@implementation CSDownloadTask
{
    NSURLSessionDownloadTask *_downloadDataTask;
    
    int _failureCount;
    
    id _downloadStatusKVO;
}

- (id)init
{
    self = [super init];
    if (self) {
        _downloadStatus = CSDownloadStatusTaskNotCreated;
        [self initDownloadStatusObserver];
    }
    
    return self;
}

- (void)initDownloadStatusObserver
{
    _downloadStatusKVO = [self addKVOBlockForKeyPath:@"downloadStatus" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld handler:^(NSString *keyPath, id object, NSDictionary *change) {
        
        //GSDownloadStatus oldStatusValue = [[change objectForKey:NSKeyValueChangeOldKey] integerValue];
        
        
        CSDownloadTask* task = object;
        [task.getDownloadUIBinder updateUIWithTask:task];
    }];
    
}


- (BOOL)isEqualToDownloadTask:(CSDownloadTask*)downloadTask
{
    if ([[self getDownloadTaskId]compare:[downloadTask getDownloadTaskId]] == 0) {
        return YES;
    }
    return NO;
}

#pragma mark - GSSingleDownloadTaskProtocol

- (void)setDownloadDataTask:(NSURLSessionDownloadTask *)downloadDataTask{
    _downloadDataTask = downloadDataTask;
}


- (void)startDownloadTask:(void (^)())bindDoSomething
{
    [_downloadDataTask resume];
    if (bindDoSomething)
    {
        bindDoSomething();
    }
}

- (void)pauseDownloadTask:(void (^)())bindDoSomething
{
    [_downloadDataTask suspend];
    
    if (bindDoSomething)
    {
        bindDoSomething();
    }
}

- (void)continueDownloadTask:(void (^)(BOOL isComplete))bindDoSomething
{
    BOOL isComplete;
    if (_downloadDataTask.state == NSURLSessionTaskStateSuspended) {
        [_downloadDataTask resume];
        isComplete = NO;
    }else{
        isComplete = YES;
        
    }
    
    if (bindDoSomething)
    {
        bindDoSomething(isComplete);
    }
}

- (void)cancelDownloadTask:(void (^)())bindDoSomething
{
    [_downloadDataTask cancel];
    
    if (bindDoSomething)
    {
        bindDoSomething();
    }
}

- (int)increaseFailureCount
{
    _failureCount++;
    
    return _failureCount;
}

#pragma mark - dealloc
- (void)dealloc
{
    NSLog(@"%@ dealloc",[self class]);
    
    [self removeKVOBlockForToken:_downloadStatusKVO];
}

@end
