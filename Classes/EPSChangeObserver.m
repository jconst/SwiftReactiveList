//
//  EPSChangeObserver.m
//  ReactiveTableViewControllerExample
//
//  Created by Peter Stuart on 5/5/14.
//  Copyright (c) 2014 Electric Peel, LLC. All rights reserved.
//

#import "EPSChangeObserver.h"

#import <ReactiveCocoa/RACEXTScope.h>
#import <ReactiveCocoa/RACEXTKeyPathCoding.h>

@interface EPSChangeObserver ()

@property (nonatomic, strong) RACSignal *objectsSignal;

@end

@implementation EPSChangeObserver

- (id)init {
    self = [super init];
    if (self == nil) return nil;
    
    RAC(self, objects) = [RACObserve(self, objectsSignal) switchToLatest];
    
    _changeSignal = [RACObserve(self, objects)
        combinePreviousWithStart:@[]
        reduce:^RACTuple *(NSArray *oldObjects, NSArray *newObjects) {
            if (!oldObjects) oldObjects = @[];
            
            NSArray *rowsToRemove;
            rowsToRemove = [[[oldObjects.rac_sequence
                filter:^BOOL(id object) {
                    return [newObjects containsObject:object] == NO;
                }]
                map:^NSIndexPath *(id object) {
                    return [NSIndexPath indexPathForRow:[oldObjects indexOfObject:object] inSection:0];
                }]
                array];
            
            NSArray *rowsToInsert = [[[newObjects.rac_sequence
                filter:^BOOL(id object) {
                    return ([oldObjects containsObject:object] == NO);
                }]
                map:^NSIndexPath *(id object) {
                    return [NSIndexPath indexPathForRow:[newObjects indexOfObject:object] inSection:0];
                }]
                array];
            
            return RACTuplePack(rowsToRemove, rowsToInsert);
        }];
    
    return self;
}

- (void)setBindingToKeyPath:(NSString *)keyPath onObject:(id)object {
    self.objectsSignal = [object rac_valuesForKeyPath:keyPath observer:self];
}

- (void)setBindingToSignal:(RACSignal *)signal {
    self.objectsSignal = signal;
}

@end
