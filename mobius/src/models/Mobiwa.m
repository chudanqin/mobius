//
//  Mobiwa.m
//  mobius
//
//  Created by chudanqin on 09/04/2018.
//  Copyright © 2018 chudanqin. All rights reserved.
//

#import <sys/stat.h>
#import <libmobi/mobi.h>
#import "mobi_tools.h"
#import "Mobiwa.h"

@interface Mobiwa ()

@property (nonatomic, copy) NSString *lastDir;

@property (nonatomic, copy) NSString *metaInfoLastPath;

@property (nonatomic, copy) NSString *MIMETypeLastPath;

@property (nonatomic, strong) NSMutableArray<NSString *> *mMarkupLastPaths;

@property (nonatomic, strong) NSMutableArray<NSString *> *mFlowLastPaths;

@property (nonatomic, strong) NSMutableArray<NSString *> *mResourceLastPaths;

- (void)addMarkupLastPath:(NSString *)markupLastPath;

- (void)addFlowLastPath:(NSString *)flowLastPath;

- (void)addResourceLastPath:(NSString *)resourceLastPath;

- (void)endParsing;

@end

void my_mobi_dump_rawml_meta_info(void *context, char *base_dir, char *meta_info_last_path) {
    Mobiwa *mobiwa = (__bridge Mobiwa *)context;
    mobiwa.baseDir = [NSString stringWithUTF8String:base_dir];
    mobiwa.lastDir = [mobiwa.baseDir lastPathComponent];
    mobiwa.metaInfoLastPath = [[NSString stringWithUTF8String:EPUB_META_INFO_PATH_COMPONENT] stringByAppendingPathComponent:[NSString stringWithUTF8String:EPUB_META_INFO_CONTAINER_FILE_NAME]];
}

void my_mobi_dump_rawml_mimetype(void *context, char *mimetype_last_path) {
    Mobiwa *mobiwa = (__bridge Mobiwa *)context;
    mobiwa.MIMETypeLastPath = [NSString stringWithUTF8String:EPUB_MIME_TYPE_FILE_NAME];
}

void my_mobi_dump_rawml_resource(void *context, char *resource_last_path) {
    Mobiwa *mobiwa = (__bridge Mobiwa *)context;
    NSString *parentDir = [NSString stringWithUTF8String:EPUB_OEBPS_PATH_COMPONENT];
    NSString *resourceName = [NSString stringWithUTF8String:resource_last_path];
    [mobiwa addResourceLastPath:[parentDir stringByAppendingPathComponent:resourceName]];
}

void my_mobi_dump_rawml_markup(void *context, char *markup_last_path) {
    Mobiwa *mobiwa = (__bridge Mobiwa *)context;
    NSString *parentDir = [NSString stringWithUTF8String:EPUB_OEBPS_PATH_COMPONENT];
    NSString *markupName = [NSString stringWithUTF8String:markup_last_path];
    [mobiwa addMarkupLastPath:[parentDir stringByAppendingPathComponent:markupName]];
}

void my_mobi_dump_rawml_flow(void *context, char *flow_last_path) {
    Mobiwa *mobiwa = (__bridge Mobiwa *)context;
    NSString *parentDir = [NSString stringWithUTF8String:EPUB_OEBPS_PATH_COMPONENT];
    NSString *flowName = [NSString stringWithUTF8String:flow_last_path];
    [mobiwa addFlowLastPath:[parentDir stringByAppendingPathComponent:flowName]];
}

@implementation Mobiwa

+ (instancetype)instanceWithMobiFileAtPath:(NSString *)mobiPath
                                 outputDir:(NSString *)outputDir
                               loadOptions:(MobiLoadOptions)loadOptions {
    const char *mobi_fp = [mobiPath fileSystemRepresentation];
    if (mobi_fp == NULL) {
        return nil;
    }
    FILE *file = fopen(mobi_fp, "rb"); // read as binary
    if (file == NULL) {
        NSLog(@"open mobi file failed: %s",  mobi_fp);
        return nil;
    }
    MOBIData *mobi_data = mobi_init();
    if (mobi_data == NULL) {
        return nil;
    }
    if (loadOptions & MobiLoadOptionParseKF7) {
        mobi_data->use_kf8 = false;
    }
    MOBI_RET ret_code = mobi_load_file(mobi_data, file);
    fclose(file);
    if (ret_code != MOBI_SUCCESS) {
        NSLog(@"load mobi file failed: %s",  mobi_fp);
        return nil;
    }
    MOBIRawml *rawml = mobi_init_rawml(mobi_data);
    if (rawml == NULL) {
        mobi_free(mobi_data);
        return nil;
    }
    ret_code = mobi_parse_rawml(rawml, mobi_data);
    if (ret_code != MOBI_SUCCESS) {
        NSLog(@"parse rawml failed: %s", mobi_fp);
        mobi_free_rawml(rawml);
        mobi_free(mobi_data);
        return nil;
    }
    
    Mobiwa *mobiwa = [Mobiwa new];
    mobi_dump_rawml_parts_handler handler = {
        .meta_info_callback = my_mobi_dump_rawml_meta_info,
        .mimetype_callback = my_mobi_dump_rawml_mimetype,
        .resource_callback = my_mobi_dump_rawml_resource,
        .markup_callback = my_mobi_dump_rawml_markup,
        .flow_callback = my_mobi_dump_rawml_flow,
    };
    
    dump_rawml_parts(rawml, mobi_fp, [outputDir fileSystemRepresentation], &handler, (__bridge void *)mobiwa);
    
    mobi_free_rawml(rawml);
    mobi_free(mobi_data);
    
    [mobiwa endParsing];
    
    return mobiwa;
}

+ (instancetype)loadFromPath:(NSString *)path {
    Mobiwa *mobiwa = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    mobiwa.baseDir = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:mobiwa.lastDir];
    return mobiwa;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _mMarkupLastPaths = [NSMutableArray array];
        _mFlowLastPaths = [NSMutableArray array];
        _mResourceLastPaths = [NSMutableArray array];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        _lastDir = [aDecoder decodeObjectForKey:@"lastDir"];
        _metaInfoLastPath = [aDecoder decodeObjectForKey:@"metaInfoLastPath"];
        _MIMETypeLastPath = [aDecoder decodeObjectForKey:@"MIMETypeLastPath"];
        _markupLastPaths = [aDecoder decodeObjectForKey:@"markupLastPaths"];
        _flowLastPaths = [aDecoder decodeObjectForKey:@"flowLastPaths"];
        _mResourceLastPaths = [aDecoder decodeObjectForKey:@"resourceLastPaths"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_lastDir forKey:@"lastDir"];
    [aCoder encodeObject:_metaInfoLastPath forKey:@"metaInfoLastPath"];
    [aCoder encodeObject:_MIMETypeLastPath forKey:@"MIMETypeLastPath"];
    [aCoder encodeObject:_markupLastPaths forKey:@"markupLastPaths"];
    [aCoder encodeObject:_flowLastPaths forKey:@"flowLastPaths"];
    [aCoder encodeObject:_resourceLastPaths forKey:@"resourceLastPaths"];
}

- (void)addMarkupLastPath:(NSString *)markupLastPath {
    [_mMarkupLastPaths addObject:markupLastPath];
}

- (void)addFlowLastPath:(NSString *)flowLastPath {
    [_mFlowLastPaths addObject:flowLastPath];
}

- (void)addResourceLastPath:(NSString *)resourceLastPath {
    [_mResourceLastPaths addObject:resourceLastPath];
}

- (BOOL)saveAtPath:(NSString *)path {
    return [NSKeyedArchiver archiveRootObject:self toFile:path];
}

- (void)endParsing {
    _markupLastPaths = [_mMarkupLastPaths copy];
    _flowLastPaths = [_mFlowLastPaths copy];
    _resourceLastPaths = [_mResourceLastPaths copy];
    _mMarkupLastPaths = nil;
    _mFlowLastPaths = nil;
    _mResourceLastPaths = nil;
}

@end
