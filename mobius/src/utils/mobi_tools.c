//
//  mobi_tools.c
//  mobius
//
//  Created by chudanqin on 17/04/2018.
//  Copyright © 2018 chudanqin. All rights reserved.
//

#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/errno.h>
#include "mobi_tools.h"

#ifdef _WIN32
const char separator = '\\';
#else
const char separator = '/';
#endif

/**
 @brief Portable mkdir
 @param[in] filename File name
 */
int mt_mkdir(const char *filename) {
    int ret;
#ifdef _WIN32
    ret = _mkdir(filename);
#else
    ret = mkdir(filename, S_IRWXU);
#endif
    return ret;
}

void split_fullpath(const char *fullpath, char *dirname, char *basename) {
    char *p = strrchr(fullpath, separator);
    if (p) {
        p += 1;
        strncpy(dirname, fullpath, (unsigned long)(p - fullpath));
        dirname[p - fullpath] = '\0';
        strncpy(basename, p, strlen(p) + 1);
    }
    else {
        dirname[0] = '\0';
        strncpy(basename, fullpath, strlen(fullpath) + 1);
    }
    p = strrchr(basename, '.');
    if (p) {
        *p = '\0';
    }
}

bool dump_rawml_parts(const MOBIRawml *rawml,
                      const char *mobi_path,
                      const char *output_dir,
                      mobi_dump_rawml_parts_handler *handler,
                      void *context) {
    if (rawml == NULL) {
        printf("Rawml structure not initialized\n");
        return false;
    }
    char dirname[FILENAME_MAX];
    char basename[FILENAME_MAX];
    split_fullpath(mobi_path, dirname, basename);
    char newdir[FILENAME_MAX];
    if (output_dir != NULL) {
        snprintf(newdir, sizeof(newdir), "%s", output_dir);
    } else {
        snprintf(newdir, sizeof(newdir), "%s%s_markup", dirname, basename);
    }
    printf("Saving markup to %s\n", newdir);
    errno = 0;
    if (mt_mkdir(newdir) != 0 && errno != EEXIST) {
        int errsv = errno;
        printf("Creating directory failed (%s)\n", strerror(errsv));
        return false;
    }
    
    /* create META_INF directory */
    char opfdir[FILENAME_MAX];
    snprintf(opfdir, sizeof(newdir), "%s%c%s", newdir, separator, EPUB_META_INFO_PATH_COMPONENT);
    errno = 0;
    if (mt_mkdir(opfdir) != 0 && errno != EEXIST) {
        int errsv = errno;
        printf("Creating META-INF directory failed (%s)\n", strerror(errsv));
        return false;
    }
    /* create container.xml */
    char container[FILENAME_MAX];
    snprintf(container, sizeof(container), "%s%c%s", opfdir, separator, EPUB_META_INFO_CONTAINER_FILE_NAME);
    FILE *file = fopen(container, "wb");
    if (file == NULL) {
        int errsv = errno;
        printf("Could not open file for writing: %s (%s)\n", container, strerror(errsv));
        return false;
    }
    errno = 0;
    fwrite(EPUB_CONTAINER, 1, sizeof(EPUB_CONTAINER) - 1, file);

    if (ferror(file)) {
        int errsv = errno;
        printf("Error writing: %s (%s)\n", container, strerror(errsv));
        fclose(file);
        return false;
    }
    fclose(file);
    if (handler != NULL && handler->meta_info_callback != NULL) {
        handler->meta_info_callback(context, newdir, container);
    }
    /* create mimetype file */
    snprintf(container, sizeof(container), "%s%c%s", newdir, separator, EPUB_MIME_TYPE_FILE_NAME);
    file = fopen(container, "wb");
    if (file == NULL) {
        int errsv = errno;
        printf("Could not open file for writing: %s (%s)\n", container, strerror(errsv));
        return false;
    }
    errno = 0;
    fwrite(EPUB_MIMETYPE, 1, sizeof(EPUB_MIMETYPE) - 1, file);
    if (ferror(file)) {
        int errsv = errno;
        printf("Error writing: %s (%s)\n", container, strerror(errsv));
        fclose(file);
        return false;
    }
    fclose(file);
    if (handler != NULL && handler->mimetype_callback != NULL) {
        handler->mimetype_callback(context, container);
    }
    /* create OEBPS directory */
    snprintf(opfdir, sizeof(opfdir), "%s%c%s", newdir, separator, EPUB_OEBPS_PATH_COMPONENT);
    errno = 0;
    if (mt_mkdir(opfdir) != 0 && errno != EEXIST) {
        int errsv = errno;
        printf("Creating OEBPS directory failed (%s)\n", strerror(errsv));
        return false;
    }
    /* output everything else to OEBPS dir */
    strcpy(newdir, opfdir);
    
    char lastname[FILENAME_MAX];
    char partname[FILENAME_MAX];
    if (rawml->markup != NULL) {
        /* Linked list of MOBIPart structures in rawml->markup holds main text files */
        MOBIPart *curr = rawml->markup;
        while (curr != NULL) {
            MOBIFileMeta file_meta = mobi_get_filemeta_by_type(curr->type);
            snprintf(lastname, sizeof(lastname), "part%05zu.%s", curr->uid, file_meta.extension);
            snprintf(partname, sizeof(partname), "%s%c%s", newdir, separator, lastname);
            errno = 0;
            FILE *file = fopen(partname, "wb");
            if (file == NULL) {
                int errsv = errno;
                printf("Could not open file for writing: %s (%s)\n", partname, strerror(errsv));
                return false;
            }
            printf("part%05zu.%s\n", curr->uid, file_meta.extension);
            errno = 0;
            fwrite(curr->data, 1, curr->size, file);
            if (ferror(file)) {
                int errsv = errno;
                printf("Error writing: %s (%s)\n", partname, strerror(errsv));
                fclose(file);
                return false;
            }
            fclose(file);
            if (handler != NULL && handler->markup_callback != NULL) {
                handler->markup_callback(context, lastname);
            }
            curr = curr->next;
        }
    }
    if (rawml->flow != NULL) {
        /* Linked list of MOBIPart structures in rawml->flow holds supplementary text files */
        MOBIPart *curr = rawml->flow;
        /* skip raw html file */
        curr = curr->next;
        while (curr != NULL) {
            MOBIFileMeta file_meta = mobi_get_filemeta_by_type(curr->type);
            snprintf(lastname, sizeof(lastname), "flow%05zu.%s", curr->uid, file_meta.extension);
            snprintf(partname, sizeof(partname), "%s%c%s", newdir, separator, lastname);
            errno = 0;
            FILE *file = fopen(partname, "wb");
            if (file == NULL) {
                int errsv = errno;
                printf("Could not open file for writing: %s (%s)\n", partname, strerror(errsv));
                return false;
            }
            printf("flow%05zu.%s\n", curr->uid, file_meta.extension);
            errno = 0;
            fwrite(curr->data, 1, curr->size, file);
            if (ferror(file)) {
                int errsv = errno;
                printf("Error writing: %s (%s)\n", partname, strerror(errsv));
                fclose(file);
                return false;
            }
            fclose(file);
            if (handler != NULL && handler->flow_callback != NULL) {
                handler->flow_callback(context, lastname);
            }
            curr = curr->next;
        }
    }
    if (rawml->resources != NULL) {
        /* Linked list of MOBIPart structures in rawml->resources holds binary files, also opf files */
        MOBIPart *curr = rawml->resources;
        /* jpg, gif, png, bmp, font, audio, video also opf, ncx */
        while (curr != NULL) {
            MOBIFileMeta file_meta = mobi_get_filemeta_by_type(curr->type);
            if (curr->size > 0) {
                if (file_meta.type == T_OPF) {
                    snprintf(lastname, sizeof(lastname), "%s", "content.opf");
                } else {
                    snprintf(lastname, sizeof(lastname), "resource%05zu.%s", curr->uid, file_meta.extension);
                }
                snprintf(partname, sizeof(partname), "%s%c%s", newdir, separator, lastname);
                errno = 0;
                FILE *file = fopen(partname, "wb");
                if (file == NULL) {
                    int errsv = errno;
                    printf("Could not open file for writing: %s (%s)\n", partname, strerror(errsv));
                    return false;
                }
                printf("%s\n", lastname);
                errno = 0;
                fwrite(curr->data, 1, curr->size, file);
                if (ferror(file)) {
                    int errsv = errno;
                    printf("Error writing: %s (%s)\n", partname, strerror(errsv));
                    fclose(file);
                    return false;
                }
                if (handler != NULL && handler->resource_callback != NULL) {
                    handler->resource_callback(context, lastname);
                }
                fclose(file);
            }
            curr = curr->next;
        }
    }
    return true;
}
