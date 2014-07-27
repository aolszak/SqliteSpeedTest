//
//  User.h
//  sqliteTest
//
//  Created by Art on 06.07.2014.
//  Copyright (c) 2014 DMSI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface User : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * age;
@property (nonatomic, retain) NSNumber * size;

@end
