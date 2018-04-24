//
//  mobi_tools.h
//  mobius
//
//  Created by chudanqin on 17/04/2018.
//  Copyright © 2018 chudanqin. All rights reserved.
//

#ifndef mobi_tools_h
#define mobi_tools_h

#include <libmobi/mobi.h>

#define EPUB_CONTAINER "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n\
<container version=\"1.0\" xmlns=\"urn:oasis:names:tc:opendocument:xmlns:container\">\n\
<rootfiles>\n\
<rootfile full-path=\"OEBPS/content.opf\" media-type=\"application/oebps-package+xml\"/>\n\
</rootfiles>\n\
</container>"

#define EPUB_MIMETYPE "application/epub+zip"

#define EPUB_META_INFO_PATH_COMPONENT           "META-INF"
#define EPUB_META_INFO_CONTAINER_FILE_NAME      "container.xml"
#define EPUB_MIME_TYPE_FILE_NAME                "mimetype"
#define EPUB_OEBPS_PATH_COMPONENT               "OEBPS"

extern int mt_mkdir(const char *filename);

extern void split_fullpath(const char *fullpath, char *dirname, char *basename);

// { dump rawml begin
typedef void mobi_dump_rawml_meta_info(void *context, char *base_dir, char *meta_info_last_path);

typedef void mobi_dump_rawml_mimetype(void *context, char *mimetype_last_path);

typedef void mobi_dump_rawml_resource(void *context, char *resource_last_path);

typedef void mobi_dump_rawml_markup(void *context, char *markup_last_path);

typedef void mobi_dump_rawml_flow(void *context, char *flow_last_path);

typedef struct {
    mobi_dump_rawml_meta_info *meta_info_callback;
    mobi_dump_rawml_mimetype *mimetype_callback;
    mobi_dump_rawml_resource *resource_callback;
    mobi_dump_rawml_markup *markup_callback;
    mobi_dump_rawml_flow *flow_callback;
} mobi_dump_rawml_parts_handler;

extern bool dump_rawml_parts(const MOBIRawml *rawml,
                             const char *mobi_path,
                             const char *output_dir,
                             mobi_dump_rawml_parts_handler *handler,
                             void *context);
// dump rawml end }

#endif /* mobi_tools_h */
