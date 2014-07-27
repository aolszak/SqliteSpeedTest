//
//  TestViewController.m
//  sqliteTest
//
//  Created by Art on 05.07.2014.
//  Copyright (c) 2014 DMSI. All rights reserved.
//

#import "TestViewController.h"
#import <sqlite3.h>
#include <iostream.h>
#import "User.h"

#define NUM 50000

@interface TestViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *arrayList;

@end

@implementation TestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _arrayList = [NSMutableArray array];
    
    [self performTestForRaw];
}

- (void)performTestForCoreData {
    [self clearCoreData];
    
    NSDate *date1 = [NSDate date];
    [self saveCoreData];
    NSDate *date2 = [NSDate date];
    [self loadCoreData];
    NSDate *date3 = [NSDate date];
    NSLog(@"save %f / load %f", [date2 timeIntervalSinceDate:date1], [date3 timeIntervalSinceDate:date2]);
}

- (void)performTestForRaw {
    NSDate *date1 = [NSDate date];
    [self saveRaw];
    NSDate *date2 = [NSDate date];
    [self loadFM:@"FUNCTIONS"];
    NSDate *date3 = [NSDate date];
    NSLog(@"save %f / load %f", [date2 timeIntervalSinceDate:date1], [date3 timeIntervalSinceDate:date2]);
}

- (void)loadFM:(NSString*)name {
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths lastObject];
    NSString* databasePath = [documentsDirectory stringByAppendingPathComponent:@"database.sqlite"];
    
    FMDatabase *database = [FMDatabase databaseWithPath:databasePath];
    [database open];
    
    NSMutableArray *arr = [NSMutableArray array];
    FMResultSet *results = [database executeQuery:[NSString stringWithFormat:@"select * from %@", name]];
    int i = 0;
    while([results next]) {
        NSString *name = [results stringForColumn:@"name"];
        i++;
        [arr addObject:name];
    }
    [database executeUpdate:[NSString stringWithFormat:@"drop table %@", name]];
    [database close];
    
    _arrayList = [NSMutableArray arrayWithArray:arr];
    [_tableView reloadData];
}

- (void)saveFM {
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths lastObject];
    NSString* databasePath = [documentsDirectory stringByAppendingPathComponent:@"database.sqlite"];
    
    FMDatabase *database = [FMDatabase databaseWithPath:databasePath];
    [database open];
    [database executeUpdate:@"create table user(id int, name text, age int)"];
    
    [database beginTransaction];
    NSString *sql = @"insert into user(id, name, age) values('1','art','25');";
    for(int j = 0; j < NUM; j++) {
        for (int i=0; i<1; i++) {
            //sql = [NSString stringWithFormat:@"%@%@", sql, sql];
        }
        [database executeStatements:sql];
    }
    [database commit];
    [database close];
}

- (void)saveRaw {
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths lastObject];
    NSString* databasePath = [documentsDirectory stringByAppendingPathComponent:@"database.sqlite"];
    
    sqlite3 *database;
    if (sqlite3_open([databasePath UTF8String], &database) != SQLITE_OK) {
        sqlite3_close(database);
        NSAssert(0, @"Failed to open database");
    }
    
    char *errorMsg;
    
    sqlite3_exec(database, "PRAGMA synchronous=OFF", NULL, NULL, &errorMsg);
    //sqlite3_exec(database, "PRAGMA count_changes=OFF", NULL, NULL, &errorMsg);
    sqlite3_exec(database, "PRAGMA journal_mode=MEMORY", NULL, NULL, &errorMsg);
    //sqlite3_exec(database, "PRAGMA temp_store=MEMORY", NULL, NULL, &errorMsg);
    
    NSString *createSQL = @"CREATE TABLE IF NOT EXISTS FUNCTIONS (name TEXT, verbs TEXT, adverbs TEXT, adjectives TEXT);";
    
    if (sqlite3_exec (database, [createSQL UTF8String], NULL, NULL, &errorMsg) != SQLITE_OK) {
        sqlite3_close(database);
        NSAssert(0, @"Error creating table: %s", errorMsg);
    }
    
    sqlite3_stmt *stmt;
    char *update = "INSERT INTO FUNCTIONS (name, verbs, adverbs, adjectives) VALUES (?, ?, ?, ?);";
    
    
    if (sqlite3_prepare_v2(database, update, -1, &stmt, nil) == SQLITE_OK) {
        char* errorMessage;
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &errorMessage);
        
        const char * pln = [@"art" UTF8String];
        const char * vrb = [@"ols" UTF8String];
        const char * adv = [@"gos" UTF8String];
        const char * adj = [@"swi" UTF8String];
        
        for (int i=0; i<NUM; i++) {
            sqlite3_bind_text(stmt, 1, pln, -1, NULL);
            sqlite3_bind_text(stmt, 2, vrb, -1, NULL);
            sqlite3_bind_text(stmt, 3, adv, -1, NULL);
            sqlite3_bind_text(stmt, 4, adj, -1, NULL);
            
            if (sqlite3_step(stmt) != SQLITE_DONE)
                NSLog(@"Error updating table: %s", sqlite3_errmsg(database));
            sqlite3_reset(stmt);
        }
        
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &errorMessage);
        sqlite3_finalize(stmt);
    }
    sqlite3_close(database);
}

- (void)saveCoreData {
    for (int i=0; i<NUM; i++) {
        User *u = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        u.name = @"Test";
        u.age = @12;
        u.size = @23;
    }
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
}

- (void)loadCoreData {
    NSArray *userList = [User MR_findAll];
    NSMutableArray *names = [NSMutableArray array];
    [userList enumerateObjectsUsingBlock:^(User *obj, NSUInteger idx, BOOL *stop) {
        [names addObject:obj.name];
    }];
    _arrayList = [NSMutableArray arrayWithArray:names];
    [_tableView reloadData];
}

- (void)clearCoreData {
    NSArray *userList = [User MR_findAll];
    [userList enumerateObjectsUsingBlock:^(User *obj, NSUInteger idx, BOOL *stop) {
        [obj MR_deleteEntity];
    }];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
}

#pragma mark - TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _arrayList.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%ld - %@", NUM-indexPath.row, _arrayList[indexPath.row]];
    
    return cell;
}

@end
